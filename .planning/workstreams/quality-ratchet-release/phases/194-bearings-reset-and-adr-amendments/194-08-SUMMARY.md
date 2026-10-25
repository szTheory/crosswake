---
phase: 194-bearings-reset-and-adr-amendments
plan: 08
subsystem: planning-orientation
status: complete
tags: [bearings-report, caps, seeds, debt, persona-tags, truncation, plan-04, plan-05]
requires:
  - phase: 194-07
    provides: sync, PR-class and local-work checks
provides:
  - check_caps/2 (four orientation-file caps plus the PROJECT.md advisory), line_count/1
  - check_seeds/2, parse_frontmatter/1, parse_fires_when/1, check_debt/2
  - check_personas/2, persona_tags/1
  - truncate/1 (40 lines, verdict and UNVERIFIED lines always kept, counted overflow)
  - live, test-run and not-required evidence
affects: [194-09]
key-files:
  modified:
    - script/bearings_report.exs
    - test/crosswake/bearings_report_test.exs
  created:
    - test/fixtures/bearings/state.json
    - test/fixtures/bearings/requirements-tagged.md
    - test/fixtures/bearings/requirements-untagged.md
decisions:
  - "state.json milestone is 'v28.0 — Title' in the real file, so only the leading version token is used; the fixture copies the real shape."
  - "A seed with no frontmatter is open and prose-only (counted), not UNVERIFIED; UNVERIFIED only when no seed parses at all."
  - "Refuting test lines go through refute_line/2, which asserts the report is non-empty first."
actuals:
  tokens: 60000
  tasks: 3
  commits: 1
plan_head_before: 23cb8da3a73191436d566ee1b19821646d2062ba
plan_head_after: 11e03fb33506ba01f46a70749c9778f4358dd100
requirements-completed: [PLAN-04, PLAN-05]
---

# Phase 194 Plan 08: bearings-report caps, triggers, persona tags and 40-line cap Summary

`script/bearings-report` now also asserts the orientation-file line caps, evaluates seed `fires_when` triggers, counts carried debt, checks persona tags and caps its output at 40 lines with a counted overflow.

## What was checked and what happened

- Live run on this branch (`194-EVIDENCE/bearings-live-194.txt`): 15 lines, no UNVERIFIED line, rc 1 (real attention: 15 unpushed commits, CI has not run on local HEAD, 2 stale dependabot PRs, 2 unlanded local branches). Caps: ROLLING 67/120, BEARINGS 35/60, STATE 39/40, AGENTS.md 102/102 (the measured cap), all ok. PROJECT.md prints the advisory (643 lines). Seeds: open 22, machine-triggered 0, fired 0, prose-only 22. Debt: v27.0 carried 12. Personas: 30/30 tagged.
- Tests (`bearings-tests-08-194.txt`): bearings file 72 tests 0 failures; ownership and absence guards rc 0; `mix test test/crosswake/planning` 95 tests 0 failures; format and compile `--warnings-as-errors` rc 0; the merge-blocking lane 2747 tests 0 failures. A mutation (`>` to `>=` in the cap compare) made 2 tests fail, then was reverted.
- Not required (`required-check-194.txt`): no workflow references bearings (`git grep` rc 1) and the merge-blocking producers list (111 lines, so not empty) mentions it 0 times.
- Negative controls, each asserting exact line text: 120 ok and 121 OVER at every cap; missing and empty cap files; PROJECT.md 250 vs 251; satisfied and unsatisfied milestone and phase triggers; unparseable `fires_when`; shipped, harvested and closed seeds skipped; no seed files; no parsed frontmatter; missing and unparseable state.json; no closeout file and zero carried rows; grammar edges for tags (`[P8]`, `[J6]`, `[]`, `[p1]`, no colon, no space); no requirements; wrong milestone; 45 fired seeds give exactly 40 lines with the computed hidden count; UNVERIFIED lines survive truncation. Persona and seed tests use fixture files or in-memory maps only; no test reads a live planning file.
- PLAN-04 and PLAN-05 are marked Complete. PLAN-01..03 were left as they were by earlier plans.

## Deviations from Plan

**1. [Rule 3 - Blocking] Single code commit.** Tasks 1 to 3 edited the same script and test file, so commit 11e03fb3 holds all three tasks' code, fixtures and evidence instead of three commits.

**2. [Rule 1 - Bug] Collection-assertion ledger.** The first lane run failed 5 tests in the Phase 170 ledger test: 9 `refute/assert Enum.any?(lines, ...)` sites in the bearings test file were unclassified (4 from plans 06 and 07, 5 from this plan). Fix: replaced them with `assert_line/2` and `refute_line/2` helpers, where the refuting form asserts the report is non-empty first; the ledger needed no edit. Lane then passed.

**3. [Rule 1 - Bug] Evidence held home paths.** The raw lane output contained absolute home paths. Before the plan's commit was final, the test evidence file was reduced to step markers, test totals and `tests08:` lines and the commit amended (local, unpushed).

**4. state.json milestone format.** The real file has `"v28.0 — Truth and Release Train"`, not a bare version; the parser takes the leading token and the fixture mirrors the real shape.

## Known Stubs

None.

## Self-Check: PASSED

Commit 11e03fb3 present; three fixtures and three evidence files present.
