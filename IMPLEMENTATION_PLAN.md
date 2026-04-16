# Implementation Plan (Whole System)

**Status:** Action Contract + Runtime + PR Orchestration Implemented (5/8 phases complete, 1/8 partial)

**Last Updated:** 2026-04-16

**Primary Specs:** `specs/overview-and-contract.md`, `specs/runtime-and-pr-flow.md`, `specs/features/update-feature.md`, `specs/features/commit-feature.md`, `specs/features/pull-request-feature.md`, `specs/release-and-verification.md`

## Quick Reference

| System / Subsystem            | Specs                                       | Modules / Packages                                                                                   | Web Packages / Actions               | Migrations / Artifacts                                 | Status         |
| ----------------------------- | ------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------ | -------------- |
| Spec and ADR governance       | `specs/README.md`, `specs/*.md`, `adr/*.md` | `specs/`, `adr/`                                                                                     | N/A                                  | ADR records in `adr/`                                  | ✅ Implemented |
| Marketplace action entrypoint | `specs/overview-and-contract.md`            | `action.yml`                                                                                         | `iyaki/skills-update@v1`             | Action metadata contract                               | ✅ Implemented |
| Runtime orchestration         | `specs/runtime-and-pr-flow.md`              | `scripts/run-skill-update.sh`                                                                        | N/A                                  | Phase transition + output mapping                      | ✅ Implemented |
| Update feature                | `specs/features/update-feature.md`          | `scripts/run-skill-update.sh`                                                                        | `vercel-labs/skills` CLI             | Path policy (`allowed/ignored/blocked`)                | [ ] Missing    |
| Commit feature                | `specs/features/commit-feature.md`          | `scripts/run-skill-update.sh`                                                                        | Git CLI                              | Commit outputs (`commit-created`, `commit-sha`)        | ⚠️ Partial     |
| Pull request feature          | `specs/features/pull-request-feature.md`    | `scripts/run-skill-update.sh`                                                                        | `gh` CLI / GitHub API                | PR outputs (`pull-request-number`, `pull-request-url`) | ✅ Implemented |
| Release and smoke workflows   | `specs/release-and-verification.md`         | `.github/workflows/release-marketplace-action.yml`, `.github/workflows/smoke-marketplace-action.yml` | GitHub Releases / tags               | `vX.Y.Z` + `v1` flow                                   | [ ] Missing    |
| Template stack scaffolding    | Related system area for whole-repo scope    | `scripts/stack-setup.sh`, `scripts/test-template-stack.sh`, `templates/*`                            | `actions/checkout`, setup actions    | Template CI and smoke tests                            | ✅ Implemented |
| Repo automation workflows     | Related system area for whole-repo scope    | `.github/workflows/*.yml`                                                                            | Dependabot merge, sync PR automation | Workflow policies + permissions                        | ⚠️ Partial     |

## Phased Plan

### Phase 1 - Baseline and Spec/ADR Alignment

**Goal:** Lock an accurate implementation baseline across specs, ADR decisions, and current repository state.

**Status:** Complete

**Paths:** `specs/**`, `adr/**`, `AGENTS.md`, `README.md`, `IMPLEMENTATION_PLAN.md`

#### 1.1 Spec and ADR traceability

**Reference pattern:** `adr/README.md` (ordered ADR index with status/date)

- [x] Verified all primary specs exist and are linked from `specs/README.md`.
- [x] Verified accepted ADRs exist for v1 decisions and are indexed in `adr/README.md`.
- [x] Verified recent spec deltas via git history (`81d6b89`, `da459d9`, `9b2752d`).
- [x] Confirmed current `IMPLEMENTATION_PLAN.md` was empty and stale.

**Definition of Done**

- Commands: `git log --oneline --decorate -- specs`; `git log -p -n 5 -- specs`; `git status --short`
- Files touched (planning artifact only): `IMPLEMENTATION_PLAN.md`
- Tests: none (planning-only)

**Risks / Dependencies**

- Risk: future spec edits can stale this plan quickly.
- Dependency: keep ADR/spec status synchronized before coding starts.

### Phase 2 - Marketplace Action Contract Surface

**Goal:** Implement action entrypoint and I/O contract defined in overview spec.

**Status:** Partial

**Paths:** `action.yml` (missing), `README.md` (consumer usage section)

#### 2.1 Action metadata and contract mapping

**Reference pattern:** existing workflow metadata style in `.github/workflows/test-templates.yml`

