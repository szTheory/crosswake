# Roadmap: Quality Ratchet & Release

## Milestones

- 🚧 **v25.0 iOS Host Setup & Digital Twin Proof** — phases 179–182; approved 2026-10-13; all four phases complete 2026-10-15 (20/20 requirements); milestone audit found one integration gap (twin source binding), [audit](../../v25.0-MILESTONE-AUDIT.md); gap-closure Phase 183 added and completed 2026-10-15 (twin-04 passed against the committed fix); re-audit next.
- **v24.0 Repository Cleanup & Maintenance** — phases 176–178; planning closeout complete 2026-10-12; 8/8 requirements, 15 plans, 28 tasks; six retained debt records. [Archive](milestones/v24.0-ROADMAP.md).
- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## Overview

v25.0 removes hand patches from iOS host generation, then proves one bounded generated-app reference study flow through visible island interaction, verified native media, durable local work, normal Phoenix replay and independent backend effects. The exact [T01–T10 scenario roster](../../research/v25/SUMMARY.md) supplies the demonstration boundary. Browser and contract evidence retain their own observation owners; simulator proof does not promote a physical-iPhone or First B2C Adopter claim.

## Phases

- [x] **Phase 179: iOS Host Setup Without Hand Patches** - Maintainers can configure, generate, check and repair one supported iOS host without editing managed native outputs. (completed 2026-10-13)
- [x] **Phase 180: Bounded Digital Twin Demonstration** - Maintainers can run and inspect one source-bound reference flow with complete, privacy-safe virtual observations.
- [x] **Phase 181: Core Host-Command Seam** - Routes can declare host commands that reach the native bridge, and the bounded iOS shell admits offline-island routes, so Phase 180's gate can rerun.
- [x] **Phase 182: Loopback Origin for Local iOS Host** - In an explicit local/dev mode, the generated iOS host can load an `http` loopback origin; production stays HTTPS-only. (completed 2026-10-14)
- [x] **Phase 183: Close gap: twin source binding fails closed on uncommitted code** - The twin receipt's source joins attest the code that ran; rerun once into a new root. (gap closure from the v25.0 audit) (completed 2026-10-15)

## Phase Details

### Phase 179: iOS Host Setup Without Hand Patches

**Goal:** Maintainers can produce and inspect a correctly configured iOS host from one ordinary Phoenix/Mix build declaration while retaining host-owned native edits.
**Depends on:** Nothing (first phase of v25.0; v24.0 planning closeout is complete)
**Requirements:** IOS-01, IOS-02, IOS-03
**Success Criteria:**
  1. Host build configuration supplies the declared route/entry/origin and app/test identity/signing values through the normal Mix environment; generation does not start Phoenix or evaluate unrelated server-runtime credentials.
  2. Generate/regenerate preserves host-owned native files, checks recognized managed resources without writing, and detects invalid inputs, ownership conflicts or incomplete updates with a safe concrete repair action.
  3. Effective Xcode app/proof-test settings show the intended simulator/device modes; configuration files are excluded from bundled resources and physical installation is not claimed.
  4. Canonical host-derived manifest/static activation rejects the example production origin and invalid route/configuration while retaining runtime auth/replay authority and existing dev/local compatibility.

**Plans:** 4/4 complete across four sequential waves; [goal verification passed](phases/179-ios-host-setup-without-hand-patches/179-VERIFICATION.md), IOS-01/02/03 satisfied.
- [x] [179-01-PLAN.md](phases/179-ios-host-setup-without-hand-patches/179-01-PLAN.md) — Compile-only host declaration, canonical resources and first effective shell setting.
- [x] [179-02-PLAN.md](phases/179-ios-host-setup-without-hand-patches/179-02-PLAN.md) — Managed ownership, nonwriting inspection, interrupted recovery and bounded migration.
- [x] [179-03-PLAN.md](phases/179-ios-host-setup-without-hand-patches/179-03-PLAN.md) — Proof target projections and independent effective Xcode matrix.
- [x] [179-04-PLAN.md](phases/179-ios-host-setup-without-hand-patches/179-04-PLAN.md) — Maintainer guides, canonical renderings and existing scoped regression gates.

The supported production path has one build-config authority. Existing local/dev invocation remains compatible; existing edited Xcode projects use an explicit documented migration. Managed-output validation and recovery must account for interrupted multi-output updates rather than claiming a filesystem-wide atomic transaction.

