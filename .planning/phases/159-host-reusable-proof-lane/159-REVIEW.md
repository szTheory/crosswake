---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-01T02:17:11Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
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
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
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
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-01T02:17:11Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The generator and evidence code have strong no-clobber and containment intent, and the focused ExUnit suite passes. However, the iOS verifier promotes a test run of the unconnected placeholder app as a passed proof, and configuration accepted by the closed normalizer can produce syntactically invalid generated TypeScript. Both defects undermine the lane's fail-closed contract.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Unwired proof lane is promoted as a passing result

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:18-21`; `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex:10-17`; `script/verify_generated_ios_shell.sh:164`
**Issue:** The generated adapter factory always returns `nil`, so the app has no host probe, no auth/replay capability, and remains in the default `.unavailable` state. The UI test explicitly accepts `Unavailable`, and the verification script emits `{"outcome":"passed"}` whenever the XCTest/XCUITest bundles execute. Consequently, a newly generated, completely unintegrated lane passes the command that is supposed to communicate whether the real host crossing worked. This violates the required explicit blocking prerequisite and creates false proof evidence.
**Fix:** Make a missing or placeholder host adapter a deterministic blocked result. For example, expose a stable `adapterInstalled`/`probeConfigured` condition in the app and require the UI test and verifier to observe a non-placeholder adapter before returning `passed`; otherwise emit a `blocked` outcome with a stable prerequisite rule. Keep the unavailable state only for genuinely unavailable tool/device capabilities, not an unimplemented host integration.

### CR-02: Accepted endpoint configuration is emitted into TypeScript without escaping

**File:** `lib/crosswake/proof_lane/config.ex:141-144`; `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex:63-64`
**Issue:** `host_local_path?/1` allows double quotes and backslashes. Those values are interpolated directly between TypeScript double quotes. For example, `sync_path: "/proof\""` normalizes successfully, then renders an unterminated `syncPath` string and prevents the generated browser lane from compiling. More complex accepted characters can alter the generated source. This breaks the promised closed configuration boundary and fails after files have been generated.
**Fix:** Validate endpoint values against a strict path-segment grammar that excludes JavaScript string delimiters/control characters, and render all string values with a real TypeScript/JSON string encoder rather than raw EEx interpolation. Add generation/typecheck coverage for quote and backslash inputs, asserting they are rejected before any output is written.

---

_Reviewed: 2026-08-01T02:17:11Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
