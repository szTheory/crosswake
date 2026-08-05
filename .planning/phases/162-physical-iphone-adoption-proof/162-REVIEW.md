---
phase: 162-physical-iphone-adoption-proof
reviewed: 2026-08-05T02:09:21Z
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
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-05T02:09:21Z
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

The reviewed proof contracts and focused Elixir suite are generally fail-closed for malformed reports and preflight callbacks. However, the proof-verification path fabricates backend authority success, and the generated accessibility contract silently skips its required assertions when no adapter is installed. The recovery-link seam also treats any same-origin URL as validated rather than requiring a host-approved recovery destination.

## Narrative Findings (AI reviewer)

## Blocker Issues

### BL-01: Advisory dual-authority verifier fabricates Phoenix success

**File:** `script/verify_physical_iphone_report_contract.sh:35-38`
**Issue:** The verifier suppresses failures from the only purported Phoenix producer check using `|| true`, then writes a literal all-passed backend report and joins it with the device report. It can therefore emit a passed contract-verification result even when the generated Phoenix authority test is absent, fails, or emits different bytes. This contradicts the phase's required independent authority proof and creates misleading physical-proof evidence for downstream users of the verifier.
**Fix:** Run the rendered/generated Phoenix authority producer, fail on any producer failure, and write its exact stdout to `BACKEND_REPORT_FILE`; remove both `|| true` and the hard-coded JSON. Parse and join those produced bytes unchanged.

## Warnings

### WR-01: Required physical accessibility assertions silently pass without execution

**File:** `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex:99-100`
**Issue:** Each of the three study-status accessibility tests returns successfully when `CROSSWAKE_PROOF_LANE_STUDY_HOST_ADAPTER` is not set (also at lines 123-124 and 149-150). XCTest marks these as passing, so Dynamic Type, focus, announcement, recovery-link, appearance, and motion coverage can disappear without failing the generated proof lane.
**Fix:** Assert that a production status adapter is present for a physical-status run, or make the test target/configuration unavailable and have the host runner reject that unavailable state before it can be counted as proof. Do not use a bare early return for a required assertion.

### WR-02: Same-origin is treated as recovery-destination validation

**File:** `examples/phoenix_host/priv/static/offline_study.js:390-398`
**Issue:** `validatedRecoveryDestination()` accepts any same-origin, same-protocol URL from `body.dataset.recoveryDestination`. That is URL syntax/origin validation, not validation that the destination is a host-approved recovery route. A bad host value can expose the recovery CTA for an unrelated or unsafe GET route, contrary to the bounded host-owned recovery seam.
**Fix:** Have the host provide a closed recovery-route capability (for example, a boolean plus a fixed route ID resolved server-side), or validate against an explicit allowlist of approved recovery paths before rendering the link.

---

_Reviewed: 2026-08-05T02:09:21Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
