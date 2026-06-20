---
gsd_state_version: 1.0
milestone: v14.0
milestone_name: Runtime Contract Confidence
status: verifying
stopped_at: Completed 123-03-PLAN.md
last_updated: "2026-06-20T20:37:25.111Z"
last_activity: 2026-06-20
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 11
  completed_plans: 11
  percent: 75
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-20)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 123 — native-package-behavioral-proof

## Current Position

Phase: 123 (native-package-behavioral-proof) — EXECUTING
Plan: 4 of 4
Status: Phase complete — ready for verification
Last activity: 2026-06-20

```
Progress: [██████████] 100%
```

## Performance Metrics

**Velocity:**

- Total plans completed: 24 (v10.0) + 8 (v11.0) + 13 (v12.0) + 16 (v13.0) = 54 across last four milestones
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Full decision log in PROJECT.md (Key Decisions). v13.0 milestone decisions archived there.

**v14.0 roadmap decisions (2026-06-20, locked by research + PITFALLS.md):**

- Four phases derived from requirement categories in the mandatory order: CANON (121) → GUARD (122) → NTEST (123) → COMPAT (124). Phase ordering is non-negotiable per registry immutability + lockstep release constraints.
- Phase 123 (NTEST) depends on Phase 121 (canonical source must exist before vectors can be generated), but can proceed in parallel with Phase 122 (drift guards) in execution if the canonical source is stable. For planning purposes, treat 123 as depending on 121 only; guards and native proof are orthogonal once the canonical source exists.
- COMPAT-01 (native `>=` floor negotiation) touches native source and must come after NTEST so the compatibility check change can be exercised by the behavioral tests already in place. Phase 124 therefore depends on Phase 123.
- Drift guards (Phase 122) use parse-based JSON comparison, not text grep, per PITFALLS.md Cluster 3 / Pitfall 3.1. Guards must emit actionable failure messages naming the diverging pair and the fix command (PITFALLS.md Pitfall 3.3).
- Native tests in Phase 123 must parametrize from `bridge_contract_vectors.json` generated from the canonical source — no hardcoded version literals — to avoid the "vacuous / fabricated proof" pattern documented in PITFALLS.md Pitfall 3.5 and the v6.0/v8.0 history.
- Kotlin JUnit CI lane is merge-blocking (JVM only); Swift XCTest CI lane is advisory (macOS environment sensitivity) — consistent with the project's hermetic-vs-advisory split pattern.
- Branch-protection registration for new CI guards follows the v12.0 script + document pattern: ship a registration script, note the human/harness-gated PATCH step, do not auto-toggle.
- Public docs updates belong in Phase 124 (last), not Phase 121. Documentation claims must be coextensive with passing CI (PITFALLS.md Pitfall 5.4, v13.0 DRIFT-02 lesson).
- Any native package publish, if required, comes only after all four phases are green on main (PITFALLS.md Pitfall 2.4, v11.0 fire-drill lesson).

**v12.0 key decisions (2026-06-17, locked by research):**

- Offline-sync reconnect flush is triggered by `window 'online'` event on the existing socketless `/offline` island — no migration to a LiveView route. The island is socketless by design (`put_root_layout(false)`); migrating would delete the proof the library exists to provide.
- The vestigial `StudySessionLive` `sync_outbox` mock is removed entirely, not relabeled as a manual-sync affordance. Labeling it "Manual Sync" would misrepresent the mechanism (server-side Elixir list, not client IndexedDB outbox) — a fresh dishonesty.
- Phase ordering is fixed: 112 (app change) → 113 (test rewrite + compile gate) → 114 (merge-blocking gate + permanent guard). Phase 115 (closeout/ledger/doc track) is independent and parallelizable but must complete before milestone close. Within Phase 115: GATE-02 must precede DEBT-01.
- `setOffline(false)` does NOT fire the browser `online` event — the test must explicitly `dispatchEvent(new Event('online'))` after calling `setOffline(false)` to trigger the app's reconnect handler.

**v11.0 key decision (2026-06-14):** Two-phase split enforced by dependency graph — Phase 110 (publish + lockstep) must complete before Phase 111 (rewire + prove + release). You cannot clean-room-prove an unpublished dep; you must not cut Hex while gen.shell emits broken coordinates. This ordering is non-negotiable per research.

**Next-step assessment decision (2026-06-19):**

