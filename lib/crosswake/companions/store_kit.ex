defmodule Crosswake.Companions.StoreKit do
  @moduledoc false

  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State

  @impl true
  @doc false
  def companion_id, do: :storekit

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
    if Code.ensure_loaded?(StoreKit) do
      :ok
    else
      {:error, [StoreKit]}
    end
  end

  @impl true
  @doc false
  def report_state do
    config = Application.get_env(:crosswake, :storekit, %{})
    enabled = Map.get(config, :enabled, false)

    dependency_status =
      if Code.ensure_loaded?(StoreKit) do
        :present
      else
        {:missing, [StoreKit]}
      end

    %State{
      companion_id: :storekit,
      enabled: enabled,
      dependency_status: dependency_status,
      gate_status: :unconfigured,
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond),
      details: %{surface: :commerce_provider, provider: :storekit, mode: :evidence_adapter}
    }
  end
end
