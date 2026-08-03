---
phase: 161-ios-pronunciation-pack-seam
reviewed: 2026-08-03T18:30:05Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj
  - examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift
  - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
  - examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift
  - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
  - examples/ios_shell_host/CrosswakeShellTests/RequiredPackViewTests.swift
  - examples/ios_shell_host/Fixtures/declared_pack_requirements.json
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackProvider.swift
  - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 161: Code Review Report

**Reviewed:** 2026-08-03T18:30:05Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The package state machine and proof-lane artifact checks were reviewed together with the example host adapter. The host adapter can report a pack as available from stale inventory after its bytes are deleted, corrupted, or replaced, so route activation can proceed without verified offline pronunciation media. Its install transaction can also leave those stale attestations behind on an inventory-write failure. Both violate the phase's fail-closed availability contract.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Reconciliation trusts an inventory claim instead of the installed bytes

**Classification:** BLOCKER

**File:** `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift:22`

**Issue:** `status(for:)` reads and returns the persisted `PackInstalledRecord` without checking that the corresponding artifact still exists or recomputing its byte count and SHA-256. `PackStore` then accepts the record's self-reported `integrityVerified` and `atomicPromotionCompleted` flags as sufficient for `.available` (see `PackStore.swift:220-233`), and `ActivationCoordinator` mounts the route when the status is available (`ActivationCoordinator.swift:395-404`). Thus deletion or modification of `pack-<id>` after a prior successful install is reported as a valid install on relaunch and permits activation even though offline audio is absent or wrong. This is a fail-open availability/integrity defect.

**Fix:** In `status(for:)`, locate the artifact and verify its current bytes against the supplied `PackRequirement` before returning `.installed`; return `.notInstalled` for absence and a closed failure for read, size, or digest mismatches. Do not treat persisted inventory booleans as an attestation. Add relaunch tests that delete and corrupt the promoted artifact after installation and assert that `PackStore` remains blocked and the route never resolves to `liveView`.

### CR-02: Promotion occurs before durable inventory commit and can make an old record attest to new bytes

**Classification:** BLOCKER

**File:** `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift:39-59`

**Issue:** The implementation replaces the live artifact at lines 40-44, then writes the corresponding inventory record at lines 54-56. If `saveInventory` fails after a replacement, the method returns `.atomicInstallFailed`, but the old inventory remains while the artifact already contains the new version's bytes. On the next `status(for:)`, lines 22-24 return the old record without inspecting the artifact; the old requirement can therefore be marked available and activate a route against different bytes. This also fails the stated last-known-good preservation requirement: a failed replacement has destroyed the prior artifact.

**Fix:** Make artifact and inventory promotion a recoverable transaction: keep the prior artifact until the new inventory has been durably staged, then atomically commit both (or roll the artifact back if inventory persistence fails). At minimum, retain a rollback copy and restore it on every post-promotion failure. Couple this with CR-01's fresh status verification so an interrupted transaction is always closed. Add an injected inventory-write-failure test for a version replacement and verify that a fresh provider reports the original verified record and original bytes, or otherwise blocks.

---

_Reviewed: 2026-08-03T18:30:05Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
