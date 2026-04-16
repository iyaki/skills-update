---
status: accepted
date: 2026-04-16
decision-makers: Repository maintainers
---

# Ignore configured local lock paths without failing runs

## Context and Problem Statement

The update stage may modify files that are local/runtime artifacts and should not be committed as part of repository maintenance. In this project, `.agents/.skill-lock.json` is such a path.

If ignored paths fail runs, maintainers receive noisy failures for expected local-only changes. If ignored paths are committed, pull requests include non-portable state and create review noise.

We need a deterministic policy that differentiates ignored paths from blocked paths:

- ignored = excluded from write stages, non-failing
- blocked = disallowed, failing

## Decision

Treat configured ignored paths as non-failing exclusions in v1.

- Default ignored path includes `.agents/.skill-lock.json`.
- Ignored paths are removed from candidate write set.
- Presence of ignored-path changes does not fail the run.
- Blocked-path changes continue to fail before commit/pull request stages.

Non-goals:

- Strict-ignore mode in v1 (failing when ignored paths change).
- Writing ignored-path diagnostics into pull request body in v1.

## Consequences

- Good, because expected local-only lock changes do not break automation.
- Good, because write stages remain scoped to reviewable, repo-relevant files.
- Good, because blocked paths still enforce fail-closed behavior.
- Bad, because ignored path drift may be less visible without explicit reporting.
- Bad, because teams needing strict-ignore semantics must wait for a later version or custom wrapper logic.

## Implementation Plan

- **Affected paths**:
  - `specs/features/update-feature.md`
  - `specs/overview-and-contract.md`
  - `action.yml` (implementation phase)
  - `scripts/run-skill-update.sh` (implementation phase)
- **Dependencies**: no additional dependency required.
- **Patterns to follow**:
  - Path policy buckets: `allowed`, `ignored`, `blocked`.
  - Fail-closed behavior for blocked paths.
- **Patterns to avoid**:
  - Do not stage ignored paths in commit generation.
  - Do not silently downgrade blocked paths to ignored.

### Verification

- [ ] Changes only in `.agents/.skill-lock.json` produce `changed=false` and no write-stage side effects.
- [ ] Ignored path changes do not fail the run by themselves.
- [ ] Any blocked path in diff fails the run before commit/pull request stages.
- [ ] Write-stage file set never includes ignored paths.

<!-- Optional — remove if not needed -->

## Alternatives Considered

- Fail on any ignored-path change: rejected for v1 because it creates high-noise failures on known local artifacts.
- Treat ignored paths as allowed: rejected because it pollutes pull requests with local/runtime state.

<!-- Optional — remove if not needed -->

## More Information

- Related specs:
  - `specs/features/update-feature.md`
  - `specs/overview-and-contract.md`
- Revisit trigger: add strict-ignore mode if multiple consumers require compliance-style failure on ignored-path changes.

