defmodule Crosswake.Proof.Phase153IosMirrorUnblockTest do
  @moduledoc """
  Hermetic proof for Phase 153's iOS mirror transport fix and lease-safe
  atomic push semantics.

  Covers: SSH transport replacing the checkout-hijackable HTTPS token (D-01,
  D-03, D-04), a real write probe inside verify-only mode so apply=false
  proves WRITE scope rather than anonymous read (D-07), the explicit-lease
  atomic push form that is the ONLY form that works in a never-fetched CI
  checkout (D-13), and the ancestry guard's unknown-object vs
  known-non-ancestor split (D-08).

  Tests A/B/C drive real `git push` against local bare-repo fixtures to prove
  git's own semantics (no app code involved). Tests D/E drive the real
  `script/verify_ios_mirror_backfill.sh` via its existing env-var override
  seams, mirroring `phase145_ios_backfill_script_test.exs`'s fixture harness.
  """

  use ExUnit.Case, async: true

  @script "script/verify_ios_mirror_backfill.sh"
  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
  @version "0.2.0"
  @source_ref "refs/tags/ios-core-v0.2.0"

  @phase153_ids ~w(
    release.ios_backfill.write_probe
    release.ios_backfill.explicit_lease
    release.ios_backfill.ssh_transport
  )

  # --- Tests A/B/C: raw git push semantics against disjoint-history bare fixtures ---

  @tag :phase153_ios_mirror_unblock
  test "atomic + explicit-lease push succeeds across disjoint mirror history (D-08 happy path)" do
    fixture = disjoint_mirror_fixture()
    current_main = fixture.preexisting_sha

    {output, exit_code} =
      atomic_push(fixture.release, fixture.mirror, current_main, fixture.split_sha, "v#{@version}")

    assert exit_code == 0, output
    assert mirror_ref_sha(fixture.mirror, "refs/heads/main") == fixture.split_sha
    assert mirror_ref_sha(fixture.mirror, "refs/tags/v#{@version}") == fixture.split_sha
    assert mirror_ref_sha(fixture.mirror, "refs/tags/v0.1.2") == fixture.preexisting_sha
  end

  @tag :phase153_ios_mirror_unblock
  test "a stale lease fails the WHOLE atomic transaction; no partial apply" do
    fixture = disjoint_mirror_fixture()
    before_main = mirror_ref_sha(fixture.mirror, "refs/heads/main")
    # deliberately wrong <expect> - the split SHA is a real, valid object but
    # is NOT the mirror's actual current main (which is preexisting_sha).
    wrong_lease = fixture.split_sha

    {output, exit_code} =
      atomic_push(fixture.release, fixture.mirror, wrong_lease, fixture.split_sha, "v#{@version}")

    assert exit_code != 0
    assert output =~ "stale info" or output =~ "rejected"
    assert mirror_ref_sha(fixture.mirror, "refs/heads/main") == before_main
    assert mirror_ref_sha(fixture.mirror, "refs/tags/v#{@version}") == nil
  end

  @tag :phase153_ios_mirror_unblock
  test "an existing tag cannot be moved inside the atomic push, even with a correct main lease" do
    fixture = disjoint_mirror_fixture()
    current_main = fixture.preexisting_sha

    {output, exit_code} =
      atomic_push(fixture.release, fixture.mirror, current_main, fixture.split_sha, "v0.1.2")

    assert exit_code != 0
    assert output =~ "already exists" or output =~ "rejected"
    assert mirror_ref_sha(fixture.mirror, "refs/tags/v0.1.2") == fixture.preexisting_sha
    assert mirror_ref_sha(fixture.mirror, "refs/heads/main") == current_main
  end

  # --- Tests D/E: drive the real script via its env seams ---

  @tag :phase153_ios_mirror_unblock
  test "apply=false proves WRITE scope via a real dry-run push probe, not merely anonymous read (D-07)" do
    fixture = backfill_fixture()

    {output, exit_code} = run_script(fixture)

    assert exit_code == 0, output
    assert output =~ "dry-run push to"
    assert output =~ "MIRROR_DEPLOY_KEY has WRITE scope"
    assert output =~ "verification-only mode made no changes"
  end

  @tag :phase153_ios_mirror_unblock
  test "ancestry guard logs an advisory (not fail-closed) when mirror main is an unknown object (D-08)" do
    fixture = backfill_fixture()
    push_foreign_main!(fixture)

    {output, exit_code} = run_script(fixture, ["--apply", "--update-main"])

    assert exit_code == 0, output
    assert output =~ "is not a known object in this repository"
    refute output =~ "mirror main has commits not reachable"
    assert mirror_ref_sha(fixture.mirror, "refs/heads/main") == fixture.split_sha
  end

  @tag :phase153_ios_mirror_unblock
  test "ancestry guard still fails closed when mirror main is known and genuinely not an ancestor (D-08)" do
    fixture = backfill_fixture()
    other_sha = add_commit!(fixture.release, "descendant.txt", "known but not an ancestor\n")
    git!(["-C", fixture.release, "push", fixture.mirror, "#{other_sha}:refs/heads/main"])

    {output, exit_code} = run_script(fixture, ["--apply", "--update-main"])

    assert exit_code != 0
    assert output =~ "mirror main has commits not reachable from expected split SHA"
    assert output =~ "mirror-only commit evidence"
  end

  # --- decoys: scanner emits the new phase153 ids as :ok (added by task 3) ---

  @tag :phase153_ios_mirror_unblock
  test "scanner reports the phase153 ios_backfill ids as OK" do
    {output, exit_code} = run_scanner()

    assert exit_code == 0, output

    for check_id <- @phase153_ids do
      assert output =~ "[crosswake] OK: #{check_id}"
    end
  end

  defp backfill_fixture do
    root = Path.join(System.tmp_dir!(), "crosswake-phase153-ios-mirror-#{System.unique_integer([:positive])}")
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

    %{root: root, release: release, mirror: mirror, split_sha: split_sha}
  end

  # Off-lineage mirror: `main` (and the preexisting v0.1.2 tag) come from a
  # SECOND, independently `git init`'d tree that shares zero history with the
  # release repo - this reproduces D-08's real off-lineage divergence (the
  # mirror was hand-completed via `git subtree split`, not splitsh-lite).
  defp disjoint_mirror_fixture do
    fixture = backfill_fixture()

    legacy = Path.join(fixture.root, "legacy")
    File.mkdir_p!(legacy)
    git!(["init", "-q", legacy])
    git!(["-C", legacy, "config", "user.email", "ci@crosswake"])
    git!(["-C", legacy, "config", "user.name", "Crosswake CI"])
    File.write!(Path.join(legacy, "legacy.txt"), "subtree split v0.1.2, unrelated history\n")
    git!(["-C", legacy, "add", "."])
    git!(["-C", legacy, "commit", "-q", "-m", "legacy v0.1.2"])
    legacy_sha = git!(["-C", legacy, "rev-parse", "HEAD"]) |> String.trim()

    git!(["-C", legacy, "push", fixture.mirror, "#{legacy_sha}:refs/heads/main"])
    git!(["-C", legacy, "push", fixture.mirror, "#{legacy_sha}:refs/tags/v0.1.2"])

    Map.put(fixture, :preexisting_sha, legacy_sha)
  end

  defp push_foreign_main!(fixture) do
    foreign = Path.join(fixture.root, "foreign")
    File.mkdir_p!(foreign)
    git!(["init", "-q", foreign])
    git!(["-C", foreign, "config", "user.email", "ci@crosswake"])
    git!(["-C", foreign, "config", "user.name", "Crosswake CI"])
    File.write!(Path.join(foreign, "foreign.txt"), "unrelated to the release repo\n")
    git!(["-C", foreign, "add", "."])
    git!(["-C", foreign, "commit", "-q", "-m", "foreign, unrelated history"])
    sha = git!(["-C", foreign, "rev-parse", "HEAD"]) |> String.trim()
    git!(["-C", foreign, "push", fixture.mirror, "#{sha}:refs/heads/main"])
    sha
  end

  defp add_commit!(repo, path, contents) do
    File.write!(Path.join(repo, path), contents)
    git!(["-C", repo, "add", path])
    git!(["-C", repo, "commit", "-q", "-m", "extra commit"])
    git!(["-C", repo, "rev-parse", "HEAD"]) |> String.trim()
  end

  # The atomic + explicit-lease command form, copied character-for-character
  # from RESEARCH's empirically-verified recommendation. Driven through
  # `bash -c` (not a plain System.cmd arg list) so the source text literally
  # contains the quoted `--force-with-lease="refs/heads/main:<expect>"` form -
  # a paraphrase here would re-arm the fuse this phase exists to defuse.
  defp atomic_push(release, mirror, lease_sha, split_sha, tag_name) do
    command =
      ~s(git -C #{release} push --atomic #{mirror} --force-with-lease="refs/heads/main:#{lease_sha}" "#{split_sha}:refs/heads/main" "#{split_sha}:refs/tags/#{tag_name}")

    System.cmd("bash", ["-c", command], stderr_to_stdout: true)
  end

  defp mirror_ref_sha(mirror, ref) do
    case System.cmd("git", ["--git-dir", mirror, "show-ref", "--verify", "-s", ref], stderr_to_stdout: true) do
      {output, 0} -> String.trim(output)
      {_output, _exit_code} -> nil
    end
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

  defp run_scanner do
    System.cmd("elixir", [@scanner, @workflow], stderr_to_stdout: true)
  end

  defp git(args), do: System.cmd("git", args, stderr_to_stdout: true)

  defp git!(args) do
    {output, exit_code} = git(args)
    assert exit_code == 0, output
    output
  end
end