- Crosswake is roughly **86% done** for its intended scope: strong and credible, with meaningful production-confidence wedges remaining before diminishing returns dominate.
- The recommended next milestone is **v14.0 Runtime Contract Confidence**, not new feature breadth. Post-v13 repo inspection found bridge protocol truth split between `Crosswake.Bridge.Contract` at `1.1.0` and manifest/example/native proof paths still using `1.0.0`.
- The next milestone should make bridge/runtime contract truth canonical across Elixir, manifest compatibility, generated templates, shell fixtures, route-tour proof, checked-in examples, reusable native packages, support matrix, and docs.
- Reusable iOS/Android shell-core package behavior needs stronger direct tests; checked-in host integration proof is useful but should not be the main proof for package-level activation and bridge behavior.
- Follow-on wedges should be ordered after runtime contract confidence: native runtime evidence/generated-shell lifecycle, offline sync productization, operator metrics/dashboard, then provider commerce or notification/auth re-entry.

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
- [Phase ?]: Fully-qualified call to Contract.version() in types.ex avoids compile cycle
- [Phase ?]: 121-01: Test assertions use Contract.version() not literal '1.1.0' to stay drift-proof against future bridge version bumps
- [Phase ?]: 121-01: Deliberate deny test fixtures retain bridge_protocol_version '1.0.0' — route_findings pipeline order (bridge step 4, pack step 6) ensures pack denial surfaces as primary via List.first
- [Phase 121]: 121-03: Replace ?: "1.0.0" silent default with kotlin error() at ActivationCoordinator.kt:594; ShellManifest.nativeRuntimeVersion stays non-nullable String (CANON-05 / D-08)
- [Phase ?]: 121-02: Sorted-pairs-to-map for deterministic JSON; write_if_changed for idempotent writes; docs/_contract_snippet.md path; seed vector IDs vec-001/002/003
- [Phase ?]: GUARD-01 reads compatibility[bridge_protocol_version] from manifests via Jason.decode; two compare helpers keep failure categories distinct
- [Phase ?]: GUARD-03: manifest path resolution
- [Phase ?]: merge-blocking-contract-drift aggregator with green-first registration script
- [Phase ?]: git add -A + git diff --cached --exit-code catches newly-emitted untracked generated files (T-122-07 mitigation)
- [Phase ?]: cloned from register-e2e-gate.sh; OLD_CHECK empty (append-only PATCH); green-first preflight exits 2 until aggregator green on main; maintainer-run/harness-blocked
- [Phase 123]: 123-03: org.json:json:20231013 added as testImplementation — Android android.jar stubs org.json.JSONObject; real library required for BridgeChannel reply-building in JVM unit tests
- [Phase 123]: 123-03: PackStore.inMemory() seeded with FAILED-state inventory record to avoid SharedPreferences Android context dependency in activation required-pack test
- [Phase ?]: Session/request capabilities decoupled in BridgeConformanceTests: request uses fixed baseline so vec-007 capability-version mismatch fires correctly
- [Phase ?]: StubAppInfoDelegate held as strong local var in iOS tests: CrosswakeShellConfig holds weak delegate references (ARC safety)
- [Phase ?]: ActivationConformanceTests @MainActor: PackStore.init and ActivationCoordinator.init are @MainActor-isolated; class annotation enables synchronous construction

### Pending Todos

- None.

### Resolved In Current Phase

- **TODO-001** (`.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md`): Resolved by Phase 116 / Plan 01 with targeted repairs to Flashcards schema-aligned tests and Chimeway registry notification-open fixture isolation. Verified with `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs test/crosswake_example/chimeway/registry_notification_open_test.exs`.
- **Phase 116 / Plan 02**: Public release truth reconciled to `crosswake 0.1.2`; README, CHANGELOG, guides, example metadata, and three example manifests no longer present stale current-release or standalone-shell deferral claims.
- **Phase 116 / Plan 03**: DRIFT-01 resolved with `test/crosswake/guides/release_boundaries_test.exs` scanning public docs and example manifests for stale release truth. Verified with `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs`.
- **Phase 117 / Plan 01**: GUIDE-01 resolved with `guides/route_policy.md`, route-owner examples, and `test/crosswake/guides/route_policy_test.exs`.
- **Phase 117 / Plan 02**: MIGRATE-01 resolved with `guides/web_to_mobile_migration.md` and `test/crosswake/guides/web_to_mobile_migration_test.exs`.
- **Phase 117 / Plan 03**: TRUTH-01 resolved with renderer-owned support-truth labels, README/install/user-flow navigation, ExDoc groups, and release-boundary guide assertions.
- **Phase 118 / Plan 01**: QUICK-01 resolved with Phoenix host setup/reset aliases, a working `/` smoke page, a walkthrough-first `examples/QUICK_START.md`, and command-verified offline, bounded-bridge, and native-skipped proof lanes.
- **Phase 118 / Plan 02**: ADOPT-01 resolved with `guides/adoption.md` teaching the app-owned IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, replay outcomes, and bridge non-authority.
- **Phase 118 / Plan 03**: DRIFT-02 resolved with `test/crosswake/guides/quick_start_adoption_drift_test.exs` scanning source-derived quick-start/adoption truth and synthetic stale-command/offline-authority regressions.
- **Phase 119 / Plan 01**: Checked-in iOS and Android hosts now default to published coordinates and label themselves as checked-in public-coordinate proof.
- **Phase 119 / Plan 02**: Public native docs, generated templates, and the canonical support matrix now share one evidence-label vocabulary.
- **Phase 119 / Plan 03**: Native evidence drift is guarded by `test/crosswake/guides/native_evidence_drift_test.exs` with source-derived rules and synthetic regressions.

