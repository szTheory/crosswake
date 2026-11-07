defmodule Crosswake.Proof.Phase199ReleaseGatesTest do
  # Scanner mutation tests for the Phase 199 release gate checks. Plan 199-03 adds the
  # approval-environment preflight check, plan 199-04 the publisher environment checks;
  # plan 199-05 extends this module with the tag gate.
  # Every fixture mutates the REAL workflow text through the shared raise-on-no-op helpers,
  # so a mutation that stops matching breaks here rather than yielding an unmutated pass.
  use ExUnit.Case, async: false

  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner

  @release_workflow ".github/workflows/release-please.yml"
  @guard_job "approved-release-guard"
  @preflight_id "release.gate.environments_preflight"
  @call "bash script/release_candidate/check_release_environments.sh || env_preflight_rc=$?"
  @blocked "REL-17 BLOCKED reason=release_environment_unprotected"
  @hex_id "release.gate.publish_hex_environment"
  @maven_id "release.gate.publish_maven_environment"
  @ios_id "release.gate.publish_ios_mirror_environment"
  @companion_id "release.gate.companion_environments"
  @order_id "release.gate.core_order"
  @publisher_ids [@hex_id, @maven_id, @ios_id, @companion_id, @order_id]

  test "the real workflow passes the environment preflight check" do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: File.read!(@release_workflow)})

    assert status == 0, output
    assert output =~ "OK: #{@preflight_id}"
    refute output =~ "FAIL: #{@preflight_id}"
    assert output =~ "DONE: 104 of 104 roster checks emitted; 0 failed."
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

  test "the real workflow passes the core Hex environment check" do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: File.read!(@release_workflow)})

    assert status == 0, output
    assert output =~ "OK: #{@hex_id}"
    refute output =~ "FAIL: #{@hex_id}"
  end

  test "deleting the publish-hex environment key turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(workflow, "publish-hex", "    environment: publish-hex\n", "")

    assert_scanner_failure(mutated, @hex_id)
  end

  test "renaming the publish-hex environment turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-hex",
        "    environment: publish-hex\n",
        "    environment: publish-hex-unprotected\n"
      )

    assert_scanner_failure(mutated, @hex_id)
  end

  test "the real workflow passes every publisher gate check" do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: File.read!(@release_workflow)})

    assert status == 0, output

    for id <- @publisher_ids do
      assert output =~ "OK: #{id}"
      refute output =~ "FAIL: #{id}"
    end
  end

  test "deleting the publish-android-core environment turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-android-core",
        "    environment: publish-maven\n",
        ""
      )

    assert_scanner_failure(mutated, @maven_id)
  end

  test "deleting the publish-ios-core environment turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-ios-core",
        "    environment: publish-ios-mirror\n",
        ""
      )

    assert_scanner_failure(mutated, @ios_id)
  end

  test "dropping the environment from one companion publisher turns the scanner red" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-hex-threadline",
        "    environment: publish-hex\n",
        ""
      )

    assert_scanner_failure(mutated, @companion_id)
  end

  test "dropping the Maven need on Hex turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-android-core",
        "needs: [approved-release-guard, release-please, publish-hex]",
        "needs: [approved-release-guard, release-please]"
      )

    assert_scanner_failure(mutated, @order_id)
  end

  test "dropping the iOS success condition on Maven turns the scanner red with the check id" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-ios-core",
        " && needs.publish-android-core.result == 'success'",
        ""
      )

    assert_scanner_failure(mutated, @order_id)
  end

  defp assert_scanner_failure(mutated, id \\ @preflight_id) do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: mutated})

    assert status != 0, output
    assert output =~ "FAIL: #{id}"
  end
end
