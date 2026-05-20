---
phase: 12-packaging-ledger-and-release-boundaries
plan: 02
subsystem: release-policy-and-doctor
requirements-completed: [PKG-02]
completed: 2026-05-19
---

# Phase 12 - Plan 02 Summary

## Objective Completed
Defined the hybrid versioning policy in canonical support truth, the compatibility guide, and doctor diagnostics.

## Tasks Completed
1. **Added canonical release-boundary entries**: Extended the support-matrix model with release/versioning policy rows for `core`, `companion`, `ios_shell`, and `android_shell`.
2. **Published the companion-ready compatibility contract**: Rewrote `guides/compatibility.md` around package versions versus compatibility axes, companion compatibility ranges, release choreography, and runtime-line rules.
3. **Surfaced release policy through diagnostics**: Updated `Crosswake.Doctor`, the human formatter, and the JSON formatter so doctor output now reports the three compatibility axes and warns that package versions alone do not determine support truth.

## Output
- Crosswake now states release-policy truth in generated support output and doctor diagnostics instead of leaving it to prose inference.
- The compatibility guide now teaches how package SemVer, capability versions, and runtime axes interact.
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/compatibility/compatibility_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs` passes locally.
