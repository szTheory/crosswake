---
phase: 147-arc-fixture-and-showcase-foundation
plan: 04
subsystem: example-host showcase
tags: [phoenix, liveview, exunit, route-policy, e2e-reset]

requires:
  - phase: 147-arc-fixture-and-showcase-foundation
    provides: showcase catalog and deterministic reset contracts from plans 147-02 and 147-03
provides:
  - Root `/` showcase hub LiveView with three route-policy-backed domain lanes
  - Test/e2e-gated showcase reset JSON endpoint delegating to the fixed reset contract
  - Token-backed showcase CSS and focused hub/router/controller tests
affects: [phase-147-first-run, phase-148-saas, phase-149-field-service, phase-150-learning, phase-151-route-tour]

tech-stack:
  added: []
  patterns:
    - Phoenix root route rendered by a catalog-backed LiveView with compiled route metadata tests
    - Test-only reset endpoint delegates to one fixed server-side reset contract and returns digest/counts

key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex
    - examples/phoenix_host/lib/crosswake_example/e2e/showcase_reset_controller.ex
    - examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs
    - examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/phoenix_host/priv/static/css/app.css
    - examples/phoenix_host/test/crosswake_example/router_test.exs

key-decisions:
  - "Root `/` now uses `CrosswakeExample.Showcase.HubLive` with Crosswake route id `showcase-hub`, runtime `:live_view`, offline `:cached_read_only`, and security `:standard`."
  - "The field-service card displays the route-policy capture template but links its CTA to reachable `/native/claims` to avoid a dead first-screen click."
  - "`/_e2e/showcase-reset` accepts no reset scopes and delegates only to `CrosswakeExample.Showcase.Reset.reset!/0`."

patterns-established:
  - "Hub render tests assert visible lane copy, route paths, CTA copy, runtime labels, support labels, and secondary proof links."
  - "Router tests assert the compiled LiveView route shape and source-level placement of the reset route inside the test/e2e guard."
  - "Endpoint tests assert counts, digest, and `browser_state_reset: false` from the shared reset contract."

requirements-completed: [SHOW-01, SHOW-02, SHOW-03]

duration: 9 min
completed: 2026-07-09
status: complete
---

# Phase 147 Plan 04: Root Showcase Hub and Gated Reset Summary

**Phoenix-owned root showcase hub with visible route-owner labels and a test-only reset endpoint backed by the deterministic reset contract.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-09T19:56:00Z
- **Completed:** 2026-07-09T20:04:52Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Replaced the minimal root controller page with `CrosswakeExample.Showcase.HubLive` at `/`, using route metadata id `showcase-hub`.
- Rendered SaaS/Admin, Field Service, and Learning/Training lane cards from `Showcase.Catalog`, including route paths, visible runtime/support labels, capability chips, boundary notes, and secondary proof links.
- Added token-backed `showcase-*` CSS for the hub surface, lane cards, badges, proof strip, mobile layout, focus rings, and reduced-motion behavior.
- Added `CrosswakeExample.E2E.ShowcaseResetController` and `POST /_e2e/showcase-reset` under the existing `Mix.env() in [:test, :e2e]` route guard.
- Added focused render/router/controller tests for the hub and reset endpoint.

## Task Commits

1. **Task 1: Write hub render and router tests** - `39074ea3` (test, RED)
2. **Task 2: Implement root HubLive and token-backed showcase styling** - `8a857a8b` (feat, GREEN)
3. **Task 3: Add gated showcase reset endpoint for E2E use** - `efe9275b` (test, RED)
4. **Task 3: Add gated showcase reset endpoint for E2E use** - `c17fa5be` (feat, GREEN)
5. **Refactor:** `132094ef` (refactor, mix format)

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example/showcase/hub_live.ex` - Root showcase hub LiveView that renders the catalog-backed three-lane product surface.
- `examples/phoenix_host/lib/crosswake_example/e2e/showcase_reset_controller.ex` - Test/e2e-only JSON controller delegating to `Showcase.Reset.reset!/0`.
- `examples/phoenix_host/lib/crosswake_example/router.ex` - Root route moved to `HubLive`; `_e2e/showcase-reset` added inside the existing compile-time guard.
- `examples/phoenix_host/priv/static/css/app.css` - Added scoped token-backed showcase hub styles.
- `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` - Render assertions for hub copy, lane labels, route paths, CTAs, and proof links.
- `examples/phoenix_host/test/crosswake_example/e2e/showcase_reset_controller_test.exs` - Controller assertions for reset counts, digest, non-browser-state claim, and ignored arbitrary params.
- `examples/phoenix_host/test/crosswake_example/router_test.exs` - Compiled route assertions for root hub, legacy proof routes, and gated reset endpoint.

## Decisions Made

- Removed the inline `PageController` because no route uses it after `/` moved to `HubLive`.
- Kept diagnostics and legacy proof routes secondary: `/offline`, `/bridge-proof`, and `/native/claims` remain linked one click deeper.
- Kept the reset endpoint narrow: it ignores request bodies and returns only the fixed reset contract output.

## Deviations from Plan

No scope deviations. Shared `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` were intentionally not updated because the Wave 2 orchestrator owns shared tracking after this plan.

## Issues Encountered

- The first Task 3 RED run exposed a source-path bug in the new router guard test. The test was corrected before committing the RED gate, so committed failing tests represented only the missing endpoint behavior.

## Verification

- `cd examples/phoenix_host && mix test test/crosswake_example/showcase/hub_live_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs test/crosswake_example/router_test.exs test/crosswake_example/showcase/reset_test.exs`
- Result: PASS, 13 tests, 0 failures.

## Known Stubs

None. Stub scan found no TODO/FIXME/placeholder/coming-soon/not-available markers or hardcoded empty UI data in files created or modified by this plan.

## Threat Flags

None beyond planned threat-model surfaces. The new reset route is the planned `/_e2e` endpoint, remains inside the existing `Mix.env() in [:test, :e2e]` guard, accepts no user-controlled reset targets, and delegates only to `Showcase.Reset.reset!/0`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 147-05 can point the first-run banner and docs at `/` as the product-shaped showcase entrypoint. Later domain phases can extend lane depth without changing the root route or reset contract.

## Self-Check: PASSED

- `147-04-SUMMARY.md` exists.
- Created hub/controller/test files exist.
- Commits `39074ea3`, `8a857a8b`, `efe9275b`, `c17fa5be`, and `132094ef` exist.
- Required verification command passed with 13 tests and 0 failures.

---
*Phase: 147-arc-fixture-and-showcase-foundation*
*Completed: 2026-07-09*
