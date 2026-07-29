defmodule Crosswake.Proof.Phase153_1GateIntegrityTest do
  @moduledoc """
  GATE-01 / GATE-02: no two workflow jobs may emit the same merge-blocking check name.

  Branch protection matches required contexts by STRING. If two jobs share a name, GitHub cannot
  tell them apart, so a red run can be masked by a green one — the gate fails open while still
  reporting as fully registered.

  Three such collisions survived in this repo because `check_required_checks_registered.sh`
  asserted that each declared name was *present* in branch protection but never that a name mapped
  to exactly *one* job. These tests cover both halves: the real workflow tree is clean, and the
  assertion that keeps it clean is not vacuous.
  """
  use ExUnit.Case, async: true

  @discover "script/list_merge_blocking_checks.py"
  @checker "script/check_required_checks_registered.sh"

  defp emitters do
    {out, 0} = System.cmd("python3", [@discover, "--emitters"])

    out
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [name, path, jid] = String.split(line, "\t")
      %{name: name, path: path, job: jid}
    end)
  end

  test "every merge-blocking check name is emitted by exactly one job" do
    collisions =
      emitters()
      |> Enum.group_by(& &1.name)
      |> Enum.filter(fn {_name, es} -> length(es) > 1 end)

    assert collisions == [],
           """
           Duplicate merge-blocking check name(s) found. Branch protection matches by string,
           so these are indistinguishable and the gate can fail open:

           #{Enum.map_join(collisions, "\n", fn {name, es} -> "  #{name}\n" <> Enum.map_join(es, "\n", &"    - #{&1.path} (#{&1.job})") end)}

           Fix: rename the later-phase emitter, keeping the "merge-blocking" substring so
           auto-discovery still finds it.
           """
  end

  test "auto-discovery still finds every emitter (the 'merge-blocking' substring is intact)" do
    # A rename that drops the substring silently stops the check being required — the exact
    # failure mode GATE-01's fix could have introduced.
    for %{name: name, path: path} <- emitters() do
      assert String.contains?(String.downcase(name), "merge-blocking"),
             "#{path}: #{inspect(name)} was discovered but lacks the 'merge-blocking' substring"
    end
  end

  @tag :tmp_dir
  test "negative control: the uniqueness assertion fails on two jobs sharing a name", %{
    tmp_dir: tmp
  } do
    # Run the real script against a synthetic tree. The script derives its root from BASH_SOURCE,
    # so copying it into the fixture makes it operate on the fixture's workflows.
    File.mkdir_p!(Path.join(tmp, "script"))
    File.mkdir_p!(Path.join(tmp, ".github/workflows"))
    File.cp!(@discover, Path.join(tmp, @discover))
    File.cp!(@checker, Path.join(tmp, @checker))

    workflow = fn wf_name, job_id ->
      """
      name: #{wf_name}
      on: [push]
      jobs:
        #{job_id}:
          name: merge-blocking duplicated proof
          runs-on: ubuntu-latest
          steps:
            - run: "true"
      """
    end

    File.write!(Path.join(tmp, ".github/workflows/a.yml"), workflow.("A", "alpha"))
    File.write!(Path.join(tmp, ".github/workflows/b.yml"), workflow.("B", "beta"))

    {out, status} = System.cmd("bash", [@checker], cd: tmp, stderr_to_stdout: true)

    assert status == 1,
           "expected the uniqueness assertion to fail (exit 1), got #{status}:\n#{out}"

    assert out =~ "duplicate-merge-blocking-name"
    # Both colliding sources must be named — a failure that does not say WHERE is not actionable.
    assert out =~ "a.yml"
    assert out =~ "b.yml"
  end

  test "the gate scripts are bash 3.2 compatible (macOS ships 3.2.57)" do
    # Caught in CI on the first run of this file: check_required_checks_registered.sh used
    # `mapfile`, which is bash 4.0+. macOS is frozen at bash 3.2.57 (the last GPLv2 release), so on
    # every macOS runner the script died with "mapfile: command not found" and exit 127 BEFORE
    # checking anything. A gate script that cannot run is indistinguishable from one that passes.
    #
    # Guard the constructs that actually bit, not a general lint: mapfile/readarray (4.0),
    # associative arrays (4.0), and case-conversion expansions (4.0).
    for script <- [@checker, "script/register_required_checks.sh"] do
      src = File.read!(script)

      for {pattern, feature} <- [
            {~r/^\s*(mapfile|readarray)\b/m, "mapfile/readarray"},
            {~r/declare\s+-A\b/, "associative arrays (declare -A)"},
            {~r/\$\{[a-zA-Z_][a-zA-Z0-9_]*(,,|\^\^)\}/, "case-conversion expansion"}
          ] do
        refute Regex.match?(pattern, src),
               "#{script} uses #{feature}, which is bash 4.0+. macOS ships bash 3.2.57, " <>
                 "so this script would exit 127 there without checking anything."
      end
    end
  end

  @tag :tmp_dir
  test "negative control: a unique-name tree passes the uniqueness assertion", %{tmp_dir: tmp} do
    # Guards the other direction: a check that always fails is as useless as one that never does.
    File.mkdir_p!(Path.join(tmp, "script"))
    File.mkdir_p!(Path.join(tmp, ".github/workflows"))
    File.cp!(@discover, Path.join(tmp, @discover))
    File.cp!(@checker, Path.join(tmp, @checker))

    File.write!(Path.join(tmp, ".github/workflows/a.yml"), """
    name: A
    on: [push]
    jobs:
      alpha:
        name: merge-blocking alpha proof
        runs-on: ubuntu-latest
        steps:
          - run: "true"
    """)

    {out, _status} = System.cmd("bash", [@checker], cd: tmp, stderr_to_stdout: true)

    refute out =~ "duplicate-merge-blocking-name"
  end
end
