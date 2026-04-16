# Commit Feature

Status: Proposed

## Overview

### Purpose

- Define the optional commit stage that persists allowed update changes to the pull request branch.
- Define the optional commit stage that persists allowed update changes to the pull request branch.
- Ensure commit behavior is deterministic and safe.
- Provide reusable commit outputs for pull request creation.

### Goals

- Create a single commit when allowed changes exist and commit stage is enabled.
- Restrict staged files to update policy allowlist results.
- Emit `commitCreated` and `commitSha` outputs for downstream use.

### Non-Goals

- Running the update command.
- Creating or updating pull requests.
- Auto-squashing or rewriting commit history.

### Scope

- In scope:
  - Stage allowed files.
  - Create commit with configured message.
  - Expose commit metadata.
- Out of scope:
  - Branch creation policy details managed by pull request feature/runtime.

## Architecture

### Module/package layout (tree format)

```text
.
|- action.yml
|- scripts/
|  |- run-skill-update.sh
|- specs/
   |- features/
      |- commit-feature.md
      |- update-feature.md
      |- pull-request-feature.md
```

### Component diagram (ASCII)

```text
+--------------------------+
| Receive Update Result    |
+------------+-------------+
             |
             v
+--------------------------+
| Stage allowed files only |
+------------+-------------+
             |
             v
+--------------------------+
| Create commit            |
| (if enabled + changes)   |
+------------+-------------+
             |
             v
+--------------------------+
| Emit commit outputs      |
+--------------------------+
```

### Data flow summary

- Commit stage consumes `UpdateFeatureResult` from `specs/features/update-feature.md`.
- If commit conditions are met, it stages only `policy.allowed` files and creates a commit.
- It emits commit metadata to shared execution state for pull request stage use.

## Data model

### Core Entities

- `CommitFeatureInput`: commit-stage configuration and upstream update result.
- `CommitFeatureResult`: commit-stage status and metadata.

```ts
type CommitFeatureInput = {
	enabled: boolean;
	commitMessage: string;
	allowedFiles: string[];
	hasAllowedChanges: boolean;
};

type CommitFeatureResult = {
	status: "skipped" | "created" | "failed";
	commitCreated: boolean;
	commitSha?: string;
	failureReason?: string;
};
```

### Relationships

- `CommitFeatureInput.allowedFiles` is sourced from `UpdateFeatureResult.policy.allowed`.
- `CommitFeatureResult.commitSha` is consumed by `specs/features/pull-request-feature.md`.
- `CommitFeatureResult` updates global `ActionOutput` fields in `specs/overview-and-contract.md`.

### Persistence Notes

- No dedicated persistence store.
- Durable outcome is the generated Git commit in the consumer repository branch.
- Optional schema reference (not required for v1):

| Table               | Column       | SQL Type      | Required | Notes                          |
| ------------------- | ------------ | ------------- | -------- | ------------------------------ |
| `commit_stage_runs` | `run_id`     | `varchar(64)` | yes      | Workflow run identifier        |
| `commit_stage_runs` | `status`     | `varchar(16)` | yes      | `skipped`, `created`, `failed` |
| `commit_stage_runs` | `commit_sha` | `char(40)`    | no       | Populated when created         |

## Workflows

1. Commit created flow:
   1. Commit stage enabled.
   2. Allowed changes exist.
   3. Stage allowed files only.
   4. Create commit with `commit-message`.
   5. Emit `commitCreated=true` and `commitSha`.

2. Commit skipped flow:
   1. Stage disabled or no allowed changes.
   2. Do not create commit.
   3. Emit `commitCreated=false`.

3. Commit failure flow:
   1. Git staging or commit command fails.
   2. Stage returns `status=failed`.
   3. Runtime halts before pull request stage unless configured otherwise.

## APIs

### Base paths

- Action reference: `uses: iyaki/skills-update@<ref>`

### Endpoints (method, path, purpose)

| Method   | Path                                | Purpose                     |
| -------- | ----------------------------------- | --------------------------- |
| `INPUT`  | `with.create-commit`                | Enable/disable commit stage |
| `INPUT`  | `with.commit-message`               | Configure commit message    |
| `OUTPUT` | `steps.<id>.outputs.commit-created` | Whether commit was created  |
| `OUTPUT` | `steps.<id>.outputs.commit-sha`     | Commit SHA when created     |

### Auth requirements

- Requires `contents: write` when commit creation is enabled.

### Request/response payloads

Request example:

```yaml
with:
  create-commit: true
  commit-message: chore(skills): update installed skills
```

Response example:

```json
{
	"commitCreated": "true",
	"commitSha": "a1b2c3d4"
}
```

## Client SDK Design

- Consumers usually keep commit enabled.
- Disabling commit is intended for workflows where pull request stage handles commit generation.

## Configuration

| Key              | Default                                  | Description          |
| ---------------- | ---------------------------------------- | -------------------- |
| `create-commit`  | `true`                                   | Enables commit stage |
| `commit-message` | `chore(skills): update installed skills` | Commit title/message |

## Permissions

| Actor          | Resource            | Access | Notes                                 |
| -------------- | ------------------- | ------ | ------------------------------------- |
| Workflow token | Repository contents | write  | Required for git commit/push behavior |

## Security Considerations

- Stage only allowlisted files produced by update feature.
- Reject empty commits.
- Keep commit message configurable but non-executable.

## Dependencies

- `specs/features/update-feature.md`
- `specs/features/pull-request-feature.md`
- `git` CLI in runner environment.

## Open Questions / Risks

- Commit signing options are deferred to a future version.
- Exposing staged file lists as dedicated commit-stage output is deferred to a future version.

## Verifications

- Commit stage never runs when `create-commit=false`.
- Commit stage creates exactly one commit when enabled and changes exist.
- Commit stage never includes ignored or blocked files.
- `commitCreated=false` is emitted when there are no allowed changes.
- `commitSha` is emitted only when a commit is created.

## Appendices

- Compatibility notes:
  - Commit behavior remains additive under same major version.
- Future considerations:
  - Optional signed-commit support.
