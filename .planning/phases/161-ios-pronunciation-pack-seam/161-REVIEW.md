---
phase: 161-ios-pronunciation-pack-seam
reviewed: 2026-08-03T20:03:21Z
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
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 161: Code Review Report

**Reviewed:** 2026-08-03T20:03:21Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The pack seam correctly blocks activation when the concrete provider reports a bad or absent artifact, and the reviewed Elixir and Swift suites pass. However, the generated proof lane can emit a passing `networking_disabled` assertion without disabling or observing networking, making the evidence artifact dishonest. The provider's replacement path can also delete a previously valid pack if publication fails after it has been moved out of place.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Offline-pack proof certifies a condition it never enforces

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:40-43,92-98`

**Issue:** `ProofLanePackEvidence.networkingDisabled` is declared but never constructed or checked. The adapter always reads the bundled fixture and local Application Support file, while the UI test merely sets `CROSSWAKE_PROOF_LANE_NETWORK_DISABLED` ([ProofLaneUITests.swift.eex](/Users/jon/projects/crosswake/priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex:23)) and the contract test prints `networking_disabled` into the structured evidence ([ProofLaneContractTests.swift.eex](/Users/jon/projects/crosswake/priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex:50)). Nothing reads that environment value or verifies that network access is unavailable. Consequently, `verify_generated_ios_shell.sh` accepts a passing artifact that asserts offline audio under disabled networking even when the process has normal network access. This violates the project's evidence-honesty and physical-iPhone proof contract.

**Fix:** Make the proof adapter obtain its fixture through an injectable transport, and have the test install once with that transport available, relaunch with a transport that deterministically fails every request, and assert playback succeeds without invoking it. Emit `networking_disabled` only from that observed result. Alternatively, remove the assertion from the emitted artifact and label this generated lane strictly as an install/readback advisory until a real offline network-control harness exists.

## Warnings

### WR-01: Replacement failure can delete the previously verified pronunciation pack

**File:** `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift:76-80,106-108`

**Issue:** During an update, the provider first moves the existing artifact to `retainedArtifact`, then moves the staged file into its place. If the second move throws (for example, a filesystem or protection-state failure), control reaches the outer `catch`; its deferred cleanup deletes `retainedArtifact`. No rollback runs on this path, so the old verified artifact is lost even though the new one was never published. The route remains correctly blocked afterward, but this breaks the promised atomic replacement and unnecessarily destroys offline media.

**Fix:** Treat both publication moves and inventory persistence as one rollback-protected transaction. Record whether the old artifact was moved, and in the outer `catch` call `rollbackPublication(...)` before returning failure; only remove `retainedArtifact` after successful promotion. Add a test seam that forces the staged-to-destination move to fail and asserts the old bytes and prior inventory remain readable.

---

_Reviewed: 2026-08-03T20:03:21Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
