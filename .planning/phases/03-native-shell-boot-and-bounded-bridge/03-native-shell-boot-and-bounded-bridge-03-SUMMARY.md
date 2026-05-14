---
phase: 03-native-shell-boot-and-bounded-bridge
plan: 03
subsystem: ios-shell
tags: [ios, shell-generator, xcode, webkit, verification]
requires:
  - phase: 03-native-shell-boot-and-bounded-bridge
    provides: typed activation requests, shared denial vocabulary, shell fixture export
provides:
  - manifest-first iOS shell boot templates
  - bounded same-origin WKWebView hosting for declared live_view routes
  - generated-project iOS verification hook via xcodebuild
affects: [03-04 android-shell, 03-05 bounded-bridge, proof-lanes]
tech-stack:
  added: []
  patterns: [manifest-first activation, host-owned Xcode baseline, same-origin app-bound webview, loud proof-lane failure]
key-files:
  created:
    - priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex
    - priv/templates/crosswake/shell/ios/Info.plist.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme.eex
    - priv/templates/crosswake/shell/ios/ActivationCoordinator.swift.eex
    - priv/templates/crosswake/shell/ios/LiveViewContainerViewController.swift.eex
    - priv/templates/crosswake/shell/ios/RouteUnavailableView.swift.eex
    - priv/templates/crosswake/shell/ios/CrosswakeShellTests/ActivationCoordinatorTests.swift.eex
    - script/verify_generated_ios_shell.sh
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/mix/tasks/crosswake_gen_shell_test.exs
key-decisions:
  - "The iOS shell resolves bundled manifest truth and activation input inside ActivationCoordinator before any WKWebView exists."
  - "Only declared live_view routes may enter LiveViewContainerViewController, which enforces same-origin navigation with App-Bound Domains enabled."
  - "The generated-project proof hook must fail loudly with raw xcodebuild output when the host Xcode environment is broken, instead of faking proof."
patterns-established:
  - "Crosswake iOS shells are host-owned Xcode projects with explicit denial UX instead of generic web fallback."
  - "Generated XCTest coverage travels with the shell scaffold so adopters inherit route-allow and denial proof lanes."
requirements-completed: [SHELL-01, SHELL-03, MANI-03]
duration: 21min
completed: 2026-05-15
---

# Phase 3 Plan 3: Native Shell Boot And Bounded Bridge Summary

**Generated iOS shells now boot from bundled manifest truth, deny blocked routes on a native Crosswake surface, and wire allowed LiveView routes into a bounded same-origin WebKit container.**

## Performance

- **Duration:** 21 min
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added real iOS template artifacts for the generated shell app, Info.plist, Xcode project, shared scheme, activation coordinator, denial UI, bounded WebKit container, and generated XCTest coverage.
- Rewired `mix crosswake.gen.shell` to emit the host-owned iOS Xcode baseline from repo-owned templates instead of inline stubs.
- Added `script/verify_generated_ios_shell.sh` to generate a fresh shell, select an iPhone simulator from `xcodebuild -showdestinations`, and fail loudly when the Xcode proof lane is unavailable.

## Task Commits

1. **Task 1: manifest-first boot and denial surface** - `27b63f3` (`feat`)
2. **Task 2: bounded WebKit hosting and iOS proof hook** - `299f246` (`feat`)

## Verification

- `mix test test/mix/tasks/crosswake_gen_shell_test.exs` — passed
- `script/verify_generated_ios_shell.sh` — failed in the host environment before project evaluation because `xcodebuild` could not load `IDESimulatorFoundation`; the missing dependency was `/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Versions/A/CoreSimulator`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created `LiveViewContainerViewController.swift.eex` during Task 1 so the generator could render the new Xcode baseline**
- **Found during:** Task 1 verification
- **Issue:** Task 1 rewired the generator to render the full iOS template set, but the container template did not exist yet, so `mix crosswake.gen.shell` failed before the Task 1 assertions could run.
- **Fix:** Added a minimal compile-safe container template in Task 1, then expanded it into the bounded `WKWebView` host during Task 2.
- **Files modified:** `priv/templates/crosswake/shell/ios/LiveViewContainerViewController.swift.eex`, `lib/mix/tasks/crosswake.gen.shell.ex`
- **Committed in:** `27b63f3`

## Deferred Issues

- The generated-project proof lane is blocked by the machine’s Xcode installation, not by repo code. `xcodebuild -list` fails before reading project content because `IDESimulatorFoundation` cannot load `CoreSimulator`. Apple’s own output suggests `xcodebuild -runFirstLaunch`, but that did not complete successfully in this session.

## User Setup Required

- Repair the local Xcode installation so `xcodebuild` can load simulator plug-ins. The current failure is: `xcodebuild failed to load a required plug-in` with a missing `CoreSimulator.framework`.

## Self-Check: PASSED

- Verified summary file exists at `.planning/phases/03-native-shell-boot-and-bounded-bridge/03-native-shell-boot-and-bounded-bridge-03-SUMMARY.md`.
- Verified required files exist: `priv/templates/crosswake/shell/ios/CrosswakeShellApp.swift.eex`, `priv/templates/crosswake/shell/ios/Info.plist.eex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/CrosswakeShell.xcscheme.eex`, `priv/templates/crosswake/shell/ios/ActivationCoordinator.swift.eex`, `priv/templates/crosswake/shell/ios/LiveViewContainerViewController.swift.eex`, `priv/templates/crosswake/shell/ios/RouteUnavailableView.swift.eex`, `priv/templates/crosswake/shell/ios/CrosswakeShellTests/ActivationCoordinatorTests.swift.eex`, `script/verify_generated_ios_shell.sh`.
- Verified commit hashes exist in git history: `27b63f3`, `299f246`.
