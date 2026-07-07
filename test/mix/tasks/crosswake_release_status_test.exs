defmodule Mix.Tasks.Crosswake.Release.StatusTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @governance_check_codes ~w(
    release.governance_queue_max
    release.governance_behavioral_identity_gates
    release.governance_cleanup_after_proof
  )

  test "release status reports local graph and guard checks" do
    status = Crosswake.ReleaseStatus.build()

    assert status.schema_version == "1.0.0"
    assert Enum.any?(status.core, &(&1.component == "hex"))
    assert Enum.any?(status.companions, &(&1.package == "crosswake_sigra"))
    assert Enum.any?(status.checks, &(&1.code == "release.workflow_path_gates"))
    assert Enum.any?(status.checks, &(&1.code == "release.cleanroom_dependency_floor"))

    for code <- @governance_check_codes do
      assert Enum.any?(status.checks, &(&1.code == code))
    end
  end

  test "human task output names package-family release posture" do
    output =
      capture_io(fn ->
        try do
          Mix.Task.clear()
          Mix.Tasks.Crosswake.Release.Status.run([])
        rescue
          Mix.Error -> :ok
        end
      end)

    assert output =~ "Crosswake release status"
    assert output =~ "Core/native lockstep"
    assert output =~ "Companions"
    assert output =~ "Checks:"
    assert output =~ "release.workflow_path_gates"

    for code <- @governance_check_codes do
      assert output =~ code
    end
  end

  test "json task output is scriptable" do
    output =
      capture_io(fn ->
        try do
          Mix.Task.clear()
          Mix.Tasks.Crosswake.Release.Status.run(["--json"])
        rescue
          Mix.Error -> :ok
        end
      end)

    decoded = Jason.decode!(output)

    assert decoded["schema_version"] == "1.0.0"
    assert is_list(decoded["core"])
    assert is_list(decoded["companions"])
    assert Enum.any?(decoded["checks"], &(&1["code"] == "release.release_as_staleness"))

    for code <- @governance_check_codes do
      assert Enum.any?(decoded["checks"], &(&1["code"] == code))
    end
  end

  test "live probes surface missing published artifacts as warnings" do
    status =
      Crosswake.ReleaseStatus.build(
        live?: true,
        http_probe: fn url -> String.contains?(url, "/crosswake/releases/") end,
        git_ref_probe: fn _remote, _ref -> false end
      )

    assert status.status == :warning

    assert %{status: :warning, message: message} =
             Enum.find(status.checks, &(&1.code == "release.live_registry_presence"))

    assert message =~ "ios-core@0.2.0 on ios_mirror"
    assert message =~ "crosswake_sigra@0.1.1 on hex"
  end
end