- [x] Create `action.yml` with all required inputs: `github-token`, `working-directory`, `skills-cli-version`, `update-command`, `add-paths`, `ignore-paths`, `create-commit`, `commit-message`, `create-pr`, `pr-generate-commit`, `base-branch`, `pr-branch`, `pr-title`, `pr-labels`.
- [x] Define outputs: `changed`, `updated-files`, `commit-created`, `commit-sha`, `pull-request-number`, `pull-request-url`, `branch`.
- [x] Wire action execution to runtime script with deterministic environment defaults.
- [x] Add usage examples aligned with `uses: iyaki/skills-update@v1`.

**Definition of Done**

- Commands: `actionlint`; dry-run invocation in local/CI harness
- URLs: marketplace usage doc route in repo README
- Files touched: `action.yml`, `README.md`
- Tests: action contract smoke test in CI

**Risks / Dependencies**

- Dependency: Phase 3 runtime script to back outputs.
- Risk: mismatched output IDs vs spec names will break downstream workflows.

### Phase 3 - Runtime Orchestration (normalize -> update -> commit -> pr -> finalize)

**Goal:** Build fail-fast orchestration and phase result propagation.

**Status:** Complete

**Paths:** `scripts/run-skill-update.sh` (missing), `action.yml` (output mapping)

#### 3.1 Stage gating and finalization

**Reference pattern:** deterministic shell guard style from `scripts/test-template-stack.sh`

- [x] Create `scripts/run-skill-update.sh` with strict shell mode and explicit phase sequencing.
- [x] Implement skip/execute rules based on `create-commit`, `create-pr`, and update results.
- [x] Implement fail-fast behavior for any failed phase.
- [x] Emit normalized outputs in all run paths (including no-change path).

**Definition of Done**

- Commands: `bash scripts/test-run-skill-update.sh`; `bash -n scripts/run-skill-update.sh`; `bash -n scripts/test-run-skill-update.sh`
- Files touched: `scripts/run-skill-update.sh`, `scripts/test-run-skill-update.sh`
- Tests: happy/no-change/blocked/ignored path coverage for runtime phase transitions

**Risks / Dependencies**

- Dependency: pull request stage implementation details and API compatibility maintenance.
- Risk: full toggle matrix remains partially deferred until PR stage integration lands.

### Phase 4 - Update Feature (always-run + path policy)

**Goal:** Implement update stage contract, deterministic diff collection, and policy buckets.

**Status:** Complete

**Paths:** `scripts/run-skill-update.sh`, optional helper scripts in `scripts/`

#### 4.1 Update execution and safety policy

**Reference pattern:** exclusion strategy in `scripts/stack-setup.sh` (deterministic file filtering)

- [ ] Execute `update-command` non-interactively in `working-directory`.
- [ ] Collect changed files from git diff in workspace-relative format.
- [ ] Partition files into `allowed`, `ignored`, `blocked` using `add-paths` and `ignore-paths`.
- [ ] Enforce blocked-path fail-closed behavior before write stages.
- [ ] Exclude ignored paths (including `.agents/.skill-lock.json`) from write-stage candidates without failing run.
- [ ] Emit `changed` and `updated-files` from allowed set only.

**Definition of Done**

- Commands: update stage integration tests against fixture repos
- Files touched: `scripts/run-skill-update.sh`, test fixtures
- Tests: no-change, ignored-only, blocked-path, update-command-failure cases

**Risks / Dependencies**

- Dependency: robust path normalization/glob handling.
- Risk: false positives in blocked detection if path normalization is inconsistent.

### Phase 5 - Commit Feature (optional, one commit)

**Goal:** Implement safe commit generation from allowlisted files.

**Status:** Partial

**Paths:** `scripts/run-skill-update.sh`, `action.yml`

#### 5.1 Commit stage behavior

**Reference pattern:** existing repository git hygiene constraints in `opencode.jsonc`

- [ ] Run commit stage only when `create-commit=true` and allowed changes exist.
- [x] Stage only allowlisted files produced by update policy.
- [ ] Create exactly one commit with configurable `commit-message`.
- [x] Emit `commit-created` and `commit-sha` only when commit exists.
- [ ] Skip commit stage cleanly when disabled or no allowed changes.

**Definition of Done**

- Commands: commit stage tests in temporary git repos
- Files touched: `scripts/run-skill-update.sh`, `action.yml`
- Tests: enabled/disabled/no-change/error scenarios

**Risks / Dependencies**

