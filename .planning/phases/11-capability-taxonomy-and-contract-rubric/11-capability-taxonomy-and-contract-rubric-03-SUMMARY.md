---
phase: 11-capability-taxonomy-and-contract-rubric
plan: 03
subsystem: generated-docs-and-parity
requirements-completed: [CAPA-02, CAPA-03]
completed: 2026-05-19
---

# Phase 11 - Plan 03 Summary

## Objective Completed
Published the first concrete package-class examples and rendered support-matrix family section from canonical metadata so the docs stay aligned mechanically.

## Tasks Completed
1. **Expanded the capability guide with package-boundary rules and example classifications**: Added the locked `core`, `companion`, `example/docs-only`, and `defer` rules plus the first public family example set and explicit defer reasons.
2. **Linked exemplar lanes back to the new family taxonomy**: Updated `guides/adopter_profiles.md` so the SaaS, selective-native, and local-first lanes point back to the relevant capability families and ownership posture.
3. **Rendered capability-family support truth into the generated support guide**: Updated `Crosswake.SupportMatrix.Renderer`, regenerated `guides/support_matrix.md`, and extended the guide/renderer tests so public examples stay aligned with manifest-derived support rows.

## Output
- `guides/capabilities.md`, `guides/adopter_profiles.md`, and `guides/support_matrix.md` now publish the same Phase 11 taxonomy and package-boundary story.
- The generated support matrix now includes a capability-family table with owner, package, proof, rebuild, prerequisites, denial, fallback, and guide columns.
- `mix test test/crosswake/guides/capabilities_test.exs test/crosswake/support_matrix/renderer_test.exs` passes locally.
