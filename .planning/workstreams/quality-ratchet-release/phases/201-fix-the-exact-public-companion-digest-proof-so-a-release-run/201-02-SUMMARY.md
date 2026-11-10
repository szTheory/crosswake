---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 02
subsystem: release-governance
tags: [planning-record, standing-approvals, bearings, runbooks, contract-test, privacy-scan, pinned-merge]

requires:
  - phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
    provides: "201-01 evidence commits on the local docs branch (the planning set that Task 1 copies to main)"
provides:
  - "The Phase 201 planning record on main (PR 286, merge 665f0b9b): eleven explicit paths, home prefix redacted, roadmap additions only"
  - "The standing release approvals on main (PR 284, merge 44e2f69b): AGENTS.md, BEARINGS invariant 4, both release runbooks and the AGENTS contract test agree"
  - "approvals-pr-201.json: the exact commit facts Plan 07 reads as its first gating action"
affects: [201-03, 201-05, 201-07, 201-08]

actuals:
  tokens: 6700
  tasks: 3
  commits: 3

plan_head_before: "ec56e97c9d5f9a9ec5e1134aa441324f0cd649ca"
plan_head_after: "329856554c0c5cdad079e16bce8b01aea40e4a45"
commits: 3

tech-stack:
  added: []
  patterns:
    - "Landing by explicit path list with a mechanical, cmp-verified redaction"
    - "Pinned merge commit (--match-head-commit) after Crosswake CI on the exact head, ran-on synthetic commit recorded"
    - "Privacy scan over files, PR body and the messages each push publishes, rescanned after every new commit"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/planning-record-pr-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/privacy-planning-record-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/approvals-contract-red-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/approvals-contract-green-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/privacy-approvals-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/approvals-pr-201.json
  modified:
    - "AGENTS.md (on main via PR 284; edited in that PR's earlier commits, not by this plan)"
    - .planning/BEARINGS.md
    - docs/RELEASE-INCIDENT-RESPONSE.md
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - test/crosswake/planning/agents_contract_test.exs
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md

key-decisions:
  - "GitHub refused PR 284's merge because the branch was behind main (the planning record had just landed), so main was merged into the branch with a merge commit and CI was waited on again; nothing was rebased, forced or re-run"
  - "The contract test counts 15 tests (4 fixed plus 11 phrases); the four-file floor is 110 (15 plus 74, 16 and 5 measured on the unchanged head)"

requirements-completed: [REL-09]

coverage:
  - id: D1
    description: "The Phase 201 planning record is on main before any other irreversible step, by one privacy-cleared, CI-green, pinned PR"
    requirement: REL-09
    verification:
      - kind: command
        ref: "Task 1 verify commands 1 to 5 (jq on planning-record-pr-201.json, merge parent and path-list checks, roadmap additions-only awk, privacy file checks, worktree and branch cleanup); gh pr view 286 prints MERGED with 11 files"
        status: pass
    human_judgment: false
  - id: D2
    description: "PR 284 carries the AGENTS.md rule, BEARINGS invariant 4, aligned runbook sentences and a contract test of the new rule; red before the edit, green after; merged after the planning record"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "201-EVIDENCE/approvals-contract-red-201.txt (rc=2 total=12 ran=12 failures=7 FAIL) and approvals-contract-green-201.txt (total=110 failures=0 PASS)"
        status: pass
      - kind: command
        ref: "Task 2 and Task 3 verify commands (BEARINGS line, runbook phrases, PR body, privacy lines, approvals-pr-201.json jq, prior-CI cross-check against run 42643335000, merge ancestry, worktree state)"
        status: pass
    human_judgment: false

duration: 53min
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 02: Planning record and standing release approvals on main Summary

**The Phase 201 planning record (PR 286) and the standing release approvals with their matching BEARINGS invariant, runbook sentences and contract test (PR 284) are both on main, each as a CI-green merge commit pinned to its head, planning record first.**

## Performance

- **Duration:** about 53 min (CI waits about 3, 17 and 21 min)
- **Completed:** 2026-11-09T20:40Z
- **Tasks:** 3
- **Files:** 6 evidence files here; 11 paths landed by PR 286; 4 files changed by the PR 284 follow-up commit (BEARINGS, two runbooks, the contract test)

## Accomplishments

