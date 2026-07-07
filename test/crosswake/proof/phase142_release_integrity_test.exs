defmodule Crosswake.Proof.Phase142ReleaseIntegrityTest do
  @moduledoc """
  Merge-blocking proof for v18 release-integrity guardrails.

  The release workflow is product surface for Crosswake's package family. These
  tests keep the v17 footguns from returning: aggregate release gates, cancelable
  publish runs, cross-platform proof cascades, and stale clean-room dependency
  floors.
  """

  use ExUnit.Case, async: true

  @workflow ".github/workflows/release-please.yml"
  @scanner "script/check_release_workflow_integrity.exs"
  @cleanroom_script "script/verify_companion_cleanroom.sh"

  test "release workflow integrity script passes" do
    {output, exit_code} = run_scanner(@workflow)

    assert exit_code == 0, output
    assert output =~ "release.root_hex.path_gate"
    assert output =~ "release.concurrency.queue_max"
    assert output =~ "release.aggregate_gate.behavioral_jobs_absent"
    assert output =~ "release.cleanup.after_publish_and_proof"
  end

  test "root and native publish jobs do not gate on aggregate releases_created" do
    workflow = File.read!(@workflow)

    assert workflow =~ "paths_released:"
    assert workflow =~ "publish-hex:"
    assert workflow =~ "contains(fromJSON(needs.release-please.outputs.paths_released), '.')"

    assert workflow =~
             "contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios')"

    assert workflow =~
             "contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android')"

    refute workflow =~
             ~r/publish-hex:[\s\S]*?if: \$\{\{ needs\.release-please\.outputs\.releases_created == 'true' \}\}/

    refute workflow =~
             ~r/publish-ios-core:[\s\S]*?if: \$\{\{ needs\.release-please\.outputs\.releases_created == 'true' \}\}/

    refute workflow =~
             ~r/publish-android-core:[\s\S]*?if: \$\{\{ needs\.release-please\.outputs\.releases_created == 'true' \}\}/
  end

  test "clean-room script derives core floor and exact companion version" do
    script = File.read!(@cleanroom_script)

    assert script =~ "CORE_REQUIREMENT="
    assert script =~ "PACKAGE_REQUIREMENT=\"${PACKAGE_REQUIREMENT:-== ${VERSION}}\""
    assert script =~ "{:crosswake, \"${CORE_REQUIREMENT}\"}"
    assert script =~ "{:${PACKAGE}, \"${PACKAGE_REQUIREMENT}\"}"

    refute script =~ "{:crosswake, \"~> 0.1\"}"
    refute script =~ "{:\"${PACKAGE}\", \"~> 0.1\"}"
  end

  test "missing queue max fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace(~r/^\s+queue:\s*max\n/m, "")

    assert_failure!("release.concurrency.queue_max", workflow)
  end

  test "conflicting true cancellation fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace("cancel-in-progress: false", "cancel-in-progress: true")

    assert_failure!("release.concurrency.not_cancelled", workflow)
    assert_failure!("release.concurrency.no_true_cancellation", workflow)
  end

  test "aggregate identity in a behavioral job fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace(
        "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
        "if: ${{ needs.release-please.outputs.releases_created == 'true' }}",
        global: false
      )

    assert_failure!("release.aggregate_gate.behavioral_jobs_absent", workflow)
  end

  test "full-line comments cannot satisfy or violate semantic checks" do
    commented_queue =
      real_workflow()
      |> String.replace("  queue: max", "  # queue: max", global: false)

    assert_failure!("release.concurrency.queue_max", commented_queue)

    aggregate_comment =
      real_workflow()
      |> String.replace(
        "  publish-hex:\n    name:",
        "  publish-hex:\n    # if: ${{ needs.release-please.outputs.releases_created == 'true' }}\n    name:",
        global: false
      )

    {output, exit_code} = run_fixture(aggregate_comment)
    assert exit_code == 0, output
  end

  test "cleanup ignoring clean-room proof fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace("      - clean-room-proof-rulestead\n", "", global: false)
      |> String.replace(
        "            needs.clean-room-proof-rulestead.result == 'success'",
        "            true",
        global: false
      )

    assert_failure!("release.cleanup.after_publish_and_proof", workflow)
  end

  test "cleanup direct main mutation fails with stable check id" do
    workflow =
      real_workflow()
      |> String.replace("git push origin \"$branch\"", "git push origin main", global: false)

    assert_failure!("release.cleanup.pr_only", workflow)
  end

  defp assert_failure!(check_id, workflow) do
    {output, exit_code} = run_fixture(workflow)

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: #{check_id}"
  end

  defp run_fixture(workflow) do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase142-#{System.unique_integer([:positive])}.yml"
      )

    File.write!(path, workflow)
    on_exit(fn -> File.rm(path) end)

    run_scanner(path)
  end

  defp run_scanner(path) do
    System.cmd("elixir", [@scanner, path], stderr_to_stdout: true)
  end

  defp real_workflow, do: File.read!(@workflow)
end
