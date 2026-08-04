defmodule Mix.Tasks.Crosswake.ProofLane.VerifyNavigationShellTest do
  use ExUnit.Case, async: false

  @task "crosswake.proof_lane.verify_navigation_shell"

  test "retains a canonical digest-bound advisory artifact" do
    destination =
      Path.join(
        System.tmp_dir!(),
        "crosswake-navigation-shell-#{System.unique_integer([:positive])}"
      )

    on_exit(fn -> File.rm_rf(destination) end)

    Mix.Task.reenable(@task)
    assert :ok = Mix.Task.run(@task, ["--destination", destination])

    assert {:ok, bytes} = File.read(Path.join(destination, "proof-lane-evidence.json"))
    assert {:ok, _evidence} = Jason.decode(bytes)
  end
end
