---
status: accepted
date: 2026-04-16
decision-makers: Repository maintainers
---

# Limit v1 scope to core skills update workflow

## Context and Problem Statement

The project needs a deliverable v1 action with clear, predictable behavior. Several optional enhancements have been identified (strict-ignore mode, phase-trace JSON outputs, advanced retries, split pull request strategy), but implementing them in v1 increases complexity and risks delaying release.

To ship a stable MVP, we need explicit scope boundaries that focus on the core skills maintenance loop.

## Decision

Limit v1 to the core workflow:

- Always run update stage.
- Support optional commit stage.
- Support optional pull request stage with default commit generation when needed.
- Enforce allowlist/ignore/blocked path policy and fail-closed blocked-path behavior.

Explicitly out of scope for v1:

- Strict-ignore failure mode.
- Machine-readable phase-trace JSON outputs.
- Advanced retry policy for transient failures.
- Split pull request strategy.

## Consequences

- Good, because implementation remains focused and feasible for initial release.
- Good, because behavior is easier to reason about and document for consumers.
- Good, because fewer moving parts reduce regression risk in v1.
- Bad, because some advanced consumer use cases need follow-up releases.
- Bad, because richer observability and policy controls are deferred.

## Implementation Plan

- **Affected paths**:
  - `specs/overview-and-contract.md`
  - `specs/features/update-feature.md`
  - `specs/features/pull-request-feature.md`
  - `specs/runtime-and-pr-flow.md`
  - `action.yml` (implementation phase)
  - `scripts/run-skill-update.sh` (implementation phase)
- **Dependencies**: no extra dependency required for deferred features.
- **Patterns to follow**:
  - Stage-based orchestration and explicit feature toggles.
  - Single rolling pull request strategy for v1.
- **Patterns to avoid**:
  - Do not partially implement deferred features behind undocumented behavior.
  - Do not blur fail-closed and ignore semantics.

### Verification

- [ ] v1 implementation includes only update/commit/pull request core stages and documented toggles.
- [ ] No strict-ignore or split pull request behavior is exposed in v1 interface.
- [ ] No phase-trace JSON output contract is declared in v1 outputs.
- [ ] Documentation clearly marks deferred enhancements as future work.

<!-- Optional — remove if not needed -->

## Alternatives Considered

- Ship feature-rich v1 including all known enhancements: rejected because it increases delivery risk and validation surface.
- Ship minimal update-only v1 without commit/pull request flow: rejected because it does not meet the desired Dependabot-like maintenance experience.

<!-- Optional — remove if not needed -->

## More Information

- Related specs:
  - `specs/overview-and-contract.md`
  - `specs/runtime-and-pr-flow.md`
  - `specs/features/update-feature.md`
  - `specs/features/pull-request-feature.md`
- Revisit trigger: after v1 release stabilization, prioritize deferred features based on consumer adoption signals.

