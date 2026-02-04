<?php

namespace App\Database;

use Doctrine\DBAL\Configuration;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\DriverManager;
use InvalidArgumentException;

final class ConnectionProvider
{
    private Configuration $configuration;

    /** @var array<string, Connection> */
    private array $instances = [];

    public function __construct(private readonly array $connections)
    {
        $this->configuration = new Configuration();
    }

    public function get(string $name): Connection
    {
        if (!isset($this->connections[$name])) {
            throw new InvalidArgumentException(sprintf('Unknown connection "%s"', $name));
        }

        if (!isset($this->instances[$name])) {
            $this->instances[$name] = DriverManager::getConnection(
                $this->connections[$name],
                $this->configuration
            );
        }

        return $this->instances[$name];
    }
}
