---
gsd_state_version: "1.0"
milestone: v26.0
milestone_name: Harden Before Trust (Phases 184–188) — in progress
current_phase: 188
status: completed
stopped_at: Phase 188 complete — all phases complete
last_updated: "2026-10-16T21:33:58.047Z"
last_activity: 2026-10-16
last_activity_desc: Phase 188 complete
state_head: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 37
  completed_plans: 37
  percent: 100
---

# Project State

## Project Reference

See `.planning/PROJECT.md` for the core thesis and decisions (updated 2026-10-15 after v25.0). Core value remains one real Phoenix application on one physical iPhone with explicit route ownership and one honest offline mutation island. Current focus: v26.0 Harden Before Trust (phases 184–188); Phase 184 Twin probe and safe preflight is complete (verification passed 4/4 after four gap rounds); Phases 185, 186 and 187 are complete (verification passed 4/4, 5/5 and 4/4); Phase 188 Freeze and twin-05 is complete (twin-05 passed; verification passed 4/4).

## Current Position

Phase: 188
Plan: Not started
Status: All phases complete
Last activity: 2026-10-16 — Phase 188 complete

Progress: [██████████] 100% (4/5 phases)

## Exact Next Action

Last completed phase: 187 Doctor and proof fidelity (v26.0, verification passed 4/4 on 2026-10-16). Last completed phase: 188 Freeze and twin-05 (TWIN-07, TWIN-08; verification passed 4/4 on 2026-10-16). No active phase: v26.0 awaits milestone audit.

- **What was checked (Phase 188 execution, 2026-10-16):** wave 1 built and self-tested the scripts in throwaway trees only: 188-01 `run-once-05.sh` (31 of 31 controls), 188-02 freeze check, identity and handoff refresh (9 of 9 subset, 18 of 18 full), 188-03 result assertion and privacy scan (15 of 15 subset, 37 of 37 full). In wave 2, 188-04 confirmed the freeze at `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` (tree `f7c4d7dc`), wrote 188-FREEZE.json and 188-IDENTITY.json, and refreshed the 180/182 handoff records between two history checks that each gave 87 OK (the 182 record now lists 129 paths and keeps the old 33 under `supersedes`). It also copied ten scripts with sha256 and ran an early privacy scan over 18 files with 0 hits. In wave 3, 188-05 ran inline in the orchestrator: it created the 0700 root, then launched `run-once-05.sh` once.
- **What happened:** gate attempt 1 passed all 30 labels (null cause), the sentinel was written at 2026-10-16T21:20:12Z, and twin-05 exited 0 with `result: passed (exit 0)` and `first cause: none`. All ten groups (T01..T10) and all seven identity joins passed. `assert-twin-05.sh` printed `assert: ok` on both the run file and the planning copy, and the negative self-test passed 15 of 15 again. The result is byte-copied into [188-TWIN-RESULT.json](phases/188-freeze-and-twin-05/188-TWIN-RESULT.json) (sha256 `cf3035ff…c448`, equal to the source). The limits, open warnings and residual gates are in [188-TWIN-RECORD.md](phases/188-freeze-and-twin-05/188-TWIN-RECORD.md). After the run the history manifest still gives 87 OK, twin-04 is unchanged, there are exactly five run roots and no twin-06, no leftover Simulator remains, and the example-host SQLite files are unchanged.
- **Orchestrator deviations:** (1) the three wave-1 plans ran concurrently with isolation forced to none. Each used its own script names and throwaway prefix, and nothing was committed. (2) 188-02 added one refusal the plan did not require: `base_head` must be an ancestor of the freeze head. The orchestrator checked it against the real records before wave 2 (`12f84cd` is an ancestor; 129 paths).
- **Did anything change:** the candidate is unchanged at `a53fbef` (porcelain 0 bytes, push URL `no-push-phase180`). The planning files are plain uncommitted files. Nothing was staged, committed, tagged, pushed or merged, and the recovery checkout stays at `d0f3e2f1`.

- **Review and verification:** a standard review of the nine new scripts ([report](phases/188-freeze-and-twin-05/188-REVIEW.md), [disposition](phases/188-freeze-and-twin-05/188-REVIEW-DISPOSITION.md)) found 0 critical, 8 warnings and 3 info. None invalidates the run; WR-01 (empty-scope scan passes), WR-03 (receipt carries no head) and WR-08 (labels without negative controls) carry into any twin reuse. Verification passed 4/4 after rerunning the D-21 list ([report](phases/188-freeze-and-twin-05/188-VERIFICATION.md)). Phase 188 is complete; all five v26.0 phases are complete.

Milestone audit (2026-10-16): [v26.0-MILESTONE-AUDIT.md](../../v26.0-MILESTONE-AUDIT.md), status tech_debt. 18/18 requirements satisfied, 5/5 phases passed, 18/18 integration paths wired, 3/3 flows complete, no blocker; open review warnings are carried as debt. Next: `$gsd-complete-milestone v26.0 --ws quality-ratchet-release` (accept debt). Do not re-run the audit. The candidate delivery gate stays open: the candidate commits need separately authorized delivery.

