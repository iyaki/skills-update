# Agent Guidelines

This repository is optimized for hands-off, AI-driven development.

## Mission and Operating Mode

- Default behavior is autonomous end-to-end execution with minimal human interruption.
- Do all non-blocked work before asking questions.
- Ask only when blocked by ambiguity with material impact, missing credentials, or destructive/irreversible operations.
- Prefer deterministic, reproducible execution over ad-hoc/manual workflows.

## Source of Truth Order

When instructions conflict, follow this order:

1. Explicit user request
2. Accepted ADRs in `adr/`
3. Specs in `specs/`
4. `IMPLEMENTATION_PLAN.md`
5. Existing code patterns and CI behavior

## Spec and ADR Discipline

- Read `specs/README.md` and relevant feature specs before implementation.
- Read `adr/README.md` and all relevant accepted ADRs before architectural changes.
- Treat specs as intent; verify actual implementation details in code.
- Do not claim a feature exists without confirming it in the repository.
- Update specs/ADRs only when explicitly requested or when task scope includes documentation updates.

### ADR Trigger Rule

Pause and propose a new ADR when introducing:

- a new dependency,
- a new cross-cutting architectural pattern,
- a hard-to-reverse technical decision,
- or a change that contradicts an accepted ADR.

## Hands-Off Delivery Workflow

Use this loop for programming work:

1. Understand scope from specs/ADRs and current code.
2. Create/confirm failing tests first.
3. Implement minimal change to pass tests.
4. Refactor while preserving behavior.
5. Run quality gates.
6. Update docs/spec references if required by scope.
7. Report results with evidence (commands + outcomes).

## Test-Driven Development Policy

- For programming tasks, always load the `test-driven-development` skill before editing implementation code.
- Follow strict TDD: red -> green -> refactor.
- When writing specs, do not do TDD; write the spec and stop.

## Testing and Quality Gates

- Coverage gate: 100% for touched behavior.
- Mutation testing is allowed only in final hardening stages.
- Never run mutation testing during red/green TDD iterations.
- If tests cannot run locally, explain exactly why and provide a precise verification plan.

## Command and Execution Policy

- Use non-interactive commands and explicit flags suitable for headless execution.
- Prefer project scripts/workflows over custom one-off command chains.
- Keep scans deterministic and reproducible.
- Avoid long-running/watch commands unless explicitly requested.

## Local Validation Commands

Use the smallest relevant validation set for changed scope:

- Template smoke tests:
  - `bash scripts/test-template-stack.sh go`
  - `bash scripts/test-template-stack.sh javascript`
  - `bash scripts/test-template-stack.sh php`
- Shell script syntax check:
  - `bash -n scripts/<script>.sh`

If workflows are edited, also validate workflow syntax with the available CI lint tooling.

## Git and Change Hygiene

- Never revert unrelated user changes.
- Keep edits scoped to task intent.
- Do not create commits unless explicitly requested.
- Never use destructive git commands unless explicitly requested.
- Never bypass hooks with `--no-verify`.

## Security and Sensitive Data

- Treat matched content and logs as sensitive.
- Do not print secrets, tokens, or raw credential values.
- Prefer secret-safe tooling for `.env` operations.
- Keep least-privilege assumptions for tokens and workflow permissions.

## Implementation Guidance

- Keep scans deterministic and reproducible.
- Consolidate near-duplicate logic into shared services when appropriate.
- Keep interfaces explicit (`inputs`, `outputs`, request structs, deterministic contracts).
- Skip binary/oversized files per spec and record skipped-file stats when relevant.
- Prefer clear failure modes over implicit behavior.

## Definition of Done

A task is done when all apply:

- Behavior matches relevant spec + ADR decisions.
- Tests for changed behavior pass.
- Quality gates pass (coverage and required checks).
- Documentation is updated when part of scope.
- Final report includes changed files, validation commands, and outcomes.
