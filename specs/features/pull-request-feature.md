# Pull Request Feature

Status: Proposed

## Overview

### Purpose

- Define the optional pull request stage that opens or updates a single rolling pull request.
- Define the optional pull request stage that opens or updates a single rolling pull request.
- Specify default behavior where this feature can generate the commit when needed.
- Keep review and merge as explicit human-controlled steps.

### Goals

- Create or update exactly one pull request branch per repository by default.
- Default to commit generation when pull request stage is enabled and no prior commit exists.
- Expose pull request metadata outputs (`number`, `url`) for downstream automation.

### Non-Goals

- Auto-merge behavior.
- Multi-pull-request fan-out by skill source.
- Running update command logic.

### Scope

- In scope:
  - Branch and pull request lifecycle management.
  - Default commit generation coupling with pull request stage.
  - Pull request metadata output behavior.
- Out of scope:
  - CODEOWNERS/review policy configuration.
  - Branch protection policy administration.

## Architecture

### Module/package layout (tree format)

```text
.
|- action.yml
|- scripts/
|  |- run-skill-update.sh
|- specs/
   |- features/
      |- pull-request-feature.md
      |- commit-feature.md
      |- update-feature.md
```

### Component diagram (ASCII)

```text
+---------------------------+
| Receive execution state   |
+-------------+-------------+
              |
              v
+---------------------------+
| Ensure commit exists      |
| (default: generate commit)|
+-------------+-------------+
              |
              v
+---------------------------+
| Create/update rolling pull request |
+-------------+-------------+
              |
              v
+---------------------------+
| Emit pull request outputs |
+---------------------------+
```

### Data flow summary

- Pull request stage consumes update and optional commit stage results.
- If pull request stage is enabled and changes exist, it ensures a commit exists.
- It then creates or updates one pull request on configured branch/base.
- Pull request metadata is emitted to global outputs.

## Data model

### Core Entities

- `PullRequestFeatureInput`: pull request stage configuration and upstream execution state.
- `PullRequestFeatureResult`: pull request stage outcome and metadata.

```ts
type PullRequestFeatureInput = {
	enabled: boolean;
	prGenerateCommit: boolean;
	baseBranch: string;
	prBranch: string;
	prTitle: string;
	prLabels: string[];
	hasAllowedChanges: boolean;
	commitSha?: string;
};

type PullRequestFeatureResult = {
	status: "skipped" | "updated" | "failed";
	commitGeneratedByPr: boolean;
	commitSha?: string;
	pullRequestNumber?: string;
	pullRequestUrl?: string;
	failureReason?: string;
};
```

### Relationships

- `hasAllowedChanges` comes from `specs/features/update-feature.md`.
- Existing `commitSha` may come from `specs/features/commit-feature.md`.
- If `commitSha` is missing and `prGenerateCommit=true`, pull request stage can create commit before pull request update.
- Outputs map to `ActionOutput` fields in `specs/overview-and-contract.md`.

### Persistence Notes

- No database persistence required.
- Durable artifacts:
  - Branch commit updates.
  - Pull request state in GitHub.
- Optional schema reference (not required for v1):

| Table           | Column             | SQL Type      | Required | Notes                                         |
| --------------- | ------------------ | ------------- | -------- | --------------------------------------------- |
| `pr_stage_runs` | `run_id`           | `varchar(64)` | yes      | Workflow run identifier                       |
| `pr_stage_runs` | `status`           | `varchar(16)` | yes      | `skipped`, `updated`, `failed`                |
| `pr_stage_runs` | `pr_number`        | `integer`     | no       | Populated when pull request exists            |
| `pr_stage_runs` | `commit_generated` | `boolean`     | yes      | True when pull request stage generated commit |

## Workflows

1. Pull request stage default flow (enabled):
   1. Validate pull request inputs.
   2. If no allowed changes, skip stage.
   3. Ensure commit exists:
      - Use prior commit if present.
      - Otherwise generate commit when `pr-generate-commit=true` (default).
   4. Create or update pull request on `pr-branch` targeting `base-branch`.
   5. Emit pull request outputs.

