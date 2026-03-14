<?php

namespace App\Command;

use Doctrine\DBAL\DriverManager;
use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(
    name: 'tms:export',
    description: 'Export data from TMS to MySQL'
)]
final class ExportDataCommand extends Command
{
    public function __construct(
        private readonly LoggerInterface $logger,
        private readonly array           $tables,
        private readonly array           $sourceConfig,
        private readonly array           $destinationConfig
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $this->logger->info('**** STARTING EXPORT');

        $srcConn = DriverManager::getConnection($this->sourceConfig);
        $destConn = DriverManager::getConnection($this->destinationConfig);

        foreach ($this->tables as $tableName) {
            if(!empty($this->sourceConfig['table_prefix'])) {
                $sourceTable = "{$this->sourceConfig['table_prefix']}{$tableName}";
            } else {
                $sourceTable = $tableName;
            }

            $this->logger->info("Migrating table {$tableName}");

            // Fetch column metadata dynamically
            $columns = $this->getDynamicColumns($srcConn, $sourceTable);

            // Prepare SQL
            $selectSql = sprintf('SELECT %s FROM %s', $columns['select'], $sourceTable);
            $insertSql = sprintf(
                'INSERT INTO %s (%s) VALUES (%s)',
                $tableName,
                implode(', ', $columns['names']),
                implode(', ', array_fill(0, count($columns['names']), '?'))
            );

            $stmtInsert = $destConn->prepare($insertSql);
            $result = $srcConn->executeQuery($selectSql);

            $destConn->beginTransaction();
            $count = 0;

            while ($row = $result->fetchNumeric()) {
                foreach ($row as $index => $value) {
                    $stmtInsert->bindValue($index + 1, $value);
                }

                $stmtInsert->executeStatement();

                if (++$count % 500 === 0) {
                    $destConn->commit();
                    $destConn->beginTransaction();
                }
            }
            $destConn->commit();
            $this->logger->info("Finished {$tableName}: Total {$count} rows.");
        }

        $srcConn->close();
        $destConn->close();

        return Command::SUCCESS;
    }

    private function getDynamicColumns($conn, string $sourceTable): array
    {
        $data = $conn->fetchAllAssociative("
            SELECT c.name, t.name AS type, c.max_length
            FROM sys.columns c
            JOIN sys.types t ON c.user_type_id = t.user_type_id
            WHERE c.object_id = OBJECT_ID(?)
        ", [$sourceTable]);

        $select = [];
        $names = [];

        foreach ($data as $col) {
            // Explicitly skip legacy binary blobs
            if ($col['type'] === 'image') {
                continue;
            }

            $n = $col['name'];
            // STABILITY FIX: Detect nvarchar(max) or legacy text
            // max_length -1 indicates a 'MAX' type
            if (($col['type'] === 'nvarchar' && $col['max_length'] == -1) || $col['type'] === 'text') {
                $select[] = "CAST([$n] AS VARCHAR(MAX)) AS [$n]";
            } elseif ($col['type'] === 'timestamp') {
                $select[] = "CONVERT(VARBINARY(8), [$n]) AS [$n]";
            } else {
                $select[] = "[$n]";
            }

            $names[] = "`{$n}`";
        }

        return [
            'select' => implode(', ', $select),
            'names' => $names
        ];
    }
}
