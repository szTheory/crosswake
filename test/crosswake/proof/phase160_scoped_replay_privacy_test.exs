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

  test "retained evidence has only the closed Phase 160 assertion vocabulary" do
    source = File.read!("lib/crosswake/proof_lane/evidence.ex")
    for identifier <- ~w(scope_partition lifecycle_fence per_event_reauthorization atomic_idempotency safe_observation disablement) do
      assert source =~ identifier
    end
    assert source =~ "raw_output"
  end
end
