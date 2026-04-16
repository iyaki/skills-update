# AI Driven Development Project Template

A practical starter template for builders using OpenCode and Ralph in a containerized Spec-Driven Development workflow.

This repository gives sensible defaults, guardrails, and batteries-included tooling so you can clone, open, and ship quickly.

## Why this template exists

- Standardize a fast, consistent AI-assisted workflow across local and CI.
- Make quality and security checks easy to adopt from day one.
- Provide a reusable baseline for building and shipping across different stacks.

## What you get out of the box

### 1) Dev environment defaults

- Devcontainer based on the universal image.
- Preinstalled tools/features:
  - OpenCode
  - Ralph
  - Lefthook (git hooks manager)
- VS Code extensions preconfigured:
  - OpenCode extension
  - EditorConfig
  - Gremlins (invisible-character detector)
- Host config mounts for OpenCode state and GitHub CLI config.
- Auto setup on initialize/post-create/post-start:
  - Creates local OpenCode and GH config directories if missing.
  - Installs git hooks via Lefthook.
  - Refreshes available OpenCode models.

### 2) Agent and workflow defaults

- OpenCode config includes a dedicated Ralph-compatible agent mode.
- Default Ralph loop settings:
  - max iterations set
  - logs enabled to logs/ralph.log
  - specs directory wired to specs/
  - OpenCode selected as agent backend
- Permission guardrails in OpenCode config to reduce risky edits.
  - Blocks bypass-style commit patterns (for example, no-verify commit flows).
  - Restricts editing sensitive paths like git internals, logs, and selected config files.
- Plugin defaults enabled for environment safety and quota visibility.
  - envsitter-guard
  - @slkiser/opencode-quota

### 3) MCP server integrations

The template includes preconfigured MCP entries you can enable/disable per project.
These are available for agent workflows through OpenCode configuration and compatible MCP-aware tooling in your workspace.

Enabled by default:

- Context7
- open-websearch with DuckDuckGo
- grep.app MCP
- gitmcp

Included but disabled by default:

- Scrapling via Docker
- Data Commons; requires DATACOMMONS_API_KEY
- async-bash-mcp

### 4) Skills included

This template ships with a curated starter skill set:

- code-search: Symbol lookup workflow using Repomix snapshots.
- dev-browser: Browser automation and UI verification using agent-browser.
- frontend-design: High-quality, production-grade frontend design guidance.
- reddit: Fetch/search subreddit posts and metadata through Reddit public JSON APIs.
- shell-command: Non-interactive shell execution strategy for agent reliability.
- skill-creator: Build and package new reusable skills.
- spec-creator: Generate technical specs compatible with Ralph workflows.

### 5) Repository defaults and quality baseline

- Editor and formatting standards via EditorConfig.
- Git hygiene defaults via .gitignore.
- Dependabot configured for:
  - Devcontainer updates
  - npm updates
- Dependabot auto-merge workflow included for minor updates.
- Security workflow template included for Semgrep (requires SEMGREP_APP_TOKEN secret).

### 6) Enabling automatic Dependabot merge

This template includes [.github/workflows/dependabot-automerge.yml](.github/workflows/dependabot-automerge.yml), but GitHub repository permissions must allow workflows to create and approve pull requests.

To enable it:

1. Open https://github.com/<user>/<repository>/settings/actions
2. Go to Workflow permissions
3. Enable Allow GitHub Actions to create and approve pull requests
4. Save changes

Without this setting, the workflow can run but will not be allowed to auto-merge Dependabot PRs.

### 7) Automatic template config sync

This template includes [.github/workflows/sync-template-files.yml](.github/workflows/sync-template-files.yml).

Behavior:

- Trigger: push to `main` (excluding pushes that only touch `templates/**`) or manual run with `workflow_dispatch`.
- Action: inspects changed root files and performs a 3-way merge into `templates/*/<same-path>` only when that target file already exists.
- Output: creates and pushes a `sync/*` branch with the updates, then opens a PR to `main`.
- Safety: if no effective changes are produced, no PR is created; if a merge conflict appears, the workflow fails for manual resolution.

## Sensible defaults checklist

This template intentionally defaults to:

- Containerized development first.
- Agent-assisted development with explicit permissions.
- Reproducible skill and tool setup.
- Automated dependency upkeep.
- Security scanning hooks ready to activate.
- Logs and specs wired for iterative AI loops.

## Quick start

1. Use this repository as a template and create your project repo.
2. Update the devcontainer name and this README for your project identity.
3. Open in VS Code Dev Containers / Codespaces.
4. Let post-create tasks complete.
5. Configure optional secrets and environment variables:
   - DATACOMMONS_API_KEY for Data Commons MCP
   - SEMGREP_APP_TOKEN for Semgrep workflow
6. Adjust AGENTS.md and OpenCode permissions to match your workflow and risk tolerance.

## Skills update marketplace action usage

Use the published action from workflow jobs with `uses: iyaki/skills-update@v1`.

Update-only run:

```yaml
- name: Update skills files only
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: false
    create-pr: false
```

Commit and pull request run:

```yaml
- name: Update skills and open PR
  id: skills
  uses: iyaki/skills-update@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    create-commit: true
    create-pr: true
    pr-generate-commit: true
```

## Marketplace action release operations

Use `.github/workflows/release-marketplace-action.yml` to publish immutable `vX.Y.Z` tags and move the `v1` major alias.

Pre-release checks:

1. Ensure the repository default branch is green.
2. Trigger `.github/workflows/smoke-marketplace-action.yml` with `scenario=all` and confirm success.
3. Verify workflow contract checks pass locally:

```sh
bash scripts/test-run-skill-update.sh
bash scripts/test-marketplace-workflows.sh
```

Release steps:

1. Open the Actions tab and run `release marketplace action`.
2. Set `release-tag` using `vX.Y.Z` format.
3. Confirm the workflow creates the immutable release tag and updates `v1`.
4. Verify release artifacts at:
   - `https://github.com/<owner>/<repo>/releases/tag/vX.Y.Z`
   - `https://github.com/<owner>/<repo>/releases/tag/v1`

Rollback strategy:

1. Do not retag the immutable `vX.Y.Z` release.
2. Move `v1` to the last known-good release tag:

```sh
git fetch --tags origin
git tag -f v1 <previous-vX.Y.Z>
git push origin refs/tags/v1 --force
```

3. Open a corrective pull request for root-cause fixes before publishing the next semver tag.

## Optional project setup paths

Scaffolding folders are provided under templates/:

- go/
- javascript/
- php/

You can add your own starter files, scripts, and language-specific conventions there.

To apply one of these stacks into an existing repository, use:

```sh
scripts/stack-setup.sh <template>
```

Stack guides:

- go: `templates/go/README.md`
- javascript: `templates/javascript/README.md`
- php: `templates/php/README.md`

## Recommended first customizations

- Rename the devcontainer project.
- Tailor AGENTS.md to your code review and coding standards.
- Configure lefthook rules with lint/test checks relevant to your stack.
- Enable additional CI workflows (tests, lint, build, release).
- Add a TDD-focused skill if your workflow relies on test-first development.

## Reference links

- OpenCode: https://opencode.ai/
- Ralph: https://github.com/iyaki/ralph
- Dependabot options: https://docs.github.com/github/administering-a-repository/configuration-options-for-dependency-updates
- Devcontainer Dependabot support: https://containers.dev/guide/dependabot
- Data Commons API keys: https://apikeys.datacommons.org/
- Semgrep CI: https://semgrep.dev/docs/semgrep-ci/
