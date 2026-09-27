defmodule Crosswake.Proof.Phase175Rel17RecoveryPathsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Phase175Rel17Fixtures, as: Rel17
  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner

  @recovery_workflow ".github/workflows/hex-publish.yml"
  @ios_workflow ".github/workflows/ios-mirror-backfill.yml"

  test "a new recovery authorization is loaded with the distinct recovery operation" do
    context = Rel17.context(operation: "recovery")
    result = Rel17.run_loader(context, operation: "recovery")
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status == 0, result.output
    assert result.env =~ "REL17_OPERATION=recovery\n"
    assert result.env =~ "REL17_PACKAGE=crosswake\n"
    assert result.env =~ "REL17_MERGE_OID="
  end

  test "Hex recovery accepts all six package identities under recovery authority" do
    for package <- [
          "crosswake",
          "crosswake_rulestead",
          "crosswake_rindle",
          "crosswake_sigra",
          "crosswake_chimeway",
          "crosswake_threadline"
        ] do
      context = Rel17.context(operation: "recovery", package: package)
      result = Rel17.run_loader(context, operation: "recovery", package: package)
      on_exit(fn -> Rel17.clean_loader_result(result) end)

      assert result.status == 0, "#{package}: #{result.output}"
      assert result.env =~ "REL17_OPERATION=recovery\n"
      assert result.env =~ "REL17_PACKAGE=#{package}\n"
    end
  end

  test "a consumed old authorization is rejected for recovery" do
    context =
      Rel17.context(operation: "recovery")
      |> Jason.decode!()
      |> Map.put("consumed", true)
      |> Jason.encode!()

    result = Rel17.run_loader(context, operation: "recovery")
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status != 0
    assert result.output =~ "REL-17 BLOCKED"
    assert result.env == ""
  end

  test "linked-release authority cannot enter a recovery job" do
    result = Rel17.run_loader(Rel17.context(), operation: "recovery")
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status != 0
    assert result.env == ""
  end

  test "a stale policy or changed merge blocks recovery before runner outputs are written" do
    for overrides <- [
          [policy_sha256: String.duplicate("9", 64)],
          [merge_oid: String.duplicate("9", 40)]
        ] do
      context = Rel17.context(Keyword.merge([operation: "recovery"], overrides))
      result = Rel17.run_loader(context, operation: "recovery")
      on_exit(fn -> Rel17.clean_loader_result(result) end)

      assert result.status != 0
      assert result.output =~ "REL-17 BLOCKED"
      assert result.env == ""
    end
  end

  test "recovery jobs expose separate exact operation guards before credentials" do
    recovery = File.read!(@recovery_workflow)
    ios = File.read!(@ios_workflow)

    {output, status} =
      Scanner.run_fixture_set(%{recovery_workflow: recovery, ios_backfill_workflow: ios})

    assert status == 0, output

    for id <- [
          "release.rel17.recovery_hex_job_guard",
          "release.rel17.recovery_maven_job_guard",
          "release.rel17.recovery_ios_job_guard",
          "release.rel17.legacy_ios_job_guard"
        ] do
      assert output =~ "OK: #{id}"
    end
  end

  test "removing each recovery entry gate fails its dedicated scanner check" do
    recovery = File.read!(@recovery_workflow)
    ios = File.read!(@ios_workflow)

    for {workflow, job, step, key, id} <- [
          {recovery, "publish", "Re-fetch REL-17 evidence before recovery credentials",
           :recovery_workflow, "release.rel17.recovery_hex_job_guard"},
          {recovery, "recover-android-core",
           "Re-fetch REL-17 evidence before Maven recovery credentials", :recovery_workflow,
           "release.rel17.recovery_maven_job_guard"},
          {ios, "recover-ios-mirror", "Re-fetch REL-17 evidence before iOS recovery credentials",
           :ios_backfill_workflow, "release.rel17.recovery_ios_job_guard"},
          {ios, "publish-ios-mirror", "Re-fetch REL-17 evidence before mirror credentials",
           :ios_backfill_workflow, "release.rel17.legacy_ios_job_guard"}
        ] do
      mutated = Scanner.remove_step!(workflow, job, step)
      assert_scanner_failure(%{key => mutated}, id)
    end
  end

  defp assert_scanner_failure(fixtures, id) do
    {output, status} = Scanner.run_fixture_set(fixtures)
    assert status != 0, output
    assert output =~ "FAIL: #{id}", output
  end
end
