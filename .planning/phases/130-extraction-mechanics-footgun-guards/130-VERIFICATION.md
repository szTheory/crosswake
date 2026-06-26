---
phase: 130-extraction-mechanics-footgun-guards
verified: 2026-06-25T23:00:00Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 130: Extraction Mechanics & Footgun Guards — Verification Report

**Phase Goal:** The `MIX_INCLUDE_*` env hack is gone; `packages/crosswake_rulestead/` exists as a `path:` dep that compiles and tests against core; merge-blocking guards prevent re-coupling.
**Verified:** 2026-06-25T23:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `MIX_INCLUDE_RULESTEAD` and `MIX_INCLUDE_RINDLE` env hack is gone from core `mix.exs` (EXTRACT-01) | VERIFIED | `grep MIX_INCLUDE_ mix.exs` returns empty; commits 92a5d85 + e6df8bd deleted both blocks |
| 2 | `packages/crosswake_rulestead/` exists as a self-contained Hex project with `{:crosswake, path: "../.."}` and NO `runtime: false` (EXTRACT-02) | VERIFIED | `mix.exs` line 50: `{:crosswake, path: "../.."}` confirmed; no `runtime: false` substring found |
| 3 | Companion package compiles and its tests pass against core via the root alias (EXTRACT-02) | VERIFIED | `mix companions.test` ran: 11 tests, 0 failures (1 excluded :engine_present) |
| 4 | EXTRACT-03 static-ref guard is merge-blocking and green against the real post-extraction `lib/` — no Rulestead alias node survives in core (EXTRACT-03) | VERIFIED | `mix test phase130_extraction_guards_test.exs`: 12 tests, 0 failures, 0 skipped; `assert_no_static_refs!/0` green |
| 5 | EXTRACT-04 guard verifies `Code.ensure_loaded?` only inside function bodies in `lib/`, never at module-eval time (EXTRACT-04) | VERIFIED | Same test run: EXTRACT-04 describe block green; 13 `ensure_loaded?` sites confirmed in-body |
| 6 | `Crosswake.CompanionGuard` exposes the real AST walk API with non-vacuous controls (EXTRACT-03 + EXTRACT-04) | VERIFIED | `check_source/1`, `check_ensure_loaded_placement/1`, `assert_no_static_refs!/0`, `assert_ensure_loaded_in_function_bodies!/0`, `extracted_companions/0` all defined; Rulestead alias detected, Sigra alias not flagged (D-14) |
| 7 | With companion dep absent, `RouteGate` denies with `:dependency_missing` before kill-switch (COMPAT-01 D-02), and a `validate_dependency/0` raise still yields `:dependency_missing` (D-08) | VERIFIED | `mix test phase130_fail_closed_contract_test.exs`: 4 tests, 0 failures — SC#5 + D-02 precedence + D-08 raise all green |
| 8 | `:dependency_missing` is the 13th Denial reason; doctor cold path shares the code string and carries `missing_kind: :engine_unvalidated` (D-04/D-05/D-06/COMPAT-01) | VERIFIED | `mix run -e "13 = length(Denial.reasons())"` passes; `doctor.ex` line 592 confirmed `"companion.dependency_missing"` code string + `missing_kind: :engine_unvalidated` |
| 9 | `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` exists with module name `Crosswake.Companions.Rulestead` preserved, `@compile {:no_warn_undefined, Rulestead}`, and `Code.ensure_loaded?` only inside function bodies (EXTRACT-02 + D-29 + EXTRACT-04) | VERIFIED | File confirmed at correct path; `@compile {:no_warn_undefined, Rulestead}` at line 9; all `Code.ensure_loaded?(Rulestead)` calls inside `validate_dependency/0` and `report_state/0` function bodies |
| 10 | Merge-blocking CI (`.github/workflows/phase130-proof.yml`) exists with blocking core + engine-absent lanes; advisory engine-present lane has `continue-on-error: true` and `mix clean` between states (D-33) | VERIFIED | File present (8198 bytes); blocking jobs confirmed; `continue-on-error: true` at line 141; `mix clean` step in advisory job |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/companion_guard.ex` | CompanionGuard with real AST walk | VERIFIED | Exists; `check_source/1` and `check_ensure_loaded_placement/1` fully implemented with `Macro.prewalk/3`; self-false-positive avoided via string-based `@extracted_companion_names` |
| `test/crosswake/proof/phase130_extraction_guards_test.exs` | RED→GREEN proof tests, 0 skips | VERIFIED | 12 tests, 0 failures, 0 skipped (Plan 05 removed `@tag :skip`) |
| `test/crosswake/proof/phase130_fail_closed_contract_test.exs` | COMPAT-01 contract test GREEN | VERIFIED | 4 tests, 0 failures |
| `packages/crosswake_rulestead/mix.exs` | `path:` dep, no `runtime: false`, version marker | VERIFIED | `{:crosswake, path: "../.."}` line 50; `@version "0.1.0" # x-release-please-version` line 4; `files:` excludes `test/`, `priv`, `guides` |
| `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` | Module name preserved, `@compile {:no_warn_undefined}` | VERIFIED | Module name `Crosswake.Companions.Rulestead` confirmed; `@compile {:no_warn_undefined, Rulestead}` at line 9 |
| `packages/crosswake_rulestead/mix.lock` | Committed lock file | VERIFIED | 8310-byte lock file exists |
| `lib/crosswake/compatibility/route_gate.ex` | `check_dependencies/2` wired before kill-switch | VERIFIED | Lines 100-180: `check_dependencies/2` fires at D-02 precedence; `Denial` synthesized inline |
| `lib/crosswake/shell/denial.ex` | `:dependency_missing` as 13th reason | VERIFIED | Line 28: `:dependency_missing` in `@reasons`; line 47: `@type reason` union extended |
| `script/verify_companion_package.sh` | Executable, passes end-to-end | VERIFIED | Executable bit confirmed; `bash script/verify_companion_package.sh crosswake_rulestead` exits OK |
| `script/extract_companion.md` | Parameterized extraction recipe (D-25) | VERIFIED | 10363-byte file present with documented D-19/D-20/D-21/D-22/D-23/D-24/D-25/D-26/D-28/D-29/D-31/D-33 decisions |
| `.github/workflows/phase130-proof.yml` | CI with blocking + advisory lanes | VERIFIED | Three-job workflow; `continue-on-error: true` on advisory lane |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `RouteGate.prepend_gate_evaluation_findings/3` | `check_dependencies/2` | Called first (D-02), before `check_kill_switches` | VERIFIED | Line 109: `check_dependencies(companions, route)` called at head of chain |
| `CompanionGuard.assert_no_static_refs!/0` | `lib/**/*.ex` glob | `Path.wildcard` + `check_source/1` per file | VERIFIED | Lines 186-195: globs `lib/**/*.ex`, calls `check_source/1` per file, raises on violation |
| `packages/crosswake_rulestead/mix.exs` | core `mix.exs` | `{:crosswake, path: "../.."}` | VERIFIED | No `runtime: false`; confirmed wired correctly |
| `mix companions.test` root alias | companion test suite | `cmd --cd packages/crosswake_rulestead mix test` | VERIFIED | Core `mix.exs` lines 57-62: `aliases/0` defines `companions.test` correctly |
| `Doctor.phase_38_companion_seam_findings` | `missing_kind: :engine_unvalidated` | Shared code string `"companion.dependency_missing"` | VERIFIED | `doctor.ex` line 592 + 598 confirm both shared code string and `missing_kind` field |

