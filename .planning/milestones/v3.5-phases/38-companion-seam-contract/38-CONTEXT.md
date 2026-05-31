# Phase 38: Companion Seam Contract - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Define `Crosswake.Companion` — the shared behaviour that every first-party companion
(rulestead, rindle, sigra) will implement, generalized from the existing `Crosswake.Commerce`
seam. Phase 38 ships **the contract foundation only**: the behaviour + its 6 callbacks, the
typed `Crosswake.Companion.State` struct, optional-dependency fail-closed handling wired into
`mix crosswake.doctor`, the in-tree `lib/crosswake/companions/<name>/` convention (documented),
the host-config companion registry, and the first `[:crosswake, :companion, …]` telemetry span
in the codebase.

**Satisfies:** COMP-01 (behaviour + declared callbacks), COMP-02 (enabled-but-missing fails
closed with a doctor `:error` naming the dependency), COMP-03 (in-tree convention + telemetry).

**In scope:**
- `lib/crosswake/companion.ex` — the `@behaviour` with 6 `@callback`s (typespecs locked below).
- `Crosswake.Companion.State` typed struct (feeds doctor + support matrix).
- Host-config companion registry (`config :crosswake, companions: […]`) + the
  `Application.compile_env`-based discovery doctor uses to iterate companions.
- Doctor wiring: a `phase_38_companion_seam_findings/0` function that runs `validate_dependency/0`
  per registered companion and emits a fail-closed `:error` finding (code
  `"companion.dependency_missing"`) when an enabled companion's optional lib is absent.
