---
phase: 160-scoped-replay-and-auth-safety
plan: "15"
subsystem: auth
tags: [phoenix, plug-session, playwright, replay, indexeddb]
requires:
  - phase: 160-14
    provides: Request-bound ReplayAuth seam with fail-closed production defaults
provides:
  - Compile-time-gated signed test session and current replay authority for browser proof
  - Lease-guarded immediate-online replay failure containment
affects: [160-16, replay-auth, offline-island-proof]
tech-stack:
  added: []
  patterns: [test-only signed host session, current-lease replay dispatch]
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex
    - examples/phoenix_host/lib/crosswake_example/e2e/replay_session_controller.ex
  modified:
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
key-decisions:
  - "Browser replay proof uses a compile-time-gated signed test session and request-bound test authority; production remains fail closed."
  - "Immediate online review replay enters replayOnOnline so current-lease failures render the existing paused state without unhandled rejections."
patterns-established:
  - "Test-only replay authority derives an opaque scope and typed Sigra auth context from signed host session state for every event."
  - "Durable local writes dispatch online replay only through replayOnOnline's lease-aware catch path."
requirements-completed: [SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05]
coverage:
  - id: D1
    description: Authenticated browser replay is test-session-bound and denies anonymous, cleared, switched, and revoked sessions before persistence.
    requirement: SCOPE-03
    verification:
      - kind: e2e
        ref: "npm run proof:offline-island -- --grep 'fully authorized scoped Study event|anonymous|logged-out|account switch|revoked session'"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e"
        status: pass
    human_judgment: false
  - id: D2
    description: Immediate-online worker storage rejection retains the exact-scope queue and renders paused without browser errors.
    requirement: SCOPE-02
    verification:
      - kind: e2e
        ref: "e2e/offline_sync.spec.ts#immediate online submit failure retains queued work without an unhandled rejection"
        status: pass
      - kind: e2e
        ref: "npm run proof:offline-island"
        status: pass
    human_judgment: false
duration: 22min
completed: 2026-08-03
status: complete
---

# Phase 160 Plan 15: Authenticated Browser Replay and Failure Containment Summary

**Signed test-only Phoenix sessions now drive request-bound replay proof, while immediate online replay failures stay paused with their exact-scope work retained.**

## Accomplishments

- Added a compile-time-gated `/_e2e/replay-session` controller and signed-session authority adapter; production replay configuration remains fail closed.
- Updated the full offline-island browser corpus to establish session authority and prove anonymous, logout, account-switch, and revoked-session denial before persistence.
- Routed immediate online review submissions through `replayOnOnline()` and pinned a deterministic IndexedDB worker failure with paused UI, retained work, and no browser errors.

## Verification

- `MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e` — 33 tests, 0 failures.
- `npm run proof:offline-island -- --grep "fully authorized scoped Study event|anonymous|logged-out|account switch|revoked session"` — 2 passed.
- `npm run proof:offline-island -- --grep "immediate online submit failure retains queued work without an unhandled rejection"` — 1 passed.
- `npm run proof:offline-island` — 22 passed.

## Task Commits

1. Task 1 RED — `954e1dfd` test: require replay session in browser proof.
2. Task 1 GREEN — `6007c536` feat: add test-only replay authority.
3. Task 2 RED — `2bf5832b` test: cover immediate replay failure.
4. Task 2 GREEN — `aad1c9f2` feat: guard immediate online replay.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Made the configured test adapter safe for direct unit-test connections.
- **Found during:** Task 1 verification.
- **Issue:** Unfetched direct `Plug.Conn` values raised while the configured E2E adapter read session state, and existing unit cases unintentionally used the E2E authority default.
- **Fix:** Treated unfetched session state as missing authority and isolated the no-authority unit setup from the test-only configured adapter.
- **Files modified:** `replay_authority.ex`, `replay_admission_test.exs`.
- **Verification:** Focused 33-test ExUnit suite passed.
- **Committed in:** `6007c536`.

## Known Stubs

None.

## Next Phase Readiness

Plan 160-16 can perform the final warning-clean reconciliation. The pre-existing `@after_digest_barrier` warning is recorded in `deferred-items.md` and was not changed outside this plan's scope.

## Self-Check: PASSED

All declared files exist and all four TDD commits are present in Git history.
