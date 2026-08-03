---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-03T02:09:03Z
status: gaps_found
score: 38/39 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 38/39
  gaps_closed:
    - "Both sync routes now use the request-bound ReplayAuth pipeline; anonymous and missing-authority requests halt before admission and persistence."
    - "Immediate online submission now dispatches through replayOnOnline(), whose current-lease catch renders paused state without an unhandled rejection."
  gaps_remaining:
    - "Unscoped legacy IndexedDB records can be assigned to whichever account is currently active."
  regressions:
    - "A legacy ReviewEvent with scope_ref: nil is treated as an accepted duplicate for a scoped replay instead of a closed migration/scope-conflict result."
gaps:
  - truth: "Logout and account switching stop replay, and cross-scope replay fails closed."
    status: failed
    reason: "Legacy records lack an account/scope binding but recoverLegacyMutations assigns every quarantined record to the current active lease. A subsequent account can therefore claim and replay prior unscoped work. The server also reports a nil-scope legacy idempotency row as accepted for an arbitrary scoped request."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "recoverLegacyMutations/1 derives the destination scope solely from activeScopeRef and copies all quarantined records into it."
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/study.ex"
        issue: "Both idempotency lookup paths treat scope_ref: nil as :duplicate and can return accepted to a scoped replay."
      - path: "examples/phoenix_host/e2e/offline_sync.spec.ts"
        issue: "The recovery test proves same-current-scope recovery but has no shared-device/account-switch denial case."
    missing:
      - "Keep unowned legacy records quarantined unless a host-owned, server-verifiable per-record ownership binding authorizes recovery; otherwise retain an explicit blocked/recovery-required state."
      - "Map nil-scope persisted tombstones to a closed migration-required or scope-conflict outcome for scoped replay, never accepted deletion authority."
      - "Add a browser/request regression that seeds an unscoped record, switches account, and proves no second-scope queue entry, accepted acknowledgement, or domain mutation occurs."
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** Enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement for the bounded First B2C Adopter offline study island.
**Verified:** 2026-08-03T02:09:03Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 160-14 through 160-16

## Goal Achievement

The final plans repaired the prior public-fixture authority and immediate-online rejection defects. That is real: both sync aliases are behind `:replay_api` / `ReplayAuth`, and the browser's immediate-online path now uses the lease-guarded `replayOnOnline()` wrapper.

The phase goal is still **not achieved**. The current tree lets a user who activates any valid scope claim every unscoped legacy browser record, then treats an existing nil-scope server row as an accepted duplicate for that new scope. This is observable code, not a coverage uncertainty: it defeats the stated account-switch/logout fail-closed contract. The focused legacy recovery test passes because it asserts the unsafe promotion, so it is not evidence for cross-account safety.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Cross-scope replay is impossible under tests. | ✗ FAILED | `recoverLegacyMutations` copies unowned quarantine records into the current lease; no ownership proof is required. Its test passes while asserting this promotion. |
| 2 | Raw answers never enter telemetry, doctor output, inspection, or evidence. | ✓ VERIFIED | Closed `SafeObservation` projections are wired into operational egress; 18 focused core/privacy tests passed. |
| 3 | `crosswake_sigra` adapts backend authority without making WebView or shell token authority. | ✓ VERIFIED | `ReplayAuth` owns request authority; `ReplayAdmission` calls Sigra only after session/scope/route/feature checks. The 15-contract Sigra suite passed. |
| 4 | A disabled path preserves queued data and visibly fails closed. | ✓ VERIFIED | Feature-disabled browser and controller paths return halted/paused retention; targeted Playwright disablement proof passed. |
| 5 | Anonymous, logged-out, switched, revoked, and scope-mismatched requests deny before persistence on both sync aliases. | ✓ VERIFIED | Router uses `:replay_api`; `ReplayAuth` fails closed without a configured authority. 24 focused Phoenix tests passed. |
| 6 | Immediate-online replay failures retain exact-scope work and render paused without an unhandled rejection. | ✓ VERIFIED | `handleReview` dispatches via `replayOnOnline`; the named Playwright regression passed. |
| 7 | An active scope is fenced before lifecycle transition and stale workers cannot mutate another scope. | ✓ VERIFIED | `fenceScope` revokes scope/epoch before awaits and aborts the owned worker; switch-in-flight regression passed. |
| 8 | Legacy idempotency cannot turn unowned work into accepted deletion authority for another scope. | ✗ FAILED | `Study.apply_one/3` and `current_outcome/2` classify `%ReviewEvent{scope_ref: nil}` as a duplicate and may return `outcome: :accepted`. |

