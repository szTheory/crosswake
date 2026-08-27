---
phase: 162-physical-iphone-adoption-proof
reviewed: 2026-08-27T19:27:54Z
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

**Reviewed:** 2026-08-27T19:27:54Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The previous compile blocker is resolved: the Phoenix host compiles and `backend_report/1` now performs cleanup through a valid `try ... after`. The single-use opaque nonce and mutation-ID binding is present from the injected test environment through session claim, replay admission, persisted row matching, and backend verification; wrong/stale rows and wrong host tickets fail closed. Host-only and generated-template contracts remain appropriately separated, and the reviewed report/evidence paths do not serialize the nonce, mutation ID, raw answer, or host endpoint.

One critical lifecycle hole remains. If the device callback returns a malformed report, the task rejects it before calling `backend_report/1`; that callback is the only successful-run cleanup path. The claimed nonce then remains active in ETS and in the task process. This violates the required failure cleanup guarantee, leaves sensitive run state live beyond a failed run, and means CR-01 is not fully resolved.

Verification performed without Xcode, device, readiness, transaction, promotion, or physical host-run commands:

- `mix compile` — passed.
- `mix compile` in `examples/phoenix_host` — passed.
- Root deterministic Phase 162 suite — 80 tests, 0 failures.
- Phoenix-host deterministic authority/proof-host suite — 13 tests, 0 failures.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Malformed device report leaks the claimed proof ticket

**File:** `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex:126-134`

**Issue:** `invoke_runner/2` is a `with`: it calls `backend_report` only after `report_from(options, :device_report, contract)` succeeds. The reference host creates and claims the nonce before its device callback returns, but only `PhysicalIphoneProofHost.backend_report/1` removes it (via its `after` at `examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex:92-102`). A malformed or otherwise unparsable device report returns `{:error, "PI-REPORT-DEVICE"}` at lines 168-185, skips `backend_report/1`, and leaves both the process run and active ETS ticket intact. The ticket is then neither single-run bounded nor reliably cleaned after failure.

**Fix:** Make cleanup an explicit required host callback and execute it in an `after` around the whole device/backend join. The callback must be idempotent and delete both the process run and ETS ticket; add a regression that returns malformed device-report bytes after a claimed ticket and asserts no process run and `active?/2 == false`.

```elixir
defp invoke_runner(contract, options) do
  try do
    with {:ok, device_report} <- report_from(options, :device_report, contract),
         {:ok, backend_report} <- report_from(options, :backend_report, contract),
         {:ok, candidate} <- join_reports(contract, device_report, backend_report),
         {:ok, result} <- promote_if_requested(candidate, options) do
      {:passed, result}
    else
      {:error, rule_id} -> {:blocked, %{outcome: "blocked", rule_id: rule_id}}
    end
  after
    case Keyword.get(options, :cleanup_run) do
      cleanup when is_function(cleanup, 0) -> cleanup.()
      _ -> :ok
    end
  end
end
```

Expose `cleanup_run/0` through `PhysicalIphoneHost.load/0` and implement it in the reference host by deleting the process key and invoking `PhysicalIphoneRunProvenance.cleanup/1`. Keep `backend_report/1` cleanup as a safe idempotent defense-in-depth fallback.

---

_Reviewed: 2026-08-27T19:27:54Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
