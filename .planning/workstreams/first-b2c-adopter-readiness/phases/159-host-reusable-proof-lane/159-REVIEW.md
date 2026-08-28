---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-02T00:00:00Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.typecheck.d.ts
  - examples/phoenix_host/package.json
  - examples/phoenix_host/tsconfig.offline_route_proof.json
  - lib/crosswake/proof_lane/config.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/crosswake/proof_lane/generator_fs.ex
  - lib/crosswake/proof_lane/native_promotion.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - priv/native/crosswake_evidence_promote.c
  - priv/native/crosswake_proof_lane_fs.c
  - priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - script/verify_generated_ios_shell.sh
  - script/verify_phoenix_host_proof_lane.sh
  - test/crosswake/proof_lane/config_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/ios_verifier_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-02T00:00:00Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

The generator, evidence validation, browser helpers, native publication helpers, templates, and proof scripts were reviewed at standard depth. The generated iOS shell cannot satisfy the proof contract that its own verifier requires. In addition, a native-promotion failure irreversibly consumes the requested evidence destination, preventing a safe retry.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Generated iOS proof lane can never produce the required passed outcome

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:18-21` (enforced by `ProofLaneContractTests.swift.eex:5-11`, `ProofLaneUITests.swift.eex:46-53`, and `script/verify_generated_ios_shell.sh:157-170`)

**Issue:** Every freshly generated app calls `ProofLaneHostAdapterFactory.make()`, whose only implementation returns `nil`. `ProofLaneView.refresh()` then leaves its initial `.unavailable` snapshot intact. The unit test unwraps the factory result and requires `.passed`; the UI test requires a `Passed:` label after each launch; and the verifier reports success only when those tests pass. Thus the exact generated project that `verify_generated_ios_shell.sh --proof-lane` creates (lines 54-65) necessarily fails its declared physical/simulator proof contract. The current verifier tests fake `xcodebuild` output rather than exercise this generated runtime behavior, so the defect is not caught.

**Fix:** Generate a concrete, host-supplied adapter implementation as part of the proof target (or generate tests that explicitly assert the truthful blocked/unavailable state until a host adapter is installed). If a passed result is required, make `ProofLaneHostAdapterFactory.make()` return an adapter whose `observe()` derives the result from the required host authorization/replay state, then run the real generated XCTest/UI test lane.

## Warnings

### WR-01: Failed evidence promotion permanently blocks retry at the same destination

**File:** `priv/native/crosswake_evidence_promote.c:157-161, 189-199`

**Issue:** The helper reserves the destination by creating its directory. On any later failure (write/fsync/marker/verification), cleanup removes only the two files; it never removes the now-empty reserved directory. A subsequent attempt at the same requested destination fails at `mkdirat` with `EEXIST` and is surfaced as `PL-EVIDENCE-COLLISION`, even though no complete evidence artifact exists. Transient I/O failures therefore turn into a persistent, misleading failure that requires callers to change the evidence path.

**Fix:** After deleting partial entries and before closing `parent_fd`, remove the empty reservation directory with `unlinkat(parent_fd, basename, AT_REMOVEDIR)` (treat a non-empty directory as a failed cleanup, never recursively remove it). Keep the existing no-replace behavior for completed destinations.

---

_Reviewed: 2026-08-02T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
