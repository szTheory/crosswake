# Phase 196 verification inputs

Merge commit: 88c8bdd88c234c7d9c6b4cc8dbcc2fc9d63fe1be (two parents). Approved head: bb291f019740a20e5ea0d0c388a7416adf85bd1f. Displayed base: 4ebe37fe893f8ef420379d1f27c83bca37c0ce33. First parent equals the displayed base, so there was no base drift at write.

Status: Phase 196 is executed and merged, and it is not yet verifiable. The landed proof on actual main refused with `landed_restoration_failed`, so the actual-main child results were not retained.

## What happened

- PR 260 was merged once with a merge commit, guarded by `--match-head-commit` on the approved head. No branch was deleted and no repository setting was changed by the merge.
- The landed proof began all 40 children on a detached checkout of the merge commit. The tool then refused at its restoration check, because the vector children had rewritten four tracked vector evidence files.
- The tool writes no per-child results before that check, so no landed child result exists. The four rewritten files were restored to their committed bytes, and their rewritten hashes are listed in landed.json.
- A rerun was not made. The same children rewrite the same files, so a rerun refuses the same way.
- The failing cause and the fix branch name are recorded in landed.json. No merge revert and no merge retry was made.

## Results keyed by VALIDATION task ID

| Task ID | Requirement | Pre-merge candidate | Actual main (landed) |
|---|---|---|---|
| 196-01-01 to 196-12-02 | SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03, GR-06 | candidate.json verdict pass, 40 of 40 children, identity bc288cde | not established, cause `landed_restoration_failed` |
| 196-13-01, 196-13-02 | SPEC-04 | moved to v29.0, not recorded as a v28 result | moved to v29.0, not recorded as a v28 result |
| 196-14-01, 196-14-02 | SPEC-04 | plan 196-14 is retired, not executed to completion | plan 196-14 is retired, not executed to completion |
| 196-15-01, 196-15-02 | SPEC-01 to ARCH-03 (in scope) | candidate pass on the final identity (see amendment-1-candidate-rerun.md) | not applicable |
| 196-16-01, 196-16-02 | SPEC-01 to ARCH-03 (in scope) | ready gate pass, CI run 40791204733 success, 49 checks on the head | not applicable |
| 196-17-01 | SPEC-01 to ARCH-03 (in scope) | merge and landed self-tests pass, ready gate pass, auto-delete read off | not applicable |
| 196-17-02 | SPEC-01 to ARCH-03 (in scope) | allow recorded and bound to PR 260, durable approval gate pass | not applicable |
| 196-17-03 | SPEC-01 to ARCH-03 (in scope) | merge executed once | landed proof fail, cause `landed_restoration_failed` |

The stale companion-row attribution (merge and landed scopes now produced by 196-15-02) is noted here, and 196-VALIDATION.md is not edited.

## Pending phase verification

The seven requirements SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03 and GR-06 are pending phase verification. None is recorded as complete.

SPEC-04 (Muex pilot) moved intact to v29.0 by recorded roadmap change; both attempts and the 5/5 accepted controls are preserved, and no adopt/drop verdict was made.

## Plan deviations to read

- `gate --stage merge` refuses before a decision exists, with `approval_not_fresh_allow`, so it could not exit 0 in the reversible task. It ran for real after the decision.
- The approval-binding and merge gates read the attempt from the working-tree delivery.json, so that file carried the decision while they ran. It was restored afterward.
- The landed tool creates the evidence branch only on success. This branch was created by hand from the merge commit after the refusal.

## Evidence branch and fix-forward

Evidence branch: docs/196-landed-evidence, created from the merge commit and carrying the 196-16 completion commit. Its PR to main is recorded in delivery.json. Merging that PR needs its own later one-use allow.

Fix-forward branch name, from current origin/main: `fix/196-landed-restoration-tracked-evidence`. The fix is to make the landed proof run its vector children without rewriting tracked evidence, or to restore them before the check, then re-run the candidate on the new tool identity and the normal PR, CI and fresh one-use merge route.

Native evidence stays at the JVM-hermetic and Swift-package ceiling and makes no device claim.

Next command after the fix lands: `$gsd-verify-work 196 --ws quality-ratchet-release`. It is eligible only once an actual-main proof has passed.
