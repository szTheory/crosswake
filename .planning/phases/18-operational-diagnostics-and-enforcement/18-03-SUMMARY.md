---
phase: "18-operational-diagnostics-and-enforcement"
plan: "03"
title: "Separated baseline support, proof status, and capability posture"
executed_at: "2026-05-21T20:40:00Z"
commits: []
files_changed:
  - "lib/crosswake/manifest/types.ex"
  - "lib/crosswake/manifest/validator.ex"
  - "lib/crosswake/support_matrix/support_matrix.ex"
  - "lib/crosswake/support_matrix/renderer.ex"
  - "guides/support_matrix.md"
  - "test/crosswake/support_matrix/support_matrix_test.exs"
  - "test/crosswake/support_matrix/renderer_test.exs"
---

# Phase 18 Plan 03 Summary

The support matrix now separates baseline support from proof verification state and renders capability-family posture explicitly in the generated guide.

## Completed Work

- Extended manifest support types with explicit `baseline_status` and `proof_status` fields.
- Added capability posture rendering for activation-first, bounded-bridge, transfer-backed, alias-snapshot, provider-snapshot, native-screen, and backend-seam families.
- Marked Android baseline support as present while keeping repository proof truth at `verification_required`.
- Re-rendered `guides/support_matrix.md` from the updated canonical renderer.

## Verification

- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs`
  - Result: passed

## Constraints Observed

- The generated guide was rewritten from canonical code after the support shape changed.

## Self-Check

PASSED
