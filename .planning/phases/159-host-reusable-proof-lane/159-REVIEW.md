---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-01T23:15:14Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-01T23:15:14Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The configuration, evidence, filesystem-confinement, and native-promotion paths were read in context. The targeted ExUnit suite and Phoenix-host TypeScript typecheck pass, but the generator emits a browser `*.spec.ts` file that contains no Playwright test and never invokes the offline proof helper. A newly generated host therefore has no generated browser/offline-island coverage, while the repository fixture passes separately.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Generated browser proof spec is inert

**Classification:** BLOCKER

**File:** `priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex:4-6` (rendered by `lib/crosswake/proof_lane/generator.ex:11`)
**Issue:** The generator creates `e2e/crosswake_proof_lane/proof_lane.spec.ts`, but its template merely exports a small wrapper and does not import Playwright, declare a `test`, or call the generated `support/proof_lane.ts` offline sequence. Playwright therefore has no generated proof to execute. `verify_phoenix_host_proof_lane.sh` succeeds by running the hand-maintained example-host spec instead, so it cannot establish that a generated host preserves the required browser/IndexedDB/replay proof.
**Fix:** Generate a real host-owned Playwright test scaffold which imports `test` and `runOfflineIslandProof` from the generated support module, and exposes explicit adapter callbacks for route navigation, mutation, queued-record read, reconnect, backend confirmation, outbox-empty, and duplicate-idempotency assertions. Add a generator contract test that renders the spec and verifies it contains at least one `test(...)` invocation wired to `runOfflineIslandProof`; run that rendered spec in the generated-host proof command.

---

_Reviewed: 2026-08-01T23:15:14Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
