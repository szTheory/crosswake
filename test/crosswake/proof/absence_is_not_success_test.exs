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

  @script "script/check_absence_is_not_success.exs"

  describe "the repository itself" do
    @tag :tmp_dir
    test "is clean: no mutation control and no open finding asserts nothing" do
      {output, code} = run(File.cwd!())

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

      {output, code} = run(tmp)

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

      {output, code} = run(tmp)

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

      {output, code} = run(tmp)

      assert code == 0, output
    end
  end

  describe "open finding citations" do
    @tag :tmp_dir
    test "a citation to a line holding no test FAILS", %{tmp_dir: tmp} do
      write_cited_test!(tmp)
      write_todo!(tmp, "Broken here: `test/cited_test.exs:99`.")

      {output, code} = run(tmp)

      assert code == 1
      assert output =~ "absence.open_finding_citation_resolves"
      assert output =~ "0 tests, 0 failures"
    end

    @tag :tmp_dir
    test "a citation to a real test line PASSES", %{tmp_dir: tmp} do
      write_cited_test!(tmp)
      write_todo!(tmp, "Asserted by `test/cited_test.exs:2`.")

      {output, code} = run(tmp)

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

      {output, code} = run(tmp)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "a citation in an entry marked resolved is NOT flagged", %{tmp_dir: tmp} do
      write_cited_test!(tmp)

      write_todo!(tmp, """
      - Broken here: `test/cited_test.exs:99`
        status: resolved
      """)

      {output, code} = run(tmp)

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

      {output, code} = run(tmp)

      assert code == 0, output
    end

    @tag :tmp_dir
    test "a citation to a file that does not exist is NOT flagged", %{tmp_dir: tmp} do
      # Verified empirically: `mix test missing.exs:21` exits 1 and says so. It is
      # loud, so it is not this guard's defect class — and such a path is usually
      # inside a generated host or another repository.
      write_todo!(tmp, "Failed at `test/not_in_this_repo_test.exs:21`.")

      {output, code} = run(tmp)

      assert code == 0, output
    end
  end

  defp run(root) do
    System.cmd("elixir", [@script, "--root", Path.expand(root)],
      stderr_to_stdout: true,
      cd: File.cwd!()
    )
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
