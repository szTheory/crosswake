# Phase 39: Route-Policy Gating DSL And Manifest Binding - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Add two new keys to the route-policy NimbleOptions schema — `gated_by` and
`on_unavailable` — and carry both bindings into `RouteEntry` so the compiled
manifest is auditable at build time without any runtime flag evaluation.

**Satisfies:** GATE-01 (DSL key + compile-time atom validation), GATE-02
(flag binding recorded in manifest, distinct from runtime flag value).

**In scope:**
- `gated_by: :my_flag` key in `Policy.Schema` NimbleOptions schema with a
  custom snake_case atom validator (SC#1).
- `on_unavailable: :deny | {:fallback_phoenix, route_id}` key in `Policy.Schema`,
  only valid when `gated_by` is also set; defaults to `:deny` (fail-closed).
- `gated_by` and `on_unavailable` fields on `RouteEntry` (and the corresponding
  `Policy.Route` struct), with `to_map/1` serialization and `new_route_entry/1`
  builder support.
- Doctor visibility per SC#2 — planner discretion (see D-05).
- Hermetic proof: new `test/crosswake/proof/phase39_route_policy_gating_test.exs`
  (untagged, picked up by `phase34-proof.yml` automatically).

**Out of scope (belongs to later phases — do NOT pull forward):**
- Runtime gate evaluation (`route_gated?/2` consumption by `RouteGate`) — **Phase 40**.
- `:gate_denied` / `:kill_switch_active` denial injection into `RouteGate` — **Phase 40**.
- Kill-switch short-circuit wiring — **Phase 40**.
- `{:fallback_phoenix, route_id}` cross-checking against declared routes — **Phase 41** (doctor).
- Full gating doctor category + runtime gate-state support-matrix column — **Phase 41**.
- Rulestead companion impl — **Phase 42**.
- `:route_gate` / `:kill_switch` telemetry emit sites — **Phase 40**.

**D-10 from Phase 38 resolved:** Routes declare their gated flag via the `gated_by`
DSL key (config-declared pattern). `RouteGate` reading `route.gated_by` and
dispatching to registered companions is Phase 40's wiring concern.

</domain>

<decisions>
## Implementation Decisions

### ① `gated_by` custom validator (GATE-01 — SC#1) — LOCKED
- **D-01:** `gated_by` uses `{:custom, __MODULE__, :validate_flag_key, []}` in the
  NimbleOptions schema. The validator enforces the snake_case atom identifier shape:
  `is_atom(value) and value not in [true, false, nil]` plus
  `Regex.match?(~r/^[a-z_][a-z0-9_]*[?!]?$/, Atom.to_string(value))`.
  Rejects: `true`, `false`, `nil`, `"string"`, integers, `:"feature.flag"`,
  `:"my-flag"`, `:CamelCase`, `:camelCase`. Allows: `:my_flag`,
  `:feature_rollout_v2`, `:gating_enabled?`.
- **D-02:** Error message: `"expected a plain atom identifier (e.g. :my_flag), got: #{inspect(value)}"`.
  Matches the existing convention in `validate_commerce_declaration/1` and
  `validate_runtime/1` error messages.
- **D-03:** External flag platform keys that use kebab-case or dot-namespacing
  (LaunchDarkly, Unleash) are a **companion adapter boundary** concern — the
  companion does `Atom.to_string(route.gated_by)` before calling the external SDK.
  The DSL key stays a clean Elixir atom identifier. Same principle as
  Absinthe's GraphQL camelCase → snake_case boundary.
- **D-04:** Rationale: `gated_by` is preserved as an atom in `RouteEntry.t()` and
  passed to `route_gated?/2` (Phase 40). Unlike `id`/`cache_contract` which
  `validate_identifier` converts to strings, the atom IS the native contract type.
  Consistent with `companion_id/0 :: atom()` convention. `inspect/1` on a
  validated snake_case atom produces `:my_flag`; a quoted atom produces
  `:"my-flag"` — noisy in doctor output and denial `details` map.

### ② `on_unavailable` DSL key (GATE-02 — build-time posture declaration) — LOCKED
- **D-05a:** `on_unavailable` is a Phase 39 DSL key declared in `Policy.Schema`
  alongside `gated_by`. Its value is recorded in `RouteEntry` at build time so
  the unavailable posture is auditable in the manifest without runtime evaluation.
  Phase 40 evaluates it at runtime; Phase 41 doctor flags unresolved
  `{:fallback_phoenix, route_id}` references.
- **D-05b:** Valid values: `:deny | {:fallback_phoenix, route_id}` where `route_id`
  is a snake_case atom identifier validated by the same `validate_flag_key/1`
  (or equivalent identifier validator). The tuple form declares that when the flag
  snapshot is unavailable, the route should fall back to the named fully-owned
  Phoenix route instead of failing closed.
- **D-05c:** `on_unavailable` is **only valid when `gated_by` is also set**. Setting
  `on_unavailable` without `gated_by` is a compile-time NimbleOptions or
  cross-key validation error — principle of least surprise (a route with no gate
  has no unavailable posture to declare).
- **D-05d:** Default when `gated_by` is set but `on_unavailable` is omitted: `:deny`
  (fail-closed). Matches Crosswake's overall posture. The only way to get any
  fail-open behavior is explicit `{:fallback_phoenix, route_id}`.
- **D-05e:** `route_id` in `{:fallback_phoenix, route_id}` is validated as a
  snake_case atom identifier at compile time (schema-level check only).
  Cross-validation against declared routes is **Phase 41 doctor** scope.

### ③ `RouteEntry` and serialization (GATE-02 — SC#2/SC#3)
- **D-06:** Add `gated_by: atom() | nil` and `on_unavailable: :deny | {:fallback_phoenix, atom()} | nil`
  to `RouteEntry` defstruct. Both default to `nil` for non-gated routes. Non-gated
  routes have neither field set; the manifest omits them or serializes as `nil`.
- **D-07 (SC#3 — CRITICAL):** `RouteEntry` carries the flag *key* (`:my_flag`) in
  `gated_by` and the declared *posture* (`:deny` or `{:fallback_phoenix, :home}`)
  in `on_unavailable`. It does NOT carry a flag *value* (enabled/disabled/killed).
  No `gated_by_value`, `gate_enabled`, or `flag_state` field exists in Phase 39.
  This is the build-time binding / runtime value split required by SC#3. Phase 40
  introduces the runtime evaluation path.
- **D-08:** `to_map/1` serialization:
  - `gated_by: :my_flag` → `"gated_by": "my_flag"` (atom-to-string, matches `"runtime"`/`"security"` pattern)
  - `on_unavailable: :deny` → `"on_unavailable": "deny"`
  - `on_unavailable: {:fallback_phoenix, :home}` → `"on_unavailable": {"type": "fallback_phoenix", "route_id": "home"}` (or a flat `"fallback_phoenix:home"` string — planner discretion for JSON shape, must be reversible)
  - `gated_by: nil` → omit the key from the map (matches the `TransferSeam` nil-rejection pattern in `to_map/1`)
- **D-09:** `Policy.Route` struct also gets `gated_by: atom() | nil` and
  `on_unavailable` fields (pass-through from DSL validation into `new_route_entry/1`).

### ④ Proof test strategy — LOCKED
- **D-10:** New `test/crosswake/proof/phase39_route_policy_gating_test.exs`,
  untagged, picked up automatically by `phase34-proof.yml`
  (`mix test --exclude requires_example_host`). No new CI workflow file.
- **D-11:** Full coverage:
  - **SC#1 (happy paths):** `gated_by: :my_flag` compiles, produces correct
    `RouteEntry.gated_by == :my_flag`. `gated_by: :my_flag, on_unavailable: {:fallback_phoenix, :home}` compiles. Omitting `on_unavailable` when `gated_by` is set defaults to `:deny`.
  - **SC#1 (error cases):** `gated_by: true`, `gated_by: "string"`, `gated_by: :"feature.flag"`, `gated_by: nil`, `on_unavailable: :deny` without `gated_by` — all produce NimbleOptions validation errors with clear messages.
  - **SC#2/SC#3 (manifest round-trip):** Route with `gated_by: :my_flag` produces a manifest where `to_map/1` includes `"gated_by": "my_flag"` and `"on_unavailable": "deny"`. Assert the field exists in JSON output.
  - **SC#2 (introspection):** `RouteEntry.gated_by` is pattern-matchable; `inspect/1` produces `:my_flag` (not `:"my_flag"`).
  - **SC#3 (binding vs value split):** Explicit assertion that `RouteEntry` has no `gated_by_value` / `gate_enabled` / `flag_state` field at Phase 39. The struct carries only the key and posture, not any evaluated flag state.
  - **Boundary:** Non-gated route (no `gated_by`) has `RouteEntry.gated_by == nil`; `to_map/1` omits the key.
- **D-12:** Shift-left principle: proof covers happy paths, main error cases, and
  boundary conditions (nil defaults, omitted optional keys, explicit error paths).

### Claude's Discretion
- Exact JSON shape for `{:fallback_phoenix, route_id}` in `to_map/1` (flat string
  vs nested map — must be reversible and consistent with existing serialization style).
- Whether doctor visibility for SC#2 is satisfied by manifest field presence alone
  (introspection), or by minimal annotation in the existing doctor route listing.
  Read `lib/crosswake/doctor/doctor.ex` `run/1` to decide the minimal touch. Phase 41
  adds the full gating category; Phase 39 must not pre-empt it.
- `validate_flag_key/1` function name and module location (likely `Policy.Schema`
  alongside `validate_commerce_declaration/1`, `validate_runtime/1`).
- Exact NimbleOptions schema entry for `on_unavailable` — consider `{:or, [:deny_atom, :fallback_tuple]}` shape or a `:custom` validator.
- Describe/test block naming and assertion style for the proof test (follow existing
  proof test conventions in `phase38_companion_contract_test.exs`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements / Roadmap
- `.planning/REQUIREMENTS.md` — v3.5 requirements; **GATE-01** and **GATE-02** for
  this phase. Also GATE-03/04 for context on what Phase 39 must NOT pull forward
  (runtime evaluation, kill-switch short-circuit, `on_unavailable` runtime behavior).
- `.planning/ROADMAP.md` §"Phase 39: Route-Policy Gating DSL And Manifest Binding"
  — goal + 3 success criteria (SC#1/SC#2/SC#3); §Phase 40/41 confirm deferral scope.
- `.planning/research/v3.5-companions-SUMMARY.md` — locked architecture for the
  companion seam; read for the behaviour-not-protocol decision and optional-dep
  handling patterns that constrain how `gated_by` interacts with `route_gated?/2`.

### Existing DSL and manifest code (MUST read before editing)
- `lib/crosswake/policy/schema.ex` — the NimbleOptions schema where `gated_by` and
  `on_unavailable` keys are added. Study existing validators (`validate_commerce_declaration/1`,
  `validate_identifier/1`, `validate_runtime/1`) for error message convention and
  custom validator signature pattern.
- `lib/crosswake/policy/route.ex` — `Policy.Route` struct and `new/1`/`new!/1`
  validation pipeline; `gated_by` and `on_unavailable` fields must be added here too,
  with cross-key validation (`on_unavailable` requires `gated_by`).
- `lib/crosswake/manifest/types.ex` (lines ~192–240) — `RouteEntry` defstruct and
  `@type t`; lines ~558–580 `new_route_entry/1` builder; lines ~802–820 `to_map/1`
  for `RouteEntry`. Add fields and serialization here.

### Phase 38 decisions (carry forward)
- `.planning/phases/38-companion-seam-contract/38-CONTEXT.md` — D-05 (callback
  typespecs, `route_gated?/2` signature that reads `RouteEntry.t()`), D-06
  (`route_gated?/2` returns `{:deny, Finding.t()} | :pass` — NOT a boolean), D-10
  resolution (routes declare flag in DSL, not companion config), D-11b (telemetry
  event names specified but not emitted until Phase 40).

### Doctor (minimal touch for SC#2)
- `lib/crosswake/doctor/doctor.ex` — `run/1` monolithic function; read to decide the
  minimal SC#2 visibility without pre-empting Phase 41's full gating category.
  `phase_19_commerce_corridor_posture` is the shape to mirror if adding a new private
  finding function; `Report.status` derivation is at ~line 137.

### Proof lane (reuse, do NOT add a new CI file)
- `.github/workflows/phase34-proof.yml` — hermetic `merge-blocking-commerce-proof`
  job runs `mix test --exclude requires_example_host`; the new untagged
  `phase39_route_policy_gating_test.exs` is picked up automatically.
- `test/crosswake/proof/phase38_companion_contract_test.exs` — the Phase 38 proof;
  read for naming convention, describe/test block style, `Application.put_env`
  usage, and telemetry handler attach idiom. Phase 39 proof follows the same style.
- `test/support/` — existing fixture home; reference for how fixtures are structured.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Policy.Schema` `validate_commerce_declaration/1` — the custom validator signature
  and `{:ok, value} | {:error, message}` return convention that `validate_flag_key/1`
  copies.
- `Policy.Schema` `validate_identifier/1` — validates string identifiers; `validate_flag_key/1`
  is the atom-identifier analog (similar shape but atom not string).
- `Manifest.Types.to_map/1` `%TransferSeam{}` clause — uses `Enum.reject(fn {_k, v} -> is_nil(v) end)`
  to omit nil fields; apply same pattern to `gated_by`/`on_unavailable` in RouteEntry's `to_map/1`.
- `Manifest.Types.to_map/1` `%RouteEntry{}` clause (line ~802) — the exact function
  to extend with `"gated_by"` and `"on_unavailable"` keys.
- `new_route_entry/1` (line ~558) — the builder to extend; uses `struct!(RouteEntry, %{…})`.
- `phase38_companion_contract_test.exs` — proof test reference for ExUnit describe/test
  structure, `Application.put_env` companion registration, telemetry handler idiom.

### Established Patterns
- NimbleOptions custom validator: `{:custom, __MODULE__, :function_name, []}` in schema
  + `def function_name(value) :: {:ok, value} | {:error, String.t()}` in the module.
- Atom-to-string serialization in `to_map/1`: `Atom.to_string(route.runtime)` →
  `"live_view"`. Apply same to `gated_by`.
- Nil-field omission in `to_map/1`: `TransferSeam` rejects nil values before `Map.new()`.
  Apply to `gated_by`/`on_unavailable` on non-gated routes.
- Cross-key validation in `Route.new/1`: `validate_offline_contracts/1` checks that
  `cache_contract` requires `:cached_read_only` offline. Apply same pattern for
  `on_unavailable` requiring `gated_by`.

### Integration Points
- `lib/crosswake/policy/schema.ex` — add `gated_by` + `on_unavailable` keys to `@schema`.
- `lib/crosswake/policy/route.ex` — add fields to `Route` struct + cross-key validation.
- `lib/crosswake/manifest/types.ex` — extend `RouteEntry` defstruct, `new_route_entry/1`, `to_map/1`.
- `lib/crosswake/doctor/doctor.ex` — minimal SC#2 touch (planner discretion).
- `test/crosswake/proof/phase39_route_policy_gating_test.exs` — new proof file.

</code_context>

<specifics>
## Specific Ideas

- The `on_unavailable: {:fallback_phoenix, route_id}` tuple is an explicit escape hatch.
  Doctor in Phase 41 audits these carve-outs and flags unknown `route_id` references.
  Phase 39 just records the declared intent; Phase 40 evaluates it.
- The SC#3 binding-vs-value split is the central correctness invariant for Phase 39:
  the manifest carries the flag *relationship* (which flag governs which route + declared
  posture) without needing any running flag service. An offline manifest diff should be
  able to show that `:feature_payment_v2` gates `/checkout` with `:deny` posture — no
  Rulestead or OpenFeature SDK call needed.
- External flag platform keys that use kebab-case or dot-namespacing are a companion
  adapter boundary concern (adapter does `Atom.to_string(route.gated_by)` before
  calling the external SDK). This is the same boundary Absinthe uses for
  GraphQL camelCase → Elixir snake_case.

</specifics>

<deferred>
## Deferred Ideas

- **`{:fallback_phoenix, route_id}` cross-validation against declared routes** — Phase 41
  (doctor category). Phase 39 records the declared intent; Phase 41 flags unknowns.
- **Runtime gate evaluation (`route_gated?/2` → `RouteGate` wiring)** — Phase 40.
- **Kill-switch short-circuit** — Phase 40.
- **Full gating doctor category + runtime gate-state support-matrix column** — Phase 41.
- **`crosswake_openfeature` companion adapter** — v3.6+. The OpenFeature-shaped
  data contract from GATE-03 makes this a drop-in when it arrives.

</deferred>

---

*Phase: 39-Route-Policy Gating DSL And Manifest Binding*
*Context gathered: 2026-05-30*
