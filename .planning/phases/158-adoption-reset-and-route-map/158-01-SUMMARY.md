---
phase: 158-adoption-reset-and-route-map
plan: 01
subsystem: adoption-route-contract
tags: [elixir, nimble-options, privacy, route-policy, first-b2c-adopter]
dependency_graph:
  requires: [158-CONTEXT.md, FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md]
  provides: [closed-sanitized-route-inventory, blocked-promotion-status]
  affects: [phase-159-host-proof, phase-162-physical-iphone-proof]
tech_stack:
  added: []
  patterns: [closed-nimble-options-schema, explicit-route-local-posture, safe-validation-errors]
key_files:
  created:
    - lib/crosswake/adoption/route_inventory.ex
    - test/crosswake/adoption/route_inventory_test.exs
  modified:
    - .planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md
decisions:
  - Route-local safety posture is represented as a closed status/value pair and never inherits from surface defaults.
  - Empty or unknown-blocking inventories are explicitly blocked from promotion.
metrics:
  duration: 6m
  completed_date: 2026-07-31
  tasks_completed: 2
  files_changed: 3
status: complete
---

# Phase 158 Plan 01: Sanitized Route Inventory Tracer Summary

Closed, privacy-safe Phoenix route rows now validate deterministically and refuse promotion while
adopter-supplied safety posture remains unknown.

## What Changed

- Added `Crosswake.Adoption.RouteInventory`, a NimbleOptions-backed closed contract for opaque
  route IDs, sanitized path patterns, explicit route-local safety posture, collision detection,
  stable declaration order, and fail-closed promotion status.
- Added ExUnit proof for accepted synthetic rows, unknown-blocking promotion denial, empty
  inventory denial, collisions, unknown and forbidden fields, and non-echoing safe errors.
- Updated the route-policy map with layered default versus concrete-row semantics, D-07 statuses,
  D-08 allowlist, D-09 exclusions, validator entry points, D-03 promotion boundary, and the
  still-open TODO-002 blocker.

## Verification

- Passed: `mix test test/crosswake/adoption/route_inventory_test.exs` (7 tests, 0 failures).
- Attempted: `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs`.
  The inventory tests passed; the planning-context test is currently blocked by the pre-existing
  executor-start `STATE.md` transition from `$gsd-discuss-phase 158` to `$gsd-execute-phase 158`.

## TDD Gate Compliance

- RED: `025e0e5f` — failing route-inventory contract test.
- GREEN: `8b93a7ec` — validator implementation and passing contract tests.
- RED: `4fe86d2c` — failing route-map contract test.
- GREEN: `ee5167ff` — layered map update and passing focused suite.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected validator compilation guard usage during GREEN implementation**
- **Found during:** Task 1
- **Issue:** Initial local validation clauses used non-guard-safe expressions.
- **Fix:** Moved regular-expression and list checks into function bodies while preserving the
  closed validation behavior.
- **Files modified:** `lib/crosswake/adoption/route_inventory.ex`
- **Commit:** `8b93a7ec`

### Deferred Issues

- The broader Task 2 planning-context verification is blocked by an executor-start `STATE.md`
  change outside this plan's owned files. The issue is recorded in `deferred-items.md` for the
  phase's planning-state work.

## Known Stubs

None.

## Self-Check: PASSED

- Required implementation, test, route-policy map, and summary files exist.
- Task commits `025e0e5f`, `8b93a7ec`, `4fe86d2c`, and `ee5167ff` exist in git history.
