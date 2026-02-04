<?php

namespace App\Filesystem;

use League\Csv\Reader;
use League\Csv\Statement;
use RuntimeException;

final class CsvReader
{
    public function __construct(
        private readonly string $basePath
    ) {}

    public function read(string $name): Reader
    {
        $file = rtrim($this->basePath, '/') . "/{$name}.csv";

        if (!is_file($file)) {
            throw new RuntimeException("CSV file not found: {$file}");
        }

        $reader = Reader::from($file);
        $reader->setHeaderOffset(0);

        return $reader;
    }
}
