<?php

namespace App\Command;

use App\Database\MysqlDestination;
use App\Database\TmsSource;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(
    name: 'tms:export',
    description: 'Export data from TMS to MySQL'
)]
final class ExportDataCommand extends Command
{
    public function __construct(
        private readonly TmsSource $source,
        private readonly MysqlDestination $destination
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addOption(
                'fetch',
                'fe',
                InputOption::VALUE_NONE,
                'Fetch data from TMS source before dumping',
                true
            )
            ->addOption(
                'exclusive',
                'ex',
                InputOption::VALUE_OPTIONAL,
                'Comma separated list of destination tables',
                false
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $exclusive = $input->getOption('exclusive');
        $exclusiveTables = $exclusive
            ? array_map('trim', explode(',', $exclusive))
            : [];

        if ($input->getOption('fetch')) {
            $this->destination->truncate($exclusiveTables);
            $this->source->fetch($exclusiveTables);
        }

        $this->destination->dump($exclusiveTables);

        return Command::SUCCESS;
    }
}
