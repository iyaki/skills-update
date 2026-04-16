# Runtime and Pull Request Flow

Status: Proposed

## Overview

### Purpose

- Define stage orchestration for the action without duplicating feature internals.
- Specify how update, commit, and pull request stages are chained, skipped, or failed.
- Provide deterministic execution and output propagation rules.

### Goals

- Keep stage ordering stable and explicit.
- Make feature toggles predictable and composable.
- Keep failure behavior fail-fast with clear diagnostics.

### Non-Goals

- Re-defining detailed behavior from feature-specific specs.
- Release/tagging policy details.

### Scope

- In scope:
  - Stage sequencing and transition conditions.
  - Global error handling and output finalization.
- Out of scope:
  - Update/commit/pull request implementation details.

## Architecture

### Module/package layout (tree format)

```text
.
|- action.yml
|- scripts/
|  |- run-skill-update.sh
|- specs/
   |- runtime-and-pr-flow.md
   |- features/
      |- update-feature.md
      |- commit-feature.md
      |- pull-request-feature.md
```

### Component diagram (ASCII)

```text
+-------------------+
| normalize_input   |
+---------+---------+
          |
          v
+-------------------+
| update_stage      |  always
+---------+---------+
          |
          v
+-------------------+
| commit_stage      |  optional
+---------+---------+
          |
          v
+-------------------+
| pr_stage          |  optional, defaults to
+---------+---------+  commit generation
          |
          v
+-------------------+
| finalize_outputs  |
+-------------------+
```

### Data flow summary

- Runtime receives `ActionInput` and initializes `ExecutionState`.
- Update stage runs first and always.
- Commit stage runs if enabled and update allows progression.
- Pull request stage runs if enabled and update allows progression.
- Finalization step maps accumulated state to `ActionOutput`.

## Data model

### Core Entities

- `RunPhase`: orchestration phase name.
- `PhaseResult`: per-phase execution result.
- `RuntimeResult`: aggregated run result for output mapping.

```ts
type RunPhase =
	| "normalize_input"
	| "update_stage"
	| "commit_stage"
	| "pull_request_stage"
	| "finalize_outputs";

type PhaseResult = {
	phase: RunPhase;
	status: "ok" | "skipped" | "failed";
	details?: string;
};

type RuntimeResult = {
	phases: PhaseResult[];
	failedPhase?: RunPhase;
};
```

### Relationships

- Update-stage definitions are in `specs/features/update-feature.md`.
- Commit-stage definitions are in `specs/features/commit-feature.md`.
- Pull request stage definitions are in `specs/features/pull-request-feature.md`.
- Shared input/output and state contracts are in `specs/overview-and-contract.md`.

### Persistence Notes

- Runtime state is ephemeral and stored in-memory within the workflow execution.
- Durable artifacts are produced by feature stages (commits, pull request metadata).

## Workflows

1. Happy path:
   1. Normalize inputs.
   2. Run update stage.
   3. Run commit stage when enabled.
   4. Run pull request stage when enabled.
   5. Finalize outputs and exit success.

2. No-change path:
   1. Update stage reports no allowed changes.
   2. Commit and pull request stages skip.
   3. Finalization emits `changed=false`.

3. Failure path:
   1. Any phase returns `failed`.
   2. Runtime marks `failedPhase`.
   3. Finalization emits available diagnostics and exits non-zero.

## APIs

### Base paths

- Action invocation: `uses: iyaki/skills-update@<ref>`

### Endpoints (method, path, purpose)

| Method   | Path                                  | Purpose                                     |
| -------- | ------------------------------------- | ------------------------------------------- |
| `INPUT`  | `with.create-commit`                  | Control commit phase execution              |
| `INPUT`  | `with.create-pr`                      | Control pull request phase execution        |
| `INPUT`  | `with.pr-generate-commit`             | Control pull request-side commit generation |
| `OUTPUT` | `steps.<id>.outputs.changed`          | Global changed signal                       |
| `OUTPUT` | `steps.<id>.outputs.commit-created`   | Commit phase result                         |
| `OUTPUT` | `steps.<id>.outputs.pull-request-url` | Pull request phase result                   |

### Auth requirements

- Runtime requires only the permissions required by enabled feature stages.

### Request/response payloads

Request example:

```yaml
with:
  create-commit: false
  create-pr: true
  pr-generate-commit: true
```

Response example:

```json
{
	"changed": "true",
	"commitCreated": "true",
	"pullRequestUrl": "https://github.com/acme/repo/pull/42"
}
```

## Client SDK Design

- No SDK required.
- Consumers interact by toggling stage flags and reading outputs.

## Configuration

| Key                  | Default | Description                                     |
| -------------------- | ------- | ----------------------------------------------- |
| `create-commit`      | `true`  | Enable commit phase                             |
| `create-pr`          | `true`  | Enable pull request phase                       |
| `pr-generate-commit` | `true`  | Let pull request phase create commit if missing |

## Permissions

| Phase                | Minimum permissions                       |
| -------------------- | ----------------------------------------- |
| `update_stage`       | `contents: read`                          |
| `commit_stage`       | `contents: write`                         |
| `pull_request_stage` | `contents: write`, `pull-requests: write` |

## Security Considerations

- Execute only enabled phases and avoid unnecessary write scopes.
- Ensure fail-fast behavior prevents partial unsafe writes after policy failures.

## Dependencies

- `specs/overview-and-contract.md`
- `specs/features/update-feature.md`
- `specs/features/commit-feature.md`
- `specs/features/pull-request-feature.md`

## Open Questions / Risks

- Should runtime support soft-fail mode for optional phases in future releases?
- Should runtime emit machine-readable phase traces as official outputs?

## Verifications

- Update stage always runs first.
- Commit and pull request stages honor feature flags.
- Pull request stage can generate commit by default when commit stage is disabled.
- Phase failures stop downstream phases.
- Final outputs reflect stage outcomes consistently.

## Appendices

- Future considerations:
  - Rich phase telemetry output for observability dashboards.
