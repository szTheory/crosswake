---
phase: 144-published-core-compatibility-clean-room-proof
plan: 01
subsystem: release
tags: [cleanroom, hex, release-integrity, companion-packages, proof]
requires:
  - phase: 143-guarded-auto-publish-train
    provides: guarded automatic Hex publish and exact-ref recovery workflow
provides:
  - Hex metadata-derived clean-room core floor proof
  - Exact companion dependency pinning for package-family clean-room hosts
  - Lockfile postconditions for selected companion and core versions
  - Phase 144 clean-room scanner IDs and ExUnit fixtures
affects: [release-workflow, clean-room-proof, companion-compatibility, phase-144]
tech-stack:
  added: []
  patterns:
    - Hex release metadata as clean-room dependency authority
    - Post-resolution mix.lock assertions as proof postconditions
    - Stable scanner IDs with adversarial fixture mutations
key-files:
  created:
    - .planning/phases/144-published-core-compatibility-clean-room-proof/144-01-SUMMARY.md
  modified:
    - script/verify_companion_cleanroom.sh
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
key-decisions:
  - "Clean-room proof derives the core floor from Hex release metadata requirements.crosswake.requirement for the exact package/version under test."
  - "Companion dependencies are generated as == VERSION and verified again through mix.lock."
  - "Chimeway and threadline keep explicit sibling-absence postconditions instead of relying on resolver behavior by inspection."
patterns-established:
  - "Release proof scripts fail closed on bad package/version/metadata states before generating clean-room Mix files."
  - "Static release-integrity checks strip full-line comments and assert stable OK/FAIL IDs."
requirements-completed: [PREF-01]
duration: 9 min
completed: 2026-07-08
status: complete
---

# Phase 144 Plan 01: Published Hex Metadata Clean-Room Proof Summary

**Companion clean-room proof now derives its core floor from exact Hex release metadata, pins the companion version exactly, and verifies resolver output through mix.lock.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-08T13:14:39Z
- **Completed:** 2026-07-08T13:20:50Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced local package-source floor derivation with an allowlisted Hex release metadata flow that reads `requirements.crosswake.requirement`.
- Added exact companion pinning, selected-version lockfile assertions, and sibling-absence checks for chimeway and threadline.
- Added Phase 144 clean-room scanner IDs and ExUnit fixtures for Hex metadata authority, exact pins, lockfile postconditions, package profiles, and fail-closed metadata cases.

## Task Commits

Each task was committed atomically:

1. **Task 1: Harden clean-room dependency authority and lockfile postconditions** - `8dde5dfb` (feat)
2. **Task 2: Add Phase 144 clean-room scanner fixtures** - `53037fad` (test)
3. **Task 2: Enforce clean-room scanner IDs** - `94436f08` (test)

**Plan metadata:** pending in closeout commit.

## Files Created/Modified

- `script/verify_companion_cleanroom.sh` - Adds package profiles, Hex metadata fetch/parsing, exact companion requirements, lockfile postconditions, sibling-absence checks, and calm operator output.
- `script/check_release_workflow_integrity.exs` - Adds `CLEANROOM_SCRIPT_PATH` support and four `release.cleanroom.*` scanner checks.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Adds `:phase144_cleanroom` positive and negative fixture coverage.

## Decisions Made

- Hex release metadata is the release-truth authority for the clean-room core floor because the proof runs after publish and must validate the artifact as published.
- The companion package is exact-pinned as `== ${VERSION}` and then rechecked in `mix.lock`, so generated dependency text and resolver output both need to agree.
- Package-profile preservation stays explicit for all five packages, including chimeway's Sigra-free boundary and threadline's observer/non-companion boundary.

## Deviations from Plan

None - plan implementation followed the planned scope.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The spawned executor produced the implementation commits but stalled before writing `144-01-SUMMARY.md`. The orchestrator closed the agent, reran the plan verification, and wrote this summary manually to restore the required GSD closeout state.

## Verification

- `bash -n script/verify_companion_cleanroom.sh` - passed
- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom` - passed, 7 tests / 0 failures

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 144-02 can now build on the clean-room harness contract: dependency proof exactness is guarded by script logic, scanner IDs, and ExUnit fixtures. Doctor-owned fresh-router loading remains the next wave.

## Self-Check: PASSED

- Key files exist on disk.
- Commits for `144-01` exist in git history.
- Plan verification commands passed.
- `PREF-01` is marked complete in `.planning/REQUIREMENTS.md`.

---
*Phase: 144-published-core-compatibility-clean-room-proof*
*Completed: 2026-07-08*
