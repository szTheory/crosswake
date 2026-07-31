defmodule Mix.Tasks.Crosswake.Gen.ProofLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Config, Generator}

  defp config(root) do
    %Config{
      route_id: "route-0123456789abcdef",
      route_path: "/study/:id",
      indexed_db_database: "proof_lane",
      indexed_db_store: "mutations",
      mutation_id_path: "client_mutation_id",
      sync_path: "/study/sync",
      evidence_path: "/_proof/evidence",
      router: CrosswakeWeb.Router,
      ios_shell_root: Path.join(root, "native/ios")
    }
  end

  defp temporary_root do
    Path.join(System.tmp_dir!(), "crosswake-proof-lane-#{System.unique_integer([:positive])}")
  end

  defp snapshot(root) do
    root
    |> Path.join("**")
    |> Path.wildcard()
    |> Enum.map(fn path ->
      {Path.relative_to(path, root), if(File.dir?(path), do: :dir, else: File.read!(path))}
    end)
    |> Map.new()
  end

  defp with_root(fun) do
    root = temporary_root()
    File.mkdir_p!(root)

    try do
      fun.(root, config(root))
    after
      File.rm_rf!(root)
    end
  end

  test "reruns create only missing scaffold and preserve host bytes" do
    with_root(fn root, config ->
      assert {:ok, _} = Generator.generate(config)
      host_file = Path.join(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts")
      host_bytes = "// host-owned change\n"
      File.write!(host_file, host_bytes)
      missing_file = Path.join(root, "test/crosswake_proof_lane/crosswake_proof_lane_test.exs")
      File.rm!(missing_file)

      assert {:ok, results} = Generator.generate(config)

      assert %{path: "test/crosswake_proof_lane/crosswake_proof_lane_test.exs", status: :created} in results

      assert File.read!(host_file) == host_bytes
    end)
  end

  test "check is satisfied by edited host-owned files but fails missing or unsafe desired state" do
    with_root(fn root, config ->
      assert {:ok, _} = Generator.generate(config)
      host_file = Path.join(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts")
      File.write!(host_file, "// host-owned edit\n")
      assert :ok = Generator.check(config)

      File.rm!(Path.join(root, "test/crosswake_proof_lane/crosswake_proof_lane_test.exs"))

      assert {:error,
              [
                %{
                  rule_id: "PL-GENERATE-MISSING",
                  path: "test/crosswake_proof_lane/crosswake_proof_lane_test.exs"
                }
              ]} = Generator.check(config)
    end)
  end

  test "check and diff are byte-for-byte read-only and diff reports only safe sorted statuses" do
    with_root(fn root, config ->
      assert {:ok, _} = Generator.generate(config)

      File.write!(
        Path.join(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts"),
        "// host-owned edit\n"
      )

      before = snapshot(root)
      assert :ok = Generator.check(config)
      diff = Generator.diff(config)
      assert before == snapshot(root)
      assert diff == Enum.sort_by(diff, & &1.path)
      assert %{path: "e2e/crosswake_proof_lane/proof_lane.spec.ts", status: :different} in diff
      assert Enum.all?(diff, &(&1.status in [:missing, :different, :current]))
      refute Enum.any?(diff, &(inspect(&1) =~ "study/sync"))
    end)
  end

  test "interrupted generation never promotes an incomplete manifest" do
    with_root(fn root, config ->
      Process.put(:crosswake_proof_lane_interrupt_before_manifest, true)
      assert {:error, {"PL-GENERATE-INTERRUPTED", "manifest"}} = Generator.generate(config)
      refute File.exists?(Path.join(root, ".crosswake/proof_lane.json"))
      Process.delete(:crosswake_proof_lane_interrupt_before_manifest)
    end)
  end
end
