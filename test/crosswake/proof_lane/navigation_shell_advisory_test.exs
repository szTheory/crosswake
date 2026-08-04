defmodule Crosswake.ProofLane.NavigationShellAdvisoryTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.NavigationShellAdvisory

  @ids ~w(PL-IOS-NAV-TOPOLOGY PL-IOS-NAV-PATCH-DEPTH PL-IOS-NAV-NAVIGATE-ONCE PL-IOS-NAV-RESTORE PL-IOS-NAV-TABS-BACK PL-IOS-NAV-MARKER-INSETS PL-IOS-NAV-FOCUS)

  test "derives passed assertions only from an exact canonical current-run observation" do
    bytes = observation_bytes()

    assert {:ok, advisory} = NavigationShellAdvisory.build(bytes)

    assert %{
             "assertions" => assertions,
             "observation_digest" => digest,
             "subject_digests" => subject_digests
           } = NavigationShellAdvisory.to_map(advisory)

    assert Map.keys(assertions) |> Enum.sort() == Enum.sort(@ids)
    assert Enum.all?(assertions, fn {_id, outcome} -> outcome == "passed" end)
    assert String.match?(digest, ~r/\A[a-f0-9]{64}\z/)
    assert subject_digests != %{}

    assert {:ok, ^advisory} =
             NavigationShellAdvisory.decode(NavigationShellAdvisory.encode!(advisory))
  end

  test "rejects missing, duplicate, reordered, unknown, widened, raw, and non-canonical observations" do
    for invalid <- [
          observation_bytes(%{"assertion_ids" => Enum.drop(@ids, -1)}),
          observation_bytes(%{"assertion_ids" => @ids ++ [List.last(@ids)]}),
          observation_bytes(%{"assertion_ids" => Enum.reverse(@ids)}),
          observation_bytes(%{"assertion_ids" => List.replace_at(@ids, 0, "PL-IOS-NAV-UNKNOWN")}),
          observation_bytes(%{"outcome" => "blocked"}),
          observation_bytes(%{"scope" => "physical-device"}),
          Jason.encode!(Map.put(observation_map(), "raw_output", "CANARY")),
          " " <> observation_bytes()
        ] do
      assert {:error, error} = NavigationShellAdvisory.build(invalid)
      refute inspect(error) =~ "CANARY"
    end
  end

  defp observation_bytes(overrides \\ %{}),
    do: Jason.encode!(Map.merge(observation_map(), overrides))

  defp observation_map do
    %{
      "assertion_ids" => @ids,
      "outcome" => "passed",
      "run_nonce" => String.duplicate("a", 64),
      "schema_version" => 1,
      "scope" => "advisory"
    }
  end
end
