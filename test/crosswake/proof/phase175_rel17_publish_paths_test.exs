defmodule Crosswake.Proof.Phase175Rel17PublishPathsTest do
  use ExUnit.Case, async: false
  import Bitwise

  alias Crosswake.Phase175Rel17Fixtures, as: Rel17
  alias Crosswake.ReleaseWorkflowFixtures, as: Scanner

  @release_workflow ".github/workflows/release-please.yml"
  @helper "script/guarded_hex_publish.sh"

  test "a complete linked-release context is loaded into private runner state" do
    result = Rel17.run_loader(Rel17.context())
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status == 0, result.output
    assert result.env =~ "REL17_OPERATION=linked_release\n"
    assert result.env =~ "REL17_PACKAGE=crosswake\n"
    assert result.env =~ "REL17_MERGE_OID="
    assert File.read!(result.auth_file) =~ ~s("state":"CONSUMED")
    assert (File.stat!(result.auth_file).mode &&& 0o777) == 0o600
  end

  test "a changed policy fingerprint blocks before runner outputs are written" do
    ctx = Jason.decode!(Rel17.context())
    changed = Map.put(ctx, "policy_sha256", String.duplicate("9", 64)) |> Jason.encode!()
    result = Rel17.run_loader(changed)
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status != 0
    assert result.output =~ "REL-17 BLOCKED"
    assert result.env == ""
    refute result.auth_file && File.exists?(result.auth_file)
  end

  test "a changed merge selector blocks before runner outputs are written" do
    ctx = Jason.decode!(Rel17.context())
    changed = Map.put(ctx, "merge_oid", String.duplicate("9", 40)) |> Jason.encode!()
    result = Rel17.run_loader(changed)
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status != 0
    assert result.output =~ "REL-17 BLOCKED"
    assert result.env == ""
    refute result.auth_file && File.exists?(result.auth_file)
  end

  test "an ordinary gate context cannot be reinterpreted as a recovery context" do
    result = Rel17.run_loader(Rel17.context(), operation: "recovery")
    on_exit(fn -> Rel17.clean_loader_result(result) end)

    assert result.status != 0
    assert result.env == ""
  end

  test "ordinary core jobs expose their individual fresh-gate checks" do
    {output, status} = Scanner.run_fixture_set(%{release_workflow: File.read!(@release_workflow)})

    assert status == 0, output

    for id <- [
          "release.rel17.approved_guard",
          "release.rel17.release_creation_guard",
          "release.rel17.core_hex_job_guard",
          "release.rel17.core_ios_job_guard",
          "release.rel17.core_maven_job_guard",
          "release.rel17.hex_final_boundary",
          "release.rel17.ios_final_boundary",
          "release.rel17.maven_final_boundary"
        ] do
      assert output =~ "OK: #{id}"
    end
  end

  test "removing each ordinary publisher job gate fails its named check" do
    workflow = File.read!(@release_workflow)

    for {job, id, step} <- [
          {"publish-hex", "release.rel17.core_hex_job_guard",
           "Re-fetch REL-17 evidence before Hex credentials"},
          {"publish-ios-core", "release.rel17.core_ios_job_guard",
           "Re-fetch REL-17 evidence before mirror credentials"},
          {"publish-android-core", "release.rel17.core_maven_job_guard",
           "Re-fetch REL-17 evidence before Maven credentials"}
        ] do
      mutated = Scanner.remove_step!(workflow, job, step)
      assert_scanner_failure(%{release_workflow: mutated}, id)
    end
  end

  test "moving the Release Please gate after its action fails the release-creation check" do
    workflow = File.read!(@release_workflow)
    block = Scanner.job_block!(workflow, "release-please")
    gate = named_step!(block, "Re-fetch REL-17 evidence before Release Please")
    action = named_step!(block, "Run Release Please")
    mutated = Scanner.replace_in_job(workflow, "release-please", gate <> action, action <> gate)

    assert_scanner_failure(%{release_workflow: mutated}, "release.rel17.release_creation_guard")
  end

  test "an unclassified package-version merge fails before Release Please can act" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "approved-release-guard",
        "echo \"REL-17 BLOCKED reason=unclassified_release_version_change\" >&2",
        "echo \"candidate omitted\" >&2"
      )

    assert_scanner_failure(%{release_workflow: mutated}, "release.rel17.approved_guard")
  end

  test "removing the common Hex final guard fails its dedicated boundary check" do
    helper = File.read!(@helper)

    mutated =
      Scanner.replace_once!(
        helper,
        "publish_package() {\n  require_rel17_publish_evidence\n",
        "publish_package() {\n  true\n"
      )

    assert_scanner_failure(%{helper: mutated}, "release.rel17.hex_final_boundary")
  end

  test "the final Hex script step must receive its live gate token" do
    workflow = File.read!(@release_workflow)

    mutated =
      Scanner.replace_in_job(
        workflow,
        "publish-hex",
        "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}\n          GH_TOKEN: ${{ github.token }}",
        "HEX_API_KEY: ${{ secrets.HEX_API_KEY }}"
      )

    assert_scanner_failure(%{release_workflow: mutated}, "release.rel17.core_hex_job_guard")
  end

  defp assert_scanner_failure(fixtures, id) do
    {output, status} = Scanner.run_fixture_set(fixtures)
    assert status != 0, output
    assert output =~ "FAIL: #{id}", output
  end

  defp named_step!(block, name) do
    case Regex.run(~r/(?ms)^      - name: #{Regex.escape(name)}\n.*?(?=^      - |\z)/, block) do
      [step] -> step
      _ -> flunk("expected named step #{inspect(name)}")
    end
  end
end
