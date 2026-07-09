# Phase 142: Release Graph & Governance Contract - Research

**Researched:** 2026-07-07  
**Domain:** GitHub Actions release governance, Release Please monorepo outputs, Hex publish proof timing  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Phase Boundary And Traceability
- **D-01:** Keep the current bundled v18 release-integrity worktree intact. Reverting or splitting it would add risk without improving runtime correctness.
- **D-02:** Downstream plans must map each file/test to its owning requirement: RELG for graph/proof governance, PREF for clean-room dependency precision, MIRR for native mirror/decoupling, and STAT for operator status.
- **D-03:** Phase 142 should not claim UI/product breadth. The product surface here is release automation, proofs, docs, CLI/status output, and failure microcopy.

### Release Identity And Gates
- **D-04:** Use exact gates for every behavioral job. Behavioral means publish, proof, cleanup, recovery, mirror, or any job that mutates state or creates an operator signal.
- **D-05:** Allow aggregate `releases_created` only for non-destructive summaries, high-level alerts, or logging. It must not gate `publish-*`, `clean-room-proof-*`, `release-as-cleanup`, recovery, or mirror jobs.
- **D-06:** Root Hex and native core jobs gate on `paths_released` parsed with `fromJSON`. Root uses `.`, iOS uses `packages/crosswake-shell-core-ios`, and Android uses `packages/crosswake-shell-core-android`.
- **D-07:** Companion/observer jobs gate on per-component aliases such as `rulestead_release_created == 'true'`. Slash-containing Release Please path outputs should be aliased in the release job outputs and consumed with dot notation downstream.
- **D-08:** Treat GitHub Actions outputs as strings unless explicitly parsed. Avoid substring checks on JSON strings; `contains(fromJSON(paths_released), item)` is the intended form for path identity.
- **D-09:** Preserve the root/native lockstep group only for root Hex, iOS core, and Android core. Rulestead, Rindle, Sigra, Chimeway, and Threadline stay independently versioned and independently gated.

### Concurrency And Run Replacement
- **D-10:** `cancel-in-progress: false` is necessary but not sufficient for "no release run disappears." GitHub Actions currently replaces an older pending run in the same concurrency group unless `queue: max` is set.
- **D-11:** Phase 142 planning should add or explicitly justify `queue: max` for the Release Please workflow if RELG-02 means both running and pending release work must not be replaced.
- **D-12:** Keep release/proof concurrency workflow-level, narrow to the release workflow/ref, and avoid cross-run `needs`. Release ordering between runs stays a runbook/operator concern until a later automation phase owns it.

### Release-As Cleanup
- **D-13:** `release-as-cleanup` should open only after the released companion's Hex publish and post-publish clean-room proof both succeed. In Crosswake, clean-room proof is release truth, not advisory noise.
- **D-14:** The cleanup job should keep `always()` so it can evaluate after skipped/failed needs, but its condition must use per-component implications: unreleased companions may be `skipped`; a released companion must have both publish and proof `success`.
- **D-15:** Do not use a blanket "no skipped needs" guard for cleanup. Skips are expected for components not released in the current run.
- **D-16:** Cleanup must open a PR only. It must not mutate protected `main` directly. On publish/proof failure, rely on `release-failure-alert`, exact-ref/idempotent rerun, or deliberate manual cleanup after proof recovery.
- **D-17:** The current workflow only waits for companion publish jobs before cleanup. Treat this as an implementation gap to reconcile during Phase 142 planning/execution.

### Proof Surface
- **D-18:** Keep `script/check_release_workflow_integrity.exs` plus ExUnit as the primary Phase 142 proof. This is idiomatic for this repo: fast, deterministic, no new dependency, and close to Mix/ExUnit operator workflows.
- **D-19:** Harden the scanner around named semantic invariants instead of replacing it with a YAML dependency. Required invariants include exact gates, `queue: max`/non-canceling concurrency, native proof decoupling, mirror preflight, cleanup-after-proof, and aggregate-gate negative controls.
- **D-20:** Add adversarial fixture or helper coverage before broadening the scanner: comment-only false passes, aggregate `releases_created` in proof/cleanup jobs, native cross-dependency regressions, missing `queue: max`, and cleanup that ignores proof results.
- **D-21:** `actionlint` is a useful pinned additive lane for syntax/expression mistakes, ShellCheck/Pyflakes integration, and `needs` errors. It must not replace the Crosswake semantic proof because it cannot know Release Please identity policy.
- **D-22:** Do not add a structured YAML parser unless the workflow integrity proof becomes broad workflow inventory. Generic YAML parsing still will not understand GitHub Actions expression semantics, and a new dependency is not worth it for the current targeted contract.

