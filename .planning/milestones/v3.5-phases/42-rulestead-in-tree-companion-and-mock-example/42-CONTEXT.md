# Phase 42: Rulestead In-Tree Companion And Mock Example - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the first concrete companion implementation at `lib/crosswake/companions/rulestead/`
that satisfies the `Crosswake.Companion` behaviour, and add a gated route in
`examples/phoenix_host` with a pure-Elixir mock flag source (named Agent) that can be
mutated at runtime to drive the route through all three gate states (`gated`,
`rolling_out`, `killed`).

**Satisfies:** COMP-01, COMP-02, COMP-03, GATE-01, GATE-02, GATE-03, GATE-04, GATE-05
(via exercise — all GATE requirements already satisfied in prior phases, Phase 42
exercises them with a real companion rather than fixture modules)

**In scope:**
- `Crosswake.Companions.Rulestead` module at `lib/crosswake/companions/rulestead.ex`
  (or `lib/crosswake/companions/rulestead/rulestead.ex`) satisfying `Crosswake.Companion`
  with `companion_id: :rulestead`; reads gate state from `MockFlagSource` Agent
- `Crosswake.Companions.Rulestead.MockFlagSource` at
  `lib/crosswake/companions/rulestead/mock_flag_source.ex` — named Agent storing
  `%{flag_atom => :gated | {:rolling_out, pct} | :killed}`
- `examples/phoenix_host`: one gated route under `/gating` scope with `gated_by: :my_flag`
  and `on_unavailable: :deny`; phoenix_host app starts MockFlagSource; local dev drives
  states by calling `MockFlagSource.set_flag/2`
- SC#3 doctor coverage: enabling rulestead companion with `Rulestead` absent → `:error`;
  with mock configured → clean output
