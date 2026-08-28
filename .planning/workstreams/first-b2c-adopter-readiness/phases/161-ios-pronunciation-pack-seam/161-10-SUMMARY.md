---
phase: 161-ios-pronunciation-pack-seam
plan: "10"
subsystem: ios-host
tags: [swift, xcode, xctest, cryptokit, pronunciation-pack]
requires:
  - phase: 161-09
    provides: reference-host pack provider and exact requirement fixtures
provides:
  - Source-built dual-architecture CrosswakeShellCore framework for the reference iOS host
  - Byte-backed installed-artifact reconciliation with closed provider failures
  - Recoverable artifact-plus-inventory publication rollback
affects: [phase-162-physical-iphone-proof, ios-shell-host]
tech-stack:
  added: []
  patterns:
    - Source-framework target is built before the app and test bundle for both simulator architectures.
    - Host pack status re-attests current private artifact bytes before granting core availability.
    - Publication retains the prior artifact until matching inventory persistence succeeds.
key-files:
  created: []
  modified:
    - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj
    - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
    - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
key-decisions:
  - "Use an in-project source-built CrosswakeShellCore.framework, not a checked-in XCFramework, so destination-derived simulator and device builds consume the module in dependency order."
  - "Treat inventory as metadata only: every status result must verify current bytes against the supplied requirement."
  - "On post-promotion inventory failure, restore the prior artifact and exact inventory bytes; first installs remove their unpublished artifact."
requirements-completed: [PACK-01, PACK-02, PACK-03, PACK-04]
coverage:
  - id: D1
    description: Clean hosted XCTest builds a source-based CrosswakeShellCore module for arm64 and x86_64 simulator architectures without architecture masking.
    requirement: PACK-01
    verification:
      - kind: integration
        ref: "xcodebuild clean test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -derivedDataPath .build/phase161-reference-host-architecture -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CrosswakeShellTests/PronunciationPackProviderTests CODE_SIGNING_ALLOWED=NO"
        status: pass
    human_judgment: false
  - id: D2
    description: Current artifact deletion, corruption, wrong size, and read failures remain route-blocking on fresh provider reconciliation.
    requirement: PACK-02
    verification:
      - kind: integration
        ref: "examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift#testDeletedArtifactBlocksFreshProviderAndPackStore"
        status: pass
      - kind: integration
        ref: "examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift#testSameSizeCorruptionFailsDigestVerificationAfterRelaunch"
        status: pass
    human_judgment: false
  - id: D3
    description: Failed inventory persistence restores known-good bytes and inventory or leaves a first install unpublished.
    requirement: PACK-03
    verification:
      - kind: integration
        ref: "xcodebuild clean test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -derivedDataPath .build/phase161-reference-host-rollback -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CrosswakeShellTests/PronunciationPackProviderTests CODE_SIGNING_ALLOWED=NO"
        status: pass
    human_judgment: false
  - id: D4
    description: Provider contract stays requirement/result-only while the host retains filesystem, hashing, inventory, and rollback authority.
    requirement: PACK-04
    verification:
      - kind: integration
        ref: "CrosswakeShellTests/PronunciationPackProviderTests XCTest suite"
        status: pass
    human_judgment: false
duration: 8m
completed: 2026-08-03
status: complete
---

# Phase 161 Plan 10: Reference Host Integrity and Simulator Compatibility Summary

**A source-built iOS core framework now supports clean dual-architecture host tests, while provider availability and publication are bound to current verified artifact bytes.**

## Performance

- **Duration:** 8m
- **Started:** 2026-08-03T19:20:00Z
- **Completed:** 2026-08-03T19:28:14Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Replaced the local Swift package build path with an in-project `CrosswakeShellCore.framework` source target, embedded in the host app and built before its app and XCTest consumers for arm64 and x86_64 simulator builds.
- Reconciled every installed provider status through bounded SHA-256 and byte-count verification of the host-private artifact; absent, corrupt, malformed, and unreadable artifacts remain closed results.
- Made artifact and inventory publication recoverable: failed inventory persistence restores the prior pair or removes a first-install artifact before returning a closed failure.

## Task Commits

1. **Task 1: Repair and prove clean simulator architecture compatibility** - `e6504eac` (fix)
2. **Task 2: Reconcile every current artifact byte before route availability** - `50c6841f` (test), `c13f6b4a` (feat)
3. **Task 3: Roll back every post-promotion inventory failure as one recoverable publication** - `1a146d30` (test), `a328719b` (feat)

## Files Created/Modified

- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` - source-built Core framework target, destination-compatible platform settings, and framework embedding.
- `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift` - current-byte reconciliation plus private, recoverable publication mechanics.
- `examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift` - fresh-relaunch corruption, read failure, and rollback regressions.

## Decisions Made

- Used a source-based framework target instead of a checked-in binary wrapper, as explicitly approved at the continuation checkpoint.
- Kept device support and standard destination-derived architectures; no `ONLY_ACTIVE_ARCH`, `EXCLUDED_ARCHS`, or CPU-specific override was introduced.
- Kept all byte, file, inventory, hashing, and transaction details host-private behind the unchanged provider seam.

## Deviations from Plan

### Approved Structural Adjustment

**1. [Rule 4 - Approved architecture] Replaced the local package product with a source-built framework target**
- **Found during:** Task 1
- **Issue:** Xcode built the local package and hosted app on incompatible simulator module paths, leaving `CrosswakeShellCore` unresolved in a clean dual-architecture build.
- **Fix:** Added the smallest in-project source framework target with explicit dependency ordering and host embedding; no binary framework was checked in.
- **Files modified:** `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj`
- **Verification:** Task 1 clean iPhone 17 simulator XCTest gate passed.
- **Committed in:** `e6504eac`

**Impact on plan:** The user approved this structural repair. It preserves the plan's no-mask architecture requirement and provider boundary.

## Issues Encountered

- The first static-library target was built under macOS output paths because it lacked iOS platform declarations. Converting it to the approved source framework target with explicit iOS supported platforms and a generated framework plist made the clean simulator module consumable.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The reference host has clean simulator proof for the foreground pack provider. Physical-iPhone proof remains advisory in this phase and is still owned by Phase 162; no physical-device claim is made here.

## Self-Check: PASSED

- Confirmed the three modified project files exist and the five task commits are present in `git log`.

---
*Phase: 161-ios-pronunciation-pack-seam*
*Completed: 2026-08-03*
