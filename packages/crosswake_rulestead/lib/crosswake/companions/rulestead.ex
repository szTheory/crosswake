defmodule Crosswake.Companions.Rulestead do
  @moduledoc false

  @behaviour Crosswake.Companion

  # Required: optional: true alone does NOT silence the undefined-module warning
  # in the engine-ABSENT build (hermetic/COMPAT-01 state). Both are needed for
  # mix compile --warnings-as-errors to pass without the rulestead engine loaded (D-29).
  @compile {:no_warn_undefined, Rulestead}

  alias Crosswake.Companion.State
  alias Crosswake.Compatibility.Finding

  # ---------------------------------------------------------------------------
  # flag_source/0 — config-indirection (D-31)
  # lib/ references this indirection symbol, never the test MockFlagSource module.
  # Application.get_env/3 is evaluated at runtime, resolving the configured flag-
  # source module. In :test env, config.exs wires flag_source: MockFlagSource.
  # In production (nil default) the adaptor ships with no flag-source configured —
  # the honest "no flag source" state, already fail-closed-gated upstream by
  # validate_dependency/0 which fires first in RouteGate (D-02).
  # ---------------------------------------------------------------------------

  defp flag_source do
    Application.get_env(:crosswake, :rulestead_flag_source, nil)
  end

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
    fs = flag_source()

    # Nil-guard: if flag_source is not configured or not running, fail-open for gate
    # (do not block requests). Mirrors the pattern used in kill_switch_active?/1 and
    # report_state/0.
    case fs && Process.whereis(fs) do
      nil ->
        :pass

      _pid ->
        case fs.get_flag(route.gated_by) do
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
    fs = flag_source()

    # Nil-guard: if flag_source is not configured or not running, treat kill switch
    # as inactive (fail-closed on the "don't block requests" side — the companion is
    # the further-restrictor; if it can't check, it should not silently fail-open).
    case fs && Process.whereis(fs) do
      nil ->
        false

      _pid ->
        # Phase 42 simplification: scan all stored flags for any :killed state.
        # This is correct for a single-flag demo but would need refinement for
        # multi-flag scenarios where only some flags should activate the kill switch.
        fs
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
    # EXTRACT-04-clean: probe is inside a function body, not at module-eval time.
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
    fs = flag_source()

    dependency_status =
      # EXTRACT-04-clean: probe is inside a function body, not at module-eval time.
      if Code.ensure_loaded?(Rulestead) do
        :present
      else
        {:missing, [Rulestead]}
      end

    # Read the most-restrictive stored gate state from the configured flag source.
    # Precedence: :killed > :gated/:rolling_out > nil (unconfigured).
    # Guard with Process.whereis nil-check; default to unconfigured pairing when
    # the flag source is not running.
    {gate_status, kill_switch_status} =
      case fs && Process.whereis(fs) do
        nil ->
          {:unconfigured, :unconfigured}

        _pid ->
          values = Agent.get(fs, &Map.values/1)

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
