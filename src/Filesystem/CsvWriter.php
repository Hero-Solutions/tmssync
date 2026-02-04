<?php

namespace App\Filesystem;

use League\Csv\AbstractCsv;
use League\Csv\Writer;

final class CsvWriter
{
    private AbstractCsv $writer;

    public function __construct(
        private readonly string $basePath
    ) {}

    public function create(string $name): void
    {
        $file = rtrim($this->basePath, '/') . "/{$name}.csv";

        if (is_file($file)) {
            unlink($file);
        }

        $this->writer = AbstractCsv::from($file, 'w');
        $this->writer->setOutputBOM(Writer::BOM_UTF8);
    }

    public function setHeader(array $header): void
    {
        $this->writer->insertOne($header);
    }

    public function insert(array $row): void
    {
        $this->writer->insertOne(
            array_map(
                static function (mixed $value): mixed {
                    return is_string($value) && str_ends_with($value, '\\')
                        ? $value . ' '
                        : $value;
                },
                $row
            )
        );
    }
}
