# Phase 130: Extraction Mechanics & Footgun Guards - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 130-Extraction Mechanics & Footgun Guards
**Areas discussed:** Fail-closed locus (COMPAT-01), Guard design & scope (EXTRACT-03/04), Path-dep rehearsal fidelity (EXTRACT-02), Engine-dep & test-support relocation

**Method:** User selected all four gray areas and requested deep research-then-recommend
(two passes, 8 parallel subagents total). Pass 1 established the shape; pass 2 red-teamed
each against the project corpus (`prompts/`, `brandbook/BRAND-SPEC.md`, `guides/companions.md`)
and the operator / companion-author / adopter / contributor JTBD lenses. All load-bearing
facts were verified against the live code before locking. No single-question turns were used —
the user asked for a coherent one-shot recommendation set.

---

## Fail-closed locus (COMPAT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Core-owned in RouteGate | RouteGate consults dependency status first, synthesizes the Denial, denies the route; companions never self-deny | ✓ |
| B — Companion self-deny | Each `route_gated?/2` must self-return `{:deny, Finding}` on missing dep | |
| Hybrid — opt-in `use` wrapper | Core provides a helper companions opt into | |

**User's choice:** A (core-owned), refined in pass 2.
**Notes:** Refinements: drop the pass-1 `:persistent_term` cache → live-compute (avoids doctor↔RouteGate TOCTOU + preserves `put_env` fixtures); keep one shared code string `"companion.dependency_missing"` but add `details.missing_kind` (`:engine_unvalidated` vs `:adapter_unloadable`) for divergent remediation; synthesize the Denial inline (not via `finding_to_denial/2`, not a new Finding axis); add `:dependency_missing` to the closed `@reasons` (verified 12 → 13); fail-closed even on a raise; advisory softening only at doctor severity, never the gate. Planner flag: reconcile with the existing `on_unavailable` route-policy key before designing the change.

## Guard design & scope (EXTRACT-03/04)

| Option | Description | Selected |
|--------|-------------|----------|
| `boundary` library | Compile-time layering enforcement | |
| Bespoke AST proof (stdlib) | `Code.string_to_quoted` + `Macro.prewalk` over `lib/**` | ✓ |
| `mix xref` primary | Compiler-resolved reference graph | partial → dropped |
| Textual grep | Simple string matching | (rejected — false-positives) |
| Source of truth: derive from `crosswake_*` path deps | Auto-arm via mix.exs deps | (rejected — phantom) |
| Source of truth: frozen hardcoded MapSet | Explicit named extracted-set in `CompanionGuard` | ✓ |

**User's choice:** Bespoke AST proof, frozen-MapSet source of truth (refined in pass 2).
**Notes:** Pass 2 dropped `mix xref` entirely (unstable API + "opaque shell soup" inside ExUnit) and corrected the source-of-truth: core has zero `path:` deps and names no companion, so deriving from deps is a phantom — hardcode a frozen MapSet (Rulestead now; Rindle at 132). Scope strictly to the extracted set — Sigra/Chimeway are legitimately referenced in core today (verified 5 aliases) and a blanket ban would brick the build. Disambiguate `Crosswake.Companions.Rulestead` (adapter, EXTRACT-03) from `Rulestead` (engine, EXTRACT-04). EXTRACT-04 = AST prune-then-walk + textual belt. Guard travels with the code (glob `File.cwd!()/lib/**`) so it isn't vacuous after the move. One file, two describe blocks, untagged hermetic lane.

## Path-dep rehearsal fidelity (EXTRACT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| One-way poncho (`{:crosswake, path: "../.."}`) | Companion depends on core; runs its own tests | ✓ |
| Two-way (core test-deps the companion) | Core names the companion in test env | |
| Umbrella app | Single config + lockfile | |

**User's choice:** One-way poncho (refined in pass 2).
**Notes:** Pass 2 fixed an error — `runtime: false` is wrong (core is a runtime dep); use plain `{:crosswake, path: "../.."}`. Critical: TEST SPLIT — SC#1 adapter-behavior tests → companion lane; the COMPAT-01 fail-closed contract test STAYS in core's hermetic lane via the registry/behaviour seam (not an alias to moved source). Delete BOTH `MIX_INCLUDE_*` blocks. `@version "0.1.0"` + marker, don't touch release-please manifest or join the lockstep group. Copy a 3-line `StudySessionLive` stub (no shared package). Dress-rehearsal fidelity = `hex.build --unpack` + `publish --dry-run` + `--warnings-as-errors`, not just "it compiles". Ship a parameterized extraction checklist + verify script; root `mix companions.test` alias to avoid a bare-`cd` DX wart.

## Engine-dep & test-support relocation

| Option | Description | Selected |
|--------|-------------|----------|
| `optional: true` + runtime probe | Swoosh idiom; declare engine optional, probe at runtime | ✓ |
| Pure probe, no dep declared | No installable handle | |
| MockFlagSource as `lib/` runtime default | Ship the mock as the gate source | (rejected — fail-open smell) |
| MockFlagSource → test/support + `FlagSource` behaviour | Full seam now | (rejected — scope creep) |
| MockFlagSource → test/support + `compile_env` indirection | One-symbol config-resolved flag source | ✓ |

**User's choice:** `optional: true` + runtime probe; MockFlagSource → test/support via `compile_env` indirection (revise-by-subtraction in pass 2).
**Notes:** Pass 2 dropped the `FlagSource` behaviour + engine-backed default reader as scope creep (corpus names the engine reader as deferred). Minimum fix: `Application.compile_env(:crosswake, [:rulestead, :flag_source], nil)` keeps `lib/` compiling once the mock moves. `@compile {:no_warn_undefined, Rulestead}` is REQUIRED (optional:true alone doesn't silence the absent-build warning). COMPAT-01 toggles ENGINE presence (adapter present+registered); two dep states without `MIX_INCLUDE` via a conditional `elixirc_paths(:test)` fake `Rulestead` stub, presence decided at runtime (not compile-baked). Fail-closed locus = `validate_dependency/0`, already implemented + documented (`guides/companions.md:31`).

## Claude's Discretion

- Exact ExUnit module/file names, stable-id slug strings, and the `CompanionGuard` helper API.
- `missing_kind` representation (atom vs string at the JSON boundary).
- Final microcopy wording within the brand voice (research drafts provided as starting points).
- Tag-vs-alias mechanism for the advisory engine-present lane.

## Deferred Ideas

- `FlagSource` behaviour + engine-backed runtime reader (later, when the real engine reader lands).
- Hex publish + release-please separate-component wiring (Phase 131).
- rindle extraction via the identical recipe + cross-package compat matrix (Phase 132).
- sigra/chimeway extraction — refactor the legitimate core aliases behind the seam (later milestone).
- `boundary` library for compile-time layering (possible future hardening; rejected this phase).
- ETS read-through cache for the dep check (only if profiling demands; doctor reads the same cache).
