<?php

declare(strict_types=1);

namespace App;

/**
 * Main application entry point
 */
class Application
{
    public function __construct(private readonly string $version = '0.1.0')
    {
    }

    public function getVersion(): string
    {
        return $this->version;
    }

    public function run(): void
    {
        echo "Application v{$this->getVersion()} is running\n";
    }
}
