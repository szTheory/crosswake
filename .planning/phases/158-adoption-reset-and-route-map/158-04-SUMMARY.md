---
phase: 158-adoption-reset-and-route-map
plan: 04
subsystem: support-truth-validation
tags: [elixir, markdown, support-matrix, privacy, nyquist, first-adopter]
dependency_graph:
  requires: [158-01-SUMMARY.md, 158-02-SUMMARY.md, 158-03-SUMMARY.md, 158-CONTEXT.md]
  provides: [narrow-public-support-truth, completed-nyquist-validation-ledger]
  affects: [phase-159-host-proof, phase-162-physical-iphone-proof]
tech_stack:
  added: []
  patterns: [renderer-owned-guide-regeneration, policy-versus-proof-boundary, deterministic-phase-gate]
key_files:
  created:
    - .planning/phases/158-adoption-reset-and-route-map/158-04-SUMMARY.md
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/support_matrix/renderer.ex
    - test/crosswake/support_matrix/renderer_test.exs
    - guides/support_matrix.md
    - .planning/phases/158-adoption-reset-and-route-map/158-VALIDATION.md
key-decisions:
  - "Policy-contract completion and surface defaults never promote external-host or physical-device support while route inputs are unknown_blocking."
  - "Public support wording uses first adopter, retains the existing vocabulary, and keeps Android at its frozen generator/Maven/JVM/vector posture."
requirements-completed: [RESET-01, RESET-02, RESET-03, RESET-04]
coverage:
  - id: D1
    description: "Generated support truth distinguishes the complete policy contract from still-required host and physical-device evidence."
    requirement: RESET-02
    verification:
      - kind: unit
        ref: test/crosswake/support_matrix/renderer_test.exs#first adopter readiness keeps policy completion separate from host and device proof
        status: pass
    human_judgment: false
  - id: D2
    description: "Public support guide keeps first-adopter wording, Android freeze, proof non-claims, and renderer byte parity."
    requirement: RESET-04
    verification:
      - kind: unit
        ref: test/crosswake/support_matrix/renderer_test.exs#first adopter readiness preserves Android freeze and makes no unsupported proof claim
        status: pass
      - kind: unit
        ref: test/crosswake/support_matrix/renderer_test.exs#guides/support_matrix.md is byte-identical to canonical renderer output after Plan 23-02 enrichment
        status: pass
    human_judgment: false
  - id: D3
    description: "Phase 158 validation maps all RESET requirements, threats, edge accounting, and deterministic green gates."
    requirement: RESET-01
    verification:
      - kind: integration
        ref: mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs test/crosswake/capability_map test/crosswake/support_matrix
        status: pass
      - kind: integration
        ref: CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs
        status: pass
      - kind: integration
        ref: mix test --exclude requires_example_host --exclude advisory_only
        status: pass
    human_judgment: false
metrics:
  duration: 12m
  completed_date: 2026-07-31
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 158 Plan 04: Support Truth and Validation Summary

The generated support guide now preserves the first-adopter policy boundary without promoting unknown route inputs, example-host proof, or existing platform posture into host or physical-device support.

## Accomplishments

- Added explicit policy-contract versus adopter-instance and host/device-proof language to the canonical support renderer.
- Kept scoped replay, cached read-only, one offline island, server-owned `gated_by`, and the Android freeze narrow and non-promotional.
- Regenerated `guides/support_matrix.md` through the renderer write path and locked byte parity with focused tests.
- Completed the Phase 158 validation ledger with requirement/threat mapping, edge accounting, and green quick, canary, hermetic, and diff gates.

## Verification

- Passed `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` — 69 tests, 0 failures.
- Passed Phase 158 quick gate — 100 tests, 0 failures.
- Passed privileged synthetic privacy canary — 7 tests, 0 failures.
- Passed hermetic suite — 1307 tests, 0 failures.
- Passed `git diff --check`.

## Task Commits

1. Task 1 RED — `030c5729` (`test`): failing policy-versus-proof support assertions.
2. Task 1 GREEN — `4c6b4841` (`feat`): narrow renderer truth, public guide regeneration, and passing parity coverage.
3. Task 2 — `ccbccab0` (`docs`): completed Nyquist validation ledger.

## Decisions Made

- Policy-contract complete is not concrete route, external-host, or physical-device proof; `unknown_blocking` remains a hard promotion blocker.
- Existing proof classes and statuses remain intact; no new label family or Android/runtime scope was added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Removed remaining hyphenated public guide wording from canonical Android notes**
- **Found during:** Task 1
- **Issue:** The readiness section used the public `first adopter` phrase, but canonical Android note text still rendered `first-adopter` into the same public guide.
- **Fix:** Updated the two canonical Android strings before regeneration so the complete guide uses the required public phrase consistently.
- **Files modified:** `lib/crosswake/support_matrix/support_matrix.ex`, `guides/support_matrix.md`
- **Verification:** Focused renderer suite and byte-parity test passed.
- **Commit:** `4c6b4841`

## Known Stubs

None.

## Next Phase Readiness

Phase 159 can consume a narrow public support baseline. Concrete route input, external-host proof, and physical-iPhone evidence remain explicitly deferred rather than manually approved.

## Self-Check: PASSED

- Required source, test, generated guide, validation ledger, and summary files exist.
- Task commits `030c5729`, `4c6b4841`, and `ccbccab0` exist in git history.
