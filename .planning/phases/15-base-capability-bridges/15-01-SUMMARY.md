---
phase: "15"
plan: "01"
subsystem: "bridge"
tags:
  - capabilities
  - bridge
  - registry
dependency_graph:
  requires: []
  provides:
    - Typed capability payloads
    - strict registry allowlist for share.invoke
  affects:
    - Bridge registry
tech_stack:
  added: []
  patterns:
    - struct-based capability payloads
    - strict allowlist verification
key_files:
  created:
    - lib/crosswake/bridge/commands/haptics.ex
    - lib/crosswake/bridge/commands/share.ex
    - lib/crosswake/bridge/commands/app_info.ex
  modified:
    - lib/crosswake/bridge/registry.ex
    - lib/crosswake/bridge/contract.ex
    - test/crosswake/bridge/registry_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/mix/tasks/crosswake_doctor_test.exs
    - test/crosswake/bridge/contract_test.exs
key_decisions:
  - "Decided to explicitly register share.invoke in bridge contract alongside capability registry."
metrics:
  duration: 10
  tasks_completed: 2
  tasks_total: 2
  files_modified: 8
---

# Phase 15 Plan 01: Base Capability Bridges Summary

Implemented the base Elixir capability models and registry allowlist for Haptics, Share, and App Info commands, solidifying payload serialization contracts on the host.

## Tasks Completed
- **Task 1**: Added `share.invoke` to capability registry in `lib/crosswake/bridge/registry.ex`, enforcing a fail-closed paradigm.
- **Task 2**: Defined strongly-typed capability payload structs for `haptics.impact`, `share.invoke`, and `app.info.get`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added share.invoke to Contract and updated failing test assertions**
- **Found during:** Task 2 (mix test)
- **Issue:** Adding `share.invoke` to the capability registry caused `mix test` to fail because several tests assert against an exact hardcoded array of `allowed_commands`, and the command was missing from `lib/crosswake/bridge/contract.ex`.
- **Fix:** Added `share.invoke` to `@commands` in `lib/crosswake/bridge/contract.ex` and updated the arrays in `registry_test.exs`, `doctor_test.exs`, `crosswake_doctor_test.exs`, and `contract_test.exs`.
- **Files modified:** `lib/crosswake/bridge/contract.ex`, `test/crosswake/bridge/registry_test.exs`, `test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`, `test/crosswake/bridge/contract_test.exs`
- **Commit:** 2563813

## Self-Check: PASSED
- `lib/crosswake/bridge/commands/haptics.ex` created successfully.
- `lib/crosswake/bridge/commands/share.ex` created successfully.
- `lib/crosswake/bridge/commands/app_info.ex` created successfully.
- `lib/crosswake/bridge/registry.ex` modified and committed.
- All tests passing.
