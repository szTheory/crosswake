---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: pipeline-repair-and-hygiene
status: executing
stopped_at: Completed 195-17-PLAN.md
last_updated: "2026-10-26T23:18:20.924Z"
state_head: ec6893f3babec3902e5743fbb2f545de795662cb
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 27
  completed_plans: 26
  percent: 50
last_activity: 2026-10-25
last_activity_desc: Phase 195 planned
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 195 (pipeline-repair-and-hygiene) — EXECUTING
Plan: 18 of 18
Status: Ready to execute

## Exact Next Action

What was checked: gap plans 195-14 and 195-15 executed. PR #256 (masker fix) merged to main as 5862a3d behind its own `allow`; GitHub deleted its branch as approved; Release Please is green on 5862a3d; `node --test` passes 186 of 186; the verifier's four original REL-03 cases are closed on main. Review dispositions: CR-01 to WR-03 fixed; WR-04, WR-05, WR-06 and IN-03 deferred to Phase 197 (carried line in ROADMAP); IN-01 and IN-02 wontfix (route `accept`). What happened: the verifier returned `passed`, but a focused review of the two changed files (195-REVIEW-GAP.md) reproduced further leaks, re-confirmed on main: credential keys in Elixir tuple, escaped-JSON and CLI-flag forms (GR-01), and a single-quoted `::add-mask::` that passes the guard (GR-02). Verification is recorded as `gaps_found` (7 of 8). What is unknown: nothing blocks planning. Nothing was released, published or tagged (114 tags). `docs/195-closeout` is pushed; its closeout PR is not opened yet.

Next action: `/gsd-plan-phase 195 --gaps --ws quality-ratchet-release` (GR-01 and GR-02 seeds first, then the fix; triage GR-03 to GR-10), then `/gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release`.

## Carried debt

See [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md); the v23 deferred table is in `milestones/v23.0-closeout`. The adopter lane stays parked; its resume is in ROLLING PARKED.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 195 P01 | 100 min | 3 tasks | 11 files |
| Phase 195 P04 | 1 session | 2 tasks | 6 files |
| Phase 195 P06 | 25min | 2 tasks | 10 files |
| Phase 195 P07 | 25min | 2 tasks | 9 files |
| Phase 195 P08 | 30m | 2 tasks | 7 files |
| Phase 195 P09 | 1 session | 3 tasks | 4 files |
| Phase 195 P10 | 40m | 2 tasks | 22 files |
| Phase 195 P11 | 30m | 3 tasks | 8 files |
| Phase 195 P12 | continuation | 3 tasks | 3 files |
| Phase 195 P13 | continuation | 3 tasks | 3 files |
| Phase 195 P14 | 40min | 3 tasks | 2 files |
| Phase 195 P15 | 20min | 3 tasks | 8 files |
| Phase 195 P16 | 45 min | 3 tasks | 2 files |
| Phase 195 P17 | 1h | 3 tasks | 2 files |

## Decisions

- [Phase 195]: Shell fixture comparisons normalize only version-derived values (stamp, crosswake_version, SwiftPM minimumVersion) on both sides; fixtures keep literal 0.2.11
- [Phase 195]: Plan 13: one-time user-approved batch for 17 branch ops (not a standing rule); #253 merge held, refused by protection
- [Phase 195]: 195-14: maskSecretShapes rules are same-line only with a required separator for generic keys; quoted values masked through closing quote (unterminated to EOL); seeds >=8 chars fake-prefixed; seed-bearing assertions are assert.ok with value-free messages
- [Phase 195]: PR #256 merged (5862a3d) on one-use allow; review route accepted: WR-04/05/06 and IN-03 deferred to Phase 197, IN-01/02 wontfix
- [Phase 195]: 195-16: value capture groups named; next-line pass runs first; accepted over-masks pinned in ACCEPTED_OVERMASK
- [Phase 195]: 195-17: GR-06 deferred on evidence; live workflow tree census 0 for all seven unparsed bash forms
- [Phase 195]: 195-17: GR-07 numeric/header-prose values stay masked (ACCEPTED_OVERMASK); literal nil/true/false/null/undefined whole values unmasked

## Session

**Last session:** 2026-10-26T23:18:20.892Z
**Stopped at:** Completed 195-17-PLAN.md
**Resume file:** None

### Blockers

- Follow-up: test/mix/tasks/crosswake_inspect_test.exs:136 failed once in CI run 40361272003 (head 3b170221), did not recur; cause unknown
