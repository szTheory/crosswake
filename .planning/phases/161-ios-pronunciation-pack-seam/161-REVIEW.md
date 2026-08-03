---
phase: 161-ios-pronunciation-pack-seam
reviewed: 2026-08-03T16:43:01Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj
  - examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift
  - examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift
  - examples/ios_shell_host/CrosswakeShellTests/RequiredPackViewTests.swift
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackProvider.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackProviderFixtureTests.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/ios/Resources/pronunciation-pack-fixture.bin.eex
  - script/verify_generated_ios_shell.sh
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/ios_verifier_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 161: Code Review Report

**Reviewed:** 2026-08-03T16:43:01Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

The new pack seam has multiple fail-closed and proof-integrity failures. In particular, the bundled declaration loses the byte/digest requirement required by the host provider, malformed pack declarations can silently remove the activation gate, and the generated proof lane reports offline-audio success without either verified installation or audio playback. The scoped ExUnit proof tests passed (40 tests), but they do not exercise these paths against the real adapter semantics.

## Critical Issues

### CR-01: Bundled pack requirements discard integrity metadata, so the example host cannot install its declared pack

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift:89`

**Issue:** `PackStore.bundled` decodes only `[String: String]` versions and constructs every `PackRequirement` with `expectedByteCount: 0` and `expectedSHA256: ""` (lines 90-93). The composition root supplies `PronunciationPackProvider`, which rejects a nonempty fixture unless those two fields match (the provider is constructed at `CrosswakeShellApp.swift:235-249`). Consequently the route's first foreground install always fails its size/digest checks and can never reach `.available`. The private runtime-computed requirement at `CrosswakeShellApp.swift:252-260` is not passed to `PackStore` and therefore cannot repair the requirement it gives the provider.

**Fix:** Make the bundled declaration decode a versioned `PackRequirement` wire format containing a positive byte count and a pinned SHA-256, validate it before constructing the store, and fail closed on missing or malformed integrity fields. Do not calculate the expected digest from the downloaded/bundled bytes at install time.

### CR-02: A malformed required-pack declaration silently allows route activation

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift:96`

**Issue:** `blockingStatus(for:)` applies `compactMap(parse(packReference:))`; any declaration without exactly one `id@version` pair is discarded. If every declared pack is malformed (for example, `"lesson_library"`), the resulting list is empty and `.first(where:)` returns `nil`, so `ActivationCoordinator.resolve` at `ActivationCoordinator.swift:395` continues into the LiveView. A corrupted or incomplete pack manifest thus degrades from a required-media denial into unguarded activation, contrary to the required explicit fail-closed posture.

**Fix:** Parse every entry before checking status and return a failed blocking status (or a dedicated manifest/pack incompatibility denial) whenever any reference is malformed, empty, unknown, or incompatible with its declared requirement.

### CR-03: Concurrent reconciliation can clear an invalidation fence and re-enable a pack whose removal failed

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift:124-156`

**Issue:** `invalidatePack` persists a revocation and then awaits the provider (lines 124-133). Because `PackStore` is main-actor isolated, a pending `reconcileAll` can run while that await is suspended. If it sees the old installed record, `reconcile` clears the revocation at lines 148-155. If the original invalidation then fails, it reports `.failed` once, but the cleared fence lets the next reconciliation trust the old record and restore `.available`. This can activate a route with bytes the user explicitly attempted to revoke after an invalidation failure.

**Fix:** Associate invalidation with a per-pack operation generation/state and ignore stale reconciliation results. Only clear the persisted revocation after the same invalidation operation has both removed the artifact and obtained a fresh `.notInstalled` status; reconciliation must never independently clear that fence.

### CR-04: Generated proof lane reports pack-audio success without installing verified bytes or playing audio offline

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:41-52`

**Issue:** The reference adapter treats any nonempty bundled fixture as a successful installation, records only a `UserDefaults` boolean, and `exerciseInstalledPronunciationAudioOffline()` merely returns `observe()`. It performs no SHA-256/size check, atomic storage promotion, readback, codec/audio operation, or network-disabled assertion. The UI test then prints `PACK-AUDIO-OFFLINE` after setting `CROSSWAKE_PROOF_LANE_NETWORK_DISABLED` only after relaunch and without the adapter reading it (`ProofLaneUITests.swift.eex:26-31`); the shell script converts those strings into a `passed` pack-audio outcome (`verify_generated_ios_shell.sh:188-195`). This is a false positive for the milestone's real offline pronunciation-media evidence and violates the ADR's prohibition on simulated storage claims.

**Fix:** Keep the generated lane blocked until a host-provided test adapter exposes real fixture acquisition, pinned digest/size validation, atomic installation, relaunch readback, and a deterministic offline playback/read operation that fails when networking would be required. Have the verifier consume structured XCTest results for those assertions rather than untrusted print markers.

## Warnings

### WR-01: LiveView URL is not bound to the allowlisted origin that was authorized

**File:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift:458-471`

**Issue:** Authorization checks `request.origin`, but the session loads `request.url` whenever it is non-nil. A caller can provide an allowlisted `origin` and a URL on another origin; `resolve` will create a LiveView session for the latter while recording the former as `allowedOrigin`. This makes the public coordinator API unsafe for host callers and risks loading an untrusted web origin under a trusted bridge/session configuration.

**Fix:** Require a parsed `resolvedURL` with an HTTPS origin exactly equal to the selected allowlisted origin (and a path matching the resolved route) before constructing `LiveViewSession`; otherwise return `.originDenied`.

---

_Reviewed: 2026-08-03T16:43:01Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
