---
phase: 95
plan: 02
subsystem: operator-surface
tags: [mix-task, cli, tdd, threadline, operator, text-tree]
dependency_graph:
  requires: [91-threadline-telemetry, 94-audit-ledger]
  provides: [mix-crosswake-threadline-cli]
  affects: [operator-ux]
tech_stack:
  added: []
  patterns: [mix-task, option-parser, unicode-text-tree, ephemeral-durable-posture]
key_files:
  created:
    - lib/mix/tasks/crosswake.threadline.ex
    - test/mix/tasks/crosswake.threadline_test.exs
  modified: []
decisions:
  - "No compile-time Ecto.Query dependency: query_events/4 uses repo.all(schema) and in-memory filtering — Ecto is not in mix.exs deps, so import Ecto.Query at compile time fails; runtime filtering is idiomatic for a diagnostic Mix task"
  - "TDD cycle followed: RED (442625a) then GREEN (9295d1c)"
metrics:
  duration_seconds: 337
  completed_date: "2026-06-10"
  tasks_completed: 1
  files_changed: 2
---

# Phase 95 Plan 02: mix crosswake.threadline CLI Task Summary

Implemented `Mix.Tasks.Crosswake.Threadline` — a `mix crosswake.threadline` CLI task that renders a Native -> Bridge -> Phoenix chronological timeline visualization for operators. Delivers OPER-01: text-only operator surface with honest ephemeral vs. durable posture reporting.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Failing tests for Threadline CLI Task | 442625a | test/mix/tasks/crosswake.threadline_test.exs |
| 1 (GREEN) | Implement Mix.Tasks.Crosswake.Threadline | 9295d1c | lib/mix/tasks/crosswake.threadline.ex |

## What Was Built

### `lib/mix/tasks/crosswake.threadline.ex`

`Mix.Tasks.Crosswake.Threadline` with:
- `@shortdoc "Inspects Threadline Native->Bridge->Phoenix events via text tree"`
- Strict `OptionParser.parse` for `--thread-id` and `--actor-ref`; raises `Mix.Error` if neither is provided
- `ledger_posture/0`: checks `Application.get_env(:crosswake, :audit_repo)` and `:audit_ledger`; returns `:ephemeral` or `{:durable, repo, schema}`
- Ephemeral path: `Mix.shell().info("Posture: Ephemeral. No ledger configured.")` and exit 0 (D-02)
- Durable path: calls `Mix.Task.run("app.start")`, fetches via `repo.all(schema)` with in-memory filter by `thread_id`/`actor_ref`, sorts by `occurred_at`/`inserted_at`
- Unicode text tree renderer grouping events by tier order: Native -> Bridge -> Phoenix, with `├──` / `└──` / `│   ` connectors (D-01)

### `test/mix/tasks/crosswake.threadline_test.exs`

Three test groups with 4 tests:
1. **Argument validation**: missing both flags raises `Mix.Error` matching `~r/(--thread-id|--actor-ref)/`
2. **Ephemeral posture**: both `--thread-id` and `--actor-ref` with cleared config produce `"Posture: Ephemeral. No ledger configured."`
3. **Durable posture**: inline `MockRepo` and `MockLedgerSchema` verify `"Posture: Durable"`, tree connectors `├──`/`└──`, and ordered tier labels (Native before Bridge before Phoenix)

## Verification

```
mix test test/mix/tasks/crosswake.threadline_test.exs
4 tests, 0 failures
```

Full suite: 64 pre-existing failures unrelated to this plan (all in `CrosswakeExample.*` modules not available in the test environment).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed compile-time `import Ecto.Query` (Ecto not a library dependency)**
- **Found during:** GREEN phase compilation
- **Issue:** `import Ecto.Query, only: [from: 2]` failed at compile time — Ecto is not listed in `mix.exs` deps (it is a host-app dependency, not a Crosswake library dependency)
- **Fix:** Replaced Ecto.Query-based filtering with `repo.all(schema)` + in-memory Enum filtering; this is idiomatic for a diagnostic/operator tool and avoids adding Ecto as a library dependency
- **Files modified:** `lib/mix/tasks/crosswake.threadline.ex`
- **Commit:** 9295d1c

**2. [Rule 2 - Missing critical functionality] Used `occurred_at`/`inserted_at` fallback chain for sort**
- **Found during:** GREEN phase — ledger template review showed `occurred_at` (not `inserted_at`) is the primary timestamp field
- **Fix:** Sort key reads `occurred_at || inserted_at` for both atom and string key variants, making the task compatible with both the generated ledger schema and test mocks
- **Files modified:** `lib/mix/tasks/crosswake.threadline.ex`
- **Commit:** 9295d1c

## TDD Gate Compliance

- RED gate: `test(95-02)` commit `442625a` — 4 failing tests created before implementation
- GREEN gate: `feat(95-02)` commit `9295d1c` — implementation makes all 4 tests pass
- REFACTOR gate: No structural cleanup needed; implementation was clean on first pass

## Known Stubs

None — all three test paths (argument error, ephemeral, durable) are fully exercised.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. The Mix task is a read-only diagnostic tool that queries the host's existing repo.

## Self-Check: PASSED

- `lib/mix/tasks/crosswake.threadline.ex` — confirmed created
- `test/mix/tasks/crosswake.threadline_test.exs` — confirmed created
- Commit `442625a` (RED) — confirmed in git log
- Commit `9295d1c` (GREEN) — confirmed in git log
- `mix test test/mix/tasks/crosswake.threadline_test.exs` — 4 tests, 0 failures
