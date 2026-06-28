---
gsd_state_version: 1.0
milestone: v16.0
milestone_name: Companion Extraction & Package-Family Discipline
current_phase: 132
current_phase_name: generalization-proof-rindle-compat-matrix
status: phase_complete
stopped_at: Phase 133 context gathered
last_updated: "2026-06-28T16:28:58.635Z"
last_activity: 2026-06-28
last_activity_desc: Phase 133 planning complete
progress:
  total_phases: 7
  completed_phases: 4
  total_plans: 14
  completed_plans: 14
  percent: 57
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-25)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 132 COMPLETE — verification passed; Phase 135 (PROOF-03 CI-ops) implemented + landed on local main (v16.0 WIP), syncs to origin at milestone boundary

## Current Position

Phase: 132 (generalization-proof-rindle-compat-matrix) — COMPLETE (verification passed 2026-06-26)
Plan: 4 of 4
Status: Phase verified. Residual CI-ops items (release-as removal, post-publish proof confirmation) transferred to Phase 135 (PROOF-03), implemented + landed on local main 2026-06-26 (v16.0 WIP). Next: plan 133/134; v16.0 (incl. Phase 135) syncs to origin in one catch-up PR at the milestone boundary (#28/#30 pattern).
Last activity: 2026-06-28 — Phase 133 planning complete

> **Planning gate override (Phases 130 & 131, re-surface at verify-phase):** The blocking
> `decision-coverage-plan` gate returned a false-negative — the known parser limitation on
> long-bold / embedded-colon `**D-NN: …**` CONTEXT bullets, which it silently drops as
> "unparseable decision bullet" and then matches 0/N.
> - Phase 130: `total: 24, covered: 0`; checker Dimension 7 PASS, all 33 decisions D-01..D-33 cited.
> - Phase 131 (2026-06-26): `covered: 0/13`; the independent gsd-plan-checker verified Dimension 7
>   (Context Compliance) PASS with all 20 locked decisions D-01..D-20 explicitly cited across the
>   3 plans, and a `grep` cross-check confirms D-01..D-20 all referenced. No real coverage gap —
>   the gate is a tooling false-positive, not a dropped decision.

Progress: [██████████] 100%

```
[          ] 0%
Phase 129 ──────────────────────────────────────────────── Phase 134
```

## Performance Metrics

**Velocity:**

- Total plans completed: 48 (v10.0) + 8 (v11.0) + 13 (v12.0) + 16 (v13.0) + 17 (v14.0) + 12 (v15.0) = 109 across last six milestones
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Roadmap Evolution

- Phase 135 added (2026-06-26): CI-Ops Hardening — Release-As Automation (PROOF-03). Shifts the two post-publish companion-release follow-ups (one-shot `release-as` removal, clean-room-proof confirmation) left to fail-closed CI — parametric across all `crosswake_*` companions, no recurring human step. Implemented + landed on local main 2026-06-26 (v16.0 WIP; syncs to origin at the milestone boundary). Origin: the Phase 132 verify-work challenge — both items were timing-gated (CI-only/post-publish), not human-judgment gates.

### v16.0 Roadmap Decisions (2026-06-25, locked)

- Six phases derived from requirement categories in the approved plan order: SEAM (129) → EXTRACT-mechanics (130) → EXTRACT-publish/PROOF rulestead (131) → EXTRACT-rindle/COMPAT (132) → TELEM (133) → LIFE (134).
- Phase ordering is non-negotiable for the extraction chain: 129 freezes the contract surface before packages depend on it; 130 dress-rehearsal with path-dep before any irreversible publish; 131 first Hex publish (rulestead); 132 generalization proof (rindle). 133 and 134 depend only on 129 and are placed last so irreversible publishes land on a settled contract.
- Phase 129 surfaces: `lib/crosswake/companion/state.ex`, `lib/crosswake/compatibility/compatibility.ex`, `lib/crosswake/manifest/types.ex`, `mix.exs` docs groups, new `guides/companion_contract.md`. Proof: `test/crosswake/proof/phase129_*` (PR-gating).
- Phase 130: no Hex publish — dress rehearsal with `path:` dep only. Removes `MIX_INCLUDE_*` env hack, creates `packages/crosswake_rulestead/`, adds two merge-blocking guards (static-reference grep guard + `Code.ensure_loaded?` placement guard) and a fail-closed absence test. Proof: `phase130-proof.yml` (PR-gating, in-monorepo).
- Phase 131: first irreversible Hex publish for `crosswake_rulestead`. Independently versioned — NOT in the `linked-versions` lockstep group. Gated by `hex.publish --dry-run` + clean-room CI lane before real publish. Surfaces: `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`, `script/verify_companion_cleanroom.sh`.
- Phase 132: identical recipe on rindle (including owned `Contracts.MediaObject` and `Reconciliation`); no rindle-specific branches in core. Ships `guides/companion_compatibility.md` and a drift test. Proof: `phase132-proof.yml` + reused clean-room lane.
- Phase 133: `Crosswake.Telemetry` is a new public module (`lib/crosswake/telemetry.ex`) + `guides/telemetry.md`. Core never auto-attaches a handler. Bidirectional contract test freezes the declared⇔emitted surface. Independent of 130-132; scheduled last to benefit from settled contract surface.
- Phase 134: generated-shell lifecycle (template-version stamp + `mix crosswake.shell.status` + `gen.shell --diff` + `guides/native_shell_upgrade.md`) + Android JVM UAT promoted to merge-blocking, iOS stays advisory. Independent of 130-133; scheduled last.
- Package name ≠ module name convention: `crosswake_rulestead`/`crosswake_rindle` as Hex package names; `Crosswake.Companions.Rulestead`/`.Rindle` as module namespaces. The sole adopter touch-point (`config :crosswake, :companions, [...]`) is unchanged — extraction is non-breaking.
- `Crosswake.Shell.Denial` stays core-private; companions emit `Compatibility.Finding`, never the final denial envelope.
- Shell upgrade is doc-driven + diff only; `gen.shell --diff` is non-destructive. No auto-overwrite.

### v15.0 Roadmap Decisions (2026-06-21, locked)

- Four phases derived from requirement categories in the maintainer-approved order: DOCKER+PORT (125) → NDEV (126) → LAUNCH (127) → COLL+DOCS (128).
- Phase ordering is non-negotiable: 126 and 127 both depend on 125 (port and backend must be stable before native dev wiring or the launch script can be finalized); Phase 128 depends on 125+126+127 (collateral requires all three runtimes live, docs reference final ports/commands).
- Phase 125 ships `examples/docker-compose.yml`, `examples/phoenix_host/Dockerfile`, `examples/phoenix_host/.dockerignore`, a committed `examples/phoenix_host/.env` (`COMPOSE_PROJECT_NAME=crosswake`, `PORT=4700`), named volumes for deps/_build/node_modules and SQLite, a polling reloader in the dev config, and `docs/PORT-REGISTRY.md`; it also moves the default demo port from 4002 → 4700 across config/scripts/playwright.config.ts.
- Phase 126 is strictly additive: iOS Dev scheme + `Info-Dev.plist` + `Fixtures/route_activation-dev.json` for iOS; Android `dev` product flavor + `res/xml/network_security_config_dev.xml` + `src/dev/assets/*` + a non-autoVerify dev intent-filter for Android. The checked-in public-coordinate proof fixtures and assets MUST NOT be modified.
- Phase 127 ships `bin/see-it-run.sh` and a `Makefile` target; the optional `lib/mix/tasks/crosswake.demo.ex` task is a thin alias. The DRY ASCII banner module is brand-voiced and includes an honest "what's proven / what needs a native build" block. Advisory native boot is present-but-not-required (prints clear guidance when toolchain absent).
- Phase 128 reuses `script/capture-native-collateral.mjs` and `examples/phoenix_host/e2e/route_tour.spec.ts` for screenshots; captures a short screen recording; writes `guides/see_it_run.md` (gameplan-at-top, JTBD-driven, links rather than duplicates QUICK_START); updates `mix.exs` ExDoc groups + README + `examples/QUICK_START.md`; and adds `test/crosswake/guides/see_it_run_test.exs`.
- Hermetic-vs-advisory split applies: Docker/web proof can be deterministic (merge-blocking); iOS simulator and Android emulator collateral stays advisory (cannot be deterministic across CI environments).
- Support labels: no native overclaim anywhere — simulator/emulator evidence is honestly labeled; doc-contract tests guard ports/routes/commands.
- Proof fixtures and assets in the checked-in iOS/Android example hosts are proof artifacts — additive dev-wiring must never mutate them.

### Decisions

Full decision log in PROJECT.md (Key Decisions).

- [Phase ?]: hexpm/elixir Debian bookworm-slim base (glibc) required for ecto_sqlite3 NIF; Alpine/musl unsafe
- [Phase ?]: Plain unconditional re-seed in entrypoint — seeds.exs is delete_all + insert, inherently idempotent
- [Phase ?]: docker-compose.yml collocated in examples/phoenix_host/ so build: . and .:/app bind-mount align with .dockerignore
- [Phase ?]: INFOPLIST_FILE set inline in target-level Debug-Dev config (not xcconfig) to avoid xcconfig GUI-override precedence
- [Phase ?]: WKAppBoundDomains in Info-Dev.plist contains both example.com and localhost to prevent WebKit silent navigation refusal
- [Phase ?]: NSExceptionDomains key uses hostname localhost not 127.0.0.1 (ATS requires hostname not IP)
- [Phase ?]: prod flavor uses no suffix; no src/prod dir needed
- [Phase ?]: tools:replace on networkSecurityConfig attribute for minimal dev manifest overlay
- [Phase ?]: dev intent-filter omits android:autoVerify entirely to avoid App Links cascade failure on older APIs
- [Phase ?]: Parameter-expansion conditional UNIT_TEST_TASK/CONNECTED_TEST_TASK: examples/ uses prod-flavored tasks; template path uses unflavored tasks
- [Phase ?]: Source-derived port in guard test (committed_port/0 regex) closes 10.0.2.2 coverage gap
- [Phase ?]: Anti-vacuity: synthetic plist-with-NSExceptionDomains and dev-fixture-at-proof-domain cases prove guard assertions non-vacuous
- [Phase ?]: QUICK_START native labels placed within new section body to satisfy native_label_failures 1500-char window for all native host references
- [Phase ?]: bin/see-it-run.sh canonical; mix crosswake.demo is thin alias (D-01)
- [Phase ?]: Two exit codes only: 0=backend+banner, 1=backend boot failure; native never changes exit code (D-17)
- [Phase ?]: Banner in shell (not Elixir): plain-ASCII printf/heredoc, ANSI gated on TTY/NO_COLOR/CI (D-02)
- [Phase ?]: mix crosswake.demo resolved script path via __DIR__ walking three levels up to repo root
- [Phase ?]: Banner scan asserts leading-space home route line to avoid false JAVA_HOME substring match
- [Phase ?]: Anti-vacuity wrong-port case replaces localhost:PORT substring (not bare port) to avoid mutating JAVA_HOME path
- [Phase ?]: async: true for Phase 129 freeze test (read-only)
- [Phase ?]: MapSet.equal? callback freeze catches both additions and removals (D-12)
- [Phase ?]: Mix.Project.config()[:docs][:groups_for_modules] single source of truth for contract module list (D-15)
- [Phase ?]: Companion Contract groups_for_modules uses full module atom list
- [Phase ?]: guide+extras registered in same commit satisfying orphan-guard and empty-group prerequisite (moduledocs promoted in prior commit)
- [Phase ?]: Extension Authors extras group positioned between Truth and Advanced/Companions (D-10 distinct audience JTBD)
- [Phase ?]: Derived @banned_alias_parts from string names to avoid {:__aliases__} nodes in own module definition
- [Phase ?]: AST prune-then-walk is authoritative for EXTRACT-04 placement; belt retained as _belt_matches (not authoritative)
- [Phase ?]: Real-lib EXTRACT-03 assertion deferred to Plan 05 — rulestead.ex stays in lib/ until Plan 04 extracts it
- [Phase ?]: D-20: SC#1 adapter tests moved to companion lane; SC#3a/SC#3b doctor tests stay in core via StubRulesteadAbsentCompanion stub
- [Phase ?]: D-31: flag_source uses Application.get_env(:crosswake, :rulestead_flag_source) at runtime; dedicated key avoids :rulestead config map clash
- [Phase ?]: D-33: engine-present advisory lane via conditional elixirc_paths; fake Rulestead stub in test/engine_present/ compiled only with ENGINE_PRESENT_LANE=1
- [Phase ?]: D-25: script/extract_companion.md is parameterized 12-step extraction recipe proven on rulestead, reusable for rindle (Phase 132)
- [Phase ?]: CROSSWAKE_RELEASE=1 returns Hex dep; unset returns path dep
- [Phase ?]: independent elixir component, not in linked-versions, manifest 0.1.0, release-as 0.1.0 first-cut
- [Phase ?]: dress-rehearsal gate removed, hex_metadata.config dep-presence grep under CROSSWAKE_RELEASE=1
- [Phase ?]: D-07 per-component gate: rulestead_release_created not aggregate releases_created
- [Phase ?]: job-level CROSSWAKE_RELEASE=1 covers all mix steps in publish-hex-rulestead; plain mix test (no --exclude) for hermetic companion lane (D-10/D-13)
- [Phase ?]: Open Question 1 resolved: minimal use Phoenix.Router with no routes suffices for doctor --router (router_module!/1 only calls Code.ensure_loaded?)
- [Phase ?]: PROOF-02: needs:[release-please,publish-hex-rulestead] enforces clean-room runs after publish
- [Phase ?]: D-16: thin YAML delegates all proof logic to verify_companion_cleanroom.sh
- [Phase ?]: D-04 runbook: release-as removal after first Release PR merges, cross-ref Step 12f for rindle
- [Phase ?]: Phase 132 P01: rindle config.exs minimal — Rindle reads :crosswake/:rindle directly, no flag-source mock (unlike rulestead MockFlagSource)
- [Phase ?]: Phase 132 P01: crosswake_rindle CHANGELOG is a clean [Unreleased] skeleton, not core-inherited rulestead history — fresh 0.1.0 companion
- [Phase ?]: Phase 132 P03: rindle companion lane is engine-PRESENT (rulestead phase42 D-20 analog) not engine-absent; ~> 0.1 admits <1.0.0 so resolves real rindle 0.3.1; engine-absent seam coverage in core via StubRindleAbsentCompanion
- [Phase ?]: Phase 132 P03: media helpers in test/support/example_host/ are require_file-only (excluded from elixirc_paths) avoiding double-load; phase72 hermeticity self-scan asserts require_file basenames
- [Phase ?]: Phase 132 P03: phase72-proof.yml retired (standalone macOS); proof now runs in rindle companion lane via phase132-proof.yml on ubuntu-latest
- [Phase ?]: 132-02 compat-matrix drift test keys the requirement assertion on the pinned Requires-crosswake column (HTML-comment contract, D-12), exact-matching that cell only; a whole-row contains check false-passed because the Engine Dependency cell carries its own ~> 0.1 literal.
- [Phase ?]: Phase 132 P04: crosswake_rindle wired into release-please as a separate elixir component (release-as 0.1.0 one-shot), NOT in linked-versions lockstep — independent versioning (EXTRACT-07, D-01)
- [Phase ?]: Phase 132 P04: rindle_release_created/tag_name/version output aliases + gated publish-hex-rindle (CROSSWAKE_RELEASE=1, dry-run then publish) + clean-room-proof-rindle (needs publish) delegating to verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle
- [Phase ?]: Phase 132 P04: rindle Contracts.media_state_vocabulary/0 canary appended inside SMOKEEOF heredoc guarded by PACKAGE==crosswake_rindle (D-18); no new script param. Removed pre-existing stray MIX_VERSION echo from rulestead clean-room run (Rule 1)

### Pending Todos

- None.

### Resolved In Current Phase

*(populated during execution)*

### Blockers/Concerns

- **WR-01 capability-axis Elixir coverage caveat (v14 carried, non-blocking).** The discriminating vec-014 floor proof runs native-only; `bridge_behavioral_vector_test.exs` hardcodes capabilities and evaluates it vacuously. Production `compatible_version?/2` is correct; native proof is green. Fix: tag vec-014 `native_only` or honor `request_override.capabilities` in the Elixir harness.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** Token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch).** Two `register-*-gate.sh` scripts from v14.0 are committed but unrun — maintainer must run to arm branch protection. Applies to any new required CI gates added in v15.0/v16.0.
- **Irreversible Hex publish risk (Phase 131/132).** Package names `crosswake_rulestead` and `crosswake_rindle` cannot be reclaimed once published. Phase 130 dress-rehearsal with `path:` dep and Phase 131 `--dry-run` gate front-load this risk before any real publish.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v15.0 close | COLL-01 native screenshot binaries (iOS sim, Android emulator, montage) | Advisory-deferred — non-proof advisory native evidence; capture automation shipped but CI Android-emulator-on-macOS hangs and local capture is blocked by the Xcode-26-vs-published-package wall; standing D-03/D-19 maintainer gate. Web route-proof PNGs + COLL-02 GIF are committed. | v15.0 close |
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred until after companion extraction (crosswake_dashboard, after telemetry contract ships in Phase 133) | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred until after companion extraction | v8.0 close |
| v11.0 close | Quick task `tighten-validation-ledger-closeout-gate` (= LEDG-01 / DEBT-01) | Resolved — Phase 115 | v11.0 close |
| v11.0 close | Phase 110 `110-HUMAN-UAT.md` audit flag | Resolved — status `passed`, 0 pending scenarios (false positive) | v11.0 close |
| v11.0 close | Phase 110 `110-VERIFICATION.md` [human_needed] | Acknowledged — the human items were the 4 deferred UAT checks, all passed when 0.1.2 shipped live | v11.0 close |
| v12.0 Phase 112 | TODO-001: pre-existing phoenix_host test failures (FlashcardsTest drift + flaky RegistryNotificationOpenTest) | Resolved — Phase 116 / Plan 01 targeted tests pass | Phase 112 surfaced |
| v14.0 close | WR-01: Elixir capability-axis floor proof (vec-014) vacuous — discriminating proof native-only | Acknowledged — test-coverage gap, no production impact; native proof green | v14.0 close |
| v14.0 close | WR-02 / WR-03: latent unexercised native divergences (Android-vs-iOS malformed-`@` pack parser; SemVer identical-garbage fallback) | Acknowledged — bounded; inputs are generated well-formed semver | v14.0 close |
| v14.0 close | Two `register-*-gate.sh` branch-protection PATCHes (contract-gate + native-gate) committed but unrun by design | Deferred — maintainer/harness-gated; run to arm branch protection | v14.0 close |
| v14.0 close | 4 pre-existing docs-debt test failures (HexPage×2, Phase48, Phase69); MIRROR_PUSH_TOKEN scope unexercised | Carried — predate / orthogonal to v14.0 | v14.0 close |
| v16.0 future | Remaining companion extraction: sigra (most entangled), chimeway (depends on sigra AuthContext), threadline (consumes other companions — build last) | Deferred — fast follow-on once the pattern is proven on 2 companions (rulestead + rindle) | v16.0 scope |
| v16.0 future | SYNCP-01: offline-sync productization (reusable idempotent replay helpers; likely a `crosswake_sync` package) | Deferred behind companion packaging wedge | v16.0 scope |
| v16.0 future | SEED-002: Native capability breadth (scanner/QR, biometrics, location) + Phoenix-first commerce paywall/subscription seam | Deferred until package-family pattern is proven | v16.0 scope |
| Phase 132 plan | Decision-coverage gate (13a) override: reported 0/10 — KNOWN parser false-negative on multi-line `**D-NN: … — …**` bold/embedded-colon CONTEXT bullets. Cross-checked GREEN: plan-checker Dimension 7 PASS (all 19 D-01..D-19 addressed) + plans literally cite D-01..D-19. Substance covered; gate artifact only. | Proceeded with override — verify-phase to re-confirm | Phase 132 plan |
| Phase 129 P01 | 1m | 1 tasks | 1 files |
| Phase 129 P02 | 15m | - tasks | - files |
| Phase 129 P02 | 15m | - tasks | - files |
| Phase 130 P01 | 28m | 3 tasks | 7 files |
| Phase 130 P02 | 45min | 2 tasks | 9 files |
| Phase 130 P03 | 8min | 2 tasks | 2 files |
| Phase 130 P04 | 60 | 3 tasks | 11 files |
| Phase 130 P05 | 5min | 2 tasks | 2 files |
| Phase 131 P01 | 6m | 3 tasks | 6 files |
| Phase 131 P02 | 10m | 2 tasks | 2 files |
| Phase 131 P03 | 5m | 2 tasks | 2 files |
| Phase 132 P01 | 12m | 2 tasks | 10 files |
| Phase 132 P03 | ~16m | 3 tasks | 27 files |
| Phase 132 P02 | ~14m | 2 tasks | 2 files |
| Phase 132 P04 | ~9m | 3 tasks | 4 files |

## Session Continuity

Last session: 2026-06-28T01:24:43.920Z
Stopped at: Phase 133 context gathered
Resume file: .planning/phases/133-telemetry-public-api/133-CONTEXT.md

## Operator Next Steps

- Plan Phase 129 with `/gsd-plan-phase 129`
