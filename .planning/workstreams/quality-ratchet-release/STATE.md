---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 195
current_phase_name: Pipeline repair and hygiene
status: executing
stopped_at: Completed 195-13-PLAN.md
last_updated: "2026-10-26T21:18:06.367Z"
state_head: e4367b4ac22b4f1267306a4a439103ceb02db6b7
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 24
  completed_plans: 22
  percent: 50
last_activity: 2026-10-25
last_activity_desc: Phase 195 planned
---

# Project State

See `.planning/BEARINGS.md` (posture and tripwires), `.planning/ROADMAP-ROLLING.md` (now, next, later, parked) and [ROADMAP.md](ROADMAP.md) for the v28.0 phases 194–199.

## Current Position

Phase: 195 (Pipeline repair and hygiene) — EXECUTING
Plan: 14 of 15
Status: Executing Phase 195

## Exact Next Action

What was checked: all 13 Phase 195 plans executed. PRs #250, #241, #240, #239, #211, #210, #238, #251, #254 and #255 are merged, each behind its own `allow`. The Weekly Canary is green on main (run 40354096432). The full `mix test` run (2788 tests) and `node --test` (148) pass. The code review (195-REVIEW.md) and the verifier (195-VERIFICATION.md) both ran. What happened: verification returned `gaps_found` (7 of 8). REL-03's `maskSecretShapes` leaks quoted secret values (`KEY="v"`), mid-line `Cookie:` headers and multi-word quoted passwords (review CR-01 and CR-02, reproduced on main), so "CI never echoes secrets" does not hold. What is unknown: nothing blocks planning the fix. Nothing was released or published. 10 `archive/` tags were pushed and 15 remote branches deleted under HYG-02. Open PRs: #236 (release, green on b1e8d95), #252 (grouped Dependabot) and #253 (collateral auto-refresh, held). The phase evidence is on the pushed branch `docs/195-closeout`, and its closeout PR is not opened yet.

Next action: `/gsd-plan-phase 195 --gaps --ws quality-ratchet-release` (plan the masking fix: failing seeds first, then the regexes; include WR-01 to WR-03), then `/gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release`.

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

## Decisions

- [Phase 195]: Shell fixture comparisons normalize only version-derived values (stamp, crosswake_version, SwiftPM minimumVersion) on both sides; fixtures keep literal 0.2.11
- [Phase 195]: Plan 13: one-time user-approved batch for 17 branch ops (not a standing rule); #253 merge held, refused by protection

## Session

**Last session:** 2026-10-26T20:25:08.146Z
**Stopped at:** Completed 195-13-PLAN.md
**Resume file:** None

### Blockers

- Follow-up: test/mix/tasks/crosswake_inspect_test.exs:136 failed once in CI run 40361272003 (head 3b170221), did not recur; cause unknown
