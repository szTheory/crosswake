---
phase: 160-scoped-replay-and-auth-safety
verified: 2026-08-02T22:54:34Z
status: gaps_found
score: 34/35 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 21/26
  gaps_closed:
    - "Host admission uses the exact bounded opaque-scope grammar before authority callbacks."
    - "Persisted rejected replay outcomes remain rejected and out of the accepted acknowledgement prefix."
    - "Inactive and fenced online events are inert and caught at the event boundary."
  gaps_remaining: []
  regressions:
    - "Client-supplied persistence status is admitted and written by the server-side replay path."
gaps:
  - truth: "Replay re-checks backend session authority, route authorization, and server-side feature state before applying queued mutations."
    status: failed
    reason: "The host validates only required event keys, then forwards the original browser map to a changeset that permits the persisted outcome field. A browser can therefore choose a rejected persisted outcome after all authority checks pass."
    artifacts:
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex"
        issue: "valid_event/1 accepts maps with unrecognized keys."
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/study.ex"
        issue: "apply_one/3 forwards the untrusted event map to persistence."
      - path: "examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex"
        issue: "changeset/2 permits the persisted outcome field from those attributes."
    missing:
      - "Require the exact three replay-wire keys at admission."
      - "Persist a server-owned allowlist of replay fields and assign the outcome/status server-side."
      - "Add an integration regression proving an extra outcome/status field is denied or ignored and cannot change the persisted outcome."
---

# Phase 160: Scoped Replay and Auth Safety Verification Report

**Phase Goal:** Enforce account-scoped outboxes, payload redaction, backend reauthorization, auth continuity, and server-side disablement.
**Verified:** 2026-08-02T22:54:34Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 160-09 through 160-11

## Goal Achievement

The earlier scope-grammar, rejected-row, and inactive-online defects are repaired and their automated regressions pass. The goal is nevertheless **not achieved**: a browser-supplied replay event can set the persisted outcome/status because server admission permits extra keys and the transaction forwards them to an accepting changeset. This is a reachable server-authority failure, not an adopter-instance unknown.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Scoped outboxes use one bounded opaque reference; no production all-scope operation exists. | ✓ VERIFIED | Core and host use the shared anchored grammar; the 18-test browser corpus proves exact-partition reads, recovery, and cross-scope retention. |
| 2 | Logout/switch fencing and reconnect lifecycle prevent cross-scope replay. | ✓ VERIFIED | `offline_study.js` fences leases before activation; `replayOnOnline` is inert without a lease and catches active failures. Browser regressions pass. |
| 3 | Every queued mutation is reauthorized by backend session, route, feature, Sigra, and domain authority before server-side application. | ✗ FAILED | `valid_event/1` accepts extra keys; the server then persists the original event map, including a browser-selected outcome/status. The independent read-only admission probe reported `extra-field-admitted`. |
| 4 | Operational and retained proof egress excludes raw replay payloads and authority facts. | ✓ VERIFIED | SafeObservation projection validation and success-only egress are exercised by 82 core/privacy tests; no raw transport map is passed to telemetry, Logger, Doctor, or retained evidence. |
| 5 | Sigra remains a typed backend authority adapter; Crosswake core/browser have no credential or token authority. | ✓ VERIFIED | Guarded Sigra contract and typed host invocation pass 15 companion tests and 18 host tests. |

**Score:** 34/35 PLAN must-have truths verified (0 present-but-behavior-unverified). The single failed truth blocks SCOPE-03 and therefore the phase goal.

### Must-Have Reconciliation

All 35 plan-frontmatter truths were inspected; 34 are supported by current source plus the focused automated suites. The failed truth is Plan 02’s atomic server-side application contract and also contradicts the roadmap SCOPE-03 requirement. Plans 09–11 repair the three prior verification failures and remain verified.

| Plan | Truths | Verdict |
| --- | ---: | --- |
| 160-01 | 3 | ✓ Verified — required scoped transport, inert lifecycle, serial retained drain. |
| 160-02 | 4 | ✗ Partial — authority ordering and transaction wiring exist, but client-controlled persisted status invalidates server-owned application authority. |
| 160-03 | 4 | ✓ Verified — closed observation/evidence projections and non-passing prerequisite boundaries. |
| 160-04 | 3 | ✓ Verified — legacy quarantine and exact-lease recovery. |
| 160-05 | 3 | ✓ Verified — abort/fence ordering, stale-completion guards, halted suffix. |
| 160-06 | 3 | ✓ Verified — typed Sigra authority and closed denial projection. |
| 160-07 | 3 | ✓ Verified — global legacy tombstone and scoped conflict handling. |
| 160-08 | 3 | ✓ Verified — public projection revalidation and success-only egress. |
| 160-09 | 3 | ✓ Verified — full opaque grammar and rejected-row retention. |
| 160-10 | 3 | ✓ Verified — inactive online no-op and contained active failure. |
| 160-11 | 3 | ✓ Verified — fresh final-tree ledger preserves TODO-002 and non-passing device/security boundaries. |

### Required Artifacts

All 36 declared artifacts exist and are substantive. `verify.artifacts` reported 36/36 passing presence/substance checks; manual wiring and data-flow checks below determine the final result.

