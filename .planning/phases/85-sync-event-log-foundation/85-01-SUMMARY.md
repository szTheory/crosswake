---
phase: 85-sync-event-log-foundation
plan: 01
subsystem: Sync
tags:
  - event-log
  - sync
  - reconciliation
  - generator
dependency_graph:
  requires:
    - none
  provides:
    - Crosswake.Sync.EventLog.Entry struct
    - mix crosswake.gen.sync generator
  affects:
    - Ecto Schema templates
    - Phoenix Controller templates
tech_stack:
  added:
    - Ecto Multi batch insertions via EEx generator
  patterns:
    - Idempotent log inserts
    - Host-owned reconciliation endpoints
key_files:
  created:
    - lib/crosswake/sync/event_log.ex
    - test/crosswake/sync/event_log_test.exs
    - priv/templates/crosswake/sync/event_log.ex.eex
    - priv/templates/crosswake/sync/sync_controller.ex.eex
    - lib/mix/tasks/crosswake.gen.sync.ex
    - test/mix/tasks/crosswake.gen.sync_test.exs
  modified:
    - none
key_decisions:
  - Used `EEx.eval_file(template, app_module: app_module)` instead of nested `assigns: []` map to ensure the templates properly substitute variable `app_module` over module attributes `@app_module`.
  - Modified `new_entry` constructor from accepting either map or keyword to explicitly handling `when is_list(attrs)` keyword parameter, bringing it in parity with `Journal.new_entry/1` type specification limits.
metrics:
  duration_minutes: 5
  completed_date: "2025-02-14T00:00:00Z"
---

# Phase 85 Plan 01: Core EventLog Structs and Sync Generator Summary

Defined `Crosswake.Sync.EventLog.Entry` as a durably struct and implemented the `mix crosswake.gen.sync` Mix task to scaffold host-owned event log infrastructure including an Ecto Schema and a Phoenix controller for reconciliation replays. 

## Completed Tasks

1. **Task 1: Define Crosswake.Sync.EventLog.Entry**
   - Created the core EventLog entry struct with rigorous type specifications matching the Journal offline representation.
   - Verified that `new_entry/1` safely handles defaults and enforces keys.

2. **Task 2: Create Host Templates for Ecto Schema and Phoenix Controller**
   - Scaffolding templates for `crosswake_sync_event_logs` were added targeting host databases. 
   - Addressed threat models: Uses `unique_constraint(:idempotency_key)` to mitigate T-85-01 (Tampering) and uses `Ecto.Multi.insert_all` batch inserts with `on_conflict: :nothing` to mitigate T-85-02 (DoS).
   - Designed controller template to deduplicate conflict records dynamically and merge the persisted state outcomes into replay HTTP responses.

3. **Task 3: Create mix crosswake.gen.sync Generator**
   - Implemented `Mix.Tasks.Crosswake.Gen.Sync` logic copying templates to `lib/MyApp/sync/event_log.ex` and `lib/MyAppWeb/controllers/sync_controller.ex`.
   - Populated the command output with explicit `mix ecto.gen.migration` steps and route scaffolding examples so that adopters get a turnkey integration point.
   - Comprehensive integration test verifies template substitutions and directory placement.

## Deviations from Plan
- None - plan executed as written.

## Self-Check
- [x] `lib/crosswake/sync/event_log.ex` exists
- [x] `test/crosswake/sync/event_log_test.exs` exists
- [x] `priv/templates/crosswake/sync/event_log.ex.eex` exists
- [x] `priv/templates/crosswake/sync/sync_controller.ex.eex` exists
- [x] `lib/mix/tasks/crosswake.gen.sync.ex` exists
- [x] `test/mix/tasks/crosswake.gen.sync_test.exs` exists
- [x] Tests pass successfully
