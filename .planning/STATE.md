---
gsd_state_version: 1.0
milestone: v13.0
milestone_name: Adopter Confidence & Native Evidence
status: executing
stopped_at: Completed 118-02-PLAN.md
last_updated: "2026-06-19T15:47:45.142Z"
last_activity: 2026-06-19
progress:
  total_phases: 5
  completed_phases: 2
  total_plans: 9
  completed_plans: 8
  percent: 40
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-19)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 118 — runnable-quick-start-and-real-adoption-proof

## Current Position

Phase: 118 (runnable-quick-start-and-real-adoption-proof) — EXECUTING
Plan: 3 of 3
Status: Ready to execute
Last activity: 2026-06-19

## Performance Metrics

**Velocity:**

- Total plans completed: 13 (v10.0) + 8 (v11.0) + 13 (v12.0) = 31 across last three milestones
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Full decision log in PROJECT.md (Key Decisions). v12.0 milestone decisions archived there.

**v12.0 key decisions (2026-06-17, locked by research):**

- Offline-sync reconnect flush is triggered by `window 'online'` event on the existing socketless `/offline` island — no migration to a LiveView route. The island is socketless by design (`put_root_layout(false)`); migrating would delete the proof the library exists to provide.
- The vestigial `StudySessionLive` `sync_outbox` mock is removed entirely, not relabeled as a manual-sync affordance. Labeling it "Manual Sync" would misrepresent the mechanism (server-side Elixir list, not client IndexedDB outbox) — a fresh dishonesty.
- Phase ordering is fixed: 112 (app change) → 113 (test rewrite + compile gate) → 114 (merge-blocking gate + permanent guard). Phase 115 (closeout/ledger/doc track) is independent and parallelizable but must complete before milestone close. Within Phase 115: GATE-02 must precede DEBT-01.
- `setOffline(false)` does NOT fire the browser `online` event — the test must explicitly `dispatchEvent(new Event('online'))` after calling `setOffline(false)` to trigger the app's reconnect handler.

**v11.0 key decision (2026-06-14):** Two-phase split enforced by dependency graph — Phase 110 (publish + lockstep) must complete before Phase 111 (rewire + prove + release). You cannot clean-room-prove an unpublished dep; you must not cut Hex while gen.shell emits broken coordinates. This ordering is non-negotiable per research.

**Next-step assessment decision (2026-06-18):**

- Crosswake is likely in the **80-89% done** band for intended scope: the route-policy substrate, published install path, diagnostics/support truth, and real offline proof are substantive, but adopter confidence still has meaningful gaps.
- The next milestone should be **v13.0 Adopter Confidence & Native Evidence**, not new capability breadth. Treat `GUIDE-01` as proof-path consolidation: runnable quick start, route-policy guide, troubleshooting/rough edges, web-to-mobile migration, ExDoc cross-linking, simulator/emulator evidence, and screenshot/video collateral.
- `TODO-001` should be first-phase or precondition work. A public proof path should not depend on an example host with known deterministic and flaky local test debt.
- Simulator/device/native evidence is valuable for "seeing is believing" collateral, but remains **advisory** unless a future milestone explicitly promotes it to merge-blocking support truth.

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

- None.

### Resolved In Current Phase

- **TODO-001** (`.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md`): Resolved by Phase 116 / Plan 01 with targeted repairs to Flashcards schema-aligned tests and Chimeway registry notification-open fixture isolation. Verified with `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs test/crosswake_example/chimeway/registry_notification_open_test.exs`.
- **Phase 116 / Plan 02**: Public release truth reconciled to `crosswake 0.1.2`; README, CHANGELOG, guides, example metadata, and three example manifests no longer present stale current-release or standalone-shell deferral claims.
- **Phase 116 / Plan 03**: DRIFT-01 resolved with `test/crosswake/guides/release_boundaries_test.exs` scanning public docs and example manifests for stale release truth. Verified with `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs`.
- **Phase 117 / Plan 01**: GUIDE-01 resolved with `guides/route_policy.md`, route-owner examples, and `test/crosswake/guides/route_policy_test.exs`.
- **Phase 117 / Plan 02**: MIGRATE-01 resolved with `guides/web_to_mobile_migration.md` and `test/crosswake/guides/web_to_mobile_migration_test.exs`.
- **Phase 117 / Plan 03**: TRUTH-01 resolved with renderer-owned support-truth labels, README/install/user-flow navigation, ExDoc groups, and release-boundary guide assertions.

