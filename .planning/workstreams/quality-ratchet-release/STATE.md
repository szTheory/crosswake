---
gsd_state_version: "1.0"
milestone: v27.0
milestone_name: Land and Clean Up (Phases 189–193) — in progress
current_phase: 193
current_phase_name: Cleanup and new working rules
status: executing
stopped_at: Phase 193 plans 01-04 complete; plan 05 (PR 1) in progress
last_updated: "2026-10-24T15:31:48.684Z"
last_activity: 2026-10-24
last_activity_desc: Phase 193 execution started
state_head: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 55
  completed_plans: 45
  percent: 60
---

# Project State

## Project Reference

See `.planning/PROJECT.md` for the core thesis and decisions (updated 2026-10-16 after v26.0). Core value remains one real Phoenix application on one physical iPhone with explicit route ownership and one honest offline mutation island. Current focus: v27.0 Land and Clean Up — land the v25 and v26 work on GitHub `main` with CI green, then clean up the local repository so no copy of the work can be lost.

## Current Position

Phase: 193 (Cleanup and new working rules) — EXECUTING
Plan: 9 of 10 (plans 01-08 complete)
Status: Executing Phase 193 (plan 09: working rules, PR dispositions and follow-up seed)
Last activity: 2026-10-24 — Phase 193 plans 01-08 complete; working rules rewritten as plain files

Progress: [██████░░░░] 60%

## Exact Next Action

What was checked and what happened in Phase 193 so far: the backups were re-verified and the post-189 items backed up (plan 01); the push/merge gate, copy-forward, folder-swap, removal, final-check and working-rules tools were built, tested and frozen by hash (plans 02 to 04); the records and tools landed on `main` through PR 1 (plan 05); the old checkout was retired and replaced by a clean `main` checkout at the same path (plan 06); the late-record sweep found all four handoff files already equal to `main` (plan 07); after your `allow`, 300 of the 306 listed copies were removed and 6 were kept, with the ledger in `193-REMOVAL-LEDGER.md` (plan 08). One local copy remains by design: the integration clone, because 8 remote-tracking refs in it (5 Dependabot, a maintenance branch, a release-attestation branch and the release-please branch) have tips that exist in no backup.

Plan 09 changed the working rules: AGENTS.md now says to branch from `main` and open a PR (section "How changes land"), the one-use `allow`/`hold` gate covers merges, publishes, tags and remote branch deletion, every open PR has a recorded disposition (recorded only, nothing was changed on GitHub), and the Phase 192 review residue is parked as SEED-025. Nothing is committed yet; these are plain files on local `main`.

Next, plan 10 cuts a branch from `main`, opens PR 2 with these records, runs the final check, and asks you once before merging. The command is `$gsd-execute-phase 193 --ws quality-ratchet-release`.

The only human touchpoint left is the PR 2 merge `allow`/`hold` (plan 10).

### Handoff history

