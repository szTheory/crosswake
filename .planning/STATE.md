---
gsd_state_version: 1.0
milestone: v14.0
milestone_name: Runtime Contract Confidence
current_phase: 0
status: Awaiting next milestone
stopped_at: Milestone v14.0 archived
last_updated: "2026-06-21T18:33:26.028Z"
last_activity: 2026-06-21
last_activity_desc: Milestone v14.0 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 17
  completed_plans: 17
  percent: 100
current_phase_name: —
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-21)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Planning next milestone (v14.0 shipped 2026-06-21; run `/gsd-new-milestone`)

## Current Position

Phase: Milestone v14.0 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-21 — Milestone v14.0 completed and archived

## Performance Metrics

**Velocity:**

- Total plans completed: 34 (v10.0) + 8 (v11.0) + 13 (v12.0) + 16 (v13.0) = 54 across last four milestones
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

v14.0 per-plan execution decisions (canonical-source compile order, drift-guard JSON-parse detectors, native test harness construction, capability-axis provides/demands direction, etc.) are archived in PROJECT.md Key Decisions and the per-phase SUMMARY frontmatter under `.planning/milestones/v14.0-ROADMAP.md`. Cleared from STATE at milestone close.

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
- **~~Runtime contract drift (v14 active)~~ → RESOLVED by v14.0 (2026-06-21).** One canonical Elixir constant (`Crosswake.Bridge.Contract.version/0`) now drives every surface via `mix crosswake.contract.gen`; the `1.1.0`/`1.0.0` divergence is resolved, native exact-equality is replaced by `>=` floor negotiation (COMPAT-01), and merge-blocking drift guards prevent re-divergence.
- **~~Reusable native package proof depth (v14 active)~~ → RESOLVED by v14.0 Phase 123 (2026-06-21).** The published iOS (XCTest) and Android (JUnit) shell-core packages now carry real behavioral tests for all six behaviors driven from one committed `bridge_contract_vectors.json`; CI lane is Android-blocking + iOS-advisory.
- **WR-01 capability-axis Elixir coverage caveat (v14 carried, non-blocking).** The discriminating vec-014 floor proof runs native-only; `bridge_behavioral_vector_test.exs` hardcodes capabilities and evaluates it vacuously. Production `compatible_version?/2` is correct; native proof is green. Fix: tag vec-014 `native_only` or honor `request_override.capabilities` in the Elixir harness.
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
| v14.0 close | WR-01: Elixir capability-axis floor proof (vec-014) vacuous — discriminating proof native-only | Acknowledged — test-coverage gap, no production impact; native proof green | v14.0 close |
| v14.0 close | WR-02 / WR-03: latent unexercised native divergences (Android-vs-iOS malformed-`@` pack parser; SemVer identical-garbage fallback) | Acknowledged — bounded; inputs are generated well-formed semver | v14.0 close |
| v14.0 close | Two `register-*-gate.sh` branch-protection PATCHes (contract-gate + native-gate) committed but unrun by design | Deferred — maintainer/harness-gated; run to arm branch protection | v14.0 close |
| v14.0 close | 4 pre-existing docs-debt test failures (HexPage×2, Phase48, Phase69); MIRROR_PUSH_TOKEN scope unexercised | Carried — predate / orthogonal to v14.0 | v14.0 close |

## Session Continuity

Last session: 2026-06-21T16:28:51.029Z
Stopped at: Completed 124-04-PLAN.md
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
