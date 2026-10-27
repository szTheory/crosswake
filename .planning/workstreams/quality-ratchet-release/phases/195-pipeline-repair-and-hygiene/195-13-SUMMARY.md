---
phase: 195-pipeline-repair-and-hygiene
plan: 13
subsystem: release-hygiene
tags: [branch-cleanup, archive-tags, pr-age, closeout]
requires: [195-12]
provides: ["remote heads reduced to the keep set", "10 archive/* tags preserving unmerged work", "closeout evidence branch docs/195-closeout pushed"]
affects: [phase-195-closeout, 199-REL-07]
status: complete
requirements-completed: [HYG-02, REL-05, REL-01]
commits: 4
plan_head_before: ff63e5d8
plan_head_after: f459008a
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/branches-195.txt
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/pr-age-195.txt
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/privacy-closeout-195.txt
actuals:
  tasks: 3
  commits: 4
---

# Phase 195 Plan 13: Branch cleanup, PR age audit and closeout branch Summary

The remote now holds only `main`, `release-please--branches--main` and the heads of open PRs #252 and #253 (plus `docs/195-closeout` once pushed). The 15 other branches are gone. The 10 with unmerged work were first preserved as `archive/<name>` tags, each read back at its branch tip. `plan_head_after` is the last commit before the commit that adds this SUMMARY, so `commits: 4` includes that final commit.

## What was checked and what happened

- Branch ledger: 19 remote heads at start (keep 4, delete_merged 5, archive_then_delete 10). Ledger line count equalled `git ls-remote --heads` count.
- Operations: 10 archive tags pushed and read back, 15 branches deleted with `--force-with-lease` bound to the ledger tip, each read back absent. Result lines: 0 `tag_conflict`, 0 `lease_failed`, 0 held branch ops.
- Final remote heads: `collateral/auto-refresh` (#253), `dependabot/github_actions/actions-4430c5f07e` (#252), `main`, `release-please--branches--main` (#236). `final_matches_keep_set yes`; the live compare at verify time also passes with `docs/195-closeout` added.
- Four branches (#250, #251, #254, #255) were deleted automatically at merge (`delete_branch_on_merge`), recorded `already_absent`, no gate.
- Worktrees: one line, the main checkout.
- Tags: `git ls-remote --tags origin` went from 94 to 114 lines. Method note: 94 was a line count, and annotated tags print a second peeled `^{}` line, so 114 = 94 + 10 new annotated archive tags x 2. The real new-tag count is 10 (`refs/tags/archive/*` without peeled lines). No existing tag was changed. Earlier plans' "tag count unchanged" statements refer to that same line count and are not contradicted; only the archive tags are new.
- Privacy scan on the changed files: rc 0, recorded in `privacy-closeout-195.txt`.
- Closeout branch pushed with upstream; remote head read back equal to local HEAD.

## PR age and #236

- #236 (release PR, age 15 days): OPEN, reason `release PR; merge is Phase 199 REL-07 behind its own allow; never closed`. Never closed by this plan.
- #252 and #253 are 0 days old.
- #236's head was rewritten by release-please twice during this plan (719c601 -> 64bd89e -> b1e8d95). On b1e8d95 the first CI run (40373281687) failed four contexts (`android-package-unit`, `phase18-elixir-android-proof`, `phase79-ios-proof`, `Crosswake CI`) because of HTTP 504 from builds.hex.pm and the Gradle download, not code. The failed jobs were re-run once; the re-run concluded success and a live read shows 50 of 50 contexts SUCCESS on b1e8d95, including the eight test jobs and the umbrella. `pr-age-195.txt` records this and its `final head` line was corrected from 64bd89e to b1e8d95.

## Deviations from Plan

**1. [Batch approval] One-time exception to "one operation per gate".** Gates 1 to 9 ran one at a time. The user then found per-operation gates to be busywork and gave one batch approval (ledger line `op: batch approval allow ...`) for the remaining 17 operations, each bound to its ledger tip, moved branches to be skipped. This is a plan deviation approved by the user, not a standing rule; it does not carry to any other operation. HYG-02 text says each remote delete is behind its own `allow`; it is marked complete here on the strength of that explicit user decision.
- **Classifier block:** Claude Code's auto-mode classifier blocked the agent from running the batch, so the user ran the script themselves. Result: all done, 0 skipped, 0 lease_failed, 0 tag_conflict, every operation read back.

**2. [Merge #253 refused]** `allow` was given, but the first attempt never executed (the pre-merge `gh pr view` returned HTTP 504; read-back OPEN). The single real attempt was refused by branch protection: head behind main, Crosswake CI never executed (run 40328488899 `action_required`). Recorded `result held refused_by_protection`; allow consumed; PR left open with reason `See It Run auto-refresh; merge held at the Phase 195 gate; re-offered at the next queue pass`.

**3. [Evidence corrections]** The auto-deleted branches were first recorded as gated ops by the plan's shape; they are recorded `already_absent` instead. The `docs/sigra-personal-account-authority-seed` tag was pushed at gate 8 and shows `already_tagged` on the batch pass. A `keep_set_note` line was split from `final_matches_keep_set yes` so the plan's exact-line verify matches. `pr1-merge-195.txt` and `pr2-merge-195.txt` carry correction lines.

**4. [Auth/CI]** A failed-job re-run of CI on #236 (not gated) was used for the 504 failures above.

## Verification results (rc)

| Check | rc |
|-------|----|
| Task 1 verify A (ledger lines, #236 age reason, 8 jobs, umbrella line) | 0 |
| Task 1 verify B (live: every open PR has a pr-age line; #236 OPEN; umbrella and 8 jobs green) | 0 after the CI re-run (first read: umbrella FAILURE on b1e8d95, see above) |
| Task 3 verify A (keep set, worktree, merged branches deleted, remote head equals HEAD) | 0 (re-run after the final push) |
| Task 3 verify B (14-day reasons, no PR closed) | 0 |

## Decisions pending for the user

none (no PR is recorded `owner-unknown; decision pending`).

## Follow-ups

- **#253** (See It Run auto-refresh) cannot merge until CI is approved and the branch is updated (12 commits behind main).
- **#252** (grouped Dependabot) was red from bandit advisories now fixed on main by #255; likely needs a rebase.
- `crosswake_inspect_test.exs:136` failed once (run 40361272003), cause unknown.
- `test/fixtures/ci/cancellation/cases.json` is orphaned.
- The derived-secret guard is line-based; multi-line derivations escape it.
- **Suggestion only (AGENTS.md not edited):** amend the approval-gate rule to allow one displayed-list approval for bulk branch cleanup, since the user found per-op gates to be busywork.
- Receiver for the rest: the phase closeout step opens the closeout PR for `docs/195-closeout` and later deletes that branch behind its own `allow`; #236 merge is Phase 199 REL-07.

## Known Stubs

None.

## Self-Check: PASSED
