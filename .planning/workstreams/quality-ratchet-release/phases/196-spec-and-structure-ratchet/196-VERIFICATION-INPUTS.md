# Phase 196 verification inputs

Merge commit: 51a1885cfd50c9dc159a2591204da69510a2ffc4. Approved head: 24fde71db5ac121d73c201913251a6f53e4d860d. Displayed base: 88c8bdd88c234c7d9c6b4cc8dbcc2fc9d63fe1be.

The seven requirements SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03 and GR-06 are pending phase verification.

SPEC-04 (Muex pilot) moved intact to v29.0 by recorded roadmap change; both attempts and the 5/5 accepted controls are preserved, and no adopt/drop verdict was made.

Plan 196-14 is retired, not executed to completion.

Per-task results: pass; children 40; failing 0.

Next command: `$gsd-verify-work 196 --ws quality-ratchet-release`

## Results keyed by VALIDATION task ID

| Task ID | Requirement | Pre-merge candidate | Actual main (landed) |
|---|---|---|---|
| 196-01-01 to 196-12-02 | SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03, GR-06 | candidate.json verdict pass, 40 of 40 children, tool identity `8b825268` (amendment 2) | landed.json verdict pass, 40 of 40 children, 0 failing, identity matches candidate.json |
| 196-13-01, 196-13-02 | SPEC-04 | moved to v29.0, not recorded as a v28 result | moved to v29.0, not recorded as a v28 result |
| 196-14-01, 196-14-02 | SPEC-04 | plan 196-14 is retired, not executed to completion | plan 196-14 is retired, not executed to completion |
| 196-15-01, 196-15-02 | SPEC-01 to ARCH-03 (in scope) | candidate pass on the final identity | not applicable |
| 196-16-01, 196-16-02 | SPEC-01 to ARCH-03 (in scope) | ready gate pass, CI green on the exact head | not applicable |
| 196-17-01 | SPEC-01 to ARCH-03 (in scope) | merge and landed self-tests pass | not applicable |
| 196-17-02 | SPEC-01 to ARCH-03 (in scope) | allow for PR 264 recorded on a local-only ref | not applicable |
| 196-17-03 | SPEC-01 to ARCH-03 (in scope) | PR 264 merged once | landed proof pass, no base drift |

The stale companion-row attribution (merge and landed scopes now produced by 196-15-02) is noted here, and 196-VALIDATION.md is not edited.

## Two merges, one proof

- PR 260 (merge commit `88c8bdd8`) landed the phase work. Its landed proof refused `landed_restoration_failed` and kept no child result. That record is in `196-EVIDENCE/196-17-blocked-1-superseded.md` and in git history.
- PR 264 (merge commit `51a1885c`, parents `88c8bdd8` then `24fde71d`) fixed the landed tool. Its landed run is the proof recorded in landed.json. The tree at `51a1885c` equals the tree of its approved head.
- The proof ran all 40 children in an isolated linked worktree of `51a1885c`. The main checkout was not switched or written, and its head, branch and whole-tree inventory were asserted equal afterward.

## Plan deviations to read

- The landed tool reads one fixed local ref for its attempt. The PR 260 record was renamed to `refs/crosswake/196-17-approval-pr260` (kept, not deleted) and a record for PR 264 was created at the fixed name with parent `24fde71d`. The tool was not edited. This record was written after the merge, so it is not write-ahead (see delivery.json).
- The approval-binding and merge gates were not run for PR 264, because the merge was made by the orchestrator before the record existed.
- The tool creates the local branch `docs/196-landed-evidence`, a name already on the remote. The new branch was renamed `docs/196-landed-evidence-2` before the push.

Native evidence stays at the JVM-hermetic and Swift-package ceiling and makes no device claim.
