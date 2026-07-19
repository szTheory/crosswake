---
phase: 151-subscription-learning-showcase
plan: 01
subsystem: testing
tags: [learnloop, exunit, liveview, playwright, offline-island, entitlement]

requires:
  - phase: 150-field-service-showcase
    provides: Fieldserv RED-contract patterns for fixtures, diagnostics, LiveView routes, and semantic-first route-tour proof
provides:
  - Wave 0 RED ExUnit contracts for LearnLoop fixture breadth, route diagnostics, entitlement truth, and showcase reset/catalog/hub integration
  - Wave 0 RED LiveView contracts for LearnLoop dashboard, course, pack, history, and subscription routes
  - Tagged Playwright LearnLoop route-tour contract covering product shell, socketless offline study, sync replay, history, and support truth
affects: [151-subscription-learning-showcase, 152-capability-map, learnloop, showcase-proof]

tech-stack:
  added: []
  patterns:
    - RED-only contract tests with Code.ensure_loaded?/1 and function_exported?/3 for planned modules
    - Semantic-first Playwright proof before screenshot collateral
    - Backend-owned entitlement copy and browser-owned offline state truth encoded in tests

key-files:
  created:
    - examples/phoenix_host/test/crosswake_example/learn_loop/fixtures_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/diagnostics_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/entitlement_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/dashboard_live_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/course_live_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/pack_live_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/history_live_test.exs
    - examples/phoenix_host/test/crosswake_example/learn_loop/subscription_live_test.exs
    - examples/phoenix_host/e2e/learnloop_route_tour.spec.ts
  modified:
    - examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs
    - examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs
    - examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs
    - examples/phoenix_host/e2e/route_tour.spec.ts

key-decisions:
  - "LearnLoop Wave 0 remains RED-only: production LearnLoop modules, routes, contexts, templates, and CSS are intentionally left to later plans."
  - "Reset tests now start the Phoenix app when run under focused --no-start RED verification so Repo-backed reset assertions fail on LearnLoop contract expectations instead of setup errors."
  - "Playwright contracts require /learnloop/sync as a product-named alias while still allowing existing /study/sync response observation, preserving the single review-event sync seam."

patterns-established:
  - "LearnLoop ExUnit contract pattern: indirect module checks plus exact contract messages for missing planned behavior."
  - "LearnLoop route-tour pattern: product path, entitlement pressure, socketless study, IndexedDB outbox, duplicate replay, history, diagnostics, then screenshots."
  - "Showcase entry pattern: LearnLoop primary CTA must be /learnloop while /offline remains a secondary proof route."

requirements-completed: [LEARN-01, LEARN-02, LEARN-03, LEARN-04]

duration: 9 min
completed: 2026-07-11
status: complete
---

# Phase 151 Plan 01: Wave 0 LearnLoop Contracts Summary

**RED contract suite for LearnLoop’s product-first route shell, socketless offline study proof, backend-owned entitlement copy, and showcase reset/catalog truth.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-11T20:24:03Z
- **Completed:** 2026-07-11T20:33:56Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added LearnLoop ExUnit contracts for fixture density, route diagnostics, entitlement projection, and showcase entry/reset truth.
- Added LiveView route contracts for dashboard, course, pack, history, and subscription surfaces without creating production modules.
- Added a tagged Playwright route-tour contract and extended the existing route tour with LearnLoop semantic assertions before screenshots.

## Task Commits

Each task was committed atomically:

1. **Task 1: RED ExUnit contracts for fixtures, diagnostics, reset, and entitlement truth** - `5f61f870` (test)
2. **Task 2: RED LiveView contracts for product-first LearnLoop shell routes** - `79063d03` (test)
3. **Task 3: RED Playwright contracts for socketless LearnLoop route tour and offline proof** - `c30e0f36` (test)

**Plan metadata:** summary committed in the final `docs(151-01)` close-out commit.

## Files Created/Modified

