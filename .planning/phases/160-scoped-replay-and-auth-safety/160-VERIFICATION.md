---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-02T19:36:04Z
status: gaps_found
score: 21/26 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 0/7
  gaps_closed:
    - "Legacy IndexedDB mutations are atomically quarantined and require an active exact-scope lease for recovery."
    - "Post-await stale success and denial paths are lease-fenced; a halted batch is visibly paused and retained."
    - "Default Sigra admission receives typed RouteEntry/AuthContext evidence."
    - "Legacy null-scope rows retain a global idempotency tombstone."
    - "SafeObservation projections revalidate forged structs before egress."
  gaps_remaining:
    - "ReplayAdmission accepts non-opaque scope references that core and browser reject."
    - "Study reports a persisted rejected idempotency record as accepted."
    - "The online event listener invokes flushOutbox while inactive, producing an unhandled rejected promise instead of an inert no-op."
  regressions: []
gaps:
  - truth: "Every scoped replay envelope uses one bounded versioned opaque scope reference and malformed scope input fails closed."
    status: failed
    reason: "The host validator accepts any v1. prefix plus 8-120 arbitrary bytes, including whitespace and account-like delimiters; callbacks can then authorize and persist it."
    artifacts:
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex"
        issue: "valid_scope/1 is weaker than the anchored core/browser grammar."
    missing:
      - "Use the common anchored vN.<16-128 URL-safe bytes> grammar at host admission and add negative integration cases."
  - truth: "Rejected, conflict, blocked, and ambiguous replay outcomes remain explicit and retained rather than being acknowledged as accepted."
    status: failed
    reason: "Study.apply_one/3 and current_outcome/2 classify every same-scope or null-scope existing ReviewEvent as accepted without examining status."
    artifacts:
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/study.ex"
        issue: "A persisted status: rejected returns outcome: accepted, causing the browser accepted-prefix path to delete the retained record."
    missing:
      - "Map persisted rejected rows to a retained rejected result in both normal and race-recovery paths, with regression tests."
  - truth: "Retained partitions launch inert and inactive reconnects do not create replay work or errors."
    status: partial
    reason: "The online listener passes flushOutbox directly; flushOutbox calls requireActiveLease before its try/finally, so reconnect after launch/logout/fence rejects without a handler."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "window.addEventListener('online', flushOutbox) permits an unhandled rejection while inactive."
    missing:
      - "Make inactive replay an explicit no-op and catch unexpected listener failures; add an inactive-online regression."
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** Enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement.
**Verified:** 2026-08-02T19:36:04Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 160-04 through 160-08 gap closure

## Goal Achievement

The goal is **not achieved**. The prior six gaps are materially repaired, and the planned suites pass, but two reachable server paths violate opaque-scope and truthful-retention guarantees. A third browser listener path violates the required inert lifecycle behavior. These are implementation gaps, not deferred adopter inputs.

### Observable Truths

All 26 PLAN `must_haves.truths` were checked against current code and the focused runnable suites. Roadmap success criteria are covered by the matching rows below (cross-scope proof: 01/04/07; redaction: 03/08; backend-only Sigra: 06; disablement: 05).

