defmodule Crosswake.Companions.Sigra do
  @moduledoc false

  # In-tree Sigra companion facade — pre-extraction registration bridge.
  #
  # This module declares @behaviour Crosswake.Companion and delegates every
  # callback to the existing Crosswake.Companions.Sigra.* sub-modules. It is
  # registered via the `env: [companions: [...]]` key in mix.exs application/0
  # (Crosswake has no config/ dir; the idiomatic library mechanism is the env: key).
  #
  # Phase-137 extraction note: when Sigra is extracted to a standalone
  # crosswake_sigra package, THIS file is removed from core and the
  # `Crosswake.Companions.Sigra` entry is removed from mix.exs application/0 env:.
  # The companion package will ship its own registration instructions.

  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Evaluator
  alias Crosswake.Companions.Sigra.Telemetry, as: SigraTelemetry

  # ---------------------------------------------------------------------------
  # Required callbacks (mirror chimeway.ex conventions)
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def companion_id, do: :sigra

  @impl true
  @doc false
  def enabled?(config) when is_map(config) do
    Map.get(config, :enabled, Map.get(config, "enabled", true))
  end

  @impl true
  @doc false
  def route_gated?(_route, _target), do: :pass

  @impl true
  @doc false
  def kill_switch_active?(_target), do: false

  @impl true
  @doc false
  def validate_dependency, do: :ok

  @impl true
  @doc false
  def report_state do
    config = Application.get_env(:crosswake, :sigra, %{})

    %State{
      companion_id: :sigra,
      enabled: enabled?(config),
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond),
      details: %{
        surface: :session_authority_route_evaluator,
        mode: :backend_session_authority,
        auth_return_support: :shipped,
        step_up_support: :shipped,
        handoff_support: :shipped
      }
    }
  end

  # ---------------------------------------------------------------------------
  # Optional callbacks
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def auth_authority?, do: true

  @impl true
  @doc false
  def evaluate_auth(route, auth_context, opts) do
    case Evaluator.evaluate_route_auth(route, auth_context, opts) do
      {:allow, %Evaluator.Result{status: status, facts: facts}} ->
        # Project to a plain map for the {:allow, map()} contract. Omit the struct's
        # :denial field (always nil on the allow branch) so the allow response never
        # carries a misleading :denial key.
        {:allow, %{status: status, facts: facts}}

      {:deny, finding} ->
        # D-137-A: the Evaluator now emits %Finding{axis: :auth} natively (Plan 02).
        # The Plan 01 Denial→Finding shim is removed. The Finding passes through unchanged
        # and RouteGate translates it to a Denial via finding_to_denial/2.
        {:deny, finding}
    end
  end

  @impl true
  @doc false
  def denial_codes, do: DenialCodes.codes()

  @impl true
  @doc false
  def forbidden_metadata_keys, do: SigraTelemetry.forbidden_metadata_keys()

  @impl true
  @doc false
  def telemetry_events do
    SigraTelemetry.event_names()
    |> Enum.map(fn name ->
      %{
        event: name,
        tier: :reserved,
        description:
          "Sigra auth diagnostic event #{Enum.join(name, ".")} — emitted by the Sigra companion",
        measurements: [],
        metadata: SigraTelemetry.metadata_keys()
      }
    end)
  end

  # ---------------------------------------------------------------------------
  # Non-behaviour public accessors (consumed by SupportMatrix.auth_contract_truth/0)
  # These are plain functions — NOT @impl — because they are not part of the behaviour.
  # ---------------------------------------------------------------------------

  @doc false
  def telemetry_event_names, do: SigraTelemetry.event_names()

  @doc false
  def telemetry_metadata_keys, do: SigraTelemetry.metadata_keys()

  @doc false
  def safe_detail_keys, do: DenialCodes.allowed_detail_keys()
end
