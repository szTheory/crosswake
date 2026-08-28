---
phase: 160-scoped-replay-and-auth-safety
plan: "01"
subsystem: offline replay safety
tags: [elixir, indexeddb, playwright, scope-ref, lifecycle-fence]
requires:
  - phase: 159-host-reusable-proof-lane
    provides: Phoenix host offline-island proof lane
provides:
  - Required bounded opaque scope references on journal and replay transport contracts
  - Exact-scope browser outbox partitions and inactive-by-default lifecycle storage
  - Monotonic epoch fencing for scope changes and stale completions
affects: [160-02, replay-admission, first-adopter-proof]
tech-stack:
  added: []
  patterns: [scope-plus-epoch lease, compound IndexedDB partition key, fail-closed opaque scope validation]
key-files:
  created: []
  modified:
    - lib/crosswake/offline/journal.ex
    - lib/crosswake/offline/replay.ex
    - lib/crosswake/offline/runtime.ex
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
key-decisions:
  - "Opaque scope refs are versioned, bounded, and validated without echoing rejected values."
  - "Browser replay starts inert and requires an exact scope-plus-epoch lease before storage, send, completion, or UI mutation."
patterns-established:
  - "Scope-bound replay: transport copies scope_ref directly; browser persistence addresses only a compound scope/local key."
  - "Fence-first lifecycle: invalidation increments epoch before a replacement scope may activate."
requirements-completed: [SCOPE-01, SCOPE-02]
coverage:
  - id: D1
    description: Scope-required journal/replay contracts and exact-scope IndexedDB partitioning
    requirement: SCOPE-01
    verification:
      - kind: integration
        ref: mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs
        status: pass
      - kind: e2e
        ref: examples/phoenix_host/e2e/offline_sync.spec.ts#exact scope storage leaves a retained second partition untouched
        status: pass
    human_judgment: false
  - id: D2
    description: Inert relaunch, scope transition fencing, stale completion rejection, and retained blocked work
    requirement: SCOPE-02
    verification:
      - kind: integration
        ref: mix test test/crosswake/offline/runtime_test.exs
        status: pass
      - kind: e2e
        ref: examples/phoenix_host/e2e/offline_sync.spec.ts#switch in flight keeps an old completion from deleting or updating the new scope
        status: pass
    human_judgment: false
duration: 12m
completed: 2026-08-02
status: complete
---

# Phase 160 Plan 01: Scoped Replay and Auth Safety Summary

**Opaque scope-bound replay contracts, compound IndexedDB partitions, and epoch-fenced browser lifecycle proof for the first-adopter offline island.**

## Performance

- **Duration:** 12m
- **Tasks:** 2/2
- **Files modified:** 9

## Accomplishments

- Made every Journal entry and Replay request carry a required versioned opaque scope reference, preserving it only in sensitive transport serialization.
- Migrated new browser outbox writes to exact compound `(scope_ref, local_ref)` identity and proved a second retained partition is unchanged.
- Added inert-on-launch scope lifecycle persistence, monotonic epoch leases, fence-first scope transitions, and stale-completion protection.
- Pinned serial blocked-drain retention and learner-facing paused/attention status behavior through focused runtime and Playwright tests.

## Task Commits

1. **Task 1: Trace one exact-scope entry through transport and deterministic browser storage** — `2fd2ad74`, `e72fc013`
2. **Task 2: Fence relaunch, logout, account switching, and ordered exact-scope drain** — `cd2affff`, `eade7e4d`
3. **Follow-up fail-closed repair** — `22380a5d`

## Files Created/Modified

- `lib/crosswake/offline/journal.ex` — validates and carries opaque scope refs.
- `lib/crosswake/offline/replay.ex` — copies validated scope refs into sensitive replay wire maps.
- `lib/crosswake/offline/runtime.ex` — supplies closed lifecycle, lease, and ordered-drain primitives.
- `examples/phoenix_host/priv/static/offline_study.js` — stores new mutations in exact scope partitions and fences stale callbacks.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — proves inactive relaunch and two-scope switch behavior.

## Decisions Made

- Scope values are validated as opaque bounded transport tokens only; Crosswake derives no account or route meaning from them.
- Browser authority is a scope-plus-epoch lease. A replacement activation happens only after the previous lease has been fenced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing and malformed direct replay requests did not share the stable scope failure**
- **Found during:** Final contract verification
- **Fix:** Reused the Journal opaque-scope validator for both omitted and malformed Journal/Replay construction.
- **Files modified:** `lib/crosswake/offline/journal.ex`, `lib/crosswake/offline/replay.ex`, related tests
- **Verification:** Focused Journal and Replay suite passes.
- **Committed in:** `22380a5d`

**Total deviations:** 1 auto-fixed (Rule 1).

## Issues Encountered

The existing Playwright helper opened IndexedDB at the prior schema version; it was updated to use version 3 and to query the exact scope index. This was necessary test-harness migration for the scoped schema.

## User Setup Required

None — all verification ran against the existing Phoenix host proof lane.

## Next Phase Readiness

Plan 02 can consume scope-required sensitive replay requests and the active scope-plus-epoch lifecycle boundary. TODO-002 remains `unknown_blocking`; no adopter-specific route, account, retention, encryption, or device claim was inferred.

## Verification

- `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs test/crosswake/offline/runtime_test.exs` — passed (9 tests).
- `npm run proof:offline-island -- --grep "offline rating queues|exact scope storage|inactive relaunch|switch before send|switch in flight|ordered blocked drain"` — passed (5 focused browser tests).

## Self-Check: PASSED

- Required implementation files and atomic task commits are present.
- No known stubs, skipped tests, or unrun planned verification remain.
