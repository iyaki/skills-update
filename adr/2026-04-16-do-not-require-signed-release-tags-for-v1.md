---
status: accepted
date: 2026-04-16
decision-makers: Repository maintainers
---

# Do not require signed release tags for v1

## Context and Problem Statement

The action needs a low-friction initial release process to publish `iyaki/skills-update@v1` quickly while preserving versioning integrity. Mandatory signed tags increase setup complexity for maintainers and can delay MVP release readiness.

At the same time, release trust still requires immutable semver tags and controlled major alias updates.

We need a v1 release policy that balances security posture with practical adoption speed.

## Decision

For v1, signed tags are not mandatory.

- Required:
  - immutable semver tags (`vX.Y.Z`)
  - controlled major alias tag updates (`v1`)
  - smoke checks and contract verification before release publication
- Not required in v1:
  - GPG or Sigstore-signed tags as a release gate

Non-goals:

- Lowering compatibility checks.
- Allowing mutable semver tags.

## Consequences

- Good, because maintainers can release v1 without additional signing infrastructure.
- Good, because release velocity improves while preserving immutable version semantics.
- Good, because compatibility validation remains enforced through smoke/contract checks.
- Bad, because provenance assurances are weaker than a mandatory signed-tag policy.
- Bad, because security-sensitive consumers may require SHA pinning until stronger attestations are added.

## Implementation Plan

- **Affected paths**:
  - `specs/release-and-verification.md`
  - `.github/workflows/release-marketplace-action.yml` (implementation phase)
- **Dependencies**: no new dependency required for this decision.
- **Patterns to follow**:
  - Immutable `vX.Y.Z` release tags.
  - Major alias progression via validated release workflow.
- **Patterns to avoid**:
  - Do not rewrite immutable semver tags.
  - Do not publish releases when required smoke checks fail.

### Verification

- [ ] Release workflow can publish `vX.Y.Z` without signed-tag enforcement.
- [ ] `vX.Y.Z` remains immutable after publication.
- [ ] `v1` is updated only by validated release workflow.
- [ ] Release pipeline blocks publication when required smoke checks fail.

<!-- Optional — remove if not needed -->

## Alternatives Considered

- Require signed tags in v1: rejected because it increases operational overhead and delays MVP rollout.
- Skip immutable semver tagging and use only a moving major tag: rejected because it weakens reproducibility and auditability.

<!-- Optional — remove if not needed -->

## More Information

- Related spec: `specs/release-and-verification.md`.
- Revisit trigger: after initial adoption, reassess mandatory signed tags and provenance attestations for v2 security posture.

