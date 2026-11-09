---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 06
subsystem: release-train
tags: [rel-09, release-gates, core-merge, core-tags, release-0.2.13]

requires:
  - phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
    provides: 200-05 pre-merge capture, checked trailer and staged merge command for PR 280 head 5a6a7521
provides:
  - release PR 280 merged as a two-parent merge commit 0aa18470 under the user's own allow (core-merge attempt 1)
  - release run 42639651064 passed its guard and waited at release-tags
  - hex-v0.2.13, ios-core-v0.2.13 and android-core-v0.2.13 and their three GitHub Releases created at the merge commit under one shared allow (core-tags attempt 1)
  - the run now waits at publish-hex only; nothing is published
affects: [200-07]

plan_head_before: 694a2f0331c90c9cfc3da9ff120df480c3e21fe8
plan_head_after: dba9775c903b85b52071e0688dfa0d3149e74adb
commits: 4

actuals:
  tokens: 1700
  tasks: 3
  commits: 4
# tokens: chars/4 over `git diff 694a2f03..dba9775c` (6955 bytes); the plan's work was reads and two gated actions, so the written diff is small.

pr: 280
candidate_head: 5a6a752185cc557af30b0f87244b8088ac83ff93
merge_commit: 0aa184704009c5baf9c3550cf7cf7fde9228f2b8
release_run_id: 42639651064

tech-stack:
  added: []
  patterns:
    - "orchestrator displays each gate and acts on the user's reply; the plan agent re-reads facts, writes prechecks and verifies afterwards"
    - "merge as a merge commit pinned with --match-head-commit, body exactly one checked REL17-AUTHORIZATION line"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-merge-200.json
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/core-tags-200.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-EVIDENCE/gates-200.txt

key-decisions:
  - "The standing wishes the user voiced in both replies (not to be asked again) were recorded as `# note:` lines and were not used to skip any display, recheck or later gate; their scope is handled outside this plan"
  - "The guard-run age rule was applied as resolved in 199-10: the latest release-please.yml run on main (42555894094) ran on the current main head e8d44c6c, which is the release PR base"

requirements-completed: []

coverage:
  - id: D1
    description: "Release PR 280 merged only after its own allow, as a two-parent merge of the approved base and head with the approved tree and one trailer"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "gate-order-200.awk core-merge (head= and merge_commit=) exit 0; live read: parents e8d44c6c and 5a6a7521, tree 4605bb05 equal, one REL17-AUTHORIZATION line, ancestor of origin/main; core-merge-200.json jq verify exit 0 after the schema conformance commit"
        status: pass
    human_judgment: false
  - id: D2
    description: "The three source tags and releases were created only after one shared allow bound to the release run, with no publisher started"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "gate-order-200.awk core-tags (run=42639651064) exit 0; git ls-remote shows three tags at 0aa18470; three releases listed; pending deployments exactly publish-hex; Hex 0.2.13 still 404; mirror tag v0.2.13 absent; core-tags-200.json jq verify exit 0 after the schema conformance commit"
        status: pass
    human_judgment: false

duration: "about 37 min wall clock on 2026-11-09 (14:30Z to 15:07Z), almost all of it waiting for the user's replies"
completed: 2026-11-09
status: complete
---

# Phase 200 Plan 06: Merge and source-tag gates Summary

**Release PR 280 (Crosswake 0.2.13) was merged under the user's allow as `0aa184704009c5baf9c3550cf7cf7fde9228f2b8` (parents base `e8d44c6c` and approved head `5a6a7521`, tree equal, one trailer); the release run passed its guard, the user's second allow approved only `release-tags`, three source tags and releases now exist at that commit, and the run waits at `publish-hex` with nothing published.**

## What was checked and what happened

- **Task 1 (tracer), commit `d0e27270`.** Before the merge gate I re-read every fact it depends on: PR 280 open, CLEAN, head and base as captured; Crosswake CI run 42556235341 green on that head (39 of 39; it checked out the synthetic merge `ccb950d5`, not the head); the CI `default-ios-build` PASS line and the 200-05 remote-form PASS unchanged; the one unexpired receipt (id 13681238151, expires 2026-11-23T14:19:07Z); Hex, Maven POM, mirror tag and source tags all absent; auto-delete false; environment preflight rc 0; the latest Release Please run on main (42555894094, on the current main head) ending `release-env: verdict=PASS`; a fresh REL-17 pre-merge capture whose envelope sha256 equals the committed one; trailer rendered and checked. The PASS precheck line was written at 14:32:20Z, bound to the captured head.
- **Gate core-merge attempt 1 (orchestrator).** Displayed 14:33:33Z. The reply came about 23 minutes later; facts were rechecked at 14:56:42Z (after the `gate:` line), `decision: allow` at 14:56:44Z, then the staged merge ran once, at 14:56:44Z. PR 280 shows MERGED at 14:56:48Z with merge commit `0aa18470`.
- **Release run 42639651064** (head `0aa18470`): guard job success; the run waited at `release-tags`.
- **Gate core-tags attempt 1 (orchestrator).** Precheck 14:58:36Z (one pending entry, `release-tags`, environment id 26568191383, guard success, Hex 404), gate 14:58:37Z, reply-time precheck 15:00:09Z, decision allow 15:00:11Z, one approval of exactly that environment id with comment `200 core-tags attempt 1`. Release Please then succeeded.
- **Read by me after the fact (read-only):** `git ls-remote` shows `hex-v0.2.13`, `ios-core-v0.2.13` and `android-core-v0.2.13` pointing directly at `0aa18470` (lightweight tags, so no peeling step); the three GitHub Releases exist (not draft, not prerelease); the run is `waiting` with exactly one pending deployment, `publish-hex` (id 26568191797); `publish-hex` job waiting, the five companion publish jobs skipped; Hex 0.2.13 returns 404; mirror tag `v0.2.13` is absent; auto-delete is still false.

