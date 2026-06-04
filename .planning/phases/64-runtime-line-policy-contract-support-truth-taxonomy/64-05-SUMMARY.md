---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
plan: 05
subsystem: doctor
tags: [elixir, doctor, proof, evidence-taxonomy, rebuild-policy, rline_02]

# Dependency graph
requires:
  - phase: 64-04
    provides: "Doctor formatter extensions (rebuild_matrix + evidence_posture), all delivered early"
provides:
  - "RLINE-02 proof accessor green-up: canonical compatibility sourced from Types.new_compatibility/0"
  - "Full phase-64 proof lane green (rline_01..05, 18 tests)"
affects:
  - "64-06 — phase 64 closeout verification (proof lane fully green)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Proof test canonical-source pattern: Types.new_compatibility/0 is the canonical compatibility record, not SupportMatrix.canonical().compatibility"

key-files:
  created: []
  modified:
    - "test/crosswake/proof/phase64_runtime_line_policy_test.exs — rline_02 accessor fixed: SupportMatrix.canonical().compatibility → Types.new_compatibility(); stable_id via/source-file updated"

key-decisions:
  - "Use Types.new_compatibility/0 directly as the canonical compatibility source in proof tests — SupportMatrix.t() has no :compatibility field (RLINE-02 invariant must not be violated by adding one)"
  - "Doctor implementation verified as fully delivered by plan 64-04; plan 64-05 net change is proof accessor correction only"

patterns-established:
  - "Proof tests that need the canonical manifest compatibility record should call Types.new_compatibility/0 directly, not traverse SupportMatrix.canonical() (which returns a SupportMatrix.t(), not a manifest root)"

requirements-completed: [RLINE-03, RLINE-04]

# Metrics
duration: ~20min
completed: 2026-06-04
---

# Phase 64 Plan 05: Doctor Rebuild Matrix + Evidence Posture Formatter Summary

**RLINE-02 proof-accessor green-up + verification of doctor formatter changes pre-delivered by plan 64-04 (Wave 2)**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-06-04T02:00:00Z
- **Completed:** 2026-06-04T02:20:00Z
- **Tasks:** 1 (proof fix only — doctor implementation verified as pre-delivered)
- **Files modified:** 1

## Accomplishments

- Fixed the single failing rline_02 proof assertion: `"canonical manifest compatibility.manifest_schema_version is 1.0.0"` now correctly sources from `Types.new_compatibility()` (the canonical compatibility record used by `Manifest.Builder.build/3`) instead of the broken `SupportMatrix.canonical().compatibility` accessor (SupportMatrix.t() has no `:compatibility` field)
- Updated stable_id `via` and `source-file` metadata to reflect the real canonical source (`Crosswake.Manifest.Types.new_compatibility/0`, `lib/crosswake/manifest/types.ex`)
- Verified that all plan 64-05 success criteria were already satisfied by plan 64-04 (Wave 2):
  - `doctor.ex` `release_policy_snapshot/1` carries `rebuild_matrix` and `evidence_posture`
  - `formatter.ex` has `format_rebuild_matrix/1`, `format_evidence_tier/1`, `format_evidence_posture/1`, and the "rebuild & compatibility matrix:" + "evidence posture:" lines in the FULL `format_release_policy/1` clause
  - `json_formatter.ex` exposes `rebuild_matrix` at top-level in `render/1` via `format_runtime_line_row/1`
  - RLINE-03, RLINE-04, RLINE-05 proof tests all passing
- Full phase-64 proof lane: **18 tests, 0 failures** (rline_01, rline_02, rline_03, rline_04, rline_05, hermetic lane guard)

## Task Commits

1. **RLINE-02 proof accessor fix** — `ec35ade` (fix)

## Files Created/Modified

