defmodule Crosswake.Proof.Phase199ReleaseGatesTest do
  # Scanner mutation tests for the Phase 199 release gate checks. Plan 199-03 adds the
  # approval-environment preflight check; plans 199-04 and 199-05 extend this module.
  # Every fixture mutates the REAL workflow text through the shared raise-on-no-op helpers,
  # so a mutation that stops matching breaks here rather than yielding an unmutated pass.
  use ExUnit.Case, async: false

  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner

  @release_workflow ".github/workflows/release-please.yml"
  @guard_job "approved-release-guard"
  @preflight_id "release.gate.environments_preflight"
  @call "bash script/release_candidate/check_release_environments.sh || env_preflight_rc=$?"
  @blocked "REL-17 BLOCKED reason=release_environment_unprotected"

  test "the real workflow passes the environment preflight check" do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: File.read!(@release_workflow)})

    assert status == 0, output
    assert output =~ "OK: #{@preflight_id}"
    refute output =~ "FAIL: #{@preflight_id}"
    assert output =~ "DONE: 99 of 99 roster checks emitted; 0 failed."
  end

  test "deleting the preflight call turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)
    mutated = Scanner.replace_in_job(workflow, @guard_job, @call, "env_preflight_rc=0")

    assert_scanner_failure(mutated)
  end

  test "moving the preflight call after the outputs turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)
    without_call = Scanner.replace_in_job(workflow, @guard_job, @call, "env_preflight_rc=0")

    moved =
      Scanner.replace_in_job(
        without_call,
        @guard_job,
        ~s(          emit_output "approved_head=$approved_head"\n),
        ~s(          emit_output "approved_head=$approved_head"\n) <>
          "          #{@call}\n"
      )

    assert_scanner_failure(moved)
  end

  test "removing the release-branch BLOCKED reason turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        @guard_job,
        ~s(echo "#{@blocked}" >&2),
        ~s(echo "REL-17 note" >&2)
      )

    assert_scanner_failure(mutated)
  end

  defp assert_scanner_failure(mutated) do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: mutated})

    assert status != 0, output
    assert output =~ "FAIL: #{@preflight_id}"
  end
end
