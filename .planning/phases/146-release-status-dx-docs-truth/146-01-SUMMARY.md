---
phase: 146-release-status-dx-docs-truth
plan: 01
subsystem: release-ops
tags: [mix-task, release-status, scanner, json, proof]

requires:
  - phase: 144-published-core-compatibility-clean-room-proof
    provides: clean-room and doctor scanner evidence IDs
  - phase: 145-native-registry-mirror-parity
    provides: native registry and mirror scanner evidence IDs
provides:
  - scanner-backed local release status checks for Phase 142-145 release integrity
  - current clean-room proof evidence in release status output
  - stable check fields for JSON automation
affects: [phase-146, release-status, package-family-release-ops]

tech-stack:
  added: []
  patterns:
    - scanner-backed status checks
    - read-only release diagnostics
    - stable check maps

key-files:
  created:
    - .planning/phases/146-release-status-dx-docs-truth/146-01-SUMMARY.md
  modified:
    - lib/crosswake/release_status.ex
    - lib/mix/tasks/crosswake.release.status.ex
    - test/mix/tasks/crosswake_release_status_test.exs

key-decisions:
  - "Release status now consumes `script/check_release_workflow_integrity.exs` IDs as evidence instead of duplicating clean-room proof policy."
  - "Clean-room status is a current `ok` proof check when scanner IDs pass, not stale Phase 144 caveat copy."

patterns-established:
  - "Scanner evidence groups map stable release-integrity IDs onto release-status check codes."
  - "Every status check carries `code`, `status`, `message`, `source`, and `next_action` for downstream automation."

requirements-completed: [STAT-01]

duration: 34 min
completed: 2026-07-09
status: complete
---

# Phase 146 Plan 01: Local Scanner-Backed Status Truth Summary

**Release status now reports local package-family truth from checked-in source plus scanner evidence, with stale Phase 144 clean-room copy removed.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-07-09T12:54:00Z
- **Completed:** 2026-07-09T13:28:25Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Replaced the stale `PREF validation remains Phase 144` clean-room caveat with a scanner-backed `release.cleanroom_dependency_floor` check.
- Wired workflow path gates, queue/cancel policy, behavioral identity gates, cleanup-after-proof, native proof, mirror-token preflight, and floor honesty to stable scanner IDs.
- Added stable `source`, `next_action`, and `evidence` fields to release-status checks and focused tests that reject stale public GSD requirement wording.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace stale local evidence with scanner-backed status checks** - `698d0d44` (feat)
2. **Task 2: Update local status text and tests for current release evidence** - `698d0d44` (feat)

**Plan metadata:** recorded in the current docs commit.

## Files Created/Modified

- `lib/crosswake/release_status.ex` - Uses `script/check_release_workflow_integrity.exs` output as release-status evidence and emits stable check/component fields.
- `lib/mix/tasks/crosswake.release.status.ex` - Routes task exit behavior through the release-status exit helper.
- `test/mix/tasks/crosswake_release_status_test.exs` - Covers scanner-backed local truth, JSON field shape, live probe injection, and stale-copy rejection.

## Decisions Made

- Kept the existing local scanner as the policy source for release-integrity evidence instead of adding a YAML parser or second workflow parser.
- Preserved the local-only default; scanner execution reads repository files only and performs no registry or mutation work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Included JSON/exit helper foundations in the Wave 1 commit**
- **Found during:** Task 2 (status text and tests)
- **Issue:** Updating local tests cleanly required stable check fields and task exit mapping that Plan 02 also relies on.
- **Fix:** Added the stable check map fields and `Crosswake.ReleaseStatus.exit_code/1` while keeping behavior read-only.
- **Files modified:** `lib/crosswake/release_status.ex`, `lib/mix/tasks/crosswake.release.status.ex`, `test/mix/tasks/crosswake_release_status_test.exs`
- **Verification:** `mix test test/mix/tasks/crosswake_release_status_test.exs`; `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs test/mix/tasks/crosswake_release_status_test.exs`
- **Committed in:** `698d0d44`

---

**Total deviations:** 1 auto-fixed (blocking sequencing).
**Impact on plan:** No scope creep; the extra helper work is required foundation for Plan 02 and keeps the same public command.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `146-02`: JSON schema and exit behavior can now be locked around stable component/check fields.

---
*Phase: 146-release-status-dx-docs-truth*
*Completed: 2026-07-09*
