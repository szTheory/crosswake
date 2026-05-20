---
phase: 11-capability-taxonomy-and-contract-rubric
plan: 01
subsystem: documentation
requirements-completed: [CAPA-01]
completed: 2026-05-19
---

# Phase 11 - Plan 01 Summary

## Objective Completed
Published the ownership-first capability taxonomy and aligned the existing bridge and native-shell guides to that vocabulary.

## Tasks Completed
1. **Created the canonical capability taxonomy guide**: Added `guides/capabilities.md` with the locked ownership rubric, public family inventory, bounded-bridge/native-screen/backend-seam framing, and family naming rules.
2. **Aligned shell and bridge wording to the new family-first contract**: Updated `guides/bridge.md` and `guides/native_shell.md` so `deep_link`, `app_info`, `haptics`, `share`, and `media_capture` are explained with explicit ownership boundaries instead of plugin-style framing.
3. **Locked the public wording mechanically**: Added `test/crosswake/guides/capabilities_test.exs` so the guide inventory and aligned bridge/native-shell terms are checked directly from the published docs.

## Output
- `guides/capabilities.md` is now the public Phase 11 contract surface for family classification.
- `guides/bridge.md` and `guides/native_shell.md` now use the same ownership-first vocabulary.
- `mix test test/crosswake/guides/capabilities_test.exs` passes locally.
