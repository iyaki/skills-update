# Overview and Contract

Status: Proposed

## Overview

### Purpose

- Define the action-level contract for a reusable Marketplace Action that maintains agent skills.
- Split behavior into feature-specific specs to avoid duplicated implementation rules.
- Keep a single source of truth for shared inputs, outputs, and stage ordering.
- Align technical behavior with product terms defined in `specs/vision-and-goals.md`.

### Goals

- Keep the action consumable with `uses: iyaki/skills-update@v1`.
- Ensure update feature executes in every run.
- Support explicit commit and pull request features with safe defaults.
- Keep merge approval human-reviewed by default.

### Non-Goals

- Defining repository-specific cron schedules inside the action.
- Auto-merging pull requests.
- Duplicating feature-level logic in this overview spec.

### Scope

- In scope:
  - Shared contract and stage boundaries.
  - Shared input/output definitions.
  - Shared security and permission baseline.
- Out of scope:
- Detailed update, commit, or pull request implementation rules (defined in dedicated specs).

## Architecture

### Module/package layout (tree format)

```text
.
|- action.yml
|- scripts/
|  |- run-skill-update.sh
|- .github/workflows/
|  |- smoke-marketplace-action.yml
|  |- release-marketplace-action.yml
|- specs/
   |- overview-and-contract.md
   |- runtime-and-pr-flow.md
   |- features/
      |- update-feature.md
      |- commit-feature.md
      |- pull-request-feature.md
   |- release-and-verification.md
```

### Component diagram (ASCII)

```text
+-------------------------+
| Consumer Workflow       |
+------------+------------+
             |
             v
 +-----------------------+
 | Feature: Update       |  (always runs)
 +-----------+-----------+
             |
             v
 +-----------------------+
 | Feature: Commit       |  (optional)
 +-----------+-----------+
             |
             v
 +-----------------------+
 | Feature: Pull Request |  (optional, defaults to
 +-----------------------+   commit generation)
```

### Data flow summary

- The action normalizes inputs and executes stages in fixed order.
- `update` produces changed-file state consumed by `commit` and `pull request`.
- `pull request` can generate a commit by default when required.
- Outputs expose stage results for downstream workflow conditions.

## Data model

### Core Entities

- `ActionInput`: global configuration accepted by the action.
- `ActionOutput`: global outputs exposed by the action.
- `ExecutionState`: shared run state passed between features.

```ts
type ActionInput = {
	githubToken: string;
	workingDirectory: string;
	skillsCliVersion: string;
	updateCommand: string;
	addPaths: string[];
	ignorePaths: string[];
	createCommit: boolean;
	commitMessage: string;
	createPr: boolean;
	prGenerateCommit: boolean;
	baseBranch: string;
	prBranch: string;
	prTitle: string;
	prLabels: string[];
};

type ActionOutput = {
	changed: "true" | "false";
	updatedFiles: string; // output id: updated-files
	commitCreated: "true" | "false"; // output id: commit-created
	commitSha?: string; // output id: commit-sha
	pullRequestNumber?: string; // output id: pull-request-number
	pullRequestUrl?: string; // output id: pull-request-url
	branch: string;
};

type ExecutionState = {
	hasAllowedChanges: boolean;
	changedFiles: string[];
	commitSha?: string;
	pullRequestNumber?: string;
};
```

### Relationships

- `features/update-feature.md` defines `hasAllowedChanges` and `changedFiles`.
- `features/commit-feature.md` defines commit creation and `commitSha` production.
- `features/pull-request-feature.md` defines pull request creation and default commit generation behavior.
- `runtime-and-pr-flow.md` defines stage orchestration and failure propagation.

### Persistence Notes

- No database is required in v1.
- Durable state exists in Git commits/branches, pull request metadata, and workflow logs.

## Workflows

1. Standard execution:
   1. Normalize inputs.
   2. Run update stage (always).
   3. Run commit stage if enabled.
   4. Run pull request stage if enabled.
   5. Emit outputs.

