---
phase: 05-packs-native-escape-and-proof-lanes
plan: 09
subsystem: support-publication
tags: [doctor, support-matrix, docs, proof]
requires:
  - phase: 05-08
    provides: passing phase 5 proof lanes
provides:
  - proof-backed canonical support matrix
  - rendered support matrix guide synced to canonical truth
  - doctor/support-matrix tests aligned to Phase 5 proof posture
completed: 2026-05-17
---

# Phase 5 Plan 9: Support Publication Summary

The published support model now matches the passing Phase 5 proof posture. `Crosswake.SupportMatrix.canonical/1` marks the iOS, Android, and generated shell artifacts as supported, and `guides/support_matrix.md` is rendered directly from that canonical model.

## Accomplishments

- Flipped the canonical support entries from pre-proof placeholders to proof-backed support.
- Updated support-matrix notes so they reference checked-in example hosts and generated-host verification hooks.
- Regenerated `guides/support_matrix.md` from the canonical renderer and removed manual drift.
- Updated support-matrix tests to account for the Phase 5 pack registry root and the now-supported shell posture.

## Verification

- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