| Artifact group | Status | Details |
| --- | --- | --- |
| Core journal/replay/runtime and browser offline island | ✓ VERIFIED | Required opaque scope passes from journal to replay and into exact IndexedDB partitions; lifecycle data is read from the active lease. |
| Phoenix admission, Study transaction, SyncController, and idempotency migrations | ✗ UNSAFE | Components are connected and tested, but untrusted event fields reach the persistence changeset. |
| Sigra companion and host admission tests | ✓ VERIFIED | Host builds typed route/auth evidence immediately before the guarded companion call. |
| SafeObservation, telemetry, Doctor, proof/privacy tests | ✓ VERIFIED | Data enters a bounded projection before each operational egress. |
| Browser E2E suite and validation ledger | ✓ VERIFIED | Real browser storage/request/response paths run; current ledger records the post-repair suite and preserves non-passing external prerequisites. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Journal entry scope | Replay request | direct required copy | ✓ WIRED | `request_for_entry/1` constructs a scope-required request. |
| Browser active lease | IndexedDB/request/completion/UI | exact scope-plus-epoch checks | ✓ WIRED | Reads, deletes, response status, and reconnect adapter are lease-fenced; 18 browser tests pass. |
| SyncController | ReplayAdmission | per-event authorize before `Study.apply_one/3` | ✓ WIRED | `sync_events/4` calls admission before each transaction. |
| ReplayAdmission | Study persistence | admitted event map | ✗ UNSAFE | The connection exists, but it carries an unallowlisted client map into persistence. |
| Host typed evidence | Sigra replay decision | RouteEntry and AuthContext | ✓ WIRED | Default construction and closed denial are exercised by companion/host tests. |
| SafeObservation | telemetry, Logger, Doctor, proof | validate then success-only projection | ✓ WIRED | Consumers pattern-match `{:ok, projection}`; forged-struct tests prove zero egress. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Browser outbox | scoped mutation records | IndexedDB `by_scope` index | Exact active partition | ✓ FLOWING |
| Replay request | scope and replay wire fields | current lease and queued record | Request reaches Phoenix in browser proof | ✓ FLOWING |
| Phoenix persistence | admitted event attributes | untrusted request map | Includes fields outside the wire contract | ✗ UNSAFE |
| Operational observations | bounded projection | `SafeObservation.validate/1` | Only declared projection fields reach consumers | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core scope/lifecycle/privacy contracts | `MIX_ENV=test mix test …phase160_scoped_replay_privacy_test.exs` | 82 tests, 0 failures | ✓ PASS |
| Typed Sigra replay contract | `cd packages/crosswake_sigra && mix deps.get && mix test …contracts_test.exs` | 15 tests, 0 failures | ✓ PASS |
| Phoenix scope/admission/idempotency contracts | `cd examples/phoenix_host && MIX_ENV=test mix test …local_first…` | 18 tests, 0 failures | ✓ PASS — missing an extra-field persistence case. |
| Offline-island lifecycle/replay flow | `cd examples/phoenix_host && npm run proof:offline-island` | 18 tests, 0 failures | ✓ PASS |
| Admission rejects client-controlled persisted outcome | read-only `MIX_ENV=test mix run -e …` | `extra-field-admitted` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SCOPE-01 | 01, 02, 04, 07–09, 11 | Opaque scope and scoped outbox partitioning | ✓ SATISFIED | Exact grammar/admission, partition, quarantine, and idempotency coverage pass. |
| SCOPE-02 | 01, 05, 08, 10–11 | Logout/switch stop replay and cross-scope replay fails closed | ✓ SATISFIED | Fence, stale-completion, inactive online, and halted-drain browser cases pass. |
| SCOPE-03 | 02, 05–11 | Re-check backend authority and server feature state before apply | ✗ BLOCKED | Client controls a persisted replay outcome after admission; the server does not exclusively own the applied outcome. |
| SCOPE-04 | 03, 08, 11 | Raw payloads excluded from operational/proof egress | ✓ SATISFIED | Forged observation and every-egress tests pass. |
| SCOPE-05 | 02, 03, 06, 08, 11 | Sigra holds backend authority; core has no credential/token authority | ✓ SATISFIED | Typed contracts and host integration pass; projection omits authority details. |

Every Phase 160 requirement in `REQUIREMENTS.md` is claimed by at least one plan; no orphaned requirement IDs were found.

### Review Reconciliation and Anti-Patterns

| Finding | Verdict | Impact |
| --- | --- | --- |
| WR-01 — client controls persisted replay outcome | 🛑 BLOCKER, confirmed | Directly blocks SCOPE-03 and phase completion. |
| WR-02 — card fields interpolate into `innerHTML` | ⚠️ WARNING, confirmed | Current cards are local fixtures, but this creates a stored-markup execution sink if card content later becomes host/cache-controlled. Replace dynamic interpolation with DOM nodes and `textContent` before widening card sources. |
| WR-03 — unused evidence barrier attribute | ⚠️ WARNING, confirmed | All focused commands emit the compiler warning. It is not a Phase 160 functional blocker, but the declared attribute and runtime lookup should share one key or the attribute should be removed. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in Phase 160 implementation artifacts. The independent review warnings above were investigated rather than accepted from the review narrative.

### Boundary Preservation

TODO-002 and adopter-instance route, scope, flag, session, adapter, and physical-device inputs remain `unknown_blocking`. Generated iOS/device output and independent security remain non-passing. These boundaries are preserved; the reported gap is a deterministic host-code defect and is not deferred to a later phase.

## Gaps Summary

One blocker prevents goal achievement: the server must not let replay input select its persisted outcome. Tighten admission to the exact wire schema, persist only an allowlisted server-owned attribute map, add an automated hostile-extra-field regression, then rerun the focused Phoenix and full Phase 160 gates. No human verification or UAT is appropriate because this is fully automatable.

**Next action:** Escalation Gate — revise the host replay admission/persistence contract and re-verify.

**Next command:** `/gsd:plan-phase 160 --gaps`

---

_Verified: 2026-08-02T22:54:34Z_
_Verifier: the agent (gsd-verifier)_