- `{:telemetry, "~> 1.0"}` added as a **direct** dep; the `[:crosswake, :companion, :validate_dependency]`
  span emitted for real (satisfies SC#4); the `:route_gate` / `:kill_switch` event names *specified*
  as the documented contract.
- Test-support fixture companion + a hermetic `phase38_companion_contract_test.exs` proving
  SC#1/SC#2/SC#4 (picked up by the existing `phase34-proof.yml` `mix test --exclude requires_example_host` lane).
- Behaviour moduledoc documents the `lib/crosswake/companions/<name>/` convention.

**Out of scope (belongs to later phases — do NOT pull forward):**
- Any edit to `lib/crosswake/commerce.ex` — commerce stays an untouched parallel seam (D-12).
- Runtime wiring of `route_gated?/2` / `kill_switch_active?/1` into `RouteGate.evaluate` (the
  `:gate_denied` / `:kill_switch_active` finding injection + short-circuit) — **Phase 40**.
- The `gated_by` route-policy DSL key + manifest binding — **Phase 39**.
- The doctor *gating* category + runtime gate-state support-matrix column — **Phase 41**.
- A real shipped companion at `lib/crosswake/companions/<name>/` (rulestead) — **Phase 42**.
- Emitting the `:route_gate` / `:kill_switch` telemetry spans (their emit sites need the Phase 40
  RouteGate wiring) — **Phase 40**.
- A new CI workflow file — Phase 38 reuses the existing hermetic lane.

</domain>

<decisions>
## Implementation Decisions

### ① Companion discovery & config (COMP-01, COMP-02 — SC#1/SC#2)
- **D-01:** Host registers companions with a list under the `:crosswake` app:
  `config :crosswake, companions: [MyApp.Rulestead]`. Idiomatic Oban/Swoosh/Mailer pattern; the
  host names the impl module(s) explicitly (no namespace auto-discovery — `Application.spec/2` only
  sees modules compiled into `:crosswake`, not the host's `:my_app` impl modules).
- **D-02:** Core/doctor reads the registry via `Application.compile_env(:crosswake, :companions, [])`
  and iterates. Recompile-to-disable is acceptable (registering a companion is a structural change,
  not a flag flip — the live on/off flip is `enabled?/1` + the Phase 39+ flag value).
- **D-03:** `enabled?/1` receives a host-owned **config `map()`** (arbitrarily shaped; the companion
  module narrows it internally — FunWithFlags-style). It is a host-level toggle, NOT a per-route
  question (per-route restriction is `route_gated?/2`). Exact env-key lookup that produces this map
  is planner discretion (mirror how existing core code reads host config).
- **D-04 (fail-closed contract, COMP-02):** When `enabled?/1 == true` **and**
  `validate_dependency/0 == {:error, mods}`, doctor emits a `Crosswake.Doctor.Check` with
  `severity: :error`, `code: "companion.dependency_missing"`, a message naming the missing
  module(s), and `details: %{missing_modules: mods}`. Silent fail-open is structurally impossible:
  `Report.status` already derives from `Enum.any?(findings, &(&1.severity == :error))`
  (`doctor.ex` ~line 137). Doctor's companion function mirrors `phase_19_commerce_corridor_posture`.

### ② Callback contract types (COMP-01 — SC#1) — LOCKED typespecs
All referenced module names verified to exist in the codebase.
- **D-05:** The six `@callback`s:
  ```elixir
  @callback companion_id() :: atom()
  @callback enabled?(config :: map()) :: boolean()
  @callback route_gated?(route :: Crosswake.Manifest.Types.RouteEntry.t(),
                         context :: Crosswake.Compatibility.Target.t()) ::
              {:deny, Crosswake.Compatibility.Finding.t()} | :pass
  @callback kill_switch_active?(context :: Crosswake.Compatibility.Target.t()) :: boolean()
  @callback validate_dependency() :: :ok | {:error, [module()]}
  @callback report_state() :: Crosswake.Companion.State.t()
  ```
- **D-06:** `route_gated?/2` returns **evidence the policy compiler consumes** —
  `{:deny, Finding.t()} | :pass`, NOT a boolean. The `Finding` carries a companion-namespaced
  `:axis` (e.g. `:gate_denied`, `:kill_switch_active`). `:pass` (not `nil`) keeps the return closed.
  Companion can only **further-restrict**, never open a route policy already denied. (Note: the
  module exists and is defined now; its *consumption* by `RouteGate` is Phase 40.)
- **D-07:** `kill_switch_active?/1` takes only `Target.t()` (kill switches are route-independent;
  they short-circuit ahead of `route_gated?/2` — that short-circuit wiring is Phase 40).
- **D-08:** `validate_dependency/0 :: :ok | {:error, [module()]}` — Swoosh-style missing-module list;
  the list holds the module(s) that failed `Code.ensure_loaded?/1`.
- **D-09:** `Crosswake.Companion.State` struct mirrors the `Commerce.Contracts` idiom
  (`@enforce_keys` + `@type t`):
  ```elixir
  @enforce_keys [:companion_id, :enabled, :dependency_status, :gate_status, :kill_switch_status, :checked_at]
  defstruct [..., details: %{}]
  # companion_id :: atom()
  # enabled :: boolean()
  # dependency_status :: :present | {:missing, [module()]}
  # gate_status :: :active | :inactive | :unconfigured
  # kill_switch_status :: :inactive | :active | :unconfigured
  # checked_at :: non_neg_integer()   # monotonic ms at report time
  # details :: map()                  # companion-specific escape hatch (defaults %{})
  ```
  `report_state/0` returns this; doctor maps `dependency_status` → `:error` finding,
  `enabled: false && dependency_status: :present` → `:advisory`. Support matrix consumes the same
  struct for its companion row. (`gate_status` / `kill_switch_status` values are *defined* now;
  routes only start populating them meaningfully in Phase 40/41.)
- **D-10 (planner discretion, flagged open):** Whether `RouteGate` calls `route_gated?/2` once per
  registered companion or companions declare their gated route patterns in config. The behaviour
  above is compatible with either; resolve in Phase 39/40, not Phase 38.

### ③ Telemetry (COMP-03 — SC#4) — first telemetry in the codebase
- **D-11a:** Add `{:telemetry, "~> 1.0"}` as a **direct** dep in `mix.exs`. Library best practice
  (Ecto/Oban/telemetry_metrics all declare it directly); a published lib that emits telemetry must
  not rely on Phoenix's transitive dep (refactor-eviction risk). `:telemetry` 1.4.2 is already in
  `mix.lock` transitively, so this is a constraint declaration, not a new download.
- **D-11b:** Three `:telemetry.span/3` events, **static names**, differentiated by
  `%{companion_id: atom(), route_id: binary() | nil}` metadata (Keathley: never put `companion_id`
  in the event-atom list):
  - `[:crosswake, :companion, :validate_dependency, :start|:stop|:exception]` — **emitted in Phase 38**
    (doctor-time); stop metadata adds `result: :ok | {:error, [module()]}`. This one real span
    satisfies SC#4.
  - `[:crosswake, :companion, :route_gate, :start|:stop|:exception]` — **specified now, emitted Phase 40**;
    stop metadata adds `status: :allow | :deny`.
  - `[:crosswake, :companion, :kill_switch, :start|:stop|:exception]` — **specified now, emitted Phase 40**;
    stop metadata adds `active: boolean()`. Called first (short-circuit), so APM sees two sequential
    spans, not a misleading nested sum.
- **D-11c:** **Synchronous** emit (no `Task.start` wrapper). The async anti-pattern corrupts
  `:telemetry.span/3` duration semantics and hides exceptions; with no handler attached the overhead
  is a single ETS lookup, so the Statsig auto-exposure hot-path footgun does not apply.

### ④ Phase-38 proof surface & commerce relationship (SC#1–SC#4)
- **D-12 (commerce — LOCKED):** **Do NOT touch `lib/crosswake/commerce.ex`.** Its 4 domain-specific
  callbacks (`submit_purchase_intent/1`, `submit_restore_intent/1`, `ingest_reconciliation_evidence/1`,
  `fetch_entitlement_snapshot/1`) have zero overlap with the companion callback set; retrofitting
  `@behaviour Crosswake.Companion` onto it would bolt 6 unrelated no-op callbacks onto a module
  already shipped/locked on hex 0.1.0, for zero behavioral gain. "Generalized FROM commerce" =
  conceptual lineage, not structural inheritance. Companion is a new parallel behaviour.
- **D-13 (proof artifact — USER-CONFIRMED):** Prove the contract with a **test-support fixture
  companion** (e.g. `test/support/<…>_companion.ex`, namespaced under a `CrosswakeTest`/example
  namespace) implementing all 6 callbacks, plus a hermetic `test/crosswake/proof/phase38_companion_contract_test.exs`.
  - SC#1: fixture `@behaviour Crosswake.Companion` compiles satisfying all callbacks with no extra
    boilerplate.
  - SC#2: register the fixture, point its `validate_dependency/0` at a deliberately-absent module,
    assert `mix crosswake.doctor` emits the `:error` finding naming it.
  - SC#4: assert the `:validate_dependency` span emits (attach a handler in the test).
  - **No new CI file** — the test is untagged, so the existing `phase34-proof.yml` hermetic job
    (`mix test --exclude requires_example_host`) picks it up automatically.
- **D-14 (SC#3 — USER-CONFIRMED):** Do **not** ship a permanent no-op companion in `lib/`. Establish
  the `lib/crosswake/companions/<name>/` convention via the **behaviour moduledoc** (and the
  companions guide when it lands). SC#3's "verifiable by inspecting the module namespace of any
  shipped companion" is honestly realized when **rulestead** ships at that path in **Phase 42** —
  keeping the published hex package free of dead code, matching the project's honest/minimal-surface
  house style. Rationale: a permanently-shipped stub is new public-API surface on a shipped lib;
  the fixture proves the same contract without that cost.

### Claude's Discretion
- Exact env-key/`Application.get_env` lookup that produces the `enabled?/1` config map (D-03).
- Whether `RouteGate` iterates companions vs config-declared gated patterns (D-10) — Phase 39/40.
- Fixture companion module name + file location under `test/support/` (mirror existing fixtures:
  `compile_router_case.ex`, `example_host.ex`, `router_fixtures.ex`).
- Doctor finding `message`/`hint` copy, `check:` string form (`"companion.#{companion_id}"`),
  describe/test block naming, telemetry handler-attach idiom in the proof test.
- Whether `report_state/0`'s `gate_status`/`kill_switch_status` default to `:unconfigured` for the
  Phase-38 fixture (likely yes, since no gating wiring exists until Phase 40).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements / Roadmap
- `.planning/REQUIREMENTS.md` — v3.5 requirements; **COMP-01/02/03** for this phase. Also the
  "Out of Scope" exclusions (companion can only further-restrict, never override route ownership;
  no hard dep on OpenFeature `0.x` SDK; hermetic lane must pass with the optional dep absent).
- `.planning/ROADMAP.md` §"Phase 38: Companion Seam Contract" — goal + 4 success criteria; and
  Phases 39/40/41/42 to confirm what is deferred OUT of Phase 38.
- `.planning/research/v3.5-companions-SUMMARY.md` — the locked architecture: behaviour-not-protocol,
  3-layer optional-dep (`optional: true` + compile-time `Code.ensure_loaded?/1` around the **module
  body** not `use` (elixir-lang#8970) + runtime `validate_dependency/0`), `optional: true`
  non-transitivity footgun, Keathley telemetry conventions, in-tree-first packaging.

### The behaviour being generalized + the contract idiom to mirror
- `lib/crosswake/commerce.ex` — the existing 4-callback `@behaviour` Companion generalizes from
  (do NOT modify — D-12).
- `lib/crosswake/commerce/contracts.ex` — the `@enforce_keys` + `@type t` typed-struct idiom and the
  `validate_*/1 :: :ok | {:error, kw}` validator pattern `Companion.State` must mirror (D-09).
- `lib/crosswake/commerce/reconciliation.ex` — `EvidenceResult` struct (status-atom + timestamp
  shape `report_state/0` echoes).

### Types the callbacks reference (verified to exist)
- `lib/crosswake/manifest/types.ex` (line ~192) — `RouteEntry` struct (`route_gated?/2` arg, D-05).
- `lib/crosswake/compatibility/compatibility.ex` — nested `Crosswake.Compatibility.Target` (line ~14)
  and `Crosswake.Compatibility.Finding` (line ~40; struct
  `[:axis, :message, :required, :available, :hint, :route_id, :subject]`) — the `route_gated?/2`
  context arg and `{:deny, Finding.t()}` return (D-05/D-06).
- `lib/crosswake/compatibility/route_gate.ex` — `evaluate/4`, `prepend_commerce_corridor_findings/3`
  short-circuit pattern the Phase 40 gate/kill injection will mirror (read for the contract shape;
  NOT edited in Phase 38).

### Doctor wiring target
- `lib/crosswake/doctor/doctor.ex` — `run/1` (~line 113, monolithic-function pattern); add a
  `phase_38_companion_seam_findings/0` mirroring `phase_19_commerce_corridor_posture`. `Report.status`
  derivation (~line 137) is what makes fail-open structurally impossible (D-04).
- `lib/crosswake/doctor/check.ex` — the `Check` struct (`severity :error|:warning|:advisory`, `code`,
  `message`, `hint`, `check`, `details: map()`) that doctor emits and `report_state/0` feeds.

### Support matrix
- `lib/crosswake/support_matrix/support_matrix.ex` — the pre-declared `:companion` release boundary
  (lines ~375/414); the companion `report_state/0` row consumer.

### Telemetry posture
- `mix.exs` — `deps/0` (jason, nimble_options, phoenix, phoenix_live_view, ex_doc); add
  `{:telemetry, "~> 1.0"}` (D-11a). NOTE: there are currently **zero** `:telemetry` call sites in
  `lib/` — Phase 38 introduces the first.

### Proof lane (reuse, do NOT add a new CI file)
- `.github/workflows/phase34-proof.yml` — the hermetic `merge-blocking-commerce-proof` job runs
  `mix test --exclude requires_example_host`; an untagged `phase38_companion_contract_test.exs` is
  picked up automatically (D-13).
- `test/support/` — existing fixture home (`compile_router_case.ex`, `example_host.ex`,
  `router_fixtures.ex`); the fixture companion lives here.
- `.planning/phases/36-hermetic-proof-lane/36-CONTEXT.md` — the hermetic-lane discipline (pure
  modules only; no network/SDK/device) the Phase 38 proof must honor.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Commerce` + `Commerce.Contracts` — the behaviour + typed-struct template the companion
  behaviour and `Companion.State` copy almost verbatim (4-callback behaviour over `@enforce_keys`
  structs → 6-callback behaviour over `Companion.State`).
- `doctor.ex` `phase_19_commerce_corridor_posture` — the exact private-posture-function shape the new
  `phase_38_companion_seam_findings/0` mirrors (read config/state → map to `Check` findings).
- `Doctor.Check` `details: map()` escape hatch — carries `%{missing_modules: …}` without a new struct.
- `RouteGate.prepend_commerce_corridor_findings/3` — the short-circuit-via-prepend pattern Phase 40
  reuses for kill switches (read-only reference in Phase 38).
- `test/support/*` fixtures + the `phase34-proof.yml` `--exclude requires_example_host` glob — the
  fixture + hermetic-proof mechanism Phase 38 reuses with zero new CI plumbing.

### Established Patterns
- Behaviour-over-typed-contracts (commerce precedent) — NOT a Protocol (a companion is a named
  one-impl-per-host integration, not data-type dispatch).
- Doctor is a single monolithic `run/1` with per-concern private finding functions; `Report.status`
  is `:error` if any finding is `:error` → fail-closed is automatic once the `:error` finding is
  emitted.
- Hermetic merge-blocking proof = untagged ExUnit test, no network/SDK/device, picked up by the
  existing `--exclude requires_example_host` run.

### Integration Points
- `mix.exs` deps (+`:telemetry`).
- `config :crosswake, companions: […]` — new host-config key read by core + doctor.
- `doctor.ex` `run/1` — new companion finding function appended.
- `support_matrix.ex` — companion row fed by `report_state/0` (the `:companion` boundary already
  exists).
- The behaviour's `route_gated?/2` / `kill_switch_active?/1` are DEFINED but NOT yet consumed —
  Phase 40 wires them into `route_gate.ex`.

</code_context>

<specifics>
## Specific Ideas

- ~80% of this architecture is pre-committed by the commerce precedent (per the research summary) —
  this phase is deliberately the low-risk pattern-locking wedge. The planner should lean hard on
  copying the commerce behaviour/contracts shape rather than inventing new structure.
- The single most dangerous outcome to design against is **silent fail-open** when a companion is
  enabled-but-missing. D-04 makes it structurally impossible; the proof test (D-13) asserts the
  absence path explicitly in a hermetic no-dep lane.
- The `optional: true` non-transitivity footgun is a doctor-message concern: when the dep is missing,
  the `:error` finding's `message`/`hint` should tell the host to add the real dep to *their* deps
  (it is not pulled transitively).

</specifics>

<deferred>
## Deferred Ideas

- **Retrofitting `Crosswake.Commerce` onto the companion behaviour** — rejected (D-12); revisit only
  if a future milestone unifies seam abstractions (no current need).
- **Shipping a real/stub companion at `lib/crosswake/companions/`** — deferred to **Phase 42**
  (rulestead) per D-14; Phase 38 documents the convention only.
- **Runtime gate/kill wiring into `RouteGate`, `gated_by` DSL, gating doctor category, gate-state
  support-matrix column** — Phases 39/40/41.
- **`:route_gate` / `:kill_switch` telemetry emit sites** — Phase 40 (names specified now, D-11b).
- **`mix crosswake.gen.companion` generator + separate-package extraction +
  `crosswake_openfeature` companion** — explicitly deferred to v3.6+ (REQUIREMENTS.md Future).

### Reviewed Todos (not folded)
None — `todo.match-phase` surfaced no matches for Phase 38.

</deferred>

---

*Phase: 38-Companion Seam Contract*
*Context gathered: 2026-05-29*
