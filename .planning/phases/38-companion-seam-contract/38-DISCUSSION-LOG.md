# Phase 38: Companion Seam Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 38-Companion Seam Contract
**Areas discussed:** Companion discovery & config, Callback contract types, Telemetry surface, Phase-38 proof + commerce link
**Mode:** advisor (calibration tier `minimal_decisive`; 4 parallel research agents, sonnet)

---

## Companion discovery & config

| Option | Description | Selected |
|--------|-------------|----------|
| Registry list + `compile_env` | `config :crosswake, companions: […]`; doctor iterates via `Application.compile_env`; `enabled?/1` gets host config map | ✓ |
| Auto-discovery by namespace | doctor scans `Crosswake.Companions.*` modules | |

**User's choice:** Locked the registry-list recommendation (not surfaced as a separate question — auto-selected per `minimal_decisive` profile; presented as locked-unless-objected, no objection).
**Notes:** Auto-discovery fails because `Application.spec/2` only sees modules compiled into `:crosswake`, not the host's `:my_app` impl modules. Matches Oban/Swoosh/Mailer. Fail-closed via `Report.status` derivation.

---

## Callback contract types

| Option | Description | Selected |
|--------|-------------|----------|
| Typed-struct contracts mirroring `Commerce.Contracts` | `Companion.State` struct + closed atom vocabularies + `route_gated?/2 :: {:deny, Finding.t()} \| :pass` | ✓ |
| Plain maps from `report_state/0` / `route_gated?/2` | untyped | |

**User's choice:** Locked the typed-struct recommendation (auto-selected per profile). All referenced module names (`RouteEntry`, `Compatibility.Target`, `Compatibility.Finding`) verified to exist before locking.
**Notes:** Phase-boundary correction applied — `route_gated?/2` + `kill_switch_active?/1` are *defined* in Phase 38 but their RouteGate wiring is Phase 40. One sub-choice (RouteGate iterates companions vs config-declared patterns) flagged open for Phase 39/40.

---

## Telemetry surface (first in repo)

| Option | Description | Selected |
|--------|-------------|----------|
| 3 spans (`validate_dependency`, `route_gate`, `kill_switch`) + direct dep + sync | static names, `companion_id`/`route_id` metadata | ✓ |
| 1 span (`route_gate` only) | minimal surface | |
| async/opt-in emit | wrap in `Task.start` | rejected |

**User's choice:** Locked the 3-span + direct-dep + synchronous recommendation (auto-selected per profile).
**Notes:** Phase-boundary correction — only the `:validate_dependency` span is emittable in Phase 38 (doctor-time) and that satisfies SC#4; `:route_gate`/`:kill_switch` are specified now, emitted Phase 40. Async rejected (corrupts span duration semantics; no-handler overhead is one ETS lookup).

---

## Phase-38 proof + commerce link

| Option | Description | Selected |
|--------|-------------|----------|
| Test-support fixture + documented convention | fixture in `test/support/` proves SC#1/2/4; SC#3 convention documented, realized when rulestead ships (Phase 42) | ✓ |
| Ship `lib/` stub companion | permanent `Crosswake.Companions.Stub` in the hex package | |
| Stub in `lib/`, hidden from docs | `@moduledoc false` + excluded from ex_doc | |

**User's choice:** Test-support fixture (the one decision explicitly surfaced as a question — it touches new public-API surface on a shipped hex lib, meeting the user's escalation bar). Commerce-untouched half locked without a question.
**Notes:** Avoids shipping dead code in the published tarball; matches honest/minimal-surface house style. SC#3's "verifiable by namespace of a shipped companion" honestly realized at Phase 42. Commerce stays an untouched parallel seam — retrofit cost is high (6 unrelated no-op callbacks on a hex-0.1.0-locked module) for zero behavioral gain.

---

## Claude's Discretion
- Exact `Application.get_env` lookup producing the `enabled?/1` config map.
- Whether `RouteGate` iterates companions vs config-declared gated patterns (Phase 39/40).
- Fixture companion module name + `test/support/` file location.
- Doctor finding message/hint copy, `check:` string form, telemetry handler-attach idiom.
- Default `gate_status`/`kill_switch_status` for the Phase-38 fixture (likely `:unconfigured`).

## Deferred Ideas
- Retrofitting `Crosswake.Commerce` onto the companion behaviour (rejected, D-12).
- Real/stub companion at `lib/crosswake/companions/` → Phase 42 (rulestead).
- Runtime gate/kill wiring, `gated_by` DSL, gating doctor category, gate-state matrix column → Phases 39/40/41.
- `:route_gate`/`:kill_switch` telemetry emit sites → Phase 40.
- `mix crosswake.gen.companion`, separate-package extraction, `crosswake_openfeature` → v3.6+.
