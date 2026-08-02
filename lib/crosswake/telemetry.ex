defmodule Crosswake.Telemetry do
  @moduledoc """
  Canonical public API for Crosswake telemetry events.

  `events/0` returns the runtime-aggregated catalog of every `:telemetry`
  event Crosswake emits across companion spans, doctor, threadline, sigra,
  chimeway, and bridge subsystems. Call it at runtime — not at compile time.

  Telemetry events are **public API**: additions are non-breaking minors;
  removals or renames are breaking majors requiring a semver major bump.

  **Diagnostic-only.** This module is NOT an APM replacement, NOT a
  distributed tracing framework, and NOT a generic event bus. It augments
  host observability by exposing a typed, low-cardinality, PII-free event
  catalog. It coexists with any host-side observability pipeline.

  Zero new dependencies — only `:telemetry`, already a project dependency.
  """

  require Logger
  alias Crosswake.Offline.SafeObservation

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

  # The 11-atom core PII baseline denylist (D-136-A / DECOUPLE-05 / D-5 Phase 139).
  # Always applied regardless of companion presence — an absent/misconfigured companion
  # can never silently drop token/identity scrubbing.
  # Semver contract: adding a key = minor (stricter safety); removing a key = major (weaker safety).
  #
  # Phase 139 curated universal-floor delta: added :actor_ref — the HMAC-anonymized audit
  # identity anchor used by the audit ledger. This is a universal-floor key (auth/identity
  # concept, not OAuth/passkey-ceremony domain) that must be scrubbed even with zero companions
  # registered. OAuth/passkey-ceremony keys (device/org/credential/PKCE/provider minutiae) are
  # companion-domain and stay companion-local — they are scrubbed at emission by the companion,
  # not at the core baseline level (D-5 boundary: universal floor ≠ companion domain).
  @baseline_forbidden_keys [
    # auth tokens — catastrophic if leaked from any event / any companion
    :access_token,
    :refresh_token,
    :id_token,
    :authorization_code,
    :token,
    # identity anchors — cross-event re-identification
    :session_ref,
    :subject_ref,
    :actor_id,
    # direct PII — GDPR/CCPA; appears in core route events
    :ip,
    :email,
    # universal-floor audit identity anchor — HMAC-anonymized actor reference (Phase 139 / D-5)
    :actor_ref
  ]

  @doc """
  Returns the 11-atom baseline PII forbidden-metadata-key denylist owned by core.

  These keys are always scrubbed from telemetry metadata regardless of whether any companion
  is registered. Companions may declare additional forbidden keys via their
  `forbidden_metadata_keys/0` callback; those are unioned with this baseline at attach time.

  Phase 139 added `:actor_ref` as the curated universal-floor delta (D-5): the HMAC-anonymized
  audit identity anchor that must be scrubbed even with zero companions registered.

  **Semver contract:** adding a key is a non-breaking minor (stricter safety);
  removing a key is a breaking major (weaker safety).
  """
  @spec baseline_forbidden_metadata_keys() :: [atom()]
  def baseline_forbidden_metadata_keys, do: @baseline_forbidden_keys

  @doc """
  Returns the runtime-aggregated catalog of all Crosswake telemetry events.

  Builds the catalog at call time by concatenating:
  1. Core `:active` span docs for the 5 confirmed emitting prefixes
  2. `:reserved` docs aggregated at runtime from each registered companion's
     `telemetry_events/0` callback (guarded by `function_exported?/3`) — zero static
     companion references (DECOUPLE-01)
  3. Additional companion docs from `Application.get_env(:crosswake, :companions, [])`
     merged via `function_exported?(mod, :telemetry_events, 0)` (D-07, TELEM-04)

  The result is de-duplicated by event prefix and sorted (D-06).

  Fail-closed (D-10): with no companions configured, returns core events only and
  never raises. The `:reserved` tier will be empty — that is correct and expected.
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
        event: [:crosswake, :offline, :replay],
        tier: :active,
        description: "Emitted for a closed scoped-replay observation.",
        measurements: [:attempt_count, :event_count, :duration_ms],
        metadata: [:route_id, :runtime, :lifecycle, :outcome, :denial]
      },
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
      },
      %{
        event: [:crosswake, :bridge, :push],
        tier: :active,
        description:
          "Emitted when Crosswake.Bridge.push/3 dispatches a bounded capability to the " <>
            "native shell. Start measurements include system_time; stop measurements " <>
            "include duration. Metadata includes route_id, capability, and command — " <>
            "never the adopter-supplied ref, which stays library-internal and never " <>
            "enters telemetry (D-20).",
        measurements: [:system_time, :duration],
        metadata: [:route_id, :capability, :command]
      },
      %{
        event: [:crosswake, :bridge, :reply],
        tier: :active,
        description:
          "Emitted when a bridge ask resolves to a delivered reply (ok or deny) — whether " <>
            "or not the adopter passed a ref: and receives it in handle_info/2 (D-21). " <>
            "Start measurements include system_time; stop measurements include duration. " <>
            "Metadata includes route_id, command, and status; deny replies also carry " <>
            "denial_reason, drawn from the closed 14-reason Crosswake.Shell.Denial " <>
            "vocabulary, never a free string.",
        measurements: [:system_time, :duration],
        metadata: [:route_id, :command, :status, :denial_reason]
      },
      %{
        event: [:crosswake, :bridge, :dropped],
        tier: :active,
        description:
          "Emitted when a reply, unreachable fact, or timer message arrives for a " <>
            "correlation id no longer in flight — a duplicate delivery, or a reply minted " <>
            "under a prior per-mount epoch (the LiveView reconnected since it was " <>
            "dispatched). Start measurements include system_time; stop measurements " <>
            "include duration. Metadata includes route_id and reason (:duplicate or " <>
            ":foreign_epoch).",
        measurements: [:system_time, :duration],
        metadata: [:route_id, :reason]
      },
      %{
        event: [:crosswake, :bridge, :hook_ack],
        tier: :active,
        description:
          "Emitted when the bridge hook's acknowledgement arrives before the server-armed " <>
            "wiring deadline. Start measurements include system_time; stop measurements " <>
            "include duration. Metadata includes route_id.",
        measurements: [:system_time, :duration],
        metadata: [:route_id]
      },
      %{
        event: [:crosswake, :bridge, :hook_missing],
        tier: :active,
        description:
          "Emitted when no acknowledgement arrives before the server-armed wiring " <>
            "deadline elapses — the bridge hook is not wired on this page at all. This " <>
            "count should always be zero in a healthy deploy; a nonzero rate means some " <>
            "page is missing the hook script tag or the phx-hook attribute. Start " <>
            "measurements include system_time; stop measurements include duration. " <>
            "Metadata includes route_id.",
        measurements: [:system_time, :duration],
        metadata: [:route_id]
      }
    ]
  end

  # ---------------------------------------------------------------------------
  # Private: reserved events
  # ---------------------------------------------------------------------------

  # Builds :reserved event_doc entries by aggregating companion telemetry_events/0 callbacks
  # at runtime via the :companions registry (DECOUPLE-01). Zero static Sigra/Chimeway references.
  # tier: :reserved — declared but not yet emitted; excluded from the declared=>emitted
  # half of the TELEM-04 contract test.
  # With no companions registered, returns [] — the reserved tier is legitimately empty (D-136-D).
  defp build_reserved_events do
    Application.get_env(:crosswake, :companions, [])
    |> Enum.flat_map(fn mod ->
      if function_exported?(mod, :telemetry_events, 0) do
        mod.telemetry_events()
        |> Enum.filter(fn event -> Map.get(event, :tier) == :reserved end)
      else
        []
      end
    end)
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

    # Build the forbidden-key MapSet ONCE at attach time and capture in the handler closure
    # (D-136-A / DECOUPLE-05 / Phase 139 SITE 2). Baseline is always unioned regardless of
    # companion presence. Companion keys come from the :companions registry via function_exported?/3.
    # Phase 139: the static compile-time Crosswake.Threadline.Telemetry.forbidden_metadata_keys()
    # call is removed. The universal-floor baseline now includes :actor_ref (curated D-5 delta).
    # Companion-domain OAuth/passkey keys stay companion-local, scrubbed at emission by the companion.
    companion_forbidden_keys =
      Application.get_env(:crosswake, :companions, [])
      |> Enum.flat_map(fn mod ->
        if function_exported?(mod, :forbidden_metadata_keys, 0),
          do: mod.forbidden_metadata_keys(),
          else: []
      end)

    forbidden_keys =
      MapSet.union(
        MapSet.new(@baseline_forbidden_keys),
        MapSet.new(companion_forbidden_keys)
      )

    # Pass a map (not a keyword list) as the handler config so the test can inspect
    # handler.config[:forbidden_keys] to verify attach-time capture (DECOUPLE-05).
    handler_config = %{
      level: Keyword.get(opts, :level, :info),
      encode: Keyword.get(opts, :encode, false),
      forbidden_keys: forbidden_keys
    }

    :telemetry.attach_many(
      "crosswake-default-logger",
      active_event_names,
      &__MODULE__.__handle_event__/4,
      handler_config
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

  @doc false
  @spec emit_safe_observation(SafeObservation.t()) :: :ok
  def emit_safe_observation(%SafeObservation{} = observation) do
    metadata = SafeObservation.to_telemetry(observation)
    measurements = Map.take(metadata, [:attempt_count, :event_count, :duration_ms])

    :telemetry.execute(
      [:crosswake, :offline, :replay, :stop],
      measurements,
      Map.drop(metadata, Map.keys(measurements))
    )
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
  # D-15: All PII keys (union of baseline + companion forbidden_metadata_keys/0 denylists)
  #       are scrubbed from metadata before logging. The forbidden-key MapSet is captured
  #       at attach time in the handler config — not re-aggregated per event (D-136-A).
  # D-20: Log messages are prefixed with "[crosswake]".
  @doc false
  def __handle_event__(event_name, measurements, metadata, config) do
    configured_level = Map.get(config, :level, :info)
    encode = Map.get(config, :encode, false)

    # D-14: force :error for :exception events regardless of configured level
    level =
      if List.last(event_name) == :exception do
        :error
      else
        configured_level
      end

    # D-15: scrub PII keys before logging — forbidden set captured at attach time (D-136-A)
    forbidden = Map.get(config, :forbidden_keys, MapSet.new(@baseline_forbidden_keys))
    scrubbed_metadata = Map.drop(metadata, MapSet.to_list(forbidden))

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
end
