# Go AI Harness Template

Harness ready for Go projects, with guardrails for AI-assisted development.

## Includes

- Base Go project structure (`cmd`, `test`).
- Makefile with `verify`, `quality`, and focused quality targets.
- Lefthook pre-commit hook.
- `golangci-lint` — fast linting across the codebase.
- `go-arch-lint` — enforce architectural dependency rules.
- `govulncheck` + `gosec` — security vulnerability and code scanning.
- `gremlins` — mutation testing to validate test suite effectiveness.
- CI workflow (`.github/workflows/quality.yml`) with dedicated jobs for lint, test, coverage, architecture checks, and mutation testing.

## Quick start

1. Apply the Go template in your target repository.
2. Initialize your Go module.
3. Install required CLI tooling.
4. Install git hooks.
5. Run verification checks.

Suggested commands:

```sh
scripts/stack-setup.sh go
go mod init your.org/your-project
make tools
lefthook install
make verify
```

## Key make targets

| Target | What it does |
|---|---|
| `make verify` | lint + unit tests (fast gate) |
| `make quality` | verify + race detection + coverage gate + security + arch |
| `make format` | gofmt on all tracked Go files |
| `make lint` | golangci-lint |
| `make test` | unit tests |
| `make test-race` | unit tests with race detector |
| `make test-coverage` | enforce ≥99% coverage threshold |
| `make mutation` | gremlins mutation testing |
| `make security` | govulncheck + gosec |
| `make arch` | go-arch-lint architectural check |
| `make tools` | install all required CLI tools |
| `make run` | run `cmd/app` from source |

## Hook pipeline

```
pre-commit (parallel, skips merge/rebase):
  setup: gofmt (tracked Go files auto-fixed)
  jobs:  test · golangci-lint · test-coverage · mutation · security · arch
```

## CI workflow

`.github/workflows/quality.yml` runs on pull requests, pushes to `main`, and manual dispatch.

Current jobs:

- `lint`: runs `golangci-lint` through `golangci/golangci-lint-action`.
- `test`: runs `make test`.
- `coverage`: runs `make coverage`.
- `arch`: installs `go-arch-lint` and runs `make arch`.
- `mutation`: installs `gremlins` and runs `make mutation`.

## Architectural constraints

`.go-arch-lint.yml` defines allowed dependency directions between packages.
Edit it to match your project's layer boundaries (`cmd`, `domain`, `service`, `transport`, `platform`).

## Coverage threshold

Default minimum coverage is **99%**. Override with:

```sh
make test-coverage COVERAGE_MIN=90
```
