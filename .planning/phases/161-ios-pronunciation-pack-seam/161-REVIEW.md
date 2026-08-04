---
phase: 161-ios-pronunciation-pack-seam
reviewed: 2026-08-04T01:25:14Z
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

**Reviewed:** 2026-08-04T01:25:14Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

The provider and core seam are generally fail-closed: route activation waits for provider-attested bytes, and the host recovery journal prevents interrupted publication from silently becoming available. The generated iOS proof lane is not run-isolated, however. A stale pack in the simulator container can satisfy the current UI assertions and cause the verifier to report a current-run advisory pass without performing the asserted installation.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Generated proof can certify a stale installed pack as a fresh installation

**File:** `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex:15-30`
**Issue:** The UI test enables the reference adapter, taps install, and only checks for a `Passed` outcome. It neither clears the adapter's Application Support artifact nor asserts that the adapter initially reports `Blocked`. `ProofLaneReferencePackAdapter` persists at a fixed Application Support path ([ProofLaneDriver.swift.eex:165-175](priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex)), while the proof verifier runs `test-without-building` without uninstalling/resetting the proof-lane app ([verify_generated_ios_shell.sh:184-216](script/verify_generated_ios_shell.sh)). Consequently a prior run's valid fixture can make the test pass even if this run's install action does nothing or fails. The verifier then accepts the test markers and emits `PL-IOS-PACK-AUDIO-ADVISORY: passed`, producing misleading proof evidence.

**Fix:** Add a test-only reset launch argument/environment handled by the generated app before it constructs the adapter, and assert the reference-adapter launch begins `Blocked` before tapping install. For example:

```swift
// ProofLaneApp.swift.eex, before ProofLaneHostAdapterFactory.make()
if ProcessInfo.processInfo.environment["CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK"] == "1" {
  ProofLaneReferencePackAdapter.resetReferencePersistenceForTests()
}
```

```swift
app.launchEnvironment["CROSSWAKE_PROOF_LANE_REFERENCE_PACK_ADAPTER"] = "1"
app.launchEnvironment["CROSSWAKE_PROOF_LANE_RESET_REFERENCE_PACK"] = "1"
app.launch()
assertBlockedPackOutcome(in: app)
install.tap()
assertAdapterDerivedPassedOutcome(in: app)
```

Keep the reset limited to the generated reference adapter/test mode so it cannot alter a host-supplied provider's storage.

---

_Reviewed: 2026-08-04T01:25:14Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