| Plan | # | Must-have (abridged) | Status | Evidence |
| --- | --- | --- | --- | --- |
| 01 | 1 | Required opaque scope on entry/request/local record/lease/completion; no all-scope operation | ✓ VERIFIED | Core and browser use anchored `vN.` URL-safe grammar; exact scope IndexedDB access is exercised by 16 browser proofs. |
| 01 | 2 | Inert launch and fenced account transitions | ✗ FAILED | Fencing is sound after activation, but `online -> flushOutbox -> requireActiveLease` rejects while inactive. |
| 01 | 3 | Serial drain deletes accepted only; nonaccepted outcomes remain recoverable | ✗ FAILED | A persisted rejected event becomes `accepted`, so the accepted-prefix browser path deletes it. |
| 02 | 1 | Exact-scope event completes ordered admission and atomic effect | ✗ FAILED | `ReplayAdmission.valid_scope/1` admits a non-opaque server envelope before the transaction. |
| 02 | 2 | Malformed/missing/denied dynamic admission fails closed | ✗ FAILED | `"v1. bad scope"` is malformed by core/browser contract yet returns `{:allow, %{route: %{}}}` with valid callbacks. |
| 02 | 3 | Duplicate accepted is accepted; rejected/conflict/blocked are explicit retained outcomes | ✗ FAILED | Existing same-scope/null rejected rows return `outcome: :accepted` in both transaction and recovery paths. |
| 02 | 4 | Tracer preserves non-passing native/device prerequisites | ✓ VERIFIED | `160-VALIDATION.md` and browser proof keep native/device outcomes non-passing; TODO-002 remains `unknown_blocking`. |
| 03 | 1 | Safe per-surface operational/evidence projections exclude sensitive bytes | ✓ VERIFIED | 118 core tests include forged-observation zero-egress coverage; every public projection calls `validate/1`. |
| 03 | 2 | Doctor/inspection expose static policy readiness, not scopes/outbox | ✓ VERIFIED | `Doctor.static_readiness/1` uses only the two-key projection; focused egress tests pass. |
| 03 | 3 | Exact evidence schema has closed Phase 160 assertions and final-byte scan | ✓ VERIFIED | `Evidence` retains its closed assertion vocabulary and evidence tests pass. |
| 03 | 4 | TODO-002/adopter/device prerequisites remain blocked or unknown | ✓ VERIFIED | State, validation, and proof output retain `unknown_blocking`; no support promotion found. |
| 04 | 1 | Legacy IndexedDB data is non-assigningly quarantined | ✓ VERIFIED | Upgrade cursor copy/delete is in the same transaction; legacy browser regressions pass. |
| 04 | 2 | Only exact active lease recovery can move quarantine into a scope | ✓ VERIFIED | `recoverLegacyMutations/1` checks active scope/epoch; wrong-scope regression passes. |
| 04 | 3 | Interrupted upgrade/recovery keeps one source of truth | ✓ VERIFIED | Transaction aborts on failure and browser recovery proofs pass. |
| 05 | 1 | Fence-first logout/switch makes later old-epoch effects inert | ✓ VERIFIED | Abort, transaction ownership, and post-await lease guards; delayed success/denial browser tests pass. |
| 05 | 2 | Delayed success/non-success cannot affect replacement scope | ✓ VERIFIED | `post-response fence` success and denial tests pass. |
| 05 | 3 | Halted partial batches retain suffix and visibly pause | ✓ VERIFIED | Closed `halted` parser renders paused state after accepted-only delete; proof passes. |
| 06 | 1 | Sigra accepts only typed route/AuthContext and otherwise returns safe denial | ✓ VERIFIED | Guarded `replay_decision/3`; 15 companion contract tests pass. |
| 06 | 2 | Host passes current typed authority; browser/core gain no token authority | ✓ VERIFIED | Default resolution builds host-private route/AuthContext immediately before Sigra; no credential fields leave authority map. |
| 06 | 3 | Default path has denial coverage and cannot allow through omitted callbacks | ✓ VERIFIED | Host test exercises default allow and missing-evidence denial before domain callback. |
| 07 | 1 | Null-scope legacy row is a global accepted tombstone | ✓ VERIFIED | Global unique index restored and legacy tombstone test passes. |
| 07 | 2 | New scoped uniqueness and cross-scope conflict are fail-closed | ✓ VERIFIED | Global lookup plus scoped conflict test leaves one row and returns conflict. |
| 07 | 3 | Corrective migration is additive and does not invent legacy ownership | ✓ VERIFIED | Second migration adds only global unique index; no backfill code exists. |
| 08 | 1 | Forged SafeObservation cannot reach egress | ✓ VERIFIED | Projection boundary round-trips through `new/1`; forged-struct suites pass. |
| 08 | 2 | Egress consumers invoke output only on `{:ok, projection}` | ✓ VERIFIED | Offline/root telemetry and doctor pattern-match success; zero-egress tests pass. |
| 08 | 3 | One same-tree gate covers original threats without self-approved security | ✓ VERIFIED | Validation records a passing gate; `160-SECURITY.md` still declares the independent audit blocked/open. |

**Score:** 21/26 truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact set | Status | Details |
| --- | --- | --- |
| 01 core scope/lifecycle and browser proof artifacts | ⚠️ PARTIAL | All exist and are substantive; `offline_study.js` has the inactive-listener gap. |
| 02 host admission, Study, Sigra, E2E artifacts | ✗ HOLLOW | All exist and are wired, but admission grammar and rejected-outcome mapping are wrong. |
| 03 SafeObservation, telemetry, doctor, evidence, privacy proof | ✓ VERIFIED | Boundary validation and success-only egress are wired and exercised. |
| 04 legacy quarantine/recovery source and browser proof | ✓ VERIFIED | Real IndexedDB upgrade/recovery flow is connected and tested. |
| 05 lifecycle/halting source and browser proof | ✓ VERIFIED | Post-await guards, abort ownership, and paused rendering are connected and tested. |
| 06 typed Sigra host/companion artifacts | ✓ VERIFIED | Default host caller supplies typed inputs to guarded companion API. |
| 07 migration/idempotency source and tests | ⚠️ PARTIAL | Migration guard is sound; Study’s status-blind outcome projection is not. |
| 08 revalidated egress and validation ledger | ✓ VERIFIED | Source and tests are substantive; the ledger cannot cover the later-discovered defects. |

### Key Link Verification

