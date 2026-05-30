---
phase: 38-companion-seam-contract
plan: 01
subsystem: companion
tags: [elixir, behaviour, telemetry, typed-struct, seam-contract]

requires:
  - phase: 37-commerce-archetype-proof (v3.4)
    provides: Crosswake.Commerce behaviour and struct idioms that companion mirrors conceptually

provides:
  - Crosswake.Companion behaviour with 6 locked @callback declarations (D-05, COMP-01)
  - Crosswake.Companion.State typed struct with @enforce_keys + @type t (D-09)
  - {:telemetry, "~> 1.0"} declared as direct runtime dependency in mix.exs (D-11a)
  - @moduledoc establishes lib/crosswake/companions/<name>/ in-tree convention (SC#3)
  - Three telemetry event-name contracts documented: validate_dependency / route_gate / kill_switch (D-11b)

affects:
  - 38-02 (companion seam doctor + test fixture — builds on this behaviour directly)
  - 39-rulestead-gating-seam
  - 40-routegate-wiring
  - 41-kill-switch
  - 42-rulestead-companion

tech-stack:
  added:
    - telemetry ~> 1.0 (direct runtime dep declared; was already transitive at 1.4.2)
  patterns:
    - Pure @behaviour module with no __using__ macro (commerce lineage, D-12)
    - "@enforce_keys + defstruct + @type t" struct idiom (commerce/contracts.ex lineage)
    - details: %{} optional escape field placed last in defstruct (Check struct idiom)
    - Closed return types on callbacks — {:deny, Finding.t()} | :pass, no bare term()
    - Alias block listing all referenced namespaces so compiler catches type drift

key-files:
  created:
    - lib/crosswake/companion.ex
    - lib/crosswake/companion/state.ex
  modified:
    - mix.exs

key-decisions:
  - "Pure @behaviour with no __using__ macro — conceptual lineage from Commerce (D-12), not structural inheritance; keeps the seam thin and understandable"
  - "route_gated?/2 returns {:deny, Finding.t()} | :pass, not boolean — closed type the policy compiler can pattern-match; prevents returning a value that opens an already-denied route (D-06, T-38-03)"
  - "kill_switch_active?/1 takes only Target.t(), not a route — kill switches are route-independent and short-circuit ahead of route_gated?/2 (D-07)"
  - "Telemetry event-name contracts documented now in @moduledoc, emitted in Plan 02 / Phase 40 — the doc locks the metadata shape before any emit site exists (T-38-02)"
  - "{:telemetry, ~> 1.0} declared directly (Ecto/Oban precedent) rather than relying on Phoenix transitive dep — avoids refactor-eviction risk (D-11a)"

patterns-established:
  - "Companion behaviour shape: @moduledoc + alias block + @doc-per-callback + pure @callback declarations, mirroring commerce.ex structure"
  - "State struct shape: @moduledoc false top-level module, @enforce_keys for required fields, details: %{} default last, helper types before @type t"
  - "Telemetry contract documentation-first: event-name triplets documented in @moduledoc before any emit sites exist"

requirements-completed: [COMP-01, COMP-03]

duration: 3min
completed: 2026-05-30
---

# Phase 38 Plan 01: Companion Seam Contract Summary

**`Crosswake.Companion` behaviour (6 locked callbacks D-05) + `Crosswake.Companion.State` typed struct (D-09) + direct `{:telemetry, "~> 1.0"}` dep — pure contract surface, zero logic, zero companion impl, commerce seam untouched (D-12)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-30T01:13:55Z
- **Completed:** 2026-05-30T01:16:57Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `Crosswake.Companion` as a pure behaviour with exactly 6 locked callbacks (D-05): `companion_id/0`, `enabled?/1`, `route_gated?/2`, `kill_switch_active?/1`, `validate_dependency/0`, `report_state/0`. No `use` macro, no `__using__/1` boilerplate — mirrors `Crosswake.Commerce` exactly.
- Created `Crosswake.Companion.State` as a top-level typed struct with `@enforce_keys` enforcing all six D-09 fields, `details: %{}` optional escape field last (matching `Check` struct idiom), and three helper status atom-union types.
- Declared `{:telemetry, "~> 1.0"}` as a direct runtime dep in `mix.exs` (telemetry 1.4.2 was already resolved transitively; this constraint makes it explicit, D-11a).
- `@moduledoc` documents the `lib/crosswake/companions/<name>/` in-tree convention (SC#3) and names all three telemetry event-name contracts (D-11b) before any emit sites exist.
- `mix compile --warnings-as-errors` exits 0; `lib/crosswake/commerce.ex` is byte-for-byte unchanged (D-12).

## Task Commits

1. **Task 1: Create Crosswake.Companion.State typed struct** - `416f780` (feat)
2. **Task 2: Create Crosswake.Companion behaviour with 6 locked callbacks** - `8286f97` (feat)
3. **Task 3: Declare {:telemetry, "~> 1.0"} as direct dependency** - `d3c2a30` (chore)

## Files Created/Modified

- `lib/crosswake/companion/state.ex` — `Crosswake.Companion.State` typed struct; @enforce_keys on 6 D-09 fields; dependency_status / gate_status / kill_switch_status helper types; `details: %{}` default
- `lib/crosswake/companion.ex` — `Crosswake.Companion` behaviour; alias block (State, Finding, Target, RouteEntry); 6 @callback declarations with @doc strings; @moduledoc with in-tree convention + telemetry contracts
- `mix.exs` — added `{:telemetry, "~> 1.0"}` before `{:ex_doc, ...}` in deps/0

## Decisions Made

- Pure @behaviour with no `__using__` macro: conceptual lineage from Commerce (D-12), not structural inheritance; keeps the seam thin and navigable.
- `route_gated?/2` returns `{:deny, Finding.t()} | :pass` (closed type), not a boolean — enables the policy compiler to pattern-match evidence without an escape hatch (D-06, T-38-03).
- `kill_switch_active?/1` takes only `Target.t()` — kill switches are route-independent and short-circuit ahead of `route_gated?/2` (D-07).
- Telemetry event-name contracts documented in @moduledoc before emit sites exist — locks the metadata shape so the Plan 02 emit site cannot leak host config (T-38-02).
- `{:telemetry, "~> 1.0"}` declared directly (Ecto/Oban pattern) rather than relying on Phoenix transitive dep (D-11a).

## Deviations from Plan

None — plan executed exactly as written.

Note: `mix deps.get` was required before the first `mix compile --warnings-as-errors` call because the worktree had not yet fetched deps. This is normal worktree initialization behavior, not a plan deviation.

## Issues Encountered

None. The `use ` grep check in verification produced a false positive (matched documentation prose in the `@moduledoc`), but confirmed no actual `use` directive exists in code lines.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. `@moduledoc` telemetry metadata contracts are restricted to `%{companion_id: atom(), route_id: binary() | nil}` — no host config or secrets documented as span metadata (T-38-02 mitigated by contract documentation here, enforced at emit site in Plan 02).

## Known Stubs

None — this plan ships pure contract surface (behaviour + typed struct + dep declaration). No data flows to UI rendering; no placeholder values.

## Next Phase Readiness

- Plan 02 (38-02) can now: declare `@behaviour Crosswake.Companion`, implement all 6 callbacks in the `StubCompanion` test fixture, wire the `validate_dependency/0` telemetry span in doctor, and write the phase38 hermetic proof test.
- Phases 39/40/41/42 can all build on the locked callback typespecs and State struct without needing to revisit contract shape.
- COMP-01 satisfied: a module declaring `@behaviour Crosswake.Companion` receives compiler prompts for all 6 callbacks with zero extra boilerplate.
- COMP-03 (declaration half) satisfied: `:telemetry` is a direct dep and @moduledoc establishes SC#3 convention + three static event-name contracts.

---
*Phase: 38-companion-seam-contract*
*Completed: 2026-05-30*
