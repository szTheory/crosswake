defmodule Crosswake.Companions.Rulestead do
  @moduledoc false

  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Companions.Rulestead.MockFlagSource

  # ---------------------------------------------------------------------------
  # companion_id/0
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def companion_id, do: :rulestead

  # ---------------------------------------------------------------------------
  # enabled?/1
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def enabled?(config), do: Map.get(config, :enabled, false)

  # ---------------------------------------------------------------------------
  # route_gated?/2
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def route_gated?(route, _target) do
    # Nil-guard: if MockFlagSource is not running, fail-open for gate (do not block requests).
    # Mirrors the pattern used in kill_switch_active?/1 and report_state/0.
    case Process.whereis(MockFlagSource) do
      nil ->
        :pass

      _pid ->
        case MockFlagSource.get_flag(route.gated_by) do
          :gated ->
            {:deny,
             %Finding{
               axis: :gate_denied,
               route_id: route.id,
               message: "#{route.gated_by} is gated",
               subject: "GATED"
             }}

          {:rolling_out, _pct} ->
            # Phase 42: rolling_out denies the route — no partial traffic-splitting yet.
            # gate_status is {:rolling_out, pct} in report_state/0 but the route is
            # still denied (the companion does not yet support percentage-based routing).
            {:deny,
             %Finding{
               axis: :gate_denied,
               route_id: route.id,
               message: "#{route.gated_by} is rolling out (partial gate)",
               subject: "ROLLING_OUT"
             }}

          _ ->
            # nil (unknown flag) or any unrecognized value -> :pass (fail-open for gate)
            :pass
        end
    end
  end

  # ---------------------------------------------------------------------------
  # kill_switch_active?/1
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def kill_switch_active?(_target) do
    # Nil-guard: if MockFlagSource is not running, treat kill switch as inactive
    # (fail-closed on the "don't block requests" side — the companion is the
    # further-restrictor; if it can't check, it should not silently fail-open).
    case Process.whereis(MockFlagSource) do
      nil ->
        false

      _pid ->
        # Phase 42 simplification: scan all stored flags for any :killed state.
        # This is correct for a single-flag demo but would need refinement for
        # multi-flag scenarios where only some flags should activate the kill switch.
        MockFlagSource
        |> Agent.get(&Map.values/1)
        |> Enum.any?(&(&1 == :killed))
    end
  end

  # ---------------------------------------------------------------------------
  # validate_dependency/0
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def validate_dependency do
    # Check for the top-level Rulestead module (root of the rulestead Hex package).
    # In Phase 42, rulestead is deliberately absent from deps — this always returns
    # {:error, [Rulestead]}, which drives the SC#3a doctor :error finding.
    if Code.ensure_loaded?(Rulestead) do
      :ok
    else
      {:error, [Rulestead]}
    end
  end

  # ---------------------------------------------------------------------------
  # report_state/0
  # ---------------------------------------------------------------------------

  @impl true
  @doc false
  def report_state do
    config = Application.get_env(:crosswake, :rulestead, %{})
    enabled = Map.get(config, :enabled, false)

    dependency_status =
      if Code.ensure_loaded?(Rulestead) do
        :present
      else
        {:missing, [Rulestead]}
      end

    # Read the most-restrictive stored gate state from MockFlagSource.
    # Precedence: :killed > :gated/:rolling_out > nil (unconfigured).
    # Guard with Process.whereis nil-check; default to unconfigured pairing when
    # MockFlagSource is not running.
    {gate_status, kill_switch_status} =
      case Process.whereis(MockFlagSource) do
        nil ->
          {:unconfigured, :unconfigured}

        _pid ->
          values = Agent.get(MockFlagSource, &Map.values/1)

          cond do
            Enum.any?(values, &(&1 == :killed)) ->
              # kill switch overrides gate_status (Pitfall 3: gate_status: :inactive)
              {:inactive, :active}

            Enum.any?(values, fn
              :gated -> true
              {:rolling_out, _} -> true
              _ -> false
            end) ->
              # Find most-restrictive among gated / rolling_out
              rolling_out =
                Enum.find(values, fn
                  {:rolling_out, _} -> true
                  _ -> false
                end)

              if rolling_out do
                {rolling_out, :inactive}
              else
                {:active, :inactive}
              end

            true ->
              {:unconfigured, :unconfigured}
          end
      end

    %State{
      companion_id: :rulestead,
      enabled: enabled,
      dependency_status: dependency_status,
      gate_status: gate_status,
      kill_switch_status: kill_switch_status,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
