---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-03T00:37:33Z
status: gaps_found
score: 37/39 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 34/35
  gaps_closed:
    - "Phoenix replay admission now rejects extra replay-wire fields before authority callbacks."
    - "Study persistence now reconstructs allowlisted fields and assigns accepted status server-side."
  gaps_remaining: []
  regressions:
    - "Online scope activation leaves retained same-scope work inert when the browser is already online."
    - "A truncated 200 replay acknowledgement is treated as complete rather than failing closed."
gaps:
  - truth: "An active, authorized scope replays its retained exact-scope outbox when activation occurs while already online."
    status: failed
    reason: "activateScope/1 persists the active lease and updates status but never starts a guarded flush. Replay waits for a later online event or a new review, so relaunch-plus-reauthorization strands retained work."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "Lines 51-65 activate the lease without calling guarded replay after writeLifecycle/1."
      - path: "examples/phoenix_host/e2e/offline_sync.spec.ts"
        issue: "No regression reloads with retained work while online, activates the scope, and asserts one sync request plus an empty scoped outbox."
    missing:
      - "After successful lifecycle activation, conditionally start a lease-guarded replay when navigator.onLine is true."
      - "Add the relaunch/online activation Playwright regression with no scope or payload disclosure."
  - truth: "Only a complete, ordered accepted acknowledgement can delete a complete submitted replay batch; any incomplete 200 response fails closed and leaves queued data visibly paused."
    status: failed
    reason: "classifyReplayResponse/2 checks accepted IDs only against a prefix and returns complete whenever halted is null. Empty or truncated accepted_records therefore clears error styling and reports success while omitted records remain queued without a retry trigger."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "Lines 107-117 lack a complete-response cardinality check; lines 545-548 render ordinary synced status for the malformed result."
      - path: "examples/phoenix_host/e2e/offline_sync.spec.ts"
        issue: "The malformed-response test covers halted-shape validation, not a 200 response that omits an accepted record with halted null."
    missing:
      - "Require accepted_records to account for every submitted record when halted is null; reject any cardinality or outcome mismatch as blocked."
      - "Add an E2E regression for a truncated successful response and assert paused status plus retained outbox."
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** Enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement.
**Verified:** 2026-08-03T00:37:33Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 160-12

## Goal Achievement

The Plan 160-12 server-authority repair is real: exact event-key admission occurs before session resolution, persistence copies only the three admitted fields plus host scope, and `ReviewEvent` sets `accepted` itself. The prior outcome/status mass-assignment gap is closed.

The goal is still **not achieved**. The current browser client has two independently observable replay defects: retained work does not start after online authorization/activation, and an incomplete successful response is displayed as successful. Both strand authorized mutations without a fail-closed visible state. These are Phase 160 code defects, not adopter-instance unknowns and not work deferred to Phases 161 or 162.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Scoped outboxes use one bounded opaque reference; no production all-scope operation exists. | ✓ VERIFIED | Core, host, and browser share the anchored scope grammar; 18-browser-test suite passed exact partition and recovery coverage. |
| 2 | Logout/switch fencing and reconnect lifecycle prevent cross-scope replay. | ✓ VERIFIED | Lease revocation precedes awaits and current-lease checks guard browser storage/UI; active/inactive reconnect and post-response fence tests passed. |
| 3 | Every queued mutation is reauthorized by backend session, route, feature, Sigra, and domain authority before application. | ✓ VERIFIED | `ReplayAdmission.authorize/4` validates exact wire keys before session resolution, then performs scope, route, feature, Sigra, and domain checks before `Study.apply_one/3`; focused Phoenix suite: 21/21. |
| 4 | Operational and retained proof egress excludes raw replay payloads and authority facts. | ✓ VERIFIED | `SafeObservation` revalidates before each projection and production egress consumes only successful projections; privacy regressions are wired. |
| 5 | Sigra remains a typed backend-authority adapter; core/browser have no credential or token authority. | ✓ VERIFIED | `replay_decision/3` accepts only `RouteEntry` and validated `AuthContext`, otherwise returns `{:deny, :sigra_denied}`. |
| 6 | A newly authorized active scope replays retained exact-scope work while already online. | ✗ FAILED | `activateScope` ends after `writeLifecycle` and status update; no guarded `flushOutbox` call exists. |
| 7 | A successful replay acknowledgement accounts for the full submitted batch before it is presented as complete. | ✗ FAILED | `classifyReplayResponse` accepts a matching prefix with `halted: null`, then renders `Synced N` even when records remain. |

**Score:** 37/39 PLAN must-have truths verified (0 present-but-behavior-unverified).

### Roadmap Success Criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| Cross-scope replay is impossible under tests. | ✓ VERIFIED | Browser scope partition, lifecycle fence, and Phoenix scope-admission regressions pass. |
| Raw answers never enter telemetry, doctor output, inspection, or evidence. | ✓ VERIFIED | Closed `SafeObservation` projections and egress tests protect named outputs. |
| `crosswake_sigra` adapts backend authority without giving WebView/shell token authority. | ✓ VERIFIED | Typed Sigra boundary and host-only session resolution are present and focused tests pass. |
| A disabled path preserves queued data and visibly fails closed. | ✓ VERIFIED | The `halted` feature-disabled path retains its suffix and renders paused; dedicated browser regression passed. |

The roadmap criteria do not reduce the broader phase-goal contract. Truths 6-7 block reliable authorized replay and fail-closed response handling.

### Required Artifacts

`verify.artifacts` reports all **41/41** PLAN-declared artifacts present and substantive. Manual source tracing finds all declared server/core links wired. The browser artifact is wired to IndexedDB and `/study/sync`, but is hollow on the two failure paths below.

