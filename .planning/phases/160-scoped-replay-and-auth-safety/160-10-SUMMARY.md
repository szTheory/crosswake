---
phase: 160-scoped-replay-and-auth-safety
plan: "10"
subsystem: browser scoped replay lifecycle
tags: [playwright, indexeddb, offline-island, replay, lifecycle, security]
requires:
  - phase: 160-05
    provides: fence-first scope lifecycle and stale-completion guards
  - phase: 160-09
    provides: scoped replay safety closure and inactive lifecycle context
provides:
  - Inactive and fenced online events that create no replay invocation or promise rejection
  - A private lease-aware online replay adapter that contains unexpected active failures
  - Browser regression coverage for no-work reconnects and contained active failures
affects: [scoped-replay, offline-island, first-adopter-proof, security-audit]
tech-stack:
  added: []
  patterns:
    - Private browser event adapters capture a current lease and own fire-and-forget promise handling.
    - Inactive lifecycle checks occur before replay invocation ownership is created.
key-files:
  created: []
  modified:
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
key-decisions:
  - "Online events capture an active scope-plus-epoch lease before replay and discard caught failure details."
  - "Inactive or fenced lifecycle state resolves as a silent no-op before requireActiveLease or activeFlush creation."
patterns-established:
  - "Event-boundary failure handling: only current lease failures may render existing paused copy; no error detail is logged or rendered."
requirements-completed: [SCOPE-02]
coverage:
  - id: D1
    description: "Inactive cold-launch and post-fence online events remain zero-work and error-free."
    requirement: SCOPE-02
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/offline_sync.spec.ts#inactive online replay is inert after launch and fence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Unexpected active listener failures are contained and stale fenced events cannot mutate status."
    requirement: SCOPE-02
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/offline_sync.spec.ts#active online replay catches unexpected failures without stale status effects"
        status: pass
    human_judgment: false
metrics:
  duration: 4m
  completed: 2026-08-02
  status: complete
---

# Phase 160 Plan 10: Inactive Online Replay Safety Summary

**Inactive browser reconnects are now inert, while active listener failures are caught at a lease-aware event boundary without exposing replay details.**

## Performance

- **Duration:** 4m
- **Started:** 2026-08-02T22:37:00Z
- **Completed:** 2026-08-02T22:41:09Z
- **Tasks:** 1/1
- **Files modified:** 2

## Accomplishments

- Made `flushOutbox` return before lease construction or invocation ownership when the lifecycle has no active scope-plus-epoch lease.
- Replaced the direct `online` listener with a private adapter that catches fire-and-forget replay failures and renders only existing paused copy when its captured lease remains current.
- Added deterministic Playwright coverage for cold-launch and post-fence zero-work reconnects, plus contained active storage failures.

## Task Commits

1. **Task 1: Trace an inactive online event to a zero-work no-op and catch active listener failures**
   - `3454190a` — `test(160-10): add inactive online replay regression`
   - `44bf89e1` — `fix(160-10): make online replay lifecycle-safe`

## Files Created/Modified

- `examples/phoenix_host/priv/static/offline_study.js` — adds inert active-lease detection and the private online replay adapter.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — proves inactive and fenced reconnects stay silent and active listener failures are caught.

## Decisions Made

- Online listener failures are deliberately discarded at the event boundary; only the existing calm paused status may be rendered under the captured current lease.
- The inactive predicate precedes `requireActiveLease`, `activeFlush`, storage reads, and network work so normal connectivity changes cannot acquire replay authority.

## Verification

- `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "inactive online replay is inert|active online replay catches unexpected failures|switch in flight|post-response fence|mid-batch disablement"` — PASS (6 tests)
- `npm --prefix examples/phoenix_host run proof:offline-island` — PASS (18 tests)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pre-existing `lib/crosswake/proof_lane/evidence.ex` unused-module-attribute compiler warning appeared while Playwright started its Phoenix web server. It is unrelated to this task and was not changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The full existing offline-island corpus passes with the new reconnect guards. Plan 160-11 can use the same-tree corpus as its final gate; TODO-002 and physical-device prerequisites remain `unknown_blocking`.

## Self-Check: PASSED

- Both modified runtime and Playwright files exist.
- Both TDD commits are present in Git history.
- No task-created stubs or skipped tests were found.

---
*Phase: 160-scoped-replay-and-auth-safety*
*Completed: 2026-08-02*