### Earlier detail (Phase 188 planning and Phase 187)

- **Phase 188 planning (2026-10-16):** five plans in three waves. Wave 1 builds and self-tests the scripts in throwaway trees only: 188-01 `run-once-05.sh` (go/no-go, read-only preflight, `twin-05.started` sentinel, one `verify_twin`; 31 controls), 188-02 freeze check, identity and handoff refresh (18 controls), 188-03 result assertion and privacy scan (37 controls). Wave 2 (188-04) freezes at `a53fbef`, prepares the record and identity, refreshes the handoffs between two 87-OK history checks, and byte-copies the scripts. Wave 3 (188-05) creates the 0700 root and runs twin-05 once, then asserts, copies and records the result. Refinements of the locked decisions, made at planning: `verify_twin` runs with `MIX_BUILD_PATH` and `DATABASE_PATH` unset (its database goes inside the run root, checked in source); a gate no-go uses nothing up, because only the sentinel is the one-way door, and the gate stops itself after 45 minutes; the D-03 exception names ignored `_build` output and the example database files, whose digests are compared before and after; the refreshed `core_diff_paths` lists 129 paths and says its meaning widened. The plan checker ran three rounds plus one final targeted revision; all blockers were fixed, and the only remaining validator note is the one-way rating on the run task, which D-12/D-13 already decided.

- **Phase 188 discussion (2026-10-16):** four parallel advisor research passes (fix scope, freeze/refresh, go/no-go and the single run, result capture and failure), synthesized without per-area questions at the owner's request. Decided: freeze at the current HEAD `a53fbef` with no new code commit and no squash (D-01); fix no open warning before the freeze, because 186 WR-01/WR-02 and 187 WR-02 are not on the Simulator twin path, and scripted preconditions cover the twin-path items instead (D-04, D-07); all refresh, gate and run scripts live in `/private/tmp/crosswake-phase180-run/` and are byte-copied into the phase directory (D-08); one `run-once-05.sh` owns the go/no-go and the single run, guarded by a noclobber `twin-05.started` sentinel, with the root pre-created as 0700 (D-12..D-14); the result JSON is byte-copied, a scripted count assertion with a negative self-test decides the outcome, and a `188-TWIN-RECORD.md` sidecar lists the limits (D-17..D-19); on failure the plan leaves a BLOCKED record, there is no retry, and twin-06 needs a new decision (D-20). Facts checked at discussion time: candidate HEAD `a53fbef`, clean; `twin-05` absent; history manifest 87 entries.

- **What was checked (Phase 187 execution, 2026-10-16):** seven plans ran one at a time in the candidate. 187-01: the `unmanaged_routes` finding carries sorted `unmanaged_paths` and `router` (null for a route list); an `:offline_island` `:local_first` route without `island_contract` is the `offline_posture_incomplete` error, found before the contract filter; no offline claim reports the `offline_posture_not_claimed` advisory; CHANGELOG and guides updated. 187-04: `187-DEFERRALS.md` records CW-REQ-A (both readings, deferred under either), CW-REQ-D, the compile-time rule and the D-09 gaps, with pointers from SEED-014 and REQUIREMENTS (16 PASS checks). 187-02: the evidence validator rejects an all-zero commit, accepts only the exact sentinels, and refuses sentinel provenance for physical-iPhone evidence and promotion. 187-03: new `Crosswake.ProofLane.Provenance` (no shell, scrubbed git env, tracked-tree check, fail closed to `git-unknown`) replaces the `0.1.0`, `161` and all-zero placeholders in `verify_navigation_shell`. 187-05: the loopback harness blocks an empty or bare `--evidence` (186 WR-03, D-19). 187-06: full suite 2622 tests with a failure set equal to the 186 baseline (only `phase180_twin_feasibility_test.exs:30`); adoption scan the same five carried findings; 25 mutation controls (control 0 passed unmutated, 24 failed their named tests); ledger regenerated display-only. 187-07: post-commit probe all zeros, 85 focused tests passed, history manifest 87 OK, no home path or username in evidence.
- **Commit:** one candidate commit `fix(187): give doctor findings real details and proof evidence real provenance` `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` on `bd294007`, 16 paths equal to the gated set. Push URL still `no-push-phase180`; no twin run, Simulator, xcodebuild or twin-05.
- **Orchestrator deviations:** (1) 187-02's directory-wide proof_lane run failed 87 tests with "TwinGitFixtures is not available"; the executor called it pre-existing, but the orchestrator showed it was a stale build (clean `bd29400` export 289/0, candidate on a fresh build 295/0 on both seeds), recorded in the 187-02 SUMMARY. (2) 187-06 found the root cause: `crosswake_gen_shell_host_test.exs` and `crosswake_doctor_router_test.exs` spawn `mix` subprocesses that inherit `MIX_BUILD_PATH` and corrupt a shared build mid-run; focused runs with `MIX_BUILD_PATH` set exclude those two files (they run in the full suite). (3) 187-07's probe grep expected a different key order of the same all-zero map. (4) The regression gate used 187-06's full-suite run on the identical committed tree.
- **What the review found:** a standard review of `a53fbef7` ([report](phases/187-doctor-and-proof-fidelity/187-REVIEW.md), [disposition](phases/187-doctor-and-proof-fidelity/187-REVIEW-DISPOSITION.md)): 0 critical, 4 warnings, 3 info. WR-01 is accepted by design (D-01 template-version fallback); WR-03 is the D-09 deferral. Open advisory: WR-02 `commit_ref` can report an enclosing repo's HEAD for a host directory without its own `.git` and scrubs only three `GIT_*` variables (fix before Phase 188 relies on provenance from a nested host); WR-04 public `provenance_known?/1` trusts validated input; IN-03 doctor JSON now names the router module, so confirm no proof artifact retains doctor JSON.
- **Verification:** passed 4/4 ([report](phases/187-doctor-and-proof-fidelity/187-VERIFICATION.md)). DOCTOR-01..04 are complete.

