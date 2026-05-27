---
phase: 19-commerce-route-corridors
plan: 03
subsystem: support-truth
tags: [commerce, support-matrix, doctor, docs, fail-closed]
requires:
  - phase: 19-commerce-route-corridors-01
    provides: canonical corridor registry and route corridor ownership truth
  - phase: 19-commerce-route-corridors-02
    provides: canonical fail-closed `commerce.corridor.*` denial mapping
provides:
  - deterministic commerce corridor support-matrix section rendered from canonical source data
  - doctor human/json corridor diagnostics with canonical denial IDs and parity coverage
  - public corridor ownership and denial/fallback guidance locked by docs tests
affects: [phase-20-entitlement-lifecycle-semantics, phase-22-commerce-support-review-proof, doctor-support-truth, support-matrix-docs]
tech-stack:
  added: []
  patterns: [canonical corridor taxonomy parity, matrix-first commerce ownership guidance, deterministic support surface rendering]
key-files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/support_matrix/renderer.ex
    - guides/support_matrix.md
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/doctor/formatter.ex
    - lib/crosswake/doctor/json_formatter.ex
    - guides/commerce.md
    - guides/capabilities.md
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/support_matrix/renderer_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/doctor/formatter_test.exs
    - test/mix/tasks/crosswake_doctor_test.exs
    - test/crosswake/guides/commerce_test.exs
    - test/crosswake/guides/capabilities_test.exs
key-decisions:
  - "Published corridor support truth through a deterministic renderer section instead of hand-maintained guide prose."
  - "Standardized doctor corridor diagnostics on canonical `commerce.corridor.*` IDs and emitted parity assertions against support-matrix taxonomy."
  - "Documented corridor ownership and denial/fallback semantics matrix-first while explicitly keeping provider adapters out of Phase 19 scope."
patterns-established:
  - "Support matrix, doctor output, and guides share one canonical corridor denial vocabulary."
  - "Guide and CLI tests lock corridor ownership posture and fallback truth to prevent documentation drift."
requirements-completed: [COMM-05, COMM-06, COMM-04]
duration: 6 min
completed: 2026-05-27
---

# Phase 19 Plan 03: Commerce Corridor Support Truth Summary

**Crosswake now publishes synchronized commerce corridor support truth across support matrix, doctor output, and public guides with canonical fail-closed denial vocabulary.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-27T09:24:00Z
- **Completed:** 2026-05-27T09:30:50Z
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments
- Added a deterministic `## Commerce Corridors` support-matrix section with ownership posture, prerequisites, denial codes, fallback behavior, and rebuild truth.
- Added canonical doctor corridor findings for undeclared, prerequisite-missing, and runtime-incompatible posture with `corridor_ref`, `role`, `denial_code`, and `fallback_hint` in human and JSON output.
- Updated commerce/capabilities guides to publish matrix-first ownership guidance and all eight canonical `commerce.corridor.*` denial/fallback codes.
- Locked the above surfaces with support-matrix, doctor/CLI, and guide tests, including taxonomy parity assertions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add commerce corridor support truth section to support matrix generation/rendering** - `c1d4042` (feat)
2. **Task 2: Extend doctor findings and formatter output for corridor prerequisites and fail-closed guidance** - `66de8f9` (feat)
3. **Task 3: Update commerce/capabilities guides with explicit corridor ownership and fallback semantics** - `d1a817b` (feat)

## Verification Results
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` -> pass (14 tests, 0 failures)
- `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/mix/tasks/crosswake_doctor_test.exs` -> pass (12 tests, 0 failures)
- `mix test test/crosswake/guides/commerce_test.exs test/crosswake/guides/capabilities_test.exs` -> pass (8 tests, 0 failures)
- `rg "Commerce Corridors|commerce\\.corridor\\.|provider adapters are out of scope" guides lib/crosswake/support_matrix lib/crosswake/doctor` -> pass

## Files Created/Modified
- `lib/crosswake/support_matrix/support_matrix.ex` and `lib/crosswake/support_matrix/renderer.ex` - canonical corridor support entries and deterministic rendered section.
- `guides/support_matrix.md` - generated support truth now includes commerce corridor table.
- `lib/crosswake/doctor/doctor.ex` - corridor-specific canonical findings plus compile-error mapping for undeclared corridor diagnostics.
- `lib/crosswake/doctor/formatter.ex` and `lib/crosswake/doctor/json_formatter.ex` - explicit corridor fields in human/json outputs.
- `guides/commerce.md` and `guides/capabilities.md` - matrix-first ownership and canonical denial/fallback guidance with Phase 19 scope guard.
- `test/crosswake/support_matrix/*`, `test/crosswake/doctor/*`, `test/mix/tasks/crosswake_doctor_test.exs`, `test/crosswake/guides/*` - regression coverage for corridor taxonomy and docs language lock.

## Decisions Made
- Kept support truth provider-neutral by publishing ownership posture and denial taxonomy without introducing adapter implementation details.
- Used canonical denial IDs as the single identifier across support-matrix entries, doctor findings, and public docs.
- Added parity assertions in doctor tests to ensure emitted corridor IDs never drift from support-matrix canonical taxonomy.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 19 is complete (3/3 plans) with support and guidance truth aligned to canonical corridor semantics.
- Milestone workflow is ready to advance into Phase 20 entitlement lifecycle semantics.

---
*Phase: 19-commerce-route-corridors*
*Completed: 2026-05-27*
