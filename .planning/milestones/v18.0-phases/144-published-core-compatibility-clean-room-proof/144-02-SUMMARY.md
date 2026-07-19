---
phase: 144-published-core-compatibility-clean-room-proof
plan: 02
subsystem: diagnostics
tags: [doctor, router, cleanroom, release-integrity, phoenix]
requires:
  - phase: 144-published-core-compatibility-clean-room-proof
    provides: Plan 01 Hex metadata clean-room dependency proof contract
provides:
  - Doctor-owned app config and router load readiness
  - Fresh Phoenix router regression proof
  - Distinct unavailable-module and non-router diagnostics
  - Static scanner guards against clean-room router preload masking
affects: [doctor, clean-room-proof, release-integrity, phase-144]
tech-stack:
  added: []
  patterns:
    - Mix task `app.config` readiness without app.start
    - Doctor command as the fresh-router proof boundary
    - Static scanner IDs for proof masking regressions
key-files:
  created:
    - test/mix/tasks/crosswake_doctor_router_test.exs
    - .planning/phases/144-published-core-compatibility-clean-room-proof/144-02-SUMMARY.md
  modified:
    - lib/mix/tasks/crosswake.doctor.ex
    - script/verify_companion_cleanroom.sh
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
key-decisions:
  - "The doctor task requires app.config, not app.start, so router diagnostics do not boot host supervision trees."
  - "Router validation requires the module to load and expose Phoenix's __routes__/0 shape before Doctor.run/1 receives it."
  - "The clean-room script may compile setup files, but mix crosswake.doctor --router CleanRoomHost.Router is the proof of router loadability."
patterns-established:
  - "Fresh-router tests use a temporary Mix host with a path dependency on the current repo."
  - "Scanner fixtures mutate real source text and fail on stable doctor-proof IDs."
requirements-completed: [PREF-02]
duration: 17 min
completed: 2026-07-08
status: complete
---

# Phase 144 Plan 02: Doctor Fresh-Router Proof Summary

**`mix crosswake.doctor --router` now owns host config/load readiness, validates fresh Phoenix routers, and rejects missing or non-router modules with distinct diagnostics.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-08T13:22:00Z
- **Completed:** 2026-07-08T13:35:59Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `@requirements ["app.config"]` to the doctor Mix task without using `app.start`.
- Implemented doctor-owned compile/loadpaths retry and Phoenix router shape validation via `__routes__/0`.
- Added a temporary-host regression test covering valid fresh router, unavailable module, and loaded non-router cases.
- Removed clean-room script-side `Code.ensure_loaded?(CleanRoomHost.Router)` proof masking and added scanner/fixture guards for that regression.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add failing doctor router readiness tests** - `867d7a4e` (test)
2. **Task 1: Implement doctor router readiness** - `55bedc8f` (feat)
3. **Task 2: Add failing doctor proof scanner fixtures** - `330a3375` (test)
4. **Task 2: Guard doctor clean-room proof ownership** - `6aa2b918` (feat)

**Plan metadata:** pending in closeout commit.

## Files Created/Modified

- `lib/mix/tasks/crosswake.doctor.ex` - Adds app config requirement, compile/loadpaths retry, router module normalization, and distinct router diagnostics.
- `test/mix/tasks/crosswake_doctor_router_test.exs` - Adds fresh-router, missing-router, and non-router tests using a temp host app.
- `script/verify_companion_cleanroom.sh` - Keeps compile setup but removes external router preload before doctor.
- `script/check_release_workflow_integrity.exs` - Adds doctor task source override and `release.doctor.*` checks.
- `test/crosswake/proof/phase142_release_integrity_test.exs` - Adds `:phase144_doctor` positive and negative fixtures.

## Decisions Made

- `app.config` is the right Mix requirement because it prepares application config without booting endpoint/database/supervision state.
- `__routes__/0` is the minimal Phoenix router shape check needed before passing a module to `Crosswake.Doctor.run/1`.
- Proof masking is guarded at the static scanner layer because the release workflow must not rely on reviewers noticing a stray preload command.

## Deviations from Plan

None - plan implementation followed the planned scope.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The spawned executor again completed implementation commits but did not create `144-02-SUMMARY.md` before shutdown. The orchestrator reran the required verification and wrote this summary manually.

## Verification

- `mix test test/mix/tasks/crosswake_doctor_router_test.exs` - passed, 3 tests / 0 failures
- `mix test test/mix/tasks/crosswake_doctor_test.exs` - passed, 7 tests / 0 failures
- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_doctor` - passed, 4 tests / 0 failures

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 144-03 can consolidate the Phase 144 release-integrity scanner surface now that clean-room dependency exactness and doctor fresh-router ownership both have implementation and fixture coverage.

## Self-Check: PASSED

- Key files exist on disk.
- Commits for `144-02` exist in git history.
- Plan verification commands passed.
- `PREF-02` is ready to mark complete in `.planning/REQUIREMENTS.md`.

---
*Phase: 144-published-core-compatibility-clean-room-proof*
*Completed: 2026-07-08*
