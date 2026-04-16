---
status: accepted
date: 2026-04-16
decision-makers: Repository maintainers
---

# Use pull request stage commit generation by default

## Context and Problem Statement

The action design separates execution into update, commit, and pull request stages. For a Dependabot-like user experience, repositories should be able to enable pull request creation without having to separately configure an explicit commit stage.

Without a clear default, `create-pr=true` and `create-commit=false` can either fail unexpectedly or create inconsistent behavior across repositories. We need one deterministic rule that favors low-friction adoption while preserving explicit opt-out controls.

Constraints:

- Human review remains required before merge.
- File safety policy (allowlist/ignore/blocked) remains enforced before any write.
- The workflow should be usable with minimal configuration.

## Decision

When `create-pr=true`, pull request stage commit generation is the default behavior:

- If a commit already exists (from commit stage), pull request stage reuses it.
- If no commit exists and `pr-generate-commit=true` (default), pull request stage generates a commit from allowed changed files before creating/updating the pull request.
- If no commit exists and `pr-generate-commit=false`, the run fails with an explicit error.

Non-goals:

- Auto-merging pull requests.
- Creating multiple pull requests in a single run.

## Consequences

- Good, because repositories get a Dependabot-like default with less setup.
- Good, because `create-commit=false` remains viable for simplified consumer workflows.
- Good, because behavior is deterministic and documented for all stage combinations.
- Bad, because pull request stage owns both branch and commit responsibilities in default mode.
- Bad, because misconfigured write permissions fail later in the pipeline when pull request stage must generate a commit.

## Implementation Plan

- **Affected paths**:
  - `specs/overview-and-contract.md`
  - `specs/runtime-and-pr-flow.md`
  - `specs/features/pull-request-feature.md`
  - `action.yml` (implementation phase)
  - `scripts/run-skill-update.sh` (implementation phase)
- **Dependencies**: no new package dependency is required for this decision.
- **Patterns to follow**:
  - Single rolling pull request branch (`chore/skills-update`).
  - Stage ordering from `specs/runtime-and-pr-flow.md`.
  - Pull request outputs contract from `specs/overview-and-contract.md`.
- **Patterns to avoid**:
  - Do not generate commits from ignored or blocked files.
  - Do not create additional pull requests when one already exists for the rolling branch.

### Verification

- [ ] With `create-pr=true`, `create-commit=false`, and allowed changes, the run creates/updates a pull request successfully.
- [ ] With `create-pr=true`, `create-commit=false`, and `pr-generate-commit=false`, the run fails with a clear missing-commit error.
- [ ] With `create-pr=true`, `create-commit=true`, pull request stage reuses existing commit SHA.
- [ ] No run path bypasses file policy checks before commit generation.

<!-- Optional — remove if not needed -->

## Alternatives Considered

- Require `create-commit=true` whenever `create-pr=true`: rejected because it adds setup friction and weakens plug-and-play behavior.
- Always force explicit commit stage and remove `pr-generate-commit`: rejected because it removes a useful safe default for simple repositories.

<!-- Optional — remove if not needed -->

## More Information

- Related specs:
  - `specs/overview-and-contract.md`
  - `specs/runtime-and-pr-flow.md`
  - `specs/features/pull-request-feature.md`
- Revisit trigger: if repositories repeatedly require custom branch/write flows that conflict with default commit generation.