### Phase 180: Bounded Digital Twin Demonstration

**Goal:** Maintainers can verify one generated reference iOS study flow end to end and inspect exactly what its virtual evidence proves.
**Depends on:** Phase 179
**Requirements:** TWIN-01, TWIN-02, TWIN-03, TWIN-04, TWIN-05, TWIN-06
**Success Criteria:**
  1. One documented invocation exercises the actual generated app's visible study WebView and matching typed bridge, with independently matched candidate/dependency/assets/backend identities and isolated owned runtime resources.
  2. The normal offline-island interaction initiates host-native playback from verified installed bytes and persists selected/free-form work through true app termination/relaunch without resetting the persistent store.
  3. Ordinary app replay reaches the real reference backend, duplicates produce one durable Ecto effect, accepted work empties the outbox, and synthetic test authority is explicit.
  4. Controlled backend/media/account/flag faults demonstrate the declared retained-work denial/recovery outcomes; meaningful visible states use necessary accessible controls and truthful copy.
  5. The exact T01–T10 scenario groups and required observations produce safe passing/failing/blocked results, with fabrication/source mismatch negative controls and explicit external/fidelity limits. Missing required virtual observations block completion.

**Plans:** 7 plans across six waves; [context gathered](phases/180-bounded-digital-twin-demonstration/180-CONTEXT.md); complete 2026-10-15. 180-01 and 180-02: the baseline gate reported stop_missing_seam, the user allowed a separate core-seam scope change (Phase 181), and the rerun reported existing_path_supported (not_required). 180-05 waited on the loopback origin (Phase 182). 180-07's third recorded run (twin-03) exited 0 with a passed receipt (49/49 observations); twin-01 and twin-02 are kept. Verification passed 5/5 ([report](phases/180-bounded-digital-twin-demonstration/180-VERIFICATION.md)). TWIN-01..06 complete.
- [x] [180-01-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-01-PLAN.md) — Wave 1: derived candidate plus executable feasibility gate (declaration, projection, native session, offline-island runtime) and closed gate verdict.
- [x] [180-02-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-02-PLAN.md) — Wave 2: user allow/hold scope decision on the missing seam and the bounded handoff.
- [x] [180-03-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-03-PLAN.md) — Wave 3 (gated): twin-only receipt, owned runtime and verify_twin command shell.
- [x] [180-04-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-04-PLAN.md) — Wave 3 (gated): island free-form entry, audio action, truthful copy, recovery destination and test-gated faults.
- [x] [180-05-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-05-PLAN.md) — Wave 4 (gated): prepared generated iOS host, identity-checked WebView, verified installer and audio delegate. Blocked at Task 1: needs the loopback-origin core phase ([record](phases/180-bounded-digital-twin-demonstration/180-05-BLOCKED.md)).
- [x] [180-06-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-06-PLAN.md) — Wave 5 (gated): held-origin fault boundary, six owner producers for all 49 observations, identity freeze, in-run negative controls, XCUITest journey and capture canary.
- [x] [180-07-PLAN.md](phases/180-bounded-digital-twin-demonstration/180-07-PLAN.md) — Wave 6 (gated): single twin run, byte-copied receipt projection, guide section and receipt-backed handoff. Third recorded run twin-03 passed (exit 0, all ten groups and 49 observations passed); twin-01 (blocked, no receipt) and twin-02 (receipt all blocked, process crash) are kept under `.twin-01`/`.twin-02` names.

**UI hint:** yes

The first composition check joins the visible generated WebView to the registered `host.*` audio delegate, installed bytes and target-scoped network denial. The runner owns a fresh database, server, port and app context; the receipt is derived and grants no runtime, replay, support or physical-promotion authority. Required virtual observations must pass for completion. If the existing seam requires a generic core protocol/storage expansion, stop with the requirement incomplete and report the missing seam. Reuse stable contract checks in existing CI leaves; the full simulator demonstration has no new standing CI lane.

### Phase 181: Core Host-Command Seam

