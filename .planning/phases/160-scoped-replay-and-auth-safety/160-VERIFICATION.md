---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-03T01:10:14Z
status: gaps_found
score: 38/39 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 37/39
  gaps_closed:
    - "An authorized active scope now starts lease-guarded replay while already online."
    - "A truncated non-halted acknowledgement now blocks before deletion and renders paused state."
  gaps_remaining: []
  regressions:
    - "The public replay endpoints construct permissive fixture authority instead of resolving the requesting account/session."
    - "An online submit invokes the replay worker without the guarded rejection handler."
gaps:
  - truth: "Every queued mutation is reauthorized from the requesting account's current backend session, route, feature, Sigra, and domain authority before application."
    status: failed
    reason: "Both replay endpoints are public JSON routes and the default authority resolvers ignore Plug.Conn, construct a configured fixture session/route, and allow the domain. An anonymous caller that knows the fixture scope can pass admission and persist events."
    artifacts:
      - path: "examples/phoenix_host/lib/crosswake_example/router.ex"
        issue: "`/study/sync` and `/learnloop/sync` use only the :api pipeline, which accepts JSON but does not fetch or require an authenticated session."
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex"
        issue: "`default_resolution/2` ignores conn and constructs fixture authority; `domain_allows?/4` defaults to :allow."
      - path: "examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs"
        issue: "The default-path test asserts allow with `%Plug.Conn{}`; no request-level anonymous, logged-out, switched-account, or revoked-session denial exists."
    missing:
      - "Install a host-owned session/authentication plug on both sync routes and fail closed without current authority."
      - "Resolve server-owned session, scope, route, flag, and domain authority from conn per event; confine synthetic fixtures to explicitly injected tests."
      - "Add request-level regressions for anonymous, logout, account-switch, and revoked-session denial before persistence."
  - truth: "Recoverable online replay failures remain contained in the visible paused state without exposing an unhandled rejection."
    status: partial
    reason: "The direct online-submit path invokes the async worker without await or catch. A storage failure after queueing can become an unhandled browser rejection rather than the existing lease-aware paused state."
    artifacts:
      - path: "examples/phoenix_host/priv/static/offline_study.js"
        issue: "`handleReview/1` calls `flushOutbox()` directly at line 636, unlike the guarded `replayOnOnline/0` path."
      - path: "examples/phoenix_host/e2e/offline_sync.spec.ts"
        issue: "The listener-failure regression exercises a dispatched online event, not an immediate online submit with a rejected worker."
    missing:
      - "Route online submit through `replayOnOnline()` or attach the same current-lease rejection handler."
      - "Add a deterministic immediate-online storage-failure regression asserting paused state and zero unhandled rejections."
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** Enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement for the bounded First B2C Adopter offline study island.
**Verified:** 2026-08-03T01:10:14Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 160-13

## Goal Achievement

Plan 160-13 closes the two earlier browser failures. The final tree dispatches an online activation through `replayOnOnline/0` and its existing current-lease guard; the two targeted Playwright tests passed (2/2). `classifyReplayResponse/2` also now requires a full ordered accepted batch with no rejected rows before deletion.

