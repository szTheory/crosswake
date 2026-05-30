# Phase 39: Route-Policy Gating DSL And Manifest Binding - Research

**Researched:** 2026-05-30
**Domain:** Elixir NimbleOptions schema extension, struct field addition, manifest serialization, cross-key validation, ExUnit proof tests
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** `gated_by` uses `{:custom, __MODULE__, :validate_flag_key, []}` in the NimbleOptions schema. Validator enforces: `is_atom(value) and value not in [true, false, nil]` plus `Regex.match?(~r/^[a-z_][a-z0-9_]*[?!]?$/, Atom.to_string(value))`. Accepts `:my_flag`, `:feature_rollout_v2`, `:gating_enabled?`. Rejects: `true`, `false`, `nil`, `"string"`, integers, `:"feature.flag"`, `:"my-flag"`, `:CamelCase`, `:camelCase`.

**D-02:** Error message: `"expected a plain atom identifier (e.g. :my_flag), got: #{inspect(value)}"`.

**D-03:** External flag platform kebab-case / dot-namespace keys are a companion adapter boundary concern. DSL key stays a clean Elixir atom identifier.

**D-04:** `gated_by` preserved as atom in `RouteEntry.t()`. Unlike `id`/`cache_contract`, the atom IS the native contract type — not converted to string at validation time.

**D-05a:** `on_unavailable` is a Phase 39 DSL key declared in `Policy.Schema` alongside `gated_by`. Its value is recorded in `RouteEntry` at build time.

**D-05b:** Valid values: `:deny | {:fallback_phoenix, route_id}` where `route_id` is a snake_case atom identifier validated by the same `validate_flag_key/1` (or equivalent).

**D-05c:** `on_unavailable` is only valid when `gated_by` is also set. Setting `on_unavailable` without `gated_by` is a compile-time error.

**D-05d:** Default when `gated_by` is set but `on_unavailable` is omitted: `:deny` (fail-closed).

**D-05e:** `route_id` in `{:fallback_phoenix, route_id}` validated as snake_case atom identifier at compile time. Cross-validation against declared routes is Phase 41 doctor scope.

**D-06:** Add `gated_by: atom() | nil` and `on_unavailable: :deny | {:fallback_phoenix, atom()} | nil` to `RouteEntry` defstruct. Both default to `nil` for non-gated routes.

**D-07 (CRITICAL):** `RouteEntry` carries the flag *key* in `gated_by` and declared *posture* in `on_unavailable`. NO `gated_by_value`, `gate_enabled`, or `flag_state` field exists in Phase 39.

**D-08:** `to_map/1` serialization: `gated_by: :my_flag` → `"gated_by": "my_flag"` (atom-to-string); `on_unavailable: :deny` → `"on_unavailable": "deny"`; `on_unavailable: {:fallback_phoenix, :home}` → planner discretion for JSON shape (must be reversible, consistent with existing style); `gated_by: nil` → omit the key.

**D-09:** `Policy.Route` struct also gets `gated_by: atom() | nil` and `on_unavailable` fields (pass-through into `new_route_entry/1`).

**D-10:** New `test/crosswake/proof/phase39_route_policy_gating_test.exs`, untagged, picked up automatically by `phase34-proof.yml` (`mix test --exclude requires_example_host`). No new CI workflow file.

**D-11:** Full test coverage: SC#1 happy paths + error cases, SC#2/SC#3 manifest round-trip and introspection, SC#3 binding-vs-value split assertion, boundary for non-gated routes.

**D-12:** Shift-left principle: proof covers happy paths, main error cases, and boundary conditions.

### Claude's Discretion

- Exact JSON shape for `{:fallback_phoenix, route_id}` in `to_map/1` (flat string vs nested map — must be reversible and consistent with existing serialization style).
- Whether doctor visibility for SC#2 is satisfied by manifest field presence alone (introspection), or by minimal annotation in the existing doctor route listing. Read `lib/crosswake/doctor/doctor.ex` `run/1` to decide the minimal touch. Phase 41 adds the full gating category; Phase 39 must not pre-empt it.
- `validate_flag_key/1` function name and module location (likely `Policy.Schema` alongside `validate_commerce_declaration/1`, `validate_runtime/1`).
- Exact NimbleOptions schema entry for `on_unavailable` — consider `{:or, [:deny_atom, :fallback_tuple]}` shape or a `:custom` validator.
- Describe/test block naming and assertion style for the proof test (follow existing proof test conventions in `phase38_companion_contract_test.exs`).

### Deferred Ideas (OUT OF SCOPE)