### Blockers/Concerns

- **~~Distribution gap (FOUNDATIONAL)~~ → RESOLVED by v11.0 (2026-06-17).** The v5.0 standalone-package thesis is now actually distributed: `crosswake 0.1.2` is live on Hex, Maven Central (`io.github.sztheory:crosswake-shell-core-android`), and the SwiftPM mirror (`szTheory/crosswake-shell-core-ios` `v0.1.2`); `gen.shell` emits resolvable, version-matched coordinates, proven by a clean-room CI lane and guarded by the `generator_coordinate_parity` check.
- **Doc drift (watch, ongoing):** Closeout/parity verifiers that hardcode the mid-flight milestone break post-archival — derive from frontmatter + search archived paths. `MILESTONE-ARC.md` reconciled 2026-06-14.
- **Adopter proof-path drift (v13 active):** Phase 116 resolved stale release truth, stale quick-start front-door commands, and fictional bridge-owned offline mutation claims in the first-read surfaces it touched. Full command-verified quick-start and adoption rewrite remain Phase 118.
- **Checked-in native host drift (v13 active):** The generator/release path proves published SwiftPM/Maven coordinates, but the checked-in iOS host still uses a local package ref and the checked-in Android host still references old `dev.crosswake:shell-core-android:0.1.0`. Decide whether checked-in hosts should prove published coordinates or be explicitly labeled local-development proof.
- **Collateral gap (v13 active):** No durable adopter screenshots/videos/artifact uploads were found for the native/browser demo paths. Current proof is strong mechanically, but not yet "seeing is believing" for a maintainer or prospective adopter.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** The splitsh-lite 404 failed before the iOS push step, so the 0.1.2 mirror was completed out-of-band via `git subtree split`. The token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch, Phase 114).** Registering `merge-blocking-offline-sync-e2e` as a required status check requires a `gh api ... PATCH`. Historical constraint: this has been harness-blocked in this environment (human step). Phase 114 ships the scripted/documented path; if toggle fails CI, the `script/register-e2e-gate.sh` carries the exact command. Must run green on `main` at least once before registration.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred until after v13 adopter-confidence proof unless required for evidence visibility | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred until after v13 adopter-confidence proof; valuable but narrower and higher-cost than proof-path trust | v8.0 close |
| v11.0 close | Quick task `tighten-validation-ledger-closeout-gate` (= LEDG-01 / DEBT-01) | Resolved — Phase 115 | v11.0 close |
| v11.0 close | Phase 110 `110-HUMAN-UAT.md` audit flag | Resolved — status `passed`, 0 pending scenarios (false positive) | v11.0 close |
| v11.0 close | Phase 110 `110-VERIFICATION.md` [human_needed] | Acknowledged — the human items were the 4 deferred UAT checks, all passed when 0.1.2 shipped live | v11.0 close |
| v12.0 Phase 112 | TODO-001: pre-existing phoenix_host test failures (FlashcardsTest drift + flaky RegistryNotificationOpenTest) | Resolved — Phase 116 / Plan 01 targeted tests pass | Phase 112 surfaced |

## Session Continuity

Last session: 2026-06-19T15:47:45.139Z
Stopped at: Completed 118-02-PLAN.md
Resume file: .planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-03-PLAN.md

## Operator Next Steps

- Start `$gsd-execute-phase 118` for Runnable Quick Start And Real Adoption Proof.
- Execute Wave 1 plans first (`118-01`, `118-02`), then Wave 2 (`118-03`) after the final quick-start/adoption docs text exists.
- Keep Phase 118 scoped to command-verified quick-start/adoption truth and DRIFT-02 guards; native evidence classification remains Phase 119.