The phase goal is nevertheless **not achieved**. Backend replay admission has no request-derived account/session authority: public `/study/sync` and `/learnloop/sync` routes use only `:api`, and `ReplayAdmission` ignores `conn` to construct a permissive fixture identity. This is the fresh review's CR-01 and is a BLOCKER, not a test-coverage uncertainty. It directly defeats SCOPE-03 and the goal's backend reauthorization/account-continuity contract. A second deterministic browser error path (WR-02) also lacks the required guarded failure handling.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Scoped outboxes use one bounded opaque reference; no production all-scope operation exists. | ✓ VERIFIED | All Plan artifact checks passed (41/41); core, IndexedDB compound-key, quarantine, and partition regressions are present. |
| 2 | Logout/switch fencing and reconnect lifecycle prevent cross-scope replay. | ✓ VERIFIED | Lease revocation precedes awaits; targeted browser evidence covers stale completion and inactive reconnect. |
| 3 | Every queued mutation is reauthorized from the requesting account's current backend authority before application. | ✗ FAILED | Public API routes plus fixture defaults allow a request with `%Plug.Conn{}` to pass without account/session authority. |
| 4 | Operational and retained proof egress excludes raw replay payloads and authority facts. | ✓ VERIFIED | Closed `SafeObservation` projections and egress tests remain wired; no raw replay map flows to observed surfaces. |
| 5 | Sigra remains a typed backend-authority adapter; core/browser have no credential or token authority. | ✓ VERIFIED | Sigra's typed allow/closed-denial boundary is present; focused Phoenix suite passed 21/21. |
| 6 | An active authorized scope replays retained exact-scope work while already online. | ✓ VERIFIED | `activateScope/1` calls guarded `replayOnOnline/0`; targeted Playwright regression passed. |
| 7 | A non-halted acknowledgement is complete only when it fully and orderedly acknowledges the submitted batch. | ✓ VERIFIED | Cardinality, rejection-empty, and index equality checks occur before deletion; targeted Playwright regression passed. |
| 8 | Unexpected immediate-online replay failure is contained without an unhandled rejection. | ✗ FAILED | `handleReview/1` directly discards `flushOutbox()`'s promise at line 636; the guarded listener wrapper is not used. |

**Score:** 38/39 must-haves verified (0 present-but-behavior-unverified).

### Roadmap Success Criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| Cross-scope replay is impossible under tests. | ✓ VERIFIED | Scope partition, lifecycle, fence, and admission regressions are present and focused tests pass. |
| Raw answers never enter telemetry, doctor output, inspection, or evidence. | ✓ VERIFIED | Safe projection/egress coverage is implemented. |
| `crosswake_sigra` adapts backend authority without making WebView/shell token authority. | ⚠️ PARTIAL | Sigra is typed and non-token-owning, but its host input is a fixed fixture rather than the requesting backend session. |
| A disabled path preserves queued data and visibly fails closed. | ✓ VERIFIED | Halted disabled responses retain the suffix and render the paused state. |

### Required Artifacts

