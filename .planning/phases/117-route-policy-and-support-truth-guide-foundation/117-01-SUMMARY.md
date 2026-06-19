---
phase: 117-route-policy-and-support-truth-guide-foundation
plan: "01"
subsystem: docs
tags: [route-policy, guides, docs-contract, support-truth]
requires:
  - phase: 116-proof-debt-and-release-truth
    provides: current v13 public proof and release-truth baseline
provides:
  - Route-policy start-here guide centered on runtime ownership
  - GUIDE-01 docs-contract test for route-owner framing and DSL fields
  - User-flow ramp link into the dedicated route-policy guide
affects: [phase-118-quick-start, phase-119-native-evidence, phase-120-collateral]
tech-stack:
  added: []
  patterns:
    - Docs-contract tests pin guide behavior without overfitting editorial copy.
    - Route-policy examples name current DSL fields instead of a simplified shadow vocabulary.
key-files:
  created:
    - guides/route_policy.md
    - test/crosswake/guides/route_policy_test.exs
  modified:
    - guides/user_flows.md
key-decisions:
  - "Used `guides/route_policy.md` as the GUIDE-01 anchor and kept `guides/user_flows.md` as the JTBD ramp."
  - "Kept capabilities subordinate to route ownership and left quick-start, adoption, native evidence classification, and collateral scope to later phases."
patterns-established:
  - "Every route-owner docs example states manifest truth, doctor/support posture, denial/fallback behavior, and visible rough edge."
  - "Guide tests assert route-owner classes, schema field names, canonical guide links, and anti-overclaim posture."
requirements-completed: [GUIDE-01]
duration: 18 min
completed: 2026-06-19
status: complete
---

# Phase 117 Plan 01: Route-Policy Guide Summary

**Route-owner-first guide and docs-contract test make Crosswake's route-policy mental model explicit**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-19T14:06:00Z
- **Completed:** 2026-06-19T14:24:05Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `guides/route_policy.md` with the one-job route-owner framing before syntax.
- Covered plain LiveView, bounded bridge, cached read-only, offline island, native screen, backend/provider seam, and explicit defer decisions.
- Included current route-policy fields and downstream manifest, doctor/support, denial/fallback, and rough-edge truth for every owner class.
- Linked `guides/user_flows.md` into the new guide while preserving the "Who should own this route?" JTBD ramp.
- Added `Crosswake.Guides.RoutePolicyTest` to pin GUIDE-01 behavior.

## Task Commits

1. **Task 1: Create the route-policy docs-contract test** - `dc92ef6` (`test`)
2. **Task 2: Add the route-policy start-here guide and preserve user-flow ramp** - `e870cdd` (`docs`)

## Files Created/Modified

- `guides/route_policy.md` - New start-here guide for route ownership, current DSL fields, downstream truth, and explicit scope boundaries.
- `guides/user_flows.md` - Adds a narrow link from the existing JTBD ramp to the route-policy guide.
- `test/crosswake/guides/route_policy_test.exs` - Docs-contract coverage for route-owner classes, schema field names, canonical links, and non-overclaim posture.

## Verification

- `bash -lc 'test -f test/crosswake/guides/route_policy_test.exs && if mix test test/crosswake/guides/route_policy_test.exs > /tmp/crosswake-route-policy-red.log 2>&1; then echo "expected route-policy docs-contract test to fail before guides/route_policy.md exists" >&2; exit 1; fi; grep -q "guides/route_policy.md" /tmp/crosswake-route-policy-red.log'` - passed before guide implementation.
- `mix test test/crosswake/guides/route_policy_test.exs test/crosswake/guides/user_flows_test.exs test/crosswake/guides/adopter_profiles_test.exs` - passed, 11 tests, 0 failures.

## Decisions Made

- Used examples based on current schema and example-router patterns rather than inventing a simplified guide-only DSL.
- Defined proof and native evidence vocabulary only generically; Phase 119 still owns checked-in native host classification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 117-02 can link to `guides/route_policy.md` while building the Phoenix SaaS web-to-mobile migration guide.

---
*Phase: 117-route-policy-and-support-truth-guide-foundation*
*Completed: 2026-06-19*
