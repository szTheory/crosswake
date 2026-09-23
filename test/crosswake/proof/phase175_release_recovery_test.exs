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
  @ios_recovery_workflow ".github/workflows/ios-tag-recovery.yml"
  @ci_workflow ".github/workflows/crosswake-ci.yml"
  @ios_recovery_script "script/release_candidate/ios_tag_recovery.sh"
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
        Fixtures.replace_once!(
          maven,
          "maven-publish-fire-drill:",
          "maven-publish-fire-drill:\n    uses: googleapis/release-please-action@deadbeef"
        )
    )

    assert_failure!(
      @isolation,
      maven_fire_drill_workflow:
        Fixtures.replace_once!(
          maven,
          "contents: read",
          "contents: read\n      - run: gh pr create"
        )
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
        release_workflow:
          Fixtures.replace_in_job(release, "approved-release-guard", needle, replacement)
      )
    end
  end

  test "dispatch, rerun, and individual-registry bypass seeds fail closed" do
    release = File.read!(@release_workflow)

    for seed <- [
          "gh run rerun 123",
          "gh workflow run release-please.yml",
          "retry_failed",
          "individual-registry"
        ] do
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

  test "0.2.3 parity exception is limited to PR 200 and the exact recovery validator" do
    workflow = File.read!(@ci_workflow)
    parity_job = job_section!(workflow, "ios-mirror-parity-proof")

    assert parity_job =~
             "if: ${{ github.event_name == 'pull_request' && github.event.pull_request.number == 200 }}"

    assert parity_job =~ "bash script/release_candidate/ios_tag_recovery.sh validate"
    assert parity_job =~ "CROSSWAKE_IOS_PARITY_ALLOW_MISSING_VERSION"

    assert parity_job =~
             "CROSSWAKE_IOS_PARITY_ALLOW_MISSING_VERSION: ${{ github.event_name == 'pull_request' && github.event.pull_request.number == 200 && '0.2.3' || '' }}"

    assert parity_job =~ "./script/check_ios_mirror_parity.sh"
  end

  test "post-merge recovery validates before loading credentials and writes only the exact tag" do
    workflow = File.read!(@ios_recovery_workflow)
    script = File.read!(@ios_recovery_script)

    assert workflow =~ "branches: [main]"
    assert workflow =~ "script/release_candidate/ios_tag_recovery.sh"
    assert workflow =~ "Validate exact approved transaction without credentials"
    assert workflow =~ "Create only the immutable v0.2.3 tag"

    {validate_at, _} =
      :binary.match(workflow, "Validate exact approved transaction without credentials")

    {credential_at, _} =
      :binary.match(workflow, "ssh-private-key: ${{ secrets.MIRROR_DEPLOY_KEY }}")

    assert validate_at < credential_at
    assert script =~ "0.2.3"
    assert script =~ "refs/tags/ios-core-v${VERSION}"
    assert script =~ "https://github.com/szTheory/crosswake-shell-core-ios.git"
    assert script =~ "git@github.com:szTheory/crosswake-shell-core-ios.git"
    assert script =~ "4df029d3799d2db18003471019c42126878572f8"
    assert script =~ "424ab96ede1b92f2b751b54bce04c6e607f0f3c8"
    assert script =~ "f5e91a9a10ead43306c5a55580bb07e54db199d12c6e0d629d6eb56f2766ca92"
    assert script =~ "git push --porcelain \"$REMOTE\" \"${SPLIT}:${TAG}\""
    assert script =~ "[ \"$after_main\" = \"$SPLIT\" ] && [ \"$after_tag\" = \"$SPLIT\" ]"
    refute script =~ "refs/heads/main\" \"${SPLIT}:refs/heads/main"
  end

  defp assert_failure!(check_id, fixtures) do
    {output, status} = Fixtures.run_fixture_set(fixtures)
    assert status != 0, output
    assert output =~ "[crosswake] FAIL: #{check_id}", output
  end

  defp job_section!(workflow, job_name) do
    pattern = ~r/^  #{Regex.escape(job_name)}:\r?\n(.*?)(?=^  [a-zA-Z0-9_-]+:\r?\n|\z)/ms
    [section] = Regex.run(pattern, workflow, capture: :all_but_first)
    section
  end
end