### Developer Experience And Operator UX
- **D-23:** Treat Mix tasks and scripts as user-facing product surface. Public tasks should follow Mix conventions: `Mix.Tasks.*`, `use Mix.Task`, helpful `@shortdoc`, actionable `@moduledoc`, and clear `run/1` parsing.
- **D-24:** CLI and CI output should use the brand voice from `brandbook/BRAND-SPEC.md`: calm, specific, actionable, and prefixed with `[crosswake]` where appropriate.
- **D-25:** Prefer named verification commands over opaque shell chains. Good examples are `mix crosswake.release.status`, `mix crosswake.doctor --router`, and `elixir script/check_release_workflow_integrity.exs`.
- **D-26:** Hide backend mechanics from operators unless the detail changes the next action. Report release state as "what happened", "what is safe to do next", and "what command/source proves it".
- **D-27:** For this phase there is no graphical UI requirement. UI/UX applies to CLI text, GitHub issue/PR copy, docs/runbooks, and machine-readable JSON output.

### Ecosystem Lessons
- **D-28:** Hex publish is effectively irreversible after a short update/revert window. Clean-room install/compile proof belongs after publish and before "done" operator signals.
- **D-29:** Successful monorepo release tools treat package/project identity as first-class. Changesets linked packages, Lerna independent mode, Nx independent release groups, and Release Please path outputs all reinforce the same lesson: do not infer exact package identity from an aggregate "something released" flag.
- **D-30:** Keep Release Please pinned output behavior explicit. The workflow currently pins `googleapis/release-please-action` v4.1.3; any upgrade to the current major must revalidate output names, path aliases, and manifest behavior before landing.

### the agent's Discretion

The user asked for one-shot recommendations across all gray areas. Downstream agents may choose implementation mechanics, but should not revisit the core policy choices above unless live docs or CI behavior contradict them.

### Deferred Ideas (OUT OF SCOPE)

