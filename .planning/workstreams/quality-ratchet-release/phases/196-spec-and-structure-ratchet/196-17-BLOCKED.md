---
phase: 196-spec-and-structure-ratchet
plan: "17"
subsystem: delivery
tags: [merge, landed-proof, fix-forward]
status: blocked
requires:
  - "196-16 exact-head PR and CI"
provides:
  - "PR 260 merged to main as a two-parent merge commit"
  - "approval record and failure record for the landed proof"
affects:
  - "phase 196 verification"
requirements-completed: []
actuals:
  tasks: 3
merge_commit: 88c8bdd88c234c7d9c6b4cc8dbcc2fc9d63fe1be
---

# Phase 196 Plan 17: Main merge and actual-main proof (blocked after merge)

PR 260 merged to main once as `88c8bdd8` with the displayed head and base. The actual-main proof refused with `landed_restoration_failed`, so there is no landed child result and Phase 196 is not verifiable yet. This file is named BLOCKED on purpose, so it does not read as a finished plan.

## Outcome in plain words

- **Merged.** One merge-commit call, guarded by `--match-head-commit` on the approved head. Merge commit `88c8bdd88c234c7d9c6b4cc8dbcc2fc9d63fe1be`, parents `4ebe37fe893f8ef420379d1f27c83bca37c0ce33` (the displayed base) then `bb291f019740a20e5ea0d0c388a7416adf85bd1f` (the approved head). No base drift at write. The PR head branch is still on the remote, and nothing was deleted.
- **Landed proof failed.** The tool began all 40 children on a detached checkout of the merge commit, then refused at its restoration check. The vector children had rewritten four tracked evidence files. The tool writes no per-child results before that check, so none was retained.
- **Not repeated.** The same children rewrite the same files, so a rerun would refuse the same way. The tool cannot be edited in this plan.
- **Nothing was reverted or retried.** The fix-forward route applies.

## Commands and results

| Step | Command or action | Result |
|---|---|---|
| Re-read before the write | PR, `origin/main`, checks, auto-delete setting, local state | head equal to H, base equal to `origin/main` tip, 49 checks success, setting false |
| Approval record | local-only ref `refs/crosswake/196-17-approval`, parent H, diff only delivery.json, marker status consuming | created, never pushed |
| Approval gate | `gate --stage approval-binding --state durable`, then without state | both exit 0 |
| Merge | `gate --stage merge --execute yes` | exit 0, one call, merged 2026-10-29T01:53:27Z |
| Read back | PR state, merge commit parents, remote branch, setting | merged, parents as above, branch present, setting false |
| Landed proof | `phase-evidence.mjs landed` | refused `landed_restoration_failed` after 78 minutes |

Task 1 earlier ran the ready gate, the merge and landed self-tests (547 ms and 769 ms), the pr-open gate and a privacy scan at H, all exit 0. Auto-delete was off at observation. It had read on earlier in this attempt, so the run held, and the user turned it off by explicit separate decision. PR 261's head branch `fix/bandit-advisory` was auto-deleted at its merge at 2026-10-28T18:38:33Z, before the change. All of this is in delivery.json.

## Identities

- Candidate identity at the merge commit, derived read-only: source roster `bc288cde60facd0139c792f9ea60234117bfb64a9c70d2e99e17a35081d891d0` (1376 files), `phase-evidence.mjs` `b4c1124e7d131088d9200bdda275c506d89d11c4bdb440170fe25bb225e6e1bd`, `measure-main.mjs` `af5acfc3325eba95baab8bb4dd75e0d3bf5d10dd995fbf1024f7548e88d7ccaf`, preserved roster `44019928d4a0f12252339781c7269fc24550e826757cdd56231a5be520aa45f2`. It equals candidate.json.
- The disposition and roster-digest checks passed in the landed process before the registry ran.
- 196-VALIDATION.md and both tools are unchanged.

## Deviations from Plan

1. **[Rule 1 - Defect, tool] Landed proof cannot succeed as built.** The vector children rewrite tracked files under 196-EVIDENCE (durations and hashes), and the tool compares a whole-tree inventory before and after. Not fixed here, because the plan forbids editing the tool. Fix branch name: `fix/196-landed-restoration-tracked-evidence`, from current origin/main.
2. **[Plan versus tool] `gate --stage merge` cannot exit 0 before a decision.** The tool requires an allow. It refused with `approval_not_fresh_allow` after the identity, auto-delete and scope checks passed. No allow was fabricated.
3. **[Plan versus tool] The approval and merge gates read the attempt from the working-tree delivery.json.** The plan restores that file first. It carried the decision while the gates ran, then was restored.
4. **[Process] The landed tool creates the evidence branch only on success.** The branch was created by hand from the merge commit and carries the 196-16 completion commit, which was local only.
5. **[Process] Gates that compare local HEAD to the PR head ran with the branch temporarily at H.** It was restored to its tip afterward, with a local backup ref, and nothing was pushed.

## Known unknowns

- The landed pass or fail for each of the 40 children on actual main is unknown. The tool kept no per-child result, and I did not rerun it.
- R-15 verify-source `main_ref_mismatch` was not re-observed.

## Stub and threat scan

No stubs. No new network surface, auth path or schema at a trust boundary.

## Requirements

SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03 and GR-06 remain pending phase verification. None is marked complete.

SPEC-04 (Muex pilot) moved intact to v29.0 by recorded roadmap change; both attempts and the 5/5 accepted controls are preserved, and no adopt/drop verdict was made.

## Handoff

Last completed phase: 195. Phase 196 is executed through plan 17 on main and is not verifiable. The evidence PR to main carries this record. Merging it needs its own later one-use allow. The next eligible work is the fix-forward branch above. `$gsd-verify-work 196 --ws quality-ratchet-release` becomes eligible only after an actual-main proof passes.
