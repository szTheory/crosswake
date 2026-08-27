---
phase: 162
slug: physical-iphone-adoption-proof
status: gaps_found
nyquist_compliant: true
validated: 2026-08-27
---

# Phase 162 — Superseded Validation Ledger

# Superseded by Plan 162-16 before the corrected-provenance transaction. The prior Plan 14 record
# predates nonce, expected-mutation, and all-exit cleanup provenance fixes and cannot authorize
# support or completion. Deterministic gates below remain useful but do not replace a fresh run.

Plan 14's retained standard production result previously described the device-to-Phoenix value, relaunch,
replay, exactly-one drain, no-replace promotion, and source-bound evidence path. Plan 15 then
passed the current-tree deterministic gates below. This ledger retains aggregate results, stable
identifiers, closed outcomes, reproducible commands, and narrow public scope only.

## Final-Tree Evidence Gates

| Gate | Reproducible command | Aggregate result | Covers |
| --- | --- | --- | --- |
| Retained standard physical behavior | `(cd examples/phoenix_host && MIX_ENV=test mix crosswake.proof_lane.physical_iphone --run --promote --json)` | passed once in Plan 14 after all-ready preflight; signed-device and independent Phoenix producers joined | DEVICE-01–05; T-162-77, T-162-80 |
| Deterministic template and evidence contracts | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs --max-failures 1` | pass: 119 tests, 0 failures | DEVICE-01–07; T-162-77, T-162-79 |
| Production serialization/parser/join regressions | `mix test test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs:40 test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:76 --max-failures 1` | pass: 2 tests, 0 failures; compiled production parser/join accepts the owner-disjoint passed union and rejects wrong-owner, unavailable, malformed, and partial input | DEVICE-06; T-162-80 |
| Phoenix authority and retained recovery | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/physical_iphone_proof_host_test.exs test/crosswake_example/local_first/physical_iphone_authority_test.exs test/crosswake_example/router_test.exs --max-failures 1 && npm test -- --project=chromium e2e/offline_sync.spec.ts --grep "study status retains rejected work")` | pass: 18 ExUnit tests and 1 browser test | DEVICE-02–05; T-162-77, T-162-78 |
| Support-guide parity | `mix run -e 'alias Crosswake.SupportMatrix; alias Crosswake.SupportMatrix.Renderer; true = File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())'` | pass: byte-identical | DEVICE-07; T-162-78 |
| Planning-status parity | `test "$(rg -c "^- \\[x\\] \\*\\*DEVICE-0[1-7]:" .planning/REQUIREMENTS.md)" = "7" && test "$(rg -c "^\\| DEVICE-0[1-7] \\| Phase 162 \\| Complete \\|" .planning/REQUIREMENTS.md)" = "7"` | pass: 7 checkboxes and 7 traceability rows | DEVICE-01–07; T-162-78 |

## Privacy and Scope

- The retained physical record is the exact two-file allowlist with a matching 64-byte completion marker.
- The standard Plan 14 run exercised internal source-bound `Evidence.check/2` using canonical source bytes from that run. `Evidence.check/1` remains intentionally non-passing because it lacks supplied canonical source bytes.
- The deterministic parser/join gate is non-Xcode and production-only; advisory simulator output is not completion authority.
- The support guide remains limited to one first-adopter flow on one iOS runtime line. Android, background replay or sync, generic storage or sync, multiple islands, simulator substitution, and every-iPhone coverage remain non-claims.

## Independent Verification

`162-VERIFICATION.md` is intentionally unchanged. A verifier must independently rerun the repaired final-tree gates; this reconciliation does not self-certify that report.
