---
phase: 160
slug: scoped-replay-and-auth-safety
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-02
---

# Phase 160 — Validation Strategy

> Focused per-task feedback stays separate from the one approximately 300-second final same-tree gate.

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit; Playwright 1.60.0 |
| **Config file** | `mix.exs`; `examples/phoenix_host/playwright.config.ts` |
| **Focused core command** | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs` |
| **Focused browser command** | `cd examples/phoenix_host && npm run proof:offline-island -- --grep "fully authorized scoped Study event"` |
| **Focused host command** | `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/sync_controller_test.exs test/crosswake_example/local_first/study_test.exs` |
| **Focused Sigra command** | `cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs` |
| **Focused egress command** | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` |
| **Full phase gate** | Plan 160-03 Task 3 command only |
| **Estimated focused latency** | each focused command targets <30 seconds |
| **Estimated final-gate latency** | ~300 seconds |

## Sampling Rate

- **After every task commit:** Run only that task's focused core, browser, host, Sigra, egress, or evidence command; target feedback is under 30 seconds.
- **After Plans 01 and 02:** Do not substitute the full repository/proof chain for focused feedback. Their summaries record their task commands.
- **Plan 03 Task 3 only:** Run the approximately 300-second full current-tree gate, including generated host/iOS proof and final evidence scanning.
- **Before `$gsd-verify-work`:** Require the recorded Plan 03 Task 3 gate to be fresh and passing; blocked native/device output remains non-passing.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Target | Status |
|---|---|---|---|---|---|---|---|---|---|
| 160-01-01 | 160-01 | 1 | SCOPE-01 | T-160-01 | Entry/Request scope is required and browser storage has exact-scope compound access only | core unit | focused core suite | <30s | ✅ green |
| 160-01-02 | 160-01 | 1 | SCOPE-01, SCOPE-02 | T-160-01, T-160-02, T-160-06 | Relaunch is inert, switch fences first, stale completion is inert, and blocked work remains | core + focused browser | `mix test test/crosswake/offline/runtime_test.exs && (cd examples/phoenix_host && npm run proof:offline-island -- --grep "inactive relaunch\|switch before send\|switch in flight\|ordered blocked drain")` | <30s | ⬜ pending |
| 160-02-01 | 160-02 | 2 | SCOPE-01, SCOPE-03, SCOPE-05 | T-160-01, T-160-03, T-160-05 | One Study event crosses complete current admission and one atomic transaction | focused browser tracer | `cd examples/phoenix_host && npm run proof:offline-island -- --grep "fully authorized scoped Study event"` | <30s | ⬜ pending |
| 160-02-02 | 160-02 | 2 | SCOPE-02, SCOPE-03 | T-160-03, T-160-05, T-160-06 | Every denial, Nth-event change, rollback, duplicate, and lost response remains closed and idempotent | Phoenix integration | `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/sync_controller_test.exs test/crosswake_example/local_first/study_test.exs` | <30s | ⬜ pending |
| 160-02-03 | 160-02 | 2 | SCOPE-05 | T-160-03, T-160-04 | Sigra projects backend evidence to closed allow/deny and leaks no authority detail | companion unit | `cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs` | <30s | ⬜ pending |
| 160-03-01 | 160-03 | 3 | SCOPE-04 | T-160-04 | SafeObservation reaches Offline.Telemetry, root Logger, and doctor through exact surface projections; final bytes exclude every D-17 class | egress unit/property-style | focused egress suite | <30s | ✅ green |
| 160-03-02 | 160-03 | 3 | SCOPE-04 | T-160-01..T-160-06 | Inspection and Evidence retain exact schemas, content-bound IDs, and forbidden-byte scanning | evidence unit/property-style | focused evidence suite | <30s | ✅ green |
| 160-03-03 | 160-03 | 3 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | One fresh current-tree gate covers every requirement, ASVS mapping, proof seam, and final retained byte | full phase gate | current-tree chain: 113 core, 13 Sigra, 8 Phoenix, 10 Playwright, host proof, asserted blocked iOS, 36 privacy/adoption tests, scoped format | ~300s; final only | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] Plan 160-01 creates scope-required core tests and exact-scope lifecycle/race/retention browser cases before implementation.
- [ ] Plan 160-02 creates the complete host tracer, every admission/rollback/retry case, and Sigra closed-projection tests before implementation.
- [ ] Plan 160-03 creates SafeObservation, root Logger/doctor production-wiring tests, and the every-egress D-17 byte matrix before implementation.
- [ ] Plan 160-03 extends the existing Phase 159 evidence vocabulary with named closed IDs while preserving exact schema and native non-passing behavior.

## Manual-Only Verifications

All Phase 160 behaviors have automated verification. Host-issued real scope values and adopter route inputs remain external `unknown_blocking` prerequisites and must not be inferred.

## Validation Sign-Off

- [ ] Every task has one automated focused command, except final Task 160-03-03 which owns the full gate
- [ ] Focused core, browser, host, Sigra, egress, and evidence commands target <30-second feedback
- [ ] No watch-mode flags
- [ ] The approximately 300-second command appears only as the final phase gate
- [ ] Five flagged assumptions and seven prohibitions remain represented across the three plans
- [ ] `nyquist_compliant: true` set only after all planned tests exist and pass

**Observed final gate:** 2026-08-02 — passed. Generated iOS proof reported `blocked` with `PL-IOS-TEST-EXECUTION`; this is the expected non-passing prerequisite and does not promote device support.

**Remaining external prerequisites:** TODO-002, real scope/route/flag/session input, real host adapters, and physical-iPhone evidence remain `unknown_blocking`.

**Approval:** automated evidence complete; no human UAT required.