## What is unknown, and why

- Whether Hex, Maven or the iOS mirror will accept 0.2.13: nothing has been published, by design. Each publisher needs its own allow in 200-07 and 200-08.
- The guard's trailer check passed in the run, but its log was read only as a job conclusion here, not line by line.
- The merge happened about 23 minutes after the display. Every fact was rechecked at reply time and the gate checker accepts it (its window is display-to-precheck, not display-to-reply), but a long gap is a thing the reader should know.

## Task Commits

1. **Task 1 (tracer): core-merge precheck** - `d0e27270`
2. **Task 2: gate core-merge and the merge** (orchestrator) - `b0f3effd`
3. **Task 3: gate core-tags and the tag approval** (orchestrator) - `789507bf`
4. **Evidence schema conformance** (this continuation) - `dba9775c`

Measured from the plan ledger: 4 commits on `docs/199-release-0-2-12`, base `694a2f03`. Local only; nothing pushed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Evidence records did not match the plan-declared schema**
- **Found during:** continuation verify of Tasks 2 and 3
- **Issue:** the orchestrator wrote `core-merge-200.json` and `core-tags-200.json` with `merged_at_utc`, `delivery: "ACCEPTED"`, no `delete_branch_on_merge_read`, `tags` as an array, no `releases_present`, `guard`, `environment_id` or `approval_comment`. The plan's two jq verifies (Task 2 second verify, Task 3 second verify) therefore exited 1 on the first run, while both gate-order awk checks exited 0.
- **Fix:** added or reshaped those fields with `jq` from facts re-read live and from `gates-200.txt` (tags as name to merge commit, `releases_present` 3, `delivery` `accepted`, `delete_branch_on_merge_read` false from the 14:56:42Z reply-time precheck and the live read). No fact changed. Both jq verifies then exit 0.
- **Files modified:** `200-EVIDENCE/core-merge-200.json`, `200-EVIDENCE/core-tags-200.json`
- **Commit:** `dba9775c`

### Plan variances

- The gates were displayed and acted on by the orchestrator, and Tasks 2 and 3 were not run as the plan agent's own checkpoints, because a plan agent cannot see the user's replies. The plan says this in its action text.
- The plan's literal guard-run age rule ("no older than the PR head's CI run") was replaced by the 199-10 resolution (latest Release Please run on main, ran on the current main head), as the dispatch instructed.
- Two `# note:` lines were added to `gates-200.txt` by the orchestrator to record the user's standing wishes. The checker accepted them (comment lines are ignored); they authorize nothing.

**Total deviations:** 1 auto-fixed (schema conformance), 3 variances. **Impact:** none on scope, order or the gates; one merge, one tag approval, no other external action.

## Issues Encountered

None blocking. While the source tags exist and the mirror tag `v0.2.13` does not, the mirror parity check on open PRs is red until the iOS gate is done, as the tag-gate display warned.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or schema; no secret values were read or recorded (token-shape grep over both new records found nothing).

## User Setup Required

None.

## Next Phase Readiness

- Ready for 200-07: the core-hex and core-maven gates. The run is 42639651064 (https://github.com/szTheory/crosswake/actions/runs/42639651064), waiting at `publish-hex` (pending deployment id 26568191797, `current_user_can_approve` true). Every later gate line is bound to `run=42639651064`; the merge commit is `0aa184704009c5baf9c3550cf7cf7fde9228f2b8`.
- No publisher has started. Hex 0.2.13 is 404, the 0.2.13 Maven POM is 404, the mirror tag is absent. Nothing here authorizes any later gate; each needs its own displayed allow.
- REL-08 and REL-09 stay incomplete until the publishes and post-publish proofs finish.

## Self-Check: PASSED

- Files present: `200-06-SUMMARY.md` (this file), `core-merge-200.json`, `core-tags-200.json`, `gates-200.txt`.
- Commits `d0e27270`, `b0f3effd`, `789507bf` and `dba9775c` are ancestors of HEAD; the measured count from the plan ledger is 4.
- Both gate-order checks exit 0; both jq verifies exit 0; `.planning/config.json`, `.review-diagnostics/` and the phase `.gitkeep` are in no plan commit.