- Release Please major upgrade: defer unless explicitly scheduled. The current workflow pins v4.1.3; revalidate output names and manifest behavior before any upgrade.
- Full YAML parsing: defer until the semantic checker becomes broad workflow inventory.
- Live release rehearsal automation beyond current proof lanes: belongs to AUTO phases.
- Companion clean-room exactness, iOS mirror observability, and release status CLI completion: validate in phases 144, 145, and 146 respectively.
- Graphical dashboard/UI: out of scope for Phase 142. CLI text, JSON, GitHub issue copy, and docs are the user-facing surfaces for this phase.
- Product integrations beyond release integrity: out of scope. Preserve Crosswake's Phoenix-first route-policy/runtime-contract thesis.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RELG-01 | Maintainers can prove the release workflow uses path-specific gates so companion-only releases cannot publish the core Hex package or native artifacts. | Use Release Please `paths_released` plus per-component aliases, with negative proof against aggregate `releases_created` on behavioral jobs. [CITED: github.com/googleapis/release-please-action#outputs] [VERIFIED: codebase grep] |
| RELG-02 | Maintainers can prove release publish/proof jobs are not canceled mid-run by newer release workflow events. | Require workflow-level `cancel-in-progress: false` and `queue: max`; GitHub confirms default pending replacement and confirms `queue: max` support. [CITED: docs.github.com/actions-workflow-syntax] [VERIFIED: codebase grep] |
| RELG-03 | Maintainers can detect stale `release-as` pins only after the relevant companion publish job succeeds. | Make `release-as-cleanup` depend on both companion publish jobs and their post-publish clean-room proofs; use per-component `needs.<job>.result` implications so unreleased components may skip. [CITED: docs.github.com/actions-contexts] [CITED: github.com/googleapis/release-please/manifest-releaser] [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` before planning or implementation. [VERIFIED: AGENTS.md]
- Preserve the core thesis: Crosswake is a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route; do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: AGENTS.md]
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; move continuous client authority toward offline islands or native screens. [VERIFIED: AGENTS.md]
- Keep offline claims honest by distinguishing cached read-only behavior from local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: AGENTS.md]
- Update planning artifacts as work progresses so requirements, roadmap state, and project decisions stay aligned. [VERIFIED: AGENTS.md]

## Summary

Phase 142 should be planned as a focused governance correction over the existing v18 release-integrity worktree: keep the current path gates and per-component aliases, add `queue: max`, make `release-as-cleanup` wait for released companion publish and clean-room proof success, and harden the semantic proof so the next regression cannot pass through comments or aggregate gates. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-workflow-syntax] [CITED: docs.github.com/actions-contexts]

The highest-risk current gap is RELG-02: `.github/workflows/release-please.yml` has workflow-level `cancel-in-progress: false` but no `queue: max`; GitHub's current workflow syntax docs confirm default pending-run replacement and confirm `queue: max` as the supported way to queue multiple pending runs. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-workflow-syntax]

The second highest-risk gap is RELG-03: `release-as-cleanup` currently needs only companion publish jobs, not `clean-room-proof-*`, while Crosswake's own phase context treats clean-room proof as release truth. The planner should assign this to Phase 142 acceptance criteria, not defer it to Phase 144, because cleanup is a release-governance signal. [VERIFIED: codebase grep] [VERIFIED: 142-CONTEXT.md]

**Primary recommendation:** implement the three-governance invariant set in one wave: `queue: max`, cleanup-after-publish-and-proof, and scanner/test negative controls. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-workflow-syntax]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Release identity gating | CI / GitHub Actions | Release Please action | GitHub Actions owns job execution; Release Please owns path/component outputs used as identity inputs. [CITED: github.com/googleapis/release-please-action#outputs] |
| Publish/proof run replacement control | CI / GitHub Actions | Operator runbook | GitHub concurrency determines whether release workflow runs are canceled, replaced, or queued. [CITED: docs.github.com/actions-workflow-syntax] |
| Stale `release-as` cleanup timing | CI / GitHub Actions | GitHub PR workflow | Cleanup is a CI job that opens a PR only after relevant release jobs succeed. [VERIFIED: codebase grep] |
| Semantic governance proof | Elixir test tier | CI merge-blocking lane | The repo's standard proof style is deterministic ExUnit plus small scripts. [VERIFIED: codebase grep] |
| Release-status spillover | Mix task / operator CLI | Live registry probes | Existing work is useful context but downstream STAT phases own completion claims. [VERIFIED: codebase grep] [VERIFIED: 142-CONTEXT.md] |

## Current-Code Observations

### Already Present

- `release-please` exposes `paths_released` with a default `[]`, root `tag_name/version`, and component aliases for all five companion packages. [VERIFIED: codebase grep]
- Root Hex, iOS core, and Android core publish jobs use `contains(fromJSON(needs.release-please.outputs.paths_released), exact_path)` instead of aggregate `releases_created`. [VERIFIED: codebase grep]
- Companion publish jobs gate on `<component>_release_created == 'true'`. [VERIFIED: codebase grep]
- Native clean-room proof jobs are decoupled by platform: iOS needs `publish-ios-core`, Android needs `publish-android-core`. [VERIFIED: codebase grep]
- iOS mirror preflight is already present in the workflow, including missing-token failure text and `git ls-remote mirror HEAD`. [VERIFIED: codebase grep]
- `script/verify_companion_cleanroom.sh` already derives `CORE_REQUIREMENT` from package `mix.exs` and pins the exact just-published companion version as `== ${VERSION}`. [VERIFIED: codebase grep]
- `lib/crosswake/release_status.ex` and `mix crosswake.release.status` exist as implementation spillover for later STAT work; their focused tests pass locally. [VERIFIED: codebase grep] [VERIFIED: local command]

### Missing Or Risky

- `queue: max` is absent from `.github/workflows/release-please.yml`; current proof only checks `cancel-in-progress: false`, so RELG-02 is under-proven. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-workflow-syntax]
- `release-as-cleanup` currently needs only companion publish jobs and does not wait for `clean-room-proof-rulestead`, `clean-room-proof-rindle`, `clean-room-proof-sigra`, `clean-room-proof-chimeway`, or `clean-room-proof-threadline`. [VERIFIED: codebase grep]
- The cleanup condition uses broad `!contains(needs.*.result, 'failure')` and `!contains(needs.*.result, 'cancelled')`; the desired contract is per-component implication so released components require publish+proof success while unreleased components may skip. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-contexts]
- `script/check_release_workflow_integrity.exs` has no checks for `queue: max`, cleanup-after-proof, comment-only false passes, aggregate gates in proof/cleanup/recovery/mirror jobs, or adversarial negative fixtures. [VERIFIED: codebase grep]
- `test/crosswake/proof/phase142_release_integrity_test.exs` proves the existing script, root/native aggregate-gate absence, and clean-room dependency floors, but not the full RELG-01..03 invariant set. [VERIFIED: codebase grep]
- `actionlint .github/workflows/release-please.yml` is available locally but currently fails on a pre-existing ShellCheck SC2086 finding at workflow line 897 (`basename $ARTIFACT` should be quoted). [VERIFIED: local command] [CITED: github.com/rhysd/actionlint]

## Standard Stack

### Core

| Library / Platform | Version | Purpose | Why Standard |
|--------------------|---------|---------|--------------|
| GitHub Actions workflow concurrency | Current GitHub-hosted syntax docs, checked 2026-07-07 | Serialize Release Please workflow runs without canceling or replacing pending release runs | Official execution platform for this workflow; supports `cancel-in-progress` and `queue: max`. [CITED: docs.github.com/actions-workflow-syntax] |
| `googleapis/release-please-action` | v4.1.3 pinned by SHA in workflow | Produce release identity outputs from manifest mode | Official Release Please action; exposes `releases_created`, `paths_released`, root outputs, and path-prefixed outputs. [CITED: github.com/googleapis/release-please-action#outputs] [VERIFIED: codebase grep] |
| Release Please manifest mode | Current docs, checked 2026-07-07 | Maintain monorepo package config and `.release-please-manifest.json` versions | Official monorepo release model; supports `separate-pull-requests`, `release-as`, and `linked-versions`. [CITED: github.com/googleapis/release-please/manifest-releaser] |
| Elixir + ExUnit | Elixir/Mix 1.19.5 on local machine | Run deterministic semantic release-workflow proof | Existing repo convention; no new dependency and fast local proof. [VERIFIED: local command] [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `actionlint` | 1.7.12 installed locally | Static GitHub Actions syntax/expression/needs/shell lint | Add only after fixing or intentionally suppressing current SC2086; it complements but does not replace Crosswake semantic proof. [VERIFIED: local command] [CITED: github.com/rhysd/actionlint] |
| Hex `mix hex.publish` | Hex docs v2.5.0 | Publish behavior and post-publish recovery window semantics | Use to justify cleanup-after-proof and recovery timing; do not run publish in this phase. [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `paths_released` exact gates | Aggregate `releases_created` | Aggregate is true for any release and is unsafe for behavioral jobs in a package family. [CITED: github.com/googleapis/release-please-action#outputs] |
| GitHub `queue: max` | Runbook-only manual serialization | Runbook discipline does not prevent pending-run replacement by the platform. [CITED: docs.github.com/actions-workflow-syntax] |
| Existing Elixir semantic scanner | Generic YAML parser | Parser would improve structure but still would not understand Crosswake release identity policy; current scope does not justify a new dependency. [VERIFIED: 142-CONTEXT.md] |
| Semantic scanner only | `actionlint` only | `actionlint` catches syntax/needs/expression mistakes, but it cannot know Crosswake-specific aggregate-gate policy. [CITED: github.com/rhysd/actionlint] |

**Installation:**

```bash
# No external package install is required for Phase 142.
```

**Version verification:**

```bash
elixir --version
mix --version
actionlint -version
```

## Package Legitimacy Audit

Phase 142 should not install new external packages. [VERIFIED: 142-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No install recommended |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Release Please workflow trigger
  |
  v
release-please job
  |-- aggregate output: releases_created
  |      \-> allowed only for summaries/alerts/logging
  |
  |-- path output: paths_released JSON
  |      |-> publish-hex when contains(fromJSON(paths_released), ".")
  |      |-> publish-ios-core when contains(..., "packages/crosswake-shell-core-ios")
  |      \-> publish-android-core when contains(..., "packages/crosswake-shell-core-android")
  |
  \-- path-prefixed outputs aliased to component_release_created/version/tag
         |-> publish-hex-component when component_release_created == "true"
         |-> clean-room-proof-component after publish-hex-component success
         \-> release-as-cleanup after released component publish + proof success

Workflow-level concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
  queue: max

Semantic proof:
  elixir script/check_release_workflow_integrity.exs
    -> ExUnit proof
    -> optional actionlint syntax/expression lint
```

Diagram source: current workflow and official GitHub/Release Please docs. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-workflow-syntax] [CITED: github.com/googleapis/release-please-action#outputs]

### Recommended Project Structure

```text
.github/workflows/
└── release-please.yml                 # release DAG, exact gates, concurrency, cleanup ordering

script/
└── check_release_workflow_integrity.exs # semantic release graph invariant proof

test/crosswake/proof/
└── phase142_release_integrity_test.exs  # merge-blocking ExUnit wrapper + adversarial cases
```

### Pattern 1: Exact Release Identity Gates

**What:** Gate core/native jobs on `paths_released` and companions on per-component aliases. [CITED: github.com/googleapis/release-please-action#outputs]  
**When to use:** Every behavioral job that publishes, proves, mirrors, recovers, cleans up, or creates operator signals. [VERIFIED: 142-CONTEXT.md]

**Example:**

```yaml
# Source: Release Please action outputs + GitHub expressions docs.
if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios') }}
```

### Pattern 2: Non-Replacing Release Workflow Concurrency

**What:** Use workflow-level concurrency with `cancel-in-progress: false` and `queue: max`. [CITED: docs.github.com/actions-workflow-syntax]  
**When to use:** Release workflows with publish/proof jobs where a newer push must not cancel or replace older pending release work. [CITED: docs.github.com/actions-workflow-syntax]

**Example:**

```yaml
# Source: GitHub Actions workflow syntax docs.
concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
  queue: max
```

### Pattern 3: Cleanup After Publish And Proof

**What:** `release-as-cleanup` should need all companion publish and proof jobs and then apply per-component implications. [VERIFIED: 142-CONTEXT.md] [CITED: docs.github.com/actions-contexts]  
**When to use:** One-shot `release-as` pins where cleanup must happen only after the package is published and the clean-room proof confirms install truth. [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

**Example:**

```yaml
# Source: GitHub needs context semantics; adapt in workflow for each component.
if: >-
  ${{
    always() &&
    needs.release-please.outputs.sigra_release_created == 'true' &&
    needs.publish-hex-sigra.result == 'success' &&
    needs.clean-room-proof-sigra.result == 'success'
  }}
```

### Pattern 4: Semantic Proof With Negative Fixtures

**What:** Keep the existing Elixir scanner, but add adversarial fixtures or helper-driven negative cases for each invariant. [VERIFIED: 142-CONTEXT.md]  
**When to use:** Release policy that generic YAML lint cannot understand. [VERIFIED: 142-CONTEXT.md] [CITED: github.com/rhysd/actionlint]

**Example:**

```elixir
# Source: local proof pattern; recommended expansion.
assert_failure!("release.concurrency.queue_max", workflow_without_queue_max)
assert_failure!("release.cleanup.after_publish_and_proof", cleanup_without_proof_needs)
assert_failure!("release.aggregate_gate.behavioral_jobs_absent", proof_job_using_releases_created)
```

### Anti-Patterns to Avoid

- **Aggregate behavioral gates:** `releases_created` is true when any package releases, so it is unsafe for publish/proof/cleanup/mirror/recovery jobs. [CITED: github.com/googleapis/release-please-action#outputs]
- **`cancel-in-progress: false` without `queue: max`:** this avoids canceling the running workflow but does not prevent default pending-run replacement. [CITED: docs.github.com/actions-workflow-syntax]
- **Blanket "no skipped needs" cleanup guard:** unreleased companion jobs are expected to skip, so cleanup must use per-component implications. [CITED: docs.github.com/actions-contexts] [VERIFIED: 142-CONTEXT.md]
- **Comment-sensitive string checks:** a scanner that accepts strings in comments can falsely prove the policy. [VERIFIED: 142-CONTEXT.md]
- **Cross-run `needs`:** GitHub `needs` is within a workflow run, so companion sequencing across separate Release PR runs must remain runbook/operator territory. [CITED: docs.github.com/actions-contexts] [VERIFIED: 140-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release path identity | Substring checks on JSON strings | `contains(fromJSON(paths_released), exact_path)` | GitHub expressions support JSON parsing and array membership. [CITED: docs.github.com/actions-expressions] |
| Pending-run preservation | Ad hoc retry or manual queue comments | `queue: max` | GitHub supports queueing up to 100 pending runs in a concurrency group. [CITED: docs.github.com/actions-workflow-syntax] |
| Cleanup result reasoning | Single broad `needs.*.result` filter | Per-component `needs.<job_id>.result == 'success'` implication | Needs results have exact `success/failure/cancelled/skipped` values. [CITED: docs.github.com/actions-contexts] |
| GitHub Actions syntax lint | Custom full YAML linter | `actionlint` as additive | It already checks workflow syntax, expressions, needs, ShellCheck, and Pyflakes. [CITED: github.com/rhysd/actionlint] |
| Package publish recovery semantics | Maintainer lore | Hex publish docs | Hex update/revert windows are time-bound and should shape cleanup/proof timing. [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |

**Key insight:** Phase 142 is not about making YAML prettier; it is about making release identity and release completion mechanically provable. [VERIFIED: 142-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Aggregate Release Output Reintroduced

**What goes wrong:** A companion-only Release Please run can trigger core Hex or native publishes if behavioral jobs use `releases_created`. [CITED: github.com/googleapis/release-please-action#outputs]  
**Why it happens:** `releases_created` is an aggregate "any release" flag. [CITED: github.com/googleapis/release-please-action#outputs]  
**How to avoid:** Gate root/native on `paths_released` and companions on aliased component outputs. [CITED: github.com/googleapis/release-please-action#outputs]  
**Warning signs:** `publish-*`, `clean-room-proof-*`, mirror, recovery, or cleanup jobs contain `outputs.releases_created`. [VERIFIED: codebase grep]

### Pitfall 2: Pending Release Run Replacement

**What goes wrong:** A newer release workflow event can replace an older pending run in the same concurrency group. [CITED: docs.github.com/actions-workflow-syntax]  
**Why it happens:** GitHub's default concurrency behavior allows only one pending run and replaces the pending one. [CITED: docs.github.com/actions-workflow-syntax]  
**How to avoid:** Add `queue: max` and keep `cancel-in-progress: false`; do not combine `queue: max` with `cancel-in-progress: true`. [CITED: docs.github.com/actions-workflow-syntax]  
**Warning signs:** Workflow has `concurrency` and `cancel-in-progress: false` but no `queue: max`. [VERIFIED: codebase grep]

### Pitfall 3: Cleanup Runs Before Clean-Room Proof

**What goes wrong:** `release-as` can be stripped after a publish job even if the just-published package cannot be installed in a clean room. [VERIFIED: codebase grep]  
**Why it happens:** `release-as-cleanup` currently needs only `publish-hex-*` jobs. [VERIFIED: codebase grep]  
**How to avoid:** Add all `clean-room-proof-*` jobs to cleanup `needs` and require proof success for each released component. [VERIFIED: 142-CONTEXT.md] [CITED: docs.github.com/actions-contexts]  
**Warning signs:** Cleanup `needs` lacks `clean-room-proof-*`. [VERIFIED: codebase grep]

### Pitfall 4: Scanner False Passes From Comments

**What goes wrong:** A proof passes because a forbidden or required string appears only in explanatory comments. [VERIFIED: 142-CONTEXT.md]  
**Why it happens:** The current scanner is string/regex-based and has no adversarial fixture layer. [VERIFIED: codebase grep]  
**How to avoid:** Add helper-driven negative tests that mutate job blocks or fixture workflows and assert specific check IDs fail. [VERIFIED: 142-CONTEXT.md]  
**Warning signs:** New check only tests `workflow =~ "...string..."` with no failing fixture. [VERIFIED: codebase grep]

### Pitfall 5: Making Actionlint The Semantic Gate

**What goes wrong:** Syntax/expression lint passes while release identity policy is wrong. [CITED: github.com/rhysd/actionlint]  
**Why it happens:** `actionlint` validates GitHub Actions mechanics, not Crosswake's product-specific release DAG. [CITED: github.com/rhysd/actionlint]  
**How to avoid:** Use `actionlint` as an additive check after the Elixir semantic proof. [VERIFIED: 142-CONTEXT.md]  
**Warning signs:** Plan removes `script/check_release_workflow_integrity.exs` or stops asserting named release-policy invariants. [VERIFIED: codebase grep]

## Code Examples

### Required Concurrency Contract

```yaml
# Source: GitHub Actions workflow syntax docs.
concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
  queue: max
```

### Required Root/Native Path Gates

```yaml
# Source: Release Please action outputs + GitHub expressions docs.
publish-hex:
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}

publish-ios-core:
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios') }}

publish-android-core:
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android') }}
```

### Required Cleanup Shape

```yaml
# Source: GitHub needs context docs; planner should expand for each component.
release-as-cleanup:
  needs:
    - release-please
    - publish-hex-sigra
    - clean-room-proof-sigra
  if: >-
    ${{
      always() &&
      (
        needs.release-please.outputs.sigra_release_created != 'true' ||
        (
          needs.publish-hex-sigra.result == 'success' &&
          needs.clean-room-proof-sigra.result == 'success'
        )
      )
    }}
```

### Required Verification Commands

```bash
elixir script/check_release_workflow_integrity.exs
mix test test/crosswake/proof/phase142_release_integrity_test.exs
mix test test/mix/tasks/crosswake_release_status_test.exs
actionlint .github/workflows/release-please.yml
```

`actionlint` currently fails on an existing SC2086 finding at workflow line 897, so the planner should either fix that quote issue before using actionlint as a gate or keep actionlint advisory for this phase. [VERIFIED: local command]

## Concrete Invariants For PLAN.md

| Req | Acceptance Invariant | Verification |
|-----|----------------------|--------------|
| RELG-01 | No behavioral job gates on `needs.release-please.outputs.releases_created`. [CITED: github.com/googleapis/release-please-action#outputs] | `elixir script/check_release_workflow_integrity.exs` |
| RELG-01 | Root/native publish jobs use `contains(fromJSON(paths_released), exact_path)` for `.`, iOS, and Android paths. [CITED: docs.github.com/actions-expressions] | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| RELG-01 | All companion publish and proof jobs use aliased per-component outputs, not path substring checks or aggregate gates. [CITED: github.com/googleapis/release-please-action#outputs] | Add scanner check IDs and negative fixtures. |
| RELG-02 | Workflow-level concurrency includes `cancel-in-progress: false` and `queue: max`. [CITED: docs.github.com/actions-workflow-syntax] | Add `release.concurrency.queue_max` check and ExUnit assertion. |
| RELG-02 | Workflow never combines `queue: max` with `cancel-in-progress: true`. [CITED: docs.github.com/actions-workflow-syntax] | Add negative fixture for conflicting concurrency. |
| RELG-03 | `release-as-cleanup` needs every companion publish job and every companion clean-room proof job. [VERIFIED: 142-CONTEXT.md] | Scanner checks cleanup job block for all ten needs. |
| RELG-03 | If a component released, cleanup requires that component's publish and proof results are `success`; if it did not release, its skipped jobs do not block cleanup. [CITED: docs.github.com/actions-contexts] | Add per-component implication checks and negative fixture. |
| RELG-03 | Cleanup opens a PR and does not push directly to protected `main`. [VERIFIED: codebase grep] | Scanner keeps PR branch/`gh pr create` shape and refutes direct-main mutation. |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Gate behavioral jobs on aggregate `releases_created` | Gate core/native on `paths_released`; gate companions on per-component aliases | Release Please action v4 output contract, verified 2026-07-07 | Prevents companion-only releases from publishing core/native artifacts. [CITED: github.com/googleapis/release-please-action#outputs] |
| Use `cancel-in-progress: false` only | Add `queue: max` to prevent pending-run replacement | GitHub docs verified 2026-07-07 | Satisfies RELG-02 for running and pending release work. [CITED: docs.github.com/actions-workflow-syntax] |
| Cleanup after publish job only | Cleanup after publish and clean-room proof | Phase 142 context decision | Prevents stale-pin cleanup from masking a broken package install. [VERIFIED: 142-CONTEXT.md] |
| String-only scanner happy path | Named semantic invariants with adversarial negative coverage | Phase 142 planning target | Prevents comment-only and aggregate-gate false passes. [VERIFIED: 142-CONTEXT.md] |

**Deprecated/outdated:**

- `releases_created` as a publish/proof/cleanup gate is deprecated for Crosswake behavioral jobs. [VERIFIED: 142-CONTEXT.md] [CITED: github.com/googleapis/release-please-action#outputs]
- `cancel-in-progress: false` alone is insufficient for RELG-02 because it does not preserve multiple pending runs. [CITED: docs.github.com/actions-workflow-syntax]

## Assumptions Log

All claims in this research were verified from local project files, local commands, or cited official documentation. No `[ASSUMED]` claims are used.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

## Open Questions (RESOLVED)

1. **Should actionlint become a required Phase 142 gate?**  
   What we know: `actionlint` is installed and official docs describe useful syntax/expression/needs checks. [VERIFIED: local command] [CITED: github.com/rhysd/actionlint]  
   What's unclear: whether Phase 142 should spend scope fixing the pre-existing SC2086 in the Android fire-drill block. [VERIFIED: local command]  
   Recommendation: keep actionlint optional unless the plan includes the small quote fix at workflow line 897. [VERIFIED: local command]
   RESOLVED: Phase 142 Plan 01 fixes the known quote issue by using `basename "$ARTIFACT"`, then treats `actionlint .github/workflows/release-please.yml` as additive evidence. The required release-identity proof remains `elixir script/check_release_workflow_integrity.exs` plus `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.

2. **Should cleanup use one large condition or a generated helper pattern?**  
   What we know: GitHub `needs.<job_id>.result` gives exact result values for direct dependencies. [CITED: docs.github.com/actions-contexts]  
   What's unclear: whether maintainers prefer a long explicit YAML condition or a preceding step that computes cleanup eligibility. [VERIFIED: 142-CONTEXT.md]  
   Recommendation: use explicit YAML per-component implications first; it is easier for the semantic scanner to verify. [VERIFIED: 142-CONTEXT.md]
   RESOLVED: Use explicit per-component cleanup implications in the `release-as-cleanup` YAML condition and in the semantic scanner checks; do not compute cleanup eligibility through a helper step or generated helper pattern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Semantic scanner and ExUnit proof | yes | 1.19.5 / OTP 28 | none needed |
| Mix | ExUnit proof and local tasks | yes | 1.19.5 | none needed |
| Git | Release-as local tag detection, workflow operations | yes | 2.41.0 | none needed |
| GitHub CLI (`gh`) | Release cleanup PR flow / local operator checks | yes | 2.95.0 | GitHub web UI/manual PR if needed |
| Node | GSD research tooling only | yes | 22.14.0 | not needed by phase implementation |
| `actionlint` | Optional workflow syntax lint | yes | 1.7.12 | keep advisory or skip if SC2086 remains |

**Missing dependencies with no fallback:** none. [VERIFIED: local command]

**Missing dependencies with fallback:** none. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5 [VERIFIED: local command] |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` or `mix verify` when companion package lanes are desired [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| RELG-01 | Core/native/companion behavioral jobs use exact path/component gates and not aggregate `releases_created`. | unit / semantic proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes, extend |
| RELG-02 | Release workflow runs are not canceled or replaced by newer events. | unit / semantic proof | `elixir script/check_release_workflow_integrity.exs` | yes, extend |
| RELG-03 | `release-as-cleanup` opens only after released companion publish and proof success. | unit / semantic proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes, extend |

### Sampling Rate

- **Per task commit:** `elixir script/check_release_workflow_integrity.exs`
- **Per wave merge:** `mix test test/crosswake/proof/phase142_release_integrity_test.exs`
- **Phase gate:** focused ExUnit proof plus `mix test test/mix/tasks/crosswake_release_status_test.exs`; run `actionlint .github/workflows/release-please.yml` only after SC2086 is fixed or explicitly accepted as advisory. [VERIFIED: local command]

### Wave 0 Gaps

- [ ] `script/check_release_workflow_integrity.exs` - add `release.concurrency.queue_max`, `release.cleanup.after_publish_and_proof`, and aggregate-gate negative controls. [VERIFIED: codebase grep]
- [ ] `test/crosswake/proof/phase142_release_integrity_test.exs` - add adversarial coverage for missing `queue: max`, cleanup ignoring proof results, and comment-only false passes. [VERIFIED: codebase grep]
- [ ] Optional `actionlint` gate - fix line 897 quote issue or keep actionlint advisory. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No end-user auth changes; CI uses GitHub tokens/secrets only. [VERIFIED: codebase grep] |
| V3 Session Management | no | No application session changes. [VERIFIED: 142-CONTEXT.md] |
| V4 Access Control | yes | Exact Release Please gates, least-privilege job permissions, PR-only cleanup. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Parse `paths_released` with `fromJSON`; treat outputs as strings unless parsed; validate workflow shape with semantic tests. [CITED: docs.github.com/actions-expressions] [VERIFIED: 142-CONTEXT.md] |
| V6 Cryptography | limited | Do not add cryptography; preserve GitHub secret handling and avoid exposing publish tokens in logs. [VERIFIED: codebase grep] |

### Known Threat Patterns for GitHub Actions Release Governance

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Confused-deputy publish from aggregate release output | Elevation of Privilege / Tampering | Exact path/component gates and negative proof. [CITED: github.com/googleapis/release-please-action#outputs] |
| Pending release run replaced before publish/proof | Denial of Service / Repudiation | `queue: max` with `cancel-in-progress: false`. [CITED: docs.github.com/actions-workflow-syntax] |
| Cleanup removes `release-as` before install proof | Tampering / Repudiation | Cleanup after publish and proof success. [VERIFIED: 142-CONTEXT.md] |
| Secret leakage or unsafe shell expansion | Information Disclosure | Keep secrets in `env`, quote shell variables, use actionlint/ShellCheck advisory. [CITED: github.com/rhysd/actionlint] |
| Comment-only proof bypass | Tampering | Adversarial negative fixtures in ExUnit. [VERIFIED: 142-CONTEXT.md] |

## Sources

### Primary / Local (HIGH confidence)

- `AGENTS.md` - project constraints and working rules. [VERIFIED: codebase grep]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - v18 scope and Phase 142 requirements. [VERIFIED: codebase grep]
- `.planning/phases/142-release-graph-governance-contract/142-CONTEXT.md` - locked decisions D-01..D-30. [VERIFIED: codebase grep]
- `.github/workflows/release-please.yml` - current release DAG, gates, concurrency, cleanup, proof jobs. [VERIFIED: codebase grep]
- `release-please-config.json`, `.release-please-manifest.json` - manifest packages, linked root/native group, independent companions. [VERIFIED: codebase grep]
- `script/check_release_workflow_integrity.exs` and `test/crosswake/proof/phase142_release_integrity_test.exs` - current semantic proof. [VERIFIED: codebase grep]
- Local commands: `elixir script/check_release_workflow_integrity.exs`, `mix test test/crosswake/proof/phase142_release_integrity_test.exs`, `mix test test/mix/tasks/crosswake_release_status_test.exs`, `actionlint .github/workflows/release-please.yml`. [VERIFIED: local command]

### Official Docs (MEDIUM confidence via websearch seam)

- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax - concurrency, pending replacement, `queue: max`, incompatibility with `cancel-in-progress: true`. [CITED: docs.github.com/actions-workflow-syntax]
- https://docs.github.com/en/actions/reference/workflows-and-actions/expressions - `fromJSON`, `contains`, `always`, `cancelled`, `failure`. [CITED: docs.github.com/actions-expressions]
- https://docs.github.com/en/actions/reference/workflows-and-actions/contexts - `needs.<job_id>.result` values. [CITED: docs.github.com/actions-contexts]
- https://github.com/googleapis/release-please-action#outputs - Release Please action outputs. [CITED: github.com/googleapis/release-please-action#outputs]
- https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md - manifest mode, `release-as`, `separate-pull-requests`, `linked-versions`. [CITED: github.com/googleapis/release-please/manifest-releaser]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - `--dry-run`, update/revert windows, `--replace`. [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- https://github.com/rhysd/actionlint - actionlint feature scope and installed current release. [CITED: github.com/rhysd/actionlint]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - local versions verified and official docs cited. [VERIFIED: local command] [CITED: docs.github.com/actions-workflow-syntax]
- Architecture: HIGH - release DAG and proof files verified directly in the codebase. [VERIFIED: codebase grep]
- Pitfalls: HIGH - current gaps are visible locally and external semantics are cited from official docs. [VERIFIED: codebase grep] [CITED: docs.github.com/actions-workflow-syntax]

**Research date:** 2026-07-07  
**Valid until:** 2026-08-06 for local architecture; re-check GitHub Actions and Release Please docs before changing workflow syntax or upgrading the action.
