---
phase: 162-physical-iphone-adoption-proof
reviewed: 2026-08-26T00:00:00Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
  - examples/phoenix_host/native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj
  - examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneApp.swift
  - examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift
  - examples/phoenix_host/native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
  - guides/support_matrix.md
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/physical_iphone_contract.ex
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-26T00:00:00Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The phase has strong closed-envelope and redaction checks, but its device evidence currently overstates what the iOS app proves. Two blockers remain: the physical UI flow discards free-form content while marking it persisted, and the advisory serialization script cannot successfully join the actual generated simulator report it invokes.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Physical proof marks discarded free-form input as persisted

**File:** `/Users/jon/projects/crosswake/examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneApp.swift:108-117`, `/Users/jon/projects/crosswake/examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift:301-305`, `/Users/jon/projects/crosswake/examples/phoenix_host/native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift:68-95`

**Issue:** The UI accepts text in `freeFormDraft`, but invokes an adapter method with no content argument. The adapter only writes a boolean `free_form` marker, and relaunch checks only that marker. Thus the test can enter any text, discard it immediately, relaunch, and still emit `PI-OFFLINE-FREE-FORM-PERSISTENCE` and `PI-RELAUNCH-PERSISTENCE` as passed. The retained evidence and support matrix then represent this as a physical offline-study flow, even though the sensitive mutation value itself was never persisted or rehydrated.

**Fix:** Pass the draft to a host-owned local journal method, persist it inside the scope-partitioned offline store, and after relaunch verify the saved value (or a locally computed, test-only integrity marker) is recoverable before reporting success. Keep the value and any derived marker out of the XCTest attachment, stdout, evidence JSON, telemetry, and diagnostics.

### CR-02: Serialization verifier always joins a non-passing simulator device report

**File:** `/Users/jon/projects/crosswake/script/verify_physical_iphone_report_contract.sh:27-29,53-58`, `/Users/jon/projects/crosswake/priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex:75-80`, `/Users/jon/projects/crosswake/priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:101-105,167-169`

**Issue:** The script runs `testPhysicalContractModeEmitsOwnerFreeReport` on a simulator. That test calls `PhysicalIphoneSequence.run(adapter: nil)`; the generated factory always returns `nil`, so every device assertion is `unavailable`. The script then calls `join_report_entries/2`, which accepts only the exact all-`passed` device assertion list. Consequently, with the real generated project the final `{:ok, _}` match fails and the script cannot emit its success result. Its ExUnit coverage masks this by replacing both `xcodebuild` and `mix` with shell stubs, rather than executing the join semantics.

**Fix:** Keep this lane serialization-only: parse and validate the owner-free simulator envelope without joining it as a passed physical run. Alternatively, provide a deliberately bounded contract-test adapter that emits the required passed shape exclusively for serialization tests, with an explicit assertion that it cannot be used by the physical runner. Add an integration test using the real Elixir join function so the script’s advertised success path is executable.

---

_Reviewed: 2026-08-26T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

