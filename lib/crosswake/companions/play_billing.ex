defmodule Crosswake.Companions.PlayBilling do
  @moduledoc false

  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State

  @impl true
  @doc false
  def companion_id, do: :play_billing

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
    if Code.ensure_loaded?(PlayBillingClient) do
      :ok
    else
      {:error, [PlayBillingClient]}
    end
  end

  @impl true
  @doc false
  def report_state do
    config = Application.get_env(:crosswake, :play_billing, %{})
    enabled = Map.get(config, :enabled, false)

    dependency_status =
      if Code.ensure_loaded?(PlayBillingClient) do
        :present
      else
        {:missing, [PlayBillingClient]}
      end

    %State{
      companion_id: :play_billing,
      enabled: enabled,
      dependency_status: dependency_status,
      gate_status: :unconfigured,
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond),
      details: %{surface: :commerce_provider, provider: :play_billing, mode: :evidence_adapter}
    }
  end
end
