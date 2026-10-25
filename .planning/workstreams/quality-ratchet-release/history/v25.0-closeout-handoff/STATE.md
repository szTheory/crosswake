---
gsd_state_version: "1.0"
milestone: v25.0
milestone_name: iOS Host Setup & Digital Twin Proof
current_phase: 183
status: completed
stopped_at: Phase 183 complete (verified 6/6); v25.0 re-audit next
last_updated: "2026-10-15T13:59:30.333Z"
last_activity: 2026-10-15
last_activity_desc: Phase 183 complete
state_head: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 32
  completed_plans: 32
  percent: 100
last_completed_phase: 180
archived_phase_with_gaps: 175
current_plan: null
---

# Project State

## Project Reference

See `.planning/PROJECT.md` for the core thesis and decisions. Current workstream focus: v25.0 iOS host setup and bounded reference twin, as approved in [authorization](v25.0-start/authorization.json). Core value remains one real Phoenix application on one physical iPhone with explicit route ownership and one honest offline mutation island. The shared project document includes the Phase179 result; scoped requirements and roadmap own the current handoff.

## Current Position

Phase: 183 (Close gap: twin source binding fails closed on uncommitted code) — COMPLETE
Discussion: Complete (183-CONTEXT.md).
Plan: 5 of 5 complete
Status: All five v25.0 phases complete (179, 180, 181, 182, 183); milestone re-audit next
Last activity: 2026-10-15 — Phase 183 verified (passed 6/6) and marked complete
Progress: [██████████] 100% — 5 of 5 phases; all 20 v25.0 requirements complete; TWIN-01/05/06 re-attested by twin-04.
Last completed phase: 183 — the twin source binding now fails closed on an uncommitted candidate; twin-04 passed against fix(183-03). Before that, 180 — Bounded Digital Twin Demonstration.

## Exact Next Action

Last completed phase: 183, verified on 2026-10-15 (passed 6/6, [report](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-VERIFICATION.md)). Every v25.0 phase is complete. The milestone audit that found the source-binding gap has not been rerun.

What was checked (2026-10-15): `mix crosswake.proof_lane.verify_twin ios` ran once from the candidate `/private/tmp/crosswake-phase180-impl` into the new root `/private/tmp/crosswake-phase180-run/twin-04`, using the prepared record `twin-04-candidate.json` and the identity `183-IDENTITY.json`. The candidate HEAD was commit `fix(183-03)` (`50fcd5743243c0b20275a7e2bd9338bf25468687`), which sits on seven ordinary commits holding all the Phase 180 code, so every line that ran is committed. The candidate tree was clean before and after the run, and the runner itself now refuses a dirty tree (`source_dirty`) when it freezes the source and again when it builds the receipt.

What happened: the run took about six minutes and exited 0, printing `result: passed` and `first cause: none`. All ten groups, all 49 observations and all seven identity joins passed, including `source` and `installed_build`. `183-TWIN-RESULT.json` is a byte copy of the run's projection (`cmp` matches) and its `receipt_sha256` (`c726b584f0f3d97733ebabbff9c6f9e086cb67796103bced9e0d8f53c752da00`) matches `receipt.json`. The run root holds no result bundle, database or media file. It supersedes `180-TWIN-RESULT.json` for TWIN-01/05/06 attestation; the twin-03 result is unchanged and annotated by its sha256 in `180-TWIN-RESULT.twin-03.annotation.json`.

- T01: passed
- T02: passed
- T03: passed
- T04: passed
- T05: passed
- T06: passed
- T07: passed
- T08: passed
- T09: passed
- T10: passed

Failed or blocked: none.

Fidelity limits: simulator not physical speaker; simulator not signed device; synthetic_test_authority not real adopter; trusted local runner not cryptographic certification; source edit made and reverted during a run not detected.

Residual external gates: physical iPhone signed-device run; first adopter sanitized route handoff (durable codename in planning files: First B2C Adopter).

Guide pending reconciliation: candidate guide `/private/tmp/crosswake-phase180-impl/guides/see_it_run.md`, SHA-256 `d8c97d03a431f94a46db4dfa7ed76e1362f366b1ac9278e90c3cc9afde30d769`.

Delivery residual: the seven Phase 180 commits (feat 180-01/03/04/05/06, the ledger chore, feat 180-07) and `fix(183-03)` exist only in the `/private/tmp` candidate. Moving them into the authoritative tree needs a separately authorized delivery.

What is unknown and why: why case 3 stalled in twin-02 is still not known, because that run kept no class for it. An edit made and reverted inside one run would not be detected; this is stated as the fifth fidelity limit. Deferred: the twin join against the Phase 179 identity/settings projections (hardcoded bundle id).

Did anything change: yes, in the candidate only (eight new commits). Planning files were edited as plain uncommitted files. Nothing was pushed, merged, released, staged or committed in the recovery checkout.

Code review (advisory, [disposition](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-REVIEW-DISPOSITION.md)): 0 critical, 4 warnings, 4 info, all open. Two warnings are fail-open paths for future runs. Git index flags (`assume-unchanged`/`skip-worktree`) or `core.filemode=false` could hide a change from the clean-tree gate. Neither was present at twin-04 (all 3257 index entries normal, filemode true), so the twin-04 attestation stands. The fix belongs in the next twin-touching change and needs a new run root.

Next: `$gsd-audit-milestone --ws quality-ratchet-release` (re-audit v25.0 now that the gap is closed). After a clean audit: `$gsd-complete-milestone v25.0 --ws quality-ratchet-release`.

Still open: `OfflineController.index` builds its island contract with route id `study-session`, while the router id is `offline-study` (flagged by 180-04, not renamed). The 182 review dispositions (6 warnings, 4 info) also stay open. The First B2C Adopter workstream remains parked.

### Handoff history

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

- Phase 183 added (2026-10-15): Close gap: twin source binding fails closed on uncommitted code. Gap closure for the v25.0 milestone audit blocker (twin `source`/`installed_build` joins bind only committed HEAD/tree; twin-03 ran with Phase 180 code uncommitted). Covers TWIN-01, TWIN-05, TWIN-06 attestation.

- Phase 182 added (2026-10-14): Loopback Origin for Local iOS Host. It allows an http loopback origin only in an explicit local/dev `:ios_host` mode, with ATS `NSAllowsLocalNetworking` and never `NSAllowsArbitraryLoads`; production stays HTTPS-only. Authorized by the user's "Allow loopback" choice when 180-05 was blocked.

- Phase 181 discussed (2026-10-14): requirements SEAM-01..06 added and mapped to its six success criteria.
- Phase 181 added (2026-10-14): Core Host-Command Seam. Covers route declaration of host commands, declaration-driven activation capability projection, native session delivery, bounded-shell offline-island admission and a versioned wire contract. Authorized by the user's allow in 180-02.

### Current decisions and limits

- v25 has three verified requirements (IOS-01/02/03, Phase179) and six pending requirements (TWIN-01/02/03/04/05/06, Phase180). Phase179 is complete; Phase180 is planned with the feasibility gate first. No twin runtime check has run.
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

**Last session:** 2026-10-14T22:51:04.104Z
**Stopped at:** Phase 183 complete; v25.0 re-audit next
**Resume file:** .planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-01-PLAN.md
