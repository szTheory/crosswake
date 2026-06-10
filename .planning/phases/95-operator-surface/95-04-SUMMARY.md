---
phase: 95-operator-surface
plan: "04"
subsystem: mix-task
tags: [mix-task, cli, threadline, operator, chronological-sort, tdd, oper-01]
requirements: [OPER-01]

dependency_graph:
  requires: []
  provides: [chronological-sort-fix, month-boundary-regression-test]
  affects: [lib/mix/tasks/crosswake.threadline.ex, test/mix/tasks/crosswake.threadline_test.exs]

tech_stack:
  added: []
  patterns: [NaiveDateTime.compare, DateTime.compare, Enum.sort_by-with-comparator, private-helper-extraction]

key_files:
  created: []
  modified:
    - lib/mix/tasks/crosswake.threadline.ex
    - test/mix/tasks/crosswake.threadline_test.exs

decisions:
  - Use explicit two-arg Enum.sort_by/3 comparator to handle both NaiveDateTime and DateTime struct types without crashing
  - Extract timestamp_of/1 private helper to keep sort call readable and the fallback chain DRY
  - Add compare_ts/2 clauses for all four type pairings (NDT/NDT, DT/DT, NDT/DT, DT/NDT) for forward-compatibility with canonical ledger schema using :utc_datetime_usec

metrics:
  duration: "~8 minutes"
  completed: "2026-06-10"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 2
---

# Phase 95 Plan 04: Threadline Chronological Sort Fix (OPER-01) Summary

Replaced Erlang-structural bare `Enum.sort_by/2` with a NaiveDateTime/DateTime comparator so `mix crosswake.threadline` renders events oldest-to-newest across month and year boundaries, closing OPER-01.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Month-boundary regression test (failing) | 8968d9d | test/mix/tasks/crosswake.threadline_test.exs |
| 1 (GREEN) | Fix date-comparator sort in query_events/4 | 75a8c31 | lib/mix/tasks/crosswake.threadline.ex |

## What Was Built

**Root cause (CR-03):** `query_events/4` used `Enum.sort_by/2` with no comparator. Elixir's default sort applies Erlang structural term order to NaiveDateTime/DateTime structs, which compares map keys alphabetically (`:day` before `:month` before `:year`). This makes a December event (day=20) appear after a January event (day=15) even when December is the earlier date — breaking chronological reconstruction for any multi-month audit window.

**Fix:** Replaced the bare sort with `Enum.sort_by(&timestamp_of/1, fn a, b -> compare_ts(a, b) != :gt end)`. The private `timestamp_of/1` helper preserves the existing fallback chain (`occurred_at → inserted_at → atom/string variants → epoch sentinel`). The `compare_ts/2` function dispatches on struct type across all four pairings (NaiveDateTime/NaiveDateTime, DateTime/DateTime, and mixed) to handle both the test fixture pattern (`:inserted_at ~N[...]`) and the canonical ledger template schema (`:occurred_at :utc_datetime_usec` → DateTime).

**Regression test:** Added a new `"chronological sort across month boundary"` describe block with `MockRepoBoundary` that supplies three events in a deliberately non-chronological order — Feb 2026, Dec 2025, Jan 2026 — all in the `phoenix` tier (so tier grouping cannot mask the sort defect). The test captures `mix crosswake.threadline` output and asserts `dec_pos < jan_pos < feb_pos` by `:binary.match` position, mirroring the existing tier-ordering assertion pattern.

## Verification

```
mix test test/mix/tasks/crosswake.threadline_test.exs
5 tests, 0 failures
```

Acceptance criteria confirmed:
- `grep -nE "NaiveDateTime.compare|DateTime.compare" lib/mix/tasks/crosswake.threadline.ex` → 4 matches
- Bare `Enum.sort_by(fn event ->` with no third arg: absent from query_events/4
- `grep -c "import Ecto.Query" lib/mix/tasks/crosswake.threadline.ex` → 0

## Deviations from Plan

None — plan executed exactly as written.

The only implementation decision beyond the plan was adding all four `compare_ts/2` clauses (including the two mixed NaiveDateTime/DateTime pairs) rather than only the two pure-type clauses. This is a Rule 2 (missing critical functionality) addition: the canonical ledger template uses `:utc_datetime_usec` (DateTime), while test fixtures naturally use NaiveDateTime; without the mixed clauses, a host that happens to mix both timestamp types in the same query would crash the sort. The addition is zero-dependency and directly required for correctness under the stated "both NaiveDateTime and DateTime can appear" constraint in the plan's `<action>` section.

## Threat Flags

No new security surface introduced. The fix operates entirely within the sort pipeline — no new network endpoints, auth paths, file access, or schema changes at trust boundaries. T-95-05 (Tampering via incorrect chronological reconstruction) is now mitigated by the date-comparator sort.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| SUMMARY.md exists | FOUND |
| RED commit 8968d9d exists | FOUND |
| GREEN commit 75a8c31 exists | FOUND |
| lib/mix/tasks/crosswake.threadline.ex exists | FOUND |
| test/mix/tasks/crosswake.threadline_test.exs exists | FOUND |
