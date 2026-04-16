<?php

// This file is used for local environment setup
// It loads environment variables from .env file

if (!function_exists('env')) {
    function env(string $key, string|bool|int $default = ''): string|bool|int
    {
        $value = $_ENV[$key] ?? $_SERVER[$key] ?? $default;
        
        if (is_string($value)) {
            $value = match ($value) {
                'true' => true,
                'false' => false,
                'null' => null,
                default => $value,
            };
        }
        
        return $value;
    }
}

// Load environment variables if .env file exists
$envPath = __DIR__ . '/../.env';
if (file_exists($envPath)) {
    $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with($line, '#') || !str_contains($line, '=')) {
            continue;
        }
        
        [$key, $value] = explode('=', $line, 2);
        $key = trim($key);
        $value = trim($value);
        
        if (!isset($_ENV[$key]) && !isset($_SERVER[$key])) {
            $_ENV[$key] = $value;
        }
    }
}
