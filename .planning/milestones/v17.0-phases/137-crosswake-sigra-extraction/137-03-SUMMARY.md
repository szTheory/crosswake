---
phase: 137-crosswake-sigra-extraction
plan: "03"
subsystem: sigra-extraction
tags: [extraction, sigra, tests, cleanroom-proof, dress-rehearsal]
dependency_graph:
  requires: [137-02]
  provides: [crosswake_sigra-test-lane, sigra-cleanroom-proof, dress-rehearsal-green]
  affects: [core-test-suite, crosswake_sigra-package]
tech_stack:
  added:
    - packages/crosswake_sigra test lane (137 tests)
    - inline test stubs for absent companions in package lane
  patterns:
    - put_env sigra registration pattern for non-vacuous package-lane tests
    - sentinel assertion pattern for core tests (is_list checks replacing in-assertions)
    - async: false + on_exit restore for companion registry tests
key_files:
  created:
    - packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase55_session_handoff_tickets_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase47_companion_arc_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase57_auth_return_boundaries_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase46_sigra_auth_contract_test.exs
    - packages/crosswake_sigra/test/crosswake/proof/phase47_companion_arc_test.exs
    - packages/crosswake_sigra/test/crosswake/compatibility/route_gate_test.exs
    - packages/crosswake_sigra/test/crosswake/operator_inspection/operator_inspection_test.exs
    - packages/crosswake_sigra/test/crosswake/doctor/publish_readiness_test.exs
  modified:
    - guides/companion_compatibility.md (added crosswake_sigra row)
    - test/crosswake/companions/chimeway/resolver_test.exs (expect :dependency_missing)
    - test/crosswake/doctor/doctor_test.exs (sentinel assertions)
    - test/crosswake/guides/companions_test.exs (removed sigra runtime assertions)
    - test/crosswake/support_matrix/support_matrix_test.exs (sentinel assertions)
    - test/crosswake/proof/phase55_session_handoff_tickets_test.exs (host-only stripped)
    - test/fixtures/proof/phase52_operator_inspection.json (regenerated without sigra)
    - test/fixtures/proof/phase52_publish_readiness.json (regenerated without sigra)
    - test/crosswake/proof/phase52_operator_truth_test.exs (phase52 fixture regen)
decisions:
  - "SupportMatrix assertion moved to package: core cannot have sigra path dep (circular dep); put_env used in package for non-vacuity"
  - "operator_inspection and publish_readiness tests moved to package: runtime calls to sigra module functions fail in core without sigra in _build"
  - "chimeway resolver_test updated to expect :dependency_missing (fail-closed) instead of :step_up_required (correct behavior without sigra companion)"
  - "phase47 inline stubs: StubRulesteadAbsent/StubRindleAbsent defined inline in package test (core test support not in package load path)"
  - "phase52 fixtures regenerated: sentinel output without sigra; non-vacuous data now exclusively in package test lane"
metrics:
  duration: "~43 minutes (this session; total plan execution ~2 sessions)"
  completed: "2026-07-01"
  tasks_completed: 3
  files_changed: 26
status: complete
---

# Phase 137 Plan 03: Sigra Package Test Migration + Clean-Room Proof Summary

Extracted sigra test suite to `crosswake_sigra` package, created non-vacuous clean-room proof, and achieved dress rehearsal green on both core (1029 tests) and package (137 tests) lanes.

## What Was Built

**Task 1 (prior session):** Scaffold `packages/crosswake_sigra/` skeleton, move all sigra source, remove from core companions env. Committed at `a18c3e81`.

**Task 2 (prior session):** Move sigra-internal unit tests to package. Split `phase54_sigra_session_authority_test.exs` (6 tests → package; SupportMatrix assertion → new `phase54_sigra_support_truth_test.exs` in package with `put_env`). Committed at `24510cca`.

**Task 3 (this session):** Non-vacuous clean-room proof + full dress rehearsal. Committed at `b92e0015`.

### Clean-Room Proof

`packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs`:
- Defines inline `AuthRouter` with `auth_min_level: :mfa` route
- `setup` registers `Crosswake.Companions.Sigra` via `Application.put_env` with `on_exit` restore
- Calls `RouteGate.evaluate/4` and asserts `decision.denial.reason == :step_up_required`
- `refute decision.denial.reason == :dependency_missing` — proves non-vacuity
- 1 test, 0 failures

## Deviations from Plan

### Auto-fixed Issues (Rule 3 — Blocking)

**1. [Rule 3 - Blocking] Core compile errors: struct patterns on sigra modules**
- **Found during:** Task 3 dress rehearsal (`mix test --exclude requires_example_host`)
- **Issue:** After sigra extraction, 8+ core test files had compile-time struct patterns on sigra modules (`%Contracts.AuthContext{}`, `%Crosswake.Companions.Sigra.*{}`). Without sigra in core's deps, these files fail to compile.
- **Files moved to package:** `route_gate_test.exs`, `phase46_sigra_auth_contract_test.exs`, `phase47_companion_arc_test.exs`, `phase57_auth_return_boundaries_test.exs`, `phase58_auth_diagnostics_closeout_test.exs`, `phase71_notification_workflow_proof_test.exs`, `phase55_session_handoff_tickets_test.exs` (stripped to host-only in core)
- **Path adjustments:** `../../examples/phoenix_host/...`, `../../guides/...`, `../../.planning/...` prefixes for files in `packages/crosswake_sigra/test/`
- **Commit:** `b92e0015`

