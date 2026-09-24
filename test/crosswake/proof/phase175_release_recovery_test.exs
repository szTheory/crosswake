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

  test "ordinary iOS job requires its own pinned Beam setup before mirror publish" do
    release = File.read!(@release_workflow)

    assert_failure!(
      "release.ios.ordinary_mix_setup",
      release_workflow:
        Fixtures.replace_in_job(
          release,
          "publish-ios-core",
          "      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0\n        with:\n          version-file: .tool-versions\n          version-type: strict\n\n      - name: Resolve locked Mix dependencies\n        run: mix deps.get --check-locked\n",
          ""
        )
    )

    late_setup =
      Fixtures.replace_in_job(
        release,
        "publish-ios-core",
        "      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0\n        with:\n          version-file: .tool-versions\n          version-type: strict\n\n      - name: Resolve locked Mix dependencies\n        run: mix deps.get --check-locked\n",
        ""
      )
      |> Fixtures.replace_in_job(
        "publish-ios-core",
        "--expected-new-ref \"$(git subtree split --prefix=packages/crosswake-shell-core-ios '${{ needs.approved-release-guard.outputs.merge_oid }}' | tail -1)\"",
        "--expected-new-ref \"$(git subtree split --prefix=packages/crosswake-shell-core-ios '${{ needs.approved-release-guard.outputs.merge_oid }}' | tail -1)\"\n\n      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93\n        with:\n          version-file: .tool-versions\n          version-type: strict\n      - run: mix deps.get --check-locked"
      )

    assert_failure!("release.ios.ordinary_mix_setup", release_workflow: late_setup)

    {output, status} = Fixtures.run_fixture_set(release_workflow: release)
    assert status == 0, output
    assert output =~ "[crosswake] OK: release.ios.ordinary_mix_setup"
  end

  test "iOS candidate adapter refuses without deploy credentials or execute authority" do
    remote =
      Path.join(
        System.tmp_dir!(),
        "phase175-ios-candidate-#{System.unique_integer([:positive])}.git"
      )

    {_output, 0} = System.cmd("git", ["init", "--bare", remote], stderr_to_stdout: true)
    on_exit(fn -> File.rm_rf!(remote) end)

    ref =
      System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) |> elem(0) |> String.trim()

    {output, status} =
      System.cmd(
        "bash",
        [
          "script/release_candidate/ios_mirror.sh",
          "candidate",
          "--version",
          "0.2.4",
          "--ref",
          ref
        ],
        env: [
          {"SSH_AUTH_SOCK", nil},
          {"MIRROR_DEPLOY_KEY", nil},
          {"CROSSWAKE_IOS_MIRROR_EXECUTE", "false"},
          {"CROSSWAKE_IOS_MIRROR_SPLIT_SHA", String.duplicate("b", 40)},
          {"CROSSWAKE_IOS_MIRROR_PUBLIC_REMOTE", remote}
        ],
        stderr_to_stdout: true
      )

    assert status == 1, output
    assert output =~ "WRITE AUTHORITY NOT CHECKED", output
    assert output =~ "\"external_state_changed\":false", output
  end

  test "ordinary Android observe accepts a synthetic exact merge and receipt" do
    fixture = android_fixture()
    on_exit(fn -> File.rm_rf!(fixture.root) end)

    {output, status} = run_android(fixture, [])
    assert status == 0, output
    assert output =~ "external_state_changed=false"

    gradlew = Path.join(fixture.root, "packages/crosswake-shell-core-android/gradlew")
    File.write!(gradlew, "#!/bin/sh\nprintf invoked > \"$ANDROID_FIXTURE_GRADLE_MARKER\"\n")
    File.chmod!(gradlew, 0o755)
    {output, status} = run_android(fixture, execute: true)
    assert status == 0, output
    assert File.read!(fixture.gradle_marker) == "invoked"
  end

  test "ordinary Android observe rejects wrong bindings before publication" do
    fixture = android_fixture()
    on_exit(fn -> File.rm_rf!(fixture.root) end)

    cases = [
      {:ref, String.duplicate("c", 40)},
      {:head, String.duplicate("d", 40)},
      {:tree, String.duplicate("e", 40)},
      {:base, String.duplicate("g", 40)},
      {:version, "9.8.7"},
      {:receipt, String.duplicate("f", 64)}
    ]

    for {field, value} <- cases do
      {output, status} = run_android(fixture, [{field, value}])
      assert status != 0, "#{field} unexpectedly passed: #{output}"
      refute output =~ fixture.receipt_body, "receipt bytes leaked for #{field}"
    end
  end

  test "Android receipt workflow and recovery identity assertions reject seeded gaps" do
    release = File.read!(@release_workflow)
    publication = File.read!("script/release_candidate/android_publication.sh")

    for {needle, replacement} <- [
          {"gh run download \"$RECEIPT_RUN_ID\"", "echo no-download"},
          {"select(.name == $name and .expired == false)] | length')\" -eq 1 ]", "true"},
          {"[ \"$receipt_digest\" = \"$APPROVED_RECEIPT\" ]", "true"},
          {"phase168-candidate-receipt-${APPROVED_HEAD}", "phase168-candidate-receipt-stale"},
          {"--receipt-file \"$RUNNER_TEMP/approved-candidate-receipt/candidate-receipt.json\"",
           ""}
        ] do
      mutated = Fixtures.replace_in_job(release, "publish-android-core", needle, replacement)

      assert_android_scanner_failure!(
        "release.android.ordinary_receipt_chain",
        mutated,
        publication
      )
    end

    assert_android_scanner_failure!(
      "release.android.recovery_identity_scope",
      release,
      String.replace(publication, "[ \"$APPROVED_TREE\" = \"$PHASE168_APPROVED_TREE\" ]", "true")
    )

    assert_android_scanner_failure!(
      "release.android.recovery_identity_scope",
      release,
      String.replace(
        publication,
        "if [ \"$MODE\" = \"recovery\" ]; then",
        "if [ \"$MODE\" != \"observe\" ]; then",
        global: false
      )
    )
  end

  defp android_fixture do
    root = Path.join(System.tmp_dir!(), "phase175-android-#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(root, "packages/crosswake-shell-core-android"))

    File.write!(
      Path.join(root, "packages/crosswake-shell-core-android/build.gradle.kts"),
      "version = \"9.8.6\"\n"
    )

    {_out, 0} = System.cmd("git", ["init", root], stderr_to_stdout: true)

    {_out, 0} =
      System.cmd("git", ["-C", root, "config", "user.name", "Fixture"], stderr_to_stdout: true)

    {_out, 0} =
      System.cmd("git", ["-C", root, "config", "user.email", "fixture@example.invalid"],
        stderr_to_stdout: true
      )

    {_out, 0} = System.cmd("git", ["-C", root, "add", "."], stderr_to_stdout: true)
    {_out, 0} = System.cmd("git", ["-C", root, "commit", "-m", "fixture"], stderr_to_stdout: true)
    tree = git!(root, ["rev-parse", "HEAD^{tree}"])
    seed = git!(root, ["rev-parse", "HEAD"])
    base = git!(root, ["commit-tree", tree, "-p", seed, "-m", "fixture base"])
    head = git!(root, ["commit-tree", tree, "-p", seed, "-m", "fixture head"])
    merge = git!(root, ["commit-tree", tree, "-p", base, "-p", head, "-m", "fixture merge"])

    {_out, 0} =
      System.cmd("git", ["-C", root, "checkout", "--detach", merge], stderr_to_stdout: true)

    receipt = %{
      state: "READY FOR APPROVAL",
      identity: %{
        bound: %{version: "9.8.6", ref: head, head: head, tree: tree, base: base},
        observed: %{version: "9.8.6", ref: head, head: head, tree: tree, base: base}
      },
      external_state: %{publication: "NONE", changed: false}
    }

    receipt_body = Jason.encode!(receipt)
    receipt_path = Path.join(root, "candidate-receipt.json")
    File.write!(receipt_path, receipt_body)

    %{
      root: root,
      base: base,
      head: head,
      merge: merge,
      tree: tree,
      receipt_path: receipt_path,
      receipt_body: receipt_body,
      gradle_marker: Path.join(root, "gradle-invoked")
    }
  end

  defp run_android(fixture, overrides) do
    values = Map.new(overrides)
    version = Map.get(values, :version, "9.8.6")

    receipt_path =
      if Map.has_key?(values, :base) do
        receipt = Jason.decode!(fixture.receipt_body)
        receipt = put_in(receipt, ["identity", "bound", "base"], values.base)
        receipt = put_in(receipt, ["identity", "observed", "base"], values.base)
        File.write!(fixture.receipt_path, Jason.encode!(receipt))
        fixture.receipt_path
      else
        File.write!(fixture.receipt_path, fixture.receipt_body)
        fixture.receipt_path
      end

    args =
      [
        "script/release_candidate/android_publication.sh",
        "--release-root",
        fixture.root,
        "--version",
        version,
        "--ref",
        Map.get(values, :ref, fixture.merge),
        "--approved-head",
        Map.get(values, :head, fixture.head),
        "--approved-tree",
        Map.get(values, :tree, fixture.tree),
        "--candidate-receipt",
        Map.get(values, :receipt, digest_file(receipt_path)),
        "--receipt-file",
        receipt_path
      ] ++ if(Map.get(values, :execute, false), do: ["--execute"], else: [])

    System.cmd("bash", args,
      stderr_to_stdout: true,
      env: [{"ANDROID_FIXTURE_GRADLE_MARKER", fixture.gradle_marker}]
    )
  end

  defp git!(root, args) do
    {out, 0} = System.cmd("git", ["-C", root | args], stderr_to_stdout: true)
    String.trim(out)
  end

  defp digest_file(path),
    do: path |> File.read!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)

  defp assert_android_scanner_failure!(check_id, release, publication) do
    release_path =
      Path.join(System.tmp_dir!(), "phase175-release-#{System.unique_integer([:positive])}.yml")

    publication_path =
      Path.join(System.tmp_dir!(), "phase175-android-#{System.unique_integer([:positive])}.sh")

    File.write!(release_path, release)
    File.write!(publication_path, publication)

    on_exit(fn ->
      File.rm(release_path)
      File.rm(publication_path)
    end)

    {output, status} =
      System.cmd("elixir", ["script/check_release_workflow_integrity.exs", release_path],
        stderr_to_stdout: true,
        env: [{"ANDROID_PUBLICATION_PATH", publication_path}]
      )

    assert status != 0, output
    assert output =~ "[crosswake] FAIL: #{check_id}", output
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
