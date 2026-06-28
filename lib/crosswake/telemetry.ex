defmodule Crosswake.Telemetry do
  @moduledoc """
  Canonical public API for Crosswake telemetry events.

  `events/0` returns the runtime-aggregated catalog of every `:telemetry`
  event Crosswake emits across companion spans, doctor, threadline, sigra,
  and chimeway subsystems. Call it at runtime — not at compile time.

  Telemetry events are **public API**: additions are non-breaking minors;
  removals or renames are breaking majors requiring a semver major bump.

  **Diagnostic-only.** This module is NOT an APM replacement, NOT a
  distributed tracing framework, and NOT a generic event bus. It augments
  host observability by exposing a typed, low-cardinality, PII-free event
  catalog. It coexists with any host-side observability pipeline.

  Zero new dependencies — only `:telemetry`, already a project dependency.
  """

  @typedoc """
  A self-describing telemetry event catalog entry.

  - `event` — the event name prefix as an atom list (without `:start`/`:stop`/`:exception` suffix)
  - `tier` — `:active` means the event is emitted; `:reserved` means declared but not yet emitted
  - `description` — a calm, specific description of what the event signals
  - `measurements` — list of measurement key atoms emitted in the measurement map
  - `metadata` — list of metadata key atoms emitted in the metadata map (key names only, no PII values)
  """
  @type event_doc :: %{
    event: [atom()],
    tier: :active | :reserved,
    description: String.t(),
    measurements: [atom()],
    metadata: [atom()]
  }

  @doc """
  Returns the runtime-aggregated catalog of all Crosswake telemetry events.

  Builds the catalog at call time by concatenating:
  1. Core `:active` span docs for the 5 confirmed emitting prefixes
  2. `:reserved` docs from `Sigra.Telemetry.event_names/0` and `Chimeway.Telemetry.event_names/0`
  3. Configured-companion docs from `Application.get_env(:crosswake, :companions, [])`
     merged via `function_exported?(mod, :telemetry_events, 0)` (D-07, TELEM-04)

  The result is de-duplicated by event prefix and sorted (D-06).

  Fail-closed (D-10): with no companions configured, returns core + reserved events
  and never raises.
  """
  @spec events() :: [event_doc()]
  def events do
    core_active = build_active_events()
    reserved = build_reserved_events()

    companion_events =
      Application.get_env(:crosswake, :companions, [])
      |> Enum.flat_map(fn mod ->
        if function_exported?(mod, :telemetry_events, 0), do: mod.telemetry_events(), else: []
      end)

    (core_active ++ reserved ++ companion_events)
    |> Enum.uniq_by(& &1.event)
    |> Enum.sort_by(& &1.event)
  end

  # ---------------------------------------------------------------------------
  # Private: core :active events
  # ---------------------------------------------------------------------------

  # Builds the 5 confirmed emitting span prefixes as :active event_doc entries.
  # Each span expands to a single entry with the prefix (not the :start/:stop/:exception suffixes).
  # Called at call time — NOT a module attribute (D-05 runtime aggregation, avoids stale-.beam).
  defp build_active_events do
    [
      %{
        event: [:crosswake, :companion, :dependency_check],
        tier: :active,
        description:
          "Emitted when RouteGate checks a companion's optional dependency presence. " <>
            "Start measurements include system_time, companion_id, and route_id. " <>
            "Stop measurements include duration, companion_id, and route_id.",
        measurements: [:system_time, :companion_id, :route_id, :duration],
        metadata: []
      },
      %{
        event: [:crosswake, :companion, :kill_switch],
        tier: :active,
        description:
          "Emitted when RouteGate evaluates a companion's kill switch. " <>
            "Short-circuits ahead of route_gate evaluation. " <>
            "Start measurements include system_time, companion_id, and route_id. " <>
            "Stop measurements include duration, companion_id, and route_id.",
        measurements: [:system_time, :companion_id, :route_id, :duration],
        metadata: []
      },
      %{
        event: [:crosswake, :companion, :route_gate],
        tier: :active,
        description:
          "Emitted when RouteGate evaluates a companion's route policy. " <>
            "Start measurements include system_time, companion_id, and route_id. " <>
            "Stop measurements include duration, companion_id, and route_id.",
        measurements: [:system_time, :companion_id, :route_id, :duration],
        metadata: []
      },
      %{
        event: [:crosswake, :companion, :validate_dependency],
        tier: :active,
        description:
          "Emitted when Doctor runs validate_dependency/0 for each registered companion. " <>
            "Start measurements include system_time, companion_id, and route_id. " <>
            "Stop measurements include duration, companion_id, route_id, and result.",
        measurements: [:system_time, :companion_id, :route_id, :duration, :result],
        metadata: []
      },
      %{
        event: [:crosswake, :threadline, :request],
        tier: :active,
        description:
          "Emitted by Plug.Threadline for each incoming HTTP request correlation span. " <>
            "Start measurements include system_time. " <>
            "Stop measurements include duration. " <>
            "Metadata includes thread_id, correlation_id, route_id, and source.",
        measurements: [:system_time, :duration],
        metadata: [:thread_id, :correlation_id, :route_id, :source]
      }
    ]
  end

  # ---------------------------------------------------------------------------
  # Private: reserved events
  # ---------------------------------------------------------------------------

  # Builds :reserved event_doc entries from in-tree Sigra and Chimeway telemetry modules.
  # Sigra: 14 event_names/0 entries; Chimeway: 10 event_names/0 entries.
  # tier: :reserved — declared but not yet emitted; excluded from the declared=>emitted
  # half of the TELEM-04 contract test.
  # NOTE: Offline.Telemetry is intentionally NOT included — it has no event_names/0
  # function and would raise UndefinedFunctionError if called.
  defp build_reserved_events do
    Enum.map(
      Crosswake.Companions.Sigra.Telemetry.event_names() ++
        Crosswake.Companions.Chimeway.Telemetry.event_names(),
      fn name ->
        %{event: name, tier: :reserved, description: "", measurements: [], metadata: []}
      end
    )
  end
end
