---
phase: 160-scoped-replay-and-auth-safety
plan: "05"
subsystem: browser scoped replay lifecycle
tags: [playwright, indexeddb, replay, scope-fence, fail-closed]
requires:
  - phase: 160-04
    provides: legacy outbox quarantine and scoped recovery boundary
provides:
  - invocation-owned abortable scoped replay flushes
  - post-await lease guards for browser storage and learner status
  - closed halted-batch parsing with retained paused suffixes
affects: [160-08, first-adopter-proof, scoped-replay-validation]
tech-stack:
  added: []
  patterns: [fence-first lease revocation, invocation-owned cancellation, accepted-prefix response validation]
key-files:
  created: []
  modified:
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
decisions:
  - "Fence-first transitions revoke browser scope authority before awaiting lifecycle persistence or an owned flush."
  - "A successful halted envelope may delete only a validated ordered accepted prefix; all other response shapes retain queued work."
metrics:
  duration: "~18m"
  tasks: 2
  files: 2
  completed: "2026-08-02"
status: complete
---

# Phase 160 Plan 05: Scoped Replay Lifecycle Summary

Fence-first browser replay now settles only its own abortable flush, and server-halted batches retain their unaccepted suffix in a calm paused state.

## Accomplishments

- Replaced the shared flushing flag with an invocation-owned lease, `AbortController`, storage transaction, and promise so an old finally block cannot clear a newer worker.
- Revoked active scope authority before the first fence await, then aborted and settled the old invocation before allowing a new scope to activate.
- Guarded every asynchronous success, parse, network, non-success, deletion, count, and status continuation with the captured lease.
- Added a closed replay-envelope classifier that validates ordered accepted prefixes, closed halt classes, and rejected records before any deletion.
- Kept malformed, contradictory, blocked, and halted suffix records intact, with the existing task-oriented paused copy and no retry loop.

## Task Commits

1. **Task 1: Revoke and settle an in-flight flush before activating another scope**
   - `8e0bfd0f` — RED tests for delayed success and denial transitions.
   - `1fc93591` — invocation-owned abortable flush and fence settlement.
2. **Task 2: Treat a partial halted batch as retained paused work**
   - `7ac335f5` — RED tests for partial halt and malformed envelope handling.
   - `0b4e9ce3` — closed halted response classifier and retained paused suffix.

## Verification

- `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "post-response fence blocks old success side effects|post-response fence blocks old denial status"` — passed (2 tests).
- `npm --prefix examples/phoenix_host run proof:offline-island -- --grep "mid-batch disablement retains halted suffix|malformed halted response fails closed"` — passed (2 tests).
- `npm --prefix examples/phoenix_host run proof:offline-island` — passed (16 tests).
- `git diff --check` — passed.

## Decisions Made

- Browser cancellation is private lifecycle ownership: fencing aborts and awaits only the captured invocation, while server admission remains independently authoritative.
- The browser recognizes only a bounded halt vocabulary and never uses a malformed response as authorization to delete queued work.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Surface Scan

No new endpoint, authentication authority, file access pattern, or trust-boundary schema was introduced. The existing browser-to-host replay boundary now fails closed across delayed completions and malformed typed responses.

## Self-Check: PASSED

- Required implementation and Playwright regression files exist.
- Task commits `8e0bfd0f`, `1fc93591`, `7ac335f5`, and `0b4e9ce3` are present in git history.
- No stub, skipped test, or unrun planned verification remains.
