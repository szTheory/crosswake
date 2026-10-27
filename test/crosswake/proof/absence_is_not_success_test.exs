defmodule Crosswake.Proof.AbsenceIsNotSuccessTest do
  @moduledoc """
  Guards the guard: `script/check_absence_is_not_success.exs` must stay green on
  this repository AND must actually fail on each defect it claims to detect.

  The second half is the point. The v22.0 retrospective found five independent
  checks that kept reporting success after they had stopped asserting anything —
  a shape a guard is uniquely able to reproduce, since a scanner that can never
  fail is indistinguishable from one that passes. Every check below therefore
  has a positive case and a negative control, and the negative control asserts
  the specific check id rather than merely a non-zero exit, so a scanner that
  failed for an unrelated reason cannot be mistaken for one that caught the bug.
  """
  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", __DIR__)
  @script Path.join(@repo_root, "script/check_absence_is_not_success.exs")
  @one ["--min-test-files", "1"]

  describe "lexical collection evidence through the actual checker" do
    @tag :tmp_dir
    test "repository enforcement matches the measured reviewed multiset" do
      receipt =
        Jason.decode!(
          File.read!(
            Path.join(
              @repo_root,
              ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-absence.json"
            )
          )
        )

      assert receipt["subject_count"] > 0
      assert receipt["counts"]["projects"] == 6
      assert receipt["privacy_before"]["exit"] == 0
      assert receipt["privacy_after"]["exit"] == 0
      assert receipt["restoration"]["branch"] == "fix/spec-structure-ratchet"

      for tool <- receipt["tools"] do
        assert :crypto.hash(:sha256, File.read!(Path.join(@repo_root, tool["path"])))
               |> Base.encode16(case: :lower) == tool["sha256"]
      end

      {output, code} = run(@repo_root, ["--collections-mode", "enforce"])
      assert code == 0, output
      assert output =~ "delta=0"
    end

    for {label, prefix, body, category} <- [
          {"wrong collection", "",
           "items = load(); other = load(); assert other != []; assert Enum.all?(items, &valid?/1)",
           "unsafe_collection"},
          {"sibling branch", "",
           "items = load(); if flag(), do: (assert items != []), else: (assert Enum.all?(items, &valid?/1))",
           "unsafe_collection"},
          {"branch does not dominate following code", "",
           "items = load(); if flag(), do: (assert items != []); assert Enum.all?(items, &valid?/1)",
           "unsafe_collection"},
          {"guard after assertion", "",
           "items = load(); assert Enum.all?(items, &valid?/1); assert items != []",
           "unsafe_collection"},
          {"rebinding", "",
           "items = load(); assert items != []; items = load(); assert Enum.all?(items, &valid?/1)",
           "unsafe_collection"},
          {"filtered derivation", "",
           "items = load(); assert items != []; items = Enum.filter(items, &valid?/1); assert Enum.all?(items, &valid?/1)",
           "unsafe_collection"},
          {"different filtered collection", "",
           "items = load(); assert items != []; selected = Enum.filter(items, &valid?/1); assert Enum.all?(selected, &valid?/1)",
           "unsafe_collection"},
          {"empty attribute", "@items []", "assert Enum.all?(@items, &valid?/1)",
           "unsafe_collection"},
          {"unknown attribute", "@items load()", "assert Enum.all?(@items, &valid?/1)",
           "unsafe_collection"},
          {"literal true", "", "assert true", "literal_true"},
          {"glob comprehension", "",
           "for path <- Path.wildcard(\"test/*.exs\"), do: assert valid?(path)",
           "glob_without_count"},
          {"rebound glob", "",
           "files = Path.wildcard(\"test/*.exs\"); assert files != []; files = Path.wildcard(\"none/*\"); for path <- files, do: assert valid?(path)",
           "glob_without_count"},
          {"piped universal", "", "items = load(); assert items |> Enum.all?(&valid?/1)",
           "unsafe_collection"}
        ] do
      @tag :tmp_dir
      test "rejects #{label} with the intended finding", %{tmp_dir: tmp} do
        source = collection_source(unquote(prefix), unquote(body))
        collection_fixture!(tmp, source)
        {output, code} = collection_run(tmp)
        assert code == 1, output
        assert output =~ "collection new_or_increased #{unquote(category)}"
        refute output =~ "parse_error"
        refute output =~ "invalid_baseline"
      end
    end

    for {label, prefix, body} <- [
          {"same branch", "",
           "items = load(); if flag() do assert items != []; assert Enum.all?(items, &valid?/1) end"},
          {"literal nonempty", "", "assert Enum.all?([1, 2], &valid?/1)"},
          {"concrete attribute", "@items [1, 2]", "assert Enum.all?(@items, &valid?/1)"},
          {"attribute alias", "@items [1]; @copy @items", "assert Enum.all?(@copy, &valid?/1)"},
          {"positive length", "",
           "items = load(); assert length(items) == 2; assert Enum.all?(items, &valid?/1)"},
          {"positive count", "",
           "items = load(); assert Enum.count(items) >= 1; assert Enum.all?(items, &valid?/1)"},
          {"independent glob cardinality", "",
           "files = Path.wildcard(\"test/*.exs\"); assert length(files) > 0; for path <- files, do: assert valid?(path)"},
          {"explicit empty", "", "assert load() == []; refute load() != []"},
          {"positive existential", "", "assert Enum.any?(load(), &valid?/1)"},
          {"quoted fixtures", "",
           "fixture = quote do assert true; assert Enum.all?(load(), &valid?/1) end; assert is_tuple(fixture)"},
          {"string and sigil data", "",
           "fixture = \"assert true\"; sigil = ~S|assert Enum.all?(load(), &valid?/1)|; assert is_binary(fixture <> sigil)"}
        ] do
      @tag :tmp_dir
      test "accepts #{label}", %{tmp_dir: tmp} do
        collection_fixture!(tmp, collection_source(unquote(prefix), unquote(body)))
        {output, code} = collection_run(tmp)
        assert code == 0, output
        assert output =~ "findings=0 delta=0"
      end
    end

    @tag :tmp_dir
    test "deleting only the guard changes source and adds one unsafe occurrence", %{tmp_dir: tmp} do
      source =
        collection_source(
          "",
          "items = load(); assert items != []; assert Enum.all?(items, &valid?/1)"
        )

      collection_fixture!(tmp, source)
      assert {_, 0} = collection_run(tmp)
      changed = String.replace(source, "assert items != []; ", "")
      assert changed != source
      write_test!(tmp, changed)
      {output, code} = collection_run(tmp)
      assert code == 1, output
      assert output =~ "unsafe_collection"
      assert output =~ "count=1 baseline=0"
    end

    @tag :tmp_dir
    test "duplicate exempt occurrence, context changes and stale removal are separate deltas", %{
      tmp_dir: tmp
    } do
      source = collection_source("", "assert Enum.all?(load(), &valid?/1)")
      collection_fixture!(tmp, source)
      {output, 1} = collection_run(tmp)

      [_, context, expression] =
        Regex.run(~r/file=test\/sample_test.exs context=(.*?) expression=([0-9a-f]{64})/, output)

      entry = %{
        file: "test/sample_test.exs",
        context: context,
        expression: expression,
        category: "unsafe_collection",
        count: 1,
        reason: "Synthetic exact occurrence"
      }

      File.write!(Path.join(tmp, "baseline.exs"), inspect([entry], limit: :infinity))
      assert {_, 0} = collection_run(tmp)

      doubled =
        String.replace(
          source,
          "assert Enum.all?(load(), &valid?/1)",
          "assert Enum.all?(load(), &valid?/1); assert Enum.all?(load(), &valid?/1)"
        )

      assert doubled != source
      write_test!(tmp, doubled)
      {output, 1} = collection_run(tmp)
      assert output =~ "count=2 baseline=1"
      moved = String.replace(source, "synthetic collection", "different context")
      assert moved != source
      write_test!(tmp, moved)
      {output, 1} = collection_run(tmp)
      assert output =~ "new_or_increased"
      assert output =~ "stale_baseline"
      write_test!(tmp, collection_source("", "assert load() == []"))
      {output, 1} = collection_run(tmp)
      assert output =~ "stale_baseline"
      assert File.read!(Path.join(tmp, "baseline.exs")) == inspect([entry], limit: :infinity)
    end

    @tag :tmp_dir
    test "same expression in distinct contexts and discovery order preserve identity", %{
      tmp_dir: tmp
    } do
      source = collection_source("", "assert true")
      collection_fixture!(tmp, source)
      second = String.replace(source, "synthetic collection", "another context")
      assert second != source
      File.write!(Path.join(tmp, "test/z_test.exs"), second)
      {first, 1} = collection_run(tmp)
      File.rm!(Path.join(tmp, "test/z_test.exs"))
      write_test!(tmp, source)
      File.write!(Path.join(tmp, "test/z_test.exs"), second)
      {again, 1} = collection_run(tmp)
      assert first == again

      findings =
        first
        |> String.split("\n")
        |> Enum.filter(&String.contains?(&1, "collection literal_true count="))

      assert length(findings) == 2
      assert findings == Enum.sort(findings)
    end

    for {label, category} <- [
          {"malformed", "parse_error"},
          {"unreadable", "read_error"},
          {"empty companion", "scope_empty"},
          {"subset", "scope_mismatch"}
        ] do
      @tag :tmp_dir
      test "fails closed on #{label} source/scope", %{tmp_dir: tmp} do
        collection_fixture!(tmp, collection_source("", "assert load() == []"))

        case unquote(label) do
          "malformed" ->
            write_test!(tmp, "defmodule Broken do\n")

          "unreadable" ->
            File.chmod!(Path.join(tmp, "test/sample_test.exs"), 0o000)

          "empty companion" ->
            File.rm!(Path.join(tmp, "packages/crosswake_sigra/test/baseline_test.exs"))

          "subset" ->
            hidden = Path.join(tmp, "packages/crosswake_sigra/test/.hidden_test.exs")
            File.write!(hidden, "defmodule Hidden do end")
        end

        on_exit(fn -> File.chmod(Path.join(tmp, "test/sample_test.exs"), 0o644) end)
        {output, code} = collection_run(tmp)
        assert code == 1, output
        assert output =~ unquote(category)
      end
    end
  end

  describe "the repository itself" do
    @tag :tmp_dir
    test "is clean: no mutation control and no open finding asserts nothing" do
      {output, code} = run(@repo_root)

      assert code == 0, "the repository has regressed:\n#{output}"
      assert output =~ "no mutation control asserts a change it never verified"
      assert output =~ "every open finding's test citation resolves to a real test"
    end
  end

  describe "mutation controls" do
    @tag :tmp_dir
    test "a shared helper that never compares its mutation to the source FAILS", %{tmp_dir: tmp} do
      write_test!(tmp, """
      defmodule SampleTest do
        defp mutate(source) do
          mutated = String.replace(source, "a", "b")
          String.replace(source, source, mutated)
        end
      end
      """)

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 1
      assert output =~ "absence.mutation_control_asserts_change"
      assert output =~ "mutate"
    end

    @tag :tmp_dir
    test "the same helper PASSES once it compares the mutation to its source", %{tmp_dir: tmp} do
      write_test!(tmp, """
      defmodule SampleTest do
        defp mutate(source) do
          mutated = String.replace(source, "a", "b")
          if mutated == source, do: raise("mutation was a no-op")
          mutated
        end
      end
      """)

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "an inline mutation in a test body is NOT flagged", %{tmp_dir: tmp} do
      # Deliberately out of scope: a no-op there fails loudly, because such tests
      # assert a SPECIFIC failure that an unmutated input cannot produce, and the
      # replacement sits three lines above its own assertion where a reader sees
      # it. Flagging these produced 25 findings and zero bugs.
      write_test!(tmp, """
      defmodule SampleTest do
        test "rejects a broken script" do
          mutated = String.replace(File.read!("x"), "set -e", "set +e")
          assert scan(mutated) == {:error, :missing_strict_mode}
        end
      end
      """)

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end
  end

  describe "open finding citations" do
    @tag :tmp_dir
    test "a citation to a line holding no test FAILS", %{tmp_dir: tmp} do
      write_cited_test!(tmp)
      write_todo!(tmp, "Broken here: `test/cited_test.exs:99`.")

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 1
      assert output =~ "absence.open_finding_citation_resolves"
      assert output =~ "0 tests, 0 failures"
    end

    @tag :tmp_dir
    test "a citation to a real test line PASSES", %{tmp_dir: tmp} do
      write_cited_test!(tmp)
      write_todo!(tmp, "Asserted by `test/cited_test.exs:2`.")

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "a citation inside a fenced block is NOT flagged", %{tmp_dir: tmp} do
      write_cited_test!(tmp)

      write_todo!(tmp, """
      Reproduce with:

      ```
      mix test test/cited_test.exs:99
      ```
      """)

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "a citation in an entry marked resolved is NOT flagged", %{tmp_dir: tmp} do
      write_cited_test!(tmp)

      write_todo!(tmp, """
      - Broken here: `test/cited_test.exs:99`
        status: resolved
      """)

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "a citation under a heading declaring resolution is NOT flagged", %{tmp_dir: tmp} do
      # A record usually declares resolution once, above its items.
      write_cited_test!(tmp)

      write_todo!(tmp, """
      ## Pre-existing failures (out of scope, RESOLVED in Phase 135)

      1. `test/cited_test.exs:99` — long since repaired.
      """)

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "a citation to a file that does not exist is NOT flagged", %{tmp_dir: tmp} do
      # Verified empirically: `mix test missing.exs:21` exits 1 and says so. It is
      # loud, so it is not this guard's defect class — and such a path is usually
      # inside a generated host or another repository.
      write_todo!(tmp, "Failed at `test/not_in_this_repo_test.exs:21`.")

      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
    end
  end

  describe "invocation" do
    @tag :tmp_dir
    test "root floor: a nonexistent --root exits 2 before scanning", %{tmp_dir: tmp} do
      missing = Path.join(tmp, "never-created")
      {output, code} = run_argv(["--root", missing])

      assert code == 2, output
      assert output =~ "[crosswake] FAIL: root does not exist: #{Path.expand(missing)}"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "root floor: a --root that is a file exits 2", %{tmp_dir: tmp} do
      file = Path.join(tmp, "plain-file")
      File.write!(file, "x")
      {output, code} = run_argv(["--root", file])

      assert code == 2, output
      assert output =~ "[crosswake] FAIL: root is not a directory: #{Path.expand(file)}"
      refute output =~ "OK:"
    end

    test "root floor: a bare --root with no value exits 2" do
      {output, code} = run_argv(["--root"])

      assert code == 2, output
      refute output =~ "OK:"
    end

    test "root floor: an unknown argument exits 2" do
      {output, code} = run_argv(["--rot", "x"])

      assert code == 2, output
      assert output =~ "--rot"
      refute output =~ "OK:"
    end
  end

  describe "scope floors" do
    @tag :tmp_dir
    test "test-files scope floor: an empty test tree fails with expected scope is empty", %{
      tmp_dir: tmp
    } do
      baseline!(tmp)
      File.rm!(Path.join(tmp, "test/baseline_test.exs"))
      {output, code} = run(tmp, @one)

      assert code == 1, output
      assert output =~ "scope test-files: expected scope is empty"
      assert output =~ "content checks were skipped"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "todos scope floor: an empty .planning/todos fails", %{tmp_dir: tmp} do
      baseline!(tmp)
      File.rm!(Path.join(tmp, ".planning/todos/TODO-000-baseline.md"))
      {output, code} = run(tmp, @one)

      assert code == 1, output
      assert output =~ "scope todos:"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "seeds scope floor: an empty .planning/seeds fails", %{tmp_dir: tmp} do
      baseline!(tmp)
      File.rm!(Path.join(tmp, ".planning/seeds/SEED-000-baseline.md"))
      {output, code} = run(tmp, @one)

      assert code == 1, output
      assert output =~ "scope seeds:"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "deferred-items scope floor: no deferred-items.md fails", %{tmp_dir: tmp} do
      baseline!(tmp)
      File.rm!(Path.join(tmp, ".planning/phases/00-baseline/deferred-items.md"))
      {output, code} = run(tmp, @one)

      assert code == 1, output
      assert output =~ "scope deferred-items:"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "test-files pin floor: a count below --min-test-files fails", %{tmp_dir: tmp} do
      baseline!(tmp)
      {output, code} = run(tmp, ["--min-test-files", "2"])

      assert code == 1, output
      assert output =~ "scope test-files:"
      assert output =~ "scanned=1"
      assert output =~ "pin=2"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "test-files full-scope floor: a test file in a dot-directory makes the scope a proper subset",
         %{tmp_dir: tmp} do
      baseline!(tmp)
      hidden = Path.join(tmp, "test/.hid/h_test.exs")
      File.mkdir_p!(Path.dirname(hidden))
      File.write!(hidden, "defmodule HTest do\nend\n")
      {output, code} = run(tmp, @one)

      assert code == 1, output
      assert output =~ "actual scope is a proper subset of expected scope"
      refute output =~ "OK:"
    end

    @tag :tmp_dir
    test "test-files regular-file floor: a directory named x.exs is not counted", %{tmp_dir: tmp} do
      baseline!(tmp)
      File.mkdir_p!(Path.join(tmp, "test/x.exs"))

      {output, code} = run(tmp, ["--min-test-files", "2"])
      assert code == 1, output
      assert output =~ "scanned=1"

      {output, code} = run(tmp, @one)
      assert code == 0, output
    end

    @tag :tmp_dir
    test "test-files pin floor: a count equal to the pin passes and prints the counts", %{
      tmp_dir: tmp
    } do
      baseline!(tmp)
      {output, code} = run(tmp, @one)

      assert code == 0, output
      assert output =~ "scanned 1 test files, pin 1"
    end

    test "all scopes pin floor: the repository itself meets every pinned minimum" do
      {output, code} = run(@repo_root)

      assert code == 0, output
      assert [_, scanned, pin] = Regex.run(~r/scanned (\d+) test files, pin (\d+)/, output)
      assert String.to_integer(scanned) >= String.to_integer(pin)
      assert output =~ ~r/todos [1-9]\d*, seeds [1-9]\d*, deferred-items [1-9]\d*/
    end
  end

  defp run(root), do: run(root, [])

  defp collection_source(prefix, body),
    do: "defmodule Synthetic do\n#{prefix}\ntest \"synthetic collection\" do\n#{body}\nend\nend\n"

  defp collection_fixture!(tmp, source) do
    baseline!(tmp)
    write_test!(tmp, source)
    File.write!(Path.join(tmp, "baseline.exs"), "[]\n")
  end

  defp collection_run(tmp),
    do:
      run(
        tmp,
        @one ++
          [
            "--collections-mode",
            "enforce",
            "--collections-baseline",
            Path.join(tmp, "baseline.exs")
          ]
      )

  defp run(root, extra_argv), do: run_argv(["--root", Path.expand(root) | extra_argv])

  defp run_argv(argv) do
    System.cmd("elixir", [@script | argv], stderr_to_stdout: true, cd: @repo_root)
  end

  # Exactly one of each scope: the smallest tree on which every scope is non-empty.
  defp baseline!(tmp) do
    for project <- ~w(chimeway rindle rulestead sigra threadline) do
      path = Path.join(tmp, "packages/crosswake_#{project}/test/baseline_test.exs")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "defmodule Baseline do\nend\n")
    end

    for {rel, body} <- [
          {"test/baseline_test.exs", "defmodule BaselineTest do\nend\n"},
          {".planning/todos/TODO-000-baseline.md", "---\nid: TODO-000\n---\n"},
          {".planning/seeds/SEED-000-baseline.md", "---\nid: SEED-000\n---\n"},
          {".planning/phases/00-baseline/deferred-items.md", "# Deferred\n"}
        ] do
      path = Path.join(tmp, rel)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, body)
    end
  end

  defp write_test!(tmp, source) do
    path = Path.join(tmp, "test/sample_test.exs")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, source)
  end

  defp write_cited_test!(tmp) do
    path = Path.join(tmp, "test/cited_test.exs")
    File.mkdir_p!(Path.dirname(path))

    File.write!(path, """
    defmodule CitedTest do
      test "the cited behaviour" do
        assert true
      end
    end
    """)
  end

  defp write_todo!(tmp, body) do
    path = Path.join(tmp, ".planning/todos/TODO-999-sample.md")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "---\nid: TODO-999\n---\n\n" <> body <> "\n")
  end
end
