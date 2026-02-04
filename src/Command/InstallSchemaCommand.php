<?php

namespace App\Command;

use App\Database\MysqlDestination;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(
    name: 'tmssync:install',
    description: 'Install the MySQL database schema'
)]
final class InstallSchemaCommand extends Command
{
    public function __construct(
        private readonly MysqlDestination $mysqlDestination
    ) {
        parent::__construct();
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $this->mysqlDestination->createSchema();

        return Command::SUCCESS;
    }
}
