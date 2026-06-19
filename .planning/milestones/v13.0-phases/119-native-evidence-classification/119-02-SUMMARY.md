---
phase: 119-native-evidence-classification
plan: "02"
subsystem: docs
tags: [docs, support-matrix, native-shell, android-uat]
requires:
  - phase: 119-native-evidence-classification
    provides: checked-in host coordinate strategy and proof-label baseline
provides:
  - public native docs aligned to checked-in public-coordinate proof
  - canonical support-matrix label vocabulary
  - android UAT truth refreshed to v0.1.2
affects: [phase-119-native-drift-guard]
tech-stack:
  added: []
  patterns:
    - Canonical support-matrix renderer remains the source of truth for shared labels.
    - Public docs now repeat the same proof labels beside commands, paths, and captions.
key-files:
  created: []
  modified:
    - README.md
    - examples/QUICK_START.md
    - guides/install.md
    - guides/native_shell.md
    - guides/compatibility.md
    - guides/android_uat.md
    - guides/support_matrix.md
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - examples/ios_shell_host/README.md
    - examples/android_shell_host/README.md
    - priv/templates/crosswake/shell/ios/README.md.eex
    - priv/templates/crosswake/shell/android/README.md.eex
    - priv/templates/crosswake/shell/android/app/build.gradle.eex
    - test/crosswake/guides/release_boundaries_test.exs
    - test/crosswake/support_matrix/renderer_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
requirements-completed: [NATIVE-02]
duration: 0h 55m
completed: 2026-06-19
status: complete
---

# Phase 119 Plan 02 Summary

**Public native docs and the canonical support matrix now speak one evidence-label language**

## Performance

- **Duration:** 55 min
- **Started:** 2026-06-19T20:15:00Z
- **Completed:** 2026-06-19T21:10:00Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Reconciled README, quick start, install, native shell, compatibility, Android UAT, host READMEs, and generated templates to the same native evidence labels.
- Added `checked-in public-coordinate proof` to the canonical support-truth legend and kept the renderer/source pair in sync.
- Updated `guides/android_uat.md` to current `0.1.2` truth with explicit JVM hermetic, emulator, device, verification-required, and rebuild-required labels.
- Regenerated `guides/support_matrix.md` from the renderer and updated the docs tests to lock the new vocabulary in.

## Task Commits

- Not recorded in this session.

## Files Created/Modified

- `README.md`
- `examples/QUICK_START.md`
- `guides/install.md`
- `guides/native_shell.md`
- `guides/compatibility.md`
- `guides/android_uat.md`
- `guides/support_matrix.md`
- `lib/crosswake/support_matrix/renderer.ex`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `examples/ios_shell_host/README.md`
- `examples/android_shell_host/README.md`
- `priv/templates/crosswake/shell/ios/README.md.eex`
- `priv/templates/crosswake/shell/android/README.md.eex`
- `priv/templates/crosswake/shell/android/app/build.gradle.eex`
- `test/crosswake/guides/release_boundaries_test.exs`
- `test/crosswake/support_matrix/renderer_test.exs`
- `test/crosswake/support_matrix/support_matrix_test.exs`

## Decisions Made

- Kept the support matrix canonical rather than duplicating label logic in ad hoc prose.
- Used short, operational label chips and limitation text instead of broader mobile-framework language.

## Deviations from Plan

- None.

## Issues Encountered

- `mix docs` emitted pre-existing hidden-module documentation warnings unrelated to this phase.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 119 can now add the drift guard so stale coordinates and missing labels do not return.

---
*Phase: 119-native-evidence-classification*
*Completed: 2026-06-19*
