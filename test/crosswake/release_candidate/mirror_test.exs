defmodule Crosswake.ReleaseCandidate.MirrorTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Mirror

  @baseline_sha String.duplicate("a", 40)
  @candidate_sha String.duplicate("b", 40)

  test "baseline accepts only the recorded credential-free 0.2.0 mirror truth" do
    assert Code.ensure_loaded?(Mirror),
           "Mirror.evaluate!/1 must enforce the four closed mirror modes"

    result = Mirror.evaluate!(baseline_fixture())

    assert result.state == "PASS"
    assert result.mode == "baseline"
    assert result.source_ref == "refs/tags/ios-core-v0.2.0"
    assert result.split_sha == @baseline_sha
    assert result.remote_main == @baseline_sha
    assert result.remote_tag == @baseline_sha
    assert result.authorization_checked == false
    assert result.authorization_result == "NOT CHECKED"
    assert result.dry_run_result == "NOT RUN"
    assert result.external_state_changed == false
    assert result.correction == "none"
  end

  test "baseline blocks absent, unreachable, replaced, conflicting, or credentialed observations" do
    input = baseline_fixture()

    mutations = [
      unreachable: put_in(input.remote.status, "UNREACHABLE"),
      absent_main: put_in(input.remote.main, nil),
      absent_tag: put_in(input.remote.tag, nil),
      replaced_main: put_in(input.remote.main, String.duplicate("c", 40)),
      conflicting_tag: put_in(input.remote.tag, String.duplicate("d", 40)),
      recorded_split_changed: %{input | recorded_split_sha: String.duplicate("e", 40)},
      credential_checked: put_in(input.authorization, %{checked: true, result: "PROVEN"}),
      changed: %{input | external_state_changed: true}
    ]

    for {name, mutation} <- mutations do
      result = Mirror.evaluate!(mutation)
      assert result.state == "BLOCKED", "#{name} passed"
      refute result.correction == "none"
    end

    assert Mirror.evaluate!(%{input | external_state_changed: true}).external_state_changed ==
             true
  end

  test "candidate proves exact 0.2.1 split, authorization, atomic porcelain, and no ref change" do
    result = Mirror.evaluate!(candidate_fixture())

    assert result.state == "PASS"
    assert result.mode == "candidate"
    assert result.source_ref == @candidate_sha
    assert result.split_sha == @candidate_sha
    assert result.atomic_supported == true
    assert result.authorization_checked == true
    assert result.authorization_result == "PROVEN"
    assert result.dry_run_result == "PASS"
    assert result.external_state_changed == false
    assert result.correction == "none"
  end

  test "candidate without credentials is honest and every denied, raced, or ambiguous observation blocks" do
    input = candidate_fixture()

    unchecked =
      input
      |> put_in([:authorization], %{checked: false, result: "NOT CHECKED"})
      |> put_in([:dry_run, :status], "NOT RUN")

    result = Mirror.evaluate!(unchecked)
    assert result.state == "BLOCKED"
    assert result.correction == "WRITE AUTHORITY NOT CHECKED"

    mutations = [
      malformed_version: %{input | version: "v0.2.1"},
      short_ref: %{input | source_ref: String.duplicate("b", 39)},
      changed_split: %{input | split_sha: String.duplicate("c", 40)},
      unreachable: put_in(input.remote.status, "UNREACHABLE"),
      denied: put_in(input.authorization, %{checked: true, result: "DENIED"}),
      unsupported_atomic: %{input | atomic_supported: false},
      rejected_porcelain: put_in(input.dry_run.status, "REJECTED"),
      unparseable_porcelain: put_in(input.dry_run.status, "UNPARSEABLE"),
      raced_main: put_in(input.dry_run.after_main, String.duplicate("d", 40)),
      raced_tag: put_in(input.dry_run.after_tag, String.duplicate("e", 40)),
      changed: %{input | external_state_changed: true}
    ]

    for {name, mutation} <- mutations do
      result = Mirror.evaluate!(mutation)
      assert result.state == "BLOCKED", "#{name} passed"
      refute result.correction == "none"
    end

    assert Mirror.evaluate!(%{input | external_state_changed: true}).external_state_changed ==
             true
  end

  test "candidate mode follows any well-formed supplied version, not just the historical 0.2.1" do
    input = candidate_fixture() |> Map.put(:version, "9.9.9")
    result = Mirror.evaluate!(input)

    assert result.state == "PASS"
    assert result.mode == "candidate"

    assert result.push_arguments == [
             "--dry-run",
             "--porcelain",
             "--atomic",
             "#{@candidate_sha}:refs/heads/main",
             "#{@candidate_sha}:refs/tags/v9.9.9"
           ]
  end

  test "baseline mode still refuses anything but the historical baseline version (Pitfall 2)" do
    input = baseline_fixture() |> Map.put(:version, "9.9.9")
    result = Mirror.evaluate!(input)

    assert result.state == "BLOCKED"
    refute result.correction == "none"
  end

  test "adapter exposes separate baseline and candidate modes with bounded output" do
    script = File.read!("script/release_candidate/ios_mirror.sh")
    wrapper = File.read!("script/verify_ios_mirror_backfill.sh")

    assert script =~ "baseline"
    assert script =~ "candidate"
    assert script =~ "subtree split"
    assert script =~ "--dry-run"
    assert script =~ "--porcelain"
    assert script =~ "--atomic"
    assert script =~ "WRITE AUTHORITY NOT CHECKED"
    assert script =~ "RUNTIME=(env)"
    refute script =~ "RUNTIME=()"
    assert wrapper =~ "release_candidate/ios_mirror.sh"

    for forbidden <- ["MIRROR_DEPLOY_KEY=", "ssh-private-key", "remote_url", "command_log"] do
      refute script =~ forbidden
    end
  end

  test "publish permits only immediate ancestor or equal main with immutable atomic refs" do
    assert Code.ensure_loaded?(Mirror)

    assert function_exported?(Mirror, :publication_plan!, 1),
           "Mirror.publication_plan!/1 must isolate ordinary publication from recovery"

    input = publish_fixture()
    result = Mirror.evaluate!(input)

    assert result.state == "PASS"
    assert result.mode == "publish"
    assert result.operation == "PUBLISH_ATOMIC"

    assert result.push_arguments == [
             "--atomic",
             "#{@candidate_sha}:refs/heads/main",
             "#{@candidate_sha}:refs/tags/v0.2.1"
           ]

    refute Enum.any?(result.push_arguments, &String.contains?(&1, "force"))

    refute Enum.any?(
             result.push_arguments,
             &String.contains?(&1, ":" <> String.duplicate("0", 40))
           )

    equal =
      input
      |> put_in([:remote, :main], @candidate_sha)
      |> put_in([:remote, :tag], @candidate_sha)
      |> put_in([:dry_run, :before_main], @candidate_sha)
      |> put_in([:dry_run, :before_tag], @candidate_sha)
      |> put_in([:dry_run, :after_main], @candidate_sha)
      |> put_in([:dry_run, :after_tag], @candidate_sha)
      |> put_in([:approval, :expected_old_ref], @candidate_sha)
      |> Map.put(:ancestry, "EQUAL")

    assert %{state: "PASS", operation: "NOOP", push_arguments: []} = Mirror.evaluate!(equal)

    mutations = [
      diverged: %{input | ancestry: "DIVERGED"},
      conflict: put_in(input.remote.tag, String.duplicate("c", 40)),
      unsupported_atomic: %{input | atomic_supported: false},
      stale_main: put_in(input.dry_run.before_main, String.duplicate("d", 40)),
      raced_main: put_in(input.dry_run.after_main, String.duplicate("e", 40)),
      denied: put_in(input.authorization, %{checked: true, result: "DENIED"})
    ]

    for {name, mutation} <- mutations do
      assert %{state: "BLOCKED", push_arguments: []} = Mirror.evaluate!(mutation),
             "#{name} passed"
    end
  end

  test "phase 170: an empty push_arguments list now fails instead of passing vacuously" do
    input = publish_fixture()

    equal =
      input
      |> put_in([:remote, :main], @candidate_sha)
      |> put_in([:remote, :tag], @candidate_sha)
      |> put_in([:dry_run, :before_main], @candidate_sha)
      |> put_in([:dry_run, :before_tag], @candidate_sha)
      |> put_in([:dry_run, :after_main], @candidate_sha)
      |> put_in([:dry_run, :after_tag], @candidate_sha)
      |> put_in([:approval, :expected_old_ref], @candidate_sha)
      |> Map.put(:ancestry, "EQUAL")

    result = Mirror.evaluate!(equal)

    assert result.push_arguments == []

    assert_raise ExUnit.AssertionError, fn ->
      refute Enum.empty?(result.push_arguments)
    end
  end

  test "recovery alone constructs exact force-with-lease after separate receipt approval" do
    input = recovery_fixture()
    result = Mirror.evaluate!(input)

    assert result.state == "PASS"
    assert result.mode == "recovery"
    assert result.operation == "RECOVER_EXACT_MAIN"

    assert result.push_arguments == [
             "--force-with-lease=refs/heads/main:#{input.approval.expected_old_ref}",
             "#{input.approval.expected_new_ref}:refs/heads/main"
           ]

    mutations = [
      missing_receipt: put_in(input.approval.receipt_digest, nil),
      unapproved: put_in(input.approval.status, "NOT APPROVED"),
      wrong_old: put_in(input.approval.expected_old_ref, String.duplicate("c", 40)),
      wrong_new: put_in(input.approval.expected_new_ref, String.duplicate("d", 40)),
      raced: put_in(input.dry_run.after_main, String.duplicate("e", 40))
    ]

    for {name, mutation} <- mutations do
      assert %{state: "BLOCKED", push_arguments: []} = Mirror.evaluate!(mutation),
             "#{name} passed"
    end

    for mode <- [baseline_fixture(), candidate_fixture(), publish_fixture()] do
      refute Enum.any?(Mirror.evaluate!(mode) |> Map.get(:push_arguments, []), fn argument ->
               String.contains?(argument, "force-with-lease")
             end)
    end
  end

  test "local bare mirror publication uses ordinary atomic fast-forward and preserves old tags" do
    fixture = git_fixture()

    env = [
      {"CROSSWAKE_IOS_MIRROR_RELEASE_REPO", fixture.release_repo},
      {"CROSSWAKE_IOS_MIRROR_PUBLIC_REMOTE", fixture.mirror_repo},
      {"CROSSWAKE_IOS_MIRROR_WRITE_REMOTE", fixture.mirror_repo},
      {"CROSSWAKE_IOS_MIRROR_AUTHORIZATION_CHECKED", "true"},
      {"CROSSWAKE_IOS_MIRROR_EXECUTE", "true"}
    ]

    {output, status} =
      System.cmd(
        "bash",
        [
          "script/release_candidate/ios_mirror.sh",
          "publish",
          "--version",
          "0.2.1",
          "--ref",
          fixture.candidate_ref,
          "--approval-receipt",
          String.duplicate("f", 64),
          "--expected-old-ref",
          fixture.old_split,
          "--expected-new-ref",
          fixture.new_split
        ],
        env: env,
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert git!(fixture.mirror_repo, ["rev-parse", "refs/heads/main"]) == fixture.new_split
    assert git!(fixture.mirror_repo, ["rev-parse", "refs/tags/v0.2.1"]) == fixture.new_split
    assert git!(fixture.mirror_repo, ["rev-parse", "refs/tags/v0.2.0"]) == fixture.old_split
    refute output =~ "force-with-lease"

    expected_split = fixture.new_split

    assert %{
             "state" => "PASS",
             "operation" => "PUBLISHED",
             "external_state_changed" => true,
             "remote_main" => ^expected_split,
             "remote_tag" => ^expected_split
           } = Jason.decode!(output)
  end

  test "publish and recovery remain unreachable from candidate readiness evaluation" do
    script = File.read!("script/release_candidate/ios_mirror.sh")
    wrapper = File.read!("script/verify_ios_mirror_backfill.sh")
    candidate_task = File.read!("lib/mix/tasks/crosswake.release.candidate.ex")

    assert script =~ "publish"
    assert script =~ "recovery"
    assert script =~ "--force-with-lease=refs/heads/main:"
    assert script =~ "--atomic"
    refute candidate_task =~ "ios_mirror.sh"
    refute candidate_task =~ " publish"
    refute candidate_task =~ " recovery"
    refute wrapper =~ "--force-with-lease"
  end

  defp baseline_fixture do
    %{
      mode: "baseline",
      version: "0.2.0",
      source_ref: "refs/tags/ios-core-v0.2.0",
      split_sha: @baseline_sha,
      recorded_split_sha: @baseline_sha,
      remote: %{status: "PASS", main: @baseline_sha, tag: @baseline_sha},
      atomic_supported: false,
      authorization: %{checked: false, result: "NOT CHECKED"},
      dry_run: %{
        status: "NOT RUN",
        before_main: @baseline_sha,
        before_tag: @baseline_sha,
        after_main: @baseline_sha,
        after_tag: @baseline_sha
      },
      external_state_changed: false
    }
  end

  defp candidate_fixture do
    remote_main = String.duplicate("9", 40)

    %{
      mode: "candidate",
      version: "0.2.1",
      source_ref: @candidate_sha,
      split_sha: @candidate_sha,
      recorded_split_sha: @candidate_sha,
      remote: %{status: "PASS", main: remote_main, tag: nil},
      atomic_supported: true,
      authorization: %{checked: true, result: "PROVEN"},
      dry_run: %{
        status: "PASS",
        before_main: remote_main,
        before_tag: nil,
        after_main: remote_main,
        after_tag: nil
      },
      external_state_changed: false
    }
  end

  defp publish_fixture do
    candidate_fixture()
    |> Map.put(:mode, "publish")
    |> Map.put(:ancestry, "ANCESTOR")
    |> Map.put(:approval, %{
      status: "APPROVED",
      receipt_digest: String.duplicate("f", 64),
      expected_old_ref: String.duplicate("9", 40),
      expected_new_ref: @candidate_sha
    })
  end

  defp recovery_fixture do
    publish_fixture()
    |> Map.put(:mode, "recovery")
    |> Map.put(:ancestry, "DIVERGED")
    |> put_in([:approval, :status], "RECOVERY APPROVED")
  end

  defp git_fixture do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-mirror-test-#{System.unique_integer([:positive, :monotonic])}"
      )

    release_repo = Path.join(root, "release")
    mirror_repo = Path.join(root, "mirror.git")
    File.mkdir_p!(Path.join(release_repo, "packages/crosswake-shell-core-ios/Sources"))
    on_exit(fn -> File.rm_rf!(root) end)

    git!(release_repo, ["init", "-q"])
    git!(release_repo, ["config", "user.email", "fixture@example.invalid"])
    git!(release_repo, ["config", "user.name", "Crosswake Fixture"])

    source_file = Path.join(release_repo, "packages/crosswake-shell-core-ios/Sources/Core.swift")
    File.write!(source_file, "public let version = 1\n")
    git!(release_repo, ["add", "."])
    git!(release_repo, ["commit", "-qm", "baseline"])

    old_split =
      git!(release_repo, [
        "subtree",
        "split",
        "--prefix=packages/crosswake-shell-core-ios",
        "HEAD"
      ])
      |> split_sha!()

    git!(root, ["init", "--bare", "-q", mirror_repo])
    git!(release_repo, ["push", "-q", mirror_repo, "#{old_split}:refs/heads/main"])
    git!(release_repo, ["push", "-q", mirror_repo, "#{old_split}:refs/tags/v0.2.0"])

    File.write!(source_file, "public let version = 2\n")
    git!(release_repo, ["add", "."])
    git!(release_repo, ["commit", "-qm", "candidate"])
    candidate_ref = git!(release_repo, ["rev-parse", "HEAD"])

    new_split =
      git!(release_repo, [
        "subtree",
        "split",
        "--prefix=packages/crosswake-shell-core-ios",
        candidate_ref
      ])
      |> split_sha!()

    %{
      release_repo: release_repo,
      mirror_repo: mirror_repo,
      candidate_ref: candidate_ref,
      old_split: old_split,
      new_split: new_split
    }
  end

  defp git!(root, args) do
    {output, status} = System.cmd("git", ["-C", root | args], stderr_to_stdout: true)
    assert status == 0, output
    String.trim(output)
  end

  defp split_sha!(output) do
    output
    |> then(&Regex.scan(~r/[0-9a-f]{40}/, &1))
    |> List.last()
    |> hd()
  end
end
