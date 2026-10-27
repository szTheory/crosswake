ExUnit.start()

defmodule AbsenceTracer do
  use ExUnit.Case

  test "known glob owners establish independent cardinality in each test" do
    {output, code} = System.cmd("elixir", ["script/check_absence_is_not_success.exs", "--collections-mode", "report"], stderr_to_stdout: true)
    assert code == 0, output
    glob_findings = output |> String.split("\n") |> Enum.filter(&String.contains?(&1, "collection glob_without_count"))
    refute Enum.any?(glob_findings, &String.contains?(&1, "phase132_compat_matrix_drift_test.exs"))
    refute Enum.any?(glob_findings, &String.contains?(&1, "phase165_ci_integrity_test.exs"))
  end

  test "deleting only cardinality evidence creates an unsafe occurrence" do
    root = Path.join(System.tmp_dir!(), "absence-tracer-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(root) end)

    for project <- [
          "test"
          | Enum.map(
              ~w(chimeway rindle rulestead sigra threadline),
              &"packages/crosswake_#{&1}/test"
            )
        ] do
      File.mkdir_p!(Path.join(root, project))

      File.write!(
        Path.join(root, project <> "/baseline_test.exs"),
        "defmodule Baseline do\nend\n"
      )
    end

    for rel <- [
          ".planning/todos/baseline.md",
          ".planning/seeds/baseline.md",
          ".planning/phases/baseline/deferred-items.md"
        ] do
      File.mkdir_p!(Path.dirname(Path.join(root, rel)))
      File.write!(Path.join(root, rel), "# Synthetic baseline\n")
    end

    baseline = Path.join(root, "baseline.exs")
    File.write!(baseline, "[]\n")
    path = Path.join(root, "test/sample_test.exs")

    source =
      "defmodule Sample do\n test \"collection\" do\n items = load()\n assert items != []\n assert Enum.all?(items, &valid?/1)\n end\nend\n"

    File.write!(path, source)

    args = [
      "script/check_absence_is_not_success.exs",
      "--root",
      root,
      "--min-test-files",
      "1",
      "--collections-mode",
      "enforce",
      "--collections-baseline",
      baseline
    ]

    {output, code} = System.cmd("elixir", args, stderr_to_stdout: true)
    assert code == 0, output
    changed = String.replace(source, " assert items != []\n", "")
    assert changed != source
    File.write!(path, changed)
    {output, code} = System.cmd("elixir", args, stderr_to_stdout: true)
    assert code == 1, output
    assert output =~ "unsafe_collection"
    assert output =~ "new_or_increased"
  end
end
