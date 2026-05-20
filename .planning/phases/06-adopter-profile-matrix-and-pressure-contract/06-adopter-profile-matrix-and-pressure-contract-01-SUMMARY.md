---
phase: 06-adopter-profile-matrix-and-pressure-contract
plan: 01
subsystem: adopter-guides
tags: [docs, guides, support, install, shell, offline, packs]
requires:
  - phase: 05-10
    provides: proof-backed adopter guide surfaces
provides:
  - public adopter profile guide
  - guide cross-links for profile-fit routing
  - doc-integrity tests for locked profile vocabulary
requirements-completed: [PROF-01]
completed: 2026-05-17
---

# Phase 6 Plan 01: Adopter Profile Matrix Summary

Crosswake now publishes one public adopter-profile guide that compares `Phoenix SaaS Portal`, `Selective Native Flow`, and `Local-First Study Flow` without turning the matrix into a second support-status surface. The guide routes readers back to the canonical install, shell, offline, packs, and support guides for exact contract and proof details.

## Accomplishments

- Added `guides/adopter_profiles.md` with the locked seven-column matrix and one narrative section per profile.
- Wired `guides/install.md`, `guides/native_shell.md`, `guides/offline.md`, and `guides/packs.md` to use the new guide as the profile-fit entrypoint.
- Added `test/crosswake/guides/adopter_profiles_test.exs` to lock profile names, matrix columns, required cross-links, and the no-second-support-matrix boundary.

## Verification

- `mix test test/crosswake/guides/adopter_profiles_test.exs`
- `rg -n 'adopter_profiles' guides/install.md guides/native_shell.md guides/offline.md guides/packs.md`
- `rg -n 'support_matrix|native_shell|offline|packs|install' guides/adopter_profiles.md`
