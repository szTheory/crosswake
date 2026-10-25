---
gsd_state_version: "1.0"
milestone: v28.0
milestone_name: Truth and Release Train
current_phase: 194
current_phase_name: Bearings reset and ADR amendments
status: executing
stopped_at: Completed 194-01-PLAN.md
last_updated: "2026-10-25T02:31:32.141Z"
last_activity: 2026-10-24
last_activity_desc: Phase 194 execution started
state_head: 8a3f2f9d40d8ac50406792e5bf57084b6e2c4603
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 9
  completed_plans: 1
  percent: 0
---

# Project State

## Project Reference

See `.planning/PROJECT.md` for the core thesis and decisions. Core value remains one real Phoenix application on one physical iPhone with explicit route ownership and one honest offline mutation island. Current focus: v28.0 Truth and Release Train, phases 194–199 ([roadmap](ROADMAP.md), [requirements](REQUIREMENTS.md), [scope](v28.0-SCOPE.md)).

## Current Position

Phase: 194 (Bearings reset and ADR amendments) — EXECUTING
Plan: 2 of 9
Status: Ready to execute
Last activity: 2026-10-24 — Phase 194 execution started

Progress: [░░░░░░░░░░] 0%

## Exact Next Action

What was checked: the v28.0 requirements (30), the approved six-phase structure in the research synthesis, and coverage (30/30 mapped, no orphans). What happened: the v28.0 roadmap was written with phases 194–199. Nothing was committed, merged, released or tagged. What is unknown: nothing that blocks the next step. Phases 196 and 198 need `--research-phase` when planned.

Last completed phase: 193 (v27.0). Active phase: 194, context gathered, not planned. Nothing was pushed, merged, released or tagged.

Next command: `$gsd-plan-phase 194 --ws quality-ratchet-release` (research skipped per ROADMAP).

The earlier handoff history is in git (this file at commit `a9bee5c0`); Phase 194 (PLAN-03) does the full STATE trim. Carried debt is in [the v27.0 debt disposition](milestones/v27.0-closeout/debt-disposition.md). The adopter lane stays parked on its external gate.

## Accumulated Context

### Roadmap Evolution

- Phase 194 discussed (2026-10-24): PLAN-02 and SC1 extended with the AGENTS.md trim already approved in v28.0-SCOPE (decision 6); requirement count unchanged at 30.

- v28.0 roadmap created (2026-10-24): phases 194–199 follow the user-approved six-phase structure in the v28 research synthesis unchanged; 30/30 requirements mapped, no orphans. Research flags on 196 and 198.

- v27.0 shipped and archived (2026-10-24): phases 189–193, 18/18 requirements; workstream ROADMAP collapsed to milestone lines.

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

The six v23 archive acknowledgements retain their original statuses and byte-identical originals in `milestones/v23.0-closeout/original-artifacts`. No new acknowledgement or phase override was added at the v24, v25, v26 or v27 closeouts.

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

**Last session:** 2026-10-25T02:31:32.124Z
**Stopped at:** Completed 194-01-PLAN.md
**Resume file:** None
