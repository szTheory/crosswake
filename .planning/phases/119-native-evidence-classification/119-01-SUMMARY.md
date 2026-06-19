---
phase: 119-native-evidence-classification
plan: "01"
subsystem: native
tags: [swiftpm, gradle, native-host, proof-labels]
requires:
  - phase: 118-runnable-quick-start-and-real-adoption-proof
    provides: checked-in host proof path and active v13 proof vocabulary
provides:
  - checked-in iOS host published-coordinate default
  - checked-in Android host published-coordinate default
  - checked-in host README evidence labels
affects: [phase-119-native-docs, phase-119-native-drift-guard]
tech-stack:
  added: []
  patterns:
    - Checked-in host projects now default to published native coordinates.
    - Host READMEs now name the evidence class explicitly and keep `--local` visible.
key-files:
  created: []
  modified:
    - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj
    - examples/android_shell_host/app/build.gradle
    - examples/ios_shell_host/README.md
    - examples/android_shell_host/README.md
requirements-completed: [NATIVE-01]
duration: 0h 35m
completed: 2026-06-19
status: complete
---

# Phase 119 Plan 01 Summary

**Checked-in native hosts now resolve published coordinates by default and label themselves as checked-in public-coordinate proof**

## Performance

- **Duration:** 35 min
- **Started:** 2026-06-19T19:40:00Z
- **Completed:** 2026-06-19T20:15:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Switched the checked-in iOS host to the published SwiftPM mirror and removed the silent local package reference from the public default.
- Switched the checked-in Android host to `io.github.sztheory:crosswake-shell-core-android:0.1.2`.
- Labeled both checked-in host READMEs as `checked-in public-coordinate proof` with explicit coordinate-mode and limitation notes.
- Kept `--local` visible as the explicit maintainer/local-dev path.

## Task Commits

- Not recorded in this session.

## Files Created/Modified

- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj`
- `examples/android_shell_host/app/build.gradle`
- `examples/ios_shell_host/README.md`
- `examples/android_shell_host/README.md`

## Decisions Made

- The checked-in host pair is the public proof artifact; `--local` remains the maintainer escape hatch.
- Evidence labels stay explicit and narrow; native host proof does not imply simulator, emulator, or device support.

## Deviations from Plan

- None.

## Issues Encountered

- None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 119 can now reconcile the public docs and support matrix to the checked-in public-coordinate strategy.

---
*Phase: 119-native-evidence-classification*
*Completed: 2026-06-19*
