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
  @isolation "release.rehearsal.maven_isolated"

  test "the ordinary release workflow cannot retain the Maven drill" do
    workflow = File.read!(@release_workflow)
    {output, status} = Fixtures.run_scanner(@release_workflow)

    refute workflow =~ "android-publish-fire-drill:"
    assert status == 0, output
    assert output =~ "[crosswake] OK: #{@isolation}"
  end
end
