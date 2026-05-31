---
phase: 49-operator-inspection-contract
plan: "02"
subsystem: diagnostics
tags: [elixir, mix-task, cli, operator-inspection, dx]
requires:
  - phase: 49-operator-inspection-contract
    provides: route-authoritative operator inspection document
provides:
  - mix crosswake.inspect CLI
  - human operator inspection formatter
  - CLI tests for human and JSON output
affects: [doctor, support-matrix, operator-cli]
tech-stack:
  added: []
  patterns: [Mix.Task strict option parsing, human/default plus json format]
key-files:
  created:
    - lib/crosswake/operator_inspection/formatter.ex
    - lib/mix/tasks/crosswake.inspect.ex
    - test/crosswake/operator_inspection/formatter_test.exs
    - test/mix/tasks/crosswake_inspect_test.exs
  modified:
    - lib/crosswake/operator_inspection/types.ex
key-decisions:
  - "Human output defaults to concise route-first inventory rather than doctor-style remediation."
  - "CLI supports only --router and --format human|json in Phase 49."
patterns-established:
  - "Mix task mirrors doctor option parsing while delegating inventory semantics to OperatorInspection."
  - "Human formatter displays support/proof/rebuild/denial axes without collapsing them into one readiness label."
requirements-completed: [OPER-01, OPER-02]
duration: 15min
completed: 2026-05-31
---

# Phase 49-02: Operator Inspection CLI Summary

**`mix crosswake.inspect` route inventory with concise human output and stable JSON output**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-31T20:36:00Z
- **Completed:** 2026-05-31T20:51:24Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `Crosswake.OperatorInspection.Formatter` for route-first human inspection output.
- Added `mix crosswake.inspect --router Elixir.YourAppWeb.Router --format human|json`.
- Added Mix task tests for human output, JSON output, missing router, and unsupported format handling.

## Task Commits

1. **Operator inspection Mix task and formatter** - `fc43784` (`feat(49): add operator inspection mix task`)

## Files Created/Modified

- `lib/crosswake/operator_inspection/formatter.ex` - Human formatter for route inventory and findings.
- `lib/mix/tasks/crosswake.inspect.ex` - Strict Mix task wrapper around `Crosswake.OperatorInspection`.
- `test/crosswake/operator_inspection/formatter_test.exs` - Covers concise route-first formatting.
- `test/mix/tasks/crosswake_inspect_test.exs` - Covers CLI human/JSON behavior and error paths.
- `lib/crosswake/operator_inspection/types.ex` - Added generic struct serialization for derived findings.

## Decisions Made

- Kept the CLI intentionally narrow: `--router` plus `--format human|json`.
- Did not add filtering/query options; route filtering remains deferred beyond Phase 49.
- Used `Mix.shell().info/1` and strict `OptionParser` behavior consistent with `crosswake.doctor`.

## Deviations from Plan

None - plan executed as scoped.

## Issues Encountered

- JSON rendering of derived findings needed generic struct-to-map handling.
- The managed router fixture uses `/study-session`; tests were corrected to assert existing fixture truth.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Operators can now inspect route readiness independently from doctor. Phase 50 can compose doctor over this inventory without changing the inspection contract.

---
*Phase: 49-operator-inspection-contract*
*Completed: 2026-05-31*
