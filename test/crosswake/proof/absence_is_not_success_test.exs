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

  defp run(root, extra_argv), do: run_argv(["--root", Path.expand(root) | extra_argv])

  defp run_argv(argv) do
    System.cmd("elixir", [@script | argv], stderr_to_stdout: true, cd: @repo_root)
  end

  # Exactly one of each scope: the smallest tree on which every scope is non-empty.
  defp baseline!(tmp) do
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