2. Pull request stage skipped flow:
   1. `create-pr=false`, or no allowed changes.
   2. Stage returns `status=skipped`.

3. Pull request stage failure flow:
   1. Commit missing and `pr-generate-commit=false`.
   2. Pull request API operation fails.
   3. Stage returns `status=failed` and action exits non-zero.

## APIs

### Base paths

- Action reference: `uses: iyaki/skills-update@<ref>`

### Endpoints (method, path, purpose)

| Method   | Path                                     | Purpose                                                |
| -------- | ---------------------------------------- | ------------------------------------------------------ |
| `INPUT`  | `with.create-pr`                         | Enable/disable pull request stage                      |
| `INPUT`  | `with.pr-generate-commit`                | Enable default commit generation in pull request stage |
| `INPUT`  | `with.pr-branch`                         | Set rolling pull request branch                        |
| `INPUT`  | `with.base-branch`                       | Set pull request target branch                         |
| `INPUT`  | `with.pr-title`                          | Set pull request title                                 |
| `INPUT`  | `with.pr-labels`                         | Set pull request labels                                |
| `OUTPUT` | `steps.<id>.outputs.pull-request-number` | Return pull request number                             |
| `OUTPUT` | `steps.<id>.outputs.pull-request-url`    | Return pull request URL                                |

### Auth requirements

- Requires `contents: write` and `pull-requests: write` when enabled.

### Request/response payloads

Request example:

```yaml
with:
  create-pr: true
  pr-generate-commit: true
  pr-branch: chore/skills-update
  base-branch: main
  pr-title: chore(skills): update installed skills
```

Response example:

```json
{
	"pullRequestNumber": "42",
	"pullRequestUrl": "https://github.com/acme/repo/pull/42"
}
```

## Client SDK Design

- Consumers generally keep pull request stage enabled for Dependabot-like behavior.
- Consumers generally keep pull request stage enabled for Dependabot-like behavior.
- `pr-generate-commit` defaults to true to keep setup simple.
- Advanced workflows may disable pull request stage and consume update/commit outputs only.

## Configuration

| Key                  | Default                                  | Description                                      |
| -------------------- | ---------------------------------------- | ------------------------------------------------ |
| `create-pr`          | `true`                                   | Enables pull request stage                       |
| `pr-generate-commit` | `true`                                   | Pull request stage can create commit when absent |
| `pr-branch`          | `chore/skills-update`                    | Rolling branch name                              |
| `base-branch`        | repository default                       | Target branch                                    |
| `pr-title`           | `chore(skills): update installed skills` | Pull request title                               |
| `pr-labels`          | `chore,automation`                       | Pull request labels                              |

## Permissions

| Actor          | Resource            | Access | Notes                                        |
| -------------- | ------------------- | ------ | -------------------------------------------- |
| Workflow token | Repository contents | write  | Branch update and possible commit generation |
| Workflow token | Pull requests       | write  | Create/update pull request                   |
| Maintainer     | Default branch      | merge  | Human review and merge gate                  |

## Security Considerations

- Restrict pull request-generated commits to allowlisted files from update stage.
- Avoid exposing sensitive diffs in pull request body generation.
- Keep a single predictable branch to reduce branch sprawl and permission complexity.

## Dependencies

- `peter-evans/create-pull-request` (or equivalent pull request API integration).
- `specs/features/update-feature.md`
- `specs/features/commit-feature.md`

## Open Questions / Risks

- Should pull request stage allow custom branch naming templates in v1?
- Should commit generation in pull request stage be skippable only when explicit commit stage is enabled?
- Should pull request body include blocked/ignored path diagnostics?

## Verifications

- Pull request stage creates/updates exactly one pull request on configured branch when enabled.
- Pull request stage skips cleanly when disabled.
- With `pr-generate-commit=true`, pull request stage succeeds even when commit stage is disabled.
- With `pr-generate-commit=false`, missing commit causes deterministic failure.
- Pull request outputs are present only when a pull request exists.

## Appendices

- Compatibility notes:
  - Single rolling pull request behavior is the default and recommended mode.
- Future considerations:
  - Optional split pull request strategy per source repository.