- Planning record: PR 286 from `docs/201-planning-record` (cut from origin/main `0aa18470`) carried exactly the eleven paths. Ten phase files differ from the docs-branch source only by the home prefix replaced with `~` (cmp-verified); the roadmap gained 83 lines and lost none. `test/crosswake/planning/` passed (95 tests, 0 failures) before the commit. Crosswake CI passed on head `e0ecb991` (it ran on the synthetic merge `0749391d873bb8c1b9e7d3f77af7b833acfbf59f`, 5 billable minutes). Merged once as `665f0b9b0acb156f3574512ffcea390aa316660b`, second parent `e0ecb991`.
- PR 284: diagnosed the earlier red run 42643335000 from its logs per job, then added one commit (`1e5a2ea1`) that replaces BEARINGS invariant 4 (35 lines before and after), rewrites the two runbook approval paragraphs, and replaces the contract test's phrase list with 11 phrases of the new rule plus a BEARINGS invariant 4 test. CI passed on head `ccfe93d8` (it ran on the synthetic merge `3dfb8902ea9de914e998af75671a6fc7e0ba0358`, 166 billable minutes, against a baseline of about 250). Merged once as `44e2f69b09afded59088e7b7a891b248a9a068a6`, second parent `ccfe93d8`, after the planning record.
- Contract test red then green, as predicted: unchanged head `rc=2 total=12 ran=12 failures=7 verdict=FAIL reason=mix_rc`; after the edit `total=110 failures=0 verdict=PASS` over the four files (floor 110 = 15 + 74 + 16 + 5).
- On origin/main after the merge: AGENTS.md carries `the release PR included`, `approving the release-tags step`, `Hex, Maven and iOS mirror publishes need no gate` and `Maven fire-drill dispatch`; BEARINGS invariant 4 carries `run under the standing exceptions recorded there`; both runbooks carry the new sentences; the pinned phrase `first of several one-use approval gates` is unchanged.

## Task Commits

Code lives in PRs, not this branch:

1. **Task 1: planning record** - PR 286, commit `e0ecb991`, merged as `665f0b9b`
2. **Task 2: PR 284 follow-up** - commits `1e5a2ea1` (the amendments) and `ccfe93d8` (merge of main into the branch), merged as `44e2f69b`
3. **Task 3: merge and record** - no code; evidence only

Evidence commits in the main checkout on `docs/199-release-0-2-12` (never pushed):

- `0c54a422` docs(201-02): record the planning-record PR and its merge
- `808373dc` docs(201-02): PR 284 diagnosed, BEARINGS and runbooks amended, CI green on the head
- `32985655` docs(201-02): record the PR 284 merge and the committed standing approvals

## CI facts per merge

| PR | Head merged | CI run | Ran on (synthetic merge) | Billable min | Merge commit |
|----|-------------|--------|--------------------------|--------------|--------------|
| 286 | `e0ecb99155e7abd4b61bef272d75113723247b32` | 42686945166 | `0749391d873bb8c1b9e7d3f77af7b833acfbf59f` | 5 | `665f0b9b0acb156f3574512ffcea390aa316660b` |
| 284 | `ccfe93d82f8b83e173d6de49d6031e670b079b96` | 42691407076 | `3dfb8902ea9de914e998af75671a6fc7e0ba0358` | 166 | `44e2f69b09afded59088e7b7a891b248a9a068a6` |

PR 284's first green head `1e5a2ea1` (run 42688429752, ran on `79f14a34a127e83ed8073840de5b6ee82ae26be3`) was not merged: GitHub reported it behind main and refused the pinned merge, so it was not the head that merged.

## Prior red CI on PR 284 (run 42643335000, first head)

| Job | Step | Logged cause | On the new head |
|-----|------|--------------|-----------------|
| ios-mirror-parity-proof | Check iOS SwiftPM mirror parity | `release.ios_mirror_parity - SwiftPM mirror is missing refs/tags/v0.2.13` (the tag exists now) | success |
| proof-requires-example-host | Run the bounded example-host isolation matrix | `FAIL example-host-proof`, `kind: command_failure`, exit 2 (not tied to AGENTS.md) | success |
| phase130-core-hermetic-proof | Run root and companion proof | cancelled, no cause logged | success |

Nothing was re-run; the new commits produced new runs.

## Decisions Made

