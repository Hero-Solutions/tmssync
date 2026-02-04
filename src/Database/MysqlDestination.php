<?php

namespace App\Database;

use App\Config\Mapping;
use App\Config\SchemaProvider;
use App\Filesystem\CsvReader;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Schema\Schema;
use Psr\Log\LoggerInterface;

final class MysqlDestination
{
    public function __construct(
        private readonly ConnectionProvider $connectionFactory,
        private readonly Mapping            $mapping,
        private readonly SchemaProvider     $schemaProvider,
        private readonly CsvReader          $csvReader,
        private readonly LoggerInterface    $logger,
    ) {}

    public function truncate(array $exclusiveTables = []): void
    {
        $connection = $this->connectionFactory->get('mysql');
        $platform = $connection->getDatabasePlatform();

        foreach (array_keys($this->schemaProvider->getSchema()['tables']) as $table) {
            if ($exclusiveTables && !in_array($table, $exclusiveTables, true)) {
                $this->logger->info('Skipping table {table}', ['table' => $table]);
                continue;
            }

            $quotedTable = $platform->quoteIdentifier($table);
            $connection->executeStatement('SET FOREIGN_KEY_CHECKS = 0');
            $connection->executeStatement('DELETE FROM ' . $quotedTable);
            $connection->executeStatement('SET FOREIGN_KEY_CHECKS = 1');
            $connection->executeStatement('ALTER TABLE ' . $quotedTable . ' AUTO_INCREMENT = 1');

            $this->logger->info('Truncated table {table}', ['table' => $table]);
        }
    }

    public function dump(array $exclusiveTables = []): void
    {
        $connection = $this->connectionFactory->get('mysql');
        $platform = $connection->getDatabasePlatform();

        foreach ($this->mapping->all() as $map) {
            $table = $map['destination'];

            if ($exclusiveTables && !in_array($table, $exclusiveTables, true)) {
                continue;
            }

            $columns = array_map(
                static fn (array $col): string => $col['name'],
                $this->schemaProvider->getSchema()['tables'][$table]['columns']
            );

            $quotedTable = $platform->quoteIdentifier($table);
            $quotedColumns = array_map(
                static fn (string $c): string => $platform->quoteIdentifier($c),
                $columns
            );
            $sql = sprintf(
                'INSERT INTO %s (%s) VALUES (%s)',
                $quotedTable,
                implode(', ', $quotedColumns),
                implode(', ', array_map(static fn (string $c): string => ':'.$c, $columns))
            );

            $reader = $this->csvReader->read($table);

            foreach ($reader->getRecords() as $id => $row) {
                $row['tmsid'] = $id;
                $connection->executeStatement($sql, $row);
            }

            $this->logger->info('Dumped table {table}', ['table' => $table]);
        }
    }

    public function createSchema(): void
    {
        $connection = $this->connectionFactory->get('mysql');
        $schema = new Schema();

        foreach ($this->schemaProvider->getSchema()['tables'] as $tableName => $tableConfig) {
            $table = $schema->createTable($tableName);

            foreach ($tableConfig['columns'] as $columnConfig) {
                $attributes = [];
                if (!empty($columnConfig['attributes'])) {
                    foreach ($columnConfig['attributes'] as $attr) {
                        if (is_array($attr)) {
                            $attributes = array_merge($attributes, $attr);
                        }
                    }
                    $attributes = array_filter($attributes);
                }

                $table->addColumn(
                    $columnConfig['name'],
                    $columnConfig['type'],
                    $attributes
                );
            }

            $table->setPrimaryKey([$tableConfig['primaryKey']]);

            $this->logger->info('Prepared schema for {table}', ['table' => $tableName]);
        }

        foreach ($schema->toSql($connection->getDatabasePlatform()) as $sql) {
            $connection->executeStatement($sql);
        }

        $this->logger->info('Schema installation completed');
    }
}
