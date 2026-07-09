---
phase: 142-release-graph-governance-contract
plan: 03
subsystem: release-ops
tags: [elixir, mix-task, release-status, release-governance, json]

# Dependency graph
requires:
  - phase: 142-release-graph-governance-contract
    provides: release workflow governance checks and semantic proof from plans 01 and 02
provides:
  - Operator-visible release governance status checks for queueing, identity gates, and cleanup-after-proof
  - Focused text and JSON regression coverage for governance codes and downstream-scope honesty
affects: [release-status, release-governance, operator-cli, phase-146]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Local workflow source checks in Crosswake.ReleaseStatus
    - Deterministic default status output with opt-in live probes

key-files:
  created:
    - lib/crosswake/release_status.ex
    - lib/mix/tasks/crosswake.release.status.ex
    - test/mix/tasks/crosswake_release_status_test.exs
  modified: []

key-decisions:
  - "Mirrored the existing semantic workflow scanner in the release-status model instead of adding a separate governance status model."
  - "Kept downstream PREF, MIRR, and STAT ownership out of release-status completion claims."

patterns-established:
  - "Governance status checks use stable release.governance_* codes and calm next-action error messages."
  - "mix crosswake.release.status remains local/read-only by default; --live is the only registry-probe path."

requirements-completed: [RELG-01, RELG-02, RELG-03]

# Metrics
duration: 35 min
completed: 2026-07-07
status: complete
---

# Phase 142 Plan 03: Release Status Governance Summary

**Local release-status output now exposes Phase 142 governance posture with stable check codes while avoiding downstream requirement-completion claims.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-07-07T15:24:48Z
- **Completed:** 2026-07-07T16:00:24Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `release.governance_queue_max`, `release.governance_behavioral_identity_gates`, and `release.governance_cleanup_after_proof` to `Crosswake.ReleaseStatus.build/1`.
- Kept `mix crosswake.release.status` local/read-only by default, with registry probes still only behind `--live`.
- Added text and JSON regression tests proving governance codes are visible and downstream requirement IDs are not rendered as completion claims.

## Task Commits

1. **Task 1 RED: release governance status checks** - `e3e91584` (test)
2. **Task 1 GREEN: release governance status checks** - `67ee24c0` (feat)
3. **Task 2: downstream-claim regression proof** - `9ed87000` (test)

## Files Created/Modified

- `lib/crosswake/release_status.ex` - Builds local release status, adds workflow governance checks, and keeps live probes opt-in.
- `lib/mix/tasks/crosswake.release.status.ex` - Documents the read-only local default for the operator-facing Mix task.
- `test/mix/tasks/crosswake_release_status_test.exs` - Covers governance check codes in build/text/JSON output and downstream-scope honesty.

## Decisions Made

- Mirrored the existing Phase 142 semantic scanner with targeted local string/block checks in `Crosswake.ReleaseStatus`; no YAML parser or new dependency was added.
- Governance error messages include the authoritative next command: `elixir script/check_release_workflow_integrity.exs`.
- The status surface reports RELG-owned facts only; downstream PREF, MIRR, and STAT work remains owned by later phases.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Task 2's new no-overclaim assertions passed immediately because the current status messages already avoided downstream requirement IDs. No production change was required for that task; the regression proof was committed as a test-only change.

## Verification

- `mix test test/mix/tasks/crosswake_release_status_test.exs` - passed, 4 tests, 0 failures.
- `elixir script/check_release_workflow_integrity.exs` - passed, all release governance checks reported OK.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs` - passed, 9 tests, 0 failures.

## Known Stubs

None. Stub-pattern scan found only legitimate empty-list comparisons in release-status control flow.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 142 release-governance status is visible through the operator CLI and JSON output. Later PREF, MIRR, and STAT phases can validate their own already-present spillover without this plan claiming those downstream requirements complete.

## Self-Check: PASSED

- Found: `lib/crosswake/release_status.ex`
- Found: `lib/mix/tasks/crosswake.release.status.ex`
- Found: `test/mix/tasks/crosswake_release_status_test.exs`
- Found commit: `e3e91584`
- Found commit: `67ee24c0`
- Found commit: `9ed87000`

---
*Phase: 142-release-graph-governance-contract*
*Completed: 2026-07-07*
