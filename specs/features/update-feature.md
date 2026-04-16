# Update Feature

Status: Proposed

## Overview

### Purpose

- Define the `update` feature that refreshes installed skills metadata and files.
- Guarantee this stage executes in every action run, independent of commit/pull request toggles.
- Produce canonical changed-file state consumed by later features.

### Goals

- Run `skills update` in project scope, non-interactive mode.
- Generate deterministic `changed` and `updated-files` outputs.
- Enforce path safety by allowlist and ignore-path policy.
- Fail early when blocked paths are modified.

### Non-Goals

- Creating commits or pull requests.
- Deciding merge strategy for generated changes.
- Managing global machine skill scope (`-g`).

### Scope

- In scope:
  - CLI execution and command-level error handling.
  - Diff collection and policy bucketing (`allowed`, `ignored`, `blocked`).
  - Emission of update-stage outputs.
- Out of scope:
  - Branch writes and pull request API operations.

## Architecture

### Module/package layout (tree format)

```text
.
|- action.yml
|- scripts/
|  |- run-skill-update.sh
|- specs/
   |- features/
      |- update-feature.md
      |- commit-feature.md
      |- pull-request-feature.md
```

### Component diagram (ASCII)

```text
+-------------------------+
| Normalize update input  |
+------------+------------+
             |
             v
+-------------------------+
| Run skills update       |
| npx skills@X update -p  |
+------------+------------+
             |
             v
+-------------------------+
| Collect git diff        |
+------------+------------+
             |
             v
+-------------------------+
| Apply path policy       |
| allowed/ignored/blocked |
+------------+------------+
             |
             v
+-------------------------+
| Publish update outputs  |
+-------------------------+
```

### Data flow summary

- Update input is derived from global `ActionInput`.
- The stage executes `update-command`, then inspects local workspace diff.
- Changed files are partitioned by allowlist and ignore rules.
- The stage emits `hasAllowedChanges`, `changedFiles`, and policy violations for downstream stages.

## Data model

### Core Entities

- `UpdateFeatureInput`: subset of global input used by update stage.
- `PathPolicyResult`: path buckets generated from diff analysis.
- `UpdateFeatureResult`: update-stage outcome consumed by runtime orchestration.

```ts
type UpdateFeatureInput = {
	workingDirectory: string;
	skillsCliVersion: string;
	updateCommand: string;
	addPaths: string[];
	ignorePaths: string[];
};

type PathPolicyResult = {
	allowed: string[];
	ignored: string[];
	blocked: string[];
};

type UpdateFeatureResult = {
	status: "no_change" | "updated" | "failed";
	changedFiles: string[];
	hasAllowedChanges: boolean;
	policy: PathPolicyResult;
	failureReason?: string;
};
```

### Relationships

- `UpdateFeatureInput` is created from `ActionInput` in `specs/overview-and-contract.md`.
- `UpdateFeatureResult` feeds `ExecutionState` for `features/commit-feature.md` and `features/pull-request-feature.md`.
- `policy.blocked.length > 0` forces action failure before write stages.

### Persistence Notes

- No database persistence is required.
- Temporary state exists in runner workspace during execution.
- Durable artifacts:
  - Modified files in workspace after successful update command.
  - Output values (`changed`, `updated-files`) in workflow logs.
- Optional schema reference (not required for v1):

| Table                | Column   | SQL Type      | Required | Notes                            |
| -------------------- | -------- | ------------- | -------- | -------------------------------- |
| `update_stage_runs`  | `run_id` | `varchar(64)` | yes      | Workflow run identifier          |
| `update_stage_runs`  | `status` | `varchar(16)` | yes      | `no_change`, `updated`, `failed` |
| `update_stage_files` | `run_id` | `varchar(64)` | yes      | FK to run                        |
| `update_stage_files` | `path`   | `text`        | yes      | Workspace relative path          |
| `update_stage_files` | `bucket` | `varchar(16)` | yes      | `allowed`, `ignored`, `blocked`  |

## Workflows

1. Standard update flow (always executes):
   1. Normalize update inputs.
   2. Execute `update-command` in working directory.
   3. Collect modified files from Git diff.
   4. Apply path policy.
   5. Emit outputs for downstream stages.

