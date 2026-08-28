---
phase: 158-adoption-reset-and-route-map
plan: "11"
subsystem: adoption route inventory
tags: [elixir, validation, privacy, route-policy, tdd]
dependency_graph:
  requires:
    - phase: 158-10
      provides: phase gap-closure baseline
  provides:
    - mechanically opaque route IDs
    - closed generic Phoenix path-template validation
    - non-echoing route-reference regressions
  affects: [route-policy-map, promotion-status, phase-158-verification]
tech_stack:
  added: []
  patterns: [closed-grammar-validation, safe-error-references, table-driven-boundary-tests]
key_files:
  created: []
  modified:
    - lib/crosswake/adoption/route_inventory.ex
    - test/crosswake/adoption/route_inventory_test.exs
key-decisions:
  - "Durable route IDs use exactly route- plus 16 lowercase hexadecimal characters."
  - "Phoenix path templates allow only generic static segments and the :id parameter token."
patterns-established:
  - "Validate opaque route references before posture construction and retain unresolved on invalid IDs."
requirements-completed: [RESET-02, RESET-04]
coverage:
  - id: D1
    description: Opaque route IDs and closed generic path templates reach validated route rows.
    requirement: RESET-02
    verification:
      - kind: unit
        ref: mix test test/crosswake/adoption/route_inventory_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Invalid route IDs and path patterns fail with stable non-echoing errors.
    requirement: RESET-04
    verification:
      - kind: unit
        ref: test/crosswake/adoption/route_inventory_test.exs#rejects-identifying-and-malformed-route-IDs-without-echoing-supplied-content
        status: pass
      - kind: unit
        ref: test/crosswake/adoption/route_inventory_test.exs#rejects-non-sanitized-route-templates-without-echoing-supplied-content
        status: pass
    human_judgment: false
metrics:
  duration: 12m
  completed_date: 2026-07-31
  tasks_completed: 1
  files_changed: 2
status: complete
---

# Phase 158 Plan 11: Opaque Route Reference Boundary Summary

Only fixed-format synthetic route IDs and closed generic Phoenix path templates can now become
validated inventory rows, while rejected route content remains absent from diagnostics.

## Accomplishments

- Replaced the broad route-ID slug check with the `route-` plus 16 lowercase hexadecimal grammar.
- Replaced broad path matching with a closed static-segment allowlist and the sole dynamic `:id`
  token.
- Preserved route-local posture, collision, ordering, and promotion behavior with synthetic
  fixtures and new negative non-echo regressions.

## Verification

- Passed: `mix test test/crosswake/adoption/route_inventory_test.exs` — 15 tests, 0 failures.
- Passed: `mix format --check-formatted lib/crosswake/adoption/route_inventory.ex test/crosswake/adoption/route_inventory_test.exs`.

## Task Commits

1. **Task 1 RED: route-reference boundary regressions** — `033436cb` (`test`)
2. **Task 1 GREEN: opaque reference validation** — `a1acce0a` (`feat`)

## Files Modified

- `lib/crosswake/adoption/route_inventory.ex` — applies the opaque-ID and sanitized-template grammar before struct construction.
- `test/crosswake/adoption/route_inventory_test.exs` — covers permitted templates, malformed and descriptive inputs, collision continuity, and non-echoing errors.

## Decisions Made

- Invalid route IDs retain the safe `unresolved` reference; invalid paths retain an already-validated opaque ID.
- No concrete adopter route, host route, arbitrary slug, or new durable schema field was introduced; TODO-002 remains open.

## TDD Gate Compliance

- RED: `033436cb` — new public API regressions failed against the broad validators.
- GREEN: `a1acce0a` — the route and path grammars made the focused suite pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented an empty rejected path from trivially matching every diagnostic string**
- **Found during:** Task 1 GREEN verification
- **Fix:** Kept the empty-path rejection assertion and skipped only the impossible empty-substring non-echo assertion.
- **Files modified:** `test/crosswake/adoption/route_inventory_test.exs`
- **Verification:** Focused suite passed with the empty-path rejection still covered.
- **Committed in:** `a1acce0a`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Test correctness only; no production scope change.

## Known Stubs

None. The only TODO-002 reference is the intentional, pre-existing adopter-input blocker.

## Self-Check: PASSED

- Required production and regression-test files exist.
- TDD RED and GREEN commits exist in git history.
