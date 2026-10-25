---
phase: 194-bearings-reset-and-adr-amendments
plan: 04
subsystem: planning-orientation
tags: [rolling-roadmap, bearings, personas, milestone-arc, plan-01, plan-02, plan-05]
requires:
  - phase: 194-03
    provides: PR1 on origin/main (28b2e71a), so "Android unfrozen" is true when written
provides:
  - .planning/ROADMAP-ROLLING.md (67 lines), .planning/BEARINGS.md (35 lines), .planning/PERSONAS.md (25 lines)
  - MILESTONE-ARC.md and JTBD-AND-USER-FLOWS.md historical banners (no body or heading edits)
  - PROJECT.md pointer to the rolling roadmap, pinned by the arc parity test
affects: [194-05, 194-08, 194-09]
key-files:
  created:
    - .planning/ROADMAP-ROLLING.md
    - .planning/BEARINGS.md
    - .planning/PERSONAS.md
  modified:
    - .planning/PROJECT.md
    - .planning/MILESTONE-ARC.md
    - .planning/research/JTBD-AND-USER-FLOWS.md
    - test/crosswake/planning/milestone_arc_closeout_parity_test.exs
actuals:
  tokens: 20000
  tasks: 3
  commits: 4
plan_head_before: 67e6c6648f7411355a503f56c790b1d4f6b3dd6e
plan_head_after: 47b54195f57c882e60256a034829c8821f0228e3
requirements-completed: []
status: complete
---

# Phase 194 Plan 04: Rolling roadmap, bearings, personas Summary

The three orientation files exist within their caps, MILESTONE-ARC.md and the root JTBD ordering are marked historical by banner only, and PROJECT.md points at the rolling roadmap under a passing test.

## Commits

- 0bf55873: record PR1 landing evidence (three named evidence files)
- 1ae8a69d: add rolling roadmap and point PROJECT.md at it
- 301e93f0: add bearings and mark milestone arc historical
- 47b54195: add personas and mark the root JTBD ordering superseded

## Results

- ROLLING: 67 lines, five sections once each in order, every row has six non-empty cells, no Checked column, counts marked `~`, DROPPED has the superseded-JTBD (not executed) and byte-snapshot rows, LATER has the PROJECT.md-split (250 lines), E7, E6 and notification re-entry rows, Loop rules carry the no-byte-snapshot convention.
- BEARINGS: 35 lines. Invariants 4 and 5 are pointers (AGENTS.md; ADR A1). Invariant 8 reads `clean-room command (Phase 195)` as a rule. Durable Lessons: three added as invariants 9-11, artifact parity covered by existing lines, the rest recorded as dropped with reasons in the ARC banner. Open traps keep only twin-05 (a53fbef).
- Tripwire sources: 194-EVIDENCE/bearings-sources-194.md. Three tripwires (pins the false value, piped gate, hand-maintained tables) had fewer than two repo-verifiable sources, so the "at least twice" wording was removed from the heading and every line.
- MILESTONE-ARC.md: banner on line 3; `cmp` of the body against origin/main exited 0. All 7 Durable Lesson titles appear in the banner.
- JTBD-AND-USER-FLOWS.md: two added lines, zero deleted, no heading edited.
- project586: still true (CHANGELOG.md line 10 and MILESTONE-ARC.md still document the vN.0 versus Hex 0.x distinction; the row sits at PROJECT.md line 591 now).
- Tests: milestone_arc_closeout_parity_test 7 tests, 0 failures; `mix test test/crosswake/guides/user_flows_test.exs test/crosswake/planning` 86 tests, 0 failures (194-EVIDENCE/doc-tests-04-194.txt, rc 0). Arc test diff has hunks only inside the one renamed test.

## Deviations from Plan

- PROJECT.md line numbers drifted (pointer at line 496, decision row at 591); targets were located by content.
- Requirements PLAN-01, PLAN-02, PLAN-05 are not marked Complete: PLAN-01's bearings-report cap check (plan 08), PLAN-02's AGENTS.md trim (plan 05) and PLAN-05's persona-tag coverage remain open.
- `roadmap update-plan-progress` is a no-op here; the plan line in the workstream ROADMAP.md was ticked by hand.
- Privacy scan was not run in this plan (plan 08/09 gate before the PR2 push); no `$` followed by two digits was written.

## Known Stubs

None.

## Self-Check: PASSED
