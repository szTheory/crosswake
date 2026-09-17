defmodule Crosswake.Proof.Phase169ExitContractGuardTest do
  @moduledoc """
  Merge-blocking guard pinning the exit-code contract (FID-02, D-24) so no
  verification entry point's literal exit values can drift from the declared
  table below without turning this test red.

  `@entry_points` IS the contract; each file's source IS the implementation.
  This test asserts they are equal — in both directions — for every entry
  point, and separately measures that it actually located at least
  #{4} of them, so a regex that silently stopped matching cannot reduce this
  guard to asserting nothing (the absence-scored-as-success class of defect
  this milestone exists to close, PR #173).

  Does not duplicate or contradict
  `test/crosswake/proof/phase135_ci_ops_proof_test.exs:526-533`, which already
  locks `exit 3` as NOT a pass for `check_required_checks_registered.sh` — that
  test covers semantics, this one covers the literal-value table.
  """

  use ExUnit.Case, async: true

  @located_floor 4
  @header_comment "# exit contract: 0 clean / 1 defect found / 3 could not verify"

  # Declared per-entry-point contract (D-24). `expected` is the exact set of
  # literal exit values this file must be found to contain — equality is
  # asserted in BOTH directions, never mere containment. `header_required`
  # marks the subset D-16 requires to carry the one-line canonical-contract
  # pointer comment byte-for-byte.
  @entry_points [
    %{
      id: "Crosswake.ReleaseStatus.exit_code/1 (source clauses)",
      path: "lib/crosswake/release_status.ex",
      kind: :exit_code_function,
      expected: MapSet.new([0, 1, 3]),
      header_required: false
    },
    %{
      id: "mix crosswake.release.status",
      path: "lib/mix/tasks/crosswake.release.status.ex",
      kind: :case_arms,
      expected: MapSet.new([0, 1, 3]),
      header_required: true
    },
    %{
      id: "script/check_release_workflow_integrity.exs",
      path: "script/check_release_workflow_integrity.exs",
      kind: :if_do_else,
      expected: MapSet.new([0, 1]),
      header_required: true
    },
    %{
      id: "script/check_required_checks_registered.sh",
      path: "script/check_required_checks_registered.sh",
      kind: :shell,
      expected: MapSet.new([0, 1, 2, 3]),
      header_required: true
    },
    %{
      id: "script/verify_generated_ios_shell.sh",
      path: "script/verify_generated_ios_shell.sh",
      kind: :shell,
      expected: MapSet.new([0, 1, 2, 3]),
      header_required: false
    },
    %{
      id: "script/check_release_version_truth.exs",
      path: "script/check_release_version_truth.exs",
      kind: :system_halt,
      expected: MapSet.new([0, 1, 2]),
      header_required: false
    }
  ]

  describe "Task 1: the exit-code contract is pinned against drift (FID-02, D-24)" do
    test "@entry_points declares at least 6 records, each with an explicit expected exit-value set" do
      assert length(@entry_points) >= 6,
             "expected at least 6 declared entry-point records, got #{length(@entry_points)}"

      for entry <- @entry_points do
        assert %MapSet{} = entry.expected, "#{entry.id}: expected must be a MapSet"
        assert MapSet.size(entry.expected) > 0, "#{entry.id}: expected set must be non-empty"
      end
    end

    test "every entry point's extracted literal exit values equal the declared set exactly, in both directions" do
      results =
        Enum.map(@entry_points, fn entry ->
          assert File.exists?(entry.path),
                 "declared entry point not found on disk: #{entry.path} (#{entry.id})"

          source = File.read!(entry.path)
          extracted = extract_exit_values(entry.kind, source)

          missing = MapSet.difference(entry.expected, extracted)
          extra = MapSet.difference(extracted, entry.expected)

          assert MapSet.size(missing) == 0 and MapSet.size(extra) == 0,
                 "#{entry.id} (#{entry.path}): declared #{inspect(Enum.sort(entry.expected))} " <>
                   "but extracted #{inspect(Enum.sort(extracted))} " <>
                   "(missing: #{inspect(Enum.sort(missing))}, extra: #{inspect(Enum.sort(extra))})"

          {entry.id, MapSet.size(extracted) > 0}
        end)

      located_count = Enum.count(results, fn {_id, located?} -> located? end)

      # D-24 non-vacuity floor: report the count even on success so the SUMMARY
      # can record it. A regex that stopped matching (e.g. a file's style
      # changed) would otherwise silently reduce this guard to asserting
      # nothing while still reporting green.
      assert located_count >= @located_floor,
             "located #{located_count} of #{length(@entry_points)} declared entry points " <>
               "#{inspect(results)} — floor is #{@located_floor}; a regex that stopped matching " <>
               "would silently reduce this guard to asserting nothing"
    end

    test "script/check_release_workflow_integrity.exs contains no System.halt( call (D-14)" do
      source = File.read!("script/check_release_workflow_integrity.exs")

      refute source =~ "System.halt(",
             "expected D-14's System.stop/Process.sleep replacement; found a System.halt( call"
    end

    test "each entry point D-16 requires to carry the exit-contract header comment carries it byte-for-byte" do
      for entry <- @entry_points, entry.header_required do
        source = File.read!(entry.path)

        assert String.contains?(source, @header_comment),
               "#{entry.path} is missing the byte-for-byte D-16 header comment: #{inspect(@header_comment)}"
      end
    end

    test "Crosswake.ReleaseStatus.exit_code/1's @doc names 0, 1, 3, and reserves 2 (read via Code.fetch_docs/1)" do
      doc = exit_code_doc_string()

      refute doc == "", "expected a non-empty @doc for Crosswake.ReleaseStatus.exit_code/1"
      assert doc =~ "0", "expected the @doc to name exit code 0"
      assert doc =~ "1", "expected the @doc to name exit code 1"
      assert doc =~ "3", "expected the @doc to name exit code 3"

      assert doc =~ ~r/2.*reserved/is,
             "expected the @doc to contain a sentence reserving 2, got: #{inspect(doc)}"
    end

    test "mutation test: a changed literal exit value makes the guard report a mismatch (teeth proof)" do
      source = File.read!("script/check_release_version_truth.exs")
      mutated = mutate_literal(source, "System.halt(1)", "System.halt(9)")

      tmp_path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase169-04-exit-contract-mutation-#{System.unique_integer([:positive])}.exs"
        )

      File.write!(tmp_path, mutated)
      on_exit(fn -> File.rm(tmp_path) end)

      extracted = extract_exit_values(:system_halt, File.read!(tmp_path))
      expected = MapSet.new([0, 1, 2])

      refute extracted == expected,
             "expected the mutated copy's extracted set to diverge from #{inspect(Enum.sort(expected))}, " <>
               "got #{inspect(Enum.sort(extracted))}"
    end

    test "the mutation helper raises when its target pattern is absent from the source" do
      source = File.read!("script/check_release_version_truth.exs")

      assert_raise RuntimeError, ~r/found no/, fn ->
        mutate_literal(source, "System.halt(999)", "System.halt(4)")
      end
    end
  end

  # -- extraction --------------------------------------------------------
  #
  # Patterns appropriate to each file kind (D-24 action text):
  #   :shell               - `exit <n>` (bash exit statements)
  #   :system_halt         - `System.halt(<n>)` literal-argument calls
  #   :case_arms           - literal integer case-clause heads matching the
  #                          `exit_code/1` result inside `crosswake.release.status.ex`
  #   :if_do_else          - literal `do:`/`else:` branch integers (the
  #                          `if failures == [], do: 0, else: 1` idiom)
  #   :exit_code_function  - literal `def exit_code(...), do: <n>` clauses,
  #                          skipping the delegating `exit_code(status)` clause

  defp extract_exit_values(:shell, source) do
    ~r/\bexit\s+(\d+)\b/
    |> Regex.scan(source, capture: :all_but_first)
    |> to_int_set()
  end

  defp extract_exit_values(:system_halt, source) do
    ~r/System\.halt\((\d+)\)/
    |> Regex.scan(source, capture: :all_but_first)
    |> to_int_set()
  end

  defp extract_exit_values(:case_arms, source) do
    ~r/^\s*(\d+)\s*->/m
    |> Regex.scan(source, capture: :all_but_first)
    |> to_int_set()
  end

  defp extract_exit_values(:if_do_else, source) do
    do_values = Regex.scan(~r/,\s*do:\s*(\d+)\b/, source, capture: :all_but_first)
    else_values = Regex.scan(~r/,\s*else:\s*(\d+)\b/, source, capture: :all_but_first)
    to_int_set(do_values ++ else_values)
  end

  defp extract_exit_values(:exit_code_function, source) do
    ~r/def exit_code\([^)]*\),\s*do:\s*(\d+)\b/
    |> Regex.scan(source, capture: :all_but_first)
    |> to_int_set()
  end

  defp to_int_set(matches) do
    matches
    |> List.flatten()
    |> Enum.map(&String.to_integer/1)
    |> MapSet.new()
  end

  defp mutate_literal(source, from, to) do
    unless String.contains?(source, from) do
      raise "found no #{inspect(from)} to mutate in source"
    end

    String.replace(source, from, to, global: false)
  end

  defp exit_code_doc_string do
    case Code.fetch_docs(Crosswake.ReleaseStatus) do
      {:docs_v1, _anno, _lang, _format, _moduledoc, _meta, docs} ->
        docs
        |> Enum.find(fn {{kind, name, arity}, _anno, _sig, _doc, _meta} ->
          kind == :function and name == :exit_code and arity == 1
        end)
        |> case do
          {_key, _anno, _sig, %{"en" => text}, _meta} -> text
          _ -> ""
        end

      _ ->
        ""
    end
  end
end
