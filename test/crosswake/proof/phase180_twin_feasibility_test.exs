defmodule Crosswake.Proof.Phase180TwinFeasibilityTest do
  use ExUnit.Case, async: true

  # Phase 180 feasibility gate, fact G1: can a route declare the host audio command?
  # Characterization only. No host.* capability is added to any production list.

  defp validate_with(capabilities) do
    route =
      Crosswake.Policy.Route.new!(
        id: "phase180-island",
        runtime: :offline_island,
        offline: :local_first,
        capabilities: capabilities,
        security: :standard
      )

    managed = [
      %{
        path: "/phase180-island",
        helper: "phase180-island",
        verb: :get,
        source: %{file: "test", line: 1}
      }
    ]

    Crosswake.Policy.Validator.validate([route], managed)
  end

  @tag phase180_gate: "G1"
  test "G1 gate: the host audio command on an offline_island route validates without errors" do
    assert validate_with(["host.study.audio.play"]) == []
  end

  @tag phase180_gate: "G1"
  test "G1 gate: an unknown core capability yields exactly one capabilities error" do
    assert [error] = validate_with(["not_a_core_capability"])
    assert error.key == :capabilities
    assert error.message =~ "unknown capability"
  end

  @tag phase180_control: "G1"
  test "G1 control: validator accepts a known capability without a capabilities error" do
    errors = validate_with(["share"])
    refute Enum.any?(errors, &(&1.key == :capabilities))
  end
end