**2. [Rule 3 - Blocking] Runtime errors: sigra module not in core BEAM load path**
- **Found during:** Task 3 dress rehearsal after compile errors resolved
- **Issue:** Even with `Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])`, core tests that call into `SupportMatrix.auth_contract_truth()`, `Doctor.run()`, or `OperatorInspection.inspect()` fail at runtime because `Crosswake.Companions.Sigra.companion_id/0` is undefined (module not in `_build/`).
- **Files requiring runtime-module-availability moved to package:** `operator_inspection_test.exs`, `publish_readiness_test.exs`
- **Core tests updated with sentinel assertions:** `support_matrix_test.exs`, `doctor_test.exs` — changed `in row.denial_codes` / `in row.telemetry.event_names` assertions to `is_list(...)` with comments explaining non-vacuous coverage is in package lane
- **Commit:** `b92e0015`

**3. [Rule 3 - Blocking] StubCompanion / StubRulesteadAbsent unavailable in package**
- **Found during:** Package test run after moving files
- **Issue:** `Crosswake.TestSupport.StubCompanion`, `StubRulesteadAbsentCompanion`, `StubRindleAbsentCompanion` are core test support modules compiled only during `mix test` of core; they're not in the package's compiled library load path.
- **Fix:** (a) Removed `StubCompanion` from package operator_inspection/publish_readiness setup (only `Crosswake.Companions.Sigra` needed for auth contract truth); (b) Defined inline `StubRulesteadAbsent` / `StubRindleAbsent` module stubs within phase47 package test — mirrors the absent-engine pattern without needing core test support.
- **Commit:** `b92e0015`

**4. [Rule 3 - Blocking] chimeway/resolver_test.exs expected :step_up_required but got :dependency_missing**
- **Found during:** Core dress rehearsal
- **Issue:** Test registered sigra via `put_env` but sigra module not in core's load path — `companion_id/0` undefined. Root cause: this is the CORRECT fail-closed behavior in core without sigra.
- **Fix:** Updated test to expect `:dependency_missing` (fail-closed sentinel). Integration test for `:step_up_required` lives in `phase137_sigra_cleanroom_test.exs` in the package.
- **Commit:** `b92e0015`

**5. [Rule 3 - Blocking] phase52 JSON fixtures drifted from sentinel output**
- **Found during:** Core dress rehearsal
- **Issue:** `test/fixtures/proof/phase52_operator_inspection.json` and `phase52_publish_readiness.json` contain sigra-era populated arrays for `denial_codes`, `safe_detail_keys`, `telemetry.event_names`. Without sigra in core's runtime, actual output has `[]` for these fields, causing fixture comparison failure.
- **Fix:** Regenerated both fixtures by running a temporary fixture-generation test. Updated `phase52_operator_truth_test.exs` to NOT register sigra in setup (can't - runtime error).
- **Commit:** `b92e0015`

**6. [Rule 2 - Missing] crosswake_sigra missing from companion_compatibility.md**
- **Found during:** Task 3 (`phase132_compat_matrix_drift_test.exs` failure)
- **Issue:** The drift test scans `packages/crosswake_*/mix.exs` and requires each package to have a row in the companion compatibility matrix. `crosswake_sigra` was extracted without adding its row.
- **Fix:** Added `crosswake_sigra | :sigra | 0.1.0 | ~> 0.1 | {:sigra, "~> 0.1", optional: true} | hexdocs` row.
- **Commit:** `b92e0015`

**7. [Rule 3 - Blocking] phase71 missing put_env setup — :dependency_missing instead of :step_up_required**
- **Found during:** Package suite run
- **Issue:** `phase71_notification_workflow_proof_test.exs` was moved verbatim but had no module-level setup registering sigra, causing RouteGate to return :dependency_missing.
- **Fix:** Added `setup do ... Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra]) ... on_exit restore end`.
- **Commit:** `b92e0015`

## Dress Rehearsal Results

### Core Suite
`mix test --exclude requires_example_host --exclude engine_present`
- **1029 tests, 0 failures, 61 excluded**
- Compile: clean

### Package Suite
`mix cmd --cd packages/crosswake_sigra mix test`
- **137 tests, 0 failures**
- Compile: clean

## Threat Flags

None — this plan moves existing test files and creates proof tests. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/proof/phase46_sigra_auth_contract_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/proof/phase47_companion_arc_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/proof/phase55_session_handoff_tickets_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/proof/phase57_auth_return_boundaries_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/proof/phase71_notification_workflow_proof_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/compatibility/route_gate_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/operator_inspection/operator_inspection_test.exs: FOUND
- packages/crosswake_sigra/test/crosswake/doctor/publish_readiness_test.exs: FOUND
- guides/companion_compatibility.md: FOUND (crosswake_sigra row added)
- Commits: a18c3e81 (task 1), 24510cca (task 2), b92e0015 (task 3)
- Core suite: 1029 tests, 0 failures
- Package suite: 137 tests, 0 failures