Superseded next (now in history): `$gsd-execute-phase 188 --ws quality-ratchet-release`. Plan 188-05 must run inline in the execute-phase orchestrator, which stays until `twin-05.exit` exists (D-15). Phase 188 changes no product code and runs twin-05 exactly once. The question of fixing 186 WR-01/WR-02 and 187 WR-02 before the freeze is settled: not before the freeze (188-CONTEXT D-04/D-05).

Orchestrator deviation (carried): `mix crosswake.adoption_context.scan` exits 1 with five pre-existing `routing.unclassified_path` findings under `examples/phoenix_host/native/ios/crosswake_shell/`; 185-05 gated on those findings staying the same. Any later gate that needs exit 0 has to classify those paths first.

Did anything change: product changes are in the candidate commits only (latest `a53fbef7`). Planning files (SUMMARYs, VERIFICATION, REVIEW, disposition, loop measurement, ROADMAP, REQUIREMENTS, this file) are plain uncommitted files. Nothing was staged, committed, tagged, pushed or merged in the recovery checkout, which stays at `d0f3e2f1`.

v26.0 Harden Before Trust has five phases ([roadmap](ROADMAP.md), [requirements](REQUIREMENTS.md), [research](../../research/v26/SUMMARY.md)): 184 Twin probe and safe preflight (PROBE-01..04); 185 Checks that cannot pass empty (GUARD-01..03); 186 Host seam and harness honesty (SEAM-07..09, LOOP-06, LOOP-07); 187 Doctor and proof fidelity (DOCTOR-01..04); 188 Freeze and twin-05 (TWIN-07, TWIN-08). 185–187 depend on 184; 187 follows 186 because both edit `doctor.ex`; 188 depends on all and changes no code. Product work happens in the `/private/tmp/crosswake-phase180-impl` candidate from `50fcd57`.

Carried forward (see the [debt disposition](milestones/v25.0-closeout/debt-disposition.md)):

- Silent-degrade paths for the next twin run: 183 WR-01 (git index flags hide a modified file from the clean-tree probe) and WR-02 (`core.filemode` not pinned). Fix both in the next twin-touching change, which needs a new run root (twin-05). v26.0 scopes both as PROBE-01/PROBE-02 in Phase 184.
- Delivery: the seven Phase 180 commits and `fix(183-03)` exist only in `/private/tmp/crosswake-phase180-impl` (HEAD `50fcd5743243c0b20275a7e2bd9338bf25468687`). Moving them into the authoritative tree needs separate authorization.
- Residual external gates: physical iPhone signed-device run; first adopter sanitized route handoff. The First B2C Adopter workstream remains parked.

Did anything change at v26.0 roadmap creation: ROADMAP.md, REQUIREMENTS.md traceability and this file were written as plain uncommitted files; no phase directory was created. At v25 closeout, likewise planning files only, as plain uncommitted files. Nothing was staged, committed, tagged, pushed or merged; the recovery checkout stays at `d0f3e2f1`.

### Handoff history

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

The six v23 archive acknowledgements retain their original statuses and byte-identical originals in `milestones/v23.0-closeout/original-artifacts`. No new acknowledgement or phase override was added at v24 closeout.

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

**Last session:** 2026-10-16T15:37:30.622Z
**Stopped at:** Phase 188 complete — all phases complete
**Resume file:** .planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-CONTEXT.md

## Operator Next Steps

- Execute Phase 186 with `$gsd-execute-phase 186 --ws quality-ratchet-release`
