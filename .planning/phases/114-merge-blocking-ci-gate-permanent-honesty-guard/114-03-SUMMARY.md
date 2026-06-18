---
phase: 114-merge-blocking-ci-gate-permanent-honesty-guard
plan: "03"
subsystem: phoenix_host_e2e_guard
tags: [elixir, phoenix, exunit, guard-02, ci, testing]
status: complete
completed_date: "2026-06-18"
duration_seconds: 142
task_count: 3
file_count: 3
requirements: [GUARD-02]

dependency_graph:
  requires: [114-01, 114-02]
  provides: [GUARD-02-in-suite-half]
  affects:
    - examples/phoenix_host/test/crosswake_example/router_test.exs
    - examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs
    - examples/phoenix_host/lib/crosswake_example/router.ex

tech_stack:
  patterns:
    - ExUnit plain-case route introspection via Phoenix.Router.routes/1
    - Direct controller invocation (no ConnCase) for count-scoping proof
    - Unique integer IDs + on_exit Repo.delete_all for deterministic SQLite test cleanup

key_files:
  created:
    - examples/phoenix_host/test/crosswake_example/router_test.exs
    - examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/router.ex

decisions:
  - "Direct controller invocation preferred over Phoenix.ConnTest routing for the scoping test — no ConnCase/DataCase exists, and calling show/2 directly avoids router path-encoding complexity while still exercising the real show/2 code path"
  - "async: false for the controller test — SQLite has no async sandbox; unique integer IDs prevent inter-test row collisions"
  - "No ~p verified-route sigil in router_test.exs — conditionally-compiled routes break ~p verification (D-08)"
  - "Mix.env() in [:test, :e2e] gate unchanged — compile-time gating is strictly stronger than any runtime guard; one-line comment only"
---

# Phase 114 Plan 03: GUARD-02 In-Suite Backstop Summary

**One-liner:** ExUnit route-presence + controller count-scoping assertions for the /_e2e test-harness endpoint, completing GUARD-02's in-suite half.

## What Was Built

Three changes forming GUARD-02's in-suite behavioral backstop:

1. **router_test.exs** — A plain `ExUnit.Case, async: true` test that calls `Phoenix.Router.routes(CrosswakeExample.Router)` and asserts the `/_e2e/sync-state/:client_mutation_id` route exists under `:test` with `verb :get`, `plug CrosswakeExample.E2E.SyncStateController`, and `plug_opts :show`. No `~p` sigil (conditionally-compiled routes break `~p` verification per D-08).

2. **sync_state_controller_test.exs** — A plain `ExUnit.Case, async: false` test that inserts 2 distinct `ReviewEvent` rows with different `client_mutation_id` values, then directly invokes `SyncStateController.show/2` and asserts `count == 1` for each id — proving the aggregate is scoped per mutation, not a whole-table count. A second test asserts `{synced: false, count: 0}` for a non-existent id. Cleanup uses `on_exit + Repo.delete_all` with `System.unique_integer` IDs for deterministic reruns.

3. **router.ex comment** — One-line comment `# /_e2e is the reserved test-harness namespace — compile-time gated OUT of prod beams.` added directly above the `if Mix.env() in [:test, :e2e] do` block. The gating expression is unchanged (no `Application.compile_env`, no runtime guard — D-09).

## Verification Results

All tests pass:
- `mix test test/crosswake_example/router_test.exs` — 1 test, 0 failures
- `mix test test/crosswake_example/e2e/sync_state_controller_test.exs` — 2 tests, 0 failures (deterministic across two successive runs)
- `MIX_ENV=test mix compile --warnings-as-errors` — clean
- Combined run of both test files: 3 tests, 0 failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Ecto.Query macro not in scope in first controller test attempt**
- **Found during:** Task 2 (first mix test run)
- **Issue:** `Ecto.Query.from(r in ReviewEvent, ...)` in `on_exit` callback raised `undefined variable "r"` because the `from` macro was called as a plain function (not imported), so the DSL binding didn't expand
- **Fix:** Added `import Ecto.Query, warn: false` to the module and used `from(r in ...)` directly
- **Files modified:** sync_state_controller_test.exs
- **Commit:** e822e6b (incorporated into same task commit)

None beyond the above auto-fix. Plan executed as written.

## Known Stubs

None. Both test files wire real data (Repo inserts + controller invocation). The router.ex comment is documentation only.

## Self-Check: PASSED

- `/Users/jon/projects/crosswake/examples/phoenix_host/test/crosswake_example/router_test.exs` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` — FOUND
- `/Users/jon/projects/crosswake/.planning/phases/114-merge-blocking-ci-gate-permanent-honesty-guard/114-03-SUMMARY.md` — FOUND
- Commit `1cdfab5` (Task 1) — verified
- Commit `e822e6b` (Task 2) — verified
- Commit `5ca355c` (Task 3) — verified
