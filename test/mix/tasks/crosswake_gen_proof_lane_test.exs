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

  test "version-1 manifests remain host-owned but fail the version-2 provenance check" do
    with_root(fn root, config ->
      old_spec = "// host-owned inert spec\n"

      old_manifest =
        Jason.encode!(%{
          "schema_version" => 1,
          "template_version" => 1,
          "paths" => ["e2e/crosswake_proof_lane/proof_lane.spec.ts"],
          "provenance" => "crosswake:proof-lane"
        })

      spec_path = Path.join(root, "e2e/crosswake_proof_lane/proof_lane.spec.ts")
      manifest_path = Path.join(root, ".crosswake/proof_lane.json")
      File.mkdir_p!(Path.dirname(spec_path))
      File.mkdir_p!(Path.dirname(manifest_path))
      File.write!(spec_path, old_spec)
      File.write!(manifest_path, old_manifest)

      assert {:ok, results} = Generator.generate(config)

      assert %{
               path: "e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts",
               status: :created
             } in results

      assert File.read!(spec_path) == old_spec
      assert File.read!(manifest_path) == old_manifest
      assert {:error, findings} = Generator.check(config)
      assert Enum.any?(findings, &(&1.rule_id == "PL-GENERATE-PROVENANCE"))
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
      assert [] == staging_paths(root)
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
          timeout: 30_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.all?(outcomes, &match?({:ok, _}, &1))
      assert File.regular?(Path.join(root, ".crosswake/proof_lane.json"))
      assert [] == staging_paths(root)
      assert :ok = Generator.check(config)
    end)
  end

  test "generator actions ignore a poisoned former shared helper cache" do
    with_root(fn root, config ->
      existing_helpers = helper_directories()
      poison = former_helper_path()
      canary = Path.join(root, "poisoned-helper-ran")
      File.write!(poison, "#!/bin/sh\nprintf poisoned-helper > \"#{canary}\"\nexit 0\n")
      File.chmod!(poison, 0o700)

      try do
        assert {:ok, :created} = GeneratorFS.write(root, "e2e/direct.txt", "safe\n")
        assert {:ok, "safe\n"} = GeneratorFS.read(root, "e2e/direct.txt")
        assert GeneratorFS.regular?(root, "e2e/direct.txt")
        assert :regular == GeneratorFS.status(root, "e2e/direct.txt")

        assert {:ok, _} = Generator.generate(config)
        assert :ok = Generator.check(config)
        assert Enum.all?(Generator.diff(config), &(&1.status in [:current, :different, :missing]))

        refute File.exists?(canary)
        assert File.regular?(poison)
        assert existing_helpers == helper_directories()
      after
        File.rm(poison)
      end
    end)
  end

  test "direct unsafe configs fail closed before generator actions inspect destinations" do
    with_root(fn root, config ->
      for {key, unsafe_value} <- [
            {:ios_shell_root, "/tmp/not-the-native-ios-root"},
            {:sync_path, "/study/\"sync"},
            {:sync_path, "/study/" <> <<92>> <> "sync"},
            {:evidence_path, "/_proof/\"evidence"},
            {:evidence_path, "/_proof/" <> <<92>> <> "evidence"}
          ] do
        unsafe_config = Map.put(config, key, unsafe_value)
        before = snapshot(root)

        for action <- [&Generator.generate/1, &Generator.check/1, &Generator.diff/1] do
          assert_raise Config.Error,
                       "PL-CONFIG-VALUE: #{key}; use the documented local proof-lane shape",
                       fn -> action.(unsafe_config) end
        end

        assert before == snapshot(root)
      end
    end)
  end

  test "application and selected config reject unsafe endpoints before output-root creation" do
    with_root(fn root, config ->
      previous = Application.get_env(:crosswake, :proof_lane)

      try do
        for {key, unsafe_value} <- [
              {:sync_path, "/study/" <> <<92>> <> "sync"},
              {:evidence_path, "/_proof/" <> <<92>> <> "evidence"}
            ] do
          unsafe_config = config |> Map.from_struct() |> Map.put(key, unsafe_value)
          before = snapshot(root)
          Application.put_env(:crosswake, :proof_lane, unsafe_config)

          assert_raise Mix.Error,
                       "PL-CONFIG-VALUE: #{key}; use the documented local proof-lane shape",
                       fn -> Mix.Task.rerun("crosswake.gen.proof_lane", ["ios"]) end

          assert before == snapshot(root)

          config_path = Path.join(root, "proof_lane_#{key}.exs")
          File.write!(config_path, selected_config(unsafe_config))
          before = snapshot(root)

          assert_raise Mix.Error,
                       "PL-CONFIG-VALUE: #{key}; use the documented local proof-lane shape",
                       fn ->
                         Mix.Task.rerun("crosswake.gen.proof_lane", [
                           "ios",
                           "--config",
                           config_path
                         ])
                       end

          assert before == snapshot(root)
        end
      after
        if previous,
          do: Application.put_env(:crosswake, :proof_lane, previous),
          else: Application.delete_env(:crosswake, :proof_lane)
      end
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

  test "descriptor publication uses only anonymous bytes and preserves collision winners" do
    with_root(fn root, _config ->
      relative = "e2e/descriptor.txt"
      winner = "host-owned winner\n"

      assert {:ok, :created} = GeneratorFS.write(root, relative, "exact rendered bytes\n")
      assert File.read!(Path.join(root, relative)) == "exact rendered bytes\n"

      assert {:ok, :reused} = GeneratorFS.write(root, relative, "replacement bytes\n")
      assert File.read!(Path.join(root, relative)) == "exact rendered bytes\n"

      collision = "e2e/collision.txt"
      File.write!(Path.join(root, collision), winner)
      assert {:ok, :reused} = GeneratorFS.write(root, collision, "replacement bytes\n")
      assert File.read!(Path.join(root, collision)) == winner
    end)
  end

  test "publication barriers are callback-only and post-publication failure preserves exact bytes" do
    with_root(fn root, _config ->
      parent = self()
      relative = "e2e/barrier.txt"
      expected = "exact rendered bytes\n"

      task =
        Task.async(fn ->
          GeneratorFS.write(root, relative, expected,
            before_publish: fn ->
              send(parent, :before_publish)
              :ok
            end,
            after_publish: fn ->
              send(parent, :after_publish)
              :error
            end
          )
        end)

      assert_receive :before_publish, 5_000
      assert_receive :after_publish, 5_000
      assert {:error, {"PL-GENERATE-WRITE", ^relative}} = Task.await(task)
      assert File.read!(Path.join(root, relative)) == expected
    end)
  end

  test "production publication source excludes named staging and privileged empty-path linking" do
    generator = File.read!("lib/crosswake/proof_lane/generator.ex")
    fs = File.read!("lib/crosswake/proof_lane/generator_fs.ex")
    native = File.read!("priv/native/crosswake_proof_lane_fs.c")

    refute generator =~ ".staging-"
    refute generator =~ "promote_manifest"
    refute fs =~ "input_file"
    refute fs =~ "invoke_publish"
    refute fs =~ "System.cmd(executable, args"
    refute native =~ "AT_EMPTY_PATH"
    refute native =~ "input_path"
    assert native =~ "/proc/self/fd"
    assert native =~ "AT_SYMLINK_FOLLOW"
    assert native =~ "O_TMPFILE"
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

  defp staging_paths(root), do: Path.wildcard(Path.join(root, ".crosswake/*.staging-*"))

  defp former_helper_path do
    source = File.read!("priv/native/crosswake_proof_lane_fs.c")
    digest = source |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
    Path.join(System.tmp_dir!(), "crosswake-proof-lane-fs-" <> digest)
  end

  defp helper_directories do
    Path.wildcard(Path.join(System.tmp_dir!(), "crosswake-proof-lane-helper-*"))
  end

  defp selected_config(config) do
    inspect(config,
      limit: :infinity,
      printable_limit: :infinity,
      charlists: :as_lists,
      structs: false
    )
    |> then(&"import Config\nconfig :crosswake, :proof_lane, #{&1}\n")
  end
end
