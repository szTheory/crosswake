---
phase: 162
slug: physical-iphone-adoption-proof
status: gaps_found
nyquist_compliant: true
superseded: 2026-08-27
---

# Phase 162 — Superseded Validation Ledger

This pre-repair ledger is superseded and does not close Phase 162. Its aggregate successes did not
exercise CR-01 value persistence or CR-02's real serialization parser/join. The repaired
current-tree ledger is required before any completion status can be restored.

## Final-Tree Evidence Gates

| Gate | Reproducible command | Aggregate result | Covers |
| --- | --- | --- | --- |
| Source-bound physical record | `mix run -e 'alias Crosswake.ProofLane.{Evidence, PhysicalIphoneContract}; assertions = PhysicalIphoneContract.assertions() |> Enum.map(fn %{id: id, owner: owner} -> %{"id" => id, "owner" => Atom.to_string(owner), "outcome" => "passed"} end); bytes = Jason.encode!(%{"schema_version" => 1, "device_class" => "physical_iphone", "ios_runtime_line" => "26.6", "outcome" => "passed", "assertions" => assertions}); :ok = Evidence.check(".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone", [%{kind: :physical_iphone_run_contract, canonical_bytes: bytes}]); :ok'` | pass | DEVICE-01–06; T-162-55, T-162-56 |
| Focused proof, renderer, and support contracts | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs --max-failures 1` | pass: 132 tests, 0 failures | DEVICE-01–07; T-162-55, T-162-56 |
| Phoenix authority and recovery | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/physical_iphone_authority_test.exs test/crosswake_example/router_test.exs --max-failures 1 && npm test -- --project=chromium e2e/offline_sync.spec.ts --grep "study status retains rejected work")` | pass: 8 ExUnit tests and 1 browser test | DEVICE-02–05; T-162-55 |
| Support-guide parity | `mix run -e 'alias Crosswake.SupportMatrix; alias Crosswake.SupportMatrix.Renderer; true = File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())'` | pass: byte-identical | DEVICE-07; T-162-57 |
| Planning-status parity | `test "$(rg -c "^- \\[x\\] \\*\\*DEVICE-0[1-7]:" .planning/REQUIREMENTS.md)" = "7" && test "$(rg -c "^\\| DEVICE-0[1-7] \\| Phase 162 \\| Complete \\|" .planning/REQUIREMENTS.md)" = "7"` | pass: 7 checkboxes and 7 traceability rows | DEVICE-01–07; T-162-57 |

## Privacy and Scope

- The evidence-specific canonicalization, digest-marker, regular-file directory allowlist, and source-bound privacy checks passed.
- `Evidence.check/1` remains intentionally non-passing for this approved-hash record because it has no supplied canonical source bytes. The authorized completion authority is `Evidence.check/2`; this ledger does not claim `/1` passed.
- The broad `mix crosswake.adoption_context.scan` remains non-passing because of the marker extension and an unrelated pre-existing binary asset. It is not completion authority and is not represented as a passing privacy gate.
- The checked support guide remains limited to one first-adopter flow on one iOS runtime line. Android, background replay or sync, generic storage or sync, multiple islands, simulator substitution, and every-iPhone coverage remain non-claims.

## Independent Verification

`162-VERIFICATION.md` is intentionally unchanged. A verifier must independently rerun the final-tree evidence and contract gates; this reconciliation does not self-certify that report.