- Merging main into PR 284's branch (a merge commit, no rebase, no force) was the plan's sanctioned response to "behind main"; it cost one more CI wait (21 min) and one more privacy rescan (run 2).
- BEARINGS is edited off its milestone-close cadence on the user's 2026-11-09 decision; one line replaced, none added (the PR body and the commit body say so).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] PR 284 was behind main when the pinned merge was attempted**
- **Found during:** Task 3
- **Issue:** CI was green on `1e5a2ea1`, but `gh pr merge 284 --merge --match-head-commit 1e5a2ea1...` was refused: "the head branch is not up to date with the base branch". Main had moved when PR 286 merged (Task 1).
- **Fix:** the plan's own route: `git merge --no-ff origin/main` in the reused worktree (`ccfe93d8`), file, body and message scans again (run 2, head `ccfe93d8`, rc 0), a fast-forward push, a new CI wait, then the pinned merge on the new head.
- **Files modified:** none beyond the merge commit (the five PR 284 files were unchanged by it)
- **Verification:** CI success on run 42691407076; merge second parent equals `ccfe93d8`.
- **Committed in:** `ccfe93d8`

**2. [Rule 1 - Bug] My first evidence-JSON build command hung on stdin**
- **Found during:** Task 1 (planning-record-pr-201.json)
- **Issue:** a stray `jq -n --slurpfile _ /dev/null '[inputs]'` waited on stdin and the shell moved it to the background. No repository or remote state was involved (worktree removed and branch deleted before it ran).
- **Fix:** killed it, rebuilt the file without that line, and corrected `redaction.files_changed` to 11 (10 phase files plus the roadmap, counted from the source copies).
- **Committed in:** `0c54a422`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 tooling slip). **Impact on plan:** one extra CI wait and push; no expectation was changed.

## Issues Encountered

- The `Monitor` tool was not available; CI waits ran as a bounded script (`ciwait.sh`, every 2 minutes, 45-minute limit, never re-runs a job) plus short foreground polls. All three waits finished well inside 45 minutes (3, 17 and 21 minutes).
- `git branch -d docs/201-planning-record` warned the branch was merged to its remote-tracking ref but "not yet merged to HEAD" (the main checkout sits on the local docs branch, by design); it succeeded without `-D`.
- Evidence-commit lock: free on every take; Plan 01 was already finished.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path or schema; the rule-text changes are the planned T-201-24 to T-201-27 mitigations (see below).

## Threat model status

- T-201-24: the contract test asserts the merged AGENTS.md text, each phrase keeps its generated negative control, and a BEARINGS invariant 4 test was added; red-before evidence recorded.
- T-201-25: ordinary-PR exception only; `--match-head-commit` on both merges; no `--admin`; auto-delete read `false` before each merge.
- T-201-26 and T-201-37: privacy-193.sh over every changed file, both PR bodies and the messages each push published; only the generic `git@github.com` class hit (3 planning files), recorded not-identifying.
- T-201-27: BEARINGS and both runbooks amended in PR 284; REL-07 and Phase 199 SC1 and SC2 left for 201-08 Task 2 (follow_ups in approvals-pr-201.json, receiver and due recorded).
- T-201-33: the pre-existing worktree `~/projects/crosswake-agents-wt` was clean at `f53c2d21` before any write, never stashed, reset or forced, and is left clean at `ccfe93d8`; its local branch is kept.
- T-201-38: the PR changed exactly the eleven paths; roadmap additions only; a `docs(201)` commit with no breaking-change marker (no version bump).

## Not verified here

- Plan 07's precondition read of the committed rules has not run; this plan only recorded the facts (blobs and merge commit) it will read.
- No tests were run on main after the merges beyond CI on each synthetic merge.
- The 11 phrases check the AGENTS.md wording only; the runbook wording is checked by the plan's grep commands and the existing `release_boundaries_test`, not by a new test.

## Local items left for the next hygiene pass

- The pre-existing worktree `~/projects/crosswake-agents-wt` and local branch `docs/agents-standing-release-approvals` (merged). Remote branches `docs/201-planning-record` and `docs/agents-standing-release-approvals` still exist; deleting them keeps its own allow.

## Next Phase Readiness

Plans 201-03 and 201-07 can proceed. 201-07's first action reads `approvals-pr-201.json`: merge `44e2f69b09afded59088e7b7a891b248a9a068a6` is on origin/main, and main's AGENTS.md, BEARINGS invariant 4 and both runbooks authorize the standing steps.

## Self-Check: PASSED

Merge commits `665f0b9b` and `44e2f69b` and the head `ccfe93d8` are ancestors of origin/main; evidence commits `0c54a422`, `808373dc` and `32985655` are ancestors of the main checkout's HEAD; all six evidence files exist.
