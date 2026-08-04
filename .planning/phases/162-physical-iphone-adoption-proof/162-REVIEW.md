---
phase: 162-physical-iphone-adoption-proof
reviewed: 2026-08-04T23:46:08Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/physical_iphone_contract.ex
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/physical_iphone_preflight_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-04T23:46:08Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

The host-loader, parser/join, and evidence-promotion path are wired and fail closed when the repository has no external physical prerequisites. However, the generated iOS device sequence continues making real host calls after a failed prerequisite, so a deliberately blocked device run can still submit/reconcile mutations. Its public report validator also raises on malformed entries instead of returning its documented closed error.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Failed device prerequisites do not stop later mutation/replay operations

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:115-120`

**Issue:** `PhysicalIphoneSequence.run` invokes every adapter operation even when `installAndVerifyPack`, `playInstalledAudioOffline`, `enterAuthorizedStudy`, or a submission has already returned `.blocked` or `.unavailable`. The `combine` calls only change the final report; they do not gate execution. Thus a failed pack/entry precondition can still execute selected/free-form submissions and `relaunchWithoutResetAndReconnect`, which may replay real mutations against the host during a run that is known invalid. This breaks the fail-closed physical-proof boundary and risks changing adopter data while no pass can be promoted.

**Fix:** Short-circuit the sequence at each prerequisite failure. Emit blocked/unavailable observations for the unrun remainder, and call study submissions only after authorized entry and offline-audio verification pass. Add a fake adapter test that returns `.blocked` at every step in turn and asserts no subsequent adapter method was invoked.

## Warnings

### WR-01: Malformed report entries can crash the public validator

**File:** `lib/crosswake/proof_lane/physical_iphone_contract.ex:48`

**Issue:** `validate_report/1` immediately calls `Map.get/2` for every list element. A caller passing a non-map entry (for example `[nil]` or `[:bad]`) raises `BadMapError` rather than returning `{:error, "PI-ASSERTIONS-COMPLETE"}`. This contradicts the function’s declared return contract and turns malformed untrusted/integration input into a task crash instead of a stable denial.

**Fix:** Validate that every entry is a map before reading IDs, or pattern-match the map entries in a safe reducer and return the closed error for any other term. Add regression cases for non-map and malformed-map entries.

---

_Reviewed: 2026-08-04T23:46:08Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
