defmodule Crosswake.Offline.SafeObservationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.SafeObservation

  @valid %{route_id: "route-0123456789abcdef", runtime: :offline_island, lifecycle: :replayed,
           outcome: :accepted, denial: :none, measurements: %{event_count: 1},
           configuration: :configured, adapter_readiness: :blocked}

  test "constructs only declared bounded values and produces distinct exact projections" do
    assert {:ok, observation} = SafeObservation.new(@valid)
    assert SafeObservation.to_telemetry(observation) == %{route_id: "route-0123456789abcdef", runtime: :offline_island, lifecycle: :replayed, outcome: :accepted, denial: :none, event_count: 1}
    assert SafeObservation.to_doctor(observation) == %{configuration: :configured, adapter_readiness: :blocked}
  end

  test "rejects unknown keys without echoing the rejected value" do
    assert {:error, error} = SafeObservation.new(Map.put(@valid, :scope_ref, "CANARY-SCOPE"))
    assert error.rule_id == "CW-SAFE-OBSERVATION-KEY"
    refute inspect(error) =~ "CANARY"
  end
end
