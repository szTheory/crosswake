# Phase 39: Route-Policy Gating DSL And Manifest Binding - Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 5 (4 modified, 1 new)
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/policy/schema.ex` | schema/validator | transform | self (existing validators) | exact |
| `lib/crosswake/policy/route.ex` | model/validator | transform | self (existing cross-key validators) | exact |
| `lib/crosswake/manifest/types.ex` | model/serializer | transform | self (existing `RouteEntry` + `TransferSeam`) | exact |
| `lib/crosswake/manifest/builder.ex` | service | request-response | self (existing `route_entries/3`) | exact |
| `test/crosswake/proof/phase39_route_policy_gating_test.exs` | test | — | `test/crosswake/proof/phase38_companion_contract_test.exs` | exact |

---

## Pattern Assignments

### `lib/crosswake/policy/schema.ex` (schema/validator, transform)

**Analog:** `lib/crosswake/policy/schema.ex` — existing `validate_runtime/1`, `validate_commerce_declaration/1`, `validate_identifier/1`

**Imports / module header pattern** (lines 1–7):
```elixir
defmodule Crosswake.Policy.Schema do
  @moduledoc """
  NimbleOptions schema for Phase 1 Crosswake route policy declarations.
  """

  alias Crosswake.Transfer.Contracts
```

**NimbleOptions custom validator registration pattern in `@schema`** (lines 16–73):
```elixir
# The {:custom, __MODULE__, :function_name, []} form is the project standard.
# Every custom validator in the schema follows this exact shape.
id: [
  type: {:custom, __MODULE__, :validate_identifier, []},
  required: true,
  type_spec: quote(do: String.t())
],
runtime: [
  type: {:custom, __MODULE__, :validate_runtime, []},
  required: true,
  type_spec: quote(do: :live_view | :offline_island | :native_screen)
],
commerce: [
  type: {:custom, __MODULE__, :validate_commerce_declaration, []},
  type_spec: quote(do: commerce_declaration() | nil)
],
# NEW: gated_by and on_unavailable follow this same schema entry shape.
# No `required:` (both are optional). No `default:` on either
# (the :deny default for on_unavailable is applied in Route.new/1,
# NOT here — see Pitfall 2 in RESEARCH.md).
```

**Custom validator function signature pattern** (lines 129–135, 138–157):
```elixir
# validate_identifier/1 — returns {:ok, value} | {:error, String.t()}
@spec validate_identifier(term()) :: {:ok, String.t()} | {:error, String.t()}
def validate_identifier(value) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
def validate_identifier(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
def validate_identifier(_value), do: {:error, "expected a non-empty string or atom"}

# validate_runtime/1 — shows guard + catch-all error pattern
@spec validate_runtime(term()) :: {:ok, runtime()} | {:error, String.t()}
def validate_runtime(:adapter), do: {:error, "runtime :adapter is a reserved future extension point"}
def validate_runtime(value) when value in @runtime_values, do: {:ok, value}
def validate_runtime(value) do
  {:error, "expected one of #{inspect(@runtime_values)}, got: #{inspect(value)}"}
end

# validate_commerce_declaration/1 — shows nil-pass-through clause convention
@spec validate_commerce_declaration(term()) :: {:ok, commerce_declaration() | nil} | {:error, String.t()}
def validate_commerce_declaration(nil), do: {:ok, nil}
```

**`@type validated_options` pattern** (lines 93–106):
```elixir
@type validated_options :: [
  id: String.t(),
  runtime: runtime(),
  offline: offline(),
  entry: entry(),
  cache_contract: String.t() | nil,
  island_contract: String.t() | nil,
  capabilities: [String.t()],
  commerce: commerce_declaration() | nil,
  packs: [pack_requirement()],
  sync: [String.t()],
  transfers: [Contracts.declaration()],
  security: security()
  # NEW: add gated_by: atom() | nil and on_unavailable: :deny | {:fallback_phoenix, atom()} | nil
]
```

**What to add for Phase 39:**
1. Two new schema entries in `@schema` (after `security:`):
   ```elixir
   gated_by: [
     type: {:custom, __MODULE__, :validate_flag_key, []},
     type_spec: quote(do: atom() | nil)
   ],
   on_unavailable: [
     type: {:custom, __MODULE__, :validate_on_unavailable, []},
     type_spec: quote(do: :deny | {:fallback_phoenix, atom()} | nil)
   ]
   ```
2. `validate_flag_key/1` public function — atom identifier validator returning `{:ok, atom()}` (NOT string — D-04).
3. `validate_on_unavailable/1` public function — handles `nil`, `:deny`, `{:fallback_phoenix, route_id}`.
4. Two new entries in `@type validated_options`.

---

### `lib/crosswake/policy/route.ex` (model/validator, transform)

**Analog:** `lib/crosswake/policy/route.ex` — `validate_offline_contracts/1`, `validate_offline_contracts!/1`, `validation_error/3`, `new/1` with-chain

**`defstruct` pattern** (lines 11–25):
```elixir
@enforce_keys [:id, :runtime]
defstruct [
  :id,
  :runtime,
  :security,
  :cache_contract,
  :island_contract,
  :commerce,
  offline: :unavailable,
  entry: :internal_only,
  capabilities: [],
  packs: [],
  sync: [],
  transfers: []
  # NEW: add :gated_by and :on_unavailable (no default values — nil means non-gated)
]
```

**`@type t` pattern** (lines 27–40):
```elixir
@type t :: %__MODULE__{
  id: String.t(),
  runtime: Schema.runtime(),
  ...
  security: Schema.security() | nil
  # NEW: add gated_by: atom() | nil and on_unavailable: :deny | {:fallback_phoenix, atom()} | nil
}
```

**`new/1` with-chain pattern** (lines 43–58):
```elixir
def new(options) when is_list(options) do
  options
  |> merged_options()
  |> Schema.validate()
  |> case do
    {:ok, validated} ->
      with {:ok, validated} <- validate_offline_contracts(validated),
           {:ok, validated} <- validate_entry_policy(validated),
           {:ok, validated} <- validate_commerce_declaration(validated),
           {:ok, validated} <- validate_pack_requirements(validated),
           {:ok, validated} <- validate_transfer_declarations(validated) do
        {:ok, struct!(__MODULE__, validated)}
      end

    {:error, error} -> {:error, error}
  end
end
# NEW: add {:ok, validated} <- validate_gating_posture(validated) in the with-chain
```

**`new!/1` bang-chain pattern** (lines 62–72):
```elixir
def new!(options) when is_list(options) do
  options
  |> merged_options()
  |> Schema.validate!()
  |> validate_offline_contracts!()
  |> validate_entry_policy!()
  |> validate_commerce_declaration!()
  |> validate_pack_requirements!()
  |> validate_transfer_declarations!()
  |> then(&struct!(__MODULE__, &1))
end
# NEW: add |> validate_gating_posture!() after validate_offline_contracts!()
```

**Cross-key validation analog: `validate_offline_contracts/1`** (lines 79–100):
```elixir
# This is the EXACT pattern for validate_gating_posture/1 — a defp that
# returns {:ok, validated} or {:error, validation_error(...)}
defp validate_offline_contracts(validated) do
  cond do
    validated[:cache_contract] && validated[:offline] != :cached_read_only ->
      {:error,
       validation_error(
         :cache_contract,
         validated[:cache_contract],
         "cache_contract requires offline :cached_read_only and does not belong on local-first routes"
       )}

    validated[:island_contract] &&
        (validated[:runtime] != :offline_island or validated[:offline] != :local_first) ->
      {:error,
       validation_error(
         :island_contract,
         validated[:island_contract],
         "island_contract requires runtime :offline_island with offline :local_first"
       )}

    true ->
      {:ok, validated}
  end
end
```

**Bang variant pattern: `validate_offline_contracts!/1`** (lines 103–108):
```elixir
defp validate_offline_contracts!(validated) do
  case validate_offline_contracts(validated) do
    {:ok, validated} -> validated
    {:error, error} -> raise error
  end
end
# validate_gating_posture!/1 follows this identical shape.
```

**`validation_error/3` helper** (lines 240–246):
```elixir
defp validation_error(key, value, message) do
  %NimbleOptions.ValidationError{
    key: key,
    value: value,
    message: message
  }
end
```

**What to add for Phase 39:**
1. `:gated_by` and `:on_unavailable` to `defstruct` (no defaults — both nil for non-gated routes).
2. `gated_by: atom() | nil` and `on_unavailable: :deny | {:fallback_phoenix, atom()} | nil` in `@type t`.
3. `defp validate_gating_posture/1` — cross-key: rejects `on_unavailable` without `gated_by`; sets `:deny` default when `gated_by` set but `on_unavailable` nil.
4. `defp validate_gating_posture!/1` — raises on error (matches bang pattern).
5. Wire `validate_gating_posture/1` into `new/1` with-chain and `validate_gating_posture!/1` into `new!/1` pipe.

---

### `lib/crosswake/manifest/types.ex` (model/serializer, transform)

**Analog:** `lib/crosswake/manifest/types.ex` — `RouteEntry` defstruct (lines 196–211), `new_route_entry/1` (lines 558–576), `to_map/1` `%RouteEntry{}` clause (lines 802–819), `to_map/1` `%TransferSeam{}` nil-rejection pattern (lines 828–843)

**`RouteEntry` defstruct** (lines 195–211):
```elixir
@enforce_keys [:id, :path, :runtime]
defstruct [
  :id,
  :path,
  :runtime,
  :offline,
  :entry,
  :cache_contract,
  :island_contract,
  :commerce,
  :security,
  capabilities: [],
  packs: [],
  sync: [],
  transfers: [],
  allowlisted_origins: []
  # NEW: add :gated_by and :on_unavailable (no @enforce_keys, both nil for non-gated)
]
```

**`RouteEntry` `@type t`** (lines 213–228):
```elixir
@type t :: %__MODULE__{
  id: String.t(),
  path: String.t(),
  runtime: Crosswake.Policy.Schema.runtime(),
  ...
  security: Crosswake.Policy.Schema.security() | nil,
  allowlisted_origins: [String.t()]
  # NEW: gated_by: atom() | nil, on_unavailable: :deny | {:fallback_phoenix, atom()} | nil
}
```

**`new_route_entry/1` builder** (lines 558–576):
```elixir
@spec new_route_entry(keyword()) :: RouteEntry.t()
def new_route_entry(attrs) when is_list(attrs) do
  struct!(RouteEntry, %{
    id: Keyword.fetch!(attrs, :id),
    path: Keyword.fetch!(attrs, :path),
    runtime: Keyword.fetch!(attrs, :runtime),
    offline: Keyword.get(attrs, :offline, :unavailable),
    entry: Keyword.get(attrs, :entry, :internal_only),
    cache_contract: Keyword.get(attrs, :cache_contract),
    island_contract: Keyword.get(attrs, :island_contract),
    commerce: Keyword.get(attrs, :commerce),
    capabilities: Keyword.get(attrs, :capabilities, []),
    packs: Keyword.get(attrs, :packs, []),
    sync: Keyword.get(attrs, :sync, []),
    transfers: Keyword.get(attrs, :transfers, []),
    security: Keyword.get(attrs, :security),
    allowlisted_origins: Keyword.get(attrs, :allowlisted_origins, [])
    # NEW: add gated_by: Keyword.get(attrs, :gated_by)
    #           on_unavailable: Keyword.get(attrs, :on_unavailable)
  })
end
```

**`to_map/1` `%RouteEntry{}` clause** (lines 802–819):
```elixir
def to_map(%RouteEntry{} = route) do
  %{
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
    "allowlisted_origins" => route.allowlisted_origins
    # NEW: add "gated_by" => route.gated_by && Atom.to_string(route.gated_by)
    #           "on_unavailable" => serialize_on_unavailable(route.on_unavailable)
  }
  # NEW: pipe through nil-rejection for gated_by/on_unavailable keys (see TransferSeam pattern below)
end
```

**`Atom.to_string` and `&&` nil-guard pattern for optional atom fields** (line 816):
```elixir
# "security" uses && to short-circuit on nil — produces nil when security is nil,
# Atom.to_string when it is set. Same pattern applies to "gated_by".
"security" => route.security && Atom.to_string(route.security),
```

**`TransferSeam` nil-rejection pattern** (lines 828–843):
```elixir
# This is the EXACT nil-rejection pattern to apply to gated_by/on_unavailable
# in the RouteEntry to_map/1 clause.
def to_map(%TransferSeam{} = seam) do
  %{
    "protocol" => seam.protocol,
    ...
    "source" => seam.source && Atom.to_string(seam.source),
    "destination" => seam.destination && Atom.to_string(seam.destination),
    ...
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Map.new()
end
# Apply same |> Enum.reject |> Map.new() pipeline to the RouteEntry map,
# scoped to the gated_by and on_unavailable keys only (non-gated routes omit them).
```

**What to add for Phase 39:**
1. `:gated_by` and `:on_unavailable` to `RouteEntry` `defstruct` (no `@enforce_keys`).
2. `gated_by: atom() | nil` and `on_unavailable: :deny | {:fallback_phoenix, atom()} | nil` in `@type t`.
3. `gated_by: Keyword.get(attrs, :gated_by)` and `on_unavailable: Keyword.get(attrs, :on_unavailable)` in `new_route_entry/1`.
4. `"gated_by"` and `"on_unavailable"` keys in `to_map(%RouteEntry{})` with nil-rejection pipeline.
5. Private `serialize_on_unavailable/1` helper for the `:deny` / `{:fallback_phoenix, atom()}` cases.

**Serialization shape decision (Claude's Discretion — D-08):**
Use flat string `"fallback_phoenix:<route_id>"` for `{:fallback_phoenix, :home}` → `"fallback_phoenix:home"`. Consistent with the flat-atom-string convention of all other `to_map/1` values; reversible with `String.split(value, ":", parts: 2)`.

---

### `lib/crosswake/manifest/builder.ex` (service, request-response)

**Analog:** `lib/crosswake/manifest/builder.ex` — `route_entries/3` (lines 115–141)

**`route_entries/3` keyword args to `new_route_entry/1`** (lines 121–137):
```elixir
entry =
  Types.new_route_entry(
    id: route.id,
    path: path,
    runtime: route.runtime,
    offline: route.offline,
    entry: route.entry,
    cache_contract: cache_contract(route),
    island_contract: island_contract(route),
    commerce: route_commerce(route),
    capabilities: route.capabilities,
    packs: route_pack_references(route.packs),
    sync: route.sync,
    transfers: transfer_seams(route.transfers),
    security: route.security,
    allowlisted_origins: [origin]
    # NEW: add gated_by: route.gated_by,
    #           on_unavailable: route.on_unavailable
  )
```

**What to add for Phase 39:**
Add `gated_by: route.gated_by` and `on_unavailable: route.on_unavailable` to the `new_route_entry/1` call — direct pass-through from `Policy.Route.t()` fields.

---

### `test/crosswake/proof/phase39_route_policy_gating_test.exs` (test)

**Analog:** `test/crosswake/proof/phase38_companion_contract_test.exs` (full file — lines 1–216)

**Module declaration and docstring pattern** (lines 1–26):
```elixir
defmodule Crosswake.Proof.Phase38CompanionContractTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 38 companion seam contract.

  Proves SC#1 ..., SC#2 ..., SC#4 ...

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs UNtagged so the existing
  phase34-proof.yml `mix test --exclude requires_example_host` lane picks it up
  with no new CI file (D-13).
  ...
  """

  # async: false — [reason why concurrent execution would be unsafe]
  use ExUnit.Case, async: false
```

**Phase 39 note:** Use `async: false` only if Application.put_env/delete_env is used. If the proof has no global state writes, `async: true` is fine. The Phase 38 proof uses `async: false` because it writes `Application.put_env(:crosswake, :companions, ...)`. Phase 39 proof does not touch the companions key — evaluate whether `async: true` is safe.

**Inline router fixture pattern** (lines 33–42):
```elixir
# Minimal hermetic router providing a single route for Doctor.run
defmodule MinimalRouter do
  use Crosswake.Router

  scope "/" do
    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      live "/home", Crosswake.TestSupport.StudySessionLive,
        crosswake: [id: "home", runtime: :live_view]
    end
  end
end
# Phase 39: define GatedRouter and NonGatedRouter as inline module fixtures the same way.
```

**Hermeticity self-assertion pattern** (lines 95–103):
```elixir
test "phase 38 companion contract proof stays hermetic — no example-host or Code.require_file dependency" do
  source = File.read!(__ENV__.file) |> String.downcase()

  refute String.contains?(source, "crosswake" <> "example.router"),
         "phase 38 companion proof must not depend on the example host router; keep the merge-blocking lane hermetic"

  refute Regex.match?(~r/code\.require_file\s*\(/, source),
         "phase 38 companion proof must not Code.require_file example-host modules; keep the lane hermetic"
end
# Phase 39: copy this pattern verbatim, updating the error message string to "phase 39".
```

**`alias` and test helper imports pattern** (lines 28–31):
```elixir
alias Crosswake.Compatibility.Target
alias Crosswake.Doctor
alias Crosswake.Manifest.Types.RouteEntry
# Phase 39 aliases needed: Crosswake.Policy.Route, Crosswake.Manifest.Types (for to_map/1),
# Crosswake.Manifest.Types.RouteEntry, Crosswake.Manifest (for compile/1 if needed).
```

**test/assert style pattern** (lines 109–138):
```elixir
test "SC#1: StubCompanion satisfies all 6 Crosswake.Companion callbacks at compile time" do
  assert Crosswake.TestSupport.StubCompanion.companion_id() == :stub_companion
  assert Crosswake.TestSupport.StubCompanion.enabled?(%{}) == true
  route_entry = %RouteEntry{id: "test-route", path: "/test", runtime: :live_view}
  target = %Target{}
  assert Crosswake.TestSupport.StubCompanion.route_gated?(route_entry, target) == :pass
  assert match?(%Crosswake.Companion.State{}, Crosswake.TestSupport.StubCompanion.report_state())
  state = Crosswake.TestSupport.StubCompanion.report_state()
  assert state.companion_id == :stub_companion
end
# Phase 39: use same assert/refute style; use assert_raise for error cases.
```

**Error case / assert_raise pattern** (lines 144–180):
```elixir
test "SC#2: doctor emits companion.dependency_missing :error when ...",
     %{target: target, install_manifest_path: install_manifest_path} do
  Application.put_env(:crosswake, :companions, [Crosswake.TestSupport.BrokenCompanion])

  on_exit(fn ->
    Application.delete_env(:crosswake, :companions)
  end)

  report = Doctor.run(route_source: MinimalRouter, ...)
  finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))
  assert finding != nil, "expected a ... finding but got none; findings: #{inspect(report.findings)}"
  assert finding.severity == :error
  assert report.status == :error
end
# Phase 39 error cases use assert_raise NimbleOptions.ValidationError (for Schema rejections)
# and assert {:error, %NimbleOptions.ValidationError{}} for Route.new/1 error path.
```

**What to write for Phase 39:**
New file at `test/crosswake/proof/phase39_route_policy_gating_test.exs`. Module name: `Crosswake.Proof.Phase39RoutePolicyGatingTest`. Follows Phase 38 conventions verbatim:
- `use ExUnit.Case, async: false` (conservative — evaluate whether any test writes Application env)
- Hermeticity self-assertion test (first test, verbatim copy with "phase 39" in messages)
- Inline `GatedRouter` and `NonGatedRouter` module fixtures
- SC#1 happy path tests (compile + struct fields)
- SC#1 error tests (`assert_raise` or `assert {:error, _}`)
- SC#2/SC#3 manifest round-trip tests (`to_map/1` assertions)
- SC#3 binding-vs-value split test (`refute Map.has_key?` for `gated_by_value` / `gate_enabled` / `flag_state`)
- Boundary: non-gated route fields are nil, to_map omits them

---

## Shared Patterns

### Atom-to-String Serialization in `to_map/1`
**Source:** `lib/crosswake/manifest/types.ex` lines 806–816
**Apply to:** `to_map/1` `%RouteEntry{}` clause for `gated_by`
```elixir
# Short-circuit nil with && — returns nil when field is nil, string when set.
# Used for :runtime, :offline, :entry, :security already.
"security" => route.security && Atom.to_string(route.security),
# Apply same pattern:
"gated_by" => route.gated_by && Atom.to_string(route.gated_by),
```

### Nil-Field Omission in `to_map/1`
**Source:** `lib/crosswake/manifest/types.ex` lines 841–843 (`TransferSeam` clause)
**Apply to:** `to_map/1` `%RouteEntry{}` clause for `gated_by` and `on_unavailable` keys
```elixir
|> Enum.reject(fn {_key, value} -> is_nil(value) end)
|> Map.new()
```
Note: apply this pipeline only to the `gated_by` / `on_unavailable` entries, not to the entire map (existing `RouteEntry` `to_map/1` does not currently use this pipeline).

### Custom Validator `{:ok, value} | {:error, String.t()}` Return Shape
**Source:** `lib/crosswake/policy/schema.ex` lines 124–135
**Apply to:** `validate_flag_key/1` and `validate_on_unavailable/1` in `Policy.Schema`
```elixir
@spec validate_identifier(term()) :: {:ok, String.t()} | {:error, String.t()}
def validate_identifier(value) when is_binary(value) and byte_size(value) > 0, do: {:ok, value}
def validate_identifier(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
def validate_identifier(_value), do: {:error, "expected a non-empty string or atom"}
```
CRITICAL: `validate_flag_key/1` must return `{:ok, atom()}` NOT `{:ok, String.t()}`. Unlike `validate_identifier/1`, the atom is the native contract type (D-04). Do NOT call `Atom.to_string` inside the validator.

### Cross-Key Validation in `Route.new/1` Pipeline
**Source:** `lib/crosswake/policy/route.ex` lines 79–108 (`validate_offline_contracts/1` and `validate_offline_contracts!/1`)
**Apply to:** `validate_gating_posture/1` and `validate_gating_posture!/1` in `Policy.Route`
```elixir
defp validate_offline_contracts(validated) do
  cond do
    condition_a -> {:error, validation_error(:key, value, "message")}
    condition_b -> {:error, validation_error(:key, value, "message")}
    true -> {:ok, validated}
  end
end

defp validate_offline_contracts!(validated) do
  case validate_offline_contracts(validated) do
    {:ok, validated} -> validated
    {:error, error} -> raise error
  end
end
```

### `validation_error/3` Helper
**Source:** `lib/crosswake/policy/route.ex` lines 240–246
**Apply to:** All new `validation_error(...)` calls in `validate_gating_posture/1`
```elixir
defp validation_error(key, value, message) do
  %NimbleOptions.ValidationError{
    key: key,
    value: value,
    message: message
  }
end
```

### Hermetic Proof Test Module Structure
**Source:** `test/crosswake/proof/phase38_companion_contract_test.exs` lines 1–26, 95–103
**Apply to:** `phase39_route_policy_gating_test.exs` module declaration and first test
```elixir
defmodule Crosswake.Proof.Phase39RoutePolicyGatingTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 39 route-policy gating DSL and manifest binding.
  ...
  """
  use ExUnit.Case, async: false

  # First test — always the hermeticity self-assertion:
  test "phase 39 route-policy gating proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()
    refute String.contains?(source, "crosswake" <> "example.router"), "..."
    refute Regex.match?(~r/code\.require_file\s*\(/, source), "..."
  end
end
```

---

## No Analog Found

No files are without an analog. All five files have direct codebase analogs with exact or near-exact pattern matches.

---

## Doctor Visibility (SC#2) — Minimal Touch Decision

**Source:** `lib/crosswake/doctor/doctor.ex` lines 112–150, 486–568

**Recommendation (Claude's Discretion):** SC#2 ("flag binding readable by introspection and visible in doctor output") is **satisfied by manifest field presence alone** at Phase 39. No change to `Doctor.run/1` is needed.

Rationale:
- `Doctor.run/1` already returns `report.manifest` in the `%Report{}` struct (line 138+).
- `report.manifest.routes["checkout"].gated_by` is pattern-matchable by any caller.
- Phase 41 owns the full gating doctor category (`phase_41_gating_posture/1`). Pre-empting it with a `phase_39_gating_posture/1` now would create a vestigial private function.
- The `phase_38_companion_seam_findings/0` pattern (lines 514–564) is the shape for Phase 40/41 findings, not Phase 39.

If the planner decides a minimal annotation IS needed, the shape to mirror is `phase_19_commerce_corridor_posture/1` (lines 486–501) — an `:info` severity finding, NOT `:error`, so it does not affect `report.status`. Never add a `:warning` or `:error` finding in Phase 39 for gating — that belongs to Phase 41.

---

## Metadata

**Analog search scope:** `lib/crosswake/policy/`, `lib/crosswake/manifest/`, `lib/crosswake/doctor/`, `test/crosswake/proof/`
**Files scanned:** 5 source files (schema.ex, route.ex, types.ex, builder.ex, doctor.ex), 1 test file (phase38_companion_contract_test.exs)
**Pattern extraction date:** 2026-05-30
