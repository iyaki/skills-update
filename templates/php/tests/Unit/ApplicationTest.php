<?php

declare(strict_types=1);

use App\Application;

describe('Application', function () {
    it('should create an application instance', function () {
        $app = new Application('0.1.0');
        expect($app)->toBeInstanceOf(Application::class);
    });

    it('should return the correct version', function () {
        $app = new Application('0.1.0');
        expect($app->getVersion())->toBe('0.1.0');
    });

    it('should have a default version', function () {
        $app = new Application();
        expect($app->getVersion())->toBe('0.1.0');
    });
});