**Score:** 38/39 must-haves verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Plan-declared artifacts | Substantive implementation/test artifacts | ✓ VERIFIED | `verify.artifacts` found 56/56 declared artifacts present and substantive across all 16 plans. |
| Scoped browser outbox | Exact-scope storage, fencing, quarantine/recovery | ✗ SAFETY GAP | Storage and lifecycle wiring exist, but legacy recovery assigns unowned records to the active scope. |
| Phoenix replay admission | Request-bound session, route, flag, Sigra, domain checks | ✓ VERIFIED | `ReplayAuth` and `ReplayAdmission.authorize(conn, ...)` are wired per event on both routes. |
| Phoenix idempotency | Scope-safe accepted/rejected outcomes | ✗ SAFETY GAP | Nil-scope legacy rows incorrectly produce accepted duplicate outcomes for a scoped replay. |
| Privacy/Sigra/evidence | Redacted egress and typed authority adapter | ✓ VERIFIED | Focused core, privacy, and Sigra suites passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `/study/sync`, `/learnloop/sync` | `ReplayAuth` | shared `:replay_api` pipeline with `fetch_session` | ✓ WIRED | Both routes use the pipeline and auth plug. |
| `SyncController.sync_events/4` | `ReplayAdmission.authorize/4` → `Study.apply_one/3` | same `Plug.Conn`, ordered reducer | ✓ WIRED | Source calls each per event before persistence. |
| `handleReview` | `replayOnOnline` → `flushOutbox` | current lease and rejection catch | ✓ WIRED | Source line 636 dispatches through the guarded wrapper. |
| `legacy_mutations_quarantine` | scoped outbox | `recoverLegacyMutations(scopeRef)` | ✗ NOT SAFE | The only authority is the current browser lease, not a server-verifiable owner binding. |
| scoped replay duplicate | persisted legacy row | `Study.current_outcome/2` | ✗ NOT SAFE | Nil scope maps to accepted/rejected prior outcome rather than a scope conflict/migration denial. |

`verify.key-links` could not mechanically score the 42 plan links because their `from` fields are human component descriptions rather than source paths. Manual source tracing above verifies the executable links and identifies the two unsafe ones.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Browser outbox | exact-scope records | IndexedDB `by_scope` index | Yes | ✓ FLOWING |
| Replay authority | session, route, flag, Sigra/domain decision | host `ReplayAuth` callbacks from `Plug.Conn` | Yes, per event | ✓ FLOWING |
| Legacy recovery | destination `scope_ref` | current active browser lease only | No ownership data | ✗ HOLLOW AUTHORITY |
| Duplicate outcome | persisted ReviewEvent status | global lookup by mutation ID | Yes, but nil-scope interpretation is unsafe | ✗ UNSAFE FLOW |
| Operational egress | SafeObservation projections | closed allowlisted constructors | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Scope contracts and redacted observation egress | `mix test ...journal ...replay ...runtime ...safe_observation ...phase160_scoped_replay_privacy` | 18 passed | ✓ PASS |
| Typed Sigra adapter | `cd packages/crosswake_sigra && mix test ...contracts_test.exs` | 15 passed | ✓ PASS |
| Request-bound host auth/admission/idempotency | `cd examples/phoenix_host && MIX_ENV=test mix test ...local_first...` | 24 passed | ✓ PASS |
| Switch fencing, disablement retention, immediate-online failure containment | `npm run proof:offline-island -- --grep ...` | 3 passed | ✓ PASS |
| Legacy recovery fails closed across accounts | named legacy recovery Playwright test plus source inspection | Test passes, but source promotes unowned data to active scope | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SCOPE-01 | 01, 02, 03, 04, 07–09, 11–16 | Opaque scope on envelopes; outbox partitioned by scope. | ✗ BLOCKED | New records partition correctly, but unscoped legacy mutations can be assigned to any active scope. |
| SCOPE-02 | 01, 02, 04, 05, 08, 10, 11, 13–16 | Logout/switch stop replay; cross-scope replay fails closed. | ✗ BLOCKED | Normal fencing passes, but legacy recovery crosses the account boundary after a switch. |
| SCOPE-03 | 02, 03, 05–09, 11–16 | Re-check current backend session, route, and feature state before mutation. | ✓ SATISFIED | Request-bound per-event pipeline is present and the focused request suite passes. |
| SCOPE-04 | 03, 08, 11, 13–16 | Exclude raw answers from operational/proof egress. | ✓ SATISFIED | Safe projections and privacy regression suite pass. |
| SCOPE-05 | 02, 03, 06, 08, 11–16 | Sigra is backend-authority adapter; no core credential/token authority. | ✓ SATISFIED | Typed closed Sigra boundary and companion tests pass. |

All five required IDs are declared by one or more plan; no Phase 160 requirement is orphaned. The two blocked requirements prevent goal achievement.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/priv/static/offline_study.js` | 242–306 | Unowned legacy records copied to active scope | 🛑 BLOCKER | A later account can claim/replay data with no ownership binding. |
| `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` | 18, 78 | Nil-scope tombstone accepted as duplicate | 🛑 BLOCKER | A scoped queue can be acknowledged/deleted without a same-scope effect. |
| `examples/phoenix_host/e2e/offline_sync.spec.ts` | 639 | Test covers only active-scope recovery | ⚠️ WARNING | The passing test masks the missing account-switch scenario. |
| `examples/phoenix_host/priv/static/offline_study.js` | 602–636 | Rating controls remain enabled across IndexedDB await | ⚠️ WARNING | Rapid clicks can queue two different mutations for one card; reviewer WR-01. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the inspected Phase 160 implementation files. `doctor.ex`'s existing placeholder scanner is product behavior, not a Phase 160 stub.

### Gaps Summary

This is a **BLOCKER**. Scope partitioning is not sufficient when a legacy record has no trustworthy scope: browser code must not manufacture ownership from whichever account happens to be active. The accompanying server duplicate classification makes the fault worse by granting accepted deletion authority for a nil-scope historical row.

No later roadmap phase explicitly owns scoped-replay/account-switch remediation, so this gap is not deferred. Plan 161 is limited to the iOS pronunciation-pack seam and Phase 162 to physical-iPhone proof.

**Next action:** Escalation Gate — repair the legacy recovery and nil-scope idempotency paths, add the cross-account regression, then re-verify Phase 160.

**Next command:** `/gsd:plan-phase 160 --gaps`

---

_Verified: 2026-08-03T02:09:03Z_
_Verifier: the agent (gsd-verifier)_
