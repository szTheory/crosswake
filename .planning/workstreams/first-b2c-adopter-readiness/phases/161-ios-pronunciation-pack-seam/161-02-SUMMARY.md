---
phase: 161-ios-pronunciation-pack-seam
plan: "02"
status: complete
subsystem: ios-pack-provider
tags: [ios, pack, integrity, revocation]
---

# Phase 161 Plan 02: iOS Pronunciation Pack Seam Summary

Host-owned pronunciation pack installation verifies fixture bytes before promotion and retains a closed, durable revocation state until safe reconciliation.

## Accomplishments

- Added the example-host provider, immutable fixture, Xcode membership, relaunch, and replacement tests.
- Restored bounded local-package compatibility for existing host consumers.
- Persisted revocation intent before invalidation and require fresh absence or verified reinstall before clearing it.

## Verification

- `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests` — passed.
- `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests` — passed.
- Focused `PronunciationPackProviderTests` Xcode test — passed with `ONLY_ACTIVE_ARCH=YES` on iPhone 17 simulator.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking issue] Restored existing host/local-core compatibility.
- Existing host code consumed capability, transfer, and denial values that local core did not expose publicly.
- Added narrow read-only/access initialization compatibility only; no pack, bridge, storage, or media authority was expanded.
- Commit: `fedb800d`

## Commits

- `aa301dc5` host pronunciation pack provider
- `fedb800d` local host compatibility repair
- `a7fe39e1` persistent pack revocation intent

## Self-Check: PASSED
