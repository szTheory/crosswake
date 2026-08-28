---
phase: 158-adoption-reset-and-route-map
plan: "09"
subsystem: capability-map
tags: [elixir, markdown, capability-map, public-wording, privacy, tdd]
dependency_graph:
  requires: [158-07-SUMMARY.md, 158-08-SUMMARY.md, canonical-capability-map]
  provides: [approved-public-capability-wording, whole-render-phrase-regression, regenerated-capability-guide]
  affects: [phase-158-validation, public-capability-guidance]
tech_stack:
  added: []
  patterns: [canonical-source-regeneration, byte-parity, whole-render-vocabulary-guard]
key_files:
  created: []
  modified:
    - lib/crosswake/capability_map.ex
    - test/crosswake/capability_map/renderer_test.exs
    - guides/capability_map.md
decisions:
  - Canonical human-readable capability strings use `first adopter`; stable internal row IDs retain their established machine identity.
metrics:
  duration: 6m
  completed_date: 2026-07-31
  tasks_completed: 1
  files_changed: 3
status: complete
---

# Phase 158 Plan 09: Public Capability Wording Summary

Canonical capability implications and evidence-source text now render the approved public phrase throughout a byte-identical guide, with stable row IDs and support posture unchanged.

## Accomplishments

- Added a whole-render regression that requires `first adopter` and rejects both lowercase and capitalized hyphenated variants without storing another forbidden literal.
- Corrected every canonical implication and evidence-source string that reached the public capability guide.
- Regenerated `guides/capability_map.md` exclusively through `Crosswake.CapabilityMap.Renderer.write/0`.

## Verification

- RED passed: `mix test test/crosswake/capability_map/renderer_test.exs` failed the new whole-render rejection before canonical wording was repaired.
- Passed: `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/capability_map/renderer_test.exs` (17 tests, 0 failures).
- Passed: `mix format --check-formatted lib/crosswake/capability_map.ex test/crosswake/capability_map/renderer_test.exs`.
- Passed: `mix crosswake.adoption_context.scan`.
- Passed: case-insensitive guide scan found no hyphenated public spelling.
- Passed: `git diff --check`.

## TDD Gate Compliance

- RED: `0b9cf77c` — whole-render public phrase regression failed against the existing guide.
- GREEN: `2542e7b8` — canonical prose repair, renderer regeneration, and passing regression.

## Task Commits

1. **Task 1: Correct one canonical implication through regenerated public output**
   - `0b9cf77c` — failing whole-render public phrase regression.
   - `2542e7b8` — corrected canonical prose and regenerated guide.

## Decisions Made

- Public phrase enforcement applies to all rendered Markdown, including evidence-source values, while machine-facing stable row IDs remain unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Formatted the focused renderer test before GREEN verification**
- **Found during:** Task 1 verification.
- **Issue:** The required formatter check reported pre-existing layout drift in the focused test file.
- **Fix:** Applied the repository formatter to the task-owned source and test files, then reran the complete verification set.
- **Files modified:** `test/crosswake/capability_map/renderer_test.exs`
- **Commit:** `2542e7b8`

**Total deviations:** 1 auto-fixed (Rule 3: 1).
**Impact:** Formatting-only; no capability semantics, stable IDs, support posture, Android posture, or scope changed.

## Known Stubs

None.

## Self-Check: PASSED

- All three task files exist and the guide equals deterministic renderer output under the focused test suite.
- TDD commits `0b9cf77c` and `2542e7b8` exist in git history.
- No task commit deleted tracked files.
