defmodule Crosswake.Proof.Phase170VacuousAssertionLedgerTest do
  @moduledoc """
  VAC-01 / D-04 / D-05 / D-06 / D-14: the collection-assertion inventory's committed ledger must
  be COMPLETE (every live call site has a row, every row resolves to a live call site) and its
  own completeness test must be capable of going red.

  Per D-06 this module asserts LEDGER COMPLETENESS only — never that a site is actually guarded.
  That second, tree-wide assertion is VACG-01 and stays deferred (Future Requirements); asserting
  it here would blur the exact line that lets this tree-wide inventory coexist with SC#3's
  "no merge-blocking guard yet" prohibition.

  Mirrors Phase 169's `release.scanner.roster_exact` proof
  (test/crosswake/proof/phase169_diagnostic_legibility_test.exs, "Task 3" describe block): a
  clean-run assertion, a both-directions completeness assertion, and a real-subprocess mutation
  control that proves the completeness assertion is not itself vacuous (D-14).
  """

  use ExUnit.Case, async: true

  @script "script/inventory_collection_assertions.exs"
  @ledger "script/collection_assertion_ledger.json"

  describe "Task 1: a clean run against the committed ledger" do
    test "elixir script/inventory_collection_assertions.exs --check exits 0 and prints [crosswake] OK: naming a non-zero row count" do
      {output, exit_code} = run_check(File.cwd!())

      assert exit_code == 0, output
      assert output =~ ~r/^\[crosswake\] OK: \d+ classified collection-assertion site\(s\)/m

      [count_str] =
        Regex.run(~r/\[crosswake\] OK: (\d+) classified/, output, capture: :all_but_first)

      assert String.to_integer(count_str) > 0,
             "expected the committed ledger to cover at least one real site:\n#{output}"
    end

    test "running --emit-snapshot twice on an unchanged tree produces byte-identical stdout" do
      committed = @ledger |> File.read!() |> JSON.decode!()

      {first, exit_1} = run_emit_snapshot(File.cwd!(), committed["scope"])
      {second, exit_2} = run_emit_snapshot(File.cwd!(), committed["scope"])

      assert exit_1 == 0 and exit_2 == 0
      assert first == second
    end
  end

  describe "Task 1: ledger completeness, both directions (D-06 / roster_exact one level down)" do
    test "the regenerated snapshot's row keys equal the committed snapshot's row keys exactly" do
      committed = @ledger |> File.read!() |> JSON.decode!()

      {regenerated_output, regen_exit} = run_emit_snapshot(File.cwd!(), committed["scope"])
      assert regen_exit == 0, regenerated_output

      regenerated = JSON.decode!(regenerated_output)

      committed_keys = committed["rows"] |> Enum.map(& &1["key"]) |> MapSet.new()
      regenerated_keys = regenerated["rows"] |> Enum.map(& &1["key"]) |> MapSet.new()

      unclassified = MapSet.difference(regenerated_keys, committed_keys)
      orphans = MapSet.difference(committed_keys, regenerated_keys)

      assert MapSet.size(unclassified) == 0 and MapSet.size(orphans) == 0,
             "unclassified (live, not in committed snapshot): #{inspect(MapSet.to_list(unclassified))}; " <>
               "orphan (in committed snapshot, not live): #{inspect(MapSet.to_list(orphans))}"
    end

    test "every row in the committed ledger has exactly the seven schema keys and a non-empty string rationale" do
      committed = @ledger |> File.read!() |> JSON.decode!()
      assert committed["rows"] != [], "expected the committed ledger to be non-empty"

      Enum.each(committed["rows"], fn row ->
        assert Enum.sort(Map.keys(row)) ==
                 Enum.sort(~w(key shape bucket rationale display enclosing expression)),
               "row #{inspect(row["key"])} has the wrong key set: #{inspect(Map.keys(row))}"

        assert is_binary(row["rationale"]) and String.length(row["rationale"]) >= 1,
               "row #{inspect(row["key"])} has a non-string or empty rationale: #{inspect(row["rationale"])}"
      end)
    end
  end

  describe "Task 1: non-vacuity control (D-14) — a mutated ledger copy must go RED" do
    test "deleting one row from a copy of the committed ledger makes --check exit non-zero and name that row's display" do
      committed = @ledger |> File.read!() |> JSON.decode!()
      [removed_row | remaining_rows] = committed["rows"]

      mutated = %{committed | "rows" => remaining_rows}
      mutated_path = tmp_json_path("crosswake-phase170-ledger-mutation")
      File.write!(mutated_path, JSON.encode!(mutated))
      on_exit(fn -> File.rm(mutated_path) end)

      {output, exit_code} =
        System.cmd("elixir", [@script, "--ledger", mutated_path, "--check"],
          stderr_to_stdout: true,
          cd: File.cwd!()
        )

      assert exit_code != 0,
             "expected a ledger missing one row to make --check exit non-zero:\n#{output}"

      assert output =~ "[crosswake] FAIL:",
             "expected the house [crosswake] FAIL: prefix in:\n#{output}"

      assert output =~ removed_row["display"],
             "expected the removed row's display value #{inspect(removed_row["display"])} to appear in:\n#{output}"
    end

    test "adding one orphan row to a copy of the committed ledger makes --check exit non-zero and name that row" do
      committed = @ledger |> File.read!() |> JSON.decode!()

      orphan_row = %{
        "key" => "sha256:0000000000000000",
        "shape" => "assert_all",
        "bucket" => "needs-fix",
        "rationale" => "synthetic orphan row for the non-vacuity control",
        "display" => "test/does/not/exist_test.exs:1",
        "enclosing" => "a test that does not exist",
        "expression" => "nonexistent_collection"
      }

      mutated = %{committed | "rows" => [orphan_row | committed["rows"]]}
      mutated_path = tmp_json_path("crosswake-phase170-ledger-orphan")
      File.write!(mutated_path, JSON.encode!(mutated))
      on_exit(fn -> File.rm(mutated_path) end)

      {output, exit_code} =
        System.cmd("elixir", [@script, "--ledger", mutated_path, "--check"],
          stderr_to_stdout: true,
          cd: File.cwd!()
        )

      assert exit_code != 0,
             "expected a ledger with an orphan row to make --check exit non-zero:\n#{output}"

      assert output =~ "[crosswake] FAIL:"
      assert output =~ orphan_row["display"]
    end
  end

  describe "VAC-01 adjacency edge: two identical adjacent assertions produce two distinct rows" do
    @tag :tmp_dir
    test "a duplicated assertion inside one test block yields two rows with different keys", %{
      tmp_dir: tmp
    } do
      write_fixture!(tmp, "test/duplicate_test.exs", """
      defmodule DuplicateTest do
        use ExUnit.Case

        test "the duplicated assertion" do
          collection = [1, 2, 3]
          assert Enum.all?(collection, &(&1 > 0))
          assert Enum.all?(collection, &(&1 > 0))
        end
      end
      """)

      {output, exit_code} = run_emit_snapshot(tmp, "test/**/*.exs")
      assert exit_code == 0, output

      %{"rows" => rows} = JSON.decode!(output)
      assert length(rows) == 2

      [first, second] = rows
      assert first["key"] != second["key"]
      assert first["expression"] == second["expression"]
      assert first["enclosing"] == second["enclosing"]
    end
  end

  describe "VAC-01 empty edge: a fixture tree with zero matching call sites" do
    @tag :tmp_dir
    test "emits zero rows and --check exits 0 naming a count of 0", %{tmp_dir: tmp} do
      write_fixture!(tmp, "test/no_matches_test.exs", """
      defmodule NoMatchesTest do
        use ExUnit.Case

        test "asserts something that is not a flagged shape" do
          assert 1 + 1 == 2
        end
      end
      """)

      {snapshot_output, snap_exit} = run_emit_snapshot(tmp, "test/**/*.exs")
      assert snap_exit == 0, snapshot_output
      assert %{"rows" => []} = JSON.decode!(snapshot_output)

      ledger_path = Path.join(tmp, "empty_ledger.json")
      File.write!(ledger_path, snapshot_output)

      {check_output, check_exit} =
        System.cmd(
          "elixir",
          [@script, "--root", Path.expand(tmp), "--ledger", ledger_path, "--check"],
          stderr_to_stdout: true,
          cd: File.cwd!()
        )

      assert check_exit == 0, check_output
      assert check_output =~ ~r/\[crosswake\] OK: 0 classified collection-assertion site\(s\)/
    end
  end

  describe "VAC-01 encoding edge: row keys are content-hashed, not position-hashed" do
    @tag :tmp_dir
    test "re-wrapping a flagged assertion across lines changes no key", %{tmp_dir: tmp} do
      write_fixture!(tmp, "one_line_test.exs", """
      defmodule OneLineTest do
        use ExUnit.Case

        test "single line call" do
          assert Enum.all?(some_collection(), &(&1 > 0))
        end

        defp some_collection, do: [1, 2, 3]
      end
      """)

      write_fixture!(tmp, "wrapped_test.exs", """
      defmodule WrappedTest do
        use ExUnit.Case

        test "single line call" do
          assert Enum.all?(
                   some_collection(),
                   &(&1 > 0)
                 )
        end

        defp some_collection, do: [1, 2, 3]
      end
      """)

      {one_line_output, exit_1} =
        run_emit_snapshot(tmp, "one_line_test.exs")

      {wrapped_output, exit_2} =
        run_emit_snapshot(tmp, "wrapped_test.exs")

      assert exit_1 == 0 and exit_2 == 0

      [%{"key" => one_line_key}] = JSON.decode!(one_line_output)["rows"]
      [%{"key" => wrapped_key}] = JSON.decode!(wrapped_output)["rows"]

      assert one_line_key == wrapped_key,
             "expected re-wrapping across lines to leave the content-hash key unchanged"
    end

    @tag :tmp_dir
    test "renaming an identifier inside the collection expression changes the key", %{
      tmp_dir: tmp
    } do
      write_fixture!(tmp, "collection_a_test.exs", """
      defmodule CollectionATest do
        use ExUnit.Case

        test "single line call" do
          assert Enum.all?(collection_a(), &(&1 > 0))
        end

        defp collection_a, do: [1, 2, 3]
      end
      """)

      write_fixture!(tmp, "collection_b_test.exs", """
      defmodule CollectionBTest do
        use ExUnit.Case

        test "single line call" do
          assert Enum.all?(collection_b(), &(&1 > 0))
        end

        defp collection_b, do: [1, 2, 3]
      end
      """)

      {output_a, exit_a} = run_emit_snapshot(tmp, "collection_a_test.exs")
      {output_b, exit_b} = run_emit_snapshot(tmp, "collection_b_test.exs")

      assert exit_a == 0 and exit_b == 0

      [%{"key" => key_a}] = JSON.decode!(output_a)["rows"]
      [%{"key" => key_b}] = JSON.decode!(output_b)["rows"]

      assert key_a != key_b,
             "expected renaming the collection identifier to change the content-hash key"
    end
  end

  describe "VAC-01 ordering edge: rows are emitted in a total order" do
    test "regenerating the committed-scope ledger twice on an unchanged tree produces byte-identical output" do
      committed = @ledger |> File.read!() |> JSON.decode!()

      {first, exit_1} = run_emit_snapshot(File.cwd!(), committed["scope"])
      {second, exit_2} = run_emit_snapshot(File.cwd!(), committed["scope"])

      assert exit_1 == 0 and exit_2 == 0
      assert first == second

      # Rows must already be sorted by display then key — a total order, not an
      # incidental one, since two rows can never share both fields.
      displays = JSON.decode!(first)["rows"] |> Enum.map(&{&1["display"], &1["key"]})
      assert displays == Enum.sort(displays)
    end
  end

  defp run_check(root) do
    System.cmd("elixir", [@script, "--root", Path.expand(root), "--check"],
      stderr_to_stdout: true,
      cd: File.cwd!()
    )
  end

  defp run_emit_snapshot(root, scope) do
    System.cmd(
      "elixir",
      [@script, "--root", Path.expand(root), "--scope", scope, "--emit-snapshot"],
      stderr_to_stdout: true,
      cd: File.cwd!()
    )
  end

  defp write_fixture!(tmp, name, source) do
    path = Path.join(tmp, name)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, source)
  end

  defp tmp_json_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}.json")
  end
end
