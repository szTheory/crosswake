defmodule Crosswake.Proof.Phase175ReleaseRecoveryTest do
  @moduledoc """
  Non-vacuous structural proof for the Phase 175 recovery boundaries.

  The tests mutate real workflow text through the shared fixture harness.  A
  fixture mutation that cannot find its target raises before the scanner runs,
  so a changed workflow cannot turn a negative control into an empty success.
  """

  use ExUnit.Case, async: true

  alias Crosswake.ReleaseWorkflowFixtures, as: Fixtures

  @release_workflow ".github/workflows/release-please.yml"
  @maven_fire_drill_workflow ".github/workflows/maven-publish-fire-drill.yml"
  @isolation "release.rehearsal.maven_isolated"
  @receipt_authority "release.recovery.receipt_exact_authority"
  @no_bypass "release.recovery.no_retry_or_bypass"

  test "the ordinary release workflow cannot retain the Maven drill" do
    workflow = File.read!(@release_workflow)
    {output, status} = Fixtures.run_scanner(@release_workflow)

    refute workflow =~ "android-publish-fire-drill:"
    assert status == 0, output
    assert output =~ "[crosswake] OK: #{@isolation}"
  end

  test "embedding the Maven drill in Release Please is a seed-red isolation failure" do
    release = File.read!(@release_workflow)
    embedded = release <> "\n  maven-publish-fire-drill:\n    name: embedded\n"
    assert_failure!(@isolation, release_workflow: embedded)
  end

  test "Maven drill rejects Release Please and PR-mutating machinery" do
    maven = File.read!(@maven_fire_drill_workflow)

    assert_failure!(
      @isolation,
      maven_fire_drill_workflow:
        Fixtures.replace_once!(maven, "maven-publish-fire-drill:", "maven-publish-fire-drill:\n    uses: googleapis/release-please-action@deadbeef")
    )

    assert_failure!(
      @isolation,
      maven_fire_drill_workflow:
        Fixtures.replace_once!(maven, "contents: read", "contents: read\n      - run: gh pr create")
    )
  end

  test "exact canonical receipt and every identity comparison are seed-red" do
    release = File.read!(@release_workflow)

    assert_failure!(
      @receipt_authority,
      release_workflow:
        Fixtures.replace_in_job(
          release,
          "approved-release-guard",
          "select(.expired == false)] | length')\" -eq 1 ]",
          "select(.expired == false)] | length')\" -ge 1 ]"
        )
    )

    for {needle, replacement} <- [
          {".identity.bound.head == $head", ".identity.bound.head == $stale_head"},
          {".identity.bound.tree == $tree", ".identity.bound.tree == $stale_tree"},
          {".identity.bound.base == $base", ".identity.bound.base == $stale_base"}
        ] do
      assert_failure!(
        @receipt_authority,
        release_workflow: Fixtures.replace_in_job(release, "approved-release-guard", needle, replacement)
      )
    end
  end

  test "dispatch, rerun, and individual-registry bypass seeds fail closed" do
    release = File.read!(@release_workflow)

    for seed <- ["gh run rerun 123", "gh workflow run release-please.yml", "retry_failed", "individual-registry"] do
      assert_failure!(
        @no_bypass,
        release_workflow:
          Fixtures.replace_in_job(
            release,
            "approved-release-guard",
            "emit_output \"linked_release=false\"",
            "emit_output \"linked_release=false\"\n          #{seed}"
          )
      )
    end
  end

  defp assert_failure!(check_id, fixtures) do
    {output, status} = Fixtures.run_fixture_set(fixtures)
    assert status != 0, output
    assert output =~ "[crosswake] FAIL: #{check_id}", output
  end
end
