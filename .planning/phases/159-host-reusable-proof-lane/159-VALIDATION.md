---
phase: 159
slug: host-reusable-proof-lane
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-31
validated: 2026-08-01T23:00:00Z
---

# Phase 159 — Validation Strategy

> Fresh final-tree validation after the host-adapter and endpoint-normalization repairs. Native simulator execution is advisory only; it neither promotes nor blocks this phase.

## Fresh Complete Automated Gate

One unchanged post-159-16 tree passed the following deterministic controls on 2026-08-01:

```sh
mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs
mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs
mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs
bash script/verify_phoenix_host_proof_lane.sh
bash -n script/verify_generated_ios_shell.sh script/verify_phoenix_host_proof_lane.sh
mix format --check-formatted lib/crosswake/proof_lane/*.ex test/crosswake/proof_lane/*.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs
```

The focused controls cover both endpoint keys, quote and backslash rejection before output-root creation, valid rerun idempotency, concurrent-winner preservation, an untouched generated lane's stable `blocked` outcome, and the connected adapter fixture's exact XCTest, lifecycle XCUITest, and accessibility-reflow XCUITest evidence. The complete ExUnit set passed across 46 declared tests. The Phoenix-host command type-checked and passed its five-test Playwright corpus with its existing `webServer` as the sole Phoenix lifecycle owner. Shell syntax and formatting passed.

The actual generated iOS proof command was attempted with project-root, xcodebuild, scheme, build, launch, and shim override variables unset. No structured simulator outcome was retained by this automated session, so its closed advisory result is `not_run`; it does not substitute for, block, or promote the deterministic fixture gate under D-14. The deterministic unconnected fixture remains `blocked`, while only the connected adapter-evidence fixture returns `passed`.

Protected before/after SHA-256 values were identical: `.planning/config.json` `de08e6a97eedb77d5b7bb23c1193c1e4aab126508e8cd26ea029e824f3391ab8`; `COVERAGE.md` `812faa33f005443b3c46f7c9fc355e63a3052b05d457c5d780349c81d848a552`.

## Verification Map

| Task ID | Requirement | Boundary | Fresh result |
| --- | --- | --- | --- |
| 159-F-01 | PROOF-01 | Missing-only generation, no-follow traversal, idempotent reruns, and collision preservation | PASS — generator controls and concurrent-winner regression passed. |
| 159-F-02 | PROOF-02 | Closed config, quote/backslash rejection, and pre-write failure | PASS — both endpoint keys reject before filesystem or render activity. |
| 159-F-03 | PROOF-03 | Existing Phoenix browser corpus plus exact generated XCTest/XCUITest adapter evidence | PASS — five browser tests passed; fixture requires all three exact native markers before `passed`. |
| 159-F-04 | PROOF-04 | Typed evidence, final-byte scan, no-replace promotion, and lifecycle-hook failure | PASS — complete evidence suite passed. |
| 159-F-05 | UI backstop | Accessibility-size wrapping, 24px containment, full labels, no horizontal scroll, and 44x44pt retry target | PASS-CONTRACT — repository-controlled template and connected-adapter fixture require the generated XCUITest assertion; native runtime is advisory `not_run`. |

## Scope and Sign-Off

- The deterministic generated-contract fixture is the required completion evidence; native runtime execution is a separately labeled advisory backstop.
- No manual UAT, raw test output, endpoint value, payload, identity, token, media, transcript, trace, screenshot, or xcresult is retained here.
- TODO-002 remains open, adopter-instance completeness remains `unknown_blocking`, Android remains frozen, and Phases 160–162 retain replay/auth, pack/audio, and physical-device ownership.
- `COVERAGE.md` keeps its reasoned no-external-API declaration unchanged.

**Approval:** all required deterministic final-tree controls passed. Phase 159 may be reconciled without widening support or device claims.
