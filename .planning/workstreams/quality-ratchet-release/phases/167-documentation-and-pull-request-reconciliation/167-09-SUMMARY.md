---
phase: 167-documentation-and-pull-request-reconciliation
plan: 09
subsystem: documentation
tags: [elixir, capability-map, adoption-authority, fail-closed, tdd]

requires:
  - phase: 167-01-documentation-reconciliation
    provides: typed three-layer first adopter claim authority
provides:
  - exact closed-set validation for all seven adoption-authority dimensions
  - exhaustive available-state cross-product and all-state one-axis mutation regressions
affects: [167-verification, documentation-sync, phase-168-handoff]

actuals:
  tokens: 2391
  tasks: 2
  commits: 4
plan_head_before: 2341a42430f74ca9af888d6c7f5e449bec80bab4

tech-stack:
  added: []
  patterns: [exact canonical tuple membership, exhaustive authority-axis mutation matrix]

key-files:
  created: []
  modified:
    - lib/crosswake/capability_map.ex
    - test/crosswake/capability_map/capability_map_test.exs

key-decisions:
  - "Admit adoption authority only by exact membership in the three canonical seven-field tuples."
  - "Return one stable complete_authority_tuple rule without echoing sensitive statement or boundary values."

patterns-established:
  - "Closed authority tuples: independently valid field values are insufficient unless their full tuple is canonical."
  - "Mutation matrices: every authority axis is tested with incompatible, missing, and omitted values."

requirements-completed: [DOC-01]

coverage:
  - id: D1
    description: Available first adopter authority rejects every noncanonical source, proof, and promotion combination.
    requirement: DOC-01
    verification:
      - kind: unit
        ref: "mix test test/crosswake/capability_map/capability_map_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Exactly three complete authority tuples are admitted while every one-axis mutation fails closed without sensitive-value echo.
    requirement: DOC-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/capability_map test/crosswake/support_matrix/renderer_test.exs && mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-09-12
status: complete
---

# Phase 167 Plan 09: Complete Adoption-Authority Tuple Closure Summary

**Exact seven-field tuple membership now admits only reusable Crosswake authority, retained reference-host evidence, and blocked first adopter activation while rejecting every mixed or incomplete authority claim.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-12T15:01:02Z
- **Completed:** 2026-09-12T15:09:46Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Closed the available-state fail-open path with a 64-case cross-product that accepts only the canonical repository-bound reusable contract.
- Replaced partial state-specific validation with exact membership in the three canonical seven-field adoption-authority tuples.
- Added 63 one-axis mutations across all canonical states, checking incompatible, missing, and omitted values while preserving a single non-echoing error contract.

## Task Commits

Each task was committed atomically using RED/GREEN TDD commits:

1. **Task 1: Close available first adopter authority combinations** — `029cd152` (RED), `0d29a431` (GREEN)
2. **Task 2: Enforce the complete three-state authority tuple set** — `d01ccc6d` (RED), `742764c2` (GREEN)

No refactor commit was needed; exact tuple membership is the smallest clear implementation of the closed-set contract.

## Files Created/Modified

- `lib/crosswake/capability_map.ex` — Defines the three canonical seven-field authority tuples and rejects every other complete claim before rendering.
- `test/crosswake/capability_map/capability_map_test.exs` — Pins the available-state cross-product, all-state one-axis mutation matrix, canonical acceptance, and non-echoing error behavior.

## Decisions Made

- Used exact tuple membership instead of accumulating partial rules, so future combinations fail closed by default.
- Kept the existing claim bytes and public renderer interfaces unchanged; validation is stricter without widening support or changing generated documentation.
- Kept one stable `complete_authority_tuple` error and asserted that statement and boundary sentinels never appear in failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repository pin requests Erlang 27.3 while the installed compatible patch runtime is 27.3.4.15; verification used `ASDF_ERLANG_VERSION=27.3.4.15` with Elixir 1.19.5.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- Task 1 intentionally failed on the available-state fail-open reproduction before GREEN; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 2 intentionally failed on noncanonical reference-state mutations before GREEN; `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- RED `029cd152` precedes GREEN `0d29a431`; RED `d01ccc6d` precedes GREEN `742764c2`.

## Verification

- `mix test test/crosswake/capability_map test/crosswake/support_matrix/renderer_test.exs` — 42 tests, 0 failures.
- `mix crosswake.docs.sync --check` — passed.
- `mix crosswake.adoption_context.scan` — passed.
- `git diff --check -- lib/crosswake/capability_map.ex test/crosswake/capability_map/capability_map_test.exs` — clean.

## Next Phase Readiness

- Phase 167 can be re-verified with adoption authority closed across all seven dimensions.
- Phase 168 remains unopened; this plan did not broaden release, PR, Android, or parked first adopter scope.

## Self-Check: PASSED

- Both declared source and test files exist, and the plan-base diff contains no other implementation files.
- All four RED/GREEN task commits are present in order in git history.
- The exact plan verification passed with 42 tests and both documentation/privacy gates green.
- The parked first adopter state has no diff from the plan base.
- No new stub, skipped test, unrun verification, deletion, or uncovered threat surface was introduced.

---
*Phase: 167-documentation-and-pull-request-reconciliation*
*Completed: 2026-09-12*
