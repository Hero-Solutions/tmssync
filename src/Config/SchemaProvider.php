<?php

namespace App\Config;

use RuntimeException;
use Symfony\Component\Yaml\Yaml;

final class SchemaProvider
{
    private array $schema;

    public function __construct(string $schemaPath)
    {
        if (!is_file($schemaPath)) {
            throw new RuntimeException("Schema file not found: {$schemaPath}");
        }

        $data = Yaml::parseFile($schemaPath);

        if (!isset($data['schema']['tables'])) {
            throw new RuntimeException('Invalid schema.yml structure');
        }

        $this->schema = $data['schema'];
    }

    public function getSchema(): array
    {
        return $this->schema;
    }
}
