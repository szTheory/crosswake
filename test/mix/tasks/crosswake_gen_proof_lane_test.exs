defmodule Mix.Tasks.Crosswake.Gen.ProofLaneTest do
  use ExUnit.Case, async: false

  alias Crosswake.ProofLane.{Config, Generator, GeneratorFS}

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

  test "concurrent generators preserve host-owned destinations" do
    with_root(fn root, config ->
      outcomes =
        1..2
        |> Task.async_stream(fn _ -> Generator.generate(config) end,
          max_concurrency: 2,
          ordered: false,
          timeout: 5_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.all?(outcomes, &match?({:ok, _}, &1))
      assert File.regular?(Path.join(root, ".crosswake/proof_lane.json"))
      assert :ok = Generator.check(config)
    end)
  end

  test "direct unsafe configs fail closed before generator actions inspect destinations" do
    with_root(fn root, config ->
      unsafe_config = %{config | ios_shell_root: "/tmp/not-the-native-ios-root"}
      before = snapshot(root)

      for action <- [&Generator.generate/1, &Generator.check/1, &Generator.diff/1] do
        assert_raise Config.Error,
                     "PL-CONFIG-VALUE: ios_shell_root; use the documented local proof-lane shape",
                     fn -> action.(unsafe_config) end
      end

      assert before == snapshot(root)
    end)
  end

  test "descriptor-relative writes reject a symlinked generated ancestor" do
    with_root(fn root, _config ->
      outside = temporary_root()
      File.mkdir_p!(outside)
      on_exit(fn -> File.rm_rf!(outside) end)

      File.mkdir_p!(Path.join(root, "e2e"))
      File.rm_rf!(Path.join(root, "e2e"))
      File.ln_s!(outside, Path.join(root, "e2e"))

      assert {:error, {"PL-GENERATE-DESTINATION", "e2e/crosswake_proof_lane/proof_lane.spec.ts"}} =
               GeneratorFS.write(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts", "safe")

      refute File.exists?(Path.join(outside, "crosswake_proof_lane/proof_lane.spec.ts"))
    end)
  end

  test "descriptor-relative writes reject an ancestor swap before final create" do
    with_root(fn root, _config ->
      outside = temporary_root()
      hook = Path.join(root, "before-final-open")
      File.mkdir_p!(outside)
      File.mkdir_p!(Path.join(root, "e2e"))
      on_exit(fn -> File.rm_rf!(outside) end)

      task =
        Task.async(fn ->
          GeneratorFS.write(root, "e2e/race.txt", "safe", before_final_open_hook: hook)
        end)

      wait_for_file(hook)
      File.rm_rf!(Path.join(root, "e2e"))
      File.ln_s!(outside, Path.join(root, "e2e"))

      assert {:error, {"PL-GENERATE-DESTINATION", "e2e/race.txt"}} = Task.await(task)
      refute File.exists?(Path.join(outside, "race.txt"))
    end)
  end

  for fault <- [:read, :write, :fsync] do
    @tag post_create_fault: fault
    test "post-create #{fault} failure removes destination and permits full-byte rerun" do
      with_root(fn root, _config ->
        relative = "e2e/post-create-#{unquote(fault)}.txt"
        expected = "complete generated output\n"

        assert {:error, {"PL-GENERATE-WRITE", ^relative}} =
                 GeneratorFS.write(root, relative, expected, post_create_fault: unquote(fault))

        refute File.exists?(Path.join(root, relative))
        assert {:ok, :created} = GeneratorFS.write(root, relative, expected)
        assert File.read!(Path.join(root, relative)) == expected
      end)
    end
  end

  test "generator actions reject generated namespace and manifest symlinks without writes outside root" do
    with_root(fn root, config ->
      outside = temporary_root()
      File.mkdir_p!(outside)
      on_exit(fn -> File.rm_rf!(outside) end)

      File.ln_s!(outside, Path.join(root, "e2e"))

      assert {:error, {"PL-GENERATE-DESTINATION", "e2e/crosswake_proof_lane/proof_lane.spec.ts"}} =
               Generator.generate(config)

      refute File.exists?(Path.join(outside, "crosswake_proof_lane/proof_lane.spec.ts"))

      before = snapshot(root)
      diff = Generator.diff(config)

      assert before == snapshot(root)
      assert {:error, findings} = Generator.check(config)

      assert Enum.any?(findings, fn finding ->
               finding.rule_id == "PL-GENERATE-DESTINATION" &&
                 finding.path == "e2e/crosswake_proof_lane/proof_lane.spec.ts"
             end)

      assert %{path: "e2e/crosswake_proof_lane/proof_lane.spec.ts", status: :missing} in diff
    end)

    with_root(fn root, config ->
      outside = temporary_root()
      File.mkdir_p!(outside)
      File.ln_s!(outside, Path.join(root, ".crosswake"))
      on_exit(fn -> File.rm_rf!(outside) end)

      assert {:error, {"PL-GENERATE-DESTINATION", ".crosswake/proof_lane.json"}} =
               Generator.generate(config)

      refute File.exists?(Path.join(outside, "proof_lane.json"))
    end)
  end

  defp wait_for_file(path, attempts \\ 100)
  defp wait_for_file(_path, 0), do: flunk("native final-create hook was not reached")

  defp wait_for_file(path, attempts) do
    if File.exists?(path) do
      :ok
    else
      Process.sleep(10)
      wait_for_file(path, attempts - 1)
    end
  end
end
