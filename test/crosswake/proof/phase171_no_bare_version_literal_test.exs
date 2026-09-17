defmodule Crosswake.Proof.Phase171NoBareVersionLiteralTest do
  @moduledoc """
  Non-vacuity proof for `release.publish_gate.no_bare_version_literal`
  (MSG-04 / MSG-05).

  Phase 171 replaces the interim TODO-009 / SEED-017 tripwire (retired in
  this same phase, WELD-07) with a permanent structural check: no
  publish-gating `if:` clause in `.github/workflows/release-please.yml`
  may compare `needs.release-please.outputs.version` against a bare
  semver literal. Every gated job must instead compare against
  `needs.approved-release-guard.outputs.approved_version` (WELD-03).

  This proves the check is non-vacuous: it must FAIL against a pre-repair
  fixture -- a copy of the (already-fixed) workflow with one job's
  comparison rewritten back into the pre-171 bare-literal shape -- and it
  must do so independently for each of the four gated jobs, not only the
  first one found.
  """

  use ExUnit.Case, async: true

  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
  @manifest ".release-please-manifest.json"
  @check_id "release.publish_gate.no_bare_version_literal"

  # Every job whose `if:` gates publication or post-publication proof on the
  # approved_version comparison. If a future edit adds a fifth, the coverage
  # test below fails rather than silently leaving it unguarded.
  @version_gated_jobs ~w(publish-hex publish-ios-core publish-android-core exact-public-proof)

  defp tmp_dir!(name) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "cw-p171-bare-#{name}-#{System.unique_integer([:positive])}"
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
  # that lists every declared check ID, including this test's @check_id -- a bare
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

  defp job_block(workflow, job) do
    case Regex.run(
           ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
           workflow
         ) do
      [block] -> block
      _ -> ""
    end
  end

  # Pre-repair fixture builder -- the INVERSE of the phase-168 mutation. Takes the
  # real (already-fixed) workflow text and rewrites one named job's
  # approved_version comparison back into a bare semver-literal comparison,
  # reconstructing the pre-171 shape "this phase's own fix was never applied."
  defp mutate_job_to_bare_literal(workflow, job, version) do
    block = job_block(workflow, job)

    expected =
      "needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version"

    unless String.contains?(block, expected) do
      raise """
      mutate_job_to_bare_literal/3 found no approved_version comparison in job #{inspect(job)}.

      The mutation would be a no-op and the control would assert nothing.
      """
    end

    mutated =
      String.replace(
        block,
        "needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version",
        "needs.release-please.outputs.version == '#{version}'"
      )

    if mutated == block do
      raise """
      mutate_job_to_bare_literal/3 produced an IDENTICAL block for job #{inspect(job)}.

      The replacement matched but changed nothing, so the control below would
      assert against an unmutated workflow and pass while proving the opposite
      of what it claims.
      """
    end

    String.replace(workflow, block, mutated, global: false)
  end

  describe "the check is silent against the real, fixed repository" do
    test "the real repository passes: no publish-gating if: compares against a bare version literal" do
      {out, _code} = run(@workflow, @manifest)
      line = line_for(out, @check_id)

      assert line, "check #{@check_id} is not registered in the scanner\n#{out}"
      assert line =~ "OK:", "expected OK on the unmodified repository, got:\n#{line}"
    end

    test "the check inspects the workflow text, not the declared release-manifest version" do
      dir = tmp_dir!("bumped-manifest")
      manifest = manifest_at!(dir, "9.9.9")

      {out, _code} = run(@workflow, manifest)
      line = line_for(out, @check_id)

      assert line =~ "OK:",
             "the check must stay OK against a bumped release manifest -- it asserts the workflow if: shape, not the release-manifest content:\n#{line}"
    end
  end

  describe "the check fires when a pre-repair fixture reintroduces the literal" do
    for job <- @version_gated_jobs do
      test "reintroducing a bare literal in #{job} alone FAILs the check" do
        job = unquote(job)
        dir = tmp_dir!("mutate-#{job}")

        original = File.read!(@workflow)
        mutated = mutate_job_to_bare_literal(original, job, "0.2.1")
        workflow = workflow_copy!(dir, mutated)

        {out, code} = run(workflow, @manifest)
        line = line_for(out, @check_id)

        assert code == 1,
               "job #{job} reintroducing a bare literal must FAIL the scanner, got exit #{code}\n#{out}"

        assert line =~ "FAIL:", "job #{job} pre-repair fixture produced:\n#{line}"
        assert line =~ job, "the failure must name the offending job (#{job}):\n#{line}"
      end
    end
  end

  describe "the roster job list matches what the workflow actually gates on" do
    test "the guarded job list matches the four version-gated jobs" do
      found =
        ~r/^  ([a-z0-9-]+):$/m
        |> Regex.scan(File.read!(@workflow), capture: :all_but_first)
        |> List.flatten()
        |> Enum.filter(fn job ->
          block = job_block(File.read!(@workflow), job)

          String.contains?(
            block,
            "needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version"
          )
        end)
        |> Enum.sort()

      assert found == Enum.sort(@version_gated_jobs), """
      The set of jobs gated on approved_version changed.

      expected: #{inspect(Enum.sort(@version_gated_jobs))}
      found:    #{inspect(found)}

      If a job was ADDED, add it to @version_gated_jobs so the mutation control
      covers it (and to the scanner's own @version_gated_jobs attribute).
      """
    end
  end

  describe "the check is registered as merge-blocking" do
    test "release.publish_gate.no_bare_version_literal is in the scanner's roster" do
      source = File.read!("script/check_release_workflow_integrity.exs")
      assert source =~ @check_id
    end
  end
end
