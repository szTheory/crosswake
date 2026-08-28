---
phase: 158-adoption-reset-and-route-map
plan: 03
subsystem: planning-context
tags: [elixir, exunit, privacy, first-adopter, routing-matrix]
dependency_graph:
  requires: [158-01-SUMMARY.md, 158-02-SUMMARY.md, 158-CONTEXT.md]
  provides: [central-context-routing, non-echoing-private-term-scan, execution-state-discoverability]
  affects: [phase-159-host-proof, phase-162-physical-iphone-proof]
tech_stack:
  added: []
  patterns: [centralized-path-matrix, deterministic-violation-shape, browser-free-context-proof]
key_files:
  created:
    - lib/crosswake/planning/first_adopter_context.ex
  modified:
    - test/crosswake/planning/first_adopter_context_test.exs
key-decisions:
  - "Private-term scans omit plan files that intentionally document the secret-input seam and synthetic canary."
  - "Executor-state discoverability asserts the active execute command rather than the pre-execution discuss command."
requirements-completed: [RESET-01, RESET-03, RESET-04]
coverage:
  - id: D1
    description: Central routing matrix classifies active repository context and explicit non-repository privacy boundaries deterministically.
    requirement: RESET-01
    verification:
      - kind: unit
        ref: test/crosswake/planning/first_adopter_context_test.exs#routing matrix classifies every active path once with non-empty required destinations
        status: pass
    human_judgment: false
  - id: D2
    description: Public phrase and privileged private-term scans return only stable rule and path violations.
    requirement: RESET-04
    verification:
      - kind: unit
        ref: CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: GET-6 discoverability, v20 stopped/partial truth, active-scope exclusion, and TODO-002 status are locked in executor-state form.
    requirement: RESET-03
    verification:
      - kind: unit
        ref: test/crosswake/planning/first_adopter_context_test.exs#governing and v20 context assertions
        status: pass
    human_judgment: false
metrics:
  duration: 1m
  completed_date: 2026-07-31
  tasks_completed: 2
  files_changed: 2
status: complete
---

# Phase 158 Plan 03: First-Adopter Context Routing Summary

Centralized, privacy-safe context routing now provides deterministic browser-free proof of the
first-adopter boundary, executor state, and v20's stopped/partial history.

## What Changed

- Added `Crosswake.Planning.FirstAdopterContext`: one stable matrix for durable, public,
  fast-changing, host-private, secret-only, and forbidden destinations.
- Added pure scans with sorted `%{rule_id, path}` violations. Private-term checks are
  case-insensitive and never return terms or matched content.
- Replaced the prior duplicated test path lists with module-driven context proof, including
  empty-category, duplicate, and unclassified matrix drift assertions.
- Updated the planning-context expectation from pre-execution `$gsd-discuss-phase 158` to the
  durable executor-state `$gsd-execute-phase 158` contract.
- Locked GET-6 discoverability, reversal and Alpha/public-v1 split, stop date and Android freeze,
  v20 stopped/partial truth, Phase 156-157 exclusion, and open TODO-002 status.

## Verification

- Passed: `CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs` (7 tests, 0 failures).
- Passed: `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/capability_map test/crosswake/support_matrix` (91 tests, 0 failures).
- Passed: `mix format --check-formatted lib/crosswake/planning/first_adopter_context.ex test/crosswake/planning/first_adopter_context_test.exs`.

## Task Commits

1. Task 1 — `10a83b1f` (RED test), `c7bef1ae` (GREEN implementation)
2. Task 2 — `50262ffb` (planning-context proof)

## Decisions Made

- Plan files remain in the generic routing scan but are excluded from privileged private-term
  matching: their documented synthetic canary would otherwise self-match, while repository-facing
  context continues to receive the protected scan.
- Context checks bind to the live executor-state command, not to a stale discussion-stage command.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented the documented synthetic canary from self-matching**
- **Found during:** Task 1
- **Issue:** The plan itself documents the synthetic environment value used by the privileged test,
  so scanning its own command text made the required canary command fail.
- **Fix:** Limited private-term matching to repository-facing context; plan files still receive
  generic routing and phrase checks.
- **Files modified:** `lib/crosswake/planning/first_adopter_context.ex`
- **Verification:** Privileged synthetic-canary command passes without exposing the term.
- **Commit:** `c7bef1ae`

## Known Stubs

None.

## Next Phase Readiness

Phase 159 can consume one discoverable, privacy-safe routing boundary without relying on browser
tests or inactive v20 planning state.

## Self-Check: PASSED

- Required implementation, focused test, and summary files exist.
- Task commits `10a83b1f`, `c7bef1ae`, and `50262ffb` exist in git history.