- Dependency: update policy accuracy (Phase 4).
- Risk: accidental inclusion of ignored/blocked paths if staging filter is incorrect.

### Phase 6 - Pull Request Feature (single rolling PR + default commit generation)

**Goal:** Implement create/update one PR branch with v1 default commit-generation behavior.

**Status:** Not started

**Paths:** `scripts/run-skill-update.sh`, `action.yml`

#### 6.1 PR lifecycle and output contract

**Reference pattern:** PR automation usage in `.github/workflows/sync-template-files.yml` (`peter-evans/create-pull-request@v8`)

- [x] Run PR stage only when `create-pr=true` and allowed changes exist.
- [x] Reuse commit SHA from commit stage when present.
- [x] If commit missing and `pr-generate-commit=true`, generate commit in PR stage.
- [x] If commit missing and `pr-generate-commit=false`, fail with explicit missing-commit error.
- [x] Create/update exactly one rolling PR on `pr-branch` targeting `base-branch`.
- [x] Emit `pull-request-number` and `pull-request-url` only when PR exists.

**Definition of Done**

- Commands: PR stage integration tests against mocked GitHub API or dry-run harness
- Files touched: `scripts/run-skill-update.sh`, `action.yml`
- Tests: all commit/PR toggle combinations including v1 default path

**Risks / Dependencies**

- Dependency: GitHub token scopes (`contents: write`, `pull-requests: write`).
- Risk: race/update conflicts on long-lived rolling branch.

### Phase 7 - Release and Verification Pipeline

**Goal:** Implement v1 release process (`vX.Y.Z` immutable + moving `v1`) and smoke verification.

**Status:** Complete

**Paths:** `.github/workflows/release-marketplace-action.yml`, `.github/workflows/smoke-marketplace-action.yml`, `README.md`

#### 7.1 Release workflows and compatibility checks

**Reference pattern:** matrix/quality workflow style in `.github/workflows/test-templates.yml`

- [x] Add smoke workflow for marketplace action scenarios (update-only, commit-enabled, pr-enabled).
- [x] Add release workflow gated on successful smoke/contract checks.
- [x] Publish immutable semver tags and move `v1` alias via validated workflow.
- [x] Document release operator steps and rollback strategy.

**Definition of Done**

- Commands: workflow dispatch for smoke and release in staging repo
- URLs: GitHub release + tag references (`refs/tags/vX.Y.Z`, `refs/tags/v1`)
- Files touched: release/smoke workflow files, `README.md`
- Tests: contract output checks against released ref

**Risks / Dependencies**

- Dependency: Phases 2-6 complete.
- Risk: publishing `v1` before contract tests are stable can break consumers.

### Phase 8 - Cross-Repo Workflow Hardening (Whole-System Related Area)

**Goal:** Stabilize existing automation around templates and security so whole-system behavior is consistent.

**Status:** Partial

**Paths:** `.github/workflows/security.yml`, `.github/workflows/dependabot-automerge.yml`, `.github/workflows/sync-template-files.yml`, `.github/dependabot.yml`, `templates/**`, `scripts/**`

#### 8.1 Existing automation quality gaps

**Reference pattern:** valid workflow structure in `.github/workflows/test-templates.yml`

- [x] Verified template stack setup and smoke test scripts exist and run path is defined.
- [x] Verified per-template CI workflows exist for Go/JavaScript/PHP.
- [x] Verified Dependabot and auto-merge workflows exist.
- [x] Fix malformed `security.yml` structure (currently missing top-level `jobs` mapping).
- [ ] Align action versions and workflow style consistency across template CI files where needed.
- [x] Add explicit verification notes for sync-template conflict paths and failure diagnostics.

**Definition of Done**

- Commands: `gh workflow view` / workflow lint checks
- Files touched: `.github/workflows/security.yml` and related workflow docs
- Tests: workflow syntax validation + manual dispatch success

**Risks / Dependencies**

- Dependency: repository-level permissions and required secrets.
- Risk: broken security workflow may hide scanning regressions.

## Verification Log

