---
phase: 160-scoped-replay-and-auth-safety
plan: "06"
subsystem: auth
tags: [elixir, sigra, phoenix, replay-admission, fail-closed]
requires:
  - phase: 160-03
    provides: scoped host replay admission ordering
provides:
  - typed Sigra replay decision projection with a closed denial result
  - host-owned default RouteEntry and AuthContext construction per replay event
affects: [scoped-replay, host-auth, phase-160-security-closeout]
tech-stack:
  added: []
  patterns: [typed authority boundary, closed replay denial, host-owned auth evidence]
key-files:
  created: []
  modified:
    - packages/crosswake_sigra/lib/crosswake/companions/sigra.ex
    - packages/crosswake_sigra/test/crosswake/companions/sigra/contracts_test.exs
    - examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex
    - examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
key-decisions:
  - "Replay admission requires typed RouteEntry and validated AuthContext; all other inputs project to sigra_denied."
  - "The Phoenix host constructs synthetic fixture authority privately for each default replay event and never returns it to callers."
patterns-established:
  - "Optional companion authority returns only :allow or {:deny, :sigra_denied} across the replay boundary."
  - "Host default replay paths resolve typed authority immediately before domain authorization."
requirements-completed: [SCOPE-03, SCOPE-05]
coverage:
  - id: D1
    description: Sigra replay admission denies untyped, malformed, and exceptional authority inputs.
    requirement: SCOPE-03
    verification:
      - kind: unit
        ref: packages/crosswake_sigra/test/crosswake/companions/sigra/contracts_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Phoenix default replay admission passes typed host authority to Sigra and stops denied events before domain authorization.
    requirement: SCOPE-05
    verification:
      - kind: integration
        ref: examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-08-02
status: complete
---

# Phase 160 Plan 06: Scoped Sigra Replay Admission Summary

**Typed Sigra replay admission now fails closed, while the Phoenix host supplies private current route and auth evidence on every default replay event.**

## Performance

- **Duration:** 15 min
- **Completed:** 2026-08-02T19:06:00Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Restricted `Sigra.replay_decision/3` to a real `RouteEntry`, a validated `AuthContext`, and keyword options; every other result becomes `{:deny, :sigra_denied}`.
- Preserved evaluator behavior for valid typed evidence while collapsing malformed data and evaluator failures without exposing authority facts.
- Replaced the example host’s nil-backed default Sigra path with private typed route and auth-context builders, retaining only route data in returned admission authority.
- Added no-callback default allow/deny tests plus pre-domain denial checks for missing evidence.

## Task Commits

1. **Task 1: Make Sigra replay projection deny every non-typed authority input** - `968e68ab` (test), `21cc110f` (feat)
2. **Task 2: Feed current typed host authority into the production default path** - `6b823d15` (test), `240988fe` (feat)

## Files Created/Modified

- `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` - typed, validated replay decision facade with closed failure projection.
- `packages/crosswake_sigra/test/crosswake/companions/sigra/contracts_test.exs` - typed-input, invalid-input, and closed-output companion proof.
- `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` - private host route/AuthContext construction and default Sigra call.
- `examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs` - default-path allow/deny and no-domain-on-denial integration proof.

## Decisions Made

- Replay authority never reaches Crosswake core or browser-facing admission output; the host retains it only while evaluating the event.
- The existing callback seams remain for tests, but the no-callback path cannot skip typed Sigra authority.

## Verification

- `cd packages/crosswake_sigra && mix test test/crosswake/companions/sigra/contracts_test.exs` — 15 tests passed.
- `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/sync_controller_test.exs` — 9 tests passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Focused test commands retain a pre-existing warning for an unused `@after_digest_barrier` attribute in `lib/crosswake/proof_lane/evidence.ex`; it is unrelated to this plan and was not changed.

## Next Phase Readiness

- The remaining Phase 160 security work can rely on a fail-closed, host-owned Sigra replay boundary.
- TODO-002 remains `unknown_blocking`; no concrete adopter route, identity, or device claim was added.

## Self-Check: PASSED

- All four modified implementation/test files exist.
- All four TDD commits are present in git history.
