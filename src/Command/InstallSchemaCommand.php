<?php

namespace App\Command;

use Doctrine\DBAL\Connection;
use Doctrine\DBAL\DriverManager;
use Psr\Log\LoggerInterface;
use RuntimeException;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(
    name: 'tms:install',
    description: 'Install the MySQL database schema and views'
)]
final class InstallSchemaCommand extends Command
{
    public function __construct(
        private readonly LoggerInterface $logger,
        private readonly array           $tables,
        private readonly array           $sourceConfig,
        private readonly array           $destinationConfig,
        private readonly string          $schemaFile
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addOption(
            'if-changed',
            null,
            InputOption::VALUE_NONE,
            'Only rebuild if table list differs'
        );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        if (!is_file($this->schemaFile)) {
            throw new RuntimeException("Schema file not found: $this->schemaFile");
        }
        if (($this->destinationConfig['driver'] ?? null) !== 'pdo_mysql') {
            throw new RuntimeException('Only pdo_mysql connections are supported');
        }

        $srcConn = DriverManager::getConnection($this->sourceConfig);
        $destConn = DriverManager::getConnection($this->destinationConfig);

        $ifChanged = $input->getOption('if-changed');

        if ($ifChanged && !$this->tablesDiffer($destConn)) {
            $this->logger->info("*** No table changes detected. Skipping rebuild.");
            return Command::SUCCESS;
        }

        $this->logger->info("*** Wiping database (tables, views, stored procedures, functions, events and triggers)");
        $this->wipeDatabase($destConn);
        $this->logger->info("*** Recreating all tables");
        $this->recreateAllTables($srcConn, $destConn);
        $this->logger->info("*** Adding stored procedures, indexes and views through " . $this->schemaFile);
        $this->executeSchemaFile();
        $this->logger->info("*** DONE recreating MySQL database");

        return Command::SUCCESS;
    }

    private function tablesDiffer(Connection $destConn): bool
    {
        $existingTables = $destConn->fetchFirstColumn('SHOW TABLES');

        if (empty($existingTables)) {
            return true;
        }

        $expectedTables = $this->tables;

        sort($existingTables);
        sort($expectedTables);

        return $existingTables !== $expectedTables;
    }

    private function wipeDatabase(Connection $conn): void
    {
        // Disable foreign key checks
        $conn->executeStatement('SET FOREIGN_KEY_CHECKS = 0');

        // Drop views
        $views = $conn->fetchFirstColumn("SELECT table_name FROM information_schema.views WHERE table_schema = DATABASE()");
        foreach ($views as $view) {
            $conn->executeStatement("DROP VIEW IF EXISTS `$view`");
        }

        // Drop tables
        $tables = $conn->fetchFirstColumn("SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'");
        foreach ($tables as $table) {
            $conn->executeStatement("DROP TABLE IF EXISTS `$table`");
        }

        // Drop triggers
        $triggers = $conn->fetchFirstColumn("SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema = DATABASE()");
        foreach ($triggers as $trigger) {
            $conn->executeStatement("DROP TRIGGER IF EXISTS `$trigger`");
        }

        // Drop stored procedures
        $procedures = $conn->fetchFirstColumn("SELECT routine_name FROM information_schema.routines WHERE routine_schema = DATABASE() AND routine_type = 'PROCEDURE'");
        foreach ($procedures as $procedure) {
            $conn->executeStatement("DROP PROCEDURE IF EXISTS `$procedure`");
        }

        // Drop functions
        $functions = $conn->fetchFirstColumn("SELECT routine_name FROM information_schema.routines WHERE routine_schema = DATABASE() AND routine_type = 'FUNCTION'");
        foreach ($functions as $function) {
            $conn->executeStatement("DROP FUNCTION IF EXISTS `$function`");
        }

        // Drop events
        $events = $conn->fetchFirstColumn("SELECT event_name FROM information_schema.events WHERE event_schema = DATABASE()");
        foreach ($events as $event) {
            $conn->executeStatement("DROP EVENT IF EXISTS `$event`");
        }

        // Re-enable foreign key checks
        $conn->executeStatement('SET FOREIGN_KEY_CHECKS = 1');
    }

