---
phase: 158-adoption-reset-and-route-map
plan: "06"
subsystem: privacy enforcement
tags: [elixir, mix-task, github-actions, filesystem-scan, privacy, tdd]
dependency_graph:
  requires: [158-04, first-adopter-context-routing]
  provides: [filesystem-privacy-gate, non-echoing-private-term-scan, ci-enforcement]
  affects: [phase-158-validation, protected-promotion, first-adopter-planning]
tech_stack:
  added: []
  patterns: [destination-tagged-glob-discovery, rule-path-only-failures, fork-safe-privileged-ci]
key_files:
  created:
    - lib/mix/tasks/crosswake.adoption_context.scan.ex
    - test/mix/tasks/crosswake_adoption_context_scan_test.exs
  modified:
    - lib/crosswake/planning/first_adopter_context.ex
    - test/crosswake/planning/first_adopter_context_test.exs
    - .github/workflows/hex-page-proof.yml
decisions:
  - Approved first-adopter artifacts are discovered through destination-tagged globs, including future Phase 158 artifacts.
  - Private-term violations disclose only a stable rule ID and repository-relative path.
  - Fork pull requests use generic enforcement; protected events require the secret-backed private-term input.
metrics:
  duration: 14m
  completed_date: 2026-07-31
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 158 Plan 06: Filesystem Privacy Gate Summary

Approved first-adopter planning and public artifacts now receive deterministic filesystem scans,
with a fork-safe Mix gate and protected private-term enforcement in merge-blocking CI.

## Accomplishments

- Replaced the planning scan's active-file snapshot with destination-tagged globs that cover current
  and future Phase 158 planning artifacts, governing documents, route-input drafts, agent guidance,
  and canonical public capability/support surfaces.
- Added a non-echoing filesystem scan and `mix crosswake.adoption_context.scan`; generic and
  private checks return only sorted stable rule IDs plus repository-relative paths.
- Added focused PLAN/SUMMARY/VALIDATION canaries and workflow enforcement: pull requests run the
  generic gate without private secrets, while protected non-PR events fail closed on missing input.

## Verification

- Passed: `mix test test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` (13 tests, 0 failures).
- Passed: `mix crosswake.adoption_context.scan`.
- Passed: `mix compile --warnings-as-errors`.
- Confirmed `.github/workflows/hex-page-proof.yml` invokes the generic and protected scan commands.

## Task Commits

1. **Task 1: Discover and scan one future planning artifact end to end**
   - `244960f4` — failing filesystem privacy scan regressions
   - `5b38eb80` — destination-tagged discovery and non-echoing filesystem scan
2. **Task 2: Wire the filesystem scan into the merge-blocking hermetic workflow**
   - `abc89abd` — failing Mix privacy-gate regressions
   - `9a077a3f` — Mix task and CI enforcement wiring

## Decisions Made

- The scanner reads only approved regular files selected by repository-relative globs; it does not
  inspect history, network sources, raw evidence, prompt lineage, or superseded brand seeds.
- Planning files no longer receive a private-term exception.
- Android remains untouched at its frozen generator, Maven, JVM, and vector posture.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture] Corrected an inverted temporary-path join in the new tracer**
- **Found during:** Task 1 RED run.
- **Fix:** Corrected the fixture directory construction, removed the test-generated empty directory,
  and reran the failing tracer before implementation.
- **Verification:** Focused context suite passes.

**2. [Rule 2 - Coverage] Removed the remaining static active-artifact snapshot from the pure scan seam**
- **Found during:** Task 2 acceptance review.
- **Fix:** `routing_matrix/0` now derives active scan paths from the same approved glob discovery as
  the filesystem gate, keeping only explicit non-file exclusion boundaries static.
- **Verification:** Context and Mix-task suites pass; the repository gate passes.

## Known Stubs

None.

## Self-Check: PASSED

- Required context scanner, Mix task, focused tests, and workflow files exist.
- All four TDD gate commits are present in git history.
- No private term, matched line, or surrounding contents are printed by scanner violations.
