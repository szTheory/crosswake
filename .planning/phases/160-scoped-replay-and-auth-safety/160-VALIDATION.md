---
phase: 160
slug: scoped-replay-and-auth-safety
status: validated
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
| **Full phase gate** | Post-160-17 generated-proof-repair current-tree chain |
| **Estimated focused latency** | each focused command targets <30 seconds |
| **Estimated final-gate latency** | ~300 seconds |

## Sampling Rate

- **After every task commit:** Run only that task's focused core, browser, host, Sigra, egress, or evidence command; target feedback is under 30 seconds.
- **Plans 01 through 07:** Focused task checks remain recorded in their summaries and preserve fast feedback.
- **Plan 08 Task 3:** The original complete gate remains recorded as superseded baseline evidence.
- **After final repair:** Run the complete fresh current-tree gate, including warning-clean compilation, core, Sigra, Phoenix, browser, generated-host, asserted non-passing iOS, planning/adoption, formatting, coverage-seal, and whitespace checks.
- **Before `$gsd-verify-work`:** Require the recorded post-160-17 generated-proof-repair gate to be fresh and passing; blocked native/device output remains non-passing.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Target | Status |
|---|---|---|---|---|---|---|---|---|---|
| 160-01-01 | 160-01 | 1 | SCOPE-01 | T-160-01 | Journal and replay contracts require one bounded opaque scope and browser storage addresses only its exact partition | core integration and browser proof | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs && npm --prefix examples/phoenix_host run proof:offline-island -- --grep "exact scope storage"` | retained in current core/browser corpora | ✅ green |
| 160-01-02 | 160-01 | 1 | SCOPE-02 | T-160-02, T-160-06 | Inert launch, fence-first scope changes, stale completion rejection, and ordered retained drain remain closed | core integration and browser proof | `mix test test/crosswake/offline/runtime_test.exs && npm --prefix examples/phoenix_host run proof:offline-island -- --grep "inactive relaunch|switch before send|switch in flight|ordered blocked drain"` | retained in current core/browser corpora | ✅ green |
| 160-02-01 | 160-02 | 2 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-05 | T-160-01, T-160-03, T-160-05 | One scoped browser event crosses current host authority and commits one atomic idempotent effect | browser tracer | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "fully authorized scoped Study event"` | retained in 23-proof corpus | ✅ green |
| 160-02-02 | 160-02 | 2 | SCOPE-02, SCOPE-03 | T-160-03, T-160-05, T-160-06 | Host denials, authority changes, rollback, and retry remain explicit and effect-safe | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 33 tests | ✅ green |
| 160-02-03 | 160-02 | 2 | SCOPE-03, SCOPE-05 | T-160-03 | Sigra projects current backend evidence only to allow or one closed denial | companion unit | `(cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs)` | 15 tests | ✅ green |
| 160-03-01 | 160-03 | 3 | SCOPE-04 | T-160-04 | Telemetry, Logger, and Doctor accept only closed safe projections | egress integration | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | retained in 119-test core corpus | ✅ green |
| 160-03-02 | 160-03 | 3 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Inspection and retained evidence preserve exact safe schemas and content-bound assertion IDs | evidence integration | `mix test test/crosswake/operator_inspection/json_formatter_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | retained in 119-test core corpus | ✅ green |
| 160-03-03 | 160-03 | 3 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Initial complete same-tree gate reconciled all requirements while leaving native prerequisites non-passing | full phase gate | historical command recorded below | superseded by later repair gates | ✅ green (superseded) |
| 160-04-01 | 160-04 | 4 | SCOPE-01 | T-160-01 | Legacy IndexedDB records move to inert quarantine on upgrade | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "legacy upgrade quarantines unscoped work\|legacy quarantine remains inert across relaunch"` | observed in final chain | ✅ green |
| 160-04-02 | 160-04 | 4 | SCOPE-01 | T-160-01 | Recovery needs an exact active scope-plus-epoch lease and preserves other partitions | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "explicit host recovery scopes quarantined work\|wrong scope cannot recover legacy work"` | observed in final chain | ✅ green |
| 160-05-01 | 160-05 | 5 | SCOPE-02 | T-160-02 | Fence-first lifecycle makes stale async completions inert | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "post-response fence blocks old success side effects\|post-response fence blocks old denial status"` | observed in final chain | ✅ green |
| 160-05-02 | 160-05 | 5 | SCOPE-02 | T-160-06 | Halted or malformed batch envelopes retain unaccepted work in a paused state | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "mid-batch disablement retains halted suffix\|malformed halted response fails closed"` | observed in final chain | ✅ green |
| 160-06-01 | 160-06 | 6 | SCOPE-03, SCOPE-05 | T-160-03 | Sigra admits only typed current authority and projects a closed denial | companion unit | `(cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs)` | 15 tests | ✅ green |
| 160-06-02 | 160-06 | 6 | SCOPE-03, SCOPE-05 | T-160-03 | Default Phoenix admission privately builds current typed authority before effects | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 14 tests | ✅ green |
| 160-07-01 | 160-07 | 7 | SCOPE-01, SCOPE-03 | T-160-05 | A legacy accepted effect remains idempotent after scope migration | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/study_test.exs)` | retained in 33-test host corpus | ✅ green |
| 160-07-02 | 160-07 | 7 | SCOPE-01, SCOPE-03 | T-160-05 | Cross-scope and concurrent retries remain closed and atomic | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs)` | retained in 33-test host corpus | ✅ green |
| 160-08-01 | 160-08 | 8 | SCOPE-04 | T-160-04 | Every public SafeObservation projection reconstructs through constructor validation | egress unit | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | 7 tests | ✅ green |
| 160-08-02 | 160-08 | 8 | SCOPE-04 | T-160-04 | Callback, telemetry, Logger, and Doctor run only after typed projection success | egress integration | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | 71 tests | ✅ green |
| 160-08-03 | 160-08 | 8 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Original same-tree chain covers the initial remediation and retained-evidence/proof boundaries | full phase gate | historical command recorded below | superseded by 160-11 | ✅ green (superseded) |
| 160-09-01 | 160-09 | 8 | SCOPE-01 | T-160-01 | Host admission uses the exact bounded opaque scope grammar and denies hostile values before authority callbacks | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 18 tests | ✅ green |
| 160-09-02 | 160-09 | 8 | SCOPE-03 | T-160-05 | Persisted rejected events remain rejected through normal and race recovery, and the controller retains the ordered suffix | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 18 tests | ✅ green |
| 160-10-01 | 160-10 | 8 | SCOPE-02 | T-160-02 | Inactive and fenced online events create no replay work; active listener failures remain contained | full offline-island browser proof | `(cd examples/phoenix_host && npm run proof:offline-island)` | 18 tests | ✅ green |
| 160-11-01 | 160-11 | 8 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Fresh final-tree chain jointly proves the repair regressions and preserved privacy, authority, proof, and formatting contracts | full phase gate | command recorded below | final only | ✅ green |
| 160-12-01 | 160-12 | 9 | SCOPE-03 | T-160-07, T-160-08 | A hostile fourth replay key reaches neither authority callbacks nor persistence; the exact three-key wire still reaches the host chain | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/sync_controller_test.exs)` | 4 tests | ✅ green |
| 160-12-02 | 160-12 | 9 | SCOPE-03 | T-160-07, T-160-08 | Exact-key admission, persistence allowlisting, server-owned accepted status, and retained duplicate/conflict semantics pass on the repaired tree | Phoenix integration and full phase gate | commands recorded below | 21 focused Phoenix tests; complete chain | ✅ green |
| 160-13-01 | 160-13 | 10 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-09, T-160-11, T-160-12, T-160-13 | Online activation dispatches the existing exact-scope lease-guarded worker; stale/fenced work remains inert and observations remain non-echoing | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "online activation replays retained exact-scope work"` | 1 focused browser proof; retained full corpus | ✅ green |
| 160-13-02 | 160-13 | 10 | SCOPE-03 | T-160-10, T-160-12, T-160-13 | Incomplete non-halted acknowledgement blocks before deletion, retains the submitted batch, and uses the existing paused status without hot retry | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "truncated successful acknowledgement fails closed"` | 1 focused browser proof; retained full corpus | ✅ green |
| 160-14-01 | 160-14 | 11 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-05 | T-160-14-01, T-160-14-02 | Both replay aliases require current request-bound host authority before one atomic event can persist | Phoenix request integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_auth_test.exs test/crosswake_example/local_first/sync_controller_test.exs --trace)` | retained in 33-test host corpus | ✅ green |
| 160-14-02 | 160-14 | 11 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-14-02..T-160-14-06 | Logout, account switch, revocation, mismatch, and mid-batch authority changes deny closed before unauthorized persistence | Phoenix request integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 33 tests | ✅ green |
| 160-15-01 | 160-15 | 12 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-15-01..T-160-15-05 | Browser proof obtains only compile-time-confined test authority and exercises real request-bound replay | Phoenix integration and browser proof | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e && npm run proof:offline-island)` | 33 host tests; 23 browser proofs | ✅ green |
| 160-15-02 | 160-15 | 12 | SCOPE-02, SCOPE-04 | T-160-15-03, T-160-15-06 | Immediate-online failure retains exact-scope work, renders paused, and produces no unhandled rejection | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "immediate online submit failure retains queued work without an unhandled rejection"` | retained in 23-proof corpus | ✅ green |
| 160-16-01 | 160-16 | 13 | SCOPE-04 | T-160-16-06 | The test-only digest barrier remains warning-clean and preserves deterministic evidence-race coverage | compilation and ExUnit | `mix compile --force --warnings-as-errors && MIX_ENV=test mix compile --force --warnings-as-errors && mix test test/crosswake/proof_lane/evidence_test.exs` | retained in current complete gate | ✅ green |
| 160-16-02 | 160-16 | 13 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-16-01..T-160-16-05 | One warning-clean tree preserves scoped replay, privacy, Sigra, proof, and inspection contracts | full phase gate | current complete command recorded below | superseded by post-160-17 repair gate | ✅ green (superseded) |
| 160-17-01 | 160-17 | 14 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-17-01, T-160-17-02 | Unscoped legacy bytes remain quarantined and nil-scope history cannot grant scoped acknowledgement | Phoenix integration and browser proof | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs && npm run proof:offline-island -- --grep "unscoped legacy work remains recovery-required across account switch")` | retained in current host/browser corpora | ✅ green |
| 160-17-02 | 160-17 | 14 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-17-03 | One card synchronously owns rating submission across IndexedDB persistence | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "rapid ratings queue one mutation for one card"` | retained in 23-proof corpus | ✅ green |
| 160-17-03 | 160-17 | 14 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-17-04, T-160-17-05 | Complete repaired tree preserves all Phase 160 requirements and explicit non-passing boundaries | full phase gate | post-160-17 generated-proof-repair command recorded below | current final | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [x] Plans 160-01 through 160-07 supplied scoped storage, lifecycle, authority, idempotency, and evidence regressions.
- [x] Plan 160-08 supplied forged-observation projection and every-production-egress regressions.
- [x] Plan 160-08 reran all requirements and high-threat regressions on its final tree; this historical evidence is superseded by Plan 160-11.
- [x] Plan 160-11 reran all requirements and high-threat regressions after Plans 160-09 and 160-10 on one fresh final tree; this evidence is superseded by the post-160-12 gate below.
- [x] Plan 160-12 reran focused hostile-key and persistence defenses plus the complete current-tree chain after closing client-controlled replay status.

## Manual-Only Verifications

All Phase 160 behaviors have automated verification. Host-issued real scope values and adopter route inputs remain external `unknown_blocking` prerequisites and must not be inferred.

## Validation Sign-Off

- [x] Every completed gap task has automated evidence; final Task 160-17-03 owns the current full gate.
- [x] Focused core, browser, host, Sigra, egress, and evidence commands remain automated.
- [x] No watch-mode flags were used.
- [x] The current full-chain command ran after all Plans 160-01 through 160-17 and the generated-proof repair were complete.
- [x] All five requirements and the phase's retained high-threat regressions were exercised on the final same tree.

## Superseded Fresh Same-Tree Gate — 2026-08-02 (pre-160-09/10)

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

**Historical note:** This gate predates the hostile-scope, rejected-row, and inactive-online regressions. It remains an auditable baseline only and cannot close those repairs.

## Superseded Fresh Same-Tree Gate — 2026-08-02 (post-160-09/10)

**Observed command:**

```bash
mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs) && (cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && (ios_output=$(bash script/verify_generated_ios_shell.sh --proof-lane 2>&1); ios_status=$?; test "$ios_status" -eq 2 -o "$ios_status" -eq 3; printf '%s\n' "$ios_output" | grep -Eq '"outcome":"(blocked|unavailable)"') && mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs && mix format --check-formatted examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex examples/phoenix_host/lib/crosswake_example/local_first/study.ex examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs examples/phoenix_host/test/crosswake_example/local_first/study_test.exs examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs
```

**Observed result:** passed. The fresh chain completed with 118 core tests, 15 Sigra contract tests, 18 Phoenix local-first tests (including hostile scope plus normal/race/controller rejected-row cases), 18 browser offline-island proofs (including inactive and fenced online dispatch plus contained active listener failure), one isolated generated Phoenix-host proof, 36 planning/adoption tests, and the six-file scoped formatting check.

**Generated iOS prerequisite:** the proof-lane script returned exit 2 with `{"outcome":"blocked","rule_id":"PL-IOS-TEST-EXECUTION"}`. This is asserted non-passing prerequisite evidence only; it does not promote generated iOS, physical-iPhone, or adopter-instance support.

**Requirement and threat coverage:**

| Requirement / Threat | Fresh observed evidence |
|---|---|
| SCOPE-01 / T-160-01 | Exact host admission grammar, hostile-scope denial, scoped storage, and partition/recovery behavior passed. |
| SCOPE-02 / T-160-02 | The complete browser corpus passed lifecycle fences and the new inactive/fenced online no-op behavior. |
| SCOPE-03 / T-160-03, T-160-05 | Typed Sigra authority and Phoenix accepted/rejected idempotency outcome handling passed, including retained rejected normal/race/controller cases. |
| SCOPE-04 / T-160-04 | Core privacy, evidence, doctor, inspection, and planning/adoption checks passed without recording replay or authority payloads. |
| SCOPE-05 / T-160-03 | Sigra remained a closed backend-authority adapter in the fresh companion and host suites. |
| T-160-06 | Complete browser ordered-drain, retained-suffix, and halted/fail-closed behavior passed. |

**Security status:** blocked pending an independent `$gsd-secure-phase 160` audit. This validation update does not edit or self-approve `160-SECURITY.md`.

**Remaining external prerequisites:** TODO-002; real adopter scope, route, flag, and session inputs; real host adapters; and physical-iPhone evidence remain `unknown_blocking`.

**Approval:** the automated final gate is complete; no manual UAT was used. The fresh code-contract evidence closes the three demonstrated defects, while independent security and external prerequisite status remain non-passing as stated above.

## Fresh Same-Tree Gate — 2026-08-02 (post-160-12)

**Focused observed commands:**

```bash
(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/sync_controller_test.exs)
(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs)
```

**Focused result:** passed. The tracer controller suite ran 4 tests. The combined exact-key admission, persistence allowlist, and controller suite ran 21 tests; hostile status, outcome, authority-shaped, atom-key, and nested extras denied before session resolution, and a direct `Study.apply_one/3` probe persisted only an accepted server-owned row.

**Observed complete command:**

```bash
mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs) && (cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && (ios_output=$(bash script/verify_generated_ios_shell.sh --proof-lane 2>&1); ios_status=$?; test "$ios_status" -eq 2 -o "$ios_status" -eq 3; printf '%s\n' "$ios_output" | grep -Eq '"outcome":"(blocked|unavailable)"') && mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs && mix format --check-formatted examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex examples/phoenix_host/lib/crosswake_example/local_first/study.ex examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs examples/phoenix_host/test/crosswake_example/local_first/study_test.exs examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs
```

**Observed result:** passed. The chain completed with 118 core tests, 15 Sigra contract tests, 21 Phoenix local-first tests, 18 browser offline-island proofs, one generated-host proof, 36 planning/adoption tests, and scoped formatting.

**Requirement and threat coverage:**

| Requirement / Threat | Fresh observed evidence |
| --- | --- |
| SCOPE-03 / T-160-07 | Exact three-string-key replay admission rejects hostile extras before authority callbacks, and persistence reconstructs only approved fields with server-owned accepted status. |
| T-160-08 | Closed denials and validation record only aggregate counts and stable identifiers; hostile replay/auth values are absent. |
| SCOPE-01, SCOPE-02, SCOPE-04, SCOPE-05 / T-160-01..T-160-06 | The complete retained phase chain passed without changing their current contracts. |

**Non-passing boundaries retained:** TODO-002 and adopter-instance completeness remain `unknown_blocking`. Generated iOS/device proof remains an asserted non-passing prerequisite (`blocked` or `unavailable` only), and independent Phase 160 security remains blocked pending `$gsd-secure-phase 160`. This evidence neither edits nor self-approves `160-SECURITY.md`.

## Fresh Same-Tree Gate — 2026-08-02 (post-160-13)

**Focused observed command:**

```bash
cd examples/phoenix_host && npm run proof:offline-island -- --grep "online activation replays retained exact-scope work|truncated successful acknowledgement fails closed"
```

**Focused result:** passed. The two browser regressions prove activation-triggered exact-scope replay and closed incomplete-success handling without recording replay-wire values.

**Observed complete command:**

```bash
mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs) && (cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && (ios_output=$(bash script/verify_generated_ios_shell.sh --proof-lane 2>&1); ios_status=$?; test "$ios_status" -eq 2 -o "$ios_status" -eq 3; printf '%s\n' "$ios_output" | grep -Eq '"outcome":"(blocked|unavailable)"') && mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs && mix format --check-formatted [scoped Phase 160 Phoenix files] && git diff --check -- examples/phoenix_host/priv/static/offline_study.js examples/phoenix_host/e2e/offline_sync.spec.ts .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
```

**Observed result:** passed. The chain completed with 118 core tests, 15 Sigra contract tests, 21 Phoenix local-first tests, 20 browser offline-island proofs, one generated-host proof, asserted blocked-or-unavailable generated iOS prerequisite output, 36 planning/adoption tests, scoped formatting, and whitespace validation.

**Requirement and threat coverage:**

| Requirement / Threat | Fresh observed evidence |
| --- | --- |
| SCOPE-01, SCOPE-02, SCOPE-03 / T-160-09, T-160-11 | Authorized online activation delegates only to the existing current exact-scope lease worker; retained switch and fence proofs passed. |
| SCOPE-03 / T-160-10, T-160-13 | A non-halted success is complete only after full ordered acknowledgement with no rejected results; incomplete success retained the batch in the existing paused state. |
| SCOPE-04 / T-160-12 | Browser, core privacy, evidence, doctor, inspection, and planning checks passed with closed safe observations only. |
| SCOPE-05 | The unchanged Sigra contract remained a closed backend-authority adapter. |

**Executed decision set retained:** D-01 required opaque scope; D-02 one scope-indexed outbox; D-03 inert launch until host activation; D-04 fence-first epoch changes; D-05 mismatches retain work and block; D-06 host-owned account, retention, encryption, cleanup, and recovery policy; D-07 bounded ordered exact-scope drain; D-08 ordered current backend admission; D-09 one-event host transaction and idempotency; D-10 no new application after observed authority change; D-11 closed accepted/rejected/conflict/blocked outcomes; D-12 typed HTTP batch semantics; D-13 host-owned route gate and visible paused state; D-14 existing proof system; D-15 separate sensitive wire and safe observation planes; D-16 closed surface-specific observation vocabulary; D-17 no sensitive or correlating observable values; D-18 narrow per-surface ceilings; D-19 allowlist-first output and final-byte scan; D-20 Sigra as a closed backend-authority adapter; D-21 calm non-echoing learner copy and stable operator rules; D-22 positive and negative egress proof; D-23 existing accessible status model without a new visual system.

**Spec-less probe status:** SCOPE-01 through SCOPE-05 remain unresolved/unclassified by SPEC fallback and are accepted here only through explicit plan truths plus executable code evidence.

**Supersession:** This gate supersedes the post-160-12 gate above while retaining it as historical evidence.

**Non-passing boundaries retained:** TODO-002 and adopter-instance completeness remain `unknown_blocking`. Generated iOS/device proof remains asserted non-passing (`blocked` or `unavailable` only). Independent Phase 160 security remains blocked pending `$gsd-secure-phase 160`; this ledger neither edits nor self-approves `160-SECURITY.md`.

## Fresh Same-Tree Gate — 2026-08-03 (post-160-16)

**Focused observed commands:**

```bash
mix compile --force --warnings-as-errors
MIX_ENV=test mix compile --force --warnings-as-errors
mix test test/crosswake/proof_lane/evidence_test.exs
(cd examples/phoenix_host && MIX_ENV=test mix compile --force --warnings-as-errors)
(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e)
(cd examples/phoenix_host && npm run proof:offline-island)
```

**Focused result:** passed. Warning-as-error compilation completed at the root and Phoenix-host test dependency contexts. The retained evidence race suite passed 22 tests, request-bound host coverage passed 33 tests, and the immediate-online browser corpus passed 22 proofs.

| Task ID | Plan | Requirement | Threat Ref | Secure behavior | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 160-14-01 | 160-14 | SCOPE-03 | T-160-16-01 | Both replay aliases deny missing current request authority before persistence. | Host request suite | ✅ green |
| 160-14-02 | 160-14 | SCOPE-03 | T-160-16-02 | Scope mismatch, account switch, revocation, and production fixture fallback deny closed. | Host request suite and production-tree inspection | ✅ green |
| 160-15-01 | 160-15 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-16-01 | Signed test authority remains compile-time confined and current-session-bound in browser proof. | Host and browser suites | ✅ green |
| 160-15-02 | 160-15 | SCOPE-02 | T-160-16-03 | Immediate-online rejection retains exact-scope work, renders paused, and emits no unhandled browser error. | Offline-island browser corpus | ✅ green |
| 160-16-01 | 160-16 | SCOPE-04 | T-160-16-06 | The private digest barrier is declared only in test compilation and still protects the deterministic digest-bound race. | Warning-as-error compilation and 22-test evidence suite | ✅ green |
| 160-16-02 | 160-16 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-16-01..T-160-16-05 | One warning-clean final tree preserves every scoped replay, privacy, Sigra, proof, and inspection contract. | Complete chain below | ✅ green |

**Observed complete command:**

```bash
mix compile --force --warnings-as-errors && MIX_ENV=test mix compile --force --warnings-as-errors && mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs) && (cd examples/phoenix_host && MIX_ENV=test mix compile --force --warnings-as-errors && MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && (ios_output=$(bash script/verify_generated_ios_shell.sh --proof-lane 2>&1); ios_status=$?; test "$ios_status" -eq 2 -o "$ios_status" -eq 3; printf '%s\n' "$ios_output" | grep -Eq '"outcome":"(blocked|unavailable)"') && mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs && mix format --check-formatted lib/crosswake/proof_lane/evidence.ex test/crosswake/proof_lane/evidence_test.exs examples/phoenix_host/lib/crosswake_example/router.ex examples/phoenix_host/lib/crosswake_example/local_first/replay_auth.ex examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex examples/phoenix_host/lib/crosswake_example/e2e/replay_session_controller.ex examples/phoenix_host/test/crosswake_example/local_first/replay_auth_test.exs examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs examples/phoenix_host/test/crosswake_example/local_first/sync_controller_test.exs test/crosswake/offline/proof_lane_test.exs && git diff --check -- lib/crosswake/proof_lane/evidence.ex test/crosswake/proof_lane/evidence_test.exs test/crosswake/offline/proof_lane_test.exs examples/phoenix_host/lib/crosswake_example/router.ex examples/phoenix_host/lib/crosswake_example/local_first/replay_auth.ex examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex examples/phoenix_host/lib/crosswake_example/e2e/replay_session_controller.ex examples/phoenix_host/config/test.exs examples/phoenix_host/priv/static/offline_study.js examples/phoenix_host/e2e/offline_sync.spec.ts .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
```

**Observed result:** passed. The complete chain ran 119 core tests, 15 Sigra contract tests, 33 Phoenix host tests, 22 offline-island browser proofs, the generated Phoenix-host proof, 36 planning/adoption tests, scoped formatting, and whitespace validation. The generated iOS check emitted only its permitted blocked-or-unavailable prerequisite outcome and remains explicitly non-passing.

**Privacy-safe final inspection:** the required replay aliases use the shared `:replay_api` boundary; production routing contains no synthetic fixture/default allow path; test authority remains within the existing `Mix.env() in [:test, :e2e]` namespace; and the retained evidence schema remains the existing 12-field allowlist. Existing privacy assertions and inspection tests passed with zero protected-output matches recorded. This ledger retains only aggregate counts, stable task/threat/requirement IDs, and closed outcomes.

**Coverage and boundaries:** SCOPE-01 through SCOPE-05 and D-01 through D-23 remain preserved by the current-tree chain. The nine unresolved spec-less probe rows remain unchanged: SCOPE-01 adjacency/empty/ordering; SCOPE-02 unclassified; SCOPE-03 adjacency/empty/ordering; SCOPE-04 unclassified; and SCOPE-05 unclassified. TODO-002 and adopter-instance completeness remain `unknown_blocking`. Generated iOS/device proof remains non-passing, and independent Phase 160 security remains pending `$gsd-secure-phase 160`; this gate neither edits nor self-approves `160-SECURITY.md`.

**Supersession:** This warning-clean gate supersedes the post-160-13 evidence above while retaining all earlier gates as history.

## Fresh Same-Tree Gate — 2026-08-03 (post-160-17)

**Focused observed commands:**

```bash
(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs)
(cd examples/phoenix_host && npm run proof:offline-island -- --grep "unscoped legacy work remains recovery-required across account switch|nil-scope history grants no scoped acknowledgement")
(cd examples/phoenix_host && npm run proof:offline-island -- --grep "rapid ratings queue one mutation for one card|immediate online submit failure retains queued work")
```

**Focused result:** passed. The request/domain suite ran 11 tests. The legacy account-switch browser regression retained one quarantined record with zero records in both scoped partitions and zero replay requests. The rapid-rating and immediate-online failure browser regressions both passed.

| Task ID | Plan | Requirement | Threat Ref | Secure behavior | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 160-17-01 | 160-17 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-17-01, T-160-17-02 | Unscoped browser bytes remain recovery-required; nil-scope history returns closed conflict before accepted/rejected mapping. | Focused ExUnit and browser regressions | ✅ green |
| 160-17-02 | 160-17 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-17-03 | One card submission owns both rating controls before persistence and produces at most one scoped mutation/effect. | Focused browser regressions | ✅ green |
| 160-17-03 | 160-17 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-17-04, T-160-17-05 | Complete current-tree chain preserves closed replay, safe egress, Sigra adapter, proof, and inspection boundaries. | Complete gate below | ✅ green |

**Observed complete command:**

```bash
mix compile --force --warnings-as-errors && MIX_ENV=test mix compile --force --warnings-as-errors && mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs) && (cd examples/phoenix_host && MIX_ENV=test mix compile --force --warnings-as-errors && MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && (ios_output=$(bash script/verify_generated_ios_shell.sh --proof-lane 2>&1); ios_status=$?; test "$ios_status" -eq 2 -o "$ios_status" -eq 3; printf '%s\n' "$ios_output" | grep -Eq '"outcome":"(blocked|unavailable)"') && mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs && mix format --check-formatted examples/phoenix_host/lib/crosswake_example/local_first/study.ex examples/phoenix_host/test/crosswake_example/local_first/study_test.exs && test "$(tr -d '\r\n' < .planning/phases/160-scoped-replay-and-auth-safety/COVERAGE.md)" = "No external API integration: this gap-closure changes existing first-party IndexedDB, Phoenix host, and Playwright/ExUnit seams only; it adds no external API, SDK, or service." && node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/160-scoped-replay-and-auth-safety | grep -Eq '"passed": true' && git diff --check -- examples/phoenix_host/priv/static/offline_study.js examples/phoenix_host/e2e/offline_sync.spec.ts examples/phoenix_host/lib/crosswake_example/local_first/study.ex examples/phoenix_host/test/crosswake_example/local_first/study_test.exs .planning/phases/160-scoped-replay-and-auth-safety/COVERAGE.md .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
```

**Observed result:** passed. The chain completed with warning-as-error root and Phoenix-host compilation, 119 core tests, 15 Sigra contract tests, 33 Phoenix host tests, 23 browser offline-island proofs, the generated Phoenix-host proof, 36 planning/adoption tests, scoped formatting, the exact no-external-API coverage declaration, a passing coverage seal gate, and whitespace validation.

**Requirement and threat coverage:** SCOPE-01 and SCOPE-02 now include the closed legacy-quarantine and nil-scope-history paths; SCOPE-03 retains current per-event admission and accepted-only deletion; SCOPE-04 retains safe output and aggregate-only evidence; SCOPE-05 retains Sigra as the closed backend-authority adapter. D-01 through D-23 remain preserved. All five unresolved spec-probe rows remain unclassified; no missing semantics were inferred.

**Non-passing boundaries retained:** TODO-002 and adopter-instance completeness remain `unknown_blocking`. Generated iOS/device proof remains asserted non-passing (`blocked` or `unavailable` only), and independent Phase 160 security remains pending `$gsd-secure-phase 160`; this gate neither edits nor self-approves `160-SECURITY.md`.

**Supersession:** This fresh complete gate supersedes the post-160-16 gate above while retaining all earlier evidence as history.

## Fresh Same-Tree Gate — 2026-08-03 (post-160-17 generated-proof repair)

**Focused observed commands:**

```bash
(cd examples/phoenix_host && npm run proof:offline-island -- --grep "drives one UI mutation through IndexedDB, application reconnect, and exactly-once Phoenix replay")
bash script/verify_phoenix_host_proof_lane.sh
```

**Focused result:** passed. The repository-host generated proof and isolated generated-host proof each completed one browser proof after the host test adapter established the existing request-bound test session before replay.

**Observed complete command:** the established post-160-17 complete same-tree gate (root and host warning-as-error compilation; core, Sigra, host, browser, generated-host, planning/adoption, formatting, coverage seal, whitespace, and asserted blocked-or-unavailable generated-iOS prerequisite checks).

**Observed result:** passed. The complete chain ran 119 core tests, 15 Sigra contract tests, 33 Phoenix host tests, 23 browser offline-island proofs, one isolated generated Phoenix-host proof, 36 planning/adoption tests, scoped formatting, the coverage seal, and whitespace validation.

**Repair and boundaries:** the generated proof adapter now uses only the existing test-only replay-session seam to obtain request-bound authority; production authority, transport shape, storage behavior, Android posture, safe output schemas, and non-passing generated-iOS/device boundaries remain unchanged. The activation replay assertion now begins capture after the unrelated page-reload teardown, preserving its replay-specific error check without accepting unrelated LiveView shutdown output.

**Supersession:** This gate supersedes the earlier post-160-17 evidence above while retaining it as history. TODO-002/adopter-instance completeness remains `unknown_blocking`; generated iOS/device proof remains non-passing; independent Phase 160 security remains pending `$gsd-secure-phase 160`.

## Validation Audit 2026-08-03

| Metric | Count |
| --- | ---: |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

The Nyquist audit mapped all 17 plans and their 36 automated tasks to existing ExUnit, Playwright, compilation, proof-lane, privacy, formatting, and coverage-seal checks. A fresh post-160-17 generated-proof-repair same-tree gate passed with 119 core tests, 15 Sigra contract tests, 33 Phoenix host tests, 23 browser proofs, one isolated generated-host proof, and 36 planning/adoption tests. No test file was generated because every Phase 160 requirement already had targeted, runnable, green coverage.
