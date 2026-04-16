# Release and Verification

Status: Proposed

## Overview

### Purpose

- Define release, versioning, and verification policies for the action.
- Keep these concerns separate from feature behavior specs.

### Goals

- Publish stable releases with clear compatibility guarantees.
- Verify feature contracts before and after release.
- Keep major-version behavior predictable for consumers.

### Non-Goals

- Re-specifying runtime/update/commit/pull request implementation logic.
- Defining repository-specific workflow triggers for consumers.

### Scope

- In scope:
  - Tagging and release process.
  - Compatibility policy.
  - Verification matrix for feature contracts.
- Out of scope:
  - Detailed feature internals.

### V1 Decisions (Frozen)

- Signed tags are not mandatory for v1 releases.
- Immutable semver tags plus mutable major alias (`v1`) remain required.
- Release verification for v1 focuses on contract stability and smoke checks.

## Architecture

### Module/package layout (tree format)

```text
.
|- action.yml
|- README.md
|- .github/workflows/
|  |- smoke-marketplace-action.yml
|  |- release-marketplace-action.yml
|- specs/
   |- overview-and-contract.md
   |- features/
      |- update-feature.md
      |- commit-feature.md
      |- pull-request-feature.md
   |- release-and-verification.md
```

### Component diagram (ASCII)

```text
+-------------------------+
| Pull request checks and smoke |
+------------+------------+
             |
             v
+-------------------------+
| Tag vX.Y.Z              |
+------------+------------+
             |
             v
+-------------------------+
| Publish release         |
| Update major tag (v1)   |
+------------+------------+
             |
             v
+-------------------------+
| Consumer repos @v1      |
+-------------------------+
```

### Data flow summary

- Changes are validated with smoke checks before tag creation.
- Release workflow publishes immutable semver tag and updates major alias.
- Consumers resolve `@v1` to latest compatible release.

## Data model

### Core Entities

- `ReleaseVersion`: immutable release tag and metadata.
- `CompatibilityPromise`: behavior guarantees for a major version.
- `VerificationSuite`: required checks and status.

```ts
type ReleaseVersion = {
	fullTag: string;
	majorTag: string;
	publishedAtUtc: string;
};

type CompatibilityPromise = {
	major: number;
	guarantees: string[];
};

type VerificationSuite = {
	name: string;
	required: boolean;
	result: "pass" | "fail" | "skipped";
};
```

### Relationships

- Verification suites validate contracts defined in:
  - `specs/overview-and-contract.md`
  - `specs/features/update-feature.md`
  - `specs/features/commit-feature.md`
  - `specs/features/pull-request-feature.md`
  - `specs/runtime-and-pr-flow.md`

### Persistence Notes

- Persistent release records are Git tags and GitHub Releases.

## Workflows

1. Pre-release validation:
   1. Run smoke checks.
   2. Verify action metadata and feature contract compatibility.
   3. Block release on required check failure.

2. Release flow:
   1. Create `vX.Y.Z` tag.
   2. Publish GitHub Release.
   3. Move major tag `v1` to latest compatible release.

3. Post-release verification:
   1. Validate consumer workflow behavior for update/commit/pull request scenarios.
   2. Confirm output contract stability.

## APIs

### Base paths

- Action reference: `uses: iyaki/skills-update@v1`
- Release reference: `refs/tags/vX.Y.Z`

### Endpoints (method, path, purpose)

| Method   | Path               | Purpose                         |
| -------- | ------------------ | ------------------------------- |
| `TAG`    | `refs/tags/vX.Y.Z` | Immutable release reference     |
| `TAG`    | `refs/tags/v1`     | Moving major alias              |
| `OUTPUT` | `changed`          | Contract compatibility sentinel |
| `OUTPUT` | `commit-created`   | Contract compatibility sentinel |
| `OUTPUT` | `pull-request-url` | Contract compatibility sentinel |

### Auth requirements

- Release workflow requires permissions for tags and GitHub Releases.

### Request/response payloads

Consumer usage example:

```yaml
- name: Update skills from marketplace action
  uses: iyaki/skills-update@v1
```

Release metadata example:

```json
{
	"releaseTag": "v1.0.0",
	"majorTag": "v1",
	"verification": "pass"
}
```

## Client SDK Design

- No language SDK; tag pinning is the compatibility mechanism.

## Configuration

- Release workflow defaults:
  - trigger on `v*` tags
  - run smoke checks before publish
  - publish notes for contract-impacting changes

## Permissions

| Role                   | Resource        | Access | Notes              |
| ---------------------- | --------------- | ------ | ------------------ |
| Maintainer             | Repository tags | write  | Create semver tags |
| Release workflow token | Releases API    | write  | Publish release    |
| Release workflow token | Git refs        | write  | Update major alias |

## Security Considerations

- Keep semver tags immutable.
- Update major alias only from validated release workflow.
- Prefer SHA pinning in high-security consumer repos.

## Dependencies

- `specs/overview-and-contract.md`
- `specs/features/update-feature.md`
- `specs/features/commit-feature.md`
- `specs/features/pull-request-feature.md`
- `specs/runtime-and-pr-flow.md`

## Open Questions / Risks

- Automated contract-diff summaries in release notes are deferred to a future version.

## Verifications

- Release is blocked when required smoke checks fail.
- `vX.Y.Z` remains immutable after publication.
- `v1` points to the latest validated compatible release.
- Consumer runs preserve output contract for update, commit, and pull request features.

## Appendices

- Future considerations:
  - Automated compatibility regression tests across historical tags.
