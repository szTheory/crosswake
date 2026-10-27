defmodule Crosswake.Proof.RuntimeDependencyRatchetTest do
  use ExUnit.Case, async: false

  @root Path.expand("../../..", __DIR__)
  @script Path.join(@root, "script/check_runtime_dependencies.exs")
  @baseline Path.join(@root, "script/fixtures/runtime_dependency_baseline.exs")
  @phase ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet"
  @roster [
    {"mix.exs", "crosswake"},
    {"packages/crosswake_chimeway/mix.exs", "crosswake_chimeway"},
    {"packages/crosswake_rindle/mix.exs", "crosswake_rindle"},
    {"packages/crosswake_rulestead/mix.exs", "crosswake_rulestead"},
    {"packages/crosswake_sigra/mix.exs", "crosswake_sigra"},
    {"packages/crosswake_threadline/mix.exs", "crosswake_threadline"}
  ]

  test "repository enforcement follows actual-main measurement of all three exact tool blobs" do
    receipt =
      @root
      |> Path.join(@phase <> "/196-EVIDENCE/main-dependencies.json")
      |> File.read!()
      |> Jason.decode!()

    assert receipt["guard"] == "dependencies"
    assert receipt["main_ref"] == "origin/main"
    assert receipt["main_sha"] =~ ~r/\A[0-9a-f]{40}\z/
    assert receipt["candidate_sha"] =~ ~r/\A[0-9a-f]{40}\z/
    assert receipt["process_exit"] == 0
    assert receipt["findings"] == []
    assert receipt["subject_count"] == 6

    assert receipt["counts"] == %{
             "files" => 6,
             "projects" => 6,
             "branches" => 2,
             "executions" => 12,
             "declarations" => 48,
             "dependencies" => 32
           }

    assert receipt["restoration"]["head"] == receipt["candidate_sha"]
    assert receipt["restoration"]["branch"] == "fix/spec-structure-ratchet"
    assert receipt["restoration"]["untracked_count"] == 0
    assert receipt["privacy_before"]["exit"] == 0
    assert receipt["privacy_after"]["exit"] == 0
    assert Enum.map(receipt["subjects"], & &1["path"]) == Enum.map(@roster, &elem(&1, 0))

    assert Enum.map(receipt["tools"], & &1["path"]) == [
             "script/check_runtime_dependencies.exs",
             "script/evaluate_runtime_dependencies.exs",
             "script/fixtures/runtime_dependency_baseline.exs"
           ]

    for tool <- receipt["tools"] do
      bytes = File.read!(Path.join(@root, tool["path"]))
      assert hash(:sha256, bytes) == tool["sha256"]
      assert hash(:sha, "blob #{byte_size(bytes)}\0" <> bytes) == tool["blob"]
    end

    for subject <- receipt["subjects"] do
      {bytes, 0} =
        System.cmd("git", ["show", receipt["main_sha"] <> ":" <> subject["path"]], cd: @root)

      assert hash(:sha256, bytes) == subject["sha256"]
    end

    {report, executions, 0} = run(@root)
    assert report["findings"] == []
    assert report["counts"] == receipt["counts"]
    assert_contexts(executions)
  end

  @tag :tmp_dir
  test "all tuple forms, optional runtime declarations and both branch environments are evaluated without fetching",
       %{tmp_dir: root} do
    fixture(root)
    {report, executions, 0} = run(root)
    assert report["findings"] == []
    assert report["counts"]["declarations"] == 68
    assert report["counts"]["dependencies"] == 32
    assert_contexts(executions)

    assert Enum.count(
             Enum.flat_map(executions, & &1["declarations"]),
             &(&1["optional"] and &1["runtime"] and &1["production"])
           ) == 8

    for {file, _} <- @roster, generated <- ["deps", "_build", "mix.lock", "fetch-attempted"] do
      refute File.exists?(Path.join([root, Path.dirname(file), generated]))
    end
  end

  for {label, original, replacement, category} <- [
        {"optional runtime addition", "# EXTRA_DECLARATIONS",
         "{:synthetic_added, \"~> 1.0\", optional: true},", "dependency_added"},
        {"dev and test promotion", "{:synthetic_dev, \"~> 1.0\", only: [:dev, :test]},",
         "{:synthetic_dev, \"~> 1.0\", only: [:dev, :test, :prod]},", "dependency_added"},
        {"runtime false promotion", "{:synthetic_build, \"~> 1.0\", runtime: false},",
         "{:synthetic_build, \"~> 1.0\", runtime: true},", "dependency_added"}
      ] do
    @tag :tmp_dir
    test "#{label} fails the actual checker", %{tmp_dir: root} do
      fixture(root)
      edit(root, "mix.exs", unquote(original), unquote(replacement))
      assert_red(root, unquote(category), 2)
    end
  end

  for {label, before, after_text} <- [
        {"runtime flag", "{:jason, \"~> 1.0\"}", "{:jason, \"~> 1.0\", runtime: false}"},
        {"production flag", "{:jason, \"~> 1.0\"}", "{:jason, \"~> 1.0\", only: :test}"},
        {"optionality", "{:jason, \"~> 1.0\"}", "{:jason, \"~> 1.0\", optional: true}"}
      ] do
    @tag :tmp_dir
    test "same name with changed #{label} fails", %{tmp_dir: root} do
      fixture(root)
      edit(root, "mix.exs", unquote(before), unquote(after_text))
      assert_red(root, "dependency_classification", 2)
    end
  end

  @tag :tmp_dir
  test "removing a runtime declaration fails", %{tmp_dir: root} do
    fixture(root)
    edit(root, "mix.exs", "{:jason, \"~> 1.0\"},", "")
    assert_red(root, "dependency_removed", 2)
  end

  @tag :tmp_dir
  test "release-only drift cannot hide behind the local branch", %{tmp_dir: root} do
    fixture(root)
    edit(root, "mix.exs", "# RELEASE_DECLARATIONS", "{:synthetic_release, \"~> 1.0\"},")
    assert_red(root, "dependency_added", 1)
  end

  for {label, change} <- [
        {"missing companion", :missing},
        {"unexpected companion", :unexpected},
        {"empty roster", :empty}
      ] do
    @tag :tmp_dir
    test "#{label} fails independent exact project discovery", %{tmp_dir: root} do
      fixture(root)

      case unquote(change) do
        :missing ->
          File.rm!(Path.join(root, "packages/crosswake_sigra/mix.exs"))

        :unexpected ->
          put(root, "packages/crosswake_unexpected/mix.exs", "defmodule Unexpected do end")

        :empty ->
          File.rm!(Path.join(root, "mix.exs"))
      end

      {report, executions, 1} = run(root)
      assert Enum.any?(report["findings"], &(&1["category"] == "project_roster"))
      assert report["counts"]["executions"] == 0
      assert executions == []
    end
  end

  for {label, source} <- [
        {"empty declarations",
         "defmodule Empty.MixProject do\nuse Mix.Project\ndef project, do: [app: :crosswake, version: \"0.1.0\", deps: []]\nend"},
        {"project exception", "raise \"synthetic_private_record\""},
        {"syntax error", "defmodule SyntheticPrivateParse do def project( end"},
        {"wrong app",
         "defmodule Wrong.MixProject do\nuse Mix.Project\ndef project, do: [app: :synthetic_wrong, deps: [{:jason, \"~> 1.0\"}]]\nend"},
        {"child exit", "System.halt(9)"},
        {"missing dependency config",
         "defmodule Missing.MixProject do\nuse Mix.Project\ndef project, do: [app: :crosswake, version: \"0.1.0\"]\nend"},
        {"invalid classification",
         "defmodule Invalid.MixProject do\nuse Mix.Project\ndef project, do: [app: :crosswake, deps: [{:jason, \"~> 1.0\", optional: :invalid}]]\nend"}
      ] do
    @tag :tmp_dir
    test "#{label} produces a closed child failure instead of empty success", %{tmp_dir: root} do
      fixture(root)
      put(root, "mix.exs", unquote(source))
      {report, executions, 1} = run(root)
      assert Enum.count(report["findings"], &(&1["category"] == "guard_failure")) == 2
      assert report["counts"]["executions"] == 10
      assert length(executions) == 10
    end
  end

  for {label, replacement} <- [
        {"blank purpose", "\" \""},
        {"empty purpose", "\"\""},
        {"missing purpose", "nil"}
      ] do
    @tag :tmp_dir
    test "#{label} cannot become an accepted baseline", %{tmp_dir: root} do
      fixture(root)

      text =
        File.read!(@baseline)
        |> String.replace("\"Encode and decode contract JSON.\"", unquote(replacement))

      put(root, "baseline.exs", text)

      assert_red(root, "missing_justification", 1, ["--baseline", Path.join(root, "baseline.exs")])
    end
  end

  @tag :tmp_dir
  test "empty or executable baseline cannot accept the current declarations", %{tmp_dir: root} do
    fixture(root)

    for text <- ["[]", "File.write!(\"synthetic-side-effect\", \"bad\"); []"] do
      put(root, "baseline.exs", text)

      assert_red(root, "missing_justification", 1, ["--baseline", Path.join(root, "baseline.exs")])

      refute File.exists?(Path.join(root, "synthetic-side-effect"))
    end
  end

  @tag :tmp_dir
  test "tuple order, version and path spelling and extra test-only declarations preserve membership",
       %{tmp_dir: root} do
    fixture(root)
    {before_report, before_exec, 0} = run(root)

    for {file, _} <- @roster do
      edit(root, file, "~> 1.0", ">= 0.0.0")
      if file != "mix.exs", do: edit(root, file, "missing/local", "another/absent/path")
      edit(root, file, "deps: local ++ release", "deps: Enum.reverse(local ++ release)")
      edit(root, file, "# EXTRA_DECLARATIONS", "{:synthetic_test, \"~> 1.0\", only: :test},")
    end

    {after_report, after_exec, 0} = run(root)
    assert before_report["findings"] == []
    assert after_report["findings"] == []
    assert after_report["counts"]["declarations"] == before_report["counts"]["declarations"] + 12
    assert after_report["counts"]["dependencies"] == 32

    assert Enum.map(before_exec, & &1["declarations"]) ==
             Enum.map(after_exec, fn execution ->
               Enum.reject(execution["declarations"], &(&1["name"] == "synthetic_test"))
             end)
  end

  defp fixture(root) do
    {rows, []} = Code.eval_file(@baseline)
    assert Enum.map(rows, fn {file, app, _} -> {file, app} end) == @roster

    for {file, app, deps} <- rows do
      declarations =
        Enum.map_join(deps, ",\n", fn {name, optional, _} ->
          cond do
            optional -> "{#{inspect(String.to_atom(name))}, \"~> 1.0\", optional: true}"
            name == "crosswake" -> "{:crosswake, path: \"missing/local\"}"
            true -> "{#{inspect(String.to_atom(name))}, \"~> 1.0\"}"
          end
        end)

      put(root, file, """
      defmodule #{Macro.camelize(app)}.MixProject do
        use Mix.Project
        def project do
          if Mix.env() != :prod, do: raise("synthetic_private_record")
          IO.puts("synthetic_private_record")
          local = [
            #{declarations},
            {:synthetic_dev, "~> 1.0", only: [:dev, :test]},
            {:synthetic_build, "~> 1.0", runtime: false},
            {:synthetic_regex, ~r/1.*/, only: :test},
            # EXTRA_DECLARATIONS
          ]
          release = if System.get_env("CROSSWAKE_RELEASE") == "1" do
            [
              # RELEASE_DECLARATIONS
            ]
          else
            if System.get_env("CROSSWAKE_RELEASE") != nil, do: raise("synthetic_private_record")
            []
          end
          [app: :#{app}, version: "0.1.0", deps: local ++ release,
           aliases: ["deps.get": fn _ -> File.write!("fetch-attempted", "bad"); raise("synthetic_private_record") end]]
        end
      end
      """)
    end
  end

  defp assert_contexts(executions) do
    assert length(executions) == 12
    assert length(Enum.uniq_by(executions, & &1["execution_id"])) == 12
    assert length(Enum.uniq_by(executions, & &1["process_id"])) == 12

    assert Enum.map(executions, &{&1["file"], &1["branch"]}) ==
             for({file, _} <- @roster, branch <- ["local", "release"], do: {file, branch})

    assert Enum.all?(
             executions,
             &(&1["environment"] == "prod" and length(&1["declarations"]) > 0)
           )
  end

  defp assert_red(root, category, count, args \\ []) do
    {report, _, 1} = run(root, args)
    assert Enum.count(report["findings"], &(&1["category"] == category)) == count
  end

  defp run(root, args \\ []) do
    {output, code} =
      System.cmd("elixir", [@script, "--root", root, "--mode", "enforce"] ++ args,
        stderr_to_stdout: true,
        env: [
          {"MIX_ENV", "test"},
          {"CROSSWAKE_RELEASE", "synthetic_inherited_value"},
          {"ERL_FLAGS", "+S 2:2"}
        ]
      )

    refute output =~ "synthetic_private_record"
    refute output =~ "SyntheticPrivateParse"
    refute output =~ root
    report = closed_line(output, "PHASE196_REPORT ")
    executions = closed_line(output, "RUNTIME_DEPENDENCY_EXECUTIONS ")
    {report, executions, code}
  end

  defp closed_line(output, prefix) do
    lines = String.split(output, "\n") |> Enum.filter(&String.starts_with?(&1, prefix))
    assert length(lines) == 1, output
    lines |> hd() |> String.replace_prefix(prefix, "") |> Jason.decode!()
  end

  defp edit(root, file, old, new) do
    path = Path.join(root, file)
    text = File.read!(path)
    assert text =~ old
    File.write!(path, String.replace(text, old, new))
  end

  defp put(root, file, text) do
    path = Path.join(root, file)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, text)
  end

  defp hash(algorithm, bytes), do: :crypto.hash(algorithm, bytes) |> Base.encode16(case: :lower)
end
