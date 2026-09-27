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
    reason = "echo \"REL-17 BLOCKED reason=unclassified_release_version_change\" >&2"

    mutated =
      workflow
      |> Scanner.replace_in_job(
        "approved-release-guard",
        reason,
        "echo \"candidate omitted\" >&2"
      )
      |> Scanner.replace_in_job(
        "approved-release-guard",
        reason,
        "echo \"candidate omitted\" >&2"
      )

    assert_scanner_failure(%{release_workflow: mutated}, "release.rel17.approved_guard")
  end

  test "a test-path-only mix.exs merge is not treated as a release-version change" do
    result =
      run_version_classifier_fixture(fn root ->
        mix_path = Path.join(root, "mix.exs")

        File.write!(
          mix_path,
          String.replace(File.read!(mix_path), "test_paths: []", "test_paths: [\"test\"]")
        )
      end)

    assert result.status == 0, result.output
    assert result.output =~ "linked_release=false"
    refute result.output =~ "candidate_operation="
    refute result.output =~ "REL-17 BLOCKED"
  end

  test "a partial linked-release version update still fails closed" do
    result =
      run_version_classifier_fixture(fn root ->
        mix_path = Path.join(root, "mix.exs")
        File.write!(mix_path, String.replace(File.read!(mix_path), "0.2.0", "0.2.1"))
      end)

    assert result.status != 0
    assert result.output =~ "REL-17 BLOCKED reason=unclassified_release_version_change"
    refute result.output =~ "candidate_operation="
  end

  test "a complete linked-release version update is classified as one release candidate" do
    result =
      run_version_classifier_fixture(fn root ->
        mix_path = Path.join(root, "mix.exs")
        manifest_path = Path.join(root, ".release-please-manifest.json")
        android_path = Path.join(root, "packages/crosswake-shell-core-android/build.gradle.kts")

        File.write!(mix_path, String.replace(File.read!(mix_path), "0.2.0", "0.2.1"))
        File.write!(android_path, String.replace(File.read!(android_path), "0.2.0", "0.2.1"))

        manifest =
          manifest_path
          |> File.read!()
          |> Jason.decode!()
          |> Map.update!(".", fn _ -> "0.2.1" end)
          |> Map.update!("packages/crosswake-shell-core-ios", fn _ -> "0.2.1" end)
          |> Map.update!("packages/crosswake-shell-core-android", fn _ -> "0.2.1" end)

        File.write!(manifest_path, Jason.encode!(manifest))
      end)

    assert result.status == 0, result.output
    assert result.output =~ "candidate_operation=linked_release"
    assert result.output =~ "candidate_package=crosswake"
    assert result.output =~ "candidate_version=0.2.1"
  end

  test "a manifest-and-source companion version update is classified independently" do
    result =
      run_version_classifier_fixture(fn root ->
        manifest_path = Path.join(root, ".release-please-manifest.json")
        companion_path = Path.join(root, "packages/crosswake_rulestead/mix.exs")

        manifest =
          manifest_path
          |> File.read!()
          |> Jason.decode!()
          |> Map.update!("packages/crosswake_rulestead", fn _ -> "0.1.1" end)

        File.write!(manifest_path, Jason.encode!(manifest))
        File.write!(companion_path, "@version \"0.1.1\"\n")
      end)

    assert result.status == 0, result.output
    assert result.output =~ "candidate_operation=companion_publish"
    assert result.output =~ "candidate_package=crosswake_rulestead"
    assert result.output =~ "candidate_version=0.1.1"
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

  defp run_version_classifier_fixture(mutate_release_candidate) do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-rel17-version-classifier-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(Path.join(root, "packages/crosswake-shell-core-android"))

    on_exit(fn -> File.rm_rf!(root) end)

    File.write!(
      Path.join(root, "mix.exs"),
      "@version \"0.2.0\"\ndef project do\n  [test_paths: []]\nend\n"
    )

    File.write!(
      Path.join(root, "packages/crosswake-shell-core-android/build.gradle.kts"),
      "version = \"0.2.0\"\n"
    )

    File.write!(
      Path.join(root, ".release-please-manifest.json"),
      Jason.encode!(%{
        "." => "0.2.0",
        "packages/crosswake-shell-core-ios" => "0.2.0",
        "packages/crosswake-shell-core-android" => "0.2.0",
        "packages/crosswake_rulestead" => "0.1.0",
        "packages/crosswake_rindle" => "0.1.0",
        "packages/crosswake_sigra" => "0.1.0",
        "packages/crosswake_chimeway" => "0.1.0",
        "packages/crosswake_threadline" => "0.1.0"
      })
    )

    for package <- ~w(rulestead rindle sigra chimeway threadline) do
      package_path = Path.join(root, "packages/crosswake_#{package}")
      File.mkdir_p!(package_path)
      File.write!(Path.join(package_path, "mix.exs"), "@version \"0.1.0\"\n")
    end

    git!(root, ["init", "--quiet", "--initial-branch=main"])
    git!(root, ["config", "user.name", "Crosswake test"])
    git!(root, ["config", "user.email", "crosswake-test@example.invalid"])
    git!(root, ["add", "."])
    git!(root, ["commit", "--quiet", "-m", "base release state"])
    git!(root, ["switch", "--quiet", "-c", "release-candidate"])
    mutate_release_candidate.(root)
    git!(root, ["add", "."])
    git!(root, ["commit", "--quiet", "-m", "release candidate"])
    git!(root, ["switch", "--quiet", "main"])

    git!(root, [
      "merge",
      "--quiet",
      "--no-ff",
      "release-candidate",
      "-m",
      "merge release candidate"
    ])

    head = git!(root, ["rev-parse", "HEAD"]) |> String.trim()
    output_path = Path.join(root, "github-output")

    {run_body, status} =
      System.cmd("bash", ["-c", version_classifier_script()],
        cd: root,
        env: [{"RUN_HEAD", head}, {"GITHUB_OUTPUT", output_path}],
        stderr_to_stdout: true
      )

    output_file = if File.exists?(output_path), do: File.read!(output_path), else: ""
    %{output: run_body <> output_file, status: status}
  end

  defp version_classifier_script do
    workflow = File.read!(@release_workflow)
    guard = Scanner.job_block!(workflow, "approved-release-guard")

    step =
      named_step!(guard, "Require approved head parentage, identical tree, and exact receipt")

    lines = String.split(step, "\n")
    run_index = Enum.find_index(lines, &(&1 == "        run: |"))
    if is_nil(run_index), do: flunk("REL-17 guard step has no literal run block")

    shell_lines =
      lines
      |> Enum.drop(run_index + 1)
      |> Enum.take_while(fn line -> line == "" or String.starts_with?(line, "          ") end)
      |> Enum.map(fn
        "" -> ""
        line -> String.replace_prefix(line, "          ", "")
      end)

    shell = Enum.join(shell_lines, "\n")
    marker = "# A linked release must be a two-parent merge. The approved Release Please"
    [classifier, _rest] = String.split(shell, marker, parts: 2)

    classifier <>
      "\nprintf 'candidate_operation=%s\\ncandidate_package=%s\\ncandidate_version=%s\\n' \"$candidate_operation\" \"$candidate_package\" \"$candidate_version\"\n"
  end

  defp git!(root, args) do
    case System.cmd("git", args, cd: root, stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> raise "git #{Enum.join(args, " ")} failed (#{status}): #{output}"
    end
  end

  defp named_step!(block, name) do
    case Regex.run(~r/(?ms)^      - name: #{Regex.escape(name)}\n.*?(?=^      - |\z)/, block) do
      [step] -> step
      _ -> flunk("expected named step #{inspect(name)}")
    end
  end
end