- Superseded (2026-10-24): frozen recovery checkout rules. Done: the recovery-checkout freeze and the /private/tmp candidate flow ended in Phase 193; work now lands through PRs from main (AGENTS.md "How changes land").
- Superseded (2026-10-24): the Exact Next Action written during Phase 193 plan 05 (PR 1). It read: "What was checked and what happened so far in Phase 193: the 189 backups were re-verified and the post-189 items were backed up (plan 01); a fresh clean clone of `main` and a standalone push/merge gate were built and dry-run (plan 02); the copy-forward, folder-swap and session-guard tools were built and tested (plan 03); the removal gate, final check and working-rules check were built and tested, and all 12 scripts are frozen by hash (plan 04). Nothing was removed. PR 1 (the Phase 192 post-sync records plus the whole Phase 193 folder) is being opened from the clean clone now; the recovery checkout has no git change.  Next, plan 05 merges PR 1 into `main` after your `allow` (you have given a standing allow for exactly that one merge, at the head it proposes, if CI is green), and plan 06 copies settings forward and swaps the folders; the session then ends. After the swap, open a new Claude Code session in `<home>/projects/crosswake` (the old checkout becomes `crosswake-recovery-retired`) and run `$gsd-execute-phase 193 --ws quality-ratchet-release`. It will recognize plans 05 and 06 as already done in the retired folder and continue at plan 07, which first checks that it is in the right folder (the guard). This is the last STATE.md write a 193 plan makes in the recovery checkout.  The only human touchpoints left: the restart, the single removal `allow`/`hold` (plan 08), and the PR 2 merge `allow`/`hold` (plan 10). All planning files are plain files and land through PR 1 (D-03, D-25)."
- Superseded (2026-10-24): `$gsd-execute-phase 193 --ws quality-ratchet-release` (start of Phase 193). Done: Phase 192 complete (PR #242 merged as `d12aed75` after the user's `allow`, CI green, verification 4/4, review 0 critical / 8 warnings / 6 info open in 192-REVIEW-DISPOSITION.md); Release Please succeeded and all publish jobs were skipped; open PRs #236, #238 and the Dependabot PRs were not touched by this phase. Phase 193 inputs then: 192 post-sync records as plain files (R-2), IN-01/IN-02 follow-ups, local trial branches and the integration clone to clean up, CLEAN-04 working rules.
- Superseded (2026-10-23): `$gsd-plan-phase 193 --ws quality-ratchet-release`. Done: research, pattern map, validation strategy and plans 193-01..10 written (9 waves). The plan checker ran 3 rounds, followed by one targeted fix the user approved; no blockers remain. Requirements CLEAN-01..04 and decisions 27/27 are covered. The user approved amendments D-22 (one small tar for the un-inventoried temp folders), D-25 (PR 1 carries the whole 193 folder) and D-26 (A-14 private-name skip extended to the 193 pushes). D-23, D-24 and D-27 are technical corrections. Plain uncommitted files; no git write in the recovery checkout.
- Superseded (2026-10-23): `$gsd-execute-phase 192 --ws quality-ratchet-release`. Done: plans 192-01..10 executed (push, PR #242, Crosswake CI green after fix-forward, merge commit `d12aed75` after the user's `allow`, post-merge proof, phase gate with amendment A-10-1); 192-08 and 192-10 each needed re-runs (run records kept as *-BLOCKED.runN.md). No git write in the recovery checkout.
- Superseded (2026-10-23): `$gsd-execute-phase 192 --ws quality-ratchet-release` start (Phase 191 handoff). Done: Phase 191 built the integration branch `land/v25-v27` (112 commits ahead of `main`), full local suite and privacy scan passed at the sync head, nothing pushed.

- Superseded (2026-10-23): `$gsd-plan-phase 192 --ws quality-ratchet-release`. Done: research, pattern map, validation strategy and plans 192-01..10 written (9 waves); plan checker 3 rounds plus one user-approved targeted fix, no blockers remaining; requirements LAND-03/LAND-04 and decisions 10/10 covered. Plain uncommitted files; no git write in the recovery checkout.
- Superseded (2026-10-23): `$gsd-verify-work 191 --ws quality-ratchet-release`. Done inside `$gsd-execute-phase 191`: plans 191-01..12 executed (191-10 and 191-11 each re-run once; run-1 records kept as *-BLOCKED.run1.md); verification passed 4/4; code review 0 critical / 3 warning / 2 info, all open in 191-REVIEW-DISPOSITION.md; Phase 191 marked complete. No git write in the recovery checkout; nothing pushed.
- Superseded (2026-10-22): `$gsd-execute-phase 191 --ws quality-ratchet-release`. Done: plans 191-01..12 executed in the integration clone (112 commits ahead of `main`, 94 candidate commits and 4 FIX commits preserved); full local suite green, privacy scan clean at the sync head, nothing pushed, recovery checkout unchanged. Plain uncommitted files in the recovery checkout.

- Superseded (2026-10-19): `$gsd-verify-work 190 --ws quality-ratchet-release`. Done inside `$gsd-execute-phase 190`: plans 190-01..10 executed (4 FIX commits in `<durable-candidate>`: 9c7c732b, 01e07a51, 8a529f52, 2faf15a2); verification passed 7/7; code review 0 critical / 11 warning / 4 info, all open in 190-REVIEW-DISPOSITION.md; Phase 190 marked complete. Plain files only; no Git operation in the recovery checkout after the pre-snapshot `git status` noted above.
- Superseded (2026-10-19): the Phase 190 execution handoff. Done: Phase 190 was planned as 10 plans in 7 waves (research, pattern map, validation strategy, plans 190-01..10; plan checker 3 rounds, no blockers; requirements 7/7 and decisions 10/10 covered), and the plans were then executed; no commits in the recovery checkout.
- Superseded (2026-10-19): `$gsd-plan-phase 190 --ws quality-ratchet-release`. Done: 190-RESEARCH.md, 190-PATTERNS.md, 190-VALIDATION.md and plans 190-01..10 written; plan checker 3 rounds, no blockers remaining; requirements 7/7 and decisions 10/10 covered. Plain uncommitted files; no Git operation in the recovery checkout.
- Superseded (2026-10-19): `$gsd-discuss-phase 190 --ws quality-ratchet-release`. Done: 190-CONTEXT.md and 190-DISCUSSION-LOG.md written (D-01..D-10); ROADMAP criterion 5 reworded per D-02. Plain uncommitted files; no Git operation in the recovery checkout.
- Superseded (2026-10-18): the gap-closure handoff. Done: gap closure was planned and executed as plans 11 to 13; plan 13 stopped once at a review check (record in 189-13-BLOCKED.run1.md), the user chose to accept and rerun it, and the rerun passed. No commits per the checkout rule.
- Superseded (2026-10-18): `$gsd-execute-phase 189 --ws quality-ratchet-release` (third run). Done: plan 10 run 3 passed after the amended no-deletion check; scripts re-verified (22 of 22), after-snapshot equal apart from the two allowed temp-listing lines, pre-execution documents scanned, final scan 0 hits, phase folder backed up and restored, `<durable-candidate>` verified. 10 plans executed; no commits per the checkout rule.
- Superseded (2026-10-18): `$gsd-execute-phase 189 --ws quality-ratchet-release` (second run). Done: plan 10 run 2 stopped because the macOS temp cleaner removed 60 loose temp-folder files; the user approved amending the no-deletion check (record in 189-10-BLOCKED.run2.md).
- Superseded (2026-10-18): plan 10 run 1 stopped on two false at-sign hits in copied scripts; repaired by a user-approved one-line scan fix (record in 189-10-BLOCKED.run1.md).
- Superseded (2026-10-16): `$gsd-execute-phase 189 --ws quality-ratchet-release` (first run, history). Done: plans 189-01..09 executed; plan 10 stopped at its final privacy scan (scan_hit on two copied scripts), after the frozen-state and no-deletion checks passed. No commits per the checkout rule.
- Superseded (2026-10-16): `$gsd-plan-phase 189 --ws quality-ratchet-release`. Done: 189-RESEARCH.md, 189-VALIDATION.md and plans 189-01..10 written (6 waves); plan check passed after three revisions plus one targeted fix (one remaining warning accepted with a mode-0600 check); requirements INV-01..03 and decisions 15/15 covered; INV-01, INV-03 and Phase 189 criteria 1 and 3 reworded to include *unclassified* and *hold*; nothing staged or committed.
- Superseded (2026-10-16): `$gsd-discuss-phase 189 --ws quality-ratchet-release`. Done: 189-CONTEXT.md written (15 decisions). User chose to keep backups local in 189, with the first off-machine copy at the Phase 191/192 push after the privacy scan. No commit (checkout rule).
- Superseded (2026-10-16): `$gsd-new-milestone --ws quality-ratchet-release`. Done: v27.0 Land and Clean Up started; 18 requirements defined (INV, FIX, LAND, CLEAN); roadmap created with phases 189–193 and 18/18 requirements mapped. The v26 handoff it replaced read: "Fresh scope is unselected"; carried forward the v26 debt (188 WR-01, 188 WR-08, the unpinned `g()` gate helper, 185 WR-02, 187 WR-02, the stale guard pin 249 vs 253, and the 186 WR-01 owner decision), the undelivered v26 commits in the candidate (HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`), and the residual external gates (physical signed-iPhone run; first adopter sanitized route handoff). Those items are now v27 requirements FIX-01..07 and LAND-01..04, except the external gates, which remain parked. Closeout changed planning files only; the recovery checkout stayed at `d0f3e2f1`; the pre-closeout STATE is in `history/v26.0-closeout-handoff/STATE.md`.
- Superseded (2026-10-16): `$gsd-complete-milestone v26.0 --ws quality-ratchet-release`. Done: planning closeout; archive copies, debt disposition and closeout record in `milestones/`. No commit or tag (checkout rule).
- Superseded (2026-10-16): `$gsd-audit-milestone --ws quality-ratchet-release`. Done: v26.0-MILESTONE-AUDIT.md written, status tech_debt (requirements 18/18, integration 18/18, flows 3/3, no blocker).
- Superseded (2026-10-16): `$gsd-execute-phase 188 --ws quality-ratchet-release`. Done: 188-01..05 executed; twin-05 ran once and passed (exit 0); TWIN-07 and TWIN-08 complete. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-plan-phase 188 --ws quality-ratchet-release`. Done: 5 plans in 3 waves (188-01..05). Commits skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-discuss-phase 188 --ws quality-ratchet-release`. Done: 188-CONTEXT.md (D-01..D-21) and 188-DISCUSSION-LOG.md written as plain files after four parallel advisor research passes. Commits in the recovery checkout skipped per checkout rule.

- Superseded (2026-10-16): `$gsd-execute-phase 187 --ws quality-ratchet-release`. Done: 187-01..07 executed; commit `fix(187)` `a53fbef7`; review 0 critical / 4 warnings / 3 info; verification passed 4/4; Phase 187 complete. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-plan-phase 187 --ws quality-ratchet-release`. Done: research, pattern map, validation strategy, 7 plans (187-01..07); plan checker 3 rounds, final two warnings fixed inline. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-discuss-phase 187 --ws quality-ratchet-release`. Done: 187-CONTEXT.md (D-01..D-19) and 187-DISCUSSION-LOG.md written as plain files after three parallel advisor research passes. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-execute-phase 186 --ws quality-ratchet-release`. Done: 186-01..05 executed (186-05 re-run once after a stale-fixture stop); commit `fix(186)` `bd294007`; review 0 critical / 3 warnings / 4 info; verification passed 5/5; Phase 186 complete. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-execute-phase 185 --ws quality-ratchet-release`. Done: 185-01..05 executed; commit `fix(185)` `25614cf6`; review 0 critical / 5 warnings / 2 info; verification passed 4/4; Phase 185 complete. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): the Phase 184 gap-round-4 detail (184-13/184-15/184-14, `fix(184-14)` `b898e110`, review 184-REVIEW-GAPS-4 0 critical / 2 warnings / 3 info, verification 4/4). Open items kept: WR-05 preflight-only (D-31, Phase 188 TWIN-07), D-36 deferrals, GAP4-WR-01 (bounded read of git local files) for the next twin-touching change.
- Superseded (2026-10-16): `$gsd-execute-phase 184 --gaps-only --ws quality-ratchet-release` (gap round 4). Done: 184-13 (run 1 blocked, plan amended with Step B2, re-run complete), 184-15 and 184-14 executed; commit `fix(184-14)` `b898e110`; review 184-REVIEW-GAPS-4 found 0 critical / 2 warnings / 3 info; re-verification passed 4/4; Phase 184 complete. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-plan-phase 184 --gaps --ws quality-ratchet-release` (gap round 4). Done: plans 184-13, 184-15 and 184-14 written (decisions D-39..D-42 proposed; recorded by 184-15); plan checker passed after 2 revisions. Commits skipped per checkout rule.
- Superseded (2026-10-16): `$gsd-execute-phase 184 --gaps-only --ws quality-ratchet-release` (gap round 3). Done: 184-11 and 184-12 executed; commit `fix(184-12)` `e4344ca5`; review 184-REVIEW-GAPS-3 found GAP3-CR-01, GAP3-CR-02, GAP3-WR-01; re-verification gaps_found 3/4. Commits in the recovery checkout skipped per checkout rule.
- Superseded (2026-10-15): `$gsd-plan-phase 184 --gaps --ws quality-ratchet-release` (gap round 3). Done: plans 184-11 and 184-12 written; checker found no blockers (one trailer warning set aside, three info notes). Commits skipped per checkout rule.
- Superseded (2026-10-23): `$gsd-verify-work 192 --ws quality-ratchet-release`. Done inside `$gsd-execute-phase 192`: verifier passed 4/4, regression gate passed, code review recorded (0/8/6, open), phase.complete ran.
- Superseded (2026-10-15): `$gsd-execute-phase 184 --gaps-only --ws quality-ratchet-release` (gap round 2). Done: 184-09 and 184-10 executed; fix(184-10) `b5399e51`; review found GAP2-CR-01 and GAP2-CR-02 (both reproduced); re-verification gaps_found 3/4. Commits skipped per checkout rule.
- Superseded (2026-10-15): the gap-round-1 handoff (decide on GAP-CR-01). Done: the user ran `$gsd-plan-phase 184 --gaps --ws quality-ratchet-release`; plans 184-09 and 184-10 written; checker passed after one revision. Commits skipped per checkout rule.
- Superseded (2026-10-15): `$gsd-plan-phase 184 --gaps --ws quality-ratchet-release`. Done: gap-closure plans 184-07 (fixes, 4 tasks) and 184-08 (gates, 13 mutation controls, single commit); plan checker 3 rounds, no blockers, warnings resolved. Commits skipped per checkout rule.
- Superseded (2026-10-15): `$gsd-execute-phase 184 --ws quality-ratchet-release`. Done: 184-01..06 executed, one candidate commit `1f5d18ee`, verification passed 4/4, code review 1 critical / 5 warnings; the user chose gap closure.
- Superseded (2026-10-15): `$gsd-plan-phase 184 --ws quality-ratchet-release`. Done: research (L1–L19, adopted as D-23..D-33), pattern map, validation strategy, 6 plans; plan checker ran 3 iterations plus 2 focused orchestrator-guided passes (all blockers and warnings resolved; probes clean; 4/4 requirements and 33/33 decisions covered). Commits skipped per checkout rule.
- Superseded (2026-10-15): `$gsd-discuss-phase 184 --ws quality-ratchet-release`. Done: four advisor researchers plus an adversarial pass (scratch-repo git experiments); 22 decisions in 184-CONTEXT.md, auto-followed at the user's request.
- Superseded (2026-10-15): `$gsd-new-milestone --ws quality-ratchet-release`. Done: v26.0 Harden Before Trust started; research written under `research/v26/`; 18 requirements defined; roadmap created with phases 184–188 and 18/18 requirements mapped.
- Superseded (2026-10-15): `$gsd-complete-milestone v25.0 --ws quality-ratchet-release`. Done: planning closeout; archive copies in `milestones/`; prior handoff kept in `history/v25.0-closeout-handoff/`.
- Superseded (2026-10-16): `$gsd-plan-phase 188 --ws quality-ratchet-release`. Done: 188-RESEARCH.md, 188-PATTERNS.md, 188-VALIDATION.md and plans 188-01..05 written; decision coverage 21/21, requirements TWIN-07 and TWIN-08 covered; nothing staged or committed.
- Superseded (2026-10-15): `$gsd-audit-milestone --ws quality-ratchet-release` (re-audit). Done: status tech_debt, requirements 20/20, integration 14/16, blocker closed.
- Superseded (2026-10-15): `$gsd-execute-phase 183 --ws quality-ratchet-release`. Done: 183-01..05 executed; verification passed 6/6; code review 0 critical / 4 warnings (open); seven Phase 180 commits plus `fix(183-03)` in the candidate; eight mutation controls bit; twin-04 passed (exit 0, 49/49).
- Superseded (2026-10-15): `$gsd-plan-phase 183 --ws quality-ratchet-release`. Done: 183-RESEARCH.md, 183-PATTERNS.md, 183-VALIDATION.md and plans 183-01..05 written; plan checker passed after one revision (stderr privacy test made fd-level); requirement and decision coverage 3/3 and 20/20; nothing staged or committed.
- Superseded (2026-10-15): `$gsd-discuss-phase 183 --ws quality-ratchet-release`. Done: 183-CONTEXT.md and 183-DISCUSSION-LOG.md written; nothing staged or committed.
- Superseded (2026-10-15): `$gsd-phase --ws quality-ratchet-release "Close gap: twin source binding fails closed on uncommitted code"`. Done: Phase 183 added with its directory, roadmap detail, phase list and progress row.
- Superseded (2026-10-15): `$gsd-execute-phase 180 --ws quality-ratchet-release --wave 6` (twin-03). Done: twin-03 passed (exit 0, 49/49); TWIN-01..06 complete; verification passed 5/5; Phase 180 complete.
- Superseded (2026-10-15): the twin-02 handoff (repair the harness, diagnose case 3, amend 180-07). Done: three runner faults repaired and tested (registry crash, lost stage cause, unreadable backend counters); case 3 passed in two throwaway diagnostic runs, and the second passed all 49 observations; 180-07 amended; the twin-02 summary and result were preserved under `.twin-02` names.
- Superseded (2026-10-15): `$gsd-audit-milestone --ws quality-ratchet-release`. Done: v25.0-MILESTONE-AUDIT.md written, status gaps_found (requirements 20/20, integration 11/15, one source-binding blocker); see Exact Next Action.
- Superseded (2026-10-15): the twin-01 handoff (prepare the candidate record and run twin-02). Done: record prepared and prechecked; twin-02 ran once and produced an all-blocked receipt (case 3 attachment check unavailable) plus a command crash after the receipt was written; see Exact Next Action.
- Superseded (2026-10-15): `$gsd-execute-phase 180 --ws quality-ratchet-release` (gate rerun on `da53c54`, then 180-05..180-07). Done: gate rerun reported existing_path_supported; 180-05, 180-06 and 180-07 executed in the candidate; the single twin run (twin-01) was blocked with `prerequisite_missing` because no candidate record file was passed.
- Superseded (2026-10-14): `$gsd-execute-phase 182 --ws quality-ratchet-release`. Done: six plans complete in `/private/tmp/crosswake-phase182-impl` (final head `da53c54db06e54be5a80fb4be144a70d3fed36a5`); verification passed 5/5; LOOP-01..05 complete; Phase 180 candidate moved onto the final head. Before it: 180-01..180-04 complete on `12f84cd`, 180-05 blocked at Task 1 on the HTTPS-only origin, and the user chose "Allow loopback".
- Superseded (2026-10-14): `$gsd-plan-phase 182 --ws quality-ratchet-release`. Done: 182-RESEARCH.md, 182-PATTERNS.md, 182-VALIDATION.md and six plans. Research corrected the discussion: Info.plist is created once and host-owned, not a managed output, so CONTEXT gained D-23 (bounded reconcile of the Crosswake block, with a production-host exception). The UI gate's frontend flag was a false positive (the word "page") and was skipped. Requirement coverage 5/5, decision coverage 23/23; checker iterations 3 with no blockers left, final warnings fixed and grep-verified. Plain uncommitted files; no Git operation in the recovery checkout.
- Superseded (2026-10-14): `$gsd-discuss-phase 182 --ws quality-ratchet-release`. Done: the user selected all four areas and delegated a researched, adversarially checked recommendation set; four research subagents plus an orchestrator adversarial pass produced 182-CONTEXT.md (D-01..D-22) and 182-DISCUSSION-LOG.md; LOOP-01..05 added to REQUIREMENTS.md. Plain uncommitted files; no Git operation in the recovery checkout.
- Superseded (2026-10-14): `$gsd-phase --ws quality-ratchet-release` to add the loopback-origin core phase. Done: Phase 182 was added with its directory and roadmap entry.

- Superseded (2026-10-14): `$gsd-execute-phase 180 --ws quality-ratchet-release`, continuing at wave 3. Done: 180-03 and 180-04 complete; 180-05 blocked at Task 1 on the HTTPS-only `:ios_host` origin; the user allowed a separate loopback-origin core phase.

- Superseded (2026-10-14): `$gsd-execute-phase 180 --ws quality-ratchet-release` for the 180-01 rerun. Done: gate reran on head `12f84cd950d4574921767df823faed6797c17c26` with verdict `existing_path_supported` (G1-G4 refuted, five controls passed, four invariants held); 180-02 recorded `not_required`, preserved the earlier allow as `180-DECISION.baseline.json`, and set 180-03/180-04 eligible. The earlier stopped-at-gate T01-T10 `not_observed` handoff no longer applies because the gate cleared.
- Superseded (2026-10-14): `$gsd-execute-phase 181 --ws quality-ratchet-release`. Done: ten plans in the candidate `/private/tmp/crosswake-phase181-impl`; final head `12f84cd950d4574921767df823faed6797c17c26`; final preflight `existing_path_supported`; full regression passed; `180-SEAM-HANDOFF.json` written and validated; 180-01/180-02 summaries renamed to baselines; SEAM-01..06 complete.
- Superseded (2026-10-14): `$gsd-plan-phase 181 --ws quality-ratchet-release`. Done: 181-RESEARCH.md, 181-PATTERNS.md, 181-VALIDATION.md and 10 plans; requirement coverage 6/6 and decision coverage 29/29. The final checker pass found no blockers, and its two remaining warnings were fixed in a targeted pass. Planning files are untracked plain files (no git operation in the recovery checkout, per D-24).
- Superseded (2026-10-14): `$gsd-discuss-phase 181 --ws quality-ratchet-release`. Done: five research lenses plus an adversarial pass produced 181-CONTEXT.md (central versioned `host_commands:` registry; per-route manifest `host_commands` as sole authority; explicit `.offlineIsland` presentation; additive manifest schema 1.2.0 with a compiled-in shell constant and a fail-closed generation gate; Android byte-unchanged; new candidate `/private/tmp/crosswake-phase181-impl`). SEAM-01..06 added.
- Superseded (2026-10-14): `$gsd-phase --ws quality-ratchet-release` to add the authorized core-seam phase. Done: it was added as Phase 181: Core Host-Command Seam, depending on Phase 179, with the seam handoff contract as its completion criterion.
- Superseded (2026-10-14, before the gate ran): the Phase 180 planning handoff directed `$gsd-execute-phase 180 --ws quality-ratchet-release` to start at 180-01, derive candidate `/private/tmp/crosswake-phase180-impl` from the Phase179 candidate (HEAD `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`, tree `0514b6244ec814c1d0701d580b04651f70f57019`, bound by the Phase 179 verification) and run the feasibility gate. 180-01 is now complete with verdict stop_missing_seam, and 180-02 recorded the user's allow decision.

## Accumulated Context

### Roadmap Evolution

- v27.0 roadmap created (2026-10-16): phases 189–193 follow the suggested five-phase structure (inventory and backup, fixes in the candidate, integration branch in a separate durable clone, PR/CI/merge, cleanup); 18/18 requirements mapped, no orphans.

- v26.0 roadmap created (2026-10-15): phases 184–188 follow the five-phase structure in the v26 research synthesis unchanged; 18/18 requirements mapped, no orphans.

- Phase 183 added (2026-10-15): Close gap: twin source binding fails closed on uncommitted code. Gap closure for the v25.0 milestone audit blocker (twin `source`/`installed_build` joins bind only committed HEAD/tree; twin-03 ran with Phase 180 code uncommitted). Covers TWIN-01, TWIN-05, TWIN-06 attestation.

- Phase 182 added (2026-10-14): Loopback Origin for Local iOS Host. It allows an http loopback origin only in an explicit local/dev `:ios_host` mode, with ATS `NSAllowsLocalNetworking` and never `NSAllowsArbitraryLoads`; production stays HTTPS-only. Authorized by the user's "Allow loopback" choice when 180-05 was blocked.

- Phase 181 discussed (2026-10-14): requirements SEAM-01..06 added and mapped to its six success criteria.
- Phase 181 added (2026-10-14): Core Host-Command Seam. Covers route declaration of host commands, declaration-driven activation capability projection, native session delivery, bounded-shell offline-island admission and a versioned wire contract. Authorized by the user's allow in 180-02.

### Current decisions and limits

- v25.0 closed 2026-10-15 with all 20 requirements (IOS, TWIN, SEAM, LOOP) satisfied; TWIN-01/05/06 were re-attested by twin-04 against the committed fix. The bullets below are the v25 decisions as recorded during the milestone.
- Phase 179 uses ordinary compile-only Phoenix/Mix build configuration, the canonical selected router/entry/primary origin, managed-output ownership and interrupted-update recovery, and explicit unsigned-simulator/device-capable Xcode settings. Generation must not require `app.config`, `app.start` or unrelated runtime-server credentials.
- Phase 180 joins one actual generated candidate, its visible study WebView and bridge, normal island persistence/replay, host-owned playback initiated through the existing declared `host.*` delegate, and an independently observed Phoenix/Ecto effect. The fixed T01–T10 groups and a derived privacy-safe twin receipt are the finite virtual boundary; a simulator receipt cannot promote physical/adopter support.
- The twin runner owns a fresh database/server/port/app context and verifies target-scoped network denial. Stable generation/receipt contracts may enter existing CI leaves; no new platform, generic core/storage API or recurring simulator lane is selected. Required virtual observations must pass; a genuine blocker remains incomplete.

### Phase180 discussion findings

- The confirmed declaration/activation gap blocks the proposed visible host-audio join. It is not a physical/adopter residual or authorization for a new core seam. The [research](phases/180-bounded-digital-twin-demonstration/180-DISCUSSION-RESEARCH.md) records exact source findings and corrected alternatives.
- The reference island also lacks visible free-form entry and a positive recovery destination; narrow host work fits T03/T07 only if the earlier scope gate permits further implementation.
- The runner must bind the prepared candidate’s exact loopback origin exclusively and preserve it through persistence testing. Private diagnostic storage never exempts sensitive data. A twin-only receipt requires mandatory owner sub-observations for each exact T01–T10 group.
- Delegated recommendations completed discussion without a preference interview. No automatic chain, new core support, source mutation, Git operation, release or remote delivery was selected.

### Phase179 evidence limits

- Missing pre-fix RED evidence for Plan03 Tasks1/2 and the Resources-membership repair remains advisory process debt under `tdd_mode=false`. Earlier subprocess failures with no retained assertion/child output retain unknown causes; later failures are not substituted as their causes.
- The scoped completion scanner returned four summary-path warnings because new source stays outside recovery and two command strings were parsed as paths. Actual candidate files and all 45 source exports were independently verified. Warnings and their dispositions remain in [completion](phases/179-ios-host-setup-without-hand-patches/179-COMPLETION.json); original summaries remain unchanged.

### Historical proof and retained limits

- v24.0 closed 8/8 requirements across Phases 176–178 and 15 plans; its [audit](milestones/v24.0-MILESTONE-AUDIT.md) retained six debt records. The accepted `script/verify_repository.sh --all` run passed all nine stages in an independent private clone; 48 required hosted checks joined the exact governed merge object `f2d8875ee52d9679157c73b4a701b510ee612cb8` (tree `27f4073039b4dd976492127549603a76ce22499b`). The run was warm-cache, with clean HEAD/tree, index bytes and NUL status verified. No cold-cache claim is made.
- Phase 177's approved head `3e8a4b2601b542323edfd6053f25e56c67873b47` and the final merge share that tree; the eight-file delta preserves 230 assertion keys and 52 frozen guard rows. All 119 captured local paths/private archives and 1,677 protected historical files remain preserved. Plan93 and mirror historical reader/receipt comparisons remain unproven.
- Two earlier seeded full-run failures have unknown causes because their assertion output was not retained. Chromium MachPort and SwiftPM sandbox denials were separately observed; a later approved less-restricted complete run passed. No cause is inferred for the two missing-output failures.
- v23.0 remains archived with exceptions: Phase 175 is 8/9 and REL-10 breached because the first publication omitted the incident-response runbook. Six accepted historical high limitations and twelve lower findings remain; Nyquist coverage is partial. None is silently promoted by v25.
- PR #238 remains open/unmerged. Its exact ordinary push/PR proposal was delivered and read-reconciled, the one-use binding is consumed, and actor attribution was not retained. No merge, release, publication, protected-history operation or recovery-checkout Git mutation is authorized by v25 planning.
- The First B2C Adopter lane remains parked at Phase 163.1-08 Task 2 until a validated sanitized route handoff exists. Resume only with `--ws first-b2c-adopter-readiness` after that input gate is met; a fresh source-bound signed-device run is then required for promotion. Existing reference/simulator proof is non-transferable.

### Working posture

Use the [v25 research synthesis](../../research/v25/SUMMARY.md) and [approved roadmap](ROADMAP.md) for the exact finite scenario roster and source/observation boundaries. Preserve explicit route ownership, backend auth authority, fail-closed denials, opaque scoped replay and payload redaction. Keep the recovery checkout and historical paths intact. Name the check, result, concrete cause if retained, remaining unknown and next action in plain language.

## Deferred Items

The six v23 archive acknowledgements retain their original statuses and byte-identical originals in `milestones/v23.0-closeout/original-artifacts`. No new acknowledgement or phase override was added at the v24, v25 or v26 closeouts.

| Category | Item | Status | Deferred At | Milestone |
|---|---|---|---|---|
| debug_sessions | release-automation-failures | fixing | 2026-10-11 | v23.0 |
| debug_sessions | release-please-guard-36352732061 | diagnosed | 2026-10-11 | v23.0 |
| uat_gaps | v22.0 / 168 / 168-UAT.md | blocked | 2026-10-11 | v23.0 |
| verification_gaps | 175 / 175-VERIFICATION-ARCHIVE-PRE-PLAN148-CLOSEOUT.md | gaps_found | 2026-10-11 | v23.0 |
| verification_gaps | 175 / 175-VERIFICATION.md | gaps_found | 2026-10-11 | v23.0 |
| verification_gaps | v22.0 / 168 / 168-VERIFICATION.md | gaps_found | 2026-10-11 | v23.0 |

The six separate v24 debt items remain in the [debt disposition](milestones/v24.0-closeout/debt-disposition.md): original SUMMARY arrays; Plan93 reader/receipt comparison; mirror reader/receipt comparison; historical guidance fixture epoch; and the two earlier full-run failures whose assertion text was not retained. None becomes v25 implementation scope.

## Session

**Last session:** 2026-10-19T23:54:39.524Z
**Stopped at:** Phase 192 complete, ready to plan Phase 193
**Resume file:** .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-10-SUMMARY.md

## Operator Next Steps

- Run `$gsd-execute-phase 193 --ws quality-ratchet-release` to continue at plan 10 (PR 2, final check, merge `allow`/`hold`); see Exact Next Action
