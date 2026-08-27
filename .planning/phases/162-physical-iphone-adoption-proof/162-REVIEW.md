---
phase: 162-physical-iphone-adoption-proof
reviewed: 2026-08-27T19:09:59Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/lib/crosswake_example/local_first/physical_iphone_authority.ex
  - examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
  - examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneApp.swift
  - examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift
  - examples/phoenix_host/native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift
  - examples/phoenix_host/priv/repo/migrations/20260826190000_add_reference_free_form_answer_to_review_events.exs
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
  - guides/support_matrix.md
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/physical_iphone_contract.ex
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - script/verify_physical_iphone_report_contract.sh
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/physical_iphone_preflight_test.exs
  - test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-27T19:09:59Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The scoped source implements the evidence and physical-device lane, including fail-closed report parsing and payload-redacted evidence. The physical run is nevertheless not provenance-bound to the Phoenix host that the backend producer inspects, so it can publish a physical-iPhone pass for a different server or an earlier replay row.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Physical device proof is not bound to the checked Phoenix replay

**File:** `examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex:181`

**Issue:** Preflight accepts any syntactically valid `http` or `https` host URL. The device adapter then posts the real journal record to that URL ([`ProofLaneDriver.swift:203`](/Users/jon/projects/crosswake/examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift:203)), while the later backend report only looks for any accepted row with the fixed scope ([`physical_iphone_authority.ex:81`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/local_first/physical_iphone_authority.ex:81)). It neither receives the device mutation ID nor requires a per-run nonce. Consequently, a remote/stale host can make the XCUITest pass and an already-present row for the static fixture scope can make the local backend report pass. The resulting joined report and evidence hash attest only to the assertion labels, not that this physical device replay reached the intended Phoenix authority in this run. This violates the lane's claimed replay-authority/provenance boundary and permits a false physical-proof artifact.

**Fix:** Have the local Phoenix proof host mint a single-use, opaque run nonce and expected mutation ID before launching XCTest. Restrict the device URL to that started host (or perform an authenticated local handshake), send the nonce only as an internal request header/body field, and make the sync endpoint persist/return the exact nonce and mutation ID. Pass those opaque values privately to `PhysicalIphoneAuthority.report/2`, require exactly that accepted row and duplicate result, and delete/reset only after it is verified. Keep both values out of the report, logs, and retained evidence.

---

_Reviewed: 2026-08-27T19:09:59Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
