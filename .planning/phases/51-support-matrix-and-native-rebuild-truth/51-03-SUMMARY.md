---
phase: 51-support-matrix-and-native-rebuild-truth
plan: "03"
subsystem: diagnostics
tags: [operator-inspection, publish-readiness, promotion-rules, rebuild-actions]
requires:
  - phase: 51-support-matrix-and-native-rebuild-truth
    provides: canonical action classes, promotion rules, and generated support docs
provides:
  - operator inspection rebuild action metadata
  - operator inspection promotion rule ids
  - publish-readiness promotion metadata and demotion triggers
affects: [operator_inspection, publish_readiness, support_matrix]
tech-stack:
  added: []
  patterns: [canonical support truth reuse, fail-closed runtime metadata]
key-files:
  created: []
  modified:
    - lib/crosswake/operator_inspection.ex
    - lib/crosswake/operator_inspection/formatter.ex
    - lib/crosswake/doctor/publish_readiness.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - guides/support_matrix.md
    - test/crosswake/operator_inspection/operator_inspection_test.exs
    - test/crosswake/operator_inspection/formatter_test.exs
    - test/crosswake/doctor/publish_readiness_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
key-decisions:
  - "Runtime surfaces expose canonical promotion rule ids instead of deriving unnamed readiness."
  - "Sigra contract-only route predicates have an explicit promotion rule for diagnostics and docs parity."
patterns-established:
  - "Route rebuild maps include change_class, action_classes, and compatibility_signal."
  - "Publish-readiness checks carry promotion_rule_ids, required_docs_anchors, demotion_trigger, and action_classes."
requirements-completed: [SUPP-01, SUPP-02]
duration: 15min
completed: 2026-06-01
---

# Phase 51-03: Runtime Support Truth Summary

**Operator inspection and publish-readiness now reuse canonical action and promotion metadata for rebuild-sensitive route surfaces.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-01T15:50:17Z
- **Completed:** 2026-06-01T15:54:49Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Added route-level `rebuild.change_class`, `rebuild.action_classes`, and `rebuild.compatibility_signal`.
- Added route-level `support.promotion_rule_ids` for commerce provider adapters, notification-token provider snapshots, and Sigra contract-only auth predicates.
- Enriched publish-readiness checks with promotion ids, docs anchors, demotion triggers, and rebuild action classes.

## Task Commits

1. **Task 1: Add failing runtime support truth tests** - `20c715d` (test)
2. **Task 2: Reuse canonical support truth in runtime consumers** - `fc3d3cc` (feat)

## Files Created/Modified

- `lib/crosswake/operator_inspection.ex` - Adds canonical rebuild/action and promotion-rule metadata to route inspection.
- `lib/crosswake/operator_inspection/formatter.ex` - Prints `change_class=` and `actions=` while keeping support/proof split.
- `lib/crosswake/doctor/publish_readiness.ex` - Adds promotion metadata and action classes to publish-readiness checks.
- `lib/crosswake/support_matrix/support_matrix.ex` - Adds Sigra contract-only promotion rule.
- `guides/support_matrix.md` - Regenerated after adding the Sigra promotion rule.
- `test/crosswake/operator_inspection/operator_inspection_test.exs` - Locks route metadata.
- `test/crosswake/operator_inspection/formatter_test.exs` - Locks human output shape.
- `test/crosswake/doctor/publish_readiness_test.exs` - Locks readiness promotion metadata.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Locks the expanded promotion-rule registry.

## Decisions Made

- Added `auth.sigra.contract_only` as a canonical rule so auth/session diagnostics are auditable and not a prose-only exception.
- Used `route_manifest` as the no-rebuild default action class and concrete native/companion/provider classes where route posture requires them.

## Deviations from Plan

Added the Sigra promotion rule to the canonical support matrix so the planned auth readiness metadata could be sourced from the same registry as shell, notification, and provider rules.

## Issues Encountered

The support-matrix registry test expected the earlier seven-rule list; it was updated to include the Sigra rule and the generated guide was regenerated.

## Verification

- `mix test test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/operator_inspection/formatter_test.exs test/crosswake/doctor/publish_readiness_test.exs` - 10 tests, 0 failures.
- `mix test test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/operator_inspection/formatter_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/guides/release_boundaries_test.exs` - 47 tests, 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 52 can add broader operator proof/docs-contract locks on top of the canonical support truth now exposed in docs, inspection, and publish-readiness.

---
*Phase: 51-support-matrix-and-native-rebuild-truth*
*Completed: 2026-06-01*
