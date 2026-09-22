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

  defp assert_failure!(check_id, fixtures) do
    {output, status} = Fixtures.run_fixture_set(fixtures)
    assert status != 0, output
    assert output =~ "[crosswake] FAIL: #{check_id}", output
  end
end
