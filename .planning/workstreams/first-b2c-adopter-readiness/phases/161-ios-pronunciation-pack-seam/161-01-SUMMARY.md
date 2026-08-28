---
phase: 161-ios-pronunciation-pack-seam
plan: "01"
subsystem: ios-shell-pack-runtime
tags: [ios, swift, pack-provider, integrity, activation]
requires: []
provides:
  - Versioned host-owned PackProvider contract with closed results
  - Fresh-status-only route availability for pronunciation packs
affects: [ios-shell, activation-gate, first-b2c-adopter]
tech-stack:
  added: []
  patterns: [typed-provider-seam, checking-first-reconciliation, closed-failure-reasons]
key-files:
  created:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackProvider.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackProviderFixtureTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
decisions:
  - Availability is granted only by a fresh exact provider status record, never by install acknowledgement or legacy bundled inventory.
  - Host providers retain distribution and storage authority; Crosswake receives only requirement-bound attestations.
metrics:
  duration: 5m
  completed: 2026-08-03
  tasks: 2
  files: 7
status: complete
---

# Phase 161 Plan 01: iOS Pronunciation Pack Seam Summary

Implemented a versioned, host-supplied pack provider that permits route activation only after exact, freshly reconciled integrity and atomic-promotion attestations.

## Completed Tasks

1. Added the typed `PackProvider` contract, closed results and reasons, a checking-first `PackStore`, and an immutable fixture tracer that proves fresh status is required before activation.
2. Added optional host provider injection, removed legacy bundled inventory as availability authority, and reconciled once after cold bootstrap before reactivating the request.

## Verification

- `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests/testVerifiedFixturePromotesThenFreshStatusUnblocksActivation`
- `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests && swift test --package-path packages/crosswake-shell-core-ios --filter ActivationConformanceTests`
- `swift test --package-path packages/crosswake-shell-core-ios` — 21 tests passed.

## Decisions Made

- Pack availability requires an exact current contract marker, pack ID, version, byte count, integrity attestation, atomic-promotion attestation, and fresh `status(for:)` result.
- A missing provider is a closed `provider_unavailable` denial; it cannot inherit authority from `pack_inventory.json`.
- The provider remains outside registered bridge capabilities and exposes no host transport, filesystem, playback, credential, or raw error fields.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- All provider, store, activation, fixture, and test artifacts exist.
- Task commits `057f72db`, `452d9516`, `4175f344`, and `e4e96b15` exist.