### Data-Flow Trace (Level 4)

Not applicable — this phase delivers guard logic, proof tests, CI configuration, and a companion package skeleton. No dynamic data rendering components involved.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| EXTRACT-03 guard green (no Rulestead alias in core lib/) | `mix test test/.../phase130_extraction_guards_test.exs` | 12 tests, 0 failures, 0 skipped | PASS |
| COMPAT-01 fail-closed contract (SC#5 + D-02 + D-08) | `mix test test/.../phase130_fail_closed_contract_test.exs` | 4 tests, 0 failures | PASS |
| Companion engine-absent lane | `mix companions.test` | 11 tests, 0 failures (1 excluded) | PASS |
| Denial.reasons() has 13 entries | `mix run -e "13 = length(Denial.reasons())"` | `13 reasons OK` | PASS |
| Verify script dress-rehearsal | `bash script/verify_companion_package.sh crosswake_rulestead` | `OK` — Steps 1+3 pass | PASS |

Note on verify script Step 2: `mix hex.build --unpack` is intentionally skipped with a Phase 131 note because `path:` deps prevent the tarball build. This is documented in Plan 04 deviation #3 and in the script itself — not a gap.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| EXTRACT-01 | Plans 01, 04 | MIX_INCLUDE_* env hack gone; core lists no companion deps | SATISFIED | `grep MIX_INCLUDE_ mix.exs` returns empty; commits 92a5d85 deleted both blocks |
| EXTRACT-02 | Plans 01, 04 | `crosswake_rulestead` standalone Hex project; module name preserved; tests pass | SATISFIED | `mix companions.test` 11/11 pass; module name `Crosswake.Companions.Rulestead` preserved at `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` |
| EXTRACT-03 | Plans 01, 03, 05 | Merge-blocking guard fails build on static companion ref in `lib/` | SATISFIED | `assert_no_static_refs!/0` green; 0 violations in real lib/ post-extraction; non-vacuity: Rulestead alias detected, Sigra alias NOT flagged |
| EXTRACT-04 | Plans 01, 03 | Guard verifies `Code.ensure_loaded?` only inside function bodies | SATISFIED | `assert_ensure_loaded_in_function_bodies!/0` green against real lib/; 13 sites all in-body; non-vacuity: module-eval placement caught as `{:violation, _}` |
| COMPAT-01 | Plans 01, 02 | Doctor + RouteGate fail-closed when companion dep absent | SATISFIED | RouteGate denies with `:dependency_missing` (SC#5); D-02 precedence verified; D-08 raise-path verified; doctor `missing_kind: :engine_unvalidated` confirmed |

All 5 phase requirement IDs (EXTRACT-01, EXTRACT-02, EXTRACT-03, EXTRACT-04, COMPAT-01) mapped in REQUIREMENTS.md as `Complete` for Phase 130. No orphaned requirement IDs.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `lib/crosswake/companion_guard.ex` | `check_source/1` stub (Plan 01) replaced by real AST walk (Plan 03) | None — stub gone | Fully implemented; Plan 03 replaced placeholder bodies |
| No files | No `TBD`/`FIXME`/`XXX` markers found in phase-modified files | — | — |

No debt markers, no stubs remaining in shipped code.

### Pre-existing Test Failures (Not Attributed to Phase 130)

Two broad-suite failures exist and are confirmed pre-existing, not caused by Phase 130:

1. `MilestoneTransitionResetTest` — REQUIREMENTS.md header format mismatch; test files not modified in this phase (confirmed: `git diff` on that file across phase commits returns empty)
2. `Phase52OperatorTruthTest` — JSON fixture drift; test files not modified in this phase

These are documented in STATE.md carried items and the Phase 04/05 summaries. Phase exit gate count: 1160 tests, 2 pre-existing failures.

### Human Verification Required

None. All must-haves are verified programmatically. The behavioral spot-checks confirm runtime correctness of the guard logic and fail-closed enforcement.

---

## Gaps Summary

No gaps. All 10 must-have truths are VERIFIED against the actual codebase. All 5 requirement IDs (EXTRACT-01 through EXTRACT-04, COMPAT-01) are satisfied. All proof tests pass with 0 skips. The phase goal is achieved.

---

_Verified: 2026-06-25T23:00:00Z_
_Verifier: Claude (gsd-verifier)_