- Runtime gate evaluation (`route_gated?/2` → `RouteGate` wiring) — Phase 40.
- `:gate_denied` / `:kill_switch_active` denial injection — Phase 40.
- Kill-switch short-circuit — Phase 40.
- `{:fallback_phoenix, route_id}` cross-checking against declared routes — Phase 41 (doctor).
- Full gating doctor category + runtime gate-state support-matrix column — Phase 41.
- Rulestead companion impl — Phase 42.
- `:route_gate` / `:kill_switch` telemetry emit sites — Phase 40.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-01 | A Phoenix team can declare that a route or capability is gated by a named flag (`gated_by`) in the route-policy DSL, validated at compile time as a typed identifier. | `validate_flag_key/1` custom validator in `Policy.Schema`, SC#1 proof coverage |
| GATE-02 | A gated route's flag *binding* is recorded in the runtime manifest at build time, while the flag *value* is evaluated at runtime from a local snapshot with no network call in the activation decision path. | `RouteEntry` struct fields, `Builder.route_entries/3` pass-through, `to_map/1` serialization, D-07 binding-vs-value split |
</phase_requirements>

---

## Summary

Phase 39 is a pure schema-extension + struct-propagation phase. There is no new library to install, no new CI workflow, and no runtime evaluation. The entire scope is: add two keys (`gated_by`, `on_unavailable`) to the NimbleOptions schema in `Policy.Schema`, carry those fields through `Policy.Route` → `Manifest.Builder` → `RouteEntry` → `to_map/1`, and prove the binding is recorded correctly with a hermetic ExUnit proof test.

The codebase already has every pattern Phase 39 needs. `validate_runtime/1` and `validate_commerce_declaration/1` in `Policy.Schema` show the exact custom validator signature. `validate_offline_contracts/1` in `Policy.Route` shows the exact cross-key validation pattern. `to_map/1` in `Manifest.Types` already serializes atoms with `Atom.to_string/1` and omits nil fields with `Enum.reject(is_nil)` on `TransferSeam`. `Builder.route_entries/3` shows how policy Route fields flow into `new_route_entry/1`. The Phase 38 proof test shows the exact describe/test/assert style, hermeticity self-assertion, and `use ExUnit.Case, async: true` pattern to follow.

The central correctness invariant is D-07: `RouteEntry` at Phase 39 carries only the flag *key* (`:my_flag`) and declared *posture* (`:deny` or `{:fallback_phoenix, :home}`). It must NOT carry any evaluated flag value. This is the build-time binding / runtime value split required by GATE-02 SC#3.

