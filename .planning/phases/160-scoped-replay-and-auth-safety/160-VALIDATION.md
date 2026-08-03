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
| **Full phase gate** | Plan 160-11 Task 1 current-tree chain after Plans 160-09 and 160-10 |
| **Estimated focused latency** | each focused command targets <30 seconds |
| **Estimated final-gate latency** | ~300 seconds |

## Sampling Rate

- **After every task commit:** Run only that task's focused core, browser, host, Sigra, egress, or evidence command; target feedback is under 30 seconds.
- **Plans 01 through 07:** Focused task checks remain recorded in their summaries and preserve fast feedback.
- **Plan 08 Task 3:** The original complete gate remains recorded as superseded baseline evidence.
- **Plan 11 Task 1 only:** Run the complete fresh current-tree gate after Plans 160-09 and 160-10, including core, Sigra, Phoenix, browser, generated-host, asserted non-passing iOS, planning/adoption, and formatting checks.
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
| 160-08-03 | 160-08 | 8 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Original same-tree chain covers the initial remediation and retained-evidence/proof boundaries | full phase gate | historical command recorded below | superseded by 160-11 | ✅ green (superseded) |
| 160-09-01 | 160-09 | 8 | SCOPE-01 | T-160-01 | Host admission uses the exact bounded opaque scope grammar and denies hostile values before authority callbacks | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 18 tests | ✅ green |
| 160-09-02 | 160-09 | 8 | SCOPE-03 | T-160-05 | Persisted rejected events remain rejected through normal and race recovery, and the controller retains the ordered suffix | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first)` | 18 tests | ✅ green |
| 160-10-01 | 160-10 | 8 | SCOPE-02 | T-160-02 | Inactive and fenced online events create no replay work; active listener failures remain contained | full offline-island browser proof | `(cd examples/phoenix_host && npm run proof:offline-island)` | 18 tests | ✅ green |
| 160-11-01 | 160-11 | 8 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Fresh final-tree chain jointly proves the repair regressions and preserved privacy, authority, proof, and formatting contracts | full phase gate | command recorded below | final only | ✅ green |
| 160-12-01 | 160-12 | 9 | SCOPE-03 | T-160-07, T-160-08 | A hostile fourth replay key reaches neither authority callbacks nor persistence; the exact three-key wire still reaches the host chain | Phoenix integration | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/sync_controller_test.exs)` | 4 tests | ✅ green |
| 160-12-02 | 160-12 | 9 | SCOPE-03 | T-160-07, T-160-08 | Exact-key admission, persistence allowlisting, server-owned accepted status, and retained duplicate/conflict semantics pass on the repaired tree | Phoenix integration and full phase gate | commands recorded below | 21 focused Phoenix tests; complete chain | ✅ green |
| 160-13-01 | 160-13 | 10 | SCOPE-01, SCOPE-02, SCOPE-03 | T-160-09, T-160-11, T-160-12, T-160-13 | Online activation dispatches the existing exact-scope lease-guarded worker; stale/fenced work remains inert and observations remain non-echoing | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "online activation replays retained exact-scope work"` | 1 focused browser proof; retained full corpus | ✅ green |
| 160-13-02 | 160-13 | 10 | SCOPE-03 | T-160-10, T-160-12, T-160-13 | Incomplete non-halted acknowledgement blocks before deletion, retains the submitted batch, and uses the existing paused status without hot retry | browser proof | `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "truncated successful acknowledgement fails closed"` | 1 focused browser proof; retained full corpus | ✅ green |

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

- [x] Every completed gap task has automated evidence; final Task 160-11-01 owns the current full gate.
- [x] Focused core, browser, host, Sigra, egress, and evidence commands remain automated.
- [x] No watch-mode flags were used.
- [x] The current full-chain command ran only after Plans 160-09 and 160-10 were complete.
- [x] Five requirements and six high-threat regressions were exercised on the final same tree.

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