| From | To | Status | Evidence |
| --- | --- | --- | --- |
| `Journal.Entry.scope_ref` | `Replay.Request.scope_ref` | ✓ WIRED | `request_for_entry/1` directly copies `scope_ref`; core contract tests pass. |
| Browser active scope/epoch | browser reads, sends, completion, UI | ⚠️ PARTIAL | Exact-scope operations and post-await guards work; inactive `online` event is not inert. |
| Browser request | `SyncController` → `ReplayAdmission` → `Study` | ✗ NOT SAFE | Calls are wired, but host `valid_scope/1` accepts values the other endpoints reject. |
| `Study.apply_one/3` | global/scoped idempotency and response | ✗ NOT SAFE | Transaction is atomic, but it discards persisted `status: "rejected"` when forming an outcome. |
| Resolved host evidence | `Sigra.replay_decision/3` | ✓ WIRED | Typed `RouteEntry` and `AuthContext` reach the guarded call per event. |
| `SafeObservation` | telemetry/Logger/Doctor/evidence | ✓ WIRED | Public projections validate; consumers emit only success projections; focused tests pass. |
| `SyncController.halted` | learner paused status | ✓ WIRED | Browser parses allowed halted classes and renders paused state after retaining suffix. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Status |
| --- | --- | --- | --- |
| Browser scoped mutations | active scope-indexed records | IndexedDB `by_scope` index | ✓ FLOWING — quarantine/recovery tests prove current data flow. |
| Replay admission scope | request `scope_ref` | browser request/host session matcher | ✗ UNSAFE — host grammar accepts non-opaque bytes. |
| Study replay outcome | persisted `ReviewEvent.status` | existing idempotency row | ✗ HOLLOW — status is read as a row but never used to select `accepted` vs `rejected`. |
| Operational observations | closed observation fields | `SafeObservation.validate/1` / `new/1` | ✓ FLOWING — success-only projection paths tested. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core scope, privacy, evidence, doctor, inspection contracts | `mix test test/crosswake/offline …json_formatter_test.exs` | 118 tests, 0 failures | ✓ PASS |
| Typed Sigra replay contract | `cd packages/crosswake_sigra && mix test …contracts_test.exs` | 15 tests, 0 failures | ✓ PASS |
| Phoenix replay/admission/idempotency contracts | `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first` | 14 tests, 0 failures | ✓ PASS — lacks rejected-row status case and hostile scope grammar case. |
| Browser scope/recovery/lifecycle/halting behavior | `cd examples/phoenix_host && npm run proof:offline-island` | 16 tests, 0 failures | ✓ PASS — lacks inactive `online` listener case. |
| Host malformed-scope admission | `MIX_ENV=test mix run -e '…authorize("v1. bad scope", …)'` | `{:allow, %{route: %{}}}` | ✗ FAIL |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| SCOPE-01 | ✗ BLOCKED | Browser/core require an opaque grammar, but host admission accepts and can persist malformed scope references. |
| SCOPE-02 | ✗ BLOCKED | Switch fencing works, but inactive reconnect produces an unhandled rejection rather than the required inert posture. |
| SCOPE-03 | ✗ BLOCKED | Current authority layers are present, but a persisted rejection is falsely acknowledged and deleted as accepted. |
| SCOPE-04 | ✓ SATISFIED | Revalidated allowlists and every-egress forged-canary tests pass. |
| SCOPE-05 | ✓ SATISFIED | Sigra receives typed server authority and safely denies untyped input; no token authority was added to core/browser. |

No orphaned Phase 160 requirement IDs were found. Phases 161–162 cover pack/device work, not these implementation defects, so none is deferred.

### Review Reconciliation

| Finding | Independent verdict | Goal impact |
| --- | --- | --- |
| CR-01 — non-opaque host scope accepted | **CONFIRMED (BLOCKER)** | Breaks SCOPE-01 and both the account-scoped/outbox boundary and malformed-admission contract. |
| CR-02 — rejected row replayed as accepted | **CONFIRMED (BLOCKER)** | Breaks truthful retained outcomes; browser accepted-prefix deletion can remove the only attention signal. |
| WR-01 — inactive online listener rejects | **CONFIRMED (WARNING / must-have failure)** | Does not cross scopes, but violates required inert launch/reconnect behavior and needs automated regression coverage. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/proof_lane/evidence.ex` | 29 | Unused `@after_digest_barrier` | ⚠️ Warning | Existing compiler warning; not a Phase 160 goal blocker. |
| `examples/phoenix_host/test/crosswake_example/local_first/*.exs` | relevant cases absent | Passing tests omit rejected-row and hostile-scope inputs | ⚠️ Warning | Suites passed while both critical behaviors remained unexercised. |

### Privacy and External Boundaries

TODO-002 and real adopter scope, route, feature, session, adapter, and physical-iPhone inputs remain `unknown_blocking`. This report neither infers those values nor promotes any device/support claim. All identified gaps are code-contract defects with deterministic automated fixes; no human UAT is created.

## Gaps Summary

Three gaps block closure: align server scope validation with the opaque cross-layer contract, preserve `rejected` idempotency outcomes through normal and race paths, and make inactive online replay a caught no-op. The first two are critical goal failures; the third is a lifecycle must-have failure. The existing unrelated `.planning/config.json` modification was observed and left untouched.

**Next action:** Gaps found. Plan the fixes, then re-run execute-phase before shipping.

**Next command:** `/gsd:plan-phase 160 --gaps`

---

_Verified: 2026-08-02T19:36:04Z_
_Verifier: the agent (gsd-verifier)_
