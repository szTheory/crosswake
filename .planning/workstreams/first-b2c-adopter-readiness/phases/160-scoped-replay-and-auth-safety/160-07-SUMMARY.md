---
phase: 160-scoped-replay-and-auth-safety
plan: "07"
subsystem: scoped replay idempotency
tags: [elixir, ecto, sqlite, replay, idempotency, auth-safety]
requires:
  - phase: 160-03
    provides: scoped host replay admission and transactional Study mutation seam
provides:
  - additive global idempotency tombstone for legacy review events
  - closed legacy, same-scope, and cross-scope replay decisions
  - normalized concurrent retry outcomes without database-detail leakage
affects: [scoped-replay, host-auth, phase-160-security-closeout]
tech-stack:
  added: []
  patterns: [global legacy tombstone, scope-aware closed idempotency decision, normalized SQLite retry race]
key-files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260802170000_restore_review_event_idempotency_guard.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
    - examples/phoenix_host/test/crosswake_example/local_first/study_test.exs
key-decisions:
  - "Legacy null-scope rows stay unassigned and globally authoritative rather than being backfilled from current replay context."
  - "A global mutation-ID race resolves only to accepted duplicate, closed scope conflict, or a generic transaction failure."
patterns-established:
  - "Query global idempotency state inside the mutation transaction before any domain effect."
  - "Map global and scoped uniqueness constraints to one stable non-echoing validation class."
requirements-completed: [SCOPE-01, SCOPE-03]
metrics:
  tasks_completed: 2
  files_modified: 4
status: complete
---

# Phase 160 Plan 07: Scoped Replay Idempotency Summary

Legacy accepted review mutations now remain global tombstones after scope migration, so replay cannot repeat their committed Study effect or infer a current account scope.

## Accomplishments

- Added an additive migration that restores `review_events.client_mutation_id` global uniqueness while retaining scoped uniqueness and leaving null legacy scopes untouched.
- Updated transactional idempotency lookup to distinguish new records, accepted legacy/same-scope duplicates, and non-echoing cross-scope conflicts before an effect begins.
- Normalized SQLite race failures through a bounded global re-read, yielding only accepted duplicate, closed conflict, or generic transaction failure.
- Added legacy-row, cross-scope, concurrent retry, and rollback-then-retry regression coverage.

## Task Commits

1. **Task 1: Keep one legacy accepted effect idempotent after scope migration**
   - `2614f373` — failing legacy tombstone regression
   - `ad1c7e3f` — additive guard and transactional global decision
2. **Task 2: Prove cross-scope and concurrent retries remain closed and atomic**
   - `d3b855dd` — race, conflict, and rollback regression coverage
   - `e909a843` — normalized race handling

## Verification

- `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/study_test.exs test/crosswake_example/local_first/sync_controller_test.exs` — 7 tests passed.
- `cd examples/phoenix_host && MIX_ENV=test mix run -e '… PRAGMA index_list(review_events) …'` — both `review_events_client_mutation_id_index` and `review_events_scope_ref_client_mutation_id_index` present.
- Re-ran the focused Study suite twice to confirm the concurrent retry regression is stable.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. The change adds no endpoint, auth path, file access pattern, or trust-boundary schema surface beyond the plan's explicitly mitigated review-event uniqueness guard.

## Next Phase Readiness

- The host replay path now preserves old global idempotency without fabricating legacy scope ownership.
- TODO-002 remains `unknown_blocking`; no adopter identity, route, account mapping, or device claim was introduced.

## Self-Check: PASSED

- Verified the corrective migration and all three modified source/test files exist.
- Verified all four TDD commits are present in git history.
