---
phase: 175-rehearsal-and-publish
plan: 67
subsystem: release-diagnostics
tags: [aggregate-proof, workflow-roster, advisory-job, fail-closed]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan66 bounded aggregate diagnostic and existing workflow parser
provides:
  - Manifest-aligned aggregate evaluation with exactly one closed brand-visual advisory exception
  - Actual-local-workflow regression whose observed roster is derived independently from aggregate needs
affects: [quality-ratchet-release, phase-175-release-diagnostics]
actuals:
  tokens: 5800
  tasks: 2
  commits: 0
  plan_head_before: ffc84f8d4da6bba116b901332f6458fe3e95f9ca
tech-stack:
  added: []
  patterns: [closed advisory exception, independently parsed workflow roster regression]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-67-SUMMARY.md]
  modified:
    - lib/crosswake/release_candidate/ios_tag_source_runner.ex
    - test/crosswake/release_candidate/ios_tag_source_runner_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/continue.md
key-decisions:
  - "Exclude only the manifest-defined brand-visual job from governed aggregate authority, while requiring its literal workflow name and continued exclusion from needs."
  - "Treat the local result as a diagnostic explanation only; retained Plan66 evidence does not establish that remote workflow bytes matched the current local workflow."
patterns-established:
  - "Build synthetic run rosters from every parsed top-level workflow job declaration, independently of aggregate needs."
requirements-completed: []
coverage:
  - id: D1
    description: "The aggregate evaluator recognizes the one documented advisory and checks governed workflow/run roster coverage."
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/ios_tag_source_runner_test.exs#Plan67 reconciles the actual workflow against an independently parsed full run roster"
        status: pass
    human_judgment: false
  - id: D2
    description: "Existing Plan66 artifacts and closeout markers remain valid after Plan67 pointer updates."
    verification:
      - kind: other
        ref: "mix run Plan66 aggregate artifact and closeout validators"
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-10-02
status: complete
---

# Phase 175 Plan 67: Advisory Aggregate Diagnostic Summary

**The aggregate evaluator now accepts the 47 governed local workflow dependencies while keeping `brand-visual` visible and outside required authority.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-10-02T01:04:00Z
- **Completed:** 2026-10-02T01:37:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added one closed `brand-visual` advisory exception aligned with `script/check_ci_leaf_manifest.py`: the workflow job must exist with the literal display name and remain outside aggregate `needs`.
- Added an actual-workflow regression that derives all observed job names from top-level job declarations, independently of the `needs` list. The local 49-job workflow passes with 47 governed dependencies.
- Added mutations for governed dependency omission, advisory inclusion, advisory misnaming/removal, and an ungoverned job. Existing aggregate guard and closed-predicate cases remain covered.
- Kept Plan66 evidence, lifecycle, and closeout marker unchanged. Plan55 remains UNKNOWN; REL-13/REL-17 remain OPEN; candidate readiness remains BLOCKED; the release hold remains ACTIVE; Phase 175 remains incomplete.

## Task Commits

No task or metadata commits were made. The execution boundary explicitly prohibits Git write operations; Plan67 changes remain in the working tree.

## Files Created/Modified

- `lib/crosswake/release_candidate/ios_tag_source_runner.ex` — closed advisory exception and governed roster evaluation.
- `test/crosswake/release_candidate/ios_tag_source_runner_test.exs` — actual workflow roster and synthetic mutation regressions.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-67-SUMMARY.md` — this summary.
- `.planning/workstreams/quality-ratchet-release/STATE.md`, `ROADMAP.md`, and `phases/175-rehearsal-and-publish/continue.md` — current Plan67 status and safe continuation.

## Decisions Made

- The evaluator excludes only `brand-visual` from governed coverage and requires it to retain the manifest's literal name and remain absent from aggregate `needs`.
- The local 49-job/47-needs result explains a known advisory-shaped count difference; it does not prove the exact-head remote workflow bytes matched current local bytes because Plan66 did not retain those bytes.

## Deviations from Plan

None. The initial formatter check identified formatting needed in the new lines; `mix format` corrected it and the required check then passed.

## Verification

- `mix test test/crosswake/release_candidate/ios_tag_source_runner_test.exs` — 42 tests, 0 failures.
- `mix format --check-formatted lib/crosswake/release_candidate/ios_tag_source_runner.ex test/crosswake/release_candidate/ios_tag_source_runner_test.exs` — passed.
- `python3 script/check_ci_leaf_manifest.py --self-test` — 7 Python tests and all manifest contract mutations passed.
- Plan66 aggregate artifact and closeout validators — passed before and after the Plan67 pointer updates; Plan66 artifacts and markers remain unchanged.
- No network, remote read, CI, source, tag, merge, recovery, Gate 2, registry, or publication operation occurred.

## Issues Encountered

No implementation blocker. Git writes were unavailable by explicit execution constraint, so no commits or Git metadata updates were attempted.

## Next Phase Readiness

Plan67's local diagnostic repair is complete. Phase 175 remains incomplete and release-blocked. Plans 175-45 through 175-48 remain blocked behind Plan 175-44. The local evaluator result does not authorize another remote read, CI rerun, source action, or release action; any such work requires its own reviewed plan and applicable authority.

## Self-Check: PASSED

- Summary file exists and is referenced by the active roadmap/state/continuation pointers.
- Focused tests, formatting, manifest self-test, and unchanged Plan66 validators passed.
- Zero commits is recorded because Git write operations were prohibited.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-02*
