# JavaScript AI Harness Template

Harness ready for JavaScript projects, with guardrails for AI-assisted development.
Structured to support both Node and browser runtimes with a quality-first workflow.

## Includes

- `package.json` scripts for local development, linting, testing, coverage, and security checks.
- `vitest` with `happy-dom` support and coverage reporting.
- `eslint` (Node + browser globals) and `prettier` for linting and formatting.
- `lefthook` pre-commit hook.
- Coverage gate with a configurable minimum threshold.
- `npm audit` security checks.
- CI workflow in `.github/workflows/quality.yml` with separate jobs for lint, test, coverage, and security.

## Quick start

1. Apply the JavaScript template in your target repository.
2. Install dependencies.
3. Install git hooks.
4. Run the verification checks.

Suggested commands:

```sh
scripts/stack-setup.sh javascript
npm install
npx lefthook install
npm run verify
```

## Key scripts

| Script | What it does |
|---|---|
| `npm run verify` | lint + unit tests (fast gate) |
| `npm run quality` | verify + coverage gate |
| `npm run format` | format supported text files with Prettier |
| `npm run format:check` | check formatting without writing changes |
| `npm run lint` | run ESLint |
| `npm run test` | run unit and browser-environment tests |
| `npm run test:watch` | run Vitest in watch mode |
| `npm run coverage` | generate coverage report and enforce minimum threshold |
| `npm run security` | run `npm audit` with `high` severity threshold |
| `npm run dev:node` | execute `src/node/index.js` |
| `npm run dev:browser` | serve `index.html` locally |

## Hook pipeline

```text
pre-commit (parallel, skips merge/rebase):
	setup:    prettier on staged text files (auto-fixed)
	jobs:     lint · tests · coverage
```

## CI workflow

`.github/workflows/quality.yml` runs on pull requests, pushes to `main`, and manual dispatch.

Current jobs:

- `lint`: `npm ci` + `npm run lint`
- `test`: `npm ci` + `npm run test`
- `coverage`: `npm ci` + `npm run coverage`
- `security`: `npm ci` + `npm run security`

## Project layout

This template provides configuration and tooling files only.
Add your application code and tests under paths such as `src/` and `test/`.

The default scripts expect:

- Node entry point at `src/node/index.js`
- Browser entry point served from project root (for example, `index.html` + browser modules)
- Test files matching `test/**/*.test.js`

## Coverage threshold

Default minimum coverage is **99%**. Override with:

```sh
COVERAGE_MIN=90 npm run coverage
```
