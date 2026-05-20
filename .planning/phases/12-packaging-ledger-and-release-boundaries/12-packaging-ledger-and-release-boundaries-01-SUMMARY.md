---
phase: 12-packaging-ledger-and-release-boundaries
plan: 01
subsystem: packaging-ledger
requirements-completed: [PKG-01]
completed: 2026-05-19
---

# Phase 12 - Plan 01 Summary

## Objective Completed
Published the packaging ledger as typed support truth and aligned the public guides to the same package-boundary story.

## Tasks Completed
1. **Added canonical package-surface support entries**: Extended `Crosswake.Manifest.Types`, `Crosswake.SupportMatrix`, and `Crosswake.SupportMatrix.Renderer` with package-surface entries so `core`, `companion`, `example/docs-only`, and `defer` render from one source of truth.
2. **Rendered the packaging ledger into the support matrix**: `guides/support_matrix.md` now includes a generated `## Packaging Ledger` section with release-burden and public-guide links.
3. **Aligned public docs with the same boundary language**: Updated `guides/capabilities.md`, `guides/install.md`, and `examples/phoenix_host/README.md` so the primary `crosswake` package, docs-only boundary, and example-host posture are explicit and mechanically tested.

## Output
- Crosswake now publishes one generated packaging ledger instead of a handwritten parallel policy table.
- Docs-only and example-host surfaces are labeled explicitly so they do not masquerade as runtime package support.
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/guides/capabilities_test.exs test/crosswake/guides/release_boundaries_test.exs` passes locally.
