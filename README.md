# Skills Update Action

[![GitHub Marketplace](https://img.shields.io/badge/GitHub%20Marketplace-skills--update-blue?logo=github)](https://github.com/marketplace?type=actions&query=skills+update)
[![Smoke Tests](https://img.shields.io/github/actions/workflow/status/iyaki/skills-update/smoke-marketplace-action.yml?label=smoke%20tests)](https://github.com/iyaki/skills-update/actions/workflows/smoke-marketplace-action.yml)
[![Latest Release](https://img.shields.io/github/v/release/iyaki/skills-update?label=latest%20release)](https://github.com/iyaki/skills-update/releases)

Keep your repository agent skills up to date with a single GitHub Action.

`iyaki/skills-update` runs skill updates, enforces path safety, and can optionally create a commit and maintain a rolling pull request for human review.

## Why use this action

- Runs skill maintenance in CI with non-interactive defaults.
- Limits writes to allowlisted paths and blocks unexpected file changes.
- Supports update-only, commit-only, and commit+PR workflows.
- Emits outputs you can use for workflow branching and notifications.
- Designed for predictable, human-reviewed automation.

## Marketplace usage

```yaml
name: update agent skills

on:
  schedule:
    - cron: "0 9 * * 1"
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Update skills
        id: skills
        uses: iyaki/skills-update@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input                | Required | Default                                  | Description                                                                                                        |
| -------------------- | -------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `github-token`       | yes      | n/a                                      | Token used for repository and pull request write operations.                                                       |
| `working-directory`  | no       | `.`                                      | Directory where update and git operations run.                                                                     |
| `skills-cli-version` | no       | `latest`                                 | Version of the skills CLI used by default update command.                                                          |
| `update-command`     | no       | `""`                                     | Custom non-interactive update command. If empty, action uses `npx --yes skills@<version> experimental_install -y`. |
| `add-paths`          | no       | `skills-lock.json,.agents/skills/**`     | Comma-separated allowlist globs for changed files.                                                                 |
| `ignore-paths`       | no       | `.agents/.skill-lock.json`               | Comma-separated ignore globs excluded from write stages.                                                           |
| `create-commit`      | no       | `true`                                   | Enables commit stage.                                                                                              |
| `commit-message`     | no       | `chore(skills): update installed skills` | Commit message used for generated commits.                                                                         |
| `create-pr`          | no       | `true`                                   | Enables pull request stage.                                                                                        |
| `pr-generate-commit` | no       | `true`                                   | Allows PR stage to generate commit if none exists yet.                                                             |
| `base-branch`        | no       | `""`                                     | Pull request base branch. If empty, repository default branch is used.                                             |
| `pr-branch`          | no       | `chore/skills-update`                    | Branch used for rolling pull request updates.                                                                      |
| `pr-title`           | no       | `chore(skills): update installed skills` | Title used when creating/updating pull request.                                                                    |
| `pr-labels`          | no       | `chore,automation`                       | Comma-separated labels added to pull request.                                                                      |

## Outputs

| Output                | Description                                             |
| --------------------- | ------------------------------------------------------- |
| `changed`             | `true` if allowlisted files changed, otherwise `false`. |
| `updated-files`       | Newline-delimited allowlisted changed files.            |
| `commit-created`      | `true` if a commit was created in this run.             |
| `commit-sha`          | Commit SHA when commit was created.                     |
| `pull-request-number` | Pull request number when PR exists.                     |
| `pull-request-url`    | Pull request URL when PR exists.                        |
| `branch`              | Branch used for commit/PR stages.                       |

## Common recipes

### Update only (no writes)

```yaml
- name: Update skills files only
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: false
    create-pr: false
```

### Create commit only

```yaml
- name: Update skills and commit
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: true
    create-pr: false
```

### Rolling PR maintenance

```yaml
- name: Update skills and open/update PR
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: true
    create-pr: true
    pr-generate-commit: true
    pr-branch: chore/skills-update
    pr-title: "chore(skills): update installed skills"
    pr-labels: chore,automation
```

### Restrict writable paths

```yaml
- name: Update skills with strict path policy
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    add-paths: skills-lock.json,.agents/skills/**
    ignore-paths: .agents/.skill-lock.json
```

## Permissions

- Minimum for update-only runs: `contents: read`
- For commit and PR stages: `contents: write`
- For PR creation/labeling: `pull-requests: write`

Example:

```yaml
permissions:
  contents: write
  pull-requests: write
```

## Behavior notes

- The update stage always runs.
- Changed files are split into `allowed`, `ignored`, and `blocked` buckets.
- Any blocked file change fails the run before commit/PR stages.
- Ignored files do not fail the run and are excluded from write stages.
- If `create-pr=true` and no commit exists, PR stage can create one when `pr-generate-commit=true`.

## Security and safety

- Keep `add-paths` narrow and explicit.
- Avoid broad globs that could permit unintended writes.
- Use GitHub-provided `GITHUB_TOKEN` unless you need custom scopes.
- Review generated pull requests before merge.

## Verification and diagnostics

- Run the runtime test suite locally:

```sh
bash scripts/test-run-skill-update.sh
```

- Run workflow contract checks locally:

```sh
bash scripts/test-marketplace-workflows.sh
```

- Inspect failed workflow logs:

```sh
gh run view <run-id> --log-failed
```

## Versioning

- Use `@v1` for stable major-version updates.
- Pin to a full tag (`@vX.Y.Z`) when you need immutable behavior for regulated environments.

## License

MIT
