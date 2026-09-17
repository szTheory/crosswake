defmodule Crosswake.Proof.Phase168ReleaseVersionWeldTest do
  @moduledoc """
  Merge-blocking tripwire for TODO-009 / SEED-017.

  Phase 168 built a release graph that publishes exactly one transaction. Four
  jobs in `release-please.yml` gate on the literal `0.2.1`:

      if: ... needs.release-please.outputs.version == '0.2.1' ...

  For any other version every one of them skips, so the release tags and then
  publishes NOTHING. The linked rollup reports `PARTIAL` — correctly, but only
  because everything downstream was skipped. A silent no-op publish is a worse
  failure than a loud one.

  Generalizing the graph is real work with a real hazard (the version literal
  and the publication authority are currently the same string — see TODO-009).
  Until that work lands, this check makes the weld impossible to trip over
  accidentally: the moment `.release-please-manifest.json` declares a version
  the publish gates do not accept, CI fails and names the remediation.

  The tripwire is deliberately quiet today (manifest 0.2.1 == gates 0.2.1) and
  fires on the 0.2.2 release pull request, BEFORE it merges — which is exactly
  the moment a human can still act on it.
  """

  use ExUnit.Case, async: true

  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
  @manifest ".release-please-manifest.json"
  @check_id "release.version_weld.gates_match_declared_version"

  # Every job whose `if:` gates publication or post-publication proof on a bare
  # version literal. If a future edit adds a fifth, the coverage test below
  # fails rather than silently leaving it unguarded.
  @gated_jobs ~w(publish-hex publish-ios-core publish-android-core exact-public-proof)

  defp tmp_dir!(name) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "cw-p168-weld-#{name}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf(dir) end)
    dir
  end

  defp manifest_at!(dir, version) do
    path = Path.join(dir, "manifest.json")

    body =
      @manifest
      |> File.read!()
      |> JSON.decode!()
      |> Map.put(".", version)
      |> Map.put("packages/crosswake-shell-core-ios", version)
      |> Map.put("packages/crosswake-shell-core-android", version)
      |> JSON.encode!()

    File.write!(path, body)
    path
  end

  defp workflow_copy!(dir, contents) do
    path = Path.join(dir, "release-please.yml")
    File.write!(path, contents)
    path
  end

  defp run(workflow_path, manifest_path) do
    System.cmd("elixir", [@scanner, workflow_path],
      stderr_to_stdout: true,
      env: [{"RELEASE_PLEASE_MANIFEST_PATH", manifest_path}]
    )
  end

  # 169-01 added an additive `[crosswake] ROSTER: <count> <comma-joined ids>` line
  # that lists every declared check ID, including this test's @check_id — a bare
  # String.contains?/2 substring match now finds THAT line first (it prints
  # before any OK/FAIL line), not the actual result line for the check. Match the
  # real `[crosswake] (OK|FAIL): <id> - ` line shape instead, which is the same
  # consumer contract release_status.ex's parser depends on and 169-01/169-02
  # guarantee stays byte-identical.
  defp line_for(output, id) do
    output
    |> String.split("\n")
    |> Enum.find(&String.contains?(&1, "] OK: #{id} -"))
    |> case do
      nil -> output |> String.split("\n") |> Enum.find(&String.contains?(&1, "] FAIL: #{id} -"))
      line -> line
    end
  end

  describe "the tripwire is silent while the weld and the manifest agree" do
    test "the real repository passes: declared 0.2.1 matches the gates' 0.2.1" do
      {out, _code} = run(@workflow, @manifest)
      line = line_for(out, @check_id)

      assert line, "check #{@check_id} is not registered in the scanner\n#{out}"
      assert line =~ "OK:", "expected OK on the unmodified repository, got:\n#{line}"
    end
  end

  describe "the tripwire fires when a release moves past the welded version" do
    test "declaring 0.2.2 while the gates still say 0.2.1 FAILs" do
      dir = tmp_dir!("bumped")
      manifest = manifest_at!(dir, "0.2.2")

      {out, code} = run(@workflow, manifest)
      line = line_for(out, @check_id)

      assert code == 1, "expected scanner exit 1, got #{code}\n#{out}"
      assert line =~ "FAIL:", "expected FAIL for a bumped manifest, got:\n#{line}"
    end

    test "the failure names the declared version, the welded version, and the remediation" do
      dir = tmp_dir!("message")
      manifest = manifest_at!(dir, "0.2.2")

      {out, _code} = run(@workflow, manifest)
      line = line_for(out, @check_id)

      assert line =~ "0.2.2", "must name the version the repository now declares:\n#{line}"
      assert line =~ "0.2.1", "must name the version the gates accept:\n#{line}"

      assert line =~ "TODO-009" or line =~ "SEED-017",
             "a tripwire that does not say what to do next is a dead end:\n#{line}"
    end

    test "a major or minor bump fires too, not only the next patch" do
      for version <- ~w(0.3.0 1.0.0 0.2.10) do
        dir = tmp_dir!("bump-#{String.replace(version, ".", "-")}")
        manifest = manifest_at!(dir, version)

        {out, code} = run(@workflow, manifest)

        assert code == 1, "#{version} must fire the tripwire, got exit #{code}\n#{out}"
        assert line_for(out, @check_id) =~ "FAIL:"
      end
    end
  end

  describe "every publication gate is covered, not just the first one found" do
    test "mutating any single gated job's version literal FAILs the check" do
      original = File.read!(@workflow)

      for job <- @gated_jobs do
        dir = tmp_dir!("mutate-#{job}")

        mutated = mutate_job_version(original, job, "0.9.9")
        workflow = workflow_copy!(dir, mutated)

        {out, code} = run(workflow, @manifest)
        line = line_for(out, @check_id)

        assert code == 1,
               "job #{job} drifting to 0.9.9 must FAIL the check, got exit #{code}\n#{out}"

        assert line =~ "FAIL:", "job #{job} drift produced:\n#{line}"
        assert line =~ "0.9.9", "the failure must name the drifted literal:\n#{line}"
      end
    end

    test "the guarded job list matches what the workflow actually gates on" do
      found =
        ~r/^  ([a-z0-9-]+):$/m
        |> Regex.scan(File.read!(@workflow), capture: :all_but_first)
        |> List.flatten()
        |> Enum.filter(fn job ->
          block = job_block(File.read!(@workflow), job)
          Regex.match?(~r/outputs\.version\s*==\s*'\d+\.\d+\.\d+'/, block)
        end)
        |> Enum.sort()

      assert found == Enum.sort(@gated_jobs), """
      The set of jobs gated on a bare version literal changed.

      expected: #{inspect(Enum.sort(@gated_jobs))}
      found:    #{inspect(found)}

      If a job was ADDED, add it to @gated_jobs so the mutation control covers it.
      If a job was REMOVED because the graph was generalized, that is TODO-009 /
      SEED-017 landing — retire this tripwire deliberately, do not loosen it.
      """
    end
  end

  defp job_block(workflow, job) do
    case Regex.run(
           ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
           workflow
         ) do
      [block] -> block
      _ -> ""
    end
  end

  defp mutate_job_version(workflow, job, version) do
    block = job_block(workflow, job)

    unless Regex.match?(~r/outputs\.version\s*==\s*'\d+\.\d+\.\d+'/, block) do
      raise """
      mutate_job_version/3 found no version gate in job #{inspect(job)}.

      The mutation would be a no-op and the control would assert nothing.
      """
    end

    mutated =
      Regex.replace(
        ~r/(outputs\.version\s*==\s*')\d+\.\d+\.\d+(')/,
        block,
        # \g{1} not \1 — "\\1" <> "0.9.9" reads as capture group 10, not group 1.
        "\\g{1}#{version}\\g{2}"
      )

    if mutated == block do
      raise """
      mutate_job_version/3 produced an IDENTICAL block for job #{inspect(job)}.

      The replacement matched but changed nothing, so the control below would
      assert against an UNMUTATED workflow and pass while proving the opposite of
      what it claims. This is exactly how "\\1" <> a version was once read as
      capture group 10 rather than group 1.
      """
    end

    String.replace(workflow, block, mutated, global: false)
  end
end
