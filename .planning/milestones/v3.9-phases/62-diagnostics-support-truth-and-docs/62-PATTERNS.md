# Phase 62: Diagnostics, Support Truth, And Docs - Pattern Map

**Mapped:** 2024-06-03
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/doctor/doctor.ex` | utility | transform | `lib/crosswake/doctor/doctor.ex` | exact |
| `lib/crosswake/operator_inspection.ex` | utility | transform | `lib/crosswake/operator_inspection.ex` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | model | config | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `lib/crosswake/telemetry.ex` | utility | event-driven | `lib/crosswake/companions/sigra/telemetry.ex` | role-match |
| `guides/support_matrix.md` | docs | static | `guides/support_matrix.md` (existing) | exact |

## Pattern Assignments

### `lib/crosswake/doctor/doctor.ex` (utility, transform)

**Analog:** `lib/crosswake/doctor/doctor.ex`

**Imports pattern** (lines 6-17):
```elixir
  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.FindingPolicy
  alias Crosswake.Doctor.PublishReadiness
  alias Crosswake.Manifest
  alias Crosswake.Offline.Status, as: OfflineStatus
  alias Crosswake.Offline.Telemetry, as: OfflineTelemetry
  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic
```

**Diagnostic Check Pattern** (lines 387-414):
```elixir
    coherent? =
      Enum.all?(offline_routes, fn {_route_id, route} ->
        case route.offline do
          :cached_read_only -> route.cache_contract and not route.island_contract
          :local_first -> route.island_contract
          :unavailable -> true
        end
      end)

    offline = %{
      status: if(coherent?, do: :supported, else: :incomplete),
      states: status_vocabulary,
      telemetry: %{
        metadata_keys: telemetry_keys,
        terminal_outcomes: terminal_outcomes
      },
      routes: stringify_offline_routes(offline_routes)
    }

    findings = [
      check(
        if(coherent?, do: :advisory, else: :error),
        if(coherent?, do: "offline_posture_ready", else: "offline_posture_incomplete"),
        "offline_posture",
        "offline posture exposes route-local cached, saved locally...",
```

---

### `lib/crosswake/operator_inspection.ex` (utility, transform)

**Analog:** `lib/crosswake/operator_inspection.ex`

**Document Generation Pattern** (lines 28-39):
```elixir
  def from_manifest(%ManifestTypes.Root{} = manifest, opts \\ []) do
    route_entries =
      manifest.routes
      |> Enum.sort_by(fn {route_id, _route} -> route_id end)
      |> Enum.map(fn {route_id, route} -> {route_id, inspect_route(route, manifest)} end)
      |> Map.new()

    findings = route_entries |> findings_from_routes() |> Enum.sort_by(&{&1.check, &1.code})

    Types.document(
      generated_at: generated_at(opts),
      crosswake_version: manifest.crosswake_version,
```

**Entry Construction Pattern** (lines 142-153):
```elixir
  defp companion_entry(route) do
    state =
      route.gated_by &&
        Enum.find(SupportMatrix.gating_truth(), &(&1.companion_id == route.gated_by))

    %{
      gated_by: route.gated_by,
      on_unavailable: on_unavailable_label(route.on_unavailable),
      gate_state: state && state.gate_state,
      dependency_status: if(route.gated_by, do: :verification_required, else: :not_applicable),
      posture: if(route.gated_by, do: :first_party_typed_companion, else: :not_applicable)
    }
  end
```

---

### `lib/crosswake/support_matrix/support_matrix.ex` (model, config)

**Analog:** `lib/crosswake/support_matrix/support_matrix.ex`

**Static Data Structure Pattern** (lines 19-33):
```elixir
  @commerce_corridor_entries [
    %{
      corridor_role: "paywall_entry",
      owner_posture: "phoenix_owned",
      prerequisite_classes: [:route_declaration, :backend_reconciliation],
      prerequisites: [
        "route declares commerce corridor binding",
        "backend entitlement contract available"
      ],
      denial_codes: [
        "commerce.corridor.undeclared",
        "commerce.corridor.entry_denied",
        "commerce.corridor.origin_denied"
      ],
```

---

### Telemetry Modules (utility, event-driven)

**Analog:** `lib/crosswake/companions/sigra/telemetry.ex`

**Event Definitions Pattern** (lines 11-26):
```elixir
  @event_names [
    [:crosswake, :auth, :session, :evaluate, :start],
    [:crosswake, :auth, :session, :evaluate, :stop],
    [:crosswake, :auth, :session, :evaluate, :exception],
    [:crosswake, :auth, :denial],
    [:crosswake, :auth, :handoff, :issue],
    [:crosswake, :auth, :handoff, :redeem],
    [:crosswake, :auth, :handoff, :deny]
  ]

  @metadata_keys [
    :route_id,
    :flow,
    :return_kind,
    :transport,
    :outcome,
    :denial_code
  ]
```

**Struct Definition Pattern** (lines 53-73):
```elixir
  defmodule Event do
    @moduledoc false

    @enforce_keys [:name]
    defstruct [
      :name,
      :route_id,
      :flow,
      :return_kind,
      :transport,
      :outcome,
      :denial_code,
      :shell_reason,
      :authority_state,
      :auth_posture
    ]

    @type t :: %__MODULE__{name: [atom()]}
  end
```

## Shared Patterns

### Error/Diagnostics Checking Structure
**Source:** `lib/crosswake/doctor/doctor.ex`
**Apply to:** Any file introducing new verifications
```elixir
check(
  :warning, # or :error / :advisory
  "commerce.entitlement.stale_snapshot",
  "commerce_summary",
  "entitlement snapshot freshness is #{freshness}...",
  "refresh the backend entitlement projection and rerun doctor...",
  %{ freshness: Atom.to_string(freshness), proof_class: "merge_blocking" }
)
```

## Metadata

**Analog search scope:** `lib/crosswake/**/*.ex`
**Files scanned:** 5
**Pattern extraction date:** 2024-06-03
