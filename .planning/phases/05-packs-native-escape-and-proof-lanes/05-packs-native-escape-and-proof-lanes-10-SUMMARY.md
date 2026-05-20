---
phase: 05-packs-native-escape-and-proof-lanes
plan: 10
subsystem: adopter-guides
tags: [docs, install, compatibility, packs, native-shell, bridge]
requires:
  - phase: 05-08
    provides: proof-backed phase 5 install lanes
  - phase: 05-09
    provides: canonical support publication truth
provides:
  - refreshed install guide
  - refreshed compatibility guide
  - refreshed native shell guide
  - refreshed bridge guide
  - new packs guide
completed: 2026-05-17
---

# Phase 5 Plan 10: Adopter Guides Summary

The adopter-facing guides now match the final Phase 5 contract. They point to the checked-in example hosts as the public proof artifact class, keep generated-host verification as secondary proof, and document packs, explicit transfers, and the single `:native_screen` native-capture escape hatch without widening into adapters or generic container behavior.

## Accomplishments

- Updated `guides/install.md` to center the example-host proof lane and clarify the role of `--native-checks`.
- Updated `guides/compatibility.md` to publish the proof-backed shell posture and the bounded Phase 5 transfer surface.
- Updated `guides/native_shell.md` to document the single `:native_screen` native capture flow, staged versus transferred state, and explicit non-fallback behavior.
- Updated `guides/bridge.md` to include the Phase 5 transfer commands and foreground-first transfer-state vocabulary.
- Added `guides/packs.md` for required-pack lifecycle, transfer seams, and native-capture handoff.

## Verification

- `rg -n 'example hosts|generated-host|foreground-first|queued|awaiting_network|Install Required Pack|transfer' guides/install.md guides/compatibility.md guides/bridge.md guides/packs.md`
- `rg -n 'Native capture|:native_screen|staged|transferred|adapter|fallback|support matrix' guides/native_shell.md`
