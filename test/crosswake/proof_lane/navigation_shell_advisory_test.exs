defmodule Crosswake.ProofLane.NavigationShellAdvisoryTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.NavigationShellAdvisory

  test "builds one closed canonical advisory with every code-owned subject digest" do
    assert {:ok, advisory} = NavigationShellAdvisory.build()

    assert %{
             "schema_version" => 1,
             "phase_id" => "161.1",
             "proof_class" => "advisory",
             "assertions" => assertions,
             "subject_digests" => subject_digests
           } = NavigationShellAdvisory.to_map(advisory)

    assert assertions != []
    assert subject_digests != %{}

    assert {:ok, ^advisory} =
             NavigationShellAdvisory.decode(NavigationShellAdvisory.encode!(advisory))
  end

  test "rejects non-canonical and sensitive advisory bytes without echoing input" do
    assert {:ok, advisory} = NavigationShellAdvisory.build()
    bytes = NavigationShellAdvisory.encode!(advisory)

    assert {:error, error} = NavigationShellAdvisory.decode(" " <> bytes)
    refute inspect(error) =~ "answer"

    assert {:error, error} =
             NavigationShellAdvisory.decode(String.replace(bytes, "advisory", "token"))

    refute inspect(error) =~ "token"
  end
end
