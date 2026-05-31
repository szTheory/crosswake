---
phase: 43-rulestead-hermetic-advisory-proof-and-guide
verified: 2026-05-31T13:57:29Z
status: human_needed
score: 2/3 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Confirm GitHub branch protection requires `merge-blocking-rulestead-proof` on `main`"
    expected: "PRs cannot merge when the hermetic job fails or is missing"
    why_human: "Required-check enforcement is configured in GitHub settings, not in repository files"
---

# Phase 43: Rulestead Hermetic+Advisory Proof And Guide Verification Report

**Phase Goal:** The rulestead seam has a merge-blocking hermetic CI lane that passes without the optional dependency present, an advisory lane with it present, and a `guides/companions.md` rulestead section locked by a docs-contract test.
**Verified:** 2026-05-31T13:57:29Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Hermetic lane runs without optional dep, asserts fail-closed behavior, and is merge-blocking | ? UNCERTAIN (WARNING) | Workflow has `merge-blocking-rulestead-proof` on `pull_request`/`push`/`workflow_dispatch`, no `MIX_INCLUDE_RULESTEAD` in hermetic steps, and runs `mix test --exclude requires_example_host --exclude advisory_only` in [.github/workflows/phase43-proof.yml](/Users/jon/projects/crosswake/.github/workflows/phase43-proof.yml). Local hermetic run passed: `391 tests, 0 failures`. Required-check enforcement in GitHub branch protection is not verifiable from repo files. |
| 2 | Advisory lane runs with optional dep present and stays advisory with promotion path | ✓ VERIFIED | Advisory job is `continue-on-error: true`, scoped to `schedule/workflow_dispatch`, and sets step-level `MIX_INCLUDE_RULESTEAD: \"1\"` for deps/compile/test in [.github/workflows/phase43-proof.yml](/Users/jon/projects/crosswake/.github/workflows/phase43-proof.yml). Promotion conditions and `Rulestead.Snapshot` are documented in workflow header and [guides/companions.md](/Users/jon/projects/crosswake/guides/companions.md). |
| 3 | `guides/companions.md` rulestead section exists and is locked by docs-contract test | ✓ VERIFIED | Guide includes required anchors (`gated_by`, `on_unavailable`, `kill_switch`, `MockFlagSource`, `fail-closed`) in [guides/companions.md](/Users/jon/projects/crosswake/guides/companions.md). Docs-contract in [test/crosswake/guides/companions_test.exs](/Users/jon/projects/crosswake/test/crosswake/guides/companions_test.exs) passed locally (`9 tests, 0 failures`) and checks `function_exported?/3` for live symbols. |

