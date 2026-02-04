<?php

namespace App\Config;

final class Mapping
{
    public function __construct(private readonly array $mapping) {}

    public function all(): array
    {
        return $this->mapping;
    }

    public function groupedByDatabase(): array
    {
        $grouped = [];
        foreach ($this->mapping as $entry) {
            $grouped[$entry['db']][] = $entry;
        }
        return $grouped;
    }
}
