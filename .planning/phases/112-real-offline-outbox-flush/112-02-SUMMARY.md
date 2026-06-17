---
phase: 112-real-offline-outbox-flush
plan: "02"
subsystem: phoenix-host-liveview
tags: [de-mock, liveview, elixir, outbox, ci-honesty]
dependency_graph:
  requires: []
  provides: [de-mocked-study-session-live]
  affects: [examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex]
tech_stack:
  added: []
  patterns: [liveview-assign-cleanup, mix-elixirc-paths]
key_files:
  created: []
  modified:
    - examples/phoenix_host/lib/crosswake_example/local_first/study_session_live.ex
    - examples/phoenix_host/mix.exs
decisions:
  - Remove sync_outbox mock entirely rather than relabeling — server-side Elixir list misrepresents IndexedDB client outbox
  - Fix elixirc_paths in mix.exs to load test/support so suite can run
metrics:
  duration: "198s"
  completed: "2026-06-17T22:00:21Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 112 Plan 02: Remove sync_outbox Mock Summary

**One-liner:** Deleted the server-side Elixir-list outbox mock from StudySessionLive — sync_outbox handler, Simulate Network Sync button, and outbox/sync_result assigns removed; mount now assigns only current_card_id: 1.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Remove the sync_outbox mock, button, and outbox/sync_result assigns | c43dac1 | study_session_live.ex |
| 2 | Verify the suite stays green and compiles warning-free | 348d1f8 | mix.exs |

## Verification

- `grep -nE "sync_outbox|sync_result|:outbox|@outbox|Simulate Network Sync" study_session_live.ex` returns nothing — PASS
- `grep -rnE "sync_outbox|sync_result|:outbox|@outbox" examples/phoenix_host/test/` returns nothing — PASS
- `mix compile --warnings-as-errors` exits 0 — no unused-variable warning from removed event binding — PASS
- `mix test` runs 18 tests; the 3 failures are pre-existing FlashcardsTest schema drift (front vs front_text, create_progress vs upsert_progress) unrelated to this plan's de-mocking — see Deviations

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing elixirc_paths in mix.exs**
- **Found during:** Task 2
- **Issue:** `mix test` failed with `CompileError: module CrosswakeExample.FlashcardsFixtures is not loaded` because `test/support/flashcards_fixtures.ex` was not on the compile path. The test suite previously could not run at all (compilation error prevented any test from loading).
- **Fix:** Added `elixirc_paths: elixirc_paths(Mix.env())` + `defp elixirc_paths(:test), do: ["lib", "test/support"]` to `mix.exs` — standard Phoenix pattern.
- **Files modified:** `examples/phoenix_host/mix.exs`
- **Commit:** 348d1f8

### Pre-existing Out-of-Scope Test Failures (NOT fixed)

The `elixirc_paths` fix allowed the test suite to load `FlashcardsFixtures` for the first time, surfacing 3 pre-existing assertion failures in `FlashcardsTest`:
1. `card.front` — schema uses `front_text` (field name drift)
2. `card.back` — schema uses `back_text` (field name drift)
3. `create_progress/1` — context uses `upsert_progress/1` (function rename drift)

These failures pre-date this plan, are in `flashcards_test.exs` and `flashcards_fixtures.ex` (files the plan's scope fence forbids editing), and have zero relation to the de-mocked `sync_outbox` handler. They are logged to deferred-items for Phase 115 or a future cleanup plan.

The critical gate (no test depends on the deleted mock) is fully satisfied.

## Threat Flags

None — this plan only deleted code. No new input surface, endpoint, or trust boundary was introduced.

## Known Stubs

None — the deletion leaves no stubs. The `current_card_id` progression in the rate handler still works; it just no longer accumulates a server-side Elixir list.

## Self-Check: PASSED

- `study_session_live.ex` modified: FOUND
- `mix.exs` modified: FOUND
- Task 1 commit c43dac1: FOUND
- Task 2 commit 348d1f8: FOUND
- No sync_outbox/sync_result/outbox references in study_session_live.ex: VERIFIED
- mix compile --warnings-as-errors: PASSED (exit 0)
- mix test: 18 tests, 3 pre-existing failures unrelated to de-mock
