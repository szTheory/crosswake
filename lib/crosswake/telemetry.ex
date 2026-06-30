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

  require Logger

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
            "Start measurements include system_time; stop measurements include duration. " <>
            "Metadata includes companion_id and route_id (Keathley span convention).",
        measurements: [:system_time, :duration],
        metadata: [:companion_id, :route_id]
      },
      %{
        event: [:crosswake, :companion, :kill_switch],
        tier: :active,
        description:
          "Emitted when RouteGate evaluates a companion's kill switch. " <>
            "Short-circuits ahead of route_gate evaluation. " <>
            "Start measurements include system_time; stop measurements include duration. " <>
            "Metadata includes companion_id and route_id (Keathley span convention).",
        measurements: [:system_time, :duration],
        metadata: [:companion_id, :route_id]
      },
      %{
        event: [:crosswake, :companion, :route_gate],
        tier: :active,
        description:
          "Emitted when RouteGate evaluates a companion's route policy. " <>
            "Start measurements include system_time; stop measurements include duration. " <>
            "Metadata includes companion_id and route_id (Keathley span convention).",
        measurements: [:system_time, :duration],
        metadata: [:companion_id, :route_id]
      },
      %{
        event: [:crosswake, :companion, :validate_dependency],
        tier: :active,
        description:
          "Emitted when Doctor runs validate_dependency/0 for each registered companion. " <>
            "Start measurements include system_time; stop measurements include duration. " <>
            "Metadata includes companion_id and route_id; stop metadata also includes result.",
        measurements: [:system_time, :duration],
        metadata: [:companion_id, :route_id, :result]
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

  # ---------------------------------------------------------------------------
  # Public: opt-in default logger (TELEM-03)
  # ---------------------------------------------------------------------------

  @doc """
  Attaches a structured default logger to all `:active` Crosswake telemetry events.

  Accepts a `Logger.level()` atom or a keyword list of options:
  - `:level` — log level for non-exception events (default: `:info`)
  - `:encode` — when `true`, JSON-encodes the event map into the log message;
    when `false` (default, D-14), places the structured map in Logger metadata
    so host formatters can handle JSON encoding (D-14).

  Attaches under handler id `"crosswake-default-logger"`. Returns `:ok` on success;
  returns `{:error, :already_exists}` if the handler is already attached (D-13:
  relies on `:telemetry`'s built-in guard — no custom double-attach guard added here).

  Core never calls this function automatically. Attachment is always the host's
  explicit decision (TELEM-03 / D-13).

  ## Examples

      # Attach with default opts (level: :info, encode: false)
      Crosswake.Telemetry.attach_default_logger()

      # Attach with a specific log level
      Crosswake.Telemetry.attach_default_logger(:debug)

      # Attach with keyword options
      Crosswake.Telemetry.attach_default_logger(level: :info, encode: false)

  """
  @spec attach_default_logger(Logger.level() | keyword()) :: :ok | {:error, :already_exists}
  def attach_default_logger(level_or_opts \\ []) do
    opts = normalize_opts(level_or_opts)

    active_event_names =
      events()
      |> Enum.filter(fn %{tier: tier} -> tier == :active end)
      |> Enum.flat_map(fn %{event: prefix} ->
        [prefix ++ [:start], prefix ++ [:stop], prefix ++ [:exception]]
      end)

    :telemetry.attach_many(
      "crosswake-default-logger",
      active_event_names,
      &__MODULE__.__handle_event__/4,
      opts
    )
  end

  @doc """
  Detaches the default Crosswake telemetry logger handler.

  Returns `:ok` if the handler was attached and is now removed.
  Returns `{:error, :not_found}` if no handler with id `"crosswake-default-logger"` exists.
  """
  @spec detach_default_logger() :: :ok | {:error, :not_found}
  def detach_default_logger do
    :telemetry.detach("crosswake-default-logger")
  end

  # ---------------------------------------------------------------------------
  # Private: handler, opts normalization, PII scrub
  # ---------------------------------------------------------------------------

  # The telemetry handler function. Must be public so :telemetry can call it via
  # a stable MFA reference (avoids the local-function performance advisory).
  # Named with double underscores to signal it is not part of the public contract.
  #
  # D-14: :exception-suffixed events are always logged at :error regardless of
  #       configured level.
  # D-14: encode: false (default) — emits structured map into Logger metadata;
  #       encode: true — JSON-encodes map into message string.
  # D-15: All PII keys (union of subsystem forbidden_metadata_keys/0 denylists)
  #       are scrubbed from metadata before logging.
  # D-20: Log messages are prefixed with "[crosswake]".
  @doc false
  def __handle_event__(event_name, measurements, metadata, opts) do
    configured_level = Keyword.get(opts, :level, :info)
    encode = Keyword.get(opts, :encode, false)

    # D-14: force :error for :exception events regardless of configured level
    level =
      if List.last(event_name) == :exception do
        :error
      else
        configured_level
      end

    # D-15: scrub PII keys before logging
    forbidden = all_forbidden_keys()
    scrubbed_metadata = Map.drop(metadata, forbidden)

    event_label = Enum.join(event_name, ".")

    if encode do
      payload =
        %{
          event: event_label,
          measurements: measurements,
          metadata: scrubbed_metadata
        }
        |> Jason.encode!()

      Logger.log(level, "[crosswake] #{payload}")
    else
      context = %{
        event: event_label,
        measurements: measurements,
        metadata: scrubbed_metadata
      }

      Logger.metadata(crosswake_telemetry: context)
      Logger.log(level, "[crosswake] #{event_label}")
    end
  end

  # Normalizes the level_or_opts argument for attach_default_logger/1.
  # Accepts a Logger.level() atom (shorthand) or a keyword list.
  # Default opts: level: :info, encode: false (D-14).
  defp normalize_opts(level) when is_atom(level) do
    [level: level, encode: false]
  end

  defp normalize_opts(opts) when is_list(opts) do
    opts
    |> Keyword.put_new(:level, :info)
    |> Keyword.put_new(:encode, false)
  end

  # Returns the runtime union of PII-forbidden metadata keys from all subsystem
  # telemetry modules (D-15). Reuses existing forbidden_metadata_keys/0 functions;
  # does not duplicate the denylist.
  defp all_forbidden_keys do
    (Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++
       Crosswake.Companions.Sigra.Telemetry.forbidden_metadata_keys() ++
       Crosswake.Companions.Chimeway.Telemetry.forbidden_metadata_keys())
    |> Enum.uniq()
  end
end