    private function recreateAllTables(Connection $srcConn, Connection $destConn): void
    {
        foreach ($this->tables as $tableName) {
            if(!empty($this->sourceConfig['table_prefix'])) {
                $sourceTable = "{$this->sourceConfig['table_prefix']}{$tableName}";
            } else {
                $sourceTable = $tableName;
            }

            // Fetch metadata from SQL Server
            $columnData = $srcConn->fetchAllAssociative("
                SELECT c.name, t.name AS type, c.max_length, c.is_nullable
                FROM sys.columns c
                JOIN sys.types t ON c.user_type_id = t.user_type_id
                WHERE c.object_id = OBJECT_ID(?)
            ", [$sourceTable]);

            if (empty($columnData)) {
                $this->logger->error("Source table {$sourceTable} not found.");
                continue;
            }

            $definitions = [];

            foreach ($columnData as $col) {
                if ($col['type'] === 'image') {
                    $this->logger->info(
                        sprintf('Skipping image column %s.%s', $tableName, $col['name'])
                    );
                    continue;
                }

                $name = $col['name'];
                $definitions[] = sprintf(
                    "`%s` %s %s",
                    $name,
                    $this->mapToMysqlType($col['type'], $col['max_length']),
                    $col['is_nullable'] ? 'NULL' : 'NOT NULL'
                );
            }

            // Execute Drop & Recreate
            $destConn->executeStatement("DROP TABLE IF EXISTS `{$tableName}`");
            $createQuery = sprintf(
                "CREATE TABLE `%s` (%s) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
                $tableName,
                implode(', ', $definitions)
            );
            $destConn->executeStatement($createQuery);
            $this->logger->info("Recreated MySQL table: {$tableName}");
        }
    }

    private function executeSchemaFile(): void
    {
        $cmd = [
            'mysql',
            '--host=' . escapeshellarg($this->destinationConfig['host']),
            '--user=' . escapeshellarg($this->destinationConfig['user']),
        ];

        if (!empty($this->destinationConfig['port'])) {
            $cmd[] = '--port=' . escapeshellarg((string) $this->destinationConfig['port']);
        }

        if (!empty($this->destinationConfig['password'])) {
            $cmd[] = '--password=' . escapeshellarg($this->destinationConfig['password']);
        }

        $cmd[] = escapeshellarg($this->destinationConfig['dbname']);
        $cmd[] = '< ' . escapeshellarg($this->schemaFile);

        $command = implode(' ', $cmd);

        exec($command, $output, $exitCode);

        if ($exitCode !== 0) {
            throw new RuntimeException('MySQL schema import failed');
        }
    }

    /**
     * Translates SQL Server types to the best MySQL equivalent
     */
    private function mapToMysqlType(string $sqlType, int $maxLength): string
    {
        return match ($sqlType) {
            'int'        => 'INT',
            'bigint'     => 'BIGINT',
            'smallint'   => 'SMALLINT',
            'tinyint'    => 'TINYINT',
            'bit'        => 'TINYINT(1)',
            'decimal', 'numeric' => 'DECIMAL(18,4)',
            'float'      => 'DOUBLE',
            'datetime', 'smalldatetime' => 'DATETIME',
            'timestamp', 'rowversion'   => 'VARBINARY(8)',
            'varchar' => match (true) {
                $maxLength === -1 => 'LONGTEXT',
                $maxLength > 16383 => 'TEXT',
                default => "VARCHAR($maxLength)",
            },
            'nvarchar' => match (true) {
                $maxLength === -1 => 'LONGTEXT',
                $maxLength > 16383*2 => 'TEXT',
                default => "VARCHAR(" . intdiv($maxLength, 2) . ")",
            },
            'text', 'ntext'       => 'LONGTEXT',
            default               => 'TEXT',
        };
    }
}
