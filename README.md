<!--
  SEO Keywords: github action, skills update, AI agent automation, Vercel Skills CLI, continuous integration, workflow automation, agent skills management, GitHub Marketplace, CI/CD automation, dependabot alternative
  Marketplace Categories: Continuous integration (primary), Code review (secondary)
  Target Audience: GitHub users implementing AI agents, teams using Vercel Skills, automation engineers, Dependabot users seeking agent skill automation
-->
<div align="center">

# Skills Update Action

<h3 align="center">GitHub Action for Automated AI Agent Skills Management</h3>

[![GitHub Marketplace](https://img.shields.io/badge/GitHub%20Marketplace-skills--update-blue?logo=github)](https://github.com/marketplace?type=actions&query=skills+update)
[![Smoke Tests](https://img.shields.io/github/actions/workflow/status/iyaki/skills-update/smoke-marketplace-action.yml?label=smoke%20tests)](https://github.com/iyaki/skills-update/actions/workflows/smoke-marketplace-action.yml)
[![Latest Release](https://img.shields.io/github/v/release/iyaki/skills-update?label=latest%20release)](https://github.com/iyaki/skills-update/releases)

Keep your repository's AI agent skills automatically up to date—like Dependabot for agent skills. This GitHub Action automates Vercel's Skills CLI updates with safe commit and pull request workflows.


## Frequently Asked Questions

### What is the Skills Update GitHub Action?

Skills Update Action is for AI agent skills. Like Dependabot scans for dependency updates, this action integrates with Vercel's Skills CLI to keep your AI agent skills current. It runs scheduled updates, enforces path safety policies, and can automatically create commits and pull requests for review.

### How does this action work with AI agents?

The action wraps Vercel's Skills CLI, executing non-interactive update commands in CI/CD pipelines. It detects changed skill files, validates them against your allowlist, and manages the git workflow for human review.

### How is this different from Dependabot?

Dependabot updates your **code dependencies** (npm packages, Python libraries, etc.), while Skills Update handles your **AI agent skills** (context files, knowledge bases, system prompts). Same automation pattern—scheduled scans, path validation, safe commits and PRs—but applied to agent configuration instead of package versions.

### Is this action safe for production use?

Yes. The action implements a "fail-closed" safety model: it rejects any changes outside your explicitly allowlisted paths before making commits or PRs. This ensures only approved files are modified.

### What workflows does this action support?

- **Read-only**: Run updates without making changes
- **Commit-only**: Create commits without opening pull requests
- **Rolling PR**: Maintain a single updating pull request for continuous review
- **Custom command**: Provide your own update command for full control

### How do I get started with skills-update?

Add the workflow to your `.github/workflows` directory with a weekly schedule. Configure your path allowlist and permissions, then let the action handle skills maintenance automatically.

[Get started](#get-started) • [How it works](#how-it-works) • [Inputs](#inputs) • [Outputs](#outputs) • [Recipes](#recipes) • [Validation](#validation)

</div>

## How does the skills-update action work?

The action executes a four-stage workflow with comprehensive path safety enforcement:

1. Runs the update stage in `working-directory`
2. Collects and classifies changed files as `allowed`, `ignored`, or `blocked`
3. Fails before any write stage if a blocked path changed
4. Creates a commit (when enabled) and updates a rolling pull request
> The action fails closed when the update command changes files outside your allowlisted paths.

> [!NOTE]
> The default flow is human-reviewed automation: update files, optionally commit them, and optionally keep one rolling PR up to date. It does not auto-merge.

## Get started
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
      - name: Checkout repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Update skills and open pull request
        id: skills
        uses: iyaki/skills-update@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

You can omit `github-token` if the default `github.token` has the permissions you need.

> [!TIP]
> Use `@v1` for the stable major line. Pin to `@vX.Y.Z` when you need an immutable release.

## How does the Skills Update workflow execute?

The workflow runs in five sequential stages with path safety validation at each step:

1. Runs the update stage in `working-directory`
2. Collects changed files and classifies them as `allowed`, `ignored`, or `blocked`
3. Fails the run before any write stage if a blocked path changed
4. Creates a commit when `create-commit=true` and allowed changes exist
5. Creates or updates a single rolling pull request when `create-pr=true`

### What is the path safety policy?

- `allowed`: files that may be committed and included in the PR.
- `ignored`: files that do not fail the run and are excluded from write stages.
- `blocked`: files that fail the run immediately.

### Behavior notes

- The update stage always runs.
- If `update-command` is empty, the action uses `npx --yes skills@<skills-cli-version> experimental_install -y`.
- `working-directory` must exist and be inside a git repository.

> [!IMPORTANT]
> Keep `add-paths` narrow and explicit. Avoid broad globs that could permit unintended writes.

## What inputs does the skills-update action accept?

All inputs are optional and configurable through your workflow file.

### General

| Input                | Default                              | Description                                                                                           |
| -------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| `github-token`       | `github.token`                       | Token used for commit, push, and PR operations.                                                       |
| `working-directory`  | `.`                                  | Directory where update and git operations run.                                                        |
| `skills-cli-version` | `latest`                             | Version used in the default update command.                                                           |
| `update-command`     | `""`                                 | Custom non-interactive update command. When omitted, the action uses the default command shown above. |
| `add-paths`          | `skills-lock.json,.agents/skills/**` | Comma-separated globs for files that are allowed to change.                                           |
| `ignore-paths`       | `.agents/.skill-lock.json`           | Comma-separated globs for files that are ignored and excluded from write stages.                      |

### Commit

| Input            | Default                                  | Description                           |
| ---------------- | ---------------------------------------- | ------------------------------------- |
| `create-commit`  | `true`                                   | Enables the commit stage.             |
| `commit-message` | `chore(skills): update installed skills` | Commit message for generated commits. |

### Pull request

| Input         | Default                                  | Description                                            |
| ------------- | ---------------------------------------- | ------------------------------------------------------ |
| `create-pr`   | `true`                                   | Enables the pull request stage.                        |
| `base-branch` | repository default                       | Target branch for the PR.                              |
| `pr-branch`   | `chore/skills-update`                    | Branch used for the rolling pull request.              |
| `pr-title`    | `chore(skills): update installed skills` | Title used when creating or updating the pull request. |
| `pr-labels`   | `chore,automation`                       | Comma-separated labels applied to the pull request.    |

## Outputs

## What outputs does the action provide for workflow integration?

All outputs are strings and can be used in downstream workflow steps.

| Output                | Description                                                                       |
| --------------------- | --------------------------------------------------------------------------------- |
| `changed`             | `true` when at least one allowlisted file changed, otherwise `false`.             |
| `updated-files`       | Newline-delimited list of allowlisted changed files.                              |
| `commit-created`      | `true` when this run created a commit.                                            |
| `commit-sha`          | Commit SHA when a commit was created.                                             |
| `pull-request-number` | Pull request number when a PR exists.                                             |
| `pull-request-url`    | Pull request URL when a PR exists.                                                |
| `branch`              | The configured `pr-branch` when PR mode is enabled, otherwise the current branch. |

## What are common usage recipes and examples?

### Update only (no branch writes)

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
- name: Update skills and create a commit
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: true
    create-pr: false
```

### Rolling PR maintenance

```yaml
- name: Update skills and open or refresh a PR
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: true
    create-pr: true
    pr-branch: chore/skills-update
    pr-title: "chore(skills): update installed skills"
    pr-labels: chore,automation
```

### Use a custom update command

```yaml
- name: Run a pinned update command
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    update-command: npx --yes skills@1.2.3 experimental_install -y
    create-commit: false
    create-pr: false
```

### Restrict writable paths

```yaml
- name: Update skills with a strict path policy
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    add-paths: skills-lock.json,.agents/skills/**
    ignore-paths: .agents/.skill-lock.json
```

## Permissions

- Update-only runs: `contents: read`
- Commit creation or branch updates: `contents: write`
- Pull request creation or labeling: `pull-requests: write`

```yaml
permissions:
  contents: write
  pull-requests: write
```

## How do I verify the action is working correctly?

Use these verification and diagnostics commands:

- Runtime smoke tests: `bash scripts/test-run-skill-update.sh`
- Workflow and README contract checks: `bash scripts/test-marketplace-workflows.sh`
- Script syntax checks: `bash -n scripts/run-skill-update.sh`
- Failed workflow logs: `gh run view <run-id> --log-failed`

## What is the release model and versioning strategy?

The action follows semantic versioning with stable major version tags:
- Releases are published as immutable `vX.Y.Z` tags.
- The release workflow moves the `v1` tag after smoke and contract checks pass.
- Pin to a full tag when you need immutable behavior across regulated or tightly controlled environments.
