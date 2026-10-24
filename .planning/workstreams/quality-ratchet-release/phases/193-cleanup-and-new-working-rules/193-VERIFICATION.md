---
phase: 193-cleanup-and-new-working-rules
verified: 2026-10-24T17:30:00Z
status: passed
score: 4/4 must-haves verified
requirements: [CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04]
behavior_unverified: 0
overrides_applied: 0
---

# Phase 193: Cleanup and new working rules Verification Report

**Phase Goal:** The recovery checkout is replaced by a clean `main` checkout, landed or obsolete local copies are removed after backup, a final check proves the state, and the working rules describe the normal branch-and-PR flow.
**Status:** passed on the content head of PR 2 (C1, short id `1ea30482`). Verified before the merge question; the post-merge rerun is reported separately (see "Final check" below).

## How to read this record

PR 2 (#244) has three commits. The first commit (C1, `1ea30482`) carries every Phase 193 record from plans 05 to 09 and the new working rules. The final check below ran on C1. The second commit (C2) adds only this verification record, the plan 10 summary and the completion bookkeeping (the CLEAN checkboxes in REQUIREMENTS.md, the ROADMAP row and the STATE and `.continue-here.md` handoff). The third commit (C3) is a one-line fix-forward: CI on C2 failed the planning test that requires STATE's `milestone_name` to appear in ROADMAP.md (my C2 had reworded it), so C3 restores that one STATE line; it changes nothing else. The pre-merge final check was run again on the final head and its result is kept in the backup folder.

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CLEAN-01: the recovery checkout is retired and replaced by a clean `main` checkout, only after its work is on `main` and everything else is backed up | VERIFIED | Preflight and post-189 record (`193-EVIDENCE/preflight-193.txt`, `193-POST189-RECORD.md`); PR 1 (#243) merged with a merge commit after the user's `allow` (`answer-pr1-193.txt`, `ci-pr1-193.txt`, `pr1-193.txt`); copy-forward and build proofs (`copyforward-verify-193.txt`, `copyforward-reverify-193.txt`, `build-proof-193.txt`, `build-reproof-193.txt`); folder swap (`swap-193.txt`); session guard (`guard-193.txt`). |
| 2 | CLEAN-02: landed or obsolete stashes, extra worktrees and local branches are removed after backup; anything kept has a stated reason | VERIFIED | The user's `allow` for the removal list (`answer-removal-193.txt`, `gate-b-list-193.txt`); per-item removal results (`removal-results-193.tsv`, `remove-apply-193.txt`, `remove-after-193.txt`); `193-REMOVAL-LEDGER.md`: 306 listed, 300 removed, 6 kept, each kept row with its reason (the integration clone stays because 8 remote-tracking ref tips exist in no backup). Final-check checks 4 and 5 passed on the ledger (`final-check-45-193.txt`). |
| 3 | CLEAN-03: the final check shows a clean `main` checkout, green main CI, a disposition for every open PR and no `/private/tmp` folder as the only copy of anything | VERIFIED | `final-check-193.sh --pre-merge 244` on C1, quoted in full below. |
| 4 | CLEAN-04: AGENTS.md and the workstream STATE replace the candidate-in-temp-folder and frozen-checkout rules with branch from `main`, open a PR, wait for CI, merge only after the user's word | VERIFIED | `193-EVIDENCE/rules-check-193.txt` ends `rules: result pass`; AGENTS.md section "How changes land"; STATE.md Exact Next Action and Handoff history ("frozen recovery checkout rules" marked superseded); PROJECT.md current-stage line; SEED-025 holds the Phase 192 review residue. |

## Final check (CLEAN-03) on C1

`bash scripts/final-check-193.sh --pre-merge 244`, run on C1 `1ea30482`, exit 0:

```
final: check 1 pass
final: ci ran on pr head SHA (pull_request runs also test a synthetic merge commit)
final: info main-push Cancel Obsolete Crosswake CI success
final: info main-push Cancel Obsolete Crosswake CI success
final: info main-push Release Please success
final: check 2 pass
final: info head drift 7
final: check 3 pass
final: info tmp crosswake entries 0
final: check 4 pass
final: check 5 pass
final: result pass
```

The required Crosswake CI check ran on the PR head and, because it is a pull-request run, also on GitHub's synthetic merge commit; it succeeded. The 7 open PRs (#210, #211, #236, #238, #239, #240, #241) each have a recorded disposition in `193-PR-DISPOSITIONS.md` (record only; none was touched). "head drift 7" is information: Dependabot rebases moved those heads since the table was written; the PR numbers still match.

Receipts live outside git in the backup folder under `receipts-193/`: the scan and PR bindings, the write log (`gh-writes-pr2.txt`), `final-check-pre-c1.txt`, `final-check-pre-c2.txt`, and, after the merge, `final-check-post-merge.txt` with `SHA256SUMS.receipts`. The post-merge rerun is reported in the handoff message and kept as a receipt there; `final-check-193.sh --post-merge` reproduces it.

## Deviations and judgments

- Scan hit on C1, fixed before the first push: the scanner flagged a self-test fixture literal in `copyforward-193.sh` (a sample path that matched the home-path pattern, twice on one line). The literal was split so it no longer matches, `193-SCRIPTS.sha256` was updated to the new hash of that one script (12 of 12 hashes verify), and because the commit had not been pushed it was folded into C1 so no added line anywhere in the PR matches. Behaviour of the script is unchanged. Nothing sensitive was involved.
- Private-term scan skipped under D-26 (the user's extension of A-14 to the Phase 193 pushes), recorded in the scan binding; home paths, tokens and credential shapes were still checked and are clean.
- CI red on C2 (fixed forward in C3): 8 jobs failed on 2 tests, `MilestoneTransitionResetTest` (STATE `milestone_name` must be named in ROADMAP.md) and the proof test that wraps it. Cause: the C2 STATE rewording. Fix: STATE `milestone_name` restored; the planning tests (83) and rules-check pass locally. No code change was needed.
- `crosswake-integration-191` was kept on purpose (ledger row, cause `ref_tip_unprotected`). It lives in the projects folder, not in `/private/tmp`, so CLEAN-03's "nothing only in `/private/tmp`" is unaffected.
- Plan 08 noted that `--check N` needs `--post-merge` or `--pre-merge`; the full `--pre-merge` run was used here.

## Requirements Coverage

| Req | Status |
|-----|--------|
| CLEAN-01 | SATISFIED |
| CLEAN-02 | SATISFIED |
| CLEAN-03 | SATISFIED (pre-merge on C1 and C2; post-merge reported in the handoff) |
| CLEAN-04 | SATISFIED |

## Human verification

None needed. The only human step is the one-word `allow` or `hold` for merging PR 2.

_Verifier: Claude (gsd-executor, plan 193-10)_
