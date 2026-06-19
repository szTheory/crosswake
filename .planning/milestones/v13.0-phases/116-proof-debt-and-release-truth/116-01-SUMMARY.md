---
phase: 116-proof-debt-and-release-truth
plan: "01"
subsystem: testing
tags: [phoenix-host, flashcards, chimeway, sqlite, proof-debt]
requires:
  - phase: 115-closeout-verifier-honesty-ledger-backlog-doc-truth
    provides: v12 closeout and proof-honesty baseline
provides:
  - TODO-001 resolved by targeted example-host test repairs
  - Schema-aligned Flashcards fixtures and tests
  - Deterministic Chimeway registry notification-open test data
affects: [phase-118-quick-start, example-host-proof, public-proof-path]
tech-stack:
  added: []
  patterns:
    - Persistent SQLite example-host tests use run-unique fixture values.
    - Public proof debt is resolved only after targeted proof commands pass.
key-files:
  created: []
  modified:
    - examples/phoenix_host/test/support/flashcards_fixtures.ex
    - examples/phoenix_host/test/crosswake_example/flashcards_test.exs
    - examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs
    - .planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md
    - .planning/STATE.md
key-decisions:
  - "Resolved TODO-001 by repairing both known debts rather than excluding them from public proof commands."
  - "Kept repairs scoped to tests and fixtures; no Flashcards or Chimeway production behavior changed."
patterns-established:
  - "Schema-backed example tests assert current field names instead of legacy attrs."
  - "SQLite-backed proof tests avoid fixed refs across persistent test runs."
requirements-completed: [PROOF-01]
duration: 2 min
completed: 2026-06-18
status: complete
---

# Phase 116 Plan 01: Proof Debt Repair Summary

**Schema-aligned Flashcards tests and deterministic Chimeway notification-open fixtures remove TODO-001 from the public proof path**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-18T20:08:00Z
- **Completed:** 2026-06-18T20:09:17Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Updated Flashcards fixtures and tests to use `front_text` and `back_text`, matching the current schema.
- Made Flashcards list assertions persistent-DB safe by proving the created deck is present rather than assuming the database is empty.
- Made Chimeway registry notification-open tests sequential and run-unique across binding, subject, installation, token, app identity, audit, and open intent refs.
- Marked `TODO-001` resolved only after the combined targeted proof command passed.

## Task Commits

1. **Task 1: Fix Flashcards schema drift and persistent-DB assumptions** - `2690648` (`test`)
2. **Task 2: Make Chimeway registry notification-open tests deterministic and reconcile TODO truth** - `241fd2d` (`test`)

## Files Created/Modified

- `examples/phoenix_host/test/support/flashcards_fixtures.ex` - Emits unique `front_text` / `back_text` card attrs and unique deck text.
- `examples/phoenix_host/test/crosswake_example/flashcards_test.exs` - Asserts current schema fields and persistent-DB-safe deck listing.
- `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` - Runs sequentially and uses run-unique refs for SQLite-safe setup.
- `.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md` - Records Phase 116 resolution and verification.
- `.planning/STATE.md` - Removes TODO-001 from pending blockers and records the resolution.

## Verification

- `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs` - passed, 4 tests, 0 failures.
- `cd examples/phoenix_host && mix test test/crosswake_example/chimeway/registry_notification_open_test.exs` - passed, 6 tests, 0 failures.
- `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs test/crosswake_example/chimeway/registry_notification_open_test.exs` - passed, 10 tests, 0 failures.

## Decisions Made

- Resolved the Chimeway path with fixture/test isolation, so the D-04 exclusion fallback was not needed.
- Left example-host SQLite database artifacts unstaged; targeted test runs modified them as local runtime data, not plan output.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 116-02 can now update public proof and release-truth docs without carrying known `TODO-001` example-host failures into adopter-facing instructions.

---
*Phase: 116-proof-debt-and-release-truth*
*Completed: 2026-06-18*