- Hermetic proof: `test/crosswake/proof/phase42_rulestead_companion_test.exs` (SC#1–SC#3)

**Out of scope:**
- Real `Rulestead.Snapshot` adapter (Phase 43 advisory lane)
- Companion-supplied `reason` / `variant` strings — still `"DISABLED"` / `"off"` (Phase 40 D-05/D-06)
- `{:fallback_phoenix}` route posture demonstration (this phase uses `:deny` only)
- Hermetic CI lane without rulestead dep (Phase 43 — PROOF-01)
- `guides/companions.md` rulestead section (Phase 43)
- `kill_switch_status` richer typespec (deferred from Phase 41)

</domain>

<decisions>
## Implementation Decisions

### ① Mock flag source model — LOCKED
- **D-01:** `Crosswake.Companions.Rulestead.MockFlagSource` is a named Agent process
  (or GenServer). It stores a map of `%{flag_atom => gate_state}` where
  `gate_state :: :gated | {:rolling_out, non_neg_integer()} | :killed`.
- **D-02:** The companion reads gate state via `MockFlagSource.get_flag(flag_key)` and
  maps the stored value to `route_gated?/2` / `kill_switch_active?/1` return values:
  - `:gated` → `route_gated?` returns `{:deny, finding}`; `kill_switch_active?` returns `false`
  - `{:rolling_out, pct}` → same as `:gated` for Phase 42 (deny path); `gate_status: {:rolling_out, pct}` in `report_state/0`
  - `:killed` → `kill_switch_active?` returns `true`; `route_gated?` is never reached (short-circuit)
  - `nil` / unknown flag → `:pass` from `route_gated?`, `false` from `kill_switch_active?`
- **D-03:** MockFlagSource exposes at minimum `start_link/0`, `set_flag(flag_key, gate_state)`,
  and `get_flag(flag_key) :: gate_state | nil`. Planner may add `reset/0` for test cleanup.
- **D-04:** Mock-only for Phase 42. The real `Rulestead.Snapshot` adapter (for the advisory
  lane with the actual library present) is deferred to Phase 43.

### ② Mock flag source location — LOCKED
- **D-05:** MockFlagSource lives in `lib/crosswake/companions/rulestead/mock_flag_source.ex`
  (`Crosswake.Companions.Rulestead.MockFlagSource`) — distributed with the library, not
  example-only. This allows any host app to start it in tests without duplicating code.
- **D-06:** The phoenix_host Application starts MockFlagSource (or a dev/test helper does).
  Local dev state changes are made by calling `MockFlagSource.set_flag/2` (e.g., in IEx or
  a dev seeds module).

### ③ Phoenix_host route design — LOCKED
- **D-07:** One gated route under a new `/gating` scope: single path (planner picks, e.g.
  `/gating/beta-feature`), `gated_by: :my_flag`, `on_unavailable: :deny`.
  All three gate states are demonstrated by mutating the MockFlagSource Agent state, not
  by having three separate routes.
- **D-08:** `on_unavailable: :deny` (`:halt` transition). The `{:fallback_phoenix}` posture
  demonstration is deferred to a future phase or docs.
- **D-09:** The new scope is `/gating` — a sibling to the existing `/commerce` and `/study`
  scopes in the phoenix_host router. Pipeline and LiveView setup follows the existing example
  patterns (planner discretion on exact scaffold).

### ④ validate_dependency/0 check — LOCKED
- **D-10:** `validate_dependency/0` checks `Code.ensure_loaded?(Rulestead)` only —
  the top-level `Rulestead` module as the root of the rulestead Hex package. Returns `:ok`
  if present, `{:error, [Rulestead]}` if absent. Follows the Swoosh-style missing-module
  list pattern established in Phase 38.

### Claude's Discretion
- Exact module layout within `lib/crosswake/companions/rulestead/` — single file vs.
  directory with `rulestead.ex` + `mock_flag_source.ex`. Follow `lib/crosswake/companions/`
  naming convention (none exist yet, so planner establishes it).
- Whether MockFlagSource uses `Agent` or a bare `GenServer`. Agent is simpler; GenServer
  if the planner sees a need for cast-based async mutation.
- Exact scaffold for the `/gating/beta-feature` LiveView or controller in phoenix_host
  (what it renders, what it's called). Planner picks a minimal illustrative name.
- Proof test structure for SC#1–SC#3: follow prior proof test conventions
  (`async: false`, `Application.put_env` with `on_exit` cleanup, inline fixture or real
  companion module, untagged so `phase34-proof.yml` picks it up automatically).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 42" — goal, success criteria SC#1–SC#3
- `.planning/REQUIREMENTS.md` §COMP and §GATE — all COMP/GATE requirements now satisfied;
  read for traceability and constraint context

### Companion behaviour contract (what this phase implements)
- `lib/crosswake/companion.ex` — `Crosswake.Companion` behaviour: 6 callbacks, telemetry
  event name contracts, companion dispatch pattern
- `lib/crosswake/companion/state.ex` — `Crosswake.Companion.State.t()` including
  `gate_status :: :active | :inactive | :unconfigured | {:rolling_out, non_neg_integer()}`
  extended in Phase 41

### RouteGate pipeline (what the companion plugs into)
- `lib/crosswake/compatibility/route_gate.ex` — `prepend_gate_evaluation_findings/3`,
  companion dispatch loop, `transition_for/2`; companion must satisfy the existing
  `route_gated?/2` / `kill_switch_active?/1` contract without changing RouteGate

### Doctor wiring (SC#3)
- `lib/crosswake/doctor/doctor.ex` — `phase_38_companion_seam_findings/0` (validate_dependency
  pattern); `phase_41_gating_findings/1` (gated route doctor pattern); the rulestead
  companion hooks into these existing checks by being registered in
  `Application.get_env(:crosswake, :companions, [])`

### Phoenix_host example
- `examples/phoenix_host/lib/crosswake_example/router.ex` — existing scope/pipeline
  structure; new `/gating` scope added here
- `examples/phoenix_host/mix.exs` — no rulestead dep added in Phase 42 (mock-only)

### Prior phase context
- `.planning/phases/41-gating-doctor-and-support-matrix-truth/41-CONTEXT.md` —
  D-06 (`gate_status` typespec), D-08 (gate-state display mapping), doctor finding codes
- `.planning/phases/40-runtime-gate-evaluation-and-fail-closed-denial/40-CONTEXT.md` —
  D-05 (`"DISABLED"` reason stays in Phase 42), D-09/D-10 (companion dispatch strategy,
  first-deny-wins short-circuit), D-13 (fixture companion pattern for proof tests)
- `.planning/phases/38-companion-seam-contract/38-CONTEXT.md` —
  validate_dependency pattern (D-08 Swoosh-style), telemetry span convention, in-tree
  directory convention

### Proof test patterns
- `test/crosswake/proof/phase38_companion_contract_test.exs` — `Application.put_env`
  fixture companion, `async: false`, `on_exit` cleanup
- `test/crosswake/proof/phase40_gate_evaluation_test.exs` — inline fixture companion,
  `route_gated?/2` returning `{:deny, finding}`, kill-switch short-circuit assertion
- `test/crosswake/proof/phase41_gating_doctor_test.exs` — inline fixture companions
  with distinct gate states for `gating_truth/0` assertions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Companion.State.t()` — the companion's `report_state/0` returns this struct;
  `gate_status: :active` for `:gated`, `gate_status: {:rolling_out, n}` for rolling out,
  `kill_switch_status: :active` for `:killed`
- Phase 38/40/41 fixture companions — inline test module pattern to follow for the
  Phase 42 proof; real companion (`Crosswake.Companions.Rulestead`) can be registered
  in proof tests directly instead of an inline fixture
- `Doctor.phase_38_companion_seam_findings/0` — reads companions from
  `Application.get_env(:crosswake, :companions, [])`, calls `validate_dependency/0`
  with telemetry span; rulestead companion hooks in automatically when registered
- `RouteGate.prepend_gate_evaluation_findings/3` — already wired; rulestead companion
  needs only to satisfy the callback contract, no changes to RouteGate itself

### Established Patterns
- Companions registered at runtime via `Application.get_env(:crosswake, :companions, [])`
  — no compile-time registry
- `validate_dependency/0` → `:ok | {:error, [module()]}` using `Code.ensure_loaded?/1`
- `async: false` with `Application.put_env(:crosswake, :companions, [...])` + `on_exit`
  cleanup in all companion proof tests (global Application state)
- Proof test files untagged (no `@moduletag`), picked up by `phase34-proof.yml` automatically
- `companion_id()` returns an atom (`companion.companion_id()` is the discriminant)

### Integration Points
- `lib/crosswake/companions/rulestead/` — new directory; no existing companion directories
  (rulestead establishes the convention for rindle and sigra)
- `examples/phoenix_host/lib/crosswake_example/application.ex` — likely needs to start
  `MockFlagSource` in the supervisor tree (or via a dev-only start call)
- `examples/phoenix_host/config/config.exs` (or `dev.exs`) — register
  `Crosswake.Companions.Rulestead` in `:crosswake, :companions` for local dev

</code_context>

<specifics>
## Specific Ideas

- The `MockFlagSource.get_flag(:my_flag)` → gate state mapping mirrors how Phase 40
  fixture companions used pattern matching on `route.gated_by` — the rulestead companion
  does the same check (`route.gated_by == companion_id` or matches any flag the companion
  handles) but reads the answer from the Agent instead of hardcoding it.
- `set_flag(:my_flag, :gated)` is the developer-facing API for local dev state driving —
  simple atom API, not a struct. Same simplicity as `Application.put_env` in tests but
  runtime-mutable.
- The companion's `report_state/0` must map stored gate state to `Companion.State.gate_status`
  correctly (D-06 of Phase 41): `:gated` → `gate_status: :active`, `{:rolling_out, n}` →
  `gate_status: {:rolling_out, n}`, `:killed` → `kill_switch_status: :active` (with
  `gate_status: :inactive` or `:unconfigured` — planner decides the most coherent pairing).

</specifics>

<deferred>
## Deferred Ideas

- **Real Rulestead.Snapshot adapter** — Phase 43. When the advisory proof lane runs with
  the real `rulestead` library present, the companion needs an adapter that reads from
  `Rulestead.Snapshot` instead of MockFlagSource. Deferred entirely from Phase 42.
- **`{:fallback_phoenix}` route posture in phoenix_host** — future docs or phase. Phase 42
  uses `:deny` only; the redirect posture demonstration was scoped out.
- **`kill_switch_status` richer typespec** — deferred from Phase 41; still deferred.
- **Multiple companion gate-state rows in support matrix** — deferred from Phase 41;
  rulestead is the first real companion so this may surface in Phase 42's support matrix
  output, but the display logic for conflicting multi-companion states is still deferred.
- **Companion-supplied reason/variant via `finding.subject`** — still deferred (Phase 40
  D-05); Phase 42 uses `"DISABLED"` / `"off"` constants.

</deferred>

---

*Phase: 42-rulestead-in-tree-companion-and-mock-example*
*Context gathered: 2026-05-30*