**Primary recommendation:** Execute as four integration points in sequence — (1) `Policy.Schema` validator + schema entry, (2) `Policy.Route` struct + cross-key validation, (3) `Manifest.Types` + `Builder`, (4) proof test. Each integration point has a direct analog already in the codebase.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DSL key validation (`gated_by`, `on_unavailable`) | Policy layer (`Policy.Schema`) | — | All route-policy NimbleOptions schema and custom validators live here |
| Cross-key validation (`on_unavailable` requires `gated_by`) | Policy layer (`Policy.Route`) | — | Cross-key constraints like `validate_offline_contracts/1` live in `Route.new/1`, not in `Schema` |
| Struct field carry-through | Manifest layer (`Manifest.Builder`) | — | `Builder.route_entries/3` reads `Policy.Route.t()` fields and passes to `new_route_entry/1` |
| Runtime manifest field (`RouteEntry`) | Manifest layer (`Manifest.Types`) | — | `RouteEntry` defstruct, `new_route_entry/1`, `to_map/1` all live in `Manifest.Types` |
| Doctor visibility (SC#2 minimal touch) | Doctor layer (`Doctor.run/1`) | — | Manifest field presence satisfies SC#2 via introspection; no new doctor function needed at Phase 39 |
| Proof / compile-time correctness | Test layer (`phase39_route_policy_gating_test.exs`) | CI (`phase34-proof.yml`) | Untagged proof test is auto-picked-up by existing CI; no new workflow file |

---

## Standard Stack

### Core (no new packages — all existing)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `nimble_options` | `~> 1.1` [VERIFIED: mix.exs line 41] | NimbleOptions schema and custom validators | Already declared in mix.exs; all route-policy DSL validation uses it |
| ExUnit (stdlib) | OTP 28 / Elixir 1.19.5 [VERIFIED: env] | Test framework for proof test | Built in; all existing proof tests use it |

**No new packages required.** Phase 39 is a pure code-extension phase. The `slopcheck` protocol is not needed — no `mix deps.get` step exists for this phase.

---

## Package Legitimacy Audit

No external packages are installed in this phase. This section is intentionally omitted.

---

## Architecture Patterns

### System Architecture Diagram

```
DSL declaration (Route.new!/1 call):
  crosswake: [id: "my_route", ..., gated_by: :feature_x, on_unavailable: :deny]
        │
        ▼
[Policy.Schema] validate/1
  → validate_flag_key(:feature_x) → {:ok, :feature_x}
  → validate_on_unavailable(:deny) → {:ok, :deny}
        │
        ▼
[Policy.Route] new/1 / new!/1
  → validate_gating_posture(validated)   ← cross-key: on_unavailable requires gated_by
  → struct!(Route, %{gated_by: :feature_x, on_unavailable: :deny, ...})
        │
        ▼
[Manifest.Builder] route_entries/3
  → Types.new_route_entry([..., gated_by: route.gated_by, on_unavailable: route.on_unavailable])
        │
        ▼
[Manifest.Types.RouteEntry]
  → %RouteEntry{gated_by: :feature_x, on_unavailable: :deny, ...}
        │
  ┌─────┴────────────────────────────────────┐
  │                                          │
  ▼                                          ▼
[to_map/1]                            [introspection / doctor]
  "gated_by" => "feature_x"            RouteEntry.gated_by == :feature_x
  "on_unavailable" => "deny"            pattern-matchable atom
  (nil fields omitted)
```

### Recommended Project Structure

No new directories. Changes are all in existing files:

```
lib/crosswake/
├── policy/
│   ├── schema.ex          # add validate_flag_key/1, gated_by + on_unavailable schema entries
│   └── route.ex           # add gated_by + on_unavailable fields; add validate_gating_posture/1
├── manifest/
│   ├── types.ex           # extend RouteEntry defstruct, new_route_entry/1, to_map/1
│   └── builder.ex         # pass gated_by + on_unavailable through route_entries/3
test/crosswake/proof/
└── phase39_route_policy_gating_test.exs   # new hermetic proof
```

### Pattern 1: NimbleOptions Custom Validator (atom identifier)

**What:** A public function in `Policy.Schema` with signature `{:custom, __MODULE__, :validate_flag_key, []}` in the `@schema`, returning `{:ok, atom()} | {:error, String.t()}`.

**When to use:** `gated_by` schema entry. Reuse same validator for `route_id` inside the `on_unavailable` tuple validator.

```elixir
# Source: [VERIFIED: lib/crosswake/policy/schema.ex validate_runtime/1 pattern]
@spec validate_flag_key(term()) :: {:ok, atom()} | {:error, String.t()}
def validate_flag_key(value) when is_atom(value) and value not in [true, false, nil] do
  str = Atom.to_string(value)
  if Regex.match?(~r/^[a-z_][a-z0-9_]*[?!]?$/, str) do
    {:ok, value}
  else
    {:error, "expected a plain atom identifier (e.g. :my_flag), got: #{inspect(value)}"}
  end
end

def validate_flag_key(value) do
  {:error, "expected a plain atom identifier (e.g. :my_flag), got: #{inspect(value)}"}
end
```

**Schema entry:**

```elixir
# Source: [VERIFIED: lib/crosswake/policy/schema.ex @schema pattern]
gated_by: [
  type: {:custom, __MODULE__, :validate_flag_key, []},
  type_spec: quote(do: atom() | nil)
],
on_unavailable: [
  type: {:custom, __MODULE__, :validate_on_unavailable, []},
  type_spec: quote(do: :deny | {:fallback_phoenix, atom()} | nil)
]
```

### Pattern 2: `on_unavailable` Validator

**What:** A custom validator for the union type `:deny | {:fallback_phoenix, atom()}`.

**Recommendation (Claude's Discretion):** Use `{:custom, __MODULE__, :validate_on_unavailable, []}` rather than the NimbleOptions `{:or, [...]}` type. Rationale: `{:or, [...]}` NimbleOptions type supports atoms and tuples but produces generic NimbleOptions error messages; the custom validator produces the prescribed D-02-style error message and can validate the `route_id` atom identifier shape inside the tuple.

```elixir
# Source: [ASSUMED — pattern inferred from validate_commerce_declaration/1 style]
@spec validate_on_unavailable(term()) :: {:ok, :deny | {:fallback_phoenix, atom()}} | {:error, String.t()}
def validate_on_unavailable(nil), do: {:ok, nil}
def validate_on_unavailable(:deny), do: {:ok, :deny}

def validate_on_unavailable({:fallback_phoenix, route_id}) do
  case validate_flag_key(route_id) do
    {:ok, valid_id} -> {:ok, {:fallback_phoenix, valid_id}}
    {:error, _msg} ->
      {:error,
       "on_unavailable fallback_phoenix route_id must be a plain atom identifier (e.g. :home), got: #{inspect(route_id)}"}
  end
end

def validate_on_unavailable(value) do
  {:error,
   "expected on_unavailable to be :deny or {:fallback_phoenix, route_id}, got: #{inspect(value)}"}
end
```

### Pattern 3: Cross-Key Validation in `Policy.Route`

**What:** After `Schema.validate/1` passes, `Route.new/1` runs a `validate_gating_posture/1` step that rejects `on_unavailable` set without `gated_by`, and sets the `:deny` default when `gated_by` is set but `on_unavailable` is nil.

**When to use:** Matches the `validate_offline_contracts/1` pattern exactly.

```elixir
# Source: [VERIFIED: lib/crosswake/policy/route.ex validate_offline_contracts/1 pattern]
defp validate_gating_posture(validated) do
  gated_by = validated[:gated_by]
  on_unavailable = validated[:on_unavailable]

  cond do
    on_unavailable != nil and is_nil(gated_by) ->
      {:error,
       validation_error(
         :on_unavailable,
         on_unavailable,
         "on_unavailable requires gated_by to be set"
       )}

    gated_by != nil and is_nil(on_unavailable) ->
      {:ok, Keyword.put(validated, :on_unavailable, :deny)}

    true ->
      {:ok, validated}
  end
end
```

Wire into `Route.new/1`:

```elixir
# Source: [VERIFIED: lib/crosswake/policy/route.ex new/1 with clause chain]
with {:ok, validated} <- validate_offline_contracts(validated),
     {:ok, validated} <- validate_entry_policy(validated),
     {:ok, validated} <- validate_gating_posture(validated),   # <-- add here
     {:ok, validated} <- validate_commerce_declaration(validated),
     ...
```

### Pattern 4: `RouteEntry` struct extension

**What:** Add `gated_by` and `on_unavailable` to the `RouteEntry` defstruct with `nil` defaults (not `@enforce_keys`).

```elixir
# Source: [VERIFIED: lib/crosswake/manifest/types.ex RouteEntry defstruct lines 195-211]
defstruct [
  :id, :path, :runtime, :offline, :entry,
  :cache_contract, :island_contract, :commerce, :security,
  :gated_by,          # atom() | nil  — add
  :on_unavailable,    # :deny | {:fallback_phoenix, atom()} | nil  — add
  capabilities: [],
  packs: [],
  sync: [],
  transfers: [],
  allowlisted_origins: []
]
```

### Pattern 5: `to_map/1` serialization for `RouteEntry`

**What:** Add `gated_by` and `on_unavailable` to the `%RouteEntry{}` clause in `to_map/1`. Omit nil fields consistent with `TransferSeam` pattern.

**Recommendation for `{:fallback_phoenix, route_id}` JSON shape (Claude's Discretion):** Use a flat `"fallback_phoenix:<route_id>"` string. Rationale: (1) It is reversible with a single `String.split` on `":"`. (2) It matches the existing flat-atom-string style of all other `to_map/1` values (no nested maps in `RouteEntry` serialization outside of sub-struct delegates). (3) It avoids introducing a nested JSON object for a two-part value. Alternative (nested map `%{"type" => "fallback_phoenix", "route_id" => "home"}`) is more machine-parseable but inconsistent with the flat-string convention.

```elixir
# Source: [VERIFIED: lib/crosswake/manifest/types.ex to_map/1 RouteEntry clause ~line 802]
def to_map(%RouteEntry{} = route) do
  base = %{
    "id" => route.id,
    "path" => route.path,
    "runtime" => Atom.to_string(route.runtime),
    "offline" => Atom.to_string(route.offline),
    "entry" => Atom.to_string(route.entry),
    "cache_contract" => to_map(route.cache_contract),
    "island_contract" => to_map(route.island_contract),
    "commerce" => to_map(route.commerce),
    "capabilities" => route.capabilities,
    "packs" => route.packs,
    "sync" => route.sync,
    "transfers" => Enum.map(route.transfers, &to_map/1),
    "security" => route.security && Atom.to_string(route.security),
    "allowlisted_origins" => route.allowlisted_origins,
    "gated_by" => route.gated_by && Atom.to_string(route.gated_by),
    "on_unavailable" => serialize_on_unavailable(route.on_unavailable)
  }

  # Omit nil fields for gated_by and on_unavailable (non-gated routes)
  # consistent with TransferSeam nil-rejection pattern
  base
  |> Enum.reject(fn {k, v} -> k in ["gated_by", "on_unavailable"] and is_nil(v) end)
  |> Map.new()
end

defp serialize_on_unavailable(nil), do: nil
defp serialize_on_unavailable(:deny), do: "deny"
defp serialize_on_unavailable({:fallback_phoenix, route_id}),
  do: "fallback_phoenix:#{route_id}"
```

### Pattern 6: `new_route_entry/1` extension in `Manifest.Types`

**What:** Add `gated_by` and `on_unavailable` keyword args to `new_route_entry/1`.

```elixir
# Source: [VERIFIED: lib/crosswake/manifest/types.ex new_route_entry/1 ~line 558]
@spec new_route_entry(keyword()) :: RouteEntry.t()
def new_route_entry(attrs) when is_list(attrs) do
  struct!(RouteEntry, %{
    # ... existing fields ...
    gated_by: Keyword.get(attrs, :gated_by),
    on_unavailable: Keyword.get(attrs, :on_unavailable)
  })
end
```

### Pattern 7: `Manifest.Builder` pass-through

**What:** In `route_entries/3`, read `route.gated_by` and `route.on_unavailable` from the `Policy.Route` struct and pass to `new_route_entry/1`.

```elixir
# Source: [VERIFIED: lib/crosswake/manifest/builder.ex route_entries/3 ~line 122]
entry =
  Types.new_route_entry(
    # ... existing fields ...
    gated_by: route.gated_by,
    on_unavailable: route.on_unavailable
  )
```

### Pattern 8: `validated_options()` type update in `Policy.Schema`

Add `gated_by` and `on_unavailable` to the `@type validated_options :: [...]` typespec in `Policy.Schema`.

```elixir
# Source: [VERIFIED: lib/crosswake/policy/schema.ex @type validated_options ~line 93]
@type validated_options :: [
  # ... existing entries ...
  gated_by: atom() | nil,
  on_unavailable: :deny | {:fallback_phoenix, atom()} | nil
]
```

### Anti-Patterns to Avoid

- **Storing evaluated flag value in `RouteEntry`:** D-07 is the central correctness invariant. No `gated_by_value`, `gate_enabled`, `flag_state`, or similar field. This splits build-time binding from runtime evaluation.
- **Converting `gated_by` atom to string at `validate_flag_key/1` time:** Unlike `validate_identifier/1` which returns `{:ok, Atom.to_string(value)}`, `validate_flag_key/1` must return `{:ok, atom()}` — the atom is the native contract type (D-04).
- **Allowing `on_unavailable` without `gated_by` in NimbleOptions schema:** The schema alone cannot enforce cross-key constraints in NimbleOptions `1.1`. The cross-key check belongs in `Route.new/1` pipeline (Pattern 3), not in `validate_on_unavailable/1`. The schema-level `on_unavailable` validator only validates the *shape* of the value, not its co-presence with `gated_by`.
- **Pre-empting Phase 41 doctor:** Phase 39's SC#2 ("doctor visibility") is satisfied by the field being present and readable on `RouteEntry` — the manifest is introspectable. Do NOT add a `phase_39_gating_posture` finding function to `Doctor.run/1`. Phase 41 owns the full gating doctor category.
- **Failing closed on `{:fallback_phoenix, route_id}` cross-validation at Phase 39:** The route_id is validated as a snake_case atom identifier only. Whether it references an actual declared route is Phase 41's concern.
- **Making `gated_by` or `on_unavailable` `@enforce_keys`:** Both default to `nil` for non-gated routes. They must not be required fields.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Snake_case atom identifier validation | Custom regex + manual `is_atom` check duplicated per call site | `validate_flag_key/1` in `Policy.Schema` (single location) | Same validator is reused for `gated_by` and the `route_id` inside `{:fallback_phoenix, route_id}` |
| Cross-key dependency validation | NimbleOptions `:requires` option (does not exist in `~> 1.1`) | Post-`Schema.validate/1` pipeline in `Route.new/1` (Pattern 3) | NimbleOptions `1.1` does not support cross-key constraints natively; the established codebase pattern is a separate validation step after `validate/1` |
| nil field omission in `to_map/1` | Manual `if/else` per nil field | `Enum.reject(fn {k, v} -> ... is_nil(v) end) |> Map.new()` | `TransferSeam` `to_map/1` clause (line ~841) already uses this pattern; use the same approach |

---

## Runtime State Inventory

Phase 39 is a greenfield feature addition (new DSL keys, new struct fields). No rename or migration is involved. This section is not applicable.

---

## Common Pitfalls

### Pitfall 1: `validate_identifier/1` vs `validate_flag_key/1` Confusion

**What goes wrong:** Implementing `validate_flag_key/1` by calling `validate_identifier/1` and converting the result — which would produce a `String.t()` return instead of `atom()`.

**Why it happens:** `validate_identifier/1` exists and does atom-to-string conversion. It's tempting to reuse it.

**How to avoid:** `validate_flag_key/1` must return `{:ok, atom()}`, not `{:ok, String.t()}`. The atom is preserved throughout — in `Policy.Route`, `RouteEntry.t()`, and passed to `route_gated?/2` in Phase 40. Only `to_map/1` converts it to a string for JSON serialization.

**Warning signs:** If `RouteEntry.gated_by` returns `"my_flag"` (binary) instead of `:my_flag` (atom), the validator is converting incorrectly.

### Pitfall 2: `on_unavailable` Default `:deny` Applied Too Eagerly

**What goes wrong:** Setting `on_unavailable: :deny` in the NimbleOptions schema `default:` field, which would make `on_unavailable: :deny` appear on non-gated routes (routes with `gated_by: nil`).

**Why it happens:** NimbleOptions `default:` is applied to every validation call, including non-gated routes that never set `gated_by`.

**How to avoid:** Do NOT put `default: :deny` in the NimbleOptions schema entry. Instead, apply the `:deny` default in the `validate_gating_posture/1` cross-key validator (Pattern 3) — only when `gated_by != nil` and `on_unavailable` is nil. Non-gated routes must have `on_unavailable: nil`.

**Warning signs:** A non-gated route's `RouteEntry.on_unavailable` is `:deny` instead of `nil`; `to_map/1` includes `"on_unavailable": "deny"` for a non-gated route.

### Pitfall 3: Missing `Route` Struct Fields Causes `struct!` KeyError

**What goes wrong:** `struct!(Route, validated)` raises `KeyError` because `gated_by` and `on_unavailable` are in the validated keyword list but not in the `Route` defstruct.

**Why it happens:** `Route.new/1` calls `struct!(__MODULE__, validated)` with the full validated keyword list. If `Route`'s defstruct does not include `gated_by` and `on_unavailable`, Elixir raises on unknown keys.

**How to avoid:** Add both fields to `Route`'s defstruct (D-09) before adding them to the NimbleOptions schema.

**Warning signs:** `** (KeyError) key :gated_by not found` at runtime or compile-time when building a gated route.

### Pitfall 4: `Builder.route_entries/3` Not Updated

**What goes wrong:** `RouteEntry.gated_by` is always `nil` even for gated routes because `Builder.route_entries/3` does not pass the fields to `new_route_entry/1`.

**Why it happens:** `Builder` explicitly lists keyword args for `new_route_entry/1`. Adding fields to `Route` and `RouteEntry` without updating `Builder` means the fields are silently dropped.

**How to avoid:** Pattern 7 — explicitly add `gated_by: route.gated_by, on_unavailable: route.on_unavailable` to the `new_route_entry/1` call in `builder.ex`.

**Warning signs:** SC#2/SC#3 proof assertions fail — `RouteEntry.gated_by == nil` for a route declared with `gated_by: :my_flag`.

### Pitfall 5: Quoted Atom in `inspect/1` Output

**What goes wrong:** Using a flag key like `:"my-flag"` or `:"feature.flag"` produces `:"my-flag"` in `inspect/1` output (noise in doctor + denial details), while a plain snake_case atom produces `:my_flag` (clean).

**Why it happens:** Elixir quotes atoms whose names contain non-identifier characters.

**How to avoid:** D-01 regex `~r/^[a-z_][a-z0-9_]*[?!]?$/` guarantees only unquoted atoms pass validation. The validator rejects `:"my-flag"` and `:"feature.flag"` at compile time. Test `inspect(:my_flag) == ":my_flag"` (not `":\"my_flag\""`) in the proof.

---

## Code Examples

### SC#1 Proof — Happy Paths

```elixir
# Source: [ASSUMED — inferred from phase38_companion_contract_test.exs style]
defmodule GatedRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/checkout", Crosswake.TestSupport.StudySessionLive,
        crosswake: [id: "checkout", runtime: :live_view, gated_by: :feature_payment_v2]
    end
  end
end

test "SC#1: gated_by: :my_flag compiles and produces RouteEntry.gated_by == :my_flag" do
  assert {:ok, %{manifest: manifest}} = Manifest.compile(GatedRouter)
  route = manifest.routes["checkout"]
  assert route.gated_by == :feature_payment_v2
  assert route.on_unavailable == :deny
  # SC#3: no flag value field
  refute Map.has_key?(Map.from_struct(route), :gated_by_value)
  refute Map.has_key?(Map.from_struct(route), :gate_enabled)
  refute Map.has_key?(Map.from_struct(route), :flag_state)
end
```

### SC#1 Proof — Error Cases

```elixir
# Source: [ASSUMED — inferred from validate_commerce_declaration error test style]
test "SC#1 error: gated_by: true is rejected" do
  assert_raise NimbleOptions.ValidationError, ~r/plain atom identifier/, fn ->
    Policy.Route.new!(id: "bad", runtime: :live_view, gated_by: true)
  end
end

test "SC#1 error: on_unavailable without gated_by is rejected" do
  assert {:error, error} =
    Policy.Route.new(id: "bad", runtime: :live_view, on_unavailable: :deny)
  assert error.key == :on_unavailable
  assert String.contains?(error.message, "requires gated_by")
end
```

### SC#2/SC#3 Manifest Round-Trip

```elixir
# Source: [ASSUMED — inferred from phase33 manifest round-trip assertions]
test "SC#2/SC#3: to_map/1 includes gated_by and on_unavailable as strings" do
  assert {:ok, %{manifest: manifest}} = Manifest.compile(GatedRouter)
  route_map = Types.to_map(manifest.routes["checkout"])
  assert route_map["gated_by"] == "feature_payment_v2"
  assert route_map["on_unavailable"] == "deny"
end

test "SC#2: non-gated route omits gated_by and on_unavailable from to_map/1" do
  assert {:ok, %{manifest: manifest}} = Manifest.compile(NonGatedRouter)
  route_map = Types.to_map(manifest.routes["home"])
  refute Map.has_key?(route_map, "gated_by")
  refute Map.has_key?(route_map, "on_unavailable")
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded route permission flags | NimbleOptions-validated atom identifier `gated_by` with compile-time check | Phase 39 (new) | Build-time errors catch invalid flag references before runtime |
| Runtime flag value stored on route struct | Build-time binding key only (no value in manifest) | Phase 39 (new) | Manifest is offline-inspectable; flag value remains runtime-only (Phase 40) |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `{:custom, __MODULE__, :validate_flag_key, []}` is the correct NimbleOptions custom type specifier syntax for NimbleOptions `~> 1.1` | Standard Stack / Code Examples | Low — same syntax is used verbatim in the existing schema.ex for validate_identifier, validate_runtime, validate_commerce_declaration |
| A2 | Flat string `"fallback_phoenix:home"` is the right JSON serialization shape for `{:fallback_phoenix, :home}` | Code Examples Pattern 5 | Low — planner has discretion; the nested-map alternative also works |
| A3 | `validate_on_unavailable/1` implementation detail (clause structure) | Code Examples Pattern 2 | Low — the shape is constrained by D-05b; specific clause order is planner/implementer discretion |
| A4 | The `:deny` default should be applied in `validate_gating_posture/1` rather than via NimbleOptions `default:` | Architecture Patterns Pattern 3 | Low — the D-05d decision is locked; the mechanism (where default is applied) is implementation detail |

---

## Open Questions

1. **Doctor minimal touch for SC#2**
   - What we know: SC#2 requires the flag binding to be "readable by introspection and visible in doctor output." The manifest field presence satisfies introspection. The CONTEXT.md says Phase 41 adds the full gating category.
   - What's unclear: Whether SC#2 requires any change to `Doctor.run/1` output, or whether "visible in doctor output" is satisfied by the manifest field being present in the compiled manifest that doctor already holds.
   - Recommendation: Read `Doctor.run/1` (lines ~113–148) before planning. The existing manifest is already part of the `Report` struct (`report.manifest`). If the planner judges that `RouteEntry.gated_by` being visible on `report.manifest.routes[id].gated_by` satisfies SC#2, no `Doctor.run/1` change is needed. If a minimal annotation is required (e.g., a `:info` finding listing gated routes), mirror `phase_19_commerce_corridor_posture/1` shape but at `:info` severity to avoid pre-empting Phase 41.

---

## Environment Availability

No external dependencies for this phase. All required tools are in the existing mix project.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.19.5 | — |
| NimbleOptions `~> 1.1` | DSL schema | ✓ | in mix.exs | — |
| ExUnit | Proof test | ✓ | stdlib | — |
| `mix test --exclude requires_example_host` | CI proof lane | ✓ | phase34-proof.yml | — |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` — `ExUnit.start()` |
| Quick run command | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-01 | `gated_by: :my_flag` compiles, invalid values rejected | unit | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` | ❌ Wave 0 |
| GATE-01 | Error cases: `gated_by: true`, `gated_by: "string"`, `gated_by: :"feature.flag"`, `gated_by: nil` | unit | same | ❌ Wave 0 |
| GATE-01 | `on_unavailable: :deny` without `gated_by` is compile-time error | unit | same | ❌ Wave 0 |
| GATE-02 | `RouteEntry.gated_by == :my_flag` for gated route | unit | same | ❌ Wave 0 |
| GATE-02 | `to_map/1` includes `"gated_by": "my_flag"` and `"on_unavailable": "deny"` | unit | same | ❌ Wave 0 |
| GATE-02 | Non-gated route has `RouteEntry.gated_by == nil` and omits key from `to_map/1` | unit | same | ❌ Wave 0 |
| GATE-02 | SC#3: `RouteEntry` has no `gated_by_value`/`gate_enabled`/`flag_state` field | unit | same | ❌ Wave 0 |
| GATE-02 | `inspect(route.gated_by)` produces `:my_flag` not `:"my_flag"` | unit | same | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs`
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase39_route_policy_gating_test.exs` — covers all GATE-01/GATE-02 test cases listed above

*(No framework install needed — ExUnit and the project test infrastructure are already in place.)*

---

## Security Domain

Phase 39 adds DSL keys and struct fields only. No authentication, session management, cryptography, or access control logic is introduced. The `on_unavailable: :deny` fail-closed default is the security posture declared at build time; the runtime enforcement belongs to Phase 40.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no (Phase 40) | — |
| V5 Input Validation | yes | `validate_flag_key/1` snake_case atom regex; `validate_on_unavailable/1` union type check |
| V6 Cryptography | no | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed atom in `gated_by` reaching runtime | Tampering | `validate_flag_key/1` at compile time via NimbleOptions; atoms cannot be injected from external input in a compiled schema |
| `on_unavailable: {:fallback_phoenix, :some_route}` referencing non-existent route | Spoofing / information disclosure | Schema validates identifier shape only; Phase 41 doctor cross-checks existence |

---

## Sources

### Primary (HIGH confidence)

- `lib/crosswake/policy/schema.ex` — full file read. Custom validator pattern, `{:custom, __MODULE__, :fn, []}` syntax, `validate_identifier/1`, `validate_runtime/1`, `validate_commerce_declaration/1` error message conventions, `@schema NimbleOptions.new!([...])` structure.
- `lib/crosswake/policy/route.ex` — full file read. `Route` defstruct, `@enforce_keys`, `Route.new/1` with-chain, `validate_offline_contracts/1` cross-key validation pattern, `validation_error/3` helper, `struct!(__MODULE__, validated)` builder.
- `lib/crosswake/manifest/types.ex` — partial read (lines 185–230, 540–620, 790–844). `RouteEntry` defstruct, `new_route_entry/1` keyword signature, `to_map/1` `%RouteEntry{}` clause with `Atom.to_string/1`, `TransferSeam` `to_map/1` nil-rejection with `Enum.reject |> Map.new`.
- `lib/crosswake/manifest/builder.ex` — partial read (lines 1–170). `route_entries/3` function and its `Types.new_route_entry/1` call with explicit keyword args.
- `lib/crosswake/doctor/doctor.ex` — partial read (lines 1–160, 486–568). `run/1` structure, `phase_38_companion_seam_findings/0` pattern, `phase_19_commerce_corridor_posture/1` private function shape.
- `test/crosswake/proof/phase38_companion_contract_test.exs` — full file read. Proof test module naming, `use ExUnit.Case, async: false`, hermeticity self-assertion pattern, describe/test block style, inline router fixture pattern.
- `.planning/phases/39-route-policy-gating-dsl-and-manifest-binding/39-CONTEXT.md` — full file read. All locked decisions D-01 through D-12.
- `.planning/REQUIREMENTS.md` — full file read. GATE-01, GATE-02 definitions.
- `.github/workflows/phase34-proof.yml` — full file read. `mix test --exclude requires_example_host` command, untagged test pickup behavior.
- `mix.exs` grep — `{:nimble_options, "~> 1.1"}` confirmed.

### Secondary (MEDIUM confidence)

- `.planning/research/v3.5-companions-SUMMARY.md` — two-layer evaluation architecture (binding at build time, value at runtime), fail-closed default rationale, atom-as-native-contract-type rationale.

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — no new packages; existing packages verified in mix.exs
- Architecture: HIGH — all patterns verified against actual codebase source
- Pitfalls: HIGH — derived from direct code inspection of the patterns being extended
- Proof test structure: HIGH — phase38 proof test read in full as direct template

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable Elixir/NimbleOptions codebase; no fast-moving external dependencies)
