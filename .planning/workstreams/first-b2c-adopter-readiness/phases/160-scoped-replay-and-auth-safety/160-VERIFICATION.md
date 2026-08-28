---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-03T03:04:53Z
status: passed
score: 39/39 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 39/39
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** Enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement.
**Verified:** 2026-08-03T03:04:53Z
**Status:** passed
**Re-verification:** Yes — after generated-host proof-session repair

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Cross-scope replay is impossible under tests. | ✓ VERIFIED | The cross-account Playwright regression leaves one legacy record quarantined, both scoped partitions empty, and records zero replay requests; the complete gate passed. |
| 2 | Raw answers never enter telemetry, doctor output, inspection, logs, aggregates, or evidence. | ✓ VERIFIED | `SafeObservation` uses closed allowlisted projections, and the fresh core privacy/evidence/doctor/inspection suite passed (119 tests). |
| 3 | `crosswake_sigra` adapts backend authority without making the WebView or shell token authority. | ✓ VERIFIED | Both sync aliases enter `:replay_api` and `ReplayAuth`; per-event `ReplayAdmission` obtains request-bound host authority. The Sigra contract suite passed (15 tests). |
| 4 | A disabled path preserves queued data and visibly fails closed. | ✓ VERIFIED | The browser proof suite, including the feature-disabled/retained-queue cases, passed (23 tests); controller admission returns a halted/blocked result before accepted-only deletion. |
| 5 | Logout and account switching stop replay, while stale work cannot mutate another scope. | ✓ VERIFIED | The scope/epoch lifecycle fence is exercised by the browser suite; legacy recovery now returns only `recovery_required` for retained unowned bytes. |
| 6 | Backend session, route, feature, Sigra, and domain authority are rechecked immediately before every mutation on both sync routes. | ✓ VERIFIED | Router wiring uses `ReplayAuth` for `/study/sync` and `/learnloop/sync`; `SyncController` calls `ReplayAdmission.authorize/4` before `Study.apply_one/3`. Phoenix-host tests passed (33 tests). |
| 7 | Nil-scope server history cannot grant accepted deletion authority to scoped replay. | ✓ VERIFIED | `Study.apply_one/3` and its race fallback `current_outcome/2` map `%ReviewEvent{scope_ref: nil}` to `:scope_conflict`; focused regressions passed in the fresh host suite. |
| 8 | Rapid input creates at most one mutation for one card while IndexedDB persistence is pending. | ✓ VERIFIED | `handleReview/1` synchronously owns and disables both controls before `queueMutation`; the rapid-rating Playwright regression passed in the complete gate. |

