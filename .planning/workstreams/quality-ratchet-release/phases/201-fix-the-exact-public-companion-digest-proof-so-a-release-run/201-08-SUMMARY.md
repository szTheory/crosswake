---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 08
subsystem: release-train
tags: [rel-08, rel-09, reconcile, ledger, landing, privacy]
requires:
  - phase: 201-07
    provides: 0.2.14 release run 42713010358 COMPLETE with exact-public fully proven for six packages
provides:
  - 0.2.12 and 0.2.13 reconciled from live reads, issue 281 and TODO-012 closed
  - REL-08 and REL-09 Complete with the REL-09 amendment; REL-07 and Phase 199 SC1 and SC2 annotated; Phase 200 9/9 and Phase 201 8/8
  - the 0.2.13 and 0.2.14 ledger lines and 187 planning-record paths on main through PR 289 (merge af1dd94e)
affects: [phase-199-replanning]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/reconcile-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/landing-privacy-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/ledger-pr-201.json
    - .planning/workstreams/quality-ratchet-release/history/201-08-prior-handoff.md
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-08-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/200-forward-fix-and-release-0-2-13-default-ios-generation-builds/200-09-SUMMARY.md
  modified:
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/todos/TODO-012-exact-public-proof-assumes-a-linked-six-package-release.md
    - docs/release-ledger/RELEASE-LEDGER.jsonl
decisions:
  - "The 0.2.14 ledger line was generated with script/append_release_ledger.sh because the runner's record-ledger job opened no PR while ledger PR 285 was open (orchestrator decision)"
  - "Local home-directory prefixes in the landed planning files were written as ~ (the 201-02 rule, applied to 33 more files); raw pre-merge sources stay unedited and are left out"
  - "The first-adopter scan has no rule for .awk, so gate-order-200.awk was left out of the landing after CI stopped on it"
requirements-completed: [REL-08, REL-09]
actuals:
  tokens: 40501
  tasks: 3
  commits: 4
plan_head_before: 52000f6c9346740d37676e8f3b8c715c8d2eae25
plan_head_after: 386455bd8ce6641f407ee532665bf89f0c7e0cd1
duration: about 45 min of agent work plus a 23 min CI wait
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 08: Closeout, reconciliation and landing Summary

**0.2.12 and 0.2.13 are reconciled in writing against the COMPLETE 0.2.14 run, issue 281 and TODO-012 are closed, REL-08 and REL-09 are Complete, and both ledger lines plus 187 planning-record paths reached main through one privacy-cleared, CI-green, pinned PR (289, merge commit af1dd94e).**

`actuals.tokens` is chars/4 over the 11 files authored on the docs branch (4 commits). The landing PR itself copies existing files (178 changed files, about 406000 chars/4); those are not counted as new work. `commits: 4` counts the docs-branch commits; the three landing-branch commits (039777ba, 3627b2f3, 67ed4c1f) are on main through the merge.

## What was checked and what happened

- **Live reads (Task 1).** Runs 42494651844 (0.2.12) and 42639651064 (0.2.13) are each still on attempt 1, conclusion failure, recorded PARTIAL and FAILURE, superseded by run 42713010358 (COMPLETE) and not re-run. PR 280 merged as 0aa18470 (shipped 0.2.13), PR 283 as dc6a8ed3 (0.2.14), PR 282 as e8d44c6c, PR 287 as fdc218f9. PR 262's head is `0fc93dcf` against `3d65f3fb` at planning (moved, Release Please refresh; read only). Gates-199 is unchanged since the 200 baseline and gates-201 names neither earlier head, so no approval was reused.
- **Issue 281** was closed with a plain-language comment (privacy scan rc 0 before posting): https://github.com/szTheory/crosswake/issues/281#issuecomment-6754328314. TODO-012 is closed with its three evidence items.
- **Planning truth (Task 2).** REL-08 cites 200-01-SUMMARY.md, 200-02-SUMMARY.md and the 0.2.14 candidate's build-gate line and remote form; I read both summaries first and every clause was delivered. REL-09 carries the amendment (direction confirmed by the user on 2026-11-09, wording drafted by the planner) and names run 42713010358. REL-07 and Phase 199 SC1 and SC2 carry the `(Annotated 2026-11-09, Phase 201: ...)` note; the original REL-09, REL-07, REL-08 and SC texts only gained text at their ends. Phase 200 shows 9/9 and Phase 201 8/8. STATE holds one handoff; the prior one is in history/201-08-prior-handoff.md.
- **Landing (Task 3).** Scope was 229 paths (the diff against the merge base; the 108 explicit W-1 files are inside it). Commit-message scan 1 over 107 docs-branch commits found 0 hits. The raw scan over the unredacted docs-branch files found hits in 79 files. After redaction of the landing copies, 54 files still had hits: 11 `not-identifying` (the generic SSH clone-URL form, plus in one file the scanner-allowed public noreply address) and 43 `exclude-from-landing`. Route B was taken (path subset, no history merge), so the docs-branch commit ids that phase evidence records are not on main.
- **Ledger.** The 0.2.13 failure line is byte-identical to the line on PR 285 and the 0.2.14 success line was produced by the script; the diff adds exactly those two lines and removes none; the ledger test ran 9 tests, 0 failures. On main the lines are adjacent (45, 46) in run order.
- **CI and merge.** First push (head 3627b2f3, run 42722231384): `documentation-contracts` and `hex-page-proof` failed on `routing.unclassified_path` for `gate-order-200.awk`. Fixed forward (the file was left out; the local scan then passed), pushed 67ed4c1f, and run 42722897153 passed 38 jobs with 1 skipping (39 of 39). CI ran on synthetic merge `fd00a09dfab366f6fb491ade56e9cae18931c8af`, not on the head. Cost 162 billable min against about 250, 20.8 min wall, 2 full-suite jobs, no flags. Auto-delete on merge read false. Merged with a merge commit pinned to head 67ed4c1f under the standing exception: `af1dd94efffcbff66cd553fc5a396bcfd8330dcf`, parents dc6a8ed3 and 67ed4c1f. PR 285 was closed with a comment; its branch is left.
- **Landed paths.** All 94 explicit files that were not excluded are on origin/main (`explicit_paths_missing` is empty); the Phase 201 run evidence and the Phase 200 summaries are there. `gh pr view 289 --json files` shows only 100 of 178 files; `gh api .../pulls/289/files --paginate` lists 178 and the only non-`.planning/` path is the ledger.
- **Local cleanup.** Both phase worktrees were removed without force. Branch deletions: `Deleted branch fix/default-ios-generation-builds (was 3696f38c)`, `Deleted branch fix/exact-public-build-env-provenance (was 57024c87)`, `Deleted branch docs/release-0-2-14-ledger-and-planning (was 67ed4c1f)`. Git printed a warning each time that the branch was merged to its remote-tracking branch but not to the docs branch; each head is an ancestor of origin/main through its merge. `-D` was never used.

