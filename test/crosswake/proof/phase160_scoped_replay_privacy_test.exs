defmodule Crosswake.Proof.Phase160ScopedReplayPrivacyTest do
  use ExUnit.Case, async: true

  @egress_sources ["lib/crosswake/offline/safe_observation.ex", "lib/crosswake/offline/telemetry.ex", "lib/crosswake/telemetry.ex", "lib/crosswake/doctor/doctor.ex"]

  test "every scoped-replay operational egress is explicitly safe-observation based" do
    for source <- @egress_sources, do: assert(File.read!(source) =~ "SafeObservation")
  end

  test "matrix cannot be made vacuous by removing an egress" do
    assert length(@egress_sources) == 4
    assert Enum.all?(@egress_sources, &File.exists?/1)
  end
end