2. No-change flow:
   1. Update command succeeds.
   2. No `allowed` files are produced.
   3. Stage returns `status=no_change`.

3. Blocked-path flow:
   1. Update command succeeds.
   2. One or more `blocked` files are detected.
   3. Stage returns `status=failed` and runtime halts.

4. Command failure flow:
   1. Update command exits non-zero.
   2. Stage returns `status=failed`.
   3. Commit and pull request stages are skipped.

## APIs

### Base paths

- Action invocation: `uses: iyaki/skills-update@<ref>`
- Working directory: `with.working-directory` (default `.`)

### Endpoints (method, path, purpose)

| Method   | Path                               | Purpose                         |
| -------- | ---------------------------------- | ------------------------------- |
| `INPUT`  | `with.skills-cli-version`          | Pin `skills` CLI version        |
| `INPUT`  | `with.update-command`              | Override default update command |
| `INPUT`  | `with.add-paths`                   | Define allowed changed paths    |
| `INPUT`  | `with.ignore-paths`                | Define ignored paths            |
| `OUTPUT` | `steps.<id>.outputs.changed`       | Flag update-stage changes       |
| `OUTPUT` | `steps.<id>.outputs.updated-files` | Newline list of allowed files   |

### Auth requirements

- Requires repository checkout access.
- No GitHub write API permissions are required for update stage itself.

### Request/response payloads

Request example:

```yaml
- name: Run update stage
  id: skills
  uses: iyaki/skills-update@v1
  with:
    skills-cli-version: 0.11.0
    update-command: npx --yes skills@0.11.0 update -p -y
    add-paths: skills-lock.json,.agents/skills/**
    ignore-paths: .agents/.skill-lock.json
```

Response example:

```json
{
	"changed": "true",
	"updatedFiles": "skills-lock.json\n.agents/skills/spec-creator/SKILL.md"
}
```

## Client SDK Design

- No language SDK; configuration is done via workflow inputs.
- Typical usage keeps default update command and only overrides CLI version.
- Downstream workflow steps can branch on `changed` output.

## Configuration

| Key                  | Default                              | Description                   |
| -------------------- | ------------------------------------ | ----------------------------- |
| `skills-cli-version` | pinned semver                        | Version for `skills` CLI      |
| `update-command`     | `npx --yes skills@<v> update -p -y`  | Update execution command      |
| `add-paths`          | `skills-lock.json,.agents/skills/**` | Allowlist for changed files   |
| `ignore-paths`       | `.agents/.skill-lock.json`           | Ignore list for changed files |
| `CI`                 | `1`                                  | Non-interactive mode          |
| `DISABLE_TELEMETRY`  | `1`                                  | Disable telemetry             |
| `DO_NOT_TRACK`       | `1`                                  | Disable telemetry alternative |
| `TZ`                 | `UTC`                                | Deterministic timestamps      |

## Permissions

| Actor          | Resource            | Access     | Notes                               |
| -------------- | ------------------- | ---------- | ----------------------------------- |
| Action runtime | Workspace files     | read/write | Update command modifies local files |
| Workflow token | Repository contents | read       | Sufficient for update-only dry-runs |

## Security Considerations

- Validate paths as workspace-relative and reject traversal patterns.
- Do not log full contents of changed files.
- Treat `update-command` as trusted-maintainer configuration.
- Fail closed on blocked-path detection.

## Dependencies

- `vercel-labs/skills` CLI.
- `git` diff capabilities on runner.
- `specs/overview-and-contract.md`.

## Open Questions / Risks

- Should strict mode fail when ignored paths are changed?
- Should update stage expose blocked paths as structured JSON output?
- Should retries be added for transient network failures when downloading CLI package?

## Verifications

- Update stage executes on every run, independent of commit/pull request flags.
- `changed=false` is emitted when no allowed files changed.
- Blocked path detection fails the run before write stages.
- `.agents/.skill-lock.json` is excluded from `updated-files` by default.
- Non-interactive command completes without prompts in CI.

## Appendices

- Compatibility notes:
  - Designed for project scope (`skills update -p`).
- Future considerations:
  - Optional machine-readable policy report output.
