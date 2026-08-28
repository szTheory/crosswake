---
phase: 158-adoption-reset-and-route-map
plan: "05"
subsystem: adoption route inventory
tags: [elixir, route-policy, validation, privacy, tdd]
dependency_graph:
  requires: [158-04, route-policy-map]
  provides: [fail-closed-safety-status-validation, local-mutation-promotion-invariants]
  affects: [host-proof-eligibility, physical-device-eligibility]
tech_stack:
  added: []
  patterns: [closed-posture-validation, validate-before-promotion, table-driven-regressions]
key_files:
  created: []
  modified:
    - lib/crosswake/adoption/route_inventory.ex
    - test/crosswake/adoption/route_inventory_test.exs
    - .planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md
decisions:
  - Concrete-route safety fields reject known_default while preserving the discovery vocabulary.
  - local_first promotion requires coherent route-local authority, scope, fallback, disablement, retention, and recent-auth posture.
metrics:
  duration: 9m
  completed_date: 2026-07-31
  tasks_completed: 2
  files_changed: 3
status: complete
---

# Phase 158 Plan 05: Route Promotion Invariants Summary

Concrete routes now reject inherited safety posture and cannot become eligible unless their
local-mutation and recent-auth authority contracts are explicitly coherent.

## What Changed

- Added an `RI-SAFETY_STATUS` validation boundary that rejects `known_default` for every concrete
  route safety field before value acceptance or promotion.
- Added route-invariant validation before struct construction: local-first routes require an
  offline-island owner, actionable mutation, scope isolation, route-local fallback, disablement,
  and retention posture; recent-auth authority must agree in both directions.
- Added public-API regressions for every inherited-safety field, defaults-only input, local-mutation
  contradictions, recent-auth contradictions, and an eligible coherent recent-auth row.
- Documented the executable invariant contract without introducing a concrete adopter route or any
  host-private facts; TODO-002 remains open.

## Verification

- Passed: `mix test test/crosswake/adoption/route_inventory_test.exs` (12 tests, 0 failures).
- Passed: `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs test/crosswake/capability_map test/crosswake/support_matrix` (105 tests, 0 failures).
- Passed: `mix format --check-formatted lib/crosswake/adoption/route_inventory.ex test/crosswake/adoption/route_inventory_test.exs`.

## TDD Gate Compliance

- RED: `917ff1b0` — known-default safety-status regressions fail against the prior validator.
- GREEN: `e14b7f9c` — safety-status rejection makes those regressions pass.
- RED: `8443c3bc` — local-mutation and recent-auth invariant regressions fail before implementation.
- GREEN: `31435785` — invariant validation and route-map contract make the focused suite pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Formatted the new invariant helper after verification exposed a formatter failure**
- **Found during:** Task 2 completion verification
- **Fix:** Applied the repository formatter and re-ran focused and quick Phase 158 suites.
- **Files modified:** `lib/crosswake/adoption/route_inventory.ex`
- **Commit:** `86ac2887`

**Total deviations:** 1 auto-fixed. **Impact:** formatting-only; no behavior change.

## Known Stubs

None. TODO-002 is an intentional, pre-existing adopter-input blocker and remains explicitly open;
this plan does not fabricate a concrete route row.

## Self-Check: PASSED

- Required implementation, test, and route-map files exist.
- All five TDD and formatting commits exist in git history.
