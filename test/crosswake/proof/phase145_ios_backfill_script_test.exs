defmodule Crosswake.Proof.Phase145IosBackfillScriptTest do
  use ExUnit.Case, async: true

  @script "script/verify_ios_mirror_backfill.sh"
  @version "0.2.1"

  @tag :phase145_ios_backfill_script
  test "script source keeps verify-first and exact-ref guardrails" do
    script = File.read!(@script)

    assert script =~ "set -euo pipefail"
    assert script =~ "ok()"
    assert script =~ "fail()"
    assert script =~ "[crosswake] OK"
    assert script =~ "[crosswake] FAIL"
    assert script =~ "--version"
    assert script =~ "--ref"
    assert script =~ "--apply"
    assert script =~ "--update-main"
    assert script =~ "baseline|candidate"
    assert script =~ "publish|recovery"
    assert script =~ "release_candidate/ios_mirror.sh"
    assert script =~ "CROSSWAKE_IOS_MIRROR_EXECUTE=true"
    assert script =~ "--approval-receipt"
    assert script =~ "--expected-old-ref"
    assert script =~ "--expected-new-ref"
  end

  @tag :phase145_ios_backfill_script
  test "candidate rehearsal proves write authorization without changing the mirror" do
    fixture = backfill_fixture()

    {output, exit_code} = run_script(fixture)
    result = output |> String.split("\n", trim: true) |> hd() |> Jason.decode!()

    assert exit_code == 0, output
    assert result["state"] == "PASS"
    assert result["authorization_result"] == "PROVEN"
    assert result["external_state_changed"] == false
    refute tag_exists?(fixture.mirror, "v0.2.1")
  end

  @tag :phase145_ios_backfill_script
  test "candidate mode rejects apply before any mirror operation" do
    fixture = backfill_fixture()
    {output, exit_code} = run_script(fixture, ["--apply"])

    assert exit_code != 0
    assert output =~ "[crosswake] FAIL: baseline and candidate modes are read-only"
    refute tag_exists?(fixture.mirror, "v0.2.1")
  end

  @tag :phase145_ios_backfill_script
  test "exact existing mirror tag exits successfully without push" do
    fixture = backfill_fixture()
    push_tag!(fixture.release, fixture.mirror, fixture.split_sha, "v0.2.1")

    {output, exit_code} = run_script(fixture)
    result = output |> String.split("\n", trim: true) |> hd() |> Jason.decode!()

    assert exit_code == 0, output
    assert result["remote_tag"] == fixture.split_sha
    assert result["external_state_changed"] == false
  end

  @tag :phase145_ios_backfill_script
  test "mismatched existing mirror tag fails closed and leaves tag unchanged" do
    fixture = backfill_fixture()
    mismatch_sha = add_commit!(fixture.release, "mismatch.txt", "wrong release\n")
    push_tag!(fixture.release, fixture.mirror, mismatch_sha, "v0.2.1")
    before_sha = mirror_tag_sha(fixture.mirror, "v0.2.1")

    {output, exit_code} = run_script(fixture)

    assert exit_code != 0
    assert output =~ "restore_mirror_write_authority"
    assert mirror_tag_sha(fixture.mirror, "v0.2.1") == before_sha
  end

  defp backfill_fixture do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase145-ios-backfill-#{System.unique_integer([:positive])}"
      )

    release = Path.join(root, "release")
    mirror = Path.join(root, "mirror.git")
    File.mkdir_p!(release)
    File.mkdir_p!(mirror)
    on_exit(fn -> File.rm_rf(root) end)

    git!(["init", "-q", release])
    git!(["-C", release, "config", "user.email", "ci@crosswake"])
    git!(["-C", release, "config", "user.name", "Crosswake CI"])

    File.mkdir_p!(Path.join(release, "packages/crosswake-shell-core-ios"))
    File.mkdir_p!(Path.join(release, "packages/crosswake-shell-core-android"))

    File.write!(
      Path.join(release, "packages/crosswake-shell-core-ios/Package.swift"),
      "// swift package\n"
    )

    File.write!(
      Path.join(release, "packages/crosswake-shell-core-android/build.gradle.kts"),
      "// gradle\n"
    )

    File.write!(
      Path.join(release, ".release-please-manifest.json"),
      Jason.encode!(%{
        "." => @version,
        "packages/crosswake-shell-core-ios" => @version,
        "packages/crosswake-shell-core-android" => @version
      })
    )

    git!(["-C", release, "add", "."])
    git!(["-C", release, "commit", "-q", "-m", "release fixture"])
    split_sha = git!(["-C", release, "rev-parse", "HEAD"]) |> String.trim()

    git!(["-C", release, "tag", "hex-v#{@version}", split_sha])
    git!(["-C", release, "tag", "ios-core-v#{@version}", split_sha])
    git!(["-C", release, "tag", "android-core-v#{@version}", split_sha])
    git!(["init", "--bare", "-q", mirror])
    git!(["-C", release, "push", mirror, "HEAD:refs/heads/main"])

    %{release: release, mirror: mirror, split_sha: split_sha}
  end

  defp run_script(fixture, args \\ [], env \\ []) do
    base_env = [
      {"CROSSWAKE_IOS_MIRROR_RELEASE_REPO", fixture.release},
      {"CROSSWAKE_IOS_MIRROR_PUBLIC_REMOTE", fixture.mirror},
      {"CROSSWAKE_IOS_MIRROR_WRITE_REMOTE", fixture.mirror},
      {"CROSSWAKE_IOS_MIRROR_SPLIT_SHA", fixture.split_sha},
      {"CROSSWAKE_IOS_MIRROR_AUTHORIZATION_CHECKED", "true"}
    ]

    System.cmd(
      "bash",
      [@script, "--mode", "candidate", "--version", @version, "--ref", fixture.split_sha] ++
        args,
      stderr_to_stdout: true,
      env: base_env ++ env
    )
  end

  defp add_commit!(repo, path, contents) do
    File.write!(Path.join(repo, path), contents)
    git!(["-C", repo, "add", path])
    git!(["-C", repo, "commit", "-q", "-m", "mismatch"])
    git!(["-C", repo, "rev-parse", "HEAD"]) |> String.trim()
  end

  defp push_tag!(repo, mirror, sha, tag) do
    git!(["-C", repo, "push", mirror, "#{sha}:refs/tags/#{tag}"])
  end

  defp tag_exists?(mirror, tag) do
    {_, exit_code} =
      System.cmd("git", [
        "--git-dir",
        mirror,
        "show-ref",
        "--verify",
        "--quiet",
        "refs/tags/#{tag}"
      ])

    exit_code == 0
  end

  defp mirror_tag_sha(mirror, tag) do
    git!(["--git-dir", mirror, "show-ref", "-s", "refs/tags/#{tag}"]) |> String.trim()
  end

  defp git!(args) do
    {output, exit_code} = System.cmd("git", args, stderr_to_stdout: true)
    assert exit_code == 0, output
    output
  end
end
