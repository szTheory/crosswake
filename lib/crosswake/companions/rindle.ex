defmodule Crosswake.Companions.Rindle do
  @moduledoc false

  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State

  @impl true
  @doc false
  def companion_id, do: :rindle

  @impl true
  @doc false
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  @doc false
  def route_gated?(_route, _target), do: :pass

  @impl true
  @doc false
  def kill_switch_active?(_target), do: false

  @impl true
  @doc false
  def validate_dependency do
    if Code.ensure_loaded?(Rindle) do
      :ok
    else
      {:error, [Rindle]}
    end
  end

  @impl true
  @doc false
  def report_state do
    config = Application.get_env(:crosswake, :rindle, %{})
    enabled = Map.get(config, :enabled, false)

    dependency_status =
      if Code.ensure_loaded?(Rindle) do
        :present
      else
        {:missing, [Rindle]}
      end

    %State{
      companion_id: :rindle,
      enabled: enabled,
      dependency_status: dependency_status,
      gate_status: :unconfigured,
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond),
      details: %{surface: :media, mode: :contract_only}
    }
  end
end