- `examples/phoenix_host/test/crosswake_example/learn_loop/fixtures_test.exs` - RED contracts for deterministic learners, courses, lessons, packs, progress, route posture, reset counts, and digest components.
- `examples/phoenix_host/test/crosswake_example/learn_loop/diagnostics_test.exs` - RED contracts for route metadata rows, labels, guide links, and capability pressure evidence.
- `examples/phoenix_host/test/crosswake_example/learn_loop/entitlement_test.exs` - RED contracts for backend-owned entitlement states, fail-closed copy, mocked storefront evidence, and no live-provider claims.
- `examples/phoenix_host/test/crosswake_example/learn_loop/*_live_test.exs` - RED contracts for dashboard, course, pack, history, and subscription LiveView route shells.
- `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` - Repointed learning lane expectations to product-first `/learnloop`.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - Added LearnLoop reset count expectations and app startup for focused `--no-start` RED verification.
- `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` - Repointed root showcase CTA expectations to `/learnloop`.
- `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` - New tagged Playwright LearnLoop proof contract.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - Existing route tour now calls `proveLearnLoopRoute`.

## Decisions Made

- Kept this plan RED-only as planned; no production LearnLoop modules, routes, contexts, templates, CSS, sync endpoints, or entitlement implementations were added.
- Kept `/offline` as secondary proof and made `/learnloop` the primary expected showcase entry in tests.
- Required `/learnloop/study/session` to prove `window.liveSocket === false`, IndexedDB queueing, app-generated UUIDs, duplicate replay idempotency, and server-confirmed history before screenshots.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Started the app for Repo-backed reset tests under focused RED verification**
- **Found during:** Task 1 (ExUnit contracts)
- **Issue:** The plan’s focused command includes `showcase/reset_test.exs` with `--no-start`; existing reset assertions touch `CrosswakeExample.Repo`, producing a setup `RuntimeError` instead of the intended LearnLoop RED contract failure.
- **Fix:** Added `setup_all` with `Application.ensure_all_started(:crosswake_example)` in the reset test.
- **Files modified:** `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs`
- **Verification:** Task 1 RED command now exits successfully by confirming intended contract failures and no forbidden runtime/setup errors.
- **Committed in:** `5f61f870`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix preserves the planned RED verification behavior and does not add production scope.

## Issues Encountered

- Focused `--no-start` reset verification needed explicit app startup for Repo-backed reset assertions; resolved in Task 1.

## Verification

- `cd examples/phoenix_host && sh -c 'mix test --warnings-as-errors --no-start ... > /tmp/phase151-wave0-exunit-red-final.log ...'` passed as a RED verifier: expected LearnLoop fixture, diagnostics, entitlement, and showcase entry contract failures were present, with no syntax/compile/runtime setup failures.
- `cd examples/phoenix_host && sh -c 'mix test --warnings-as-errors --no-start ... > /tmp/phase151-wave0-live-red-final.log ...'` passed as a RED verifier: expected dashboard, course, pack, history, and subscription LiveView contract failures were present, with no syntax/compile/runtime setup failures.
- `cd examples/phoenix_host && npx playwright test --list e2e/learnloop_route_tour.spec.ts` listed 1 tagged `@learnloop` test successfully.

## TDD Gate Compliance

This plan is intentionally Wave 0 RED-only. It produced three `test(151-01)` commits and no `feat(151-01)` GREEN commit because the plan explicitly forbids production LearnLoop implementation in this wave.

## Known Stubs

None. Stub scan only found assertion guards such as `!= ""` in tests; no placeholder UI data or unimplemented production stubs were introduced.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/151-subscription-learning-showcase/151-01-SUMMARY.md`.
- Created LearnLoop ExUnit, LiveView, and Playwright contract files exist on disk.
- Task commits found in git history: `5f61f870`, `79063d03`, `c30e0f36`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `151-02`: later plans can now implement deterministic LearnLoop fixture/read-context breadth against failing contracts for LEARN-01 through LEARN-04.

---
*Phase: 151-subscription-learning-showcase*
*Completed: 2026-07-11*
