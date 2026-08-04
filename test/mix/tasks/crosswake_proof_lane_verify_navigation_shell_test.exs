defmodule Mix.Tasks.Crosswake.ProofLane.VerifyNavigationShellTest do
  use ExUnit.Case, async: false

  @task "crosswake.proof_lane.verify_navigation_shell"
  @ids ~w(PL-IOS-NAV-TOPOLOGY PL-IOS-NAV-PATCH-DEPTH PL-IOS-NAV-NAVIGATE-ONCE PL-IOS-NAV-RESTORE PL-IOS-NAV-TABS-BACK PL-IOS-NAV-MARKER-INSETS PL-IOS-NAV-FOCUS)

  test "retains canonical evidence only from an invocation-owned observation and invalidates it" do
    {root, destination, observation} = run_fixture()
    on_exit(fn -> File.rm_rf(root) end)

    Mix.Task.reenable(@task)

    assert is_nil(
             Mix.Task.run(@task, [
               "--destination",
               destination,
               "--run-root",
               root,
               "--observation",
               observation
             ])
           )

    assert {:ok, bytes} = File.read(Path.join(destination, "proof-lane-evidence.json"))
    assert {:ok, evidence} = Jason.decode(bytes)
    assert [%{"kind" => "navigation_shell_advisory"}] = evidence["approved_hashes"]
    refute File.exists?(observation)
    refute File.exists?(Path.join(root, ".navigation-shell-run-nonce"))
  end

  test "rejects stale, forged, symlinked, duplicate, reordered, and subject-raced current-run inputs" do
    for mode <- [:stale, :forged, :symlink, :duplicate, :reordered] do
      {root, destination, observation} = run_fixture(mode)
      on_exit(fn -> File.rm_rf(root) end)
      Mix.Task.reenable(@task)

      assert_raise Mix.Error, "navigation_shell.verification_failed", fn ->
        Mix.Task.run(@task, [
          "--destination",
          destination,
          "--run-root",
          root,
          "--observation",
          observation
        ])
      end
    end
  end

  defp run_fixture(mode \\ :valid) do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-navigation-shell-#{System.unique_integer([:positive])}"
      )

    destination = Path.join(root, "retained")
    observation = Path.join(root, "navigation-shell-observation.json")
    File.mkdir_p!(root)
    File.chmod!(root, 0o700)

    nonce = String.duplicate("a", 64)
    File.write!(Path.join(root, ".navigation-shell-run-nonce"), nonce)

    File.write!(
      observation,
      observation_bytes(if(mode == :stale, do: String.duplicate("b", 64), else: nonce))
    )

    case mode do
      :forged ->
        File.write!(observation, "{}")

      :symlink ->
        target = Path.join(root, "elsewhere.json")
        File.write!(target, observation_bytes(nonce))
        File.rm!(observation)
        File.ln_s!(target, observation)

      :duplicate ->
        File.write!(observation, observation_bytes(nonce, @ids ++ [List.last(@ids)]))

      :reordered ->
        File.write!(observation, observation_bytes(nonce, Enum.reverse(@ids)))

      _ ->
        :ok
    end

    {root, destination, observation}
  end

  defp observation_bytes(nonce, ids \\ @ids) do
    Jason.encode!(%{
      "assertion_ids" => ids,
      "outcome" => "passed",
      "run_nonce" => nonce,
      "schema_version" => 1,
      "scope" => "advisory"
    })
  end
end
