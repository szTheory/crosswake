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
| **Full phase gate** | Plan 160-08 Task 3 current-tree chain |
| **Estimated focused latency** | each focused command targets <30 seconds |
| **Estimated final-gate latency** | ~300 seconds |

## Sampling Rate

- **After every task commit:** Run only that task's focused core, browser, host, Sigra, egress, or evidence command; target feedback is under 30 seconds.
- **Plans 01 through 07:** Focused task checks remain recorded in their summaries and preserve fast feedback.
- **Plan 08 Task 3 only:** Run the complete fresh current-tree gate after all gap fixes, including core, Sigra, Phoenix, browser, generated-host, asserted non-passing iOS, planning/adoption, and formatting checks.
- **Before `$gsd-verify-work`:** Require the recorded Plan 08 Task 3 gate to be fresh and passing; blocked native/device output remains non-passing.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Target | Status |
|---|---|---|---|---|---|---|---|---|---|
| 160-04-01 | 160-04 | 4 | SCOPE-01 | T-160-01 | Legacy IndexedDB records move to inert quarantine on upgrade | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "legacy upgrade quarantines unscoped work\|legacy quarantine remains inert across relaunch"` | observed in final chain | ✅ green |
| 160-04-02 | 160-04 | 4 | SCOPE-01 | T-160-01 | Recovery needs an exact active scope-plus-epoch lease and preserves other partitions | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "explicit host recovery scopes quarantined work\|wrong scope cannot recover legacy work"` | observed in final chain | ✅ green |
| 160-05-01 | 160-05 | 5 | SCOPE-02 | T-160-02 | Fence-first lifecycle makes stale async completions inert | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "post-response fence blocks old success side effects\|post-response fence blocks old denial status"` | observed in final chain | ✅ green |
| 160-05-02 | 160-05 | 5 | SCOPE-02 | T-160-06 | Halted or malformed batch envelopes retain unaccepted work in a paused state | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "mid-batch disablement retains halted suffix\|malformed halted response fails closed"` | observed in final chain | ✅ green |
| 160-06-01 | 160-06 | 6 | SCOPE-03, SCOPE-05 | T-160-03 | Sigra admits only typed current authority and projects a closed denial | companion unit | `(cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs)` | 15 tests | ✅ green |
| 160-06-02 | 160-06 | 6 | SCOPE-03, SCOPE-05 | T-160-03 | Default Phoenix admission privately builds current typed authority before effects | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 14 tests | ✅ green |
| 160-07-01 | 160-07 | 7 | SCOPE-01, SCOPE-03 | T-160-05 | Legacy and scoped idempotency remain atomic and globally safe under retry | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 14 tests | ✅ green |
| 160-08-01 | 160-08 | 8 | SCOPE-04 | T-160-04 | Every public SafeObservation projection reconstructs through constructor validation | egress unit | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | 7 tests | ✅ green |
| 160-08-02 | 160-08 | 8 | SCOPE-04 | T-160-04 | Callback, telemetry, Logger, and Doctor run only after typed projection success | egress integration | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | 71 tests | ✅ green |
| 160-08-03 | 160-08 | 8 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | One fresh final same-tree chain covers every gap remediation and the retained-evidence/proof boundaries | full phase gate | command recorded below | final only | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] Plans 160-01 through 160-07 supplied scoped storage, lifecycle, authority, idempotency, and evidence regressions.
- [x] Plan 160-08 supplied forged-observation projection and every-production-egress regressions.
- [x] Plan 160-08 reran all requirements and high-threat regressions on the final same tree.

## Manual-Only Verifications

All Phase 160 behaviors have automated verification. Host-issued real scope values and adopter route inputs remain external `unknown_blocking` prerequisites and must not be inferred.

## Validation Sign-Off

- [x] Every completed gap task has automated evidence; final Task 160-08-03 owns the full gate.
- [x] Focused core, browser, host, Sigra, egress, and evidence commands remain automated.
- [x] No watch-mode flags were used.
- [x] The full-chain command ran only after Plans 160-04 through 160-08 were complete.
- [x] Five requirements and six high-threat regressions were exercised on the final same tree.

## Fresh Same-Tree Gate — 2026-08-02

**Observed command:**

```bash
mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs) && (cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && (ios_output=$(bash script/verify_generated_ios_shell.sh --proof-lane 2>&1); ios_status=$?; test "$ios_status" -eq 2 -o "$ios_status" -eq 3; printf '%s\n' "$ios_output" | grep -Eq '"outcome":"(blocked|unavailable)"') && mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs && mix format --check-formatted [listed Phase 160 files]
```

**Observed result:** passed. The chain completed with 118 core tests, 15 Sigra contract tests, 14 Phoenix local-first tests, 16 browser offline-island proofs, one isolated generated Phoenix-host proof, 36 planning/adoption tests, and the scoped formatting check.

**Requirement and threat coverage:**

| Requirement / Threat | Final observed evidence |
|---|---|
| SCOPE-01 / T-160-01 | Legacy quarantine/recovery and scoped/idempotent Phoenix/browser coverage passed. |
| SCOPE-02 / T-160-02, T-160-06 | Lifecycle fence, stale-completion, halted-suffix, and malformed-envelope browser cases passed. |
| SCOPE-03 / T-160-03 | Typed Sigra contracts and Phoenix current-authority admission passed. |
| SCOPE-04 / T-160-04 | Forged SafeObservation projections and all named production egresses returned closed results with zero egress. |
| SCOPE-05 / T-160-03 | Sigra's companion contract remained a closed backend-authority adapter. |
| T-160-05 | Legacy, same-scope, cross-scope, rollback, and concurrent retry idempotency cases passed in the Phoenix suite. |

**Generated iOS prerequisite:** the proof-lane script returned a permitted nonzero prerequisite outcome (`blocked` or `unavailable`) containing the required JSON outcome marker. This is explicitly non-passing and does not promote generated iOS, physical-iPhone, or adopter-instance support.

**Security status:** blocked pending an independent `$gsd-secure-phase 160` audit. This validation update does not edit or self-approve `160-SECURITY.md`.

**Remaining external prerequisites:** TODO-002, real adopter scope/route/flag/session inputs, real host adapters, and physical-iPhone evidence remain `unknown_blocking`.

**Approval:** the automated final gate is complete; no manual UAT was used. Phase/security completion remains blocked as stated above.
