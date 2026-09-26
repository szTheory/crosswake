defmodule Crosswake.Proof.Phase175Rel17WiringTest do
  use ExUnit.Case, async: false

  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner
  alias Crosswake.Phase175Rel17Fixtures, as: Rel17

  @release_workflow ".github/workflows/release-please.yml"
  @ios_script "script/release_candidate/ios_mirror.sh"
  @android_script "script/release_candidate/android_publication.sh"

  @rel17_ids ~w(
    release.rel17.approved_guard
    release.rel17.roster_exact
    release.rel17.release_creation_guard
    release.rel17.core_hex_job_guard
    release.rel17.core_ios_job_guard
    release.rel17.core_maven_job_guard
    release.rel17.recovery_hex_job_guard
    release.rel17.recovery_ios_job_guard
    release.rel17.recovery_maven_job_guard
    release.rel17.legacy_ios_job_guard
    release.rel17.companion_rulestead_job_guard
    release.rel17.companion_rindle_job_guard
    release.rel17.companion_sigra_job_guard
    release.rel17.companion_chimeway_job_guard
    release.rel17.companion_threadline_job_guard
    release.rel17.hex_final_boundary
    release.rel17.ios_final_boundary
    release.rel17.maven_final_boundary
  )

  test "the full scanner declares and passes every REL-17 guard check" do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: File.read!(@release_workflow)})

    assert status == 0, output
    for id <- @rel17_ids, do: assert(output =~ "OK: #{id}")
    refute output =~ "FAIL: release.rel17."
  end

  test "all five companion packages accept only their package-scoped operation context" do
    for package <- [
          "crosswake_rulestead",
          "crosswake_rindle",
          "crosswake_sigra",
          "crosswake_chimeway",
          "crosswake_threadline"
        ] do
      context = Rel17.context(operation: "companion_publish", package: package)
      result = Rel17.run_loader(context, operation: "companion_publish", package: package)
      on_exit(fn -> Rel17.clean_loader_result(result) end)

      assert result.status == 0, "#{package}: #{result.output}"
      assert result.env =~ "REL17_PACKAGE=#{package}\n"
    end
  end

  test "Chimeway's migrated authorization retains the exact third-leg run selector" do
    context =
      Rel17.context(
        operation: "companion_publish",
        package: "crosswake_chimeway",
        pr: 115,
        authorization_run_id: 909
      )

    result =
      Rel17.run_loader(context,
        operation: "companion_publish",
        package: "crosswake_chimeway"
      )

    on_exit(fn -> Rel17.clean_loader_result(result) end)
    assert result.status == 0, result.output
    assert result.env =~ "REL17_PACKAGE=crosswake_chimeway\n"
  end

  test "removing any companion entry gate fails that package's named check" do
    workflow = File.read!(@release_workflow)

    for {component, id} <- [
          {"rulestead", "release.rel17.companion_rulestead_job_guard"},
          {"rindle", "release.rel17.companion_rindle_job_guard"},
          {"sigra", "release.rel17.companion_sigra_job_guard"},
          {"chimeway", "release.rel17.companion_chimeway_job_guard"},
          {"threadline", "release.rel17.companion_threadline_job_guard"}
        ] do
      mutated =
        Scanner.remove_step!(
          workflow,
          "publish-hex-#{component}",
          "Re-fetch REL-17 evidence before companion credentials"
        )

      assert_scanner_failure(%{release_workflow: mutated}, id)
    end
  end

  test "a missing companion job fails the named job guard and rostered component gate" do
    workflow = File.read!(@release_workflow)
    mutated = remove_job!(workflow, "publish-hex-threadline")
    {output, status} = Scanner.run_fixture_set(%{release_workflow: mutated})

    assert status != 0
    assert output =~ "FAIL: release.rel17.companion_threadline_job_guard"
    assert output =~ "FAIL: release.threadline.component_gate"
  end

  test "independent iOS push mutations each fail the shared final-boundary check" do
    script = File.read!(@ios_script)

    ordinary =
      Scanner.replace_once!(
        script,
        "require_rel17_publish_evidence\n    git -C \"$RELEASE_REPO\" push --porcelain --atomic",
        "true\n    git -C \"$RELEASE_REPO\" push --porcelain --atomic"
      )

    assert_scanner_failure(%{ios_backfill_script: ordinary}, "release.rel17.ios_final_boundary")

    recovery =
      Scanner.replace_once!(
        script,
        "require_rel17_publish_evidence\n    git -C \"$RELEASE_REPO\" push --porcelain \\\n      \"--force-with-lease=refs/heads/main:${EXPECTED_OLD_REF}\"",
        "true\n    git -C \"$RELEASE_REPO\" push --porcelain \\\n      \"--force-with-lease=refs/heads/main:${EXPECTED_OLD_REF}\""
      )

    assert_scanner_failure(%{ios_backfill_script: recovery}, "release.rel17.ios_final_boundary")
  end

  test "removing the Maven final gate fails its dedicated boundary check" do
    script = File.read!(@android_script)

    mutated =
      Scanner.replace_once!(
        script,
        "(cd \"$REPO_ROOT\" && REL17_STAGE=post_merge bash script/release_candidate/require_release_evidence.sh)\n./gradlew publishToMavenCentral",
        "(cd \"$REPO_ROOT\" && true)\n./gradlew publishToMavenCentral"
      )

    assert_scanner_failure(%{android_publication: mutated}, "release.rel17.maven_final_boundary")
  end

  test "removing a declared REL-17 site makes the roster check red" do
    source = File.read!(Scanner.scanner())

    roster_prefix = "@rel17_guard_roster ~w(\n"
    [before_roster, roster_body] = String.split(source, roster_prefix, parts: 2)

    mutated_roster =
      Scanner.replace_once!(
        roster_body,
        "    release.rel17.companion_threadline_job_guard\n",
        ""
      )

    mutated = before_roster <> roster_prefix <> mutated_roster

    path =
      Path.join(
        System.tmp_dir!(),
        "phase175-rel17-roster-#{System.unique_integer([:positive])}.exs"
      )

    File.write!(path, mutated)
    on_exit(fn -> File.rm(path) end)

    {output, status} = System.cmd("elixir", [path], stderr_to_stdout: true)
    assert status != 0, output
    assert output =~ "FAIL: release.rel17.roster_exact"
  end

  defp assert_scanner_failure(fixtures, id) do
    {output, status} = Scanner.run_fixture_set(fixtures)
    assert status != 0, output
    assert output =~ "FAIL: #{id}", output
  end

  defp remove_job!(workflow, job) do
    pattern = ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/
    mutated = Regex.replace(pattern, workflow, "", global: false)
    if mutated == workflow, do: flunk("job #{job} was not present")
    mutated
  end
end