| Artifact group | Status | Details |
| --- | --- | --- |
| Core journal/runtime and browser IndexedDB scope partition | ✓ VERIFIED | Required opaque scope, compound-key store, lifecycle epoch, and exact-scope reads are implemented. |
| Phoenix admission, transaction, and idempotency artifacts | ✓ VERIFIED | Exact admission → current authority chain → `Ecto.Multi` → server-owned accepted persistence. |
| Sigra authority adapter | ✓ VERIFIED | Typed inputs, closed denial projection, and host-owned authority construction. |
| Privacy/evidence/doctor artifacts | ✓ VERIFIED | Safe projection construction, validation, and success-only egress are wired. |
| Browser replay activation and response parser | ✗ HOLLOW | Runtime entry points exist and are used, but online activation does not invoke replay and truncated acknowledgement semantics fail open. |
| Validation ledger | ✓ VERIFIED | Current post-160-12 command ledger exists, but its green browser suite lacks the two reported cases. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Journal entry | Replay request | required `scope_ref` copy | ✓ WIRED | Shared required opaque value is present through core transport. |
| Browser active lease | IndexedDB/send/completion | scope + epoch guards | ✓ WIRED | `activeLeaseOrNull`/`leaseIsCurrent` protect existing worker paths. |
| Sync controller | admission → study transaction | ordered per-event authority | ✓ WIRED | Source and 21 focused Phoenix tests prove admission-before-persistence. |
| Replay admission | Sigra | typed route/auth context | ✓ WIRED | Host invokes `replay_decision/3` only after typed construction. |
| Online authorization | replay worker | activation of retained queue | ✗ NOT_WIRED | `activateScope` has no replay invocation. |
| Accepted server response | browser deletion/status | complete ordered acknowledgement | ✗ PARTIAL | Prefix IDs are validated, but full-batch cardinality is not. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Browser offline island | `records` | scoped IndexedDB `getScopeMutations(scopeRef)` | Yes; POST body uses the current exact-scope batch | ✓ FLOWING, with replay activation gap |
| Phoenix replay path | `events` | `/study/sync` request | Yes; controller authorizes and persists outcomes in `Repo.transaction` | ✓ FLOWING |
| Safe observations | typed projection | explicit closed constructor/validation | Yes; egress receives projections only | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Extra replay-wire key is denied before authority/persistence; server-owned status persists | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs)` | 21 tests, 0 failures | ✓ PASS |
| Existing browser scoped replay, fence, halted, and malformed-halted checks | `(cd examples/phoenix_host && npm run proof:offline-island)` | 18 tests, 0 failures | ✓ PASS — insufficient for truths 6-7 |
| Online activation replays retained work | Existing targeted test search | No matching regression; source omits call | ✗ FAIL |
| Truncated 200 acknowledgement fails closed | Existing targeted test search | No matching regression; parser accepts prefix | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SCOPE-01 | 01, 02, 03, 04, 07, 08, 09, 11 | Opaque scope on envelopes and scope-partitioned outbox. | ✓ SATISFIED | Shared grammar, storage partitions, quarantine/recovery, and hostile-scope regressions. |
| SCOPE-02 | 01, 02, 03, 04, 05, 08, 10, 11 | Logout/account switch stop replay; cross-scope replay fails closed. | ✓ SATISFIED | Fence-first lifecycle, stale-completion guards, and inactive-online no-op coverage. |
| SCOPE-03 | 02, 03, 05, 06, 07, 08, 09, 11, 12 | Backend session/route/feature reauthorization before applying mutations. | ✓ SATISFIED | Exact admission and current authority chain, server-owned persistence, 21 focused host tests. |
| SCOPE-04 | 03, 08, 11 | Raw answers excluded from operational and proof egress. | ✓ SATISFIED | SafeObservation validation/projections and every-egress privacy tests. |
| SCOPE-05 | 02, 03, 06, 08, 11 | Sigra is backend authority adapter; token authority stays outside core. | ✓ SATISFIED | Typed guarded Sigra decision and closed host integration. |

Every Phase 160 requirement is declared by at least one PLAN; no orphaned requirement IDs were found. The two gaps are additional phase-goal/must-have failures: they do not negate the narrower reauthorization statement in SCOPE-03, but prevent completion of the end-to-end replay and auth-continuity outcome.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/priv/static/offline_study.js` | 51-65 | Activation returns without replay start | 🛑 BLOCKER | Authorized retained mutations can remain stranded. |
| `examples/phoenix_host/priv/static/offline_study.js` | 107-117, 545-548 | Prefix acknowledgement treated as complete | 🛑 BLOCKER | Incomplete server result is displayed as normal success. |
| `lib/crosswake/proof_lane/evidence.ex` | 29 | Unused `@after_digest_barrier` | ℹ️ INFO | Compiler warning observed in both focused commands; not the phase goal blocker. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in Phase 160 implementation artifacts. The `return null` match in browser code is a guarded absence value, not user-visible stub output.

### Gaps Summary

Two closely related browser replay gaps block the phase goal. Repair the activation-to-replay link with existing lease guards, make complete acknowledgements exact/full-batch only, and add the two missing Playwright regressions. Re-run the focused browser suite and the Phase 160 gate afterwards. No human verification is appropriate: both defects are deterministic and automatable.

**Next action:** Escalation Gate — revise the browser replay activation and response-contract handling, then re-verify.

**Next command:** `/gsd:plan-phase 160 --gaps`

---

_Verified: 2026-08-03T00:37:33Z_
_Verifier: the agent (gsd-verifier)_
