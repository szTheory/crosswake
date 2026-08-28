---
phase: 161-ios-pronunciation-pack-seam
reviewed: 2026-08-04T02:44:13Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj
  - examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift
  - examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift
  - examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift
  - examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift
  - examples/ios_shell_host/CrosswakeShellTests/RequiredPackViewTests.swift
  - examples/ios_shell_host/CrosswakeShellUITests/RequiredPackViewAccessibilityTests.swift
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 161: Code Review Report

**Reviewed:** 2026-08-04T02:44:13Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

The reviewed implementation correctly fails route activation closed while pack state is unreconciled, and the generated proof reset chain now addresses the prior stale-simulator evidence gap. However, the crash-recovery state machine has an uncovered valid state: stale inventory without a prior artifact. A crash after its journal is written makes startup recovery fail permanently, blocking all pack operations.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Recovery permanently bricks installation when inventory outlives its artifact

**File:** `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift:147-171, 320-329`

**Classification:** BLOCKER

**Issue:** `install` records `priorRecord` from `inventory.json` even when the corresponding destination file does not exist (`hadPriorArtifact == false`). That state is reachable after a crash during `invalidate` after the artifact removal succeeds but before the inventory write, or after a missing/corrupt artifact is reconciled. If the process then crashes after `persistJournal` at line 171 but before promotion, recovery enters `.promotionPending`, sees the non-nil `priorRecord`, and requires the never-created `retained` file at line 323. Recovery throws, `startupRecovery` remains failed, and every subsequent `status`, `install`, and `invalidate` returns a failure indefinitely. This breaks the required restart-safe, fail-closed recovery path rather than allowing the user to reinstall.

**Fix:** Only treat the previous record as recoverable when a verified previous artifact was retained. For example, derive the journal record from `hadPriorArtifact`, and add a regression test for `inventory present + destination absent + crash after journal persistence`:

```swift
let priorRecord = hadPriorArtifact ? loadInventory()[requirement.packID] : nil
// If no prior artifact exists, remove the stale inventory entry before journaling
// or make recovery's promotion-pending branch remove it rather than requiring retained.
```

Recovery should also explicitly handle `priorRecord == nil` by removing any stale inventory entry, preserving the current `else` path at lines 326-329.

---

_Reviewed: 2026-08-04T02:44:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