2. No-change execution:
   1. Update reports no allowed changes.
   2. Commit and pull request stages are skipped.
   3. Action returns `changed=false`.

3. Error execution:
   1. Any stage failure stops the pipeline.
   2. Action exits non-zero.

## APIs

### Base paths

- Action reference: `uses: iyaki/skills-update@<ref>`

### Endpoints (method, path, purpose)

| Method   | Path                                  | Purpose                                        |
| -------- | ------------------------------------- | ---------------------------------------------- |
| `USES`   | `iyaki/skills-update@<ref>`           | Execute the action                             |
| `INPUT`  | `with.update-command`                 | Configure update behavior                      |
| `INPUT`  | `with.create-commit`                  | Enable or disable commit stage                 |
| `INPUT`  | `with.create-pr`                      | Enable or disable pull request stage           |
| `INPUT`  | `with.pr-generate-commit`             | Control pull request default commit generation |
| `OUTPUT` | `steps.<id>.outputs.commit-sha`       | Return commit SHA when created                 |
| `OUTPUT` | `steps.<id>.outputs.pull-request-url` | Return pull request URL when created/updated   |

### Auth requirements

- `contents: write` when commit and/or pull request stages may write branches.
- `pull-requests: write` when pull request stage is enabled.
- `contents: read` for read-only update runs.

### Request/response payloads

Request example:

```yaml
- name: Run skills maintenance
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: true
    create-pr: true
    pr-generate-commit: true
```

Response example:

```json
{
	"changed": "true",
	"updatedFiles": "skills-lock.json",
	"commitCreated": "true",
	"commitSha": "a1b2c3d4",
	"pullRequestNumber": "42",
	"pullRequestUrl": "https://github.com/acme/repo/pull/42",
	"branch": "chore/skills-update"
}
```

## Client SDK Design

- No language SDK is required; workflow YAML is the client integration surface.
- Feature-specific behavior is defined in:
  - `specs/features/update-feature.md`
  - `specs/features/commit-feature.md`
  - `specs/features/pull-request-feature.md`

## Configuration

| Input                | Type    | Default                              | Description                                      |
| -------------------- | ------- | ------------------------------------ | ------------------------------------------------ |
| `create-commit`      | boolean | `true`                               | Enables explicit commit stage                    |
| `create-pr`          | boolean | `true`                               | Enables pull request stage                       |
| `pr-generate-commit` | boolean | `true`                               | Pull request feature generates commit if missing |
| `add-paths`          | string  | `skills-lock.json,.agents/skills/**` | Allowed changed paths                            |
| `ignore-paths`       | string  | `.agents/.skill-lock.json`           | Ignored changed paths                            |

## Permissions

| Role           | Resource            | Access | Notes                                 |
| -------------- | ------------------- | ------ | ------------------------------------- |
| Workflow token | Repository contents | write  | Required for branch updates           |
| Workflow token | Pull requests       | write  | Required when pull request stage runs |
| Maintainer     | Default branch      | merge  | Human review gate                     |

## Security Considerations

- Enforce allowlist/ignore-path policy before write stages.
- Use least-privilege token permissions per enabled feature.
- Avoid logging sensitive file contents.

## Dependencies

- `specs/features/update-feature.md`
- `specs/features/commit-feature.md`
- `specs/features/pull-request-feature.md`
- `specs/runtime-and-pr-flow.md`
- `specs/release-and-verification.md`

## Open Questions / Risks

- Should `create-commit=false` and `create-pr=true` remain supported long-term?
- Should `pr-generate-commit` stay default-true for all future majors?
- Should outputs include explicit stage-level error codes?

## Verifications

- Every run executes update stage regardless of other flags.
- Commit stage creates commits only when enabled and changes exist.
- Pull request stage can create/update a pull request and return URL when enabled.
- Default pull request behavior can generate a commit when missing.
- Disabling both write stages produces a read-only run.

## Appendices

- Compatibility notes:
  - Contract evolves additively within the same major version.
- Future considerations:
  - Structured JSON output for policy engines.