**Score:** 39/39 truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| Plan-declared artifacts | Substantive Phase 160 implementation and regression artifacts | ✓ VERIFIED | `verify.artifacts` reported all declared artifacts present and substantive across all 17 plans (no failed artifact records). |
| `lib/crosswake/offline/journal.ex`, `replay.ex`, `runtime.ex` | Scoped envelope, exact-scope journal order, lifecycle/epoch fence | ✓ VERIFIED | Exercised by the 119-test core gate and browser lifecycle proofs. |
| `examples/phoenix_host/priv/static/offline_study.js` | Scoped IndexedDB outbox, quarantine, recovery-required response, input ownership | ✓ VERIFIED | The source has no quarantine-to-scoped transaction; Playwright exercised account-switch, disablement, replay, and rapid-input behavior. |
| `examples/phoenix_host/lib/crosswake_example/local_first/{replay_auth,replay_admission,study,sync_controller}.ex` | Request-bound admission and scope-safe idempotency | ✓ VERIFIED | Both router aliases are wired through the request pipeline; 33 host tests passed. |
| `lib/crosswake/offline/safe_observation.ex` and egress consumers | Redacted operational/proof projections | ✓ VERIFIED | Closed projections are the only telemetry/doctor inputs; privacy/evidence tests passed. |
| `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` | Backend-authority adapter boundary | ✓ VERIFIED | 15 focused companion contract tests passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Journal.Entry.scope_ref` | `Replay.Request.scope_ref` | `request_for_entry/1` | ✓ WIRED | Required opaque scope is carried through the core contract tests. |
| Browser lifecycle lease | IndexedDB reads/sends/completions | exact `scope_ref` + epoch checks | ✓ WIRED | Browser switch/fence tests passed. |
| `/study/sync`, `/learnloop/sync` | `ReplayAuth` | shared `:replay_api` router pipeline | ✓ WIRED | Both routes explicitly use `fetch_session` then `ReplayAuth`. |
| `SyncController.sync_events/4` | `ReplayAdmission.authorize/4` → `Study.apply_one/3` | ordered per-event reducer | ✓ WIRED | Source invokes authorization before persistence; host request tests passed. |
| `legacy_mutations_quarantine` | `recoverLegacyMutations/1` | closed `recovery_required` outcome | ✓ WIRED | Source retains quarantine and browser test proves neither account receives a scoped record or request. |
| `Study.apply_one/3` | `current_outcome/2` | nil-scope conflict before status mapping | ✓ WIRED | Both initial and race paths deny `scope_ref: nil`; tests preserve the historical row. |

`verify.key-links` cannot score most plan links mechanically because their `from` fields name components rather than paths; manual source tracing and the executable suites above verify those links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Scoped browser outbox | `scope_ref`-partitioned records | IndexedDB `by_scope` index and exact keys | Yes | ✓ FLOWING |
| Legacy recovery | retained legacy bytes | `legacy_mutations_quarantine` only | Intentionally non-authoritative | ✓ QUARANTINED |
| Replay authority | session, route, flag, Sigra/domain decision | request-bound host callbacks on `Plug.Conn` | Yes, per event | ✓ FLOWING |
| Idempotency outcome | persisted `ReviewEvent` | same-scope row only | Yes; nil/different scope is denied | ✓ FLOWING |
| Operational egress | `SafeObservation` projection | closed field-by-field constructors | Yes, with no payload/scope fields | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete Phase 160 core, Sigra, Phoenix, browser, proof-lane, iOS-boundary, planning, format, coverage-seal, and diff gate | Recorded command in `160-VALIDATION.md`, rerun at 2026-08-03T03:04:53Z | 119 core + 15 Sigra + 33 Phoenix-host + 23 browser tests; all checks exited 0 | ✓ PASS |
| Generated-host session repair | `npm run proof:offline-island` plus `bash script/verify_phoenix_host_proof_lane.sh` within the complete gate | The repaired test-only request-bound session established before replay; the repository proof and isolated generated-host proof passed | ✓ PASS |
| Generated iOS boundary remains non-promoting | `bash script/verify_generated_ios_shell.sh --proof-lane` within complete gate | Required blocked/unavailable result observed; it was not treated as success | ✓ PASS |

### Probe Execution

No documented Phase 160 `scripts/*/tests/probe-*.sh` probe exists. The runnable Phase 160 proof is the Playwright offline-island suite, executed in the complete gate above.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SCOPE-01 | 01–04, 07–09, 11, 13–17 | Opaque scope on envelopes; scope-partitioned outbox. | ✓ SATISFIED | Exact-scope contracts and indexes pass; unscoped legacy data is retained only in quarantine. |
| SCOPE-02 | 01–05, 08, 10–11, 13–17 | Logout/switch stop replay; cross-scope replay fails closed. | ✓ SATISFIED | Account-switch and stale-worker browser proofs pass; the former legacy-account bypass is closed. |
| SCOPE-03 | 02–03, 05–09, 11–17 | Re-check backend session, route, and feature state before mutation. | ✓ SATISFIED | Request-bound `ReplayAuth`/admission sequence and Phoenix-host suite passed. |
| SCOPE-04 | 03, 08, 11, 13–17 | Exclude raw answers from operational and proof egress. | ✓ SATISFIED | Safe-projection code and the fresh privacy/evidence/inspection tests passed. |
| SCOPE-05 | 02–03, 06, 08, 11, 13–17 | Sigra is backend-authority adapter; no core credential/token authority. | ✓ SATISFIED | Typed companion boundary and all 15 Sigra contract tests passed. |

All five Phase 160 requirement IDs appear in plan frontmatter; none is orphaned. No later roadmap phase specifically owns a Phase 160 scope/auth gap, so no items were deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No Phase 160 `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty rendering stub found in inspected implementation artifacts. | ℹ️ INFO | No completion-debt blocker. |

The full gate reported third-party dependency advisories while resolving dependencies. They are outside this phase’s scoped-replay implementation and do not contradict these five requirements; they should be handled by the project’s dependency/security workflow, not by silently changing this verdict.

### Review Advisory Assessment

| Advisory | Assessment | Effect on Phase 160 verdict |
| --- | --- | --- |
| `160-REVIEW.md` WR-01: a fence during a pending IndexedDB save can leave rating controls disabled. | Confirmed by source: the stale-lease early return bypasses the reset. It retains the queued data and prevents stale UI/domain mutation, so it does not violate scope partitioning, fail-closed replay, request authority, redaction, or Sigra ownership. It is a recoverability/UI warning that deserves a regression and `finally` cleanup. | ⚠️ Non-blocking; does not invalidate SCOPE-01..05 evidence. |
| `160-REVIEW-REPAIR.md` WR-01: generated proof fixture stores request/page in module globals. | Confirmed by source. The current Phoenix proof configuration sets `fullyParallel: false` and `workers: 1`; the fresh current-tree generated-host proof is therefore invocation-isolated and valid. A future host that changes this runner to parallel execution could weaken the fixture’s proof attribution, so the fixture should eventually use a per-invocation factory. | ⚠️ Non-blocking for the current serial proof; does not invalidate SCOPE-01..05 or the observed repair. |

### Human Verification Required

None. All Phase 160 must-haves are automated and were exercised by the current-tree gate.

---

_Verified: 2026-08-03T03:04:53Z_
_Verifier: the agent (gsd-verifier)_
