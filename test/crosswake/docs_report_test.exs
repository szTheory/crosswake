defmodule Crosswake.DocsReportTest do
  @moduledoc """
  `script/docs_report.exs` over fixture directories. No test touches the network or the real
  `mix docs`. Each counter has a positive case with exact counts and a negative control that
  asserts the specific line text, so a report that failed for another reason cannot pass.
  """
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)
  @launcher Path.join(@repo_root, "script/docs-report")
  @allowlist "script/docs_leak_allowlist.json"
  @empty_allowlist ~s({"schema_version": 1, "entries": []})

  setup_all do
    Process.put(:crosswake_docs_report_library, true)

    unless Code.ensure_loaded?(Crosswake.DocsReport) do
      Code.require_file(Path.join(@repo_root, "script/docs_report.exs"))
    end

    :ok
  end

  defp put(root, file, bytes) do
    path = Path.join(root, file)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, bytes)
  end

  defp mix_exs(root, extras) do
    list = Enum.map_join(extras, ", ", &inspect/1)

    put(root, "mix.exs", """
    defmodule Fixture.MixProject do
      def project, do: [app: :fixture]

      defp docs do
        [main: "readme", extras: [#{list}]]
      end
    end
    """)
  end

  defp allowlist(root, body \\ @empty_allowlist), do: put(root, @allowlist, body)

  defp entry(file, text), do: %{"file" => file, "text" => text, "reason" => "fixture"}

  defp allowlist_with(root, entries) do
    allowlist(root, JSON.encode!(%{"schema_version" => 1, "entries" => entries}))
  end

  # Two `.md` extras: five leaks (one per pattern) plus a semver and a fenced decoy.
  defp two_file_fixture(root) do
    mix_exs(root, ["README.md", "guides/a.md", "LICENSE"])
    put(root, "LICENSE", "MIT\n")
    allowlist(root)

    put(root, "README.md", """
    # Readme

    Plain prose with nothing to flag.
    This came from Phase 12 of the work.
    See TODO-3 for the follow-up.
    """)

    put(root, "guides/a.md", """
    # Guide

    The decision D-07 is recorded elsewhere.
    Tracked as SEED-9 in the backlog.
    Shipped in the v28.0 milestone.
    Released as 0.2.11 on Hex.

    ```bash
    echo "Phase 99 is only an example"
    ```
    """)
  end

  defp one_leak_fixture(root) do
    mix_exs(root, ["README.md"])
    put(root, "README.md", "# Readme\n\nThis came from Phase 12 of the work.\n")
    allowlist(root)
  end

  defp report(root, deps_overrides \\ %{}, opts \\ []) do
    deps = Map.merge(Crosswake.DocsReport.deps(), deps_overrides)
    {code, lines} = Crosswake.DocsReport.run(root, deps, opts)
    {code, lines}
  end

  defp leaks_line(lines), do: Enum.find(lines, &String.starts_with?(&1, "docs.leaks "))

  describe "leak counter" do
    @tag :tmp_dir
    test "counts one hit per pattern and ignores semver, exactly", %{tmp_dir: root} do
      two_file_fixture(root)
      {code, lines} = report(root)

      assert leaks_line(lines) == "docs.leaks hits=5 allowlisted=0 stale_allowlist=0 files=2"
      assert "docs-report: REPORT-ONLY (not a required check)" in lines
      assert "docs.warnings UNVERIFIED reason=not_measured" in lines
      # warnings are unmeasured until the mix docs counter lands, so the exit is 2, never 1
      assert code == 2
    end

    @tag :tmp_dir
    test "fenced code adds nothing to the count", %{tmp_dir: root} do
      two_file_fixture(root)
      fenced = File.read!(Path.join(root, "guides/a.md"))
      assert fenced =~ "Phase 99"

      stripped = String.replace(fenced, "Phase 99", "an")
      assert stripped != fenced
      put(root, "guides/a.md", stripped)

      {_code, lines} = report(root)
      assert leaks_line(lines) == "docs.leaks hits=5 allowlisted=0 stale_allowlist=0 files=2"
    end

    @tag :tmp_dir
    test "an allowlisted line is suppressed and counted", %{tmp_dir: root} do
      two_file_fixture(root)
      allowlist_with(root, [entry("README.md", "This came from Phase 12 of the work.")])

      {_code, lines} = report(root)
      assert leaks_line(lines) == "docs.leaks hits=4 allowlisted=1 stale_allowlist=0 files=2"
    end

    @tag :tmp_dir
    test "a mutated allowlist entry suppresses nothing and is stale", %{tmp_dir: root} do
      two_file_fixture(root)
      original = entry("README.md", "This came from Phase 12 of the work.")
      mutated = Map.put(original, "text", "This came from Phase 13 of the work.")
      assert mutated != original
      allowlist_with(root, [mutated])

      {_code, lines} = report(root)
      assert leaks_line(lines) == "docs.leaks hits=5 allowlisted=0 stale_allowlist=1 files=2"
    end

    @tag :tmp_dir
    test "single leak: allowlisting its one hit gives zero, mutating returns it", %{
      tmp_dir: root
    } do
      one_leak_fixture(root)
      {_code, lines} = report(root)
      assert leaks_line(lines) == "docs.leaks hits=1 allowlisted=0 stale_allowlist=0 files=1"

      original = entry("README.md", "This came from Phase 12 of the work.")
      allowlist_with(root, [original])
      {_code, lines} = report(root)
      assert leaks_line(lines) == "docs.leaks hits=0 allowlisted=1 stale_allowlist=0 files=1"

      mutated = Map.put(original, "text", "This came from Phase 99 of the work.")
      assert mutated != original
      allowlist_with(root, [mutated])
      {_code, lines} = report(root)
      assert leaks_line(lines) == "docs.leaks hits=1 allowlisted=0 stale_allowlist=1 files=1"
    end

    @tag :tmp_dir
    test "--detail lists each hit with file, pattern and normalized text", %{tmp_dir: root} do
      one_leak_fixture(root)
      {_code, lines} = report(root, %{}, detail: true)

      assert "docs.leaks.hit file=README.md pattern=phase text=This came from Phase 12 of the work." in lines
    end
  end

  describe "scope and UNVERIFIED rules" do
    @tag :tmp_dir
    test "scan floor: a scan that drops a parsed extra is UNVERIFIED, not clean", %{
      tmp_dir: root
    } do
      two_file_fixture(root)

      parsed = ["README.md", "guides/a.md"]
      drop_last = fn files -> Enum.drop(files, -1) end
      assert length(drop_last.(parsed)) < length(parsed)

      {code, lines} = report(root, %{scan: drop_last})
      assert code == 2
      assert "docs.leaks UNVERIFIED reason=scan_floor" in lines
      assert lines != []
      refute Enum.any?(lines, &String.starts_with?(&1, "docs.leaks hits="))

      # positive pair: the default scan reads both files
      {_code, lines} = report(root)
      assert leaks_line(lines) =~ " files=2"
    end

    @tag :tmp_dir
    test "empty extras is UNVERIFIED no_extras", %{tmp_dir: root} do
      mix_exs(root, [])
      allowlist(root)

      {code, lines} = report(root)
      assert code == 2
      assert "docs.leaks UNVERIFIED reason=no_extras" in lines
      assert lines != []
      refute Enum.any?(lines, &String.starts_with?(&1, "docs.leaks hits="))
    end

    @tag :tmp_dir
    test "a missing mix.exs is UNVERIFIED no_extras", %{tmp_dir: root} do
      allowlist(root)

      {code, lines} = report(root)
      assert code == 2
      assert "docs.leaks UNVERIFIED reason=no_extras" in lines
    end

    @tag :tmp_dir
    test "a listed extra that does not exist is UNVERIFIED unreadable_extra", %{tmp_dir: root} do
      mix_exs(root, ["README.md", "guides/missing.md"])
      put(root, "README.md", "# Readme\n")
      allowlist(root)

      {code, lines} = report(root)
      assert code == 2
      assert "docs.leaks UNVERIFIED reason=unreadable_extra" in lines
      assert lines != []
      refute Enum.any?(lines, &String.starts_with?(&1, "docs.leaks hits="))
    end

    @tag :tmp_dir
    test "a missing allowlist is UNVERIFIED allowlist_unreadable", %{tmp_dir: root} do
      one_leak_fixture(root)
      File.rm!(Path.join(root, @allowlist))

      {code, lines} = report(root)
      assert code == 2
      assert "docs.leaks UNVERIFIED reason=allowlist_unreadable" in lines
    end
  end

  describe "allowlist schema" do
    @invalid_allowlists [
      {"wrong schema_version", ~s({"schema_version": 2, "entries": []})},
      {"no entries key", ~s({"schema_version": 1})},
      {"entries as an object", ~s({"schema_version": 1, "entries": {}})},
      {"entry without file",
       ~s({"schema_version": 1, "entries": [{"text": "t", "reason": "r"}]})},
      {"entry without text",
       ~s({"schema_version": 1, "entries": [{"file": "f", "reason": "r"}]})},
      {"entry without reason", ~s({"schema_version": 1, "entries": [{"file": "f", "text": "t"}]})}
    ]

    for {name, body} <- @invalid_allowlists do
      @tag :tmp_dir
      test "#{name} is UNVERIFIED allowlist_invalid", %{tmp_dir: root} do
        one_leak_fixture(root)
        body = unquote(body)
        assert body != @empty_allowlist
        allowlist(root, body)

        {code, lines} = report(root)
        assert code == 2
        assert "docs.leaks UNVERIFIED reason=allowlist_invalid" in lines
        assert lines != []
        refute Enum.any?(lines, &String.starts_with?(&1, "docs.leaks hits="))
      end
    end

    @tag :tmp_dir
    test "the shipped empty allowlist validates", %{tmp_dir: root} do
      one_leak_fixture(root)
      shipped = File.read!(Path.join(@repo_root, @allowlist))
      assert JSON.decode!(shipped) == %{"schema_version" => 1, "entries" => []}
      allowlist(root, shipped)

      {_code, lines} = report(root)
      assert leaks_line(lines) =~ "docs.leaks hits="
      assert lines != []
      refute Enum.any?(lines, &(&1 =~ "allowlist_invalid"))
    end
  end

  describe "launcher" do
    test "answers --help without scanning anything" do
      assert {out, 0} = System.cmd(@launcher, ["--help"], stderr_to_stdout: true)
      assert out =~ "usage: script/docs-report [--root DIR] [--detail]"
    end
  end
end
