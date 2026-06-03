defmodule Crosswake.Companions.Chimeway do
  @moduledoc false

  @behaviour Crosswake.Companion

  alias Crosswake.Companion.State

  @impl true
  @doc false
  def companion_id, do: :chimeway

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
    config = Application.get_env(:crosswake, :chimeway, %{})

    %State{
      companion_id: :chimeway,
      enabled: enabled?(config),
      dependency_status: :present,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond),
      details: %{
        surface: :notification_contract,
        mode: :token_binding_contract,
        delivery_support: :not_shipped,
        open_routing: :active,
        raw_token_posture: :redacted
      }
    }
  end
end
