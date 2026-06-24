---
phase: 126-additive-native-dev-wiring
plan: "02"
subsystem: ios-dev-scheme
tags: [ios, xcode, pbxproj, xcscheme, plist, dev-config, ats, wkappbounddomains]

requires:
  - phase: 126-01
    provides: "examples/ios_shell_host/Fixtures/route_activation-dev.json (iOS dev fixture)"

provides:
  - "Info-Dev.plist with localhost cleartext ATS exception + WKAppBoundDomains localhost + Dev display name"
  - "Debug-Dev project-level XCBuildConfiguration (C1260002)"
  - "Debug-Dev target-level XCBuildConfiguration (C1260003) with INFOPLIST_FILE = CrosswakeShell/Info-Dev.plist"
  - "PBXShellScriptBuildPhase (C1260001) guarded on CONFIGURATION == Debug-Dev; copies dev fixture at build time"
  - "Shared Dev.xcscheme whose Launch/Test/Analyze actions use Debug-Dev; Profile/Archive stay on Release"

affects:
  - 126-04-proof-posture-guard (reads Info-Dev.plist + Dev.xcscheme for guard assertions)

tech-stack:
  added: []
  patterns:
    - "C12600-prefixed UUID namespace for new Phase 126 pbxproj objects (avoids A1XXXXX collision)"
    - "INFOPLIST_FILE inline in target-level XCBuildConfiguration (avoids xcconfig GUI-override precedence gotcha)"
    - "Run Script build phase ordered AFTER Resources phase in buildPhases array (pitfall 9 guard)"
    - "CONFIGURATION == Debug-Dev guard in shell script (not DEBUG flag — plist keys cannot be conditionalized in Swift)"
    - "WKAppBoundDomains must include localhost alongside example.com (pitfall 2: WebKit silently refuses navigation otherwise)"

key-files:
  created:
    - examples/ios_shell_host/CrosswakeShell/Info-Dev.plist
    - examples/ios_shell_host/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/Dev.xcscheme
  modified:
    - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj

key-decisions:
  - "INFOPLIST_FILE set inline in target-level Debug-Dev config (not xcconfig) — avoids xcconfig GUI-override precedence gotcha per RESEARCH"
  - "NSExceptionDomains key uses hostname 'localhost' (not '127.0.0.1') — ATS requires hostname, not IP (pitfall 1)"
  - "WKAppBoundDomains array in Info-Dev.plist contains both example.com and localhost — WebKit silently refuses navigation without localhost (pitfall 2)"
  - "PBXShellScriptBuildPhase appended after Resources phase in buildPhases (pitfall 9 guard)"
  - "No NSAllowsArbitraryLoads added — cleartext scoped to localhost only"

duration: 3min
completed: 2026-06-22
status: complete
---

# Phase 126 Plan 02: iOS Dev Scheme + Info-Dev.plist + Debug-Dev Config Summary

**iOS Dev scheme backed by a new Debug-Dev build configuration using Info-Dev.plist (localhost cleartext ATS exception) and a guarded Run Script copy phase that swaps in the dev fixture at build time**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-22T17:05:55Z
- **Completed:** 2026-06-22T17:08:15Z
- **Tasks:** 3
- **Files modified:** 3 (1 created plist, 1 modified pbxproj, 1 created scheme)

## Accomplishments

