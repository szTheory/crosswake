---
phase: 82
plan: 01
subsystem: shell-core
tags: [ios, android, swift, kotlin, routing, capability-handshake]

requires: []
provides:
  - "RouteDelegate definitions in Swift and Kotlin"
  - "Route registry inside CrosswakeShellConfig"
  - "Capability list exposure"
  - "RouteUnavailableView fallback for unmapped native routes"
affects: [82-02, routing, native_shell]

tech-stack:
  added: []
  patterns: [Registry/Delegate Pattern]

key-files:
  created:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/RouteUnavailableView.swift
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/RouteUnavailableView.kt
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/CrosswakeDelegates.kt
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/CrosswakeShellConfig.kt
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt

key-decisions:
  - "Implemented Registry/Delegate Pattern for route mapping to prevent host-specific screens from bleeding into the core."
  - "Added fail-closed RouteUnavailableView when native routes cannot be resolved."

patterns-established:
  - "RouteDelegate: standard for host applications to declare native routing capabilities to the shell"

requirements-completed: [NAV-01, NAV-02]

duration: 1m
completed: 2026-06-08
---

# Phase 82 Plan 01: Navigation Capability Handshake Summary

**Implemented RouteDelegate and capability reporting in iOS and Android shell cores with fail-closed native routing**

## Performance

- **Duration:** 1m
- **Started:** 2026-06-08T00:00:00Z
- **Completed:** 2026-06-08T00:01:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added `RouteDelegate` to allow host apps to map custom route IDs without compiling them into the core.
- Updated `CrosswakeShellConfig` to collect and expose `registeredCapabilities` dynamically based on registered delegates.
- Modified `ActivationCoordinator` to verify if a native route is registered; if not, it surfaces a `.denied` presentation which maps to `RouteUnavailableView`.

## Task Commits

1. **Task 1: Add RouteDelegate and Registry to iOS Core** - `2917fe4` (feat)
2. **Task 2: Add RouteDelegate and Registry to Android Core** - `2baa3a7` (feat)

## Files Created/Modified
- `CrosswakeDelegates.swift/kt` - Added `RouteDelegate` definitions.
- `CrosswakeShellConfig.swift/kt` - Added `routeDelegate` property and dynamic capability reporting.
- `ActivationCoordinator.swift/kt` - Added route checking against `routeDelegate` before returning `.nativeCapture`.
- `RouteUnavailableView.swift/kt` - Added default fail-closed UI.
- `CrosswakeShellConfigTest.kt` - Wrote configuration unit tests for Android.

## Decisions Made
- Used the **Registry/Delegate Pattern** to keep the core shell standalone while empowering the host apps to provide custom intent/view mappings.
- The `ActivationCoordinator` does not instantiate views directly, but instead returns enums (like `.denied` or `.nativeCapture`), offloading implementation to the host UI.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Shell cores are now capable of receiving native route delegates. The system is ready to have the hosts (example apps) actually wire up these capabilities (Phase 82 Plan 02).

---
*Phase: 82*
*Completed: 2026-06-08*