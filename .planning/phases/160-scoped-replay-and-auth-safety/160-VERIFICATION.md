---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-02T18:14:00Z
status: gaps_found
score: 0/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Opaque scope-partitioned outboxes retain and recover queued work safely across upgrade."
    status: failed
    reason: "The IndexedDB v3 upgrade creates scoped_mutations but neither reads nor quarantines the legacy mutations store, making existing queued work permanently unreachable."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "initDB/1 has no legacy-store migration, quarantine, or visible recovery path."
    missing:
      - "An upgrade fixture from the legacy store and an explicit non-assigning migration/quarantine/recovery flow."
  - truth: "Account transition fencing prevents an old epoch from mutating the current UI."
    status: failed
    reason: "flushOutbox checks the lease once after response parsing, then awaits deletion/count operations and updates shared status without rechecking it."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "Lines 307-329 permit a fenced old flush to overwrite status for a newly activated scope."
    missing:
      - "Lease checks before every post-await storage/UI side effect and regression cases for delayed success and non-OK responses."
  - truth: "Every event is reauthorized against the current backend session, route, feature, Sigra, and host domain before effect."
    status: failed
    reason: "The default production Sigra branch evaluates nil route and nil authority input; direct execution returns :allow."
    artifacts:
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex"
        issue: "sigra_allows?/3 calls evaluate_auth(nil, nil, []) rather than evaluating resolved route/session."
    missing:
      - "Fail-closed construction of real Sigra RouteEntry/AuthContext plus a default-path denial integration test."
  - truth: "Accepted retries remain idempotent across the scope migration."
    status: failed
    reason: "Existing review_events receive NULL scope_ref while the global unique index is dropped; scoped lookup cannot find a legacy row and can apply its mutation again."
    artifacts:
      - path: "examples/phoenix_host/priv/repo/migrations/20260802160000_scope_review_events.exs"
        issue: "Nullable scope_ref and scoped-only unique index replace the only legacy idempotency guard without backfill or quarantine."
    missing:
      - "Authoritative backfill plus NOT NULL scoped uniqueness, or a retained global guard/quarantine, with an old-row duplicate regression."
  - truth: "Raw answers and other sensitive values cannot reach telemetry, Logger, doctor, inspection, aggregates, or evidence."
    status: failed
    reason: "Public SafeObservation structs can be directly constructed and every projection/egress trusts the struct without revalidation."
    artifacts:
      - path: "lib/crosswake/offline/safe_observation.ex"
        issue: "to_telemetry/1 and to_doctor/1 directly copy fields from any %SafeObservation{} value."
      - path: "lib/crosswake/telemetry.ex"
        issue: "emit_safe_observation/1 sends the unvalidated telemetry projection to the root telemetry/default Logger path."
    missing:
      - "Boundary revalidation or an opaque validated type, plus forged-struct canary tests for all projections and Logger bytes."
  - truth: "A disabled replay path retains queued work and visibly fails closed rather than presenting progress."
    status: failed
    reason: "The browser ignores SyncController's halted field on a 200 partial batch and renders normal Synced status while the blocked current/later records remain queued."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "flushOutbox reads accepted_records/rejected only; it never handles data.data.halted before rendering Synced."
    missing:
      - "Closed halted/blocked UI handling that retains queue, pauses drain, and tests a mid-batch feature-disable response."
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement for one scoped replay flow.
**Verified:** 2026-08-02T18:14:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is **not achieved**. The planned suites pass, but they do not exercise the unsafe default admission branch, direct SafeObservation construction, legacy IndexedDB/SQL upgrades, or the post-await epoch/UI race. These are observable implementation failures, not external adopter prerequisites.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Every retained outbox record is scope-partitioned and recoverable without cross-account assignment. | ✗ FAILED | `offline_study.js:122-133` adds `scoped_mutations` but never reads, migrates, or quarantines the legacy `mutations` store. A v1 queued record is silently stranded after the v3 upgrade. |
| 2 | A logout/switch epoch prevents stale work from affecting a new scope's UI or storage. | ✗ FAILED | `offline_study.js:307-329` performs awaits and status mutations after its sole `leaseIsCurrent` check. The focused switch test passes but fences before response completion, not after that check. |
| 3 | Each event uses current session, scope, route, feature, Sigra, and host-domain authority before mutation. | ✗ FAILED | `replay_admission.ex:116` calls Sigra with `(nil, nil, [])`; `MIX_ENV=test mix run` returned `decision: :allow` for that exact default call. |
| 4 | Idempotency survives scope introduction and cannot repeat a legacy domain effect. | ✗ FAILED | The migration adds nullable `scope_ref`, drops global uniqueness, then creates nullable scoped uniqueness. `Study.apply_one/3` queries only the scoped pair. |
| 5 | Operational and retained egress accept only validated safe projections. | ✗ FAILED | Direct execution constructed `%SafeObservation{route_id: "scope-canary", ...}` and `to_telemetry/1` returned it (`forged_route_reaches_projection: true`). Root telemetry accepts this projection. |
| 6 | `crosswake_sigra` is a backend-authority adapter rather than a permissive tokenless gate. | ✗ FAILED | Although `Sigra.replay_decision/3` itself is closed when called correctly, the only default host integration bypasses resolved route/session evidence and permits nil inputs. |
| 7 | Server-side disablement preserves work and visibly presents blocked state. | ✗ FAILED | `SyncController` emits partial-batch `halted`; browser `flushOutbox` ignores it and can render `Synced … queued …` for retained disabled work. |

**Score:** 0/7 truths verified.

## Requirements Coverage

Every requirement declared by the three PLAN frontmatters was found in `.planning/REQUIREMENTS.md`; there are no orphaned Phase 160 requirement IDs. All are blocked by current code evidence.

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SCOPE-01 | 160-01, 160-02, 160-03 | Opaque scope envelopes and partitioned outbox | ✗ BLOCKED | New writes are scoped, but the v3 IndexedDB upgrade leaves old retained mutations inaccessible. |
| SCOPE-02 | 160-01, 160-02, 160-03 | Logout/switch stops replay; cross-scope replay fails closed | ✗ BLOCKED | An old flush can update the new scope's shared status after a transition. |
| SCOPE-03 | 160-02, 160-03 | Session, route, and feature reauthorization before mutation | ✗ BLOCKED | Default Sigra admission is evaluated with nil route/session, not current authority. |
| SCOPE-04 | 160-03 | Raw payloads excluded from egress surfaces | ✗ BLOCKED | A forgeable public struct can carry arbitrary sensitive values into root telemetry/Logger projection. |
| SCOPE-05 | 160-02, 160-03 | Sigra adapts backend authority only | ✗ BLOCKED | The default host call does not pass backend authority evidence to Sigra. |

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/offline/journal.ex` | Required opaque journal scope | ✓ VERIFIED | Required bounded `scope_ref` validation and direct transport map copy exist. |
| `lib/crosswake/offline/runtime.ex` | Lifecycle/epoch primitives | ✓ VERIFIED | Inactive/active lease and ordered drain primitives are substantive; browser integration still fails stale post-await fencing. |
| `examples/phoenix_host/priv/static/offline_study.js` | Scoped browser storage and lifecycle | ✗ HOLLOW | New-store operations are wired, but legacy migration, post-await fencing, and partial-block UI handling are missing. |
| `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` | Fail-closed ordered host admission | ✗ HOLLOW | Wiring reaches `Study.apply_one/3`, but default Sigra authority evaluation is nil/nil. |
| `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` | Atomic idempotent domain mutation | ✗ HOLLOW | `Ecto.Multi` is wired, but the schema migration breaks idempotency for existing rows. |
| `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` | Closed replay allow/deny projection | ⚠️ PARTIAL | `replay_decision/3` is substantive, but the production caller does not supply real inputs. |
| `lib/crosswake/offline/safe_observation.ex` | Validated surface-specific projections | ✗ HOLLOW | Constructor validates maps; public structs bypass it at every projection. |
| `lib/crosswake/telemetry.ex` / `lib/crosswake/doctor/doctor.ex` | Safe root egress | ✗ HOLLOW | Both trust forgeable SafeObservation structs. |
| `lib/crosswake/proof_lane/evidence.ex` | Closed evidence assertions | ✓ VERIFIED | Existing exact-schema machinery remains wired; it cannot compensate for the unsafe source egress. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Journal.Entry.scope_ref` | `Replay.Request.scope_ref` | `request_for_entry/1` | ✓ WIRED | Direct copy at `lib/crosswake/offline/replay.ex:79-88`. |
| Browser active scope/epoch | IndexedDB/send/completion/UI | lease checks | ✗ PARTIAL | Checks exist before send and response handling, but not after later awaits or before all UI writes. |
| `SyncController.sync_events/4` | `ReplayAdmission.authorize/4` | per-event reduction | ✓ WIRED | Direct invocation at `sync_controller.ex:29`. |
| `ReplayAdmission.authorize/4` | Sigra | `sigra_allows?/3` | ✗ NOT SAFE | Default link calls `evaluate_auth(nil, nil, [])`. |
| `ReplayAdmission.authorize/4` | `Study.apply_one/3` | allowed authority map | ⚠️ PARTIAL | Connected at `sync_controller.ex:31`, but its upstream Sigra decision is not authority-backed. |
| `Study.apply_one/3` | `Repo.transaction/0` | `Ecto.Multi` | ✗ PARTIAL | Atomic new-row transaction exists; migration removes legacy uniqueness protection. |
| `SafeObservation` | telemetry/Logger/doctor | projection functions | ✗ NOT SAFE | Connected, but accepts forged structs without validation. |
| Server `halted` result | browser blocked status | `flushOutbox` response handling | ✗ NOT WIRED | Browser does not inspect `data.data.halted`. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `offline_study.js` | `records` | `scoped_mutations.by_scope` IndexedDB index | New records only; legacy `mutations` is ignored | ⚠️ STATIC/LEGACY-DISCONNECTED |
| `replay_admission.ex` | Sigra decision | resolved route/session should be source | Default source is literal `nil, nil` | ✗ DISCONNECTED |
| `safe_observation.ex` | egress metadata | caller-supplied struct fields | No projection-boundary validation | ✗ UNTRUSTED |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused core lifecycle/scope contracts | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs test/crosswake/offline/runtime_test.exs` | 11 tests, 0 failures | ✓ PASS — does not cover legacy browser upgrade or post-await UI race |
| Host admission/idempotency tests | `cd examples/phoenix_host && MIX_ENV=test mix test …local_first…` | 8 tests, 0 failures | ✓ PASS — callback-injected tests do not cover default Sigra inputs or old rows |
| Safe egress tests | focused five-file Mix test | 66 tests, 0 failures | ✓ PASS — no direct-struct forgery test |
| Sigra contracts | `cd packages/crosswake_sigra && mix test …contracts_test.exs` | 13 tests, 0 failures | ✓ PASS — companion test does not validate the host caller |
| Existing in-flight browser test | `npm run proof:offline-island -- --grep "switch in flight keeps an old completion"` | 1 passed | ✓ PASS — does not fence after the response lease check |
| Default Sigra branch | `MIX_ENV=test mix run -e 'Sigra.replay_decision(nil, nil, [])'` | `decision: :allow` | ✗ FAIL |
| Forged SafeObservation projection | `mix run -e 'SafeObservation.to_telemetry(forged)'` | `forged_route_reaches_projection: true` | ✗ FAIL |

## Review Reconciliation

All four blockers in `160-REVIEW.md` are confirmed independently:

1. **CR-01 confirmed:** nil route/session default Sigra evaluation returns allow.
2. **CR-02 confirmed:** direct `%SafeObservation{}` construction bypasses `new/1` and reaches the projection used by root telemetry.
3. **CR-03 confirmed:** no legacy IndexedDB migration/quarantine/recovery code or upgrade fixture exists.
4. **CR-04 confirmed:** nullable migration drops the global unique key without backfill, while the runtime checks only the scoped pair.

**WR-01 is confirmed.** It is a real SCOPE-02 failure, not merely a test-quality concern: there is no lease check before status writes after the deletion/count awaits, and no regression simulates that timing. An additional independent failure was found: a partial server-side feature denial is emitted as `halted` but rendered as ordinary sync progress by the browser.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/proof_lane/evidence.ex` | 29 | Unused `@after_digest_barrier` module attribute | ⚠️ Warning | Every focused run emits a compiler warning; not a phase-goal blocker. |
| `test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | 19-27 | Source-string/equation assertions only | ⚠️ Warning | Test proves mentions of SafeObservation, not rejection of forged values at public egress. |

## External Prerequisites

TODO-002, real host-issued scope/route/flag/session data, host adapters, and physical-iPhone proof remain `unknown_blocking` downstream prerequisites. They are not used to defer or mask the Phase 160 implementation failures above; no human UAT is requested because all identified gaps have deterministic automated regression paths.

## Gaps Summary

Six related gaps block the phase: unsafe legacy upgrade handling, stale UI fencing, nil-backed Sigra authorization, legacy idempotency regression, forgeable privacy projections, and ignored partial disablement. The next action is an automated gap-closure plan with explicit regression tests for each case; Phase 161/162 do not specifically address these contracts, so none is deferred.

---

_Verified: 2026-08-02T18:14:00Z_
_Verifier: the agent (gsd-verifier)_
