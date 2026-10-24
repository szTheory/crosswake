# v27.0 closeout

Completed 2026-10-24 at the user's request (`/gsd-complete-milestone v27.0 --ws quality-ratchet-release`), after the milestone audit returned `tech_debt` with no blocker (18/18 requirements, 5/5 phases, 14/14 integration links, 4/4 flows). The workstream open-artifact audit was clear (6 earlier acknowledgements still suppressed). All 55 plans in phases 189–193 have a SUMMARY, and every VERIFICATION reports `passed`, so this is a `verified_closeout`. 193-VERIFICATION.md was written by the plan 10 executor, not by an independent verifier; the audit re-checked its claims live.

This is the first closeout since v23 that lands through git. The recovery-checkout freeze ended in Phase 193, so this close goes through an ordinary `chore/` PR branched from `main` (AGENTS.md "How changes land").

## Archive and workflow exceptions

- `init.manager --ws quality-ratchet-release` returned 0 phases (it does not parse this roadmap's phase lines). Readiness was checked directly instead: 55 PLAN and 55 SUMMARY files in 189–193, five VERIFICATION files with `status: passed`, and ROADMAP plan checkboxes all ticked.
- The unscoped `audit-open` stopped on an archived v3.8 report whose status (`complete`) is outside the CLI's closed set. The workstream-scoped run was clear. The archived report was not changed.
- Ran `milestone.complete v27.0 --name 'Land and Clean Up' --no-archive-phases --confirm --ws quality-ratchet-release` once, after a dry run. It moved the audit into `milestones/` and wrote the roadmap and requirements copies. Phase folders stay in place: `phases/` still holds 176–188 from earlier milestones, and recorded evidence paths point at the live folders. Quick tasks were not archived.
- The writer reported 1 task; the plan files hold 127 `<task>` entries (29, 19, 29, 21, 29), and the milestone record uses 127. Its generated MILESTONES entry listed only Phase 189 one-liners and was rewritten.
- In the archive copies: FIX-01..07 checkboxes ticked, the "in progress" headers and the 191/192 progress rows corrected, and the conditional Phase 193 handoff replaced. The audit copy is unchanged.
- The workstream REQUIREMENTS.md was removed with `git rm` after the archive copy existed. The pre-close STATE, ROADMAP, REQUIREMENTS, continue-here, state.json and PROJECT files are at `f34baa7b` on `main`, so no byte copy was made under `history/`.
- No milestone tag was created: creating or pushing a tag needs its own `allow`, and no `vX.Y` milestone tag exists in this clone.

## Verification

Live at close: `main` = `origin/main` = `f34baa7b` (PR #244 merge); PRs #242, #243 and #244 merged with merge commits; Release PR #236 still open and on hold; nothing released. This planning-only close did not rerun the suites, a simulator or Xcode.

Last completed phase: 193. Exact next command: `$gsd-new-milestone --ws quality-ratchet-release`. Debt is carried in [debt-disposition.md](debt-disposition.md).