| Artifact group | Status | Details |
| --- | --- | --- |
| Plan-declared artifacts | ✓ VERIFIED | `verify.artifacts` reported every Plan 160 artifact substantive: 41/41 across all 13 plans. |
| Browser scoped replay | ⚠️ PARTIAL | Activation and acknowledgement links are repaired; direct online submit lacks the guarded rejection path. |
| Phoenix admission and persistence | ✗ HOLLOW AUTHORITY | Exact envelope/persistence constraints exist, but the authority source is fabricated and not request-bound. |
| Sigra adapter | ✓ VERIFIED | Typed route/auth-context contract is substantive and called before the host effect. |
| Safe observation/evidence surfaces | ✓ VERIFIED | Closed projections and validation-ledger boundaries are wired. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `activateScope` | `replayOnOnline` → `flushOutbox` | online captured lease | ✓ WIRED | Lines 51-65 activate then dispatch through the same guard used by reconnect. |
| Submitted records | `classifyReplayResponse` | exact cardinality and ordered IDs | ✓ WIRED | Lines 107-124 reject incomplete/mismatched success before deletion. |
| Sync request | host session/route/feature/Sigra/domain authority | `ReplayAdmission.authorize/4` | ✗ NOT WIRED | Endpoint does not establish auth; defaults ignore conn and return fixture values. |
| Online submit | visible failure handling | rejected replay promise | ✗ PARTIAL | `handleReview` calls `flushOutbox()` without `await`/`catch`; `replayOnOnline` is the wired safe adapter. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Browser island | exact-scope `records` | IndexedDB `by_scope` index | Yes | ✓ FLOWING |
| Browser replay response | `accepted_records` | `/study/sync` JSON response | Yes, now fully classified | ✓ FLOWING |
| Phoenix authority | `session`, `route`, domain result | static application fixture/default `:allow`, not `conn` | No requesting-account data | ✗ HOLLOW |
| Safe observations | typed projection | closed constructor + revalidation | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Online activation and truncated-ack fail closed | `npm run proof:offline-island -- --grep 'online activation replays retained exact-scope work|truncated successful acknowledgement fails closed'` | 2 passed | ✓ PASS |
| Phoenix exact-wire/persistence/Sigra focused regressions | `MIX_ENV=test mix test test/.../replay_admission_test.exs test/.../study_test.exs test/.../sync_controller_test.exs` | 21 tests, 0 failures | ✓ PASS — but tests affirm the insecure fixture default |
| Anonymous request is rejected before persistence | request-bound authority source inspection | No auth plug or conn resolution exists | ✗ FAIL |
| Immediate-online worker failure is caught | source/test inspection | No catch and no matching regression | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SCOPE-01 | 01, 02, 03, 04, 07, 08, 09, 11, 13 | Opaque scope on envelopes and scope-partitioned outbox. | ✓ SATISFIED | Shared grammar, partitions, quarantine/recovery, and browser regression evidence. |
| SCOPE-02 | 01, 02, 03, 04, 05, 08, 10, 11, 13 | Logout/switch stop replay; cross-scope replay fails closed. | ⚠️ PARTIAL | Fencing works, but an immediate online replay failure is unhandled. |
| SCOPE-03 | 02, 03, 05, 06, 07, 08, 09, 11, 12, 13 | Replay re-checks backend session, route authorization, feature state before mutation. | ✗ BLOCKED | Request pipeline never resolves authenticated current authority; fixture defaults allow. |
| SCOPE-04 | 03, 08, 11, 13 | Raw answers excluded from operational/proof egress. | ✓ SATISFIED | Closed safe-observation egress and tests. |
| SCOPE-05 | 02, 03, 06, 08, 11, 13 | Sigra backend adapter; credentials/token authority outside core. | ✓ SATISFIED | Typed guarded Sigra boundary; no browser/core credential authority. |

All five IDs are claimed by at least one plan. `REQUIREMENTS.md` currently shows SCOPE-03 checked, but that mark conflicts with final-tree evidence and cannot override this verification result.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | 128, 133 | JSON-only replay routes lack auth/session plug | 🛑 BLOCKER | Anonymous request can reach replay admission. |
| `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` | 89-125, 168 | Conn ignored; fixed fixture authority and default allow | 🛑 BLOCKER | No backend account/revocation/session continuity authority. |
| `examples/phoenix_host/priv/static/offline_study.js` | 636 | Async replay promise discarded | ⚠️ WARNING | Recoverable error may become unhandled rather than visibly paused. |
| `lib/crosswake/proof_lane/evidence.ex` | 29 | Unused `@after_digest_barrier` compiler warning | ⚠️ WARNING | Focused browser and host commands compile with a warning; risks a warnings-as-errors CI gate. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in inspected Phase 160 implementation artifacts. The second review warning does not independently change the goal verdict, but must be cleared before relying on a warning-clean CI proof.

### Gaps Summary

The original two browser gaps are closed, but the central backend-auth truth fails. A fixed synthetic session is useful only as an explicitly injected test fixture; it cannot represent current requester authority at a public replay endpoint. This must be repaired before Phase 160 can proceed. The immediate-submit unhandled-rejection path should be repaired in the same browser pass.

TODO-002/adopter-instance completeness remains `unknown_blocking`; generated iOS/device proof and independent security remain non-passing. They are deliberately not promoted by this report.

**Next action:** Escalation Gate — replace fixture-default endpoint authority with a host-owned authenticated request boundary, add the required denial regressions, then repair the direct-submit promise handling and re-verify.

**Next command:** `/gsd:plan-phase 160 --gaps`

---

_Verified: 2026-08-03T01:10:14Z_
_Verifier: the agent (gsd-verifier)_
