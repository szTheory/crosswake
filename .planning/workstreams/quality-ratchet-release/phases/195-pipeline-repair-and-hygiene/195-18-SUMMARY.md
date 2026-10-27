---
phase: 195-pipeline-repair-and-hygiene
plan: 18
subsystem: infra
tags: [ci, secret-masking, gap-closure, merge-gate, review-disposition]
requires:
  - phase: 195-17
    provides: fix/secret-mask-key-forms (round-2 masking fix) and the GR-06 census
provides:
  - "PR #257 merged into main (merge 7621c0ce) with a merge commit, after its own one-use allow"
  - "On-main proof: nine GR-01 forms masked, prose unchanged, GR-02 tests 2 pass 0 fail, JS suite 275 pass 0 fail"
  - "195-REVIEW-DISPOSITION.md rows GR-01 to GR-10; GR-06 deferred to Phase 196 with a ROADMAP carried line"
affects: [196, 197]
requirements-completed: [REL-03]
actuals:
  tokens: 6000
  tasks: 3
  commits: 3
  plan_head_before: 68d10db327a9c6c2f7d08c002f03a813a0ed38ab
  plan_head_after: 53985c97
completed: 2026-10-27
status: complete
---

# Phase 195 Plan 18: Land the round-2 masking fix and record the gap-review dispositions Summary

**PR #257 (merge 7621c0c) put the round-2 secret-masking fix on main, the on-main reproduction shows all nine leaked forms masked and the prose case unchanged, and GR-01 to GR-10 now have recorded dispositions (GR-06 deferred to Phase 196).**

`commits: 3` is measured with `git rev-list --first-parent --count`: the origin/main merge, the docs commit and this SUMMARY commit. A plain count would also include the PR's own commits that arrive through the merge. No plan-head ledger file existed (the plan ran across two executors), so `plan_head_before` is the first parent of the merge commit.

## What was checked and what happened

- Task 1: PR #257 was opened from `fix/secret-mask-key-forms` and privacy-scanned (2 files, body clean). CI on head 283111ee was red; head 12281b87 was red once and then green (see Deviations).
- Task 2 (gate): the user answered `allow` to Question A, bound to PR #257 head 12281b8 and including the automatic remote-branch deletion, and `accept` to Question B (recorded in `review-route2-195.txt`). `pr5 approval: allow` (PR #257, head 12281b8); `gr06 route: accept`.
- Task 3: the merge was executed by the user, not the agent (the agent's merge call was refused by the auto-mode classifier). The agent then verified state `MERGED`, merge commit 7621c0ce (two parents: main 5862a3d and head 12281b87), mergedAt 2026-10-27T01:03:11Z, merge commit on origin/main, remote branch gone, remote tags 114 before and after. The local branch `fix/secret-mask-key-forms` was left in place because `git branch -d` refused it; it was not forced.
- `origin/main` was merged into `docs/195-closeout` by merge commit 2c48773d (no rebase, no force).
- On-main proof (`mask-gr-main-195.txt`): escaped_json, tuple_atom, tuple_authorization, bearer_quoted, next_line, yaml_block, cli_flag, curl_user and double_equals all masked; prose_token_expired unchanged; GR-02 single-quoted tests 2 pass 0 fail; `node --test test/js/*.mjs` rc 0, 275 pass, 0 fail. Control: the pre-PR masker (5862a3d) leaked 8 of the 9 forms with this fixture (`bearer_quoted` was already masked there for this fixture's shape), so the reproduction is not vacuous.
- Dispositions: GR-01 to GR-05 and GR-07 to GR-10 are `fixed` (PR #257, merge 7621c0c); GR-06 is `deferred` to Phase 196 with the zero-census reason; frontmatter `findings_total: 21`, `open: 0`, `fixed: 14`, `deferred: 5`, `wontfix: 2`. The Phase 196 ROADMAP entry gained one `**Carried from Phase 195 gap review**` line naming GR-06 (numstat `1 0`).
- Nothing was merged to main by the agent, no tag was created, nothing was published, no remote branch was deleted by the agent.

## Deviations from Plan

1. **Orchestrator commits a4327ad0 (red) and 283111ee (fix)** gave the JWT rule a `(?<![A-Za-z0-9_-])` left boundary: an `eyJ-` run of 200k characters went from about 7 s to 1 ms. Trade-off: a JWT directly after a hyphen is no longer masked by that rule. Noted in the GR-05 row.
2. **Commit 12281b87 raised the linear-time floor from 40 ms to 250 ms** after the shared runner measured linear inputs at 51 to 95 ms. This deviates from plan 17's `Math.max(40, 10 * baselineMs)` truth and from the plan 18 GR-08 note (about 200 ms). The old JWT rule still fails the 250 ms bound at 7909 ms. Noted in the GR-08 row.
3. **The red example-host job was re-run once without a change**, by user decision, which departs from the plan prohibition on re-running to green. Both conclusions are recorded in `pr5-ci-195.txt`. The cause of the attempt-1 exit 2 in `proof-requires-example-host` was never observed; that job also failed in 13 of the last 25 failed Crosswake CI runs, so it is not a clean history. Unknown, not fixed.
4. **The merge was performed by the user**, because the classifier refused the agent's merge. It was the exact displayed command at the same head, so the bound allow was respected.
5. **The fix branch's real tip** was 283111ee and then 12281b87, not the 40c018a5 recorded in the plan 17 evidence.
6. `195-18-TASK1.md` (notes from the blocked/resumed Task 1) was folded into this SUMMARY and deleted; no file named `195-18-BLOCKED.md` exists.
7. The repro script lives in the session scratchpad and builds inputs from fragments, as planned; the pre-PR control run was added by the executor.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- 7621c0ce is an ancestor of origin/main and of HEAD; mask-gr-main-195.txt, pr5-merge-195.txt, review-route2-195.txt and 195-REVIEW-DISPOSITION.md exist; docs commit 53985c97 exists.
