---
phase: 162-physical-iphone-adoption-proof
reviewed: 2026-08-04T22:00:17Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - lib/crosswake/proof_lane/physical_iphone_contract.ex
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
  - test/crosswake/proof_lane/physical_iphone_preflight_test.exs
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
  - test/crosswake/proof_lane/template_contract_test.exs
  - examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
  - examples/phoenix_host/priv/static/offline_study.js
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - lib/crosswake/proof_lane/evidence.ex
findings:
  critical: 4
  warning: 0
  info: 0
  total: 4
status: issues_found
---

# Phase 162: Code Review Report

**Reviewed:** 2026-08-04T22:00:17Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The intentional absence of a signed physical iPhone, eligible route inventory, and adopter host was treated as a required blocked state. The submitted implementation nevertheless has no executable path from those prerequisites to a truthful physical run or promotion. Its generated producer/consumer report contracts disagree, and two backend assertions are marked passed without testing the behavior they claim.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Production command cannot run or promote a physical proof

**File:** `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex:7-10,36-40,52-59`

**Issue:** The only production entry point calls `run_with(args, [])`, so it supplies neither the inventory/config/preflight callbacks nor device/backend report providers. Consequently even a fully configured host can only receive `PI-PREFLIGHT-INVENTORY`; there is no host integration seam to execute. More directly, the required Phase 162 command, `--run --promote --json`, is rejected because `:promote` is not an accepted switch, and the task never invokes `Evidence.promote/3`. This prevents the real proof and its atomic publication after external prerequisites become available.

**Fix:** Load a closed host-owned physical-proof configuration in `run/1`, add and require `--promote` with `--run`, wire its callbacks into `PhysicalIphonePreflight.check/1` and the two report producers, then derive the canonical candidate and call `Evidence.promote/3` only after the complete join passes. Add an integration test that exercises the accepted command with a synthetic host configuration and asserts one publication to the fixed destination.

### CR-02: Generated device and Phoenix reports cannot be consumed by the Mix join

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex:74-88`; `priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex:122-124`; `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex:62-93`

**Issue:** The Swift producer emits a report object containing `schema_version`, `device_class`, and assertion objects with only `id` and `outcome`. The generated Phoenix fixture similarly emits assertion objects with only `id` and `outcome`. In contrast, the Mix task accepts only a bare list and requires every entry to carry an `owner`. There is no parser or adapter that validates the producer envelopes and adds/verifies ownership from `PhysicalIphoneContract`. A real generated report therefore fails `report_from/3` or `owned_by?/2` and cannot ever reach a passed join.

**Fix:** Define one canonical serialized report envelope shared by Swift, generated Phoenix, and Elixir. In the Mix task, parse that envelope, verify schema/device class and the exact assertion IDs, derive each owner from `PhysicalIphoneContract` rather than trusting producer-supplied owner values, and reject a producer that includes extra fields. Cover the real serialized Swift and Phoenix fixture outputs in an end-to-end join test.

### CR-03: `PI-REDACTED-PROMOTION` is reported passed without any evidence validation or promotion

**File:** `examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs:32-60`; `priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex:26-32,98-124`

**Issue:** Both the example fixture and generated host test manufacture a passed `PI-REDACTED-PROMOTION` result after replay-only callbacks complete. Neither performs a canonical run-contract scan, evidence build, no-replace promotion, or post-publication check. This lets the backend half of a candidate attest that redacted promotion passed when no physical record exists, contradicting the phase's no-fabrication boundary.

**Fix:** Remove this assertion from the Phoenix authority fixture. Produce it only in the promotion command after `Evidence.build/1`, approved-source verification, `Evidence.promote/3`, and `Evidence.check/2` succeed against the physical destination; alternatively add a dedicated evidence authority callback that performs exactly those operations and returns only a closed result.

### CR-04: The claimed entry-disablement test only tests replay disablement

**File:** `examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs:133-159`

**Issue:** `entry_disablement/0` and `replay_disablement/0` execute the same `SyncController.sync_events/4` call with the same feature-denied option. Both exercise replay admission; neither invokes the route-entry gate. The test then returns passed results for two distinct assertion IDs, leaving a disabled route entry untested and allowing a false DEVICE-05 claim.

**Fix:** Make `entry_disablement/0` invoke the host's actual route-entry/controller or route-policy gate and assert it denies entry while preserving the queued aggregate. Keep `replay_disablement/0` on `SyncController.sync_events/4`, and add a mutation that makes one gate allow while the other denies to prove the assertions are independent.

---

_Reviewed: 2026-08-04T22:00:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
