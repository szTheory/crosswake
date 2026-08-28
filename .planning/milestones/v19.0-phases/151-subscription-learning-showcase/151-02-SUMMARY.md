---
phase: 151-subscription-learning-showcase
plan: 02
subsystem: showcase
tags: [learnloop, fixtures, reset, exunit, offline-island, entitlement]

requires:
  - phase: 151-subscription-learning-showcase
    provides: 151-01 RED contracts for LearnLoop fixture breadth and reset truth
provides:
  - Deterministic LearnLoop learner, course, lesson, pack, progress, subscription, route posture, support, sync ledger, and capability-pressure data
  - LearnLoop context read models for dashboard, course, pack, history, subscription, reset counts, and digest components
  - Showcase reset integration that delegates learning_training counts and digest truth to LearnLoop while preserving browser_state_reset false
affects: [151-subscription-learning-showcase, learnloop, showcase-reset, phase-152-capability-map]

tech-stack:
  added: []
  patterns:
    - Deterministic fixture breadth plus narrow persisted evidence through existing Flashcards and LocalFirst review-event tables
    - Lane-local context facade for product read models instead of LiveView-owned business logic
    - Reset digest components include LearnLoop static IDs/titles/statuses while browser IndexedDB remains browser-owned

key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/learn_loop.ex
    - examples/phoenix_host/lib/crosswake_example/learn_loop/fixtures.ex
  modified:
    - examples/phoenix_host/lib/crosswake_example/showcase/reset.ex
    - examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs

key-decisions:
  - "LearnLoop course, lesson, learner, pack, route posture, support, and entitlement breadth stays deterministic fixture/read-context data; no broad LMS persistence was added."
  - "LearnLoop reset delegates to Flashcards for server-owned review/progress table reset, then reports LearnLoop product counts with browser_state_reset: false."
  - "Showcase reset digest now includes LearnLoop digest components so fixture ID/title/status/support changes affect reset truth."

patterns-established:
  - "LearnLoop fixture digest pattern: learning_training.* components sorted from stable IDs, titles, states, route posture, support findings, and capability pressure."
  - "LearnLoop read-model pattern: dashboard/course/pack/history/subscription maps include product context plus explicit route/support posture for later LiveViews."
  - "Reset controller contract pattern: learning_training JSON reports LearnLoop product counts, not legacy Flashcards deck/card counts."

requirements-completed: [LEARN-01, LEARN-02, LEARN-03, LEARN-04]

duration: 8 min
completed: 2026-07-11
status: complete
---

# Phase 151 Plan 02: LearnLoop Fixture and Reset Foundation Summary

**Deterministic LearnLoop fixture/read-context breadth with server-owned reset counts, digest truth, and browser-state honesty.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-11T20:38:27Z
- **Completed:** 2026-07-11T20:45:57Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added dense LearnLoop fixtures for learners, courses, lessons, content packs, progress checkpoints, sync ledger preview, subscription states, route posture, support findings, and capability pressure.
- Added `CrosswakeExample.LearnLoop` read models for dashboard, course, pack, history, subscription, reset, and digest use by later routes.
- Updated `Showcase.Reset` so `learning_training` reset counts and digest components are LearnLoop-owned while `browser_state_reset` remains false.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create deterministic LearnLoop fixtures** - `4c687ab0` (feat)
2. **Task 2: Add LearnLoop context read models and reset helper** - `2f2088ba` (feat)
3. **Task 3: Wire LearnLoop reset counts and digest into Showcase.Reset** - `6735481d` (feat)

**Plan metadata:** this summary is committed in the final `docs(151-02)` close-out commit.

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/learn_loop/fixtures.ex` - Deterministic LearnLoop domain data and digest components.
- `examples/phoenix_host/lib/crosswake_example/learn_loop.ex` - Lane-local context read models and reset/digest facade.
- `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` - Reset now delegates LearnLoop counts and digest components through the context.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` - Reset JSON contract now expects LearnLoop product counts.

## Decisions Made

- Static LearnLoop breadth remains deterministic maps; persisted workflow evidence remains the existing Flashcards and LocalFirst review-event tables.
- Subscription pressure stays backend-projection/mocked-storefront evidence in fixture/read-context data, with no live StoreKit, Play Billing, RevenueCat, or entitlement table.
- Reset reports product-shaped LearnLoop counts rather than deck/card seed details, while Flashcards reset still performs the server-owned table cleanup.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stabilized route path exposure in LearnLoop course read models**
- **Found during:** Task 3 verification
- **Issue:** The existing contract used `inspect/1` to find `/learnloop/study/session`; large context maps could truncate fields even when action paths existed.
- **Fix:** Added concrete route paths to lesson summaries so course/pack read models expose UI-consumable paths directly.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/learn_loop.ex`
- **Verification:** Full Task 3 ExUnit suite passed.
- **Committed in:** `6735481d`

**2. [Rule 1 - Bug] Aligned support finding count with reset contract**
- **Found during:** Task 3 verification
- **Issue:** Fixture support findings split mocked storefront evidence into a sixth row, while the Wave 0 reset contract expected five support findings.
- **Fix:** Consolidated mocked storefront evidence into the backend-projection finding while retaining `Mocked storefront evidence` in route posture and capability-pressure data.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/learn_loop/fixtures.ex`
- **Verification:** Reset and LearnLoop fixture suites passed with `support_findings: 5`.
- **Committed in:** `6735481d`

**3. [Rule 3 - Blocking] Updated stale reset controller JSON expectation**
- **Found during:** Task 3 verification
- **Issue:** The controller reset test still expected legacy Flashcards deck/card counts even though the plan required LearnLoop-owned product counts.
- **Fix:** Updated the JSON assertion to match the LearnLoop reset count contract.
- **Files modified:** `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs`
- **Verification:** Full Task 3 ExUnit suite passed.
- **Committed in:** `6735481d`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking issue)
**Impact on plan:** All fixes tightened the planned LearnLoop reset/read-model contract without adding scope or persistence.

## Issues Encountered

- Task 1’s planned `--only learnloop_fixture_density` command selected both the fixture contract and the Task 2 context contract. I verified Task 1 with the fixture-density line scope, then the full LearnLoop fixture/context suite passed after Task 2.

## Verification

- `cd examples/phoenix_host && mix test test/crosswake_example/learn_loop/fixtures_test.exs:16` - passed for Task 1 fixture density.
- `cd examples/phoenix_host && mix test test/crosswake_example/learn_loop/fixtures_test.exs` - passed for Task 2.
- `cd examples/phoenix_host && mix test test/crosswake_example/showcase/reset_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs test/crosswake_example/learn_loop/fixtures_test.exs` - passed, 9 tests.
- `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/learn_loop/fixtures_test.exs` - passed, 3 tests.

## TDD Gate Compliance

RED contracts were supplied by `151-01` as planned for Wave 0. This plan executed the GREEN implementation commits against those existing failing contracts; no new RED test commits were needed in `151-02`.

## Known Stubs

None. Stub scan found no TODO/FIXME/placeholder text or hardcoded empty UI data in the files created or modified by this plan.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/151-subscription-learning-showcase/151-02-SUMMARY.md`.
- Key files exist on disk: `learn_loop.ex`, `learn_loop/fixtures.ex`, `showcase/reset.ex`, and the reset controller test.
- Task commits found in git history: `4c687ab0`, `2f2088ba`, `6735481d`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `151-03`: LearnLoop now has deterministic fixture/read-context data and reset digest truth for product-first route declarations and diagnostics.

---
*Phase: 151-subscription-learning-showcase*
*Completed: 2026-07-11*