### Blockers/Concerns

- **~~Distribution gap (FOUNDATIONAL)~~ → RESOLVED by v11.0 (2026-06-17).** The v5.0 standalone-package thesis is now actually distributed: `crosswake 0.1.2` is live on Hex, Maven Central (`io.github.sztheory:crosswake-shell-core-android`), and the SwiftPM mirror (`szTheory/crosswake-shell-core-ios` `v0.1.2`); `gen.shell` emits resolvable, version-matched coordinates, proven by a clean-room CI lane and guarded by the `generator_coordinate_parity` check.
- **Doc drift (watch, ongoing):** Closeout/parity verifiers that hardcode the mid-flight milestone break post-archival — derive from frontmatter + search archived paths. `MILESTONE-ARC.md` reconciled 2026-06-14.
- **~~Adopter proof-path drift (v13 active)~~ → RESOLVED by Phase 118 (2026-06-19).** The quick start and adoption guide now use command-verified paths, current offline proof truth, and a DRIFT-02 docs-contract guard.
- **~~Collateral gap (v13 active)~~ → RESOLVED by Phase 120 (2026-06-19).** Browser route-tour evidence, bounded manifests, advisory native collateral capture, and troubleshooting shipped; live native simulator/emulator quality remains advisory and environment-dependent.
- **Runtime contract drift (v14 active — Phase 121):** `Crosswake.Bridge.Contract` defaults to `1.1.0`, while manifest compatibility, example bridge payloads, route-tour proof, and native proof paths still commonly use `1.0.0`. Native bridge code requires exact version equality, so this can deny otherwise valid bounded-bridge requests until one canonical source drives all surfaces.
- **Reusable native package proof depth (v14 active — Phase 123):** Published iOS/Android shell-core packages exist, but package-level behavioral tests are thin compared with checked-in host integration proof. Move or duplicate activation and bridge behavior proof into the packages before widening native claims.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** The splitsh-lite 404 failed before the iOS push step, so the 0.1.2 mirror was completed out-of-band via `git subtree split`. The token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch, Phase 122).** Registering new contract-version drift checks as required status checks requires a `gh api ... PATCH`. Historical constraint: this has been harness-blocked in this environment (human step). Phase 122 ships the scripted/documented path matching the v12.0 pattern.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred until after v14 runtime contract confidence | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred until after v14 runtime contract confidence | v8.0 close |
| v11.0 close | Quick task `tighten-validation-ledger-closeout-gate` (= LEDG-01 / DEBT-01) | Resolved — Phase 115 | v11.0 close |
| v11.0 close | Phase 110 `110-HUMAN-UAT.md` audit flag | Resolved — status `passed`, 0 pending scenarios (false positive) | v11.0 close |
| v11.0 close | Phase 110 `110-VERIFICATION.md` [human_needed] | Acknowledged — the human items were the 4 deferred UAT checks, all passed when 0.1.2 shipped live | v11.0 close |
| v12.0 Phase 112 | TODO-001: pre-existing phoenix_host test failures (FlashcardsTest drift + flaky RegistryNotificationOpenTest) | Resolved — Phase 116 / Plan 01 targeted tests pass | Phase 112 surfaced |
| Phase 121 P01 | 1007 | 3 tasks | 8 files |
| Phase 121 P02 | 4m | - tasks | - files |
| Phase 121 P04 | 3m | 3 tasks | 4 files |
| Phase 122 P01 | 3m | 2 tasks | 1 files |
| Phase 122 P02 | 14m | 2 tasks | 4 files |
| Phase 122 P03 | 2m | 2 tasks | 2 files |
| Phase 123 P01 | 5m 20s | 3 tasks | 6 files |
| Phase 123 P02 | 4m 30s | 3 tasks | 4 files |
| Phase 123 P03 | 8m 4s | 2 tasks | 3 files |

## Session Continuity

Last session: 2026-06-20T20:37:25.107Z
Stopped at: Completed 123-03-PLAN.md
Resume file: None

## Operator Next Steps

- Run `/gsd-plan-phase 121` to plan Phase 121: Canonical Contract Source
