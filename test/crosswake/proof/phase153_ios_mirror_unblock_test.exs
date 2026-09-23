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

  The parity-gate block additionally covers D-16/D-19: the merge-blocking
  `script/check_ios_mirror_parity.sh` invariant (every released
  `refs/tags/ios-core-vX` here implies `refs/tags/vX` on the SwiftPM mirror),
  its one-directional shape, its 2am-maintainer failure microcopy, and the
  T-153-09 guarantee that an unreachable mirror is NEVER reported as a
  missing tag.
  """

  use ExUnit.Case, async: true

  @script "script/verify_ios_mirror_backfill.sh"
  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
  @parity_script "script/check_ios_mirror_parity.sh"
  @parity_workflow ".github/workflows/crosswake-ci.yml"
  @parity_leaf "ios-mirror-parity-proof"
  @version "0.2.0"

  @phase153_ids ~w(
    release.ios.ssh_transport
    release.ios.ordinary_atomic_push
    release.ios.checkout_ref_pinned
    release.workflow.native_rollup_fails_closed
    release.workflow.release_failure_alert_native
    release.ios_mirror.four_modes
    release.partial.exact_ref_recovery
  )

  # --- Tests A/B/C: raw git push semantics against disjoint-history bare fixtures ---

  @tag :phase153_ios_mirror_unblock
  test "atomic + explicit-lease push succeeds across disjoint mirror history (D-08 happy path)" do
    fixture = disjoint_mirror_fixture()
    current_main = fixture.preexisting_sha

    {output, exit_code} =
      atomic_push(
        fixture.release,
        fixture.mirror,
        current_main,
        fixture.split_sha,
        "v#{@version}"
      )

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

  # --- Phase 168 compatibility: the former backfill entry point is now a
  # four-mode adapter whose candidate paths are strictly read-only. ---

  @tag :phase153_ios_mirror_unblock
  test "candidate mode rejects every mutation flag before delegating" do
    {output, exit_code} =
      System.cmd(
        "bash",
        [
          @script,
          "--mode",
          "candidate",
          "--version",
          "0.2.1",
          "--ref",
          String.duplicate("a", 40),
          "--apply"
        ],
        stderr_to_stdout: true
      )

    assert exit_code != 0
    assert output =~ "baseline and candidate modes are read-only"
    assert output =~ "explicit publish or recovery mode"
  end

  # --- decoys: scanner emits the new phase153 ids as :ok (added by task 3) ---

  @tag :phase153_ios_mirror_unblock
  test "scanner reports the phase153 ios_backfill and release-job ids as OK" do
    {output, exit_code} = run_scanner()

    assert exit_code == 0, output

    for check_id <- @phase153_ids do
      assert output =~ "[crosswake] OK: #{check_id}"
    end
  end

  # --- decoys: deliberately-broken release-please.yml fixtures fail the new
  # publish-ios-core / native-release-rollup / release-failure-alert ids ---

  @tag :phase153_ios_mirror_unblock
  test "publish-ios-core checkout without the release tag ref fails checkout_ref_pinned id" do
    workflow =
      real_workflow()
      |> replace_in_job(
        "publish-ios-core",
        "ref: ${{ needs.release-please.outputs.tag_name }}",
        "# ref intentionally omitted by decoy fixture"
      )

    assert_scanner_failure!("release.ios.checkout_ref_pinned", workflow)
  end

  @tag :phase153_ios_mirror_unblock
  test "publish-ios-core cannot switch ordinary publication to recovery" do
    workflow =
      real_workflow()
      |> replace_in_job(
        "publish-ios-core",
        "script/release_candidate/ios_mirror.sh publish",
        "script/release_candidate/ios_mirror.sh recovery"
      )

    assert_scanner_failure!("release.ios.ordinary_atomic_push", workflow)
  end

  @tag :phase153_ios_mirror_unblock
  test "native-release-rollup without the partial-native exit 1 fails native_rollup_fails_closed id" do
    workflow =
      real_workflow()
      |> replace_in_job(
        "native-release-rollup",
        "exit 1",
        "echo 'decoy: partial native release no longer fails closed'"
      )

    assert_scanner_failure!("release.workflow.native_rollup_fails_closed", workflow)
  end

  @tag :phase153_ios_mirror_unblock
  test "release-failure-alert missing native-release-rollup from needs fails release_failure_alert_native id" do
    workflow =
      real_workflow()
      |> replace_in_job(
        "release-failure-alert",
        "      - native-release-rollup\n",
        ""
      )

    assert_scanner_failure!("release.workflow.release_failure_alert_native", workflow)
  end

  # --- Parity gate (D-16, D-19): the merge-blocking mirror-vs-released-tags invariant ---

  @tag :phase153_ios_mirror_unblock
  test "parity holds when every released ios-core tag has a matching mirror tag" do
    fixture = parity_fixture(["0.1.2", "0.2.0"], ["0.1.2", "0.2.0"])

    {output, exit_code} = run_parity(fixture)

    assert exit_code == 0, output
    assert output =~ "[crosswake] OK: release.ios_mirror_parity - "
  end

  @tag :phase153_ios_mirror_unblock
  test "a missing mirror tag fails the gate with 2am-maintainer microcopy (D-19)" do
    fixture = parity_fixture(["0.1.2", "0.2.0"], ["0.1.2"])

    {output, exit_code} = run_parity(fixture)

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: release.ios_mirror_parity - "
    assert output =~ "SwiftPM mirror is missing refs/tags/v0.2.0."
    assert output =~ "released here:  refs/tags/ios-core-v0.2.0"
    assert output =~ "has no refs/tags/v0.2.0"
    assert output =~ "CANNOT RESOLVE. Every iOS adopter of 0.2.0 is broken right now."
    assert output =~ "gh workflow run ios-mirror-backfill.yml -f version=0.2.0"
    assert output =~ "-f release_ref=refs/tags/ios-core-v0.2.0 -f apply=true"
    assert output =~ "This gate stays RED and merges stay BLOCKED until the mirror tag exists."
    # 0.1.2 IS mirrored - it must not be named as broken.
    refute output =~ "missing refs/tags/v0.1.2"
  end

  test "one-time recovery exception ignores only v0.2.3 and leaves every other release blocking" do
    exact = parity_fixture(["0.1.2", "0.2.3"], ["0.1.2"])

    {output, exit_code} =
      run_parity(exact, [{"CROSSWAKE_IOS_PARITY_ALLOW_MISSING_VERSION", "0.2.3"}])

    assert exit_code == 0, output
    assert output =~ "0.2.3 parity is pending the exact protected-main tag-only recovery"

    other_missing = parity_fixture(["0.2.1", "0.2.3"], [])

    {output, exit_code} =
      run_parity(other_missing, [{"CROSSWAKE_IOS_PARITY_ALLOW_MISSING_VERSION", "0.2.3"}])

    assert exit_code == 1, output
    assert output =~ "missing refs/tags/v0.2.1"
    refute output =~ "missing refs/tags/v0.2.3"
  end

  @tag :phase153_ios_mirror_unblock
  test "the invariant is one-directional: extra mirror tags are not a violation" do
    fixture = parity_fixture(["0.1.2", "0.2.0"], ["0.1.2", "0.2.0", "9.9.9"])

    {output, exit_code} = run_parity(fixture)

    assert exit_code == 0, output
    refute output =~ "9.9.9"
  end

  @tag :phase153_ios_mirror_unblock
  test "an unreachable mirror retries 3 times and reports unreachability, NEVER a missing tag (T-153-09)" do
    fixture = parity_fixture(["0.2.0"], [])
    unreachable = Path.join(fixture.root, "not-a-repo.git")

    {output, exit_code} =
      run_parity(fixture, [{"CROSSWAKE_IOS_PARITY_MIRROR_REMOTE", unreachable}])

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: release.ios_mirror_parity - "
    assert output =~ "could not reach"
    assert output =~ "after 3 attempts"
    # The whole point of T-153-09: an unknown must never masquerade as a
    # definite negative. No missing-tag language, no adopter-broken claim.
    refute output =~ "is missing refs/tags/"
    refute output =~ "CANNOT RESOLVE"
  end

  @tag :phase153_ios_mirror_unblock
  test "the parity gate keys on released tags, never on the release-please manifest (deadlock trap)" do
    source = File.read!(@parity_script)

    refute source =~ "release-please-manifest"
    assert source =~ "ios-core-v"
    assert source =~ "release.ios_mirror_parity - "
    assert source =~ "CANNOT RESOLVE"
    assert source =~ "set -euo pipefail"
    assert source =~ "core.askPass="
    assert File.stat!(@parity_script).mode |> Bitwise.band(0o111) != 0
  end

  @tag :phase153_ios_mirror_unblock
  test "the parity workflow satisfies the merge-blocking naming and checkout contract" do
    workflow = File.read!(@parity_workflow)
    parity = job_section!(workflow, @parity_leaf)

    # The executable leaf is literal and remains under the single Crosswake CI authority.
    assert workflow =~ "  #{@parity_leaf}:\n"
    assert parity =~ "name: #{@parity_leaf}\n"
    refute parity =~ ~r/name:.*\$\{\{/
    # The LOCAL side enumerates ios-core-v* tags; a shallow clone would not have them.
    assert parity =~ "fetch-depth: 0"
    assert parity =~ "fetch-tags: true"
    # This repo's dominant discipline is an immutable SHA pin plus its reviewed version comment.
    assert parity =~ "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v6.0.2"
    assert parity =~ "./script/check_ios_mirror_parity.sh"

    umbrella = job_section!(workflow, "merge-blocking-crosswake-ci")
    assert umbrella =~ ~r/^      - #{@parity_leaf}$/m
  end

  @tag :phase153_ios_mirror_unblock
  test "required-check discovery returns only the target Crosswake CI context" do
    {output, exit_code} =
      System.cmd("python3", ["script/list_merge_blocking_checks.py"], stderr_to_stdout: true)

    assert exit_code == 0, output
    assert String.split(output, "\n", trim: true) == ["Crosswake CI"]
  end

  defp job_section!(workflow, job_name) do
    pattern = ~r/^  #{Regex.escape(job_name)}:\r?\n(.*?)(?=^  [a-zA-Z0-9_-]+:\r?\n|\z)/ms

    case Regex.run(pattern, workflow, capture: :all_but_first) do
      [section] -> section
      nil -> flunk("missing workflow job #{job_name}")
    end
  end

  defp parity_fixture(local_versions, mirror_versions) do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase153-parity-#{System.unique_integer([:positive])}"
      )

    release = Path.join(root, "release")
    mirror = Path.join(root, "mirror.git")
    File.mkdir_p!(release)
    File.mkdir_p!(mirror)
    on_exit(fn -> File.rm_rf(root) end)

    git!(["init", "-q", release])
    git!(["-C", release, "config", "user.email", "ci@crosswake"])
    git!(["-C", release, "config", "user.name", "Crosswake CI"])
    File.write!(Path.join(release, "README.md"), "parity fixture\n")
    git!(["-C", release, "add", "."])
    git!(["-C", release, "commit", "-q", "-m", "parity fixture"])
    sha = git!(["-C", release, "rev-parse", "HEAD"]) |> String.trim()

    for version <- local_versions do
      git!(["-C", release, "tag", "ios-core-v#{version}", sha])
    end

    git!(["init", "--bare", "-q", mirror])

    for version <- mirror_versions do
      git!(["-C", release, "push", mirror, "#{sha}:refs/tags/v#{version}"])
    end

    %{root: root, release: release, mirror: mirror, sha: sha}
  end

  defp run_parity(fixture, env \\ []) do
    base_env = [
      {"CROSSWAKE_IOS_PARITY_RELEASE_REPO", fixture.release},
      {"CROSSWAKE_IOS_PARITY_MIRROR_REMOTE", fixture.mirror},
      # Test-only seam: keeps the 3-attempt retry proof sub-second.
      {"CROSSWAKE_IOS_PARITY_RETRY_SLEEP", "0"}
    ]

    System.cmd("bash", [@parity_script], stderr_to_stdout: true, env: base_env ++ env)
  end

  defp backfill_fixture do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase153-ios-mirror-#{System.unique_integer([:positive])}"
      )

    release = Path.join(root, "release")
    mirror = Path.join(root, "mirror.git")
    File.mkdir_p!(release)
    on_exit(fn -> File.rm_rf(root) end)

    git!(["init", "-q", release])
    git!(["-C", release, "config", "user.email", "ci@crosswake"])
    git!(["-C", release, "config", "user.name", "Crosswake CI"])
    File.write!(Path.join(release, "Package.swift"), "// swift package\n")
    git!(["-C", release, "add", "."])
    git!(["-C", release, "commit", "-q", "-m", "release fixture"])
    split_sha = git!(["-C", release, "rev-parse", "HEAD"]) |> String.trim()
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
    case System.cmd("git", ["--git-dir", mirror, "show-ref", "--verify", "-s", ref],
           stderr_to_stdout: true
         ) do
      {output, 0} -> String.trim(output)
      {_output, _exit_code} -> nil
    end
  end

  defp run_scanner do
    System.cmd("elixir", [@scanner, @workflow], stderr_to_stdout: true)
  end

  defp real_workflow, do: File.read!(@workflow)

  # Mirrors phase142_release_integrity_test.exs's house decoy-fixture pattern:
  # mutate one job block's text and confirm the scanner's exit code and the
  # specific check id it reports FAIL for. An invariant with no decoy proving
  # it is not vacuous is not trustworthy (D-20).
  defp replace_in_job(workflow, job, pattern, replacement) do
    Regex.replace(
      ~r/(?ms)^  #{Regex.escape(job)}:\n.*?(?=^  [A-Za-z0-9_-]+:\n|\z)/,
      workflow,
      fn block -> String.replace(block, pattern, replacement, global: false) end,
      global: false
    )
  end

  defp assert_scanner_failure!(check_id, workflow) do
    path =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase153-fixture-#{System.unique_integer([:positive])}.yml"
      )

    File.write!(path, workflow)
    on_exit(fn -> File.rm(path) end)

    {output, exit_code} = System.cmd("elixir", [@scanner, path], stderr_to_stdout: true)

    assert exit_code == 1, output
    assert output =~ "[crosswake] FAIL: #{check_id}"
  end

  defp git(args), do: System.cmd("git", args, stderr_to_stdout: true)

  defp git!(args) do
    {output, exit_code} = git(args)
    assert exit_code == 0, output
    output
  end
end
