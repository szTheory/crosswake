---
phase: 161-ios-pronunciation-pack-seam
reviewed: 2026-08-03T21:21:38Z
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
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 161: Code Review Report

**Reviewed:** 2026-08-03T21:21:38Z
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

The 26 scoped implementation, template, and test files were reviewed in context. The current tree correctly closes the earlier thrown-error rollback path and binds generated proof evidence to the deny-only URLSession operation. However, replacement publication is still not atomic across process interruption: no on-disk transaction state or startup recovery can restore the prior verified artifact after a termination between its removal and commit.

Focused verification passed: `swift test --package-path packages/crosswake-shell-core-ios` (27 tests) and `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/template_contract_test.exs` (41 tests). Those suites do not cover process termination in the replacement transaction.

## Critical Issues

### CR-01: Replacement publication is not crash-atomic

**File:** `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift:87`
**Issue:** The transaction first moves the known-good destination to a randomly named retained file (lines 87–89), then separately moves staging into the destination (line 103) and writes inventory (line 105). If the app or OS terminates after the first move, or after the second move but before inventory commit, deferred cleanup and `catch` rollback never execute. On relaunch, `status` only looks for `pack-{id}` and `inventory.json` (lines 46–59); it neither discovers the retained artifact nor reconciles the new artifact with the old inventory. The required route therefore remains blocked and the advertised last-known-good/atomic-replacement guarantee is violated under an ordinary interruption such as process kill, crash, or device shutdown.

**Fix:** Persist a small, non-sensitive replacement journal before moving the live artifact, fsync it and each state transition, then recover it before `status` or `install` uses the inventory. Recovery must either restore the retained artifact and prior inventory or complete the verified new publication. Add deterministic tests that seed each journal state (prior retained, replacement promoted, inventory pending) and assert the next provider instance restores a valid, route-unblocking state. Alternatively, use an OS-supported atomic replacement primitive together with an atomic, recoverable inventory commit; do not rely on `defer`/`catch` for crash recovery.

---

_Reviewed: 2026-08-03T21:21:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
