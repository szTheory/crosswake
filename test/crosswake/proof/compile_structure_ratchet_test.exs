defmodule Crosswake.Proof.CompileStructureRatchetTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 180_000
  @root Path.expand("../../..", __DIR__)
  @script Path.join(@root, "script/check_compile_structure.exs")
  @phase ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet"

  test "repository enforcement uses the exact capsule measured on actual main" do
    receipt =
      @root
      |> Path.join(@phase <> "/196-EVIDENCE/main-compile.json")
      |> File.read!()
      |> Jason.decode!()

    assert receipt["subject_count"] > 0
    assert receipt["counts"]["files"] == receipt["subject_count"]
    assert receipt["process_exit"] == 1
    assert receipt["counts"]["compile_cycles"] == 1
    assert receipt["counts"]["compile_connected_cycles"] == 1
    assert receipt["privacy_before"]["exit"] == 0
    assert receipt["privacy_after"]["exit"] == 0
    assert receipt["restoration"]["branch"] != ""
    assert receipt["restoration"]["head"] == receipt["candidate_sha"]
    assert length(receipt["tools"]) == 2

    for tool <- receipt["tools"] do
      assert :crypto.hash(:sha256, File.read!(Path.join(@root, tool["path"])))
             |> Base.encode16(case: :lower) == tool["sha256"]
    end

    {output, code} = guard(@root)
    assert code == 0, output
    assert output =~ "compile_exit=0 compile_connected_exit=0 all_exit=0"
    report = report(output)

    assert report["counts"] == %{
             "files" => length(Path.wildcard(Path.join(@root, "lib/**/*.ex"))),
             "compile_cycles" => 0,
             "compile_connected_cycles" => 0,
             "all_cycles" => 4
           }

    assert report["scanned_files"] != []
    assert report["findings"] == []
  end

  @tag :tmp_dir
  test "acyclic real compilation and encoded relative paths pass", %{tmp_dir: root} do
    project(root, [
      {"nested/quoted\"_λ.ex", "defmodule Fixture.Leaf do\n def value, do: :ok\nend\n"}
    ])

    {output, code} = guard(root)
    assert code == 0, output
    assert report(output)["scanned_files"] == ["lib/nested/quoted\"_λ.ex"]

    assert report(output)["counts"] == %{
             "files" => 1,
             "compile_cycles" => 0,
             "compile_connected_cycles" => 0,
             "all_cycles" => 0
           }
  end

  @tag :tmp_dir
  test "mixed runtime and compile edges fail both native zero gates", %{tmp_dir: root} do
    project(root, mixed_sources())
    {output, code} = guard(root)
    assert code == 1, output
    assert output =~ "compile_exit=1 compile_connected_exit=1 all_exit=0"

    assert report(output)["counts"] == %{
             "files" => 2,
             "compile_cycles" => 1,
             "compile_connected_cycles" => 1,
             "all_cycles" => 1
           }

    assert Enum.map(report(output)["findings"], & &1["category"]) == [
             "compile_cycle",
             "compile_connected_cycle"
           ]

    assert native(root, "compile", 0) == 1
    assert native(root, "compile-connected", 0) == 1
    assert native(root, nil, 0) == 1
    assert native(root, nil, 1) == 0
  end

  for {cycles, expected} <- [{4, 0}, {5, 1}] do
    @tag :tmp_dir
    test "real runtime cycle count #{cycles} respects exact cap four", %{tmp_dir: root} do
      project(root, runtime_sources(unquote(cycles)))
      {output, code} = guard(root)
      assert code == unquote(expected), output
      assert report(output)["counts"]["all_cycles"] == unquote(cycles)
      assert output =~ "compile_exit=0 compile_connected_exit=0 all_exit=#{unquote(expected)}"
      assert native(root, nil, unquote(cycles) - 1) == 1
      assert native(root, nil, unquote(cycles)) == 0
    end
  end

  @tag :tmp_dir
  test "source discovery order cannot change graph identity", %{tmp_dir: root} do
    first = Path.join(root, "first")
    second = Path.join(root, "second")
    sources = runtime_sources(1)
    project(first, sources)
    project(second, Enum.reverse(sources))
    {a, 0} = guard(first)
    {b, 0} = guard(second)
    assert report(a) == report(b)
  end

  for {label, mutation, reason} <- [
        {"missing manifest", :missing, "manifest_missing"},
        {"malformed real manifest", :malformed, "manifest_malformed"},
        {"same-size stale source", :stale, "manifest_stale"},
        {"added uncompiled source", :added, "source_coverage"},
        {"removed compiled source", :removed, "source_coverage"},
        {"missing compiled beam", :beam, "manifest_stale"}
      ] do
    @tag :tmp_dir
    test "#{label} is refused by the production coverage barrier before xref", %{tmp_dir: root} do
      project(root, [
        {"leaf.ex", "defmodule Fixture.Leaf do\n def value, do: :ok\nend\n"},
        {"retained.ex", "defmodule Fixture.Retained do\n def value, do: :ok\nend\n"}
      ])

      compile!(root)
      assert {valid, 0} = coverage(root)
      assert valid =~ "coverage=2"
      mutate(root, unquote(mutation))
      {output, code} = coverage(root)
      assert code == 2, output
      assert output == "refused=#{unquote(reason)}\n"
      refute output =~ root
    end
  end

  @tag :tmp_dir
  test "empty source discovery cannot certify an empty graph", %{tmp_dir: root} do
    project(root, [])
    {output, code} = guard(root)
    assert code == 2
    assert output == "compile_structure refused=scope_empty\n"
  end

  @tag :tmp_dir
  test "uncompiled real source records must be nonempty", %{tmp_dir: root} do
    project(root, [{"leaf.ex", "# deliberately no module\n"}])
    compile!(root)
    {output, code} = coverage(root)
    assert code == 2
    assert output == "refused=manifest_malformed\n"
  end

  @tag :tmp_dir
  test "compile failure output is sanitized and never treated as findings", %{tmp_dir: root} do
    project(root, [{"leaf.ex", "raise \"synthetic-sensitive-proof-sentinel\"\n"}])
    {output, code} = guard(root)
    assert code == 2
    assert output == "compile_structure refused=compile_failed\n"
    refute output =~ "synthetic-sensitive-proof-sentinel"
    refute output =~ "PHASE196_REPORT"
    refute output =~ root
  end

  defp project(root, sources) do
    File.mkdir_p!(Path.join(root, "lib"))

    File.write!(Path.join(root, "mix.exs"), """
    defmodule CompileFixture.MixProject do
      use Mix.Project
      def project, do: [app: :compile_fixture, version: "0.1.0", elixir: "== 1.19.5", deps: []]
    end
    """)

    for {name, code} <- sources do
      path = Path.join([root, "lib", name])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, code)
    end

    assert Path.wildcard(Path.join(root, "lib/**/*.ex")) |> length() == length(sources)
  end

  defp mixed_sources do
    [
      {"a.ex",
       "defmodule Fixture.A do\n @value Fixture.B.value()\n def value, do: @value\nend\n"},
      {"b.ex",
       "defmodule Fixture.B do\n def value, do: :ok\n def back, do: Fixture.A.value()\nend\n"}
    ]
  end

  defp runtime_sources(count) do
    for n <- 1..count,
        {name, code} <- [
          {"a#{n}.ex",
           "defmodule Fixture.A#{n} do\n def value, do: Fixture.B#{n}.value()\nend\n"},
          {"b#{n}.ex",
           "defmodule Fixture.B#{n} do\n def value, do: :ok\n def back, do: Fixture.A#{n}.value()\nend\n"}
        ],
        do: {name, code}
  end

  defp compile!(root) do
    {output, code} =
      System.cmd("mix", ["compile", "--force", "--warnings-as-errors"],
        cd: root,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    assert code == 0, output
    assert File.regular?(manifest(root))
    assert Path.wildcard(Path.join(root, "lib/**/*.ex")) != []
  end

  defp manifest(root), do: Path.join(root, "_build/test/lib/compile_fixture/.mix/compile.elixir")
  defp mutate(root, :missing), do: File.rm!(manifest(root))
  defp mutate(root, :malformed), do: File.write!(manifest(root), "synthetic malformed manifest")

  defp mutate(root, :stale) do
    path = Path.join(root, "lib/leaf.ex")
    old = File.read!(path)
    changed = String.replace(old, ":ok", ":no")
    assert byte_size(old) == byte_size(changed)
    File.write!(path, changed)
  end

  defp mutate(root, :added),
    do: File.write!(Path.join(root, "lib/extra.ex"), "defmodule Fixture.Extra do\nend\n")

  defp mutate(root, :removed), do: File.rm!(Path.join(root, "lib/leaf.ex"))

  defp mutate(root, :beam),
    do: File.rm!(Path.join(root, "_build/test/lib/compile_fixture/ebin/Elixir.Fixture.Leaf.beam"))

  defp coverage(root) do
    code = """
    Mix.start()
    try do
      result = Crosswake.CompileStructure.coverage!(#{inspect(root)})
      IO.puts("coverage=\#{length(result.files)}")
    catch
      {:compile_structure, reason} -> IO.puts("refused=\#{reason}"); System.halt(2)
    end
    """

    System.cmd("elixir", ["-r", @script, "-e", code],
      env: [{"CROSSWAKE_COMPILE_STRUCTURE_LIBRARY", "1"}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
  end

  defp guard(root),
    do:
      System.cmd("elixir", [@script, "--root", root, "--mode", "enforce"], stderr_to_stdout: true)

  defp report(output) do
    lines =
      output |> String.split("\n") |> Enum.filter(&String.starts_with?(&1, "PHASE196_REPORT "))

    assert length(lines) == 1
    hd(lines) |> String.replace_prefix("PHASE196_REPORT ", "") |> Jason.decode!()
  end

  defp native(root, label, cap) do
    args = ["xref", "graph", "--no-compile", "--format", "cycles"]
    args = if label, do: args ++ ["--label", label], else: args

    {_, code} =
      System.cmd("mix", args ++ ["--fail-above", Integer.to_string(cap)],
        cd: root,
        env: [{"MIX_ENV", "test"}],
        stderr_to_stdout: true
      )

    code
  end
end