- 2026-04-16: `git status --short` - clean working tree for planning baseline; tests run: none; bug fixes: none; files reviewed: repository root.
- 2026-04-16: `git log --oneline --decorate -- specs` - confirmed recent spec evolution (`81d6b89`, `da459d9`, `9b2752d`); tests run: none; files reviewed: `specs/**`.
- 2026-04-16: `git log -p -n 5 -- specs` - verified scope shifts and deferred v1 decisions across overview/runtime/features/release specs; tests run: none; bug fixes discovered: none; files reviewed: `specs/overview-and-contract.md`, `specs/runtime-and-pr-flow.md`, `specs/features/*.md`, `specs/release-and-verification.md`, `specs/README.md`.
- 2026-04-16: repository path audit (`glob`/content review) - confirmed missing action implementation files (`action.yml`, `scripts/run-skill-update.sh`, release/smoke action workflows) and existing template automation surface; tests run: none; files reviewed: `.github/workflows/*.yml`, `scripts/*.sh`, `templates/**`, `README.md`, `AGENTS.md`, `adr/**`.
- 2026-04-16: `bash scripts/test-run-skill-update.sh` - pass; verified no-change skip behavior, allowlisted commit creation, blocked-path failure, ignored-path non-failing flow, PR-stage commit generation default, PR output mapping, and missing-commit failure behavior when `pr-generate-commit=false`.
- 2026-04-16: `bash -n scripts/run-skill-update.sh` - pass
- 2026-04-16: `bash -n scripts/test-run-skill-update.sh` - pass
- 2026-04-16: bash scripts/test-run-skill-update.sh - pass
- 2026-04-16: bash scripts/test-marketplace-workflows.sh - pass
- 2026-04-16: bash -n scripts/test-marketplace-workflows.sh - pass
- 2026-04-16: `bash scripts/test-marketplace-workflows.sh` - pass after fixing `security.yml` top-level `jobs` mapping and extending workflow contract checks.
- 2026-04-16: `bash -n scripts/test-marketplace-workflows.sh` - pass.
- 2026-04-16: `bash scripts/test-run-skill-update.sh` - pass.
- 2026-04-16: `bash -n scripts/run-skill-update.sh && bash -n scripts/test-run-skill-update.sh` - pass.
- 2026-04-16: `bash scripts/test-marketplace-workflows.sh` - pass after adding release operator and rollback documentation in `README.md`.
- 2026-04-16: `bash scripts/test-run-skill-update.sh` - pass; validated runtime behavior including default `update-command` fallback derived from `skills-cli-version` and existing no-change/blocked/PR flows.
- 2026-04-16: `bash -n scripts/run-skill-update.sh && bash -n scripts/test-run-skill-update.sh` - pass.
- 2026-04-16: bash scripts/test-run-skill-update.sh - pass after adding regression coverage for pre-staged ignored file exclusion from commit contents.
- 2026-04-16: bash -n scripts/run-skill-update.sh && bash -n scripts/test-run-skill-update.sh - pass.
- 2026-04-16: bash scripts/test-marketplace-workflows.sh - pass after adding sync-template conflict diagnostics assertions and README verification notes checks.
- 2026-04-16: bash -n scripts/test-marketplace-workflows.sh - pass.
- 2026-04-16: bash scripts/test-run-skill-update.sh - pass after adding regression for omitted optional outputs (`commit-sha`, `pull-request-number`, `pull-request-url`) when not created.
- 2026-04-16: bash -n scripts/run-skill-update.sh && bash -n scripts/test-run-skill-update.sh - pass.

## Summary

| Phase                                         | Status      | Completion |
| --------------------------------------------- | ----------- | ---------- |
| Phase 1 - Baseline and Spec/ADR Alignment     | Complete    | 100%       |
| Phase 2 - Marketplace Action Contract Surface | Complete    | 100%       |
| Phase 3 - Runtime Orchestration               | Complete    | 100%       |
| Phase 4 - Update Feature                      | Not started | 0%         |
| Phase 5 - Commit Feature                      | Partial     | 40%        |
| Phase 6 - Pull Request Feature                | Complete    | 100%       |
| Phase 7 - Release and Verification Pipeline   | Complete    | 100%       |
| Phase 8 - Cross-Repo Workflow Hardening       | Partial     | 83%        |

**Remaining effort:** 2 core action phases and 1 hardening phase are unfinished.

## Known Existing Work

- Confirmed spec corpus and ADR decisions are present and recently updated.
- Confirmed template scaffolding is operational: `scripts/stack-setup.sh`, `scripts/test-template-stack.sh`, and `templates/go`, `templates/javascript`, `templates/php`.
- Confirmed template CI workflows exist and are wired for smoke/quality execution.
- Confirmed repository automation exists for template sync and Dependabot auto-merge.
- Confirmed runtime now supports update, optional commit, and PR-stage create/update behavior with output contract propagation.

## Manual Deployment Tasks

- None
