defmodule Crosswake.Proof.Phase165CiIntegrityTest do
  @moduledoc """
  Structural CI trust-boundary proof for Phase 165.
  """
  use ExUnit.Case, async: true

  @controller ".github/workflows/cancel-obsolete-crosswake-ci.yml"
  @crosswake_ci ".github/workflows/crosswake-ci.yml"

  @tag :cancellation_controller
  test "controller is requested-run-only and grants no permission beyond Actions mutation" do
    workflow = File.read!(@controller)

    assert workflow =~
             ~r/^on:\n  workflow_run:\n    workflows: \[Crosswake CI\]\n    types: \[requested\]$/m

    assert workflow =~ ~r/^permissions:\n  actions: write$/m
    refute workflow =~ "pull_request_target"
    refute workflow =~ ~r/^\s+(contents|issues|pull-requests|checks|packages): write$/m
    refute workflow =~ "write-all"
    refute workflow =~ "secrets."
  end

  @tag :cancellation_controller
  test "controller consumes immutable default-branch policy and never checks out PR code" do
    workflow = File.read!(@controller)

    refute workflow =~ "actions/checkout"
    refute workflow =~ "github.event.workflow_run.head_sha"
    refute workflow =~ "github.event.workflow_run.head_repository"
    assert workflow =~ "${GITHUB_REPOSITORY}/${GITHUB_SHA}/script/select_obsolete_ci_runs.py"
    assert workflow =~ "--repository \"$GITHUB_REPOSITORY\""
    assert workflow =~ "--workflow-name 'Crosswake CI'"
    assert workflow =~ "pagination_complete"
  end

  @tag :cancellation_controller
  test "strict-lower selection is a hard gate before bounded cancel and force-cancel" do
    workflow = File.read!(@controller)

    select_at = byte_offset(workflow, "id: select")
    gate_at = byte_offset(workflow, "steps.select.outputs.disposition == 'cancel_lower'")
    cancel_at = byte_offset(workflow, ~s(actions/runs/$run_id/cancel"))
    poll_at = byte_offset(workflow, "poll_attempt")
    force_at = byte_offset(workflow, ~s(actions/runs/$run_id/force-cancel"))

    assert select_at < gate_at
    assert gate_at < cancel_at
    assert cancel_at < poll_at
    assert poll_at < force_at
    assert workflow =~ "timeout-minutes: 10"
    assert workflow =~ "steps.select.outputs.run_ids != '[]'"
    assert workflow =~ "closed disposition"
    refute workflow =~ ~r/\b(retry|rerun|re-run)\b.*\b(test|proof|assert)/i
  end

  @tag :cancellation_controller
  test "ordinary PR concurrency remains repository-and-PR scoped and non-cancelling" do
    workflow = File.read!(@crosswake_ci)

    assert workflow =~
             "group: crosswake-ci-${{ github.repository }}-pr-${{ github.event.pull_request.number }}"

    assert workflow =~ "cancel-in-progress: false"
    refute workflow =~ "cancel-in-progress: true"
  end

  defp byte_offset(value, needle) do
    case :binary.match(value, needle) do
      {offset, _length} -> offset
      :nomatch -> flunk("expected workflow marker #{inspect(needle)}")
    end
  end
end
