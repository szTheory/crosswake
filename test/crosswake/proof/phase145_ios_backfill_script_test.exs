defmodule Crosswake.Proof.Phase145IosBackfillScriptTest do
  use ExUnit.Case, async: true

  @script "script/verify_ios_mirror_backfill.sh"
  @version "0.2.0"
  @source_ref "refs/tags/ios-core-v0.2.0"

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
    assert script =~ "main|master|HEAD|heads/*|refs/heads/*|v*|[0-9]*"
    assert script =~ "refs/tags/hex-v${VERSION}"
    assert script =~ "refs/tags/android-core-v${VERSION}"
    assert script =~ "refs/tags/v${VERSION}"
    assert script =~ ".release-please-manifest.json"
    assert script =~ "packages/crosswake-shell-core-ios"
    assert script =~ "splitsh-lite v1.0.1"
    assert script =~ "--force-with-lease=refs/heads/main"
  end

  @tag :phase145_ios_backfill_script
  test "verify-only mode reports absent mirror tag without requiring MIRROR_PUSH_TOKEN" do
    fixture = backfill_fixture()

    {output, exit_code} = run_script(fixture)

    assert exit_code == 0, output
    assert output =~ "[crosswake] OK: SwiftPM mirror refs/tags/v0.2.0 is absent"
    assert output =~ "verification-only mode made no changes"
  end

  @tag :phase145_ios_backfill_script
  test "apply mode requires MIRROR_PUSH_TOKEN before mutation" do
    fixture = backfill_fixture()

    {output, exit_code} = run_script(fixture, ["--apply"])

    assert exit_code != 0
    assert output =~ "[crosswake] FAIL: MIRROR_PUSH_TOKEN is required for --apply."
    refute tag_exists?(fixture.mirror, "v0.2.0")
  end

  @tag :phase145_ios_backfill_script
  test "exact existing mirror tag exits successfully without push" do
    fixture = backfill_fixture()
    push_tag!(fixture.release, fixture.mirror, fixture.split_sha, "v0.2.0")

    {output, exit_code} = run_script(fixture)

    assert exit_code == 0, output
    assert output =~ "already points at #{fixture.split_sha}; no push needed"
  end

  @tag :phase145_ios_backfill_script
  test "mismatched existing mirror tag fails closed and leaves tag unchanged" do
    fixture = backfill_fixture()
    mismatch_sha = add_commit!(fixture.release, "mismatch.txt", "wrong release\n")
    push_tag!(fixture.release, fixture.mirror, mismatch_sha, "v0.2.0")
    before_sha = mirror_tag_sha(fixture.mirror, "v0.2.0")

    {output, exit_code} = run_script(fixture)

    assert exit_code != 0
    assert output =~ "[crosswake] FAIL: SwiftPM mirror refs/tags/v0.2.0 points at #{mismatch_sha}"
    assert output =~ "Do not delete or move the public SwiftPM tag automatically"
    assert mirror_tag_sha(fixture.mirror, "v0.2.0") == before_sha
  end

  defp backfill_fixture do
    root = Path.join(System.tmp_dir!(), "crosswake-phase145-ios-backfill-#{System.unique_integer([:positive])}")
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
    File.write!(Path.join(release, "packages/crosswake-shell-core-ios/Package.swift"), "// swift package\n")
    File.write!(Path.join(release, "packages/crosswake-shell-core-android/build.gradle.kts"), "// gradle\n")

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

    %{release: release, mirror: mirror, split_sha: split_sha}
  end

  defp run_script(fixture, args \\ [], env \\ []) do
    base_env = [
      {"CROSSWAKE_IOS_BACKFILL_RELEASE_REPO", fixture.release},
      {"CROSSWAKE_IOS_BACKFILL_MIRROR_REMOTE", fixture.mirror},
      {"CROSSWAKE_IOS_BACKFILL_SPLIT_SHA", fixture.split_sha},
      {"CROSSWAKE_IOS_BACKFILL_HEX_LIVE", "true"},
      {"CROSSWAKE_IOS_BACKFILL_MAVEN_LIVE", "true"}
    ]

    System.cmd(
      "bash",
      [@script, "--version", @version, "--ref", @source_ref] ++ args,
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
    {_, exit_code} = System.cmd("git", ["--git-dir", mirror, "show-ref", "--verify", "--quiet", "refs/tags/#{tag}"])
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
