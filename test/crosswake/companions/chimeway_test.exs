defmodule Crosswake.Companions.ChimewayTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companion.State
  alias Crosswake.Companions.Chimeway

  test "implements the companion contract with a chimeway id" do
    assert Chimeway.companion_id() == :chimeway
    assert Chimeway.enabled?(%{}) == true
    assert Chimeway.enabled?(%{enabled: false}) == false
    assert Chimeway.enabled?(%{"enabled" => false}) == false
    assert Chimeway.validate_dependency() == :ok
  end

  test "does not gate routes or activate kill switch in contract-only phase" do
    assert Chimeway.route_gated?(:route, :target) == :pass
    assert Chimeway.kill_switch_active?(:target) == false
  end

  test "reports notification state with active open_routing but no delivery claims" do
    assert %State{} = state = Chimeway.report_state()
    assert state.companion_id == :chimeway
    assert state.dependency_status == :present
    assert state.gate_status == :unconfigured
    assert state.kill_switch_status == :unconfigured

    assert state.details == %{
             surface: :notification_contract,
             mode: :token_binding_contract,
             delivery_support: :not_shipped,
             open_routing: :active,
             raw_token_posture: :redacted
           }
  end
end
