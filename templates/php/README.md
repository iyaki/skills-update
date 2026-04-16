# PHP AI Harness Template

Harness ready for PHP projects, with guardrails for AI-assisted development.
Follows the same quality-first workflow used in the Go and JavaScript templates.

## Includes

- Base PHP project structure (`src/`, `tests/`).
- **[Mago](https://github.com/carthage-software/mago)** oxidized toolchain (Rust) for:
  - `mago lint` — fast style and semantic linting
  - `mago analyze` — deep semantic analysis
  - `mago format` — PER-CS2.0 code formatting
- **Pest** for unit tests with code coverage reporting.
- **PHPStan** (level 9) for deep type-level static analysis.
- **shipmonk/composer-dependency-analyser** for dead/shadow/misplaced dependency validation.
- **Rector** for automated code refactoring and modernization.
- Pest mutation testing mode for mutation score checks.
- **Composer validate** with strict PSR and ambiguity checks.
- **Lefthook** pre-commit hook.
- CI workflow in `.github/workflows/ci.yml` using:
  - `shivammathur/setup-php` for PHP environment setup
  - `shivammathur/cache-extensions` for PHP extension caching
  - `ramsey/composer-install` for dependency installation
- **Composer scripts** for all CLI commands.

## Quick start

1. Apply the PHP template in your target repository.
2. Install dependencies.
3. Install git hooks.
4. Run verification checks.

Suggested commands:

```sh
scripts/stack-setup.sh php --target . --force
composer install
vendor/bin/lefthook install
composer verify
```

## Key composer scripts

| Script | What it does |
|---|---|
| `composer verify` | mago lint + tests (fast gate) |
| `composer quality` | verify + analyze + phpstan + dependency analysis + coverage + mutation + validation |
| `composer format` | format PHP code with mago (PER-CS2.0) |
| `composer format:check` | check formatting without modifying files (`--check`) |
| `composer lint` | run mago lint (fast style + semantic check) |
| `composer lint:fix` | run mago lint with auto-fix (`--fix`) |
| `composer analyze` | run mago semantic analysis |
| `composer phpstan` | run PHPStan deep type analysis (level 9) |
| `composer deps:analyze` | validate dead/shadow/misplaced Composer dependencies |
| `composer test` | run Pest unit tests |
| `composer test:watch` | watch tests and re-run on changes |
| `composer test:coverage` | generate coverage report |
| `composer mutation` | run Pest mutation testing with MSI thresholds |
| `composer mutation:full` | run full Pest mutation testing without progress output |
| `composer rector` | run Rector auto-refactoring |
| `composer validate:composer` | validate composer.json configuration |
| `composer validate:autoload` | validate and optimize autoload |

## Hook pipeline

```text
pre-commit (parallel, skips merge/rebase):
  setup: composer format (staged php files auto-fixed)
  jobs:  composer-validate · composer-autoload · mago-lint · mago-analyze · phpstan · dependency-analyser · tests · mutation
```

## CI workflow

`.github/workflows/ci.yml` runs on pushes and pull requests targeting `main` and `develop`.

Current job matrix:

- `quality` on PHP `8.3` and `8.4`.

Current checks in CI:

- composer validation
- mago lint + format check + analyze
- phpstan analysis
- dependency analysis
- tests + coverage
- mutation testing (`continue-on-error: true`)

## Quick reference

Use composer scripts directly:

```sh
composer list
```

## Mago configuration

`mago.toml` configures the three mago tools:

```toml
php-version = "8.3"

[source]
paths = ["src", "tests"]
includes = ["vendor"]

[linter]
# all rules enabled at "error" severity by default

[formatter]
# enforces PER-CS2.0 coding standard

[analyzer]
# deep semantic analysis, excluding tests by default
excludes = ["tests/**"]
```

See the [Mago configuration reference](https://mago.carthage.software/guide/configuration) for full options.

## Coverage threshold

Default minimum coverage is **99%**. Override with:

```sh
COVERAGE_MIN=90 composer test:coverage
```

## Mutation testing threshold

Default minimum MSI (Mutation Score Indicator) is **90%**, configured in composer scripts:

```json
"mutation": "@php vendor/bin/pest --configuration=pest.xml --mutate --min-covered-msi=90 --min-msi=90"
```

## Project layout

Template files include:

- `src/Application.php` and `public/index.php` as a minimal runtime skeleton
- `tests/Unit/ApplicationTest.php` plus test bootstrap helpers
- tool config files (`mago.toml`, `phpstan.neon`, `rector.php`, `pest.xml`)

## PHP Version

This template is configured and tested for **PHP 8.3/8.4** in CI.

If your project targets a different version, update both `mago.toml` and `.github/workflows/ci.yml`.

Example `mago.toml` snippet:

```toml
php-version = "8.3"
```

## CI/CD Workflow

The GitHub Actions workflow in `.github/workflows/ci.yml`:

1. Runs on PHP 8.3 and 8.4
2. Sets up PHP with required extensions
3. Caches dependencies for faster builds
4. Validates composer configuration
5. Runs PHPStan analysis
6. Executes test suite
7. Generates coverage reports
8. Checks code formatting
9. Runs Composer dependency analysis
10. Runs mutation testing (non-blocking)

## Recommended PHP Extensions

For best results, ensure these extensions are installed:

- `json` - JSON support
- `dom` - DOM manipulation
- `mbstring` - Multibyte string functions
- `xdebug` - Code coverage (dev only)

## Tools Configuration

All tools are configured with sensible defaults:

- **mago.toml**: Mago config (lint, analyze, format — PER-CS2.0)
- **phpstan.neon**: Level 9 static analysis with bleeding edge rules
- **rector.php**: PHP 8.3 modernization rules
- **pest.xml**: Test suite configuration with coverage
- **composer.json**: Scripts for all CLI commands

## Next steps

1. Update `composer.json` with your project name and namespace
2. Add business logic in `src/` and expose it from `public/index.php`
3. Write tests in `tests/`
4. Configure `.github/workflows/ci.yml` based on your CI/CD needs
5. Review and customize `phpstan.neon` and `rector.php` rules for your codebase
6. Adjust coverage and mutation testing thresholds in composer scripts

## Troubleshooting

**PHP not found**: Ensure PHP 8.3+ is installed and in your PATH
**Composer error**: Run `composer install` to install dependencies
**Tests failing**: Check `tests/bootstrap.php` for proper test configuration
**Mutation testing timeout**: Try `composer mutation:full` in CI and run `composer mutation` locally

## Composer Scripts Reference

All commands use `composer` - run `composer list` for full list:

**Quick aliases**:
- `composer verify` - Fast gate before commit
- `composer quality` - Full quality suite
- `composer format` - Auto-format all code (mago)
- `composer lint` - Fast mago lint
- `composer analyze` - Mago semantic analysis
- `composer phpstan` - Deep PHPStan type analysis
- `composer deps:analyze` - Composer dependency validation
- `composer test` - Run tests with watch option available
- `composer rector` - Auto-fix code modernization
- `composer mutation` - Mutation score checks using Pest mutation mode

See `composer.json` for full script definitions.