- `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — `rline_02` test "canonical manifest compatibility.manifest_schema_version is 1.0.0": replaced `SupportMatrix.canonical().compatibility` with `Types.new_compatibility()`; updated stable_id `via` from `SupportMatrix.canonical/0 → compatibility.manifest_schema_version` to `Crosswake.Manifest.Types.new_compatibility/0 → manifest_schema_version`; updated `source_file` from `lib/crosswake/support_matrix/support_matrix.ex` to `lib/crosswake/manifest/types.ex`

## Decisions Made

- Use `Types.new_compatibility()` directly as the canonical compatibility source — `SupportMatrix.canonical/0` returns `SupportMatrix.t()` which correctly has NO `:compatibility` field (RLINE-02 invariant); adding one would violate the "no new manifest field" contract
- Doctor implementation not re-implemented — verified as fully delivered by plan 64-04

## Deviations from Plan

### Early Delivery by Wave 2

**[Wave 2 Over-delivery] Doctor formatter changes fully implemented by plan 64-04**
- **Context:** Plan 64-04 (Wave 2) over-delivered and implemented ALL of plan 64-05's declared doctor changes before plan 64-05 executed.
- **What was pre-delivered:**
  - `lib/crosswake/doctor/doctor.ex` — `release_policy_snapshot/1` carries `rebuild_matrix: SupportMatrix.rebuild_matrix(support_matrix)` and `evidence_posture: evidence_posture_snapshot(support_matrix)` (with private `evidence_posture_snapshot/1`)
  - `lib/crosswake/doctor/formatter.ex` — `format_rebuild_matrix/1`, `format_evidence_tier/1` (`:jvm_hermetic -> "jvm-hermetic (CI only)"`, `:device_verified -> "device-verified"`), `format_evidence_posture/1`, and additive FULL `format_release_policy/1` clause with both the "evidence posture:" line and "rebuild & compatibility matrix:" block
  - `lib/crosswake/doctor/json_formatter.ex` — `rebuild_matrix` at top-level in `render/1` via `format_runtime_line_row/1`; RLINE-03/04/05 proof tests all passing
- **Plan 64-05 action:** Verified success criteria hold, fixed the one remaining proof accessor bug (RLINE-02), and committed
- **No re-implementation:** Plan 64-05's doctor task declarations were not re-executed; the pre-delivered code was confirmed correct

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fix rline_02 proof accessor — SupportMatrix.canonical() has no :compatibility field**
- **Found during:** Verification step (proof lane run)
- **Issue:** Test "canonical manifest compatibility.manifest_schema_version is 1.0.0" did `manifest = SupportMatrix.canonical(); compat = manifest.compatibility` — but `SupportMatrix.canonical/0` returns `%Crosswake.Manifest.Types.SupportMatrix{}` (the support matrix struct), which has no `:compatibility` field. This is a proof-scaffold bug inherited from plan 64-01/64-02, owned by no other plan.
- **Fix:** Changed to `compat = Types.new_compatibility()` — the canonical compatibility record used by `Manifest.Builder.build/3`. Also updated `via` and `source-file` metadata in the stable_id message to reflect the real source.
- **Files modified:** `test/crosswake/proof/phase64_runtime_line_policy_test.exs`
- **Commit:** ec35ade

## Test Results

- `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs`: 18 tests, 0 failures
- `mix compile --warnings-as-errors`: clean
- Full suite worktree: 785 tests, 37 failures — all pre-existing environment conditions:
  - 3 `MilestoneTransitionResetTest` failures (known milestone-brittleness, fail identically on main)
  - ~34 tests requiring `CrosswakeExample.*` modules (worktree does not have example host `_build` compiled — pre-existing environment condition documented in 64-04 SUMMARY)
  - Main project full suite: 4 failures pre-phase (3 MilestoneTransitionResetTest + the rline_02 accessor bug this plan fixes); post-fix the main project would show 3 failures (MilestoneTransitionResetTest only)

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Test-file-only change.

## Self-Check: PASSED

- `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — modified, exists
- Commit ec35ade exists in git log
- `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs`: 18 tests, 0 failures
- `mix compile --warnings-as-errors`: clean

---
*Phase: 64-runtime-line-policy-contract-support-truth-taxonomy*
*Completed: 2026-06-04*
