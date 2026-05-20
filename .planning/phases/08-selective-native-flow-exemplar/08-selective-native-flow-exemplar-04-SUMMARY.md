---
phase: 08-selective-native-flow-exemplar
plan: 04
subsystem: documentation
requirements-completed: [NATIVE-02]
completed: 2026-05-18
---

# Phase 8 - Plan 04 Summary

## Objective Completed
Refreshed the public documentation and rough-edge truth for the selective-native lane.

## Tasks Completed
1. **Updated shared-host and adopter-profile docs to the locked claims-evidence lane**: Refreshed `examples/phoenix_host/README.md` and `guides/adopter_profiles.md` so the selective-native profile is publicly defined by the nested claims-evidence lane instead of an older generic route set. Made the route budget, `:camera` capability, route-local pack gate, and review-before-upload posture explicit. Updated the `script/verify_adopter_profile_contract.sh` test loop to ensure ongoing doc alignment.
2. **Aligned packs, shell, bridge, and install guides to the new public lane**: Updated `guides/packs.md`, `guides/native_shell.md`, `guides/bridge.md`, and `guides/install.md` so the selective-native exemplar is explained consistently across pack, shell, bridge, and install docs. Kept wording plain: media stays local until Phoenix review confirms upload, and `pack_incompatible` remains visible when activation fails. Support and proof status still route back to the canonical matrices.

## Output
- `guides/adopter_profiles.md` and `examples/phoenix_host/README.md` now refer to the explicit claims-evidence routes and state transitions.
- `guides/packs.md`, `guides/native_shell.md`, `guides/bridge.md`, and `guides/install.md` explicitly cover `pack_incompatible` and `transfer.upload.prepare` in the context of the new Phase 8 selective-native exemplar.
- All proof tests and verification scripts successfully pass locally.
