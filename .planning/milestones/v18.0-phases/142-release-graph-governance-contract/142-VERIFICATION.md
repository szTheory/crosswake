---
phase: 142-release-graph-governance-contract
verified: 2026-07-07T16:26:53Z
status: passed
requirement_ids:
  - RELG-01
  - RELG-02
  - RELG-03
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
automated_checks:
  - command: "elixir script/check_release_workflow_integrity.exs"
    result: "passed; all release.* governance checks OK"
  - command: "mix test test/crosswake/proof/phase142_release_integrity_test.exs"
    result: "passed; 11 tests, 0 failures"
  - command: "mix test test/mix/tasks/crosswake_release_status_test.exs"
    result: "passed; 4 tests, 0 failures"
  - command: "mix crosswake.release.status"
    result: "passed; text output includes release.governance_* checks and Phase 144 warning"
  - command: "mix crosswake.release.status --json"
    result: "passed; clean JSON output includes release.governance_* checks"
  - command: "mix run -e <temporary mutated workflow ReleaseStatus decoy check>"
    result: "passed; status rejects inline decoys and cleanup bypasses, ignores comment-only aggregate decoy"
residual_risks:
  - "mix crosswake.release.status reports status: warning because release.cleanroom_dependency_floor is explicitly downstream Phase 144 scope, not a Phase 142 gap."
  - "Full PREF, MIRR, and STAT requirement completion remains owned by Phases 144, 145, and 146."
  - "Older local actionlint versions may not recognize queue: max; current GitHub Actions docs confirm queue: max is valid and incompatible only with cancel-in-progress: true."
external_sources:
  - "https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency"
---

# Phase 142: Release Graph & Governance Contract Verification Report