**Score:** 2/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | Conditional rulestead dep + docs extras entry | ✓ VERIFIED | `MIX_INCLUDE_RULESTEAD` conditional `{:rulestead, \"~> 0.1.6\"}` and `\"guides/companions.md\"` in docs extras present in [mix.exs](/Users/jon/projects/crosswake/mix.exs). |
| `.github/workflows/phase43-proof.yml` | Hermetic + advisory CI split | ✓ VERIFIED | Two jobs exist; hermetic run excludes `advisory_only`; advisory is `continue-on-error` with step env and schedule cron in [.github/workflows/phase43-proof.yml](/Users/jon/projects/crosswake/.github/workflows/phase43-proof.yml). |
| `test/crosswake/proof/phase43_rulestead_advisory_test.exs` | Advisory assertion `validate_dependency/0 == :ok` | ✓ VERIFIED | Module exists, tagged `@moduletag :advisory_only`, and asserts `Crosswake.Companions.Rulestead.validate_dependency() == :ok` in [phase43_rulestead_advisory_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase43_rulestead_advisory_test.exs). |
| `guides/companions.md` | Rulestead docs slice with contract anchors | ✓ VERIFIED | Required DSL/behavior anchors and promotion path language present in [guides/companions.md](/Users/jon/projects/crosswake/guides/companions.md). |
| `test/crosswake/guides/companions_test.exs` | Docs-contract + live symbol guards | ✓ VERIFIED | `File.read!` anchor assertions and export checks for `validate_dependency/0`, `MockFlagSource.set_flag/2`, `SupportMatrix.gating_truth/0` in [companions_test.exs](/Users/jon/projects/crosswake/test/crosswake/guides/companions_test.exs). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| advisory workflow job | conditional dep include | `MIX_INCLUDE_RULESTEAD=1` on deps/compile/test steps | ✓ WIRED | Three step-level env bindings in [.github/workflows/phase43-proof.yml](/Users/jon/projects/crosswake/.github/workflows/phase43-proof.yml), consumed by `System.get_env(\"MIX_INCLUDE_RULESTEAD\")` in [mix.exs](/Users/jon/projects/crosswake/mix.exs). |
| advisory workflow job | advisory proof test | explicit file run | ✓ WIRED | `mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs` in workflow. |
| docs-contract test | guide content | `File.read!` + anchor assertions | ✓ WIRED | `@guide_path` + `setup_all` content map used across assertions in [companions_test.exs](/Users/jon/projects/crosswake/test/crosswake/guides/companions_test.exs). |
| docs-contract test | live code symbols | `function_exported?/3` guards | ✓ WIRED | Export checks for companion and support matrix APIs present and passing. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| docs-contract test | `content` | `File.read!(guides/companions.md)` | Yes | ✓ FLOWING |
| advisory proof test | `validate_dependency/0` result | `Crosswake.Companions.Rulestead` runtime check | Yes (when dep present) | ⚠️ STATICALLY WIRED; runtime pass in this workspace not re-executed due hermetic lock posture |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs-contract test passes | `mix test test/crosswake/guides/companions_test.exs` | `9 tests, 0 failures` | ✓ PASS |
| Hermetic proof lane behavior passes without optional dep | `mix test --exclude requires_example_host --exclude advisory_only` | `391 tests, 0 failures (39 excluded)` | ✓ PASS |
| Hermetic lock state excludes rulestead | `grep -c "rulestead" mix.lock` | `0` | ✓ PASS |
| Advisory test runnable in this hermetic workspace | `MIX_INCLUDE_RULESTEAD=1 mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs` | Fails before run: dependency unavailable without `mix deps.get` in this lock posture | ? SKIP (verified via CI wiring instead) |

### Probe Execution

Step 7c: SKIPPED (no phase-specific `scripts/*/tests/probe-*.sh` declared or present).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 43-01 | Hermetic merge-blocking lane + advisory lane with dep present | ? NEEDS HUMAN | Workflow and tests are correctly wired; human confirmation needed for branch protection required-check enforcement on GitHub. |
| PROOF-02 (Phase 43 slice) | 43-02 | Rulestead section in `guides/companions.md` with docs-contract lock | ✓ SATISFIED | Guide + docs-contract test implemented and passing locally. |
| PROOF-02 (global) | REQUIREMENTS/ROADMAP | Full companions arc guide (rulestead+rindle+sigra + deferred non-goals) | ℹ️ DEFERRED | Explicitly pending for Phase 47 in `.planning/REQUIREMENTS.md`; not a Phase 43 blocker. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER` markers found in Phase 43 key files | ℹ️ Info | No debt-marker blockers detected. |

### Human Verification Required

### 1. Merge Gate Enforcement

**Test:** In GitHub branch protection for `main`, verify `merge-blocking-rulestead-proof` is a required status check.  
**Expected:** PR merge is blocked when this job fails or is absent.  
**Why human:** Required-check policy lives in GitHub settings, outside the repository.

### Warnings

- Local advisory execution was not re-run in this hermetic lock state because optional dependency installation is intentionally excluded from committed lockfile posture; advisory behavior is verified through workflow wiring and test contract.
- `PROOF-02` remains globally pending until Phase 47 by roadmap contract; this does not invalidate the Phase 43 rulestead documentation slice.

---

_Verified: 2026-05-31T13:57:29Z_  
_Verifier: the agent (gsd-verifier)_
