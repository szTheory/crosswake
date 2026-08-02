defmodule Crosswake.Offline.SafeObservationTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.SafeObservation

  @valid %{
    route_id: "route-0123456789abcdef",
    runtime: :offline_island,
    lifecycle: :replayed,
    outcome: :accepted,
    denial: :none,
    measurements: %{event_count: 1},
    configuration: :configured,
    adapter_readiness: :blocked
  }

  test "constructs only declared bounded values and produces distinct exact projections" do
    assert {:ok, observation} = SafeObservation.new(@valid)

    assert {:ok, telemetry} = SafeObservation.to_telemetry(observation)

    assert telemetry == %{
             route_id: "route-0123456789abcdef",
             runtime: :offline_island,
             lifecycle: :replayed,
             outcome: :accepted,
             denial: :none,
             event_count: 1
           }

    assert {:ok, doctor} = SafeObservation.to_doctor(observation)

    assert doctor == %{
             configuration: :configured,
             adapter_readiness: :blocked
           }
  end

  test "rejects unknown keys without echoing the rejected value" do
    assert {:error, error} = SafeObservation.new(Map.put(@valid, :scope_ref, "CANARY-SCOPE"))
    assert error.rule_id == "CW-SAFE-OBSERVATION-KEY"
    refute inspect(error) =~ "CANARY"
  end

  test "revalidates every forged struct projection without echoing a canary" do
    forged_cases = [
      %{field: :route_id, value: "CANARY-ROUTE"},
      %{field: :outcome, value: :canary_outcome},
      %{field: :adapter_readiness, value: :canary_readiness},
      %{field: :measurements, value: %{event_count: "CANARY-MEASUREMENT"}},
      %{field: :measurements, value: %{event_count: 1, nested: %{canary: "CANARY-NESTED"}}},
      %{field: :extra_field, value: "CANARY-EXTRA"}
    ]

    for %{field: field, value: value} <- forged_cases do
      forged =
        case field do
          :extra_field -> Map.put(struct!(SafeObservation, @valid), field, value)
          _ -> Map.put(struct!(SafeObservation, @valid), field, value)
        end

      for projection <- [
            &SafeObservation.to_telemetry/1,
            &SafeObservation.to_logger/1,
            &SafeObservation.to_doctor/1
          ] do
        assert {:error, error} = projection.(forged)
        assert %SafeObservation.Error{rule_id: rule_id, path: path} = error
        assert is_binary(rule_id)
        assert is_atom(path)
        refute inspect(error) =~ "CANARY"
      end
    end
  end
end