**Phase Goal:** Encode and test the release DAG so core/native/companion publish jobs cannot be triggered by the wrong Release Please output.
**Verified:** 2026-07-07T16:26:53Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | RELG-01: Behavioral jobs use exact path/component Release Please identity; aggregate `releases_created` is not a behavioral gate. | VERIFIED | `.github/workflows/release-please.yml` gates root/native jobs with exact `paths_released` membership and all companion publish/proof jobs with per-component `*_release_created` outputs. Scanner passed `release.root_hex.path_gate`, `release.ios.path_gate`, `release.android.path_gate`, five `release.<component>.component_gate`, five `release.<component>.proof_gate`, and `release.aggregate_gate.behavioral_jobs_absent`. |
| 2 | RELG-02: Release workflow concurrency is non-replacing with `cancel-in-progress: false` and `queue: max`. | VERIFIED | Workflow has top-level `concurrency` with `cancel-in-progress: false` and `queue: max`; scanner passed `release.concurrency.not_cancelled`, `release.concurrency.queue_max`, and `release.concurrency.no_true_cancellation`. GitHub docs confirm `queue: max` enables multiple pending runs and conflicts only with `cancel-in-progress: true`. |
| 3 | RELG-03: `release-as-cleanup` waits for released companion publish plus clean-room proof success and stays PR-only. | VERIFIED | Cleanup `needs` includes all five companion publish jobs and all five companion proof jobs. Its condition requires each released component's publish and proof result to be `success`; PR flow uses branch push plus `gh pr create`. Scanner passed `release.cleanup.after_publish_and_proof` and `release.cleanup.pr_only`. |
| 4 | Scanner proof is not fooled by comments or decoy text. | VERIFIED | `script/check_release_workflow_integrity.exs` strips full-line comments, parses job-level `if`/`needs`, and normalizes expressions. Focused ExUnit passed comment-only, inline-comment, env-decoy, aggregate-gate, missing-queue, true-cancel, cleanup-proof, proof-gate, and direct-main mutation fixtures. |
| 5 | Companion proof jobs have matching per-component `if` and `needs`. | VERIFIED | Each `clean-room-proof-*` job is gated on the same component's `*_release_created == 'true'` output and needs its matching `publish-hex-*` job. Scanner and ExUnit enforce this via `release.<component>.proof_gate` and cleanup-after-proof negative fixtures. |
| 6 | `mix crosswake.release.status` text/JSON exposes governance checks without claiming downstream PREF/MIRR/STAT completion. | VERIFIED | Text and JSON output include `release.governance_queue_max`, `release.governance_behavioral_identity_gates`, and `release.governance_cleanup_after_proof`. Tests assert `PREF-01`, `MIRR-01`, and `STAT-01` are not rendered as completion claims. |
| 7 | Release status remains deterministic by default and live registry probes are opt-in. | VERIFIED | Mix task defaults to local files only; `--live` is the only registry-probe path. Focused status test injects probe functions for live behavior without network dependence. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/release-please.yml` | Release DAG governance contract | VERIFIED | 1380 lines; exact gates, queue max, cleanup-after-proof, PR-only cleanup, and quoted `basename "$ARTIFACT"` present. |
| `script/check_release_workflow_integrity.exs` | Named semantic scanner | VERIFIED | 329 lines; default/env/argv workflow path support, non-comment scanning, job-level `if`/`needs` parsing, stable `[crosswake] OK/FAIL` check IDs. |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | Merge-blocking adversarial proof | VERIFIED | 221 lines; 11 tests pass and exercise real workflow plus mutated fixtures. |
| `lib/crosswake/release_status.ex` | Local release governance status model | VERIFIED | 549 lines; reads release config/manifest/workflow and reports governance checks from checked-in source. |
| `lib/mix/tasks/crosswake.release.status.ex` | Operator-facing Mix task | VERIFIED | 49 lines; exposes text, JSON, and opt-in `--live` behavior. |
| `test/mix/tasks/crosswake_release_status_test.exs` | Status text/JSON regression proof | VERIFIED | 105 lines; 4 tests pass and lock governance codes plus downstream-scope honesty. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.github/workflows/release-please.yml` | `release-please-config.json` | Release Please paths/components | VERIFIED | Config defines root/native linked group and independent companion components; workflow consumes exact path/component outputs. |
| `script/check_release_workflow_integrity.exs` | `.github/workflows/release-please.yml` | Default scanner path | VERIFIED | `elixir script/check_release_workflow_integrity.exs` reads and validates the real workflow by default. |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | `script/check_release_workflow_integrity.exs` | `System.cmd("elixir", ...)` | VERIFIED | Tests run the real scanner against both real and mutated workflows. |
| `lib/crosswake/release_status.ex` | `.github/workflows/release-please.yml` | Local workflow source read | VERIFIED | `Crosswake.ReleaseStatus.build/1` reads checked-in workflow source for guard posture. |
| `lib/crosswake/release_status.ex` | `script/check_release_workflow_integrity.exs` | Next-action command text | VERIFIED | Governance error messages point to the scanner as authoritative proof. |
| `lib/mix/tasks/crosswake.release.status.ex` | `Crosswake.ReleaseStatus` | Mix task invocation | VERIFIED | Task builds status, renders text or JSON, and raises only on blocking errors. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `script/check_release_workflow_integrity.exs` | `workflow`, `jobs`, `checks` | Real `.github/workflows/release-please.yml` by default, fixture path by argv/env | Yes | VERIFIED |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | Mutated workflow fixtures | Real workflow copied and modified into temp files | Yes | VERIFIED |
| `lib/crosswake/release_status.ex` | `manifest`, `config`, `workflow`, `checks` | `.release-please-manifest.json`, `release-please-config.json`, `.github/workflows/release-please.yml` | Yes | VERIFIED |
| `mix crosswake.release.status --json` | JSON status object | `Crosswake.ReleaseStatus.build/1` | Yes | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Semantic workflow scanner validates actual DAG | `elixir script/check_release_workflow_integrity.exs` | Exit 0; 23 OK checks | PASS |
| Adversarial scanner proof passes | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | 11 tests, 0 failures | PASS |
| Status text/JSON proof passes | `mix test test/mix/tasks/crosswake_release_status_test.exs` | 4 tests, 0 failures | PASS |
| Text status exposes governance without live probes | `mix crosswake.release.status` | Exit 0; `status: warning` only for Phase 144 clean-room warning; governance checks OK | PASS |
| JSON status is scriptable | `mix crosswake.release.status --json` | Exit 0; clean JSON with `schema_version`, `core`, `companions`, `checks` | PASS |
| Status model rejects decoys and cleanup bypasses | `mix run -e <temporary mutated workflow ReleaseStatus decoy check>` | Exit 0; inline path decoy rejected, comment-only aggregate decoy ignored, missing proof need rejected | PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` files or phase-declared probe scripts were found for Phase 142. Probe execution is not applicable; the phase proof surface is the Elixir scanner and focused ExUnit suites above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| RELG-01 | 142-01, 142-02, 142-03 | Maintainers can prove path-specific gates prevent companion-only releases from publishing core/native artifacts. | SATISFIED | Exact workflow gates plus scanner and ExUnit negative fixtures for aggregate behavioral gates. |
| RELG-02 | 142-01, 142-02, 142-03 | Maintainers can prove release publish/proof jobs are not canceled mid-run by newer workflow events. | SATISFIED | `cancel-in-progress: false`, `queue: max`, scanner checks, ExUnit missing-queue/true-cancel fixtures, external GitHub syntax sanity. |
| RELG-03 | 142-01, 142-02, 142-03 | Maintainers can detect stale `release-as` pins only after relevant companion publish succeeds. | SATISFIED | Cleanup waits on publish plus proof success for released components; PR-only cleanup and status `release.release_as_staleness` remain local checks. |

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|---|---|---|
| 1 | Full clean-room exact package/floor validation | Phase 144 | Roadmap Phase 144 goal: repair clean-room harness, use exact companion versions and derived core floors. |
| 2 | Full iOS mirror parity and missing `v0.2.0` backfill | Phase 145 | Roadmap Phase 145 goal: harden mirror token path, decouple native proofs, document/backfill missing tag. |
| 3 | Full release-status DX and docs truth | Phase 146 | Roadmap Phase 146 goal: ship release status, JSON, optional live probes, and reconcile release docs. Phase 142 verifies only governance surfacing. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `.github/workflows/release-please.yml` | 1326 | `_TODO_release_as` in cleanup PR body | INFO | Intentional text naming the release-config cleanup key removed by the PR; not an implementation stub. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in the Phase 142 source files reviewed.

### External Syntax Sanity

Current GitHub Actions workflow syntax documentation says `queue: max` allows multiple pending workflow/job runs in a concurrency group and that `queue: max` conflicts with `cancel-in-progress: true`. The checked workflow uses `queue: max` with `cancel-in-progress: false`, matching the phase contract.

Source: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency

### Human Verification Required

None. The must-haves are static workflow/source invariants with focused automated scanner and ExUnit coverage.

### Gaps Summary

No blocking gaps found. Phase 142's release DAG governance contract is present, substantive, wired into scanner/tests/status output, and behaviorally exercised by focused positive and adversarial checks.

---

_Verified: 2026-07-07T16:26:53Z_
_Verifier: the agent (gsd-verifier)_
