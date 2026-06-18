---
gsd_state_version: 1.0
milestone: v12.0
milestone_name: CI Honesty & Real-E2E Sweep
status: executing
stopped_at: Phase 115 planned
last_updated: "2026-06-18T15:12:07.737Z"
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 13
  completed_plans: 10
  percent: 75
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-17)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 115 — closeout-verifier-honesty-ledger-backlog-doc-truth

## Current Position

Phase: 115 (closeout-verifier-honesty-ledger-backlog-doc-truth) — EXECUTING
Plan: 1 of 3
Next: Execute Phase 115 (closeout verifier honesty + ledger backlog + doc truth)
Status: Executing Phase 115

**Progress bar:** Phase 3/4 complete · Plan 10/13 complete

## Performance Metrics

**Velocity:**

- Total plans completed: 21 (v10.0) + 8 (v11.0) + 2 (v12.0 Phase 112) = 23 across last three milestones
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Full decision log in PROJECT.md (Key Decisions). v11.0 milestone decisions archived there.

**v12.0 key decisions (2026-06-17, locked by research):**

- Offline-sync reconnect flush is triggered by `window 'online'` event on the existing socketless `/offline` island — no migration to a LiveView route. The island is socketless by design (`put_root_layout(false)`); migrating would delete the proof the library exists to provide.
- The vestigial `StudySessionLive` `sync_outbox` mock is removed entirely, not relabeled as a manual-sync affordance. Labeling it "Manual Sync" would misrepresent the mechanism (server-side Elixir list, not client IndexedDB outbox) — a fresh dishonesty.
- Phase ordering is fixed: 112 (app change) → 113 (test rewrite + compile gate) → 114 (merge-blocking gate + permanent guard). Phase 115 (closeout/ledger/doc track) is independent and parallelizable but must complete before milestone close. Within Phase 115: GATE-02 must precede DEBT-01.
- `setOffline(false)` does NOT fire the browser `online` event — the test must explicitly `dispatchEvent(new Event('online'))` after calling `setOffline(false)` to trigger the app's reconnect handler.

**v11.0 key decision (2026-06-14):** Two-phase split enforced by dependency graph — Phase 110 (publish + lockstep) must complete before Phase 111 (rewire + prove + release). You cannot clean-room-prove an unpublished dep; you must not cut Hex while gen.shell emits broken coordinates. This ordering is non-negotiable per research.

- [Phase ?]: D-03 confirmed
- [Phase ?]: Rule 1: Study.sync_events struct serialization
- [Phase ?]: D-04: MIX_ENV=test mandatory in offline-sync-e2e-gate.yml compile gate; catches elixirc_paths(:test) + _e2e route (the v6.0 break path)
- [Phase ?]: Job name e2e-offline-sync preserved in offline-sync-e2e-gate.yml; Phase 114 GATE-01 owns rename to merge-blocking-offline-sync-e2e to avoid dropping it from branch-protection required-checks
- [Phase ?]: Option-C aggregator topology selected (merge-blocking-offline-sync-e2e as sole required check, re-actors/alls-green)
- [Phase ?]: Env-scoped cache keys (build-test-* / build-prod-*) + rm -rf _build/prod isolate MIX_ENV compiles (T-114-02 mitigation)
- [Phase ?]: GUARD-01: typescript resolved via createRequire from examples/phoenix_host; guard-01 CI job must run npm ci --prefix examples/phoenix_host before honesty check
- [Phase ?]: Direct controller invocation (no ConnCase) for GUARD-02 count-scoping test — lowest footprint, exercises real show/2
- [Phase ?]: Mix.env() gate unchanged in router.ex — compile-time-out strictly stronger than runtime guard (D-09)
- [Phase ?]: Plan 114-05: GATE-01 registration script reads live state
- [Phase ?]: Plan 114-05: register-e2e-gate.sh refuses to register until aggregator goes green on main
- [Phase ?]: Plan 114-05: GATE-01 registration uses minimal-footprint PATCH endpoint

### Pending Todos

- **TODO-001** (`.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md`): Pre-existing `FlashcardsTest` field-name drift + flaky `Chimeway.RegistryNotificationOpenTest` surfaced by Phase 112's `elixirc_paths` fix. Out of scope for Phase 112; candidate for Phase 115 (DEBT-01) or standalone cleanup.

### Blockers/Concerns

- **~~Distribution gap (FOUNDATIONAL)~~ → RESOLVED by v11.0 (2026-06-17).** The v5.0 standalone-package thesis is now actually distributed: `crosswake 0.1.2` is live on Hex, Maven Central (`io.github.sztheory:crosswake-shell-core-android`), and the SwiftPM mirror (`szTheory/crosswake-shell-core-ios` `v0.1.2`); `gen.shell` emits resolvable, version-matched coordinates, proven by a clean-room CI lane and guarded by the `generator_coordinate_parity` check.
- **Doc drift (watch, ongoing):** Closeout/parity verifiers that hardcode the mid-flight milestone break post-archival — derive from frontmatter + search archived paths. `MILESTONE-ARC.md` reconciled 2026-06-14.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** The splitsh-lite 404 failed before the iOS push step, so the 0.1.2 mirror was completed out-of-band via `git subtree split`. The token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch, Phase 114).** Registering `merge-blocking-offline-sync-e2e` as a required status check requires a `gh api ... PATCH`. Historical constraint: this has been harness-blocked in this environment (human step). Phase 114 ships the scripted/documented path; if toggle fails CI, the `script/register-e2e-gate.sh` carries the exact command. Must run green on `main` at least once before registration.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred to post-v12.0 | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred to post-v12.0 | v8.0 close |
| v11.0 close | Quick task `tighten-validation-ledger-closeout-gate` (= LEDG-01 / DEBT-01) | Active — Phase 115 | v11.0 close |
| v11.0 close | Phase 110 `110-HUMAN-UAT.md` audit flag | Resolved — status `passed`, 0 pending scenarios (false positive) | v11.0 close |
| v11.0 close | Phase 110 `110-VERIFICATION.md` [human_needed] | Acknowledged — the human items were the 4 deferred UAT checks, all passed when 0.1.2 shipped live | v11.0 close |
| v12.0 Phase 112 | TODO-001: pre-existing phoenix_host test failures (FlashcardsTest drift + flaky RegistryNotificationOpenTest) | Open — candidate for Phase 115 | Phase 112 surfaced |
| Phase 113 P02 | 14min | 1 tasks | 2 files |
| Phase 113 P03 | 1min | 1 tasks | 1 files |
| Phase 114 P01 | 5 | 2 tasks | 1 files |
| Phase 114 P02 | 5 | 2 tasks | 4 files |
| Phase 114 P03 | 142 | 3 tasks | 3 files |
| Phase 114 P04 | 7 | 3 tasks | 15 files |
| Phase 114 P05 | 2 minutes | 2 tasks | 2 files |

## Session Continuity

Last session: 2026-06-18T14:20:26.041Z
Stopped at: Phase 115 planned
Resume file: .planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-01-PLAN.md

## Operator Next Steps

- Execute Phase 115 with `/gsd:execute-phase 115`.
- Wave 1: `115-01-PLAN.md` (GATE-02 verifier hardening).
- Wave 2: `115-02-PLAN.md` (DEBT-01 ledger/exception cleanup) and `115-03-PLAN.md` (DOC-01 doc truth), both after 115-01.