- Created `Info-Dev.plist` as a copy of prod `Info.plist` with: `CFBundleDisplayName = "CrosswakeShell Dev"`, `NSAppTransportSecurity.NSExceptionDomains.localhost.NSExceptionAllowsInsecureHTTPLoads = true`, `WKAppBoundDomains = ["example.com", "localhost"]`. No `NSAllowsArbitraryLoads`.
- Added two new `XCBuildConfiguration` objects with C12600-prefixed UUIDs: project-level `Debug-Dev` (C1260002, cloned from project Debug) and target-level `Debug-Dev` (C1260003, cloned from target Debug with `INFOPLIST_FILE = CrosswakeShell/Info-Dev.plist`). Both inserted into their respective `XCConfigurationList.buildConfigurations` arrays.
- Added `PBXShellScriptBuildPhase` (C1260001) with shell script guarded on `$CONFIGURATION == Debug-Dev`; copies `$SRCROOT/Fixtures/route_activation-dev.json` over `$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/route_activation.json`. Appended to app target `buildPhases` AFTER Resources phase.
- Created `Dev.xcscheme` modeled on `CrosswakeShell.xcscheme`; `LaunchAction`, `TestAction`, and `AnalyzeAction` set `buildConfiguration="Debug-Dev"`; `ProfileAction` and `ArchiveAction` stay on `Release`. Same `BlueprintIdentifier = "A100002A0000000000000001"` and `ReferencedContainer = "container:CrosswakeShell.xcodeproj"`.
- `xcodebuild -project … -list` confirms both `Debug-Dev` build configuration and `Dev` scheme are discovered.
- Prod `Info.plist`, `CrosswakeShell.xcscheme`, and existing Debug/Release configs all byte-untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Info-Dev.plist with localhost cleartext ATS exception (D-03)** - `b1ce781` (feat)
2. **Task 2: Add Debug-Dev XCBuildConfigurations + guarded Run Script copy phase (D-01/D-04)** - `c9042dd` (feat)
3. **Task 3: Add shared Dev.xcscheme pointing Launch/Test at Debug-Dev (D-02)** - `f03b33d` (feat)

## Files Created/Modified

- `examples/ios_shell_host/CrosswakeShell/Info-Dev.plist` - Dev plist: localhost ATS exception, WKAppBoundDomains, Dev display name
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` - Added Debug-Dev project+target configs (C1260002, C1260003) + guarded Run Script phase (C1260001)
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/Dev.xcscheme` - Shared scheme with Debug-Dev on Launch/Test/Analyze; Release on Profile/Archive

## Decisions Made

- Set `INFOPLIST_FILE` inline in target-level `Debug-Dev` config (not xcconfig) to avoid xcconfig precedence gotcha per RESEARCH recommendation
- Used `localhost` as the `NSExceptionDomains` hostname (not `127.0.0.1`) — pitfall 1 guard
- Included `localhost` in `WKAppBoundDomains` alongside `example.com` — pitfall 2 guard
- Appended Run Script phase AFTER Resources in `buildPhases` — pitfall 9 guard
- UUID namespace `C12600` for all three new pbxproj objects to avoid collision with existing `A1XXXXX` UUIDs

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The cleartext ATS exception is strictly scoped to `Info-Dev.plist` (used only by `Debug-Dev`), host-pinned to `localhost`. Prod `Info.plist` is byte-untouched. T-126-01 and T-126-03 threat mitigations are fully applied as specified in the plan's threat model.

## Next Phase Readiness

- Plan 03 (Android build.gradle + dev source set) can proceed immediately — independent of iOS changes
- Plan 04 (proof-posture guard test) depends on `Info-Dev.plist` from this plan and Android dev files from Plan 03; `Info-Dev.plist` is now committed

## Self-Check

Verifying all claims before proceeding:

- `examples/ios_shell_host/CrosswakeShell/Info-Dev.plist` FOUND (created)
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` FOUND (modified)
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/xcshareddata/xcschemes/Dev.xcscheme` FOUND (created)
- Commits: b1ce781, c9042dd, f03b33d all present
- `plutil -lint Info-Dev.plist`: OK
- `plutil -lint project.pbxproj`: OK
- `Dev.xcscheme` parses as valid XML: OK
- `xcodebuild -list` shows `Debug-Dev` configuration: CONFIRMED
- `xcodebuild -list` shows `Dev` scheme: CONFIRMED
- Prod `Info.plist` untouched: CONFIRMED
- Prod `CrosswakeShell.xcscheme` untouched: CONFIRMED

## Self-Check: PASSED

---
*Phase: 126-additive-native-dev-wiring*
*Completed: 2026-06-22*
