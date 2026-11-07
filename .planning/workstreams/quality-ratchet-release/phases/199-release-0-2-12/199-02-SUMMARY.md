---
phase: 199-release-0-2-12
plan: 02
subsystem: release
tags: [pr-queue, dependabot, collateral, release-gates, d-06]

requires:
  - phase: 199-release-0-2-12
    provides: "199-01 decisions (D-06 B) and the gate protocol"
provides:
  - "199-EVIDENCE/queue-199.txt: one disposition block per open non-release PR (252, 253, 258) plus main_after_queue"
  - "main left unmoved by the queue (0a9ba2913c37 before and after), so the release candidate is measured on a stable main"
affects: [199-03, 199-19]

plan_head_before: 6ac750402e794c99968dbd9d1b12b5ab580cb33d
plan_head_after: 3b720fc6aeeaa6de64a5748f8aa3b25b696f717e

actuals:
  tokens: 1800
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "merge only on green CI on the exact head; otherwise close with a recorded, reopenable reason"
    - "image PRs: download at the PR head to scratch, open every file, record one looked: line per file"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/queue-199.txt
  modified: []

key-decisions:
  - "PR 252 closed, not merged: CI red on the exact head for a real cause (repo pin guard asserts setup-java de7274f0; the bump changes it to b843ebf9)"
  - "PR 258 closed per D-06 B (user's explicit instruction, 2026-11-07)"
  - "PR 253 left open for the user: images fine, but no CI ever ran on its head, and the close command was denied by the permission system"

requirements-completed: []

coverage:
  - id: D1
    description: "PR 252 (Dependabot actions bump) disposed of with the cause recorded and no agent commit on the bot branch"
    requirement: REL-07
    verification:
      - kind: other
        ref: "gh pr view 252 --json state -> CLOSED; commit authors -> [dependabot[bot]]"
        status: pass
    human_judgment: false
  - id: D2
    description: "PR 258 closed with the D-06 B reason"
    requirement: REL-07
    verification:
      - kind: other
        ref: "gh pr view 258 --json state -> CLOSED"
        status: pass
    human_judgment: false
  - id: D3
    description: "PR 253 collateral refresh: all four images looked at and recorded, but the PR is still open"
    requirement: REL-07
    verification:
      - kind: other
        ref: "grep -c '^looked: ' queue-199.txt -> 4 (PR changes 4 files); gh pr view 253 --json state -> OPEN (Task 2 verify FAILS)"
        status: fail
    human_judgment: true
    rationale: "The close of PR 253 was denied by the permission system and needs the user to close it or allow the agent to"

duration: "about 5 min (13:25Z to 13:30Z, 2026-11-07)"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 02: Pre-release PR Queue Summary

**Of the three non-release PRs, 252 (Dependabot) and 258 (Codex profile switch) are closed with recorded reasons and nothing was merged, so main did not move; PR 253 (collateral refresh) is still open because its close was denied and is left to the user.**

## What was checked

- Read `delete_branch_on_merge` on the repo: `false`, as required before any merge. No merge was needed in the end.
- PR 252: CI on its exact head `956e4094344e` (run 42168186565) failed. It was not stale (the branch parent is current main), so a rebase comment would not help. Real cause: `test/crosswake/proof/phase165_ci_integrity_test.exs` ("all setup-java uses share the official immutable v6 commit") asserts the single pinned commit `de7274f0...`, and the Dependabot bump changes it to `b843ebf9...` (v6.1.0). Closed with that reason; Dependabot reopens monthly. Only `dependabot[bot]` authored commits on the branch; nothing was pushed.
- PR 253: downloaded all four changed files at the PR head and opened each one (three PNGs, one GIF; the GIF was also sampled at frames 12, 24 and 36 and compared with main's version). All four render correctly and show no private identifiers. But the only Crosswake CI run for that head (41401898229) ended `action_required` and no check ran, so the "green CI on the exact head" condition for a merge cannot be met.
- PR 258: closed under D-06 B with the reason "local GSD Codex model-routing switch not wanted while the project runs on Claude; reopenable". Not merged. Its only changed file is `.planning/config.json`.
- Main before and after the queue: `0a9ba2913c371f7671f534060d9c8154629de5a0` (unchanged). PRs 236 and 262 were not touched.

## What is unknown, and why

- Whether PR 253 should be closed or have its CI approved and then merged. The plan says to close it when CI is not green on the head. The `gh pr close 253` call was denied by the Claude Code permission classifier ("External System Writes"). It was not retried or worked around; PR 253 is untouched and OPEN.

## Next action for the user

Close PR 253 (`gh pr close 253`) or tell the agent it may. The See It Run Collateral workflow (weekly, Mondays 06:17 UTC, or manual dispatch) opens a fresh refresh PR. PR 253 was created 2026-10-26 and turns 14 days old on 2026-11-09, after which the bearings report counts it as ATTENTION (SC4); plan 199-19 checks again, and if it is still open there, SC4 is unmet.

## Task Commits

1. **Task 1: Tracer, dispose of Dependabot PR 252** - `2a60c416` (docs)
2. **Task 2: Look at PR 253 images, then merge or close** - images looked at and recorded; close denied, so no GitHub change; record committed with Task 3
3. **Task 3: Apply D-06 to PR 258 and commit the queue record** - `3b720fc6` (docs)

**Plan metadata:** committed after this file (docs: complete plan).

## Deviations from Plan

### Blocked step

**1. [Not a rule deviation - external block] PR 253 close denied**
- **Found during:** Task 2
- **Issue:** `gh pr close 253 --comment ...` was denied by the permission system. The plan's Task 2 verify (`gh pr view 253 --json state` is MERGED or CLOSED) therefore fails.
- **Action taken:** recorded `merge_blocked`, `close_attempt` and `action: left_to_user` in queue-199.txt; did not retry or use another route; PR 253 untouched.
- **Files modified:** queue-199.txt only.

### Plan variance

**2. Tasks 2 and 3 share one commit.** Both only touch queue-199.txt and the 253 record was written after the denied close, so they were committed together as the plan-specified `docs(199-02): record pre-release PR queue dispositions`. `git show --stat HEAD` for that commit lists only queue-199.txt.

**Total deviations:** 1 blocked step, 1 commit grouping. **Impact:** the plan's must-have "every open non-release PR is merged, closed or left to the user per D-06" holds in the "left to the user" form for PR 253; SC4 depends on the user's action before 2026-11-09 or on plan 199-19.

## Issues Encountered

PR 253's close denied (above). Plan 199-03 and later are not blocked by it: main is stable and PR 253 can never merge to main in its current state.

## Known Stubs

None.

## Threat Flags

None. No merge, tag, publish or branch deletion happened; no branch of any bot or PR was modified.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 199-03. Main is `0a9ba2913c371f7671f534060d9c8154629de5a0`.
- REL-07 is not complete (later plans finish it).

## Self-Check: PASSED

- queue-199.txt exists with three `action:` lines (252 closed, 253 left_to_user, 258 closed) and `main_after_queue: 0a9ba2913c371f7671f534060d9c8154629de5a0`; `looked:` lines = 4 = files PR 253 changes.
- Commits `2a60c416` and `3b720fc6` are on `ci/199-release-gates`; measured commit count from the plan ledger is 2.
- PR 252 authors `[dependabot[bot]]`, state CLOSED; PR 258 state CLOSED; PR 253 state OPEN (recorded, not hidden); PRs 236 and 262 untouched.
- Self-check of the plan's Task 2 verify: FAILS on PR 253 state, disclosed above.

---
*Phase: 199-release-0-2-12*
*Completed: 2026-11-07*
