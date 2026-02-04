<?php

namespace App\Database;

use App\Config\Mapping;
use App\Config\SchemaProvider;
use App\Filesystem\CsvWriter;
use Psr\Log\LoggerInterface;
use RuntimeException;

final class TmsSource
{
    public function __construct(
        private readonly ConnectionProvider $connectionFactory,
        private readonly Mapping            $mapping,
        private readonly SchemaProvider     $schemaProvider,
        private readonly CsvWriter          $csvWriter,
        private readonly LoggerInterface    $logger,
    ) {}

    public function fetch(array $exclusiveTables = []): void
    {
        $this->logger->info('**** FETCHING DATA FROM TMS');

        foreach ($this->mapping->groupedByDatabase() as $dbName => $mappings) {
            $connection = $this->connectionFactory->get($dbName);

            foreach ($mappings as $map) {
                $destination = $map['destination'];
                $sourceTable = $map['source'];

                if ($exclusiveTables && !in_array($destination, $exclusiveTables, true)) {
                    $this->logger->info(
                        'Skipping table {table}',
                        ['table' => $destination]
                    );
                    continue;
                }

                if (!isset($this->schemaProvider->getSchema()['tables'][$destination])) {
                    throw new RuntimeException(
                        "Destination table '{$destination}' not found in schema"
                    );
                }

                $columns = array_map(
                    static fn (array $col): string => $col['name'],
                    $this->schemaProvider->getSchema()['tables'][$destination]['columns']
                );

                // drop tmsid (autoincrement)
                array_shift($columns);

                $sql = sprintf(
                    'SELECT %s FROM %s',
                    implode(', ', $columns),
                    $sourceTable
                );

                $rows = $connection
                    ->executeQuery($sql)
                    ->fetchAllAssociative();

                $this->csvWriter->create($destination);

                if ($rows !== []) {
                    $this->csvWriter->setHeader(array_keys($rows[0]));
                }

                foreach ($rows as $row) {
                    $this->csvWriter->insert($row);
                }

                $this->logger->info(
                    'Fetched {source} → {destination}',
                    [
                        'source' => $sourceTable,
                        'destination' => $destination,
                    ]
                );
            }
        }
    }
}
