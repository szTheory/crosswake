---
phase: 146-release-status-dx-docs-truth
plan: 02
subsystem: release-ops
tags: [mix-task, json, cli, automation-contract]

requires:
  - phase: 146-release-status-dx-docs-truth
    provides: scanner-backed local status checks from plan 01
provides:
  - stable release-status JSON contract fields
  - aggregate status and exit behavior coverage
  - non-OK next_action enforcement for automation consumers
affects: [phase-146, release-status, ci-json]

tech-stack:
  added: []
  patterns:
    - additive JSON schema with stable check codes
    - non-fatal warning exit behavior

key-files:
  created:
    - .planning/phases/146-release-status-dx-docs-truth/146-02-SUMMARY.md
  modified:
    - test/mix/tasks/crosswake_release_status_test.exs
    - lib/crosswake/release_status.ex
    - lib/mix/tasks/crosswake.release.status.ex

key-decisions:
  - "JSON consumers branch on stable fields and check codes; prose stays human-facing."
  - "`ok` and `warning` release status states remain exit-zero; only `error` and invalid invocation are fatal."

patterns-established:
  - "Top-level JSON fields remain `schema_version`, `generated_at`, `status`, `live_checked`, `core`, `companions`, and `checks`."
  - "Every non-OK check must include an actionable `next_action`."

requirements-completed: [STAT-02]

duration: 3 min
completed: 2026-07-09
status: complete
---

# Phase 146 Plan 02: JSON Contract and Exit Behavior Summary

**Release status JSON is now covered as a machine contract with stable fields, status precedence, and predictable CLI exit behavior.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-09T13:28:30Z
- **Completed:** 2026-07-09T13:31:13Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Locked JSON top-level fields and component/check object fields through focused tests.
- Added explicit aggregate precedence coverage: `error > warning > ok`.
- Verified `mix crosswake.release.status --json` produces parseable JSON for `jq`, and invalid CLI flags exit non-zero.

## Task Commits

Each task was committed atomically:

1. **Task 1: Normalize JSON component and check objects** - `698d0d44` (feat)
2. **Task 2: Lock JSON-only output and CLI exit behavior** - `705cd4f6` (test)

**Plan metadata:** recorded in the current docs commit.

## Files Created/Modified

- `lib/crosswake/release_status.ex` - Provides stable check/component fields and aggregate/exit helpers.
- `lib/mix/tasks/crosswake.release.status.ex` - Uses the release-status exit helper for fatal status mapping.
- `test/mix/tasks/crosswake_release_status_test.exs` - Covers JSON schema fields, status precedence, exit mapping, invalid options, and non-OK next actions.

## Decisions Made

- Kept `schema_version` at `1.0.0`; field additions are additive within this version.
- Did not add issue-opening automation; stable JSON output and check codes satisfy the automation contract for this phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan 02 code foundation landed in the Plan 01 implementation commit**
- **Found during:** Task 1 (JSON object normalization)
- **Issue:** Stable check fields were required to remove stale local-status tests in Plan 01.
- **Fix:** Recorded `698d0d44` as the implementation commit for shared JSON fields, then added a Plan 02-specific regression commit for status precedence and next actions.
- **Files modified:** `lib/crosswake/release_status.ex`, `lib/mix/tasks/crosswake.release.status.ex`, `test/mix/tasks/crosswake_release_status_test.exs`
- **Verification:** `mix test test/mix/tasks/crosswake_release_status_test.exs`; `mix crosswake.release.status --json` piped through `jq`; invalid-option shell check.
- **Committed in:** `698d0d44`, `705cd4f6`

---

**Total deviations:** 1 auto-fixed (sequencing).
**Impact on plan:** No behavior was skipped; the JSON contract is implemented and independently regression-tested.

## Issues Encountered

- A first shell JSON verification run included Mix compile chatter before the JSON document because source had just changed. After compilation, the real task output was parseable JSON and the command passed. The task path itself emits JSON only.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `146-03`: live probe taxonomy is implemented and needs docs reconciliation plus final stale-doc guards.

---
*Phase: 146-release-status-dx-docs-truth*
*Completed: 2026-07-09*