**Goal:** A route's own `crosswake:` capabilities declaration of a `host.*` command travels through route policy validation, generated activation capabilities and the native session to the registered host delegate, and the bounded iOS shell admits offline-island routes. This closes the four blockers the Phase 180 feasibility gate confirmed (G1–G4, plus G6).
**Depends on:** Phase 179. Authorized by the user's "allow" in 180-02 ([decision](phases/180-bounded-digital-twin-demonstration/180-DECISION.json)). Phase 180 plans 180-03..180-07 depend on this phase through the seam handoff.
**Requirements:** SEAM-01, SEAM-02, SEAM-03, SEAM-04, SEAM-05, SEAM-06 (added in discussion 2026-10-14; [context](phases/181-core-host-command-seam/181-CONTEXT.md)). It unblocks TWIN-01..06, which Phase 180 still owns.
**Success Criteria:**
  1. Route policy accepts a declared `host.*` command and still rejects undeclared or unknown commands with explicit, fail-closed denials.
  2. Generated activation capabilities come from each declaring route's own declaration for every declaring route, not from a hard-coded probe route.
  3. The native session receives only the declared commands and delivers them to the registered host delegate. Undeclared commands stay denied.
  4. The bounded iOS shell admits offline-island routes, and other non-admitted runtimes stay explicitly denied.
  5. The bridge/activation wire contract is versioned, so existing hosts keep working or fail with an explicit, actionable denial rather than silently.
  6. On completion the phase writes `180-SEAM-HANDOFF.json` (schema `crosswake.phase180.seam_handoff/1`) and renames the 180-01/180-02 summaries to `*-SUMMARY.baseline.md`, as the STATE seam handoff contract specifies.

**Plans:** 10/10 plans executed across ten sequential waves (one shared candidate checkout and git index, so no plan runs in parallel). The pinned Phase 180 gate preflight (181-07) runs right after the Elixir and Swift core plans and before docs and handoff.
- [x] 181-01-PLAN.md
- [x] 181-02-PLAN.md
- [x] 181-03-PLAN.md
- [x] 181-04-PLAN.md
- [x] 181-05-PLAN.md
- [x] 181-06-PLAN.md
- [x] 181-07-PLAN.md
- [x] 181-08-PLAN.md
- [x] 181-09-PLAN.md
- [x] 181-10-PLAN.md
- [x] [181-01-PLAN.md](phases/181-core-host-command-seam/181-01-PLAN.md) — Wave 1: candidate plus router host-command registry (versions limited to the shell-supported 1.x.y range) and fail-closed route-policy validation (SEAM-01).
- [x] [181-02-PLAN.md](phases/181-core-host-command-seam/181-02-PLAN.md) — Wave 2: per-route manifest `host_commands`, entry-only activation projection, declaration-driven matrix with mutation check, example-host fallout (SEAM-02).
- [x] [181-03-PLAN.md](phases/181-core-host-command-seam/181-03-PLAN.md) — Wave 3: manifest schema 1.2.0, conditional seam key, generated Swift seam fixture, schema-pin re-baseline (SEAM-05, SEAM-02).
- [x] [181-04-PLAN.md](phases/181-core-host-command-seam/181-04-PLAN.md) — Wave 4: fail-closed generation shell-package gate, doctor and inspect diagnostics (SEAM-05, SEAM-01).
- [x] [181-05-PLAN.md](phases/181-core-host-command-seam/181-05-PLAN.md) — Wave 5: Swift per-route grant (declared, registered, version in the compiled 1.x.y range), navigation re-resolution, wire decoding, compiled seam constant, named bridge denials (SEAM-03, SEAM-05).
- [x] [181-06-PLAN.md](phases/181-core-host-command-seam/181-06-PLAN.md) — Wave 6: bounded-shell `offline_island` admission as `.offlineIsland` with identical checks (SEAM-04).
- [x] [181-07-PLAN.md](phases/181-core-host-command-seam/181-07-PLAN.md) — Wave 7: pinned Phase 180 gate preflight on the core head, Android byte freeze, full regression (SEAM-06, SEAM-05).
- [x] [181-08-PLAN.md](phases/181-core-host-command-seam/181-08-PLAN.md) — Wave 8: contract snippet, rendered support matrix, CHANGELOG, compatibility and architecture guides (SEAM-05).
- [x] [181-09-PLAN.md](phases/181-core-host-command-seam/181-09-PLAN.md) — Wave 9: host-author, bridge, upgrade and offline guides plus the seam guide truth test (SEAM-05).
- [x] [181-10-PLAN.md](phases/181-core-host-command-seam/181-10-PLAN.md) — Wave 10: final-head preflight, `180-SEAM-HANDOFF.json`, baseline summary renames, TWIN traceability (SEAM-06).

Product work happens only in a temporary candidate repo under `/private/tmp`. The recovery checkout gets no Git mutation. Android stays frozen. No generic sync, storage or native breadth is added.

