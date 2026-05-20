---
phase: 12-packaging-ledger-and-release-boundaries
plan: 03
subsystem: change-classes-and-rebuild-guidance
requirements-completed: [PKG-03]
completed: 2026-05-19
---

# Phase 12 - Plan 03 Summary

## Objective Completed
Published the four public change classes, rebuild-first guidance, and docs-only graduation rules across generated support truth and public docs.

## Tasks Completed
1. **Added canonical change-class support entries**: Extended the support-matrix model and renderer with `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, and `native or companion rebuild required`.
2. **Made rebuild guidance action-first in public docs**: Updated `guides/install.md`, `guides/native_shell.md`, and `guides/compatibility.md` so the user-facing answer starts with whether a rebuild is required and which proof lane to run.
3. **Locked docs-only graduation rules mechanically**: Added `test/crosswake/guides/release_boundaries_test.exs` and updated guide tests so runnable docs-only lanes cannot be implied without reclassification plus proof.

## Output
- Generated support truth now answers package class, compatibility policy, and rebuild class from one canonical renderer.
- Public guides now answer “Do I need to rebuild?” before raw version details.
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/compatibility/compatibility_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs test/crosswake/guides/release_boundaries_test.exs` passes locally.
