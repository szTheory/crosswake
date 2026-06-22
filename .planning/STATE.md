---
gsd_state_version: 1.0
milestone: v15.0
milestone_name: See It Run — Experiential First-Run DX
current_phase: 127
current_phase_name: launch-orchestration-banner
status: executing
stopped_at: Phase 127 context gathered
last_updated: "2026-06-22T18:54:05.638Z"
last_activity: 2026-06-22
last_activity_desc: Phase 127 execution started
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 9
  completed_plans: 8
  percent: 50
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-21)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 127 — launch-orchestration-banner

## Current Position

Phase: 127 (launch-orchestration-banner) — EXECUTING
Plan: 2 of 2
Status: Ready to execute
Last activity: 2026-06-22 -- Phase 127 execution started

```
v15.0 progress: [░░░░░░░░░░░░░░░░░░░░] 0% (0/4 phases)
Phase 125 [░░░░░] Phase 126 [░░░░░] Phase 127 [░░░░░] Phase 128 [░░░░░]
```

## Performance Metrics

**Velocity:**

- Total plans completed: 41 (v10.0) + 8 (v11.0) + 13 (v12.0) + 16 (v13.0) + 17 (v14.0) = 88 across last five milestones
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

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

### Pending Todos

- None.

### Resolved In Current Phase

*(populated during execution)*

### Blockers/Concerns

- **WR-01 capability-axis Elixir coverage caveat (v14 carried, non-blocking).** The discriminating vec-014 floor proof runs native-only; `bridge_behavioral_vector_test.exs` hardcodes capabilities and evaluates it vacuously. Production `compatible_version?/2` is correct; native proof is green. Fix: tag vec-014 `native_only` or honor `request_override.capabilities` in the Elixir harness.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** Token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch).** Two `register-*-gate.sh` scripts from v14.0 are committed but unrun — maintainer must run to arm branch protection. Applies to any new required CI gates added in v15.0.
- **Port migration (Phase 125 execution risk).** Changing the default demo port from 4002 → 4700 touches config, scripts, and playwright.config.ts. The plan must audit all references and ensure `mix phx.server` continues to work with an explicit `PORT=4700` env var, not just Docker.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred until after v15 DX wedge | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred until after v15 DX wedge | v8.0 close |
| v11.0 close | Quick task `tighten-validation-ledger-closeout-gate` (= LEDG-01 / DEBT-01) | Resolved — Phase 115 | v11.0 close |
| v11.0 close | Phase 110 `110-HUMAN-UAT.md` audit flag | Resolved — status `passed`, 0 pending scenarios (false positive) | v11.0 close |
| v11.0 close | Phase 110 `110-VERIFICATION.md` [human_needed] | Acknowledged — the human items were the 4 deferred UAT checks, all passed when 0.1.2 shipped live | v11.0 close |
| v12.0 Phase 112 | TODO-001: pre-existing phoenix_host test failures (FlashcardsTest drift + flaky RegistryNotificationOpenTest) | Resolved — Phase 116 / Plan 01 targeted tests pass | Phase 112 surfaced |
| v14.0 close | WR-01: Elixir capability-axis floor proof (vec-014) vacuous — discriminating proof native-only | Acknowledged — test-coverage gap, no production impact; native proof green | v14.0 close |
| v14.0 close | WR-02 / WR-03: latent unexercised native divergences (Android-vs-iOS malformed-`@` pack parser; SemVer identical-garbage fallback) | Acknowledged — bounded; inputs are generated well-formed semver | v14.0 close |
| v14.0 close | Two `register-*-gate.sh` branch-protection PATCHes (contract-gate + native-gate) committed but unrun by design | Deferred — maintainer/harness-gated; run to arm branch protection | v14.0 close |
| v14.0 close | 4 pre-existing docs-debt test failures (HexPage×2, Phase48, Phase69); MIRROR_PUSH_TOKEN scope unexercised | Carried — predate / orthogonal to v14.0 | v14.0 close |
| v15.0 future | LIFE-01 / LIFE-02: native runtime evidence & generated-shell lifecycle hardening | Deferred behind v15.0 DX wedge | v15.0 scope |
| v15.0 future | SYNCP-01: offline-sync productization | Deferred behind v15.0 DX wedge | v15.0 scope |
| v15.0 future | DASH-01: operator metrics / LiveDashboard | Deferred behind v15.0 DX wedge | v15.0 scope |
| v15.0 future | NTV-01: native disk storage budgets | Deferred behind v15.0 DX wedge | v15.0 scope |
| v15.0 future | Companion package extraction (Sigra/Chimeway/Rindle/Threadline) | Deferred behind v15.0 DX wedge | v15.0 scope |
| Phase 125 P01 | 5m | 3 tasks | 8 files |
| Phase 125 P02 | 4m | 2 tasks | 4 files |
| Phase 126 P01 | 3min | 3 tasks | 4 files |
| Phase 126 P02 | 3min | 3 tasks | 3 files |
| Phase 126 P03 | 8min | 3 tasks | 5 files |
| Phase 126 P04 | 4min | 2 tasks | 2 files |
| Phase 127 P01 | 202 | 3 tasks | 1 files |

## Session Continuity

Last session: 2026-06-22T18:53:53.477Z
Stopped at: Phase 127 context gathered
Resume file: .planning/phases/127-launch-orchestration-banner/127-CONTEXT.md

## Operator Next Steps

- Plan Phase 125 with `/gsd-plan-phase 125`