### Phase 182: Loopback Origin for Local iOS Host

**Goal:** In an explicit local/dev `:ios_host` mode, the iOS host generator can use an `http` loopback origin (`127.0.0.1` or `localhost`) so the Phase 180 twin can load `http://127.0.0.1:4790`. Production origin validation stays HTTPS-only and fails closed.
**Depends on:** Phase 181. Authorized by the user's "Allow loopback" choice when 180-05 was blocked ([decision](phases/180-bounded-digital-twin-demonstration/180-ORIGIN-DECISION.json)). Phase 180 plans 180-05..180-07 depend on this phase.
**Requirements:** LOOP-01, LOOP-02, LOOP-03, LOOP-04, LOOP-05
**Success Criteria:**
  1. Without the explicit `origin_mode: :local_loopback` key in `:ios_host`, origin validation still accepts only `https://` origins and rejects `http` with an explicit, actionable denial. The mode is refused under `MIX_ENV=prod`.
  2. In the local/dev mode, only `http://127.0.0.1` and `http://localhost` origins (with optional port) are accepted. Any other `http` host is rejected.
  3. Generated iOS output for a loopback origin uses ATS `NSAllowsLocalNetworking` (plus a `CrosswakeOriginMode` marker) and never `NSAllowsArbitraryLoads`. Production output is unchanged and gets no ATS exception. An automated Simulator check observes the generated app actually loading a loopback page.
  4. Check, inspect and doctor report the local/dev mode honestly and never present it as production-ready; the physical proof lane refuses it.
  5. On completion the phase records how the Phase 180 candidate `/private/tmp/crosswake-phase180-impl` moves onto its head, keeping the uncommitted 180-03/180-04 work and the three SHA-pinned feasibility gate test files unchanged. 180-05 can then rerun from Task 1.

**Plans:** 6/6 plans complete across six sequential waves ([context](phases/182-loopback-origin-for-local-ios-host/182-CONTEXT.md), [research](phases/182-loopback-origin-for-local-ios-host/182-RESEARCH.md)); verification passed 5/5 ([verification](phases/182-loopback-origin-for-local-ios-host/182-VERIFICATION.md)).
- [x] [182-01-PLAN.md](phases/182-loopback-origin-for-local-ios-host/182-01-PLAN.md) — Wave 1: candidate clone, base production Info.plist golden, `origin_mode: :local_loopback` validator and template branch (LOOP-01, LOOP-02).
- [x] [182-02-PLAN.md](phases/182-loopback-origin-for-local-ios-host/182-02-PLAN.md) — Wave 2: bounded Info.plist block reconcile, `--check`/`--diff` mode drift, D-13 line, README banner (LOOP-03, LOOP-04).
- [x] [182-03-PLAN.md](phases/182-loopback-origin-for-local-ios-host/182-03-PLAN.md) — Wave 3: doctor warning/mismatch error, conditional `--check-publish` refusal, formatter line, leak guard (LOOP-04).
- [x] [182-04-PLAN.md](phases/182-loopback-origin-for-local-ios-host/182-04-PLAN.md) — Wave 4: physical proof-lane refusal, inspect line, renderers and guides (LOOP-04).
- [x] [182-05-PLAN.md](phases/182-loopback-origin-for-local-ios-host/182-05-PLAN.md) — Wave 5: automated Simulator loopback load check with narrowness control, full regression, frozen head (LOOP-03).
- [x] [182-06-PLAN.md](phases/182-loopback-origin-for-local-ios-host/182-06-PLAN.md) — Wave 6: verified move of the Phase 180 candidate onto the 182 head and `182-CANDIDATE-MOVE.json` (LOOP-05).

Product work happens only in a temporary candidate repo under `/private/tmp`. The recovery checkout gets no Git mutation. Android stays frozen. No arbitrary `http` origins, no `NSAllowsArbitraryLoads`, no push, merge, release or PR.

### Phase 183: Close gap: twin source binding fails closed on uncommitted code