## Deviations from Plan

**1. [Orchestrator decision, variance] No 0.2.14 bot PR existed.** The run's `record-ledger` job (129511426824) succeeded but opened no PR because ledger PR 285 was still open. The 0.2.14 line was generated locally with `script/append_release_ledger.sh` from run-final-201.json `ledger_job.env`. Its `recorded_at` (2026-11-09T23:38:05Z) differs from the line the runner discarded. `ledger-pr-201.json` records `bot_prs: [285]` and `bot_pr_0_2_14: null`. The REL-09 amendment says the line was appended by script for that reason. The plan's literal verifies that need `run-final-201.json ledger_line` (null) or `bot_prs` of length 2 therefore cannot pass as written; the equivalent checks were run instead (line equals the script output, adjacent to the 0.2.13 line on main, ledger test PASS).

**2. [Rule 2 - privacy] Home-prefix redaction of 33 landed files.** The plan's disposition rule would have excluded every planning file carrying a local home path (the account and private-string classes came from that prefix). That would have left STATE, ROADMAP and the plans off main and made the explicit-path check fail. I applied the same rule 201-02 used (prefix to `~`, user decision of 2026-11-09) to the landing copies only, a temp prefix to `<tmp>` in one evidence file, `users/...` to `users/<name>` in two narrative files and one scratch-folder name to `-Users-<user>`. The docs-branch files are unchanged. Ten of the eleven 201-02 planning-record paths came out byte-identical to main's landed versions, which confirms the rule matches. Recorded in landing-privacy-201.txt.

**3. [Rule 3 - blocking] `gate-order-200.awk` left out after CI.** The first-adopter scan classifies by extension and has no `.awk` rule, so two required jobs stopped on `routing.unclassified_path`. Adding the extension is a policy change in `lib/`, so I left the file out (43 exclusions in total) with a reopening condition instead.

**4. [Plan wording] `explicit_paths_missing` excludes excluded paths.** 14 explicit Phase 201 files (13 raw sources and `premerge-result-201.json`) are `exclude-from-landing`; the check covers the 94 non-excluded explicit files.

**5. [Plan wording] The first wait is recorded as `DONE` with an `outcome` field.** `ci_waits` has two entries: the red head (run cancelled by the next push, nothing re-run) and the green head.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the landing PR, covered by T-201-20, T-201-35 and T-201-36.

## Carried items and remaining gates

- **Trailing commits** on `docs/199-release-0-2-12` (ledger-pr-201.json, this summary, state and roadmap metadata) are not on main; they land with the first PR of the next session's work, repeating Route B with the same redaction. Owner: the agent running the next command.
- **43 excluded files** (39 raw sources, 3 pre-merge result files, `gate-order-200.awk`): reopen when each source is redacted or re-dispositioned and the scan knows `.awk`. Owner: the agent running the next command.
- **Remote branches left, each deletion needs its own allow:** `fix/default-ios-generation-builds`, `fix/exact-public-build-env-provenance`, `docs/agents-standing-release-approvals`, `docs/201-planning-record`, `docs/release-0-2-14-ledger-and-planning`, `chore/release-ledger-42639651064`.
- **Pre-existing worktree** `~/projects/crosswake-agents-wt` is left for the milestone-boundary hygiene pass.
- **Not touched:** PR 262, PR 279, release PR 288, Hex retire of 0.2.12 (undecided), the Phase 199 plans 13-19.
- **Next command:** `/gsd-plan-phase 199 --ws quality-ratchet-release`.

## Self-Check: PASSED

Checked: reconcile-201.json, landing-privacy-201.txt, ledger-pr-201.json, 200-08 and 200-09 summaries and the history file exist; commits 5a6291c2, 347308db, 97a36375, 386455bd are on the docs branch; merge af1dd94e is an ancestor of origin/main with 67ed4c1f as its second parent; both ledger lines are on main in run order; the worktrees and three local branches are gone and the main checkout is on `docs/199-release-0-2-12`.
