---
phase: 159
slug: host-reusable-proof-lane
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-31
validated: 2026-08-01T23:09:10Z
---

# Phase 159 — Validation Strategy

> Fresh same-tree validation after the generated Phoenix proof and endpoint-normalization repairs. Native accessibility-size execution remains advisory; it neither promotes nor blocks this phase.

## Fresh Complete Automated Gate

One unchanged post-159-18/post-159-19 tree passed the required deterministic gate on 2026-08-01:

```sh
mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs
npm --prefix examples/phoenix_host run typecheck:offline-route-proof
bash script/verify_phoenix_host_proof_lane.sh
bash -n script/verify_generated_ios_shell.sh script/verify_phoenix_host_proof_lane.sh
mix format --check-formatted lib/crosswake/proof_lane/*.ex test/crosswake/proof_lane/*.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs
```

The ExUnit controls cover direct, application, selected-config, render, and pre-write rejection of exactly one backslash in both endpoint keys, with stable non-echoing `PL-CONFIG-VALUE` failures. They also cover valid rerun and concurrent-winner behavior, generated target truth, exact adapter-backed XCTest/XCUITest evidence, the UI contract (wrapped full labels within 24pt insets; no clipping, ellipsis, or horizontal scroll; 44x44pt retry target), and typed final-byte evidence safety.

The explicit TypeScript project passed. The Phoenix-host wrapper executed the existing primary browser corpus and the generated host proof, including real backend confirmation, empty-outbox, and duplicate-idempotency assertions; the generated member is selected and typechecked with the corpus. Shell syntax and formatting passed.

No actual native accessibility-size runtime was available in this run. Its closed advisory result is `not_run`; repository-controlled deterministic contract controls remain the required evidence under D-14.

Protected before/after SHA-256 values were identical: `.planning/config.json` `de08e6a97eedb77d5b7bb23c1193c1e4aab126508e8cd26ea029e824f3391ab8`; `COVERAGE.md` `812faa33f005443b3c46f7c9fc355e63a3052b05d457c5d780349c81d848a552`.

## Verification Map

| Task ID | Requirement | Boundary | Fresh result |
| --- | --- | --- | --- |
| 159-F-01 | PROOF-01 | Missing-only generation, no-follow traversal, idempotent reruns, collision preservation, and generated browser-member execution | PASS |
| 159-F-02 | PROOF-02 | Closed config plus one-backslash rejection before render or filesystem authority at every config seam | PASS |
| 159-F-03 | PROOF-03 | Primary Phoenix browser corpus plus real generated host backend/outbox/duplicate proof and exact native fixture contract | PASS |
| 159-F-04 | PROOF-04 | Typed allowlist, final-byte scan, no-replace promotion, and lifecycle-hook failure | PASS |
| 159-F-05 | UI contract | 24pt containment, full wrapped labels, no horizontal scroll, and 44x44pt retry target | PASS-CONTRACT; runtime advisory `not_run` |

## Scope and Sign-Off

- Both reproduced gaps are closed from fresh same-tree evidence; no status is inferred from prior summaries.
- No raw tool output, endpoint value, payload, identity, token, media, transcript, trace, screenshot, or xcresult is retained.
- TODO-002 remains open and adopter-instance completeness remains `unknown_blocking`; Android remains frozen; Phases 160–162 retain replay/auth, pack/audio, and physical-device authority.
- `COVERAGE.md` retains its no-external-API declaration unchanged.

**Approval:** all required deterministic controls passed. Phase 159 is complete without widening support or device claims.