**Goal:** The twin receipt's `source` and `installed_build` joins attest the code that actually ran. A twin run against a candidate with uncommitted or untracked changes either fails closed with a named cause or binds a digest of the working tree that ran; the Phase 180 code is placed in the attested candidate tree; and the twin runs once into a new run root (D-16) so the passed receipt matches the delivered source.
**Requirements**: TWIN-01, TWIN-05, TWIN-06 (gap closure; already marked complete, attestation weakened per the [v25.0 audit](../../v25.0-MILESTONE-AUDIT.md))
**Gap Closure:** Closes the v25.0 audit integration blocker (`twin_producers.ex:632-633`, `:797-798` bind only `HEAD` and `HEAD^{tree}`).
**Depends on:** Phase 180, Phase 182
**Plans:** 5/5 plans complete across five sequential waves (one shared candidate checkout and git index, so no plan runs in parallel).

Plans:
- [x] [183-01-PLAN.md](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-01-PLAN.md) — Wave 1: freeze history manifest; commit the 60 Phase 180 paths as seven ordered candidate commits; record test baseline (TWIN-01, TWIN-06).
- [x] [183-02-PLAN.md](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-02-PLAN.md) — Wave 2: clean-tree probe, freeze and mid-run gates, `source_dirty` cause, real-git negative controls (uncommitted) (TWIN-01, TWIN-05).
- [x] [183-03-PLAN.md](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-03-PLAN.md) — Wave 3: run-root containment, plain-language output with typed count, fifth fidelity limit, guide sentence, eight mutation controls, single `fix(183-03)` commit (TWIN-01, TWIN-05, TWIN-06).
- [x] [183-04-PLAN.md](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-04-PLAN.md) — Wave 4: script-generated twin-04 record, superseding identity, preflight and one-shot wrapper (TWIN-01, TWIN-06).
- [x] [183-05-PLAN.md](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-05-PLAN.md) — Wave 5: one run into twin-04 (run inline by one owner), byte-copied result, twin-03 annotation, handoff (TWIN-01, TWIN-05, TWIN-06).

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---|---|---|
| 179. iOS Host Setup Without Hand Patches | v25.0 | 4/4 | Complete    | 2026-10-13 |
| 180. Bounded Digital Twin Demonstration | v25.0 | 7/7 | Complete; twin-03 passed 49/49; verification 5/5 | 2026-10-15 |
| 181. Core Host-Command Seam | v25.0 | 10/10 | Complete; seam handoff written | 2026-10-14 |
| 182. Loopback Origin for Local iOS Host | v25.0 | 6/6 | Complete    | 2026-10-14 |
| 183. Close gap: twin source binding fails closed on uncommitted code | v25.0 | 5/5 | Complete    | 2026-10-15 |

## Exact Next Action

Phase 183 (gap closure) was added on 2026-10-15 and was discussed and planned on 2026-10-15 (5 plans, 5 sequential waves). It closes the one v25.0 audit gap: the twin receipt's source checks bind only the committed tree, and twin-03 ran with the Phase 180 code uncommitted ([audit](../../v25.0-MILESTONE-AUDIT.md)). Decided: fail closed on a dirty or untracked candidate, commit Phase 180 into the candidate, write a fresh prepared record and rerun once into `twin-04` ([context](phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co/183-CONTEXT.md)). Executed 2026-10-15: Phase 180 committed in the candidate as seven commits, the fail-closed guard landed as `fix(183-03)`, and twin-04 ran once against it and passed (exit 0, 49/49, source join at the fix commit). Verification passed 6/6 and Phase 183 is complete. Next: `$gsd-audit-milestone --ws quality-ratchet-release`. Phase 180 completed on 2026-10-15: the third recorded twin run (twin-03) exited 0 with a passed receipt covering all 49 observations, and verification passed 5/5. TWIN-01..06 are complete. The candidate product changes and the guide section are committed only in the `/private/tmp/crosswake-phase180-impl` candidate and need a separately authorized delivery. Details are in STATE.md.

Last completed phase: **180** (bounded digital twin; twin-03 passed). Before it, **182** (loopback origin; LOOP-01..05 complete, details in STATE.md). Before it, Phase 181 built the core host-command seam in the temporary candidate `/private/tmp/crosswake-phase181-impl` (branch `phase181-impl`, head `12f84cd950d4574921767df823faed6797c17c26`). On that final head the pinned Phase 180 gate was run read-only and every gating fact was refuted with its control passing, all four invariants held, and the full regression passed (Android, bridge vectors, example fixtures and lockfiles byte-identical to the base; root 2218 tests, example host 150, Swift 80, host build and both guard scripts green). That preflight is not the authoritative verdict; 180-01's own rerun is. The Phase 180 gate rerun has since reported existing_path_supported, and the twin-03 run then passed, completing all six TWIN requirements. Details are in STATE.md.
