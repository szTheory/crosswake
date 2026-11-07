defmodule Crosswake.ReleaseCandidate.MirrorReleaseTagTest do
  # Network-free fixtures for script/check_ios_mirror_release_tag.sh (Phase 199 SC3).
  # Each failure reason has its own test asserting the exit status and the exact verdict and
  # reason tokens on the last line. The real published mirror is exercised by hand and recorded
  # in the phase evidence, never from this suite.
  use ExUnit.Case, async: true

  @script Path.expand("../../../script/check_ios_mirror_release_tag.sh", __DIR__)
  @version "0.2.11"
  @package_path "packages/crosswake-shell-core-ios"

  @git_env [
    {"GIT_CONFIG_GLOBAL", "/dev/null"},
    {"GIT_CONFIG_NOSYSTEM", "1"},
    {"GIT_TERMINAL_PROMPT", "0"},
    {"GIT_AUTHOR_NAME", "Fixture"},
    {"GIT_AUTHOR_EMAIL", "fixture@example.invalid"},
    {"GIT_COMMITTER_NAME", "Fixture"},
    {"GIT_COMMITTER_EMAIL", "fixture@example.invalid"}
  ]

  @package_files [
    {"Package.swift", "// swift-tools-version: 5.9\nimport PackageDescription\n"},
    {"Sources/CrosswakeShellCore/Core.swift", "public enum Core {}\n"}
  ]

  test "1 PASS: the mirror tag holds the released tree and is the newest tag" do
    fx = fixture()
    {output, status} = run(fx)

    assert status == 0

    captures =
      Regex.run(
        ~r/^mirror-tag: version 0\.2\.11 source_tag ios-core-v0\.2\.11 source_tree ([0-9a-f]{12}) mirror_tag v0\.2\.11 mirror_commit ([0-9a-f]{12}) mirror_tree ([0-9a-f]{12}) newest v0\.2\.11 verdict=PASS$/,
        last_line(output),
        capture: :all_but_first
      )

    assert is_list(captures)
    [source_tree, mirror_commit, mirror_tree] = captures
    assert byte_size(source_tree) == 12
    assert byte_size(mirror_commit) == 12
    assert byte_size(mirror_tree) == 12
    assert source_tree == mirror_tree
    assert output =~ "mirror-tag: remote #{fx.mirror}\n"
    assert verdict(output) == "verdict=PASS"
  end

  test "2 source_tag_missing: no ios-core-v tag in the release repository" do
    fx = fixture(ios_tag: false)
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=source_tag_missing"
  end

  test "3 linked_tag_mismatch: hex-v and ios-core-v name different commits" do
    fx = fixture(hex_tag: :other_commit)
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=linked_tag_mismatch"
  end

  test "4 manifest_version_mismatch: the iOS manifest entry is not the released version" do
    fx = fixture(manifest_ios: "0.2.10")
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=manifest_version_mismatch"
  end

  test "5 mirror_tag_missing: the mirror has no v tag for the version" do
    fx = fixture()
    git!(fx.mirror, ["tag", "-d", "v#{@version}"])
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=mirror_tag_missing"
  end

  test "6 tree_mismatch: one byte differs between the mirror and the released package" do
    fx = fixture(mirror_mutation: :one_byte)
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=tree_mismatch"
  end

  test "7 newer_mirror_tag: the mirror already carries a newer patch version" do
    fx = fixture()
    commit = git!(fx.mirror, ["rev-parse", "refs/tags/v#{@version}^{commit}"])
    git!(fx.mirror, ["tag", "v0.2.12", commit])
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=newer_mirror_tag"
    assert last_line(output) =~ " newest v0.2.12 verdict=FAIL reason=newer_mirror_tag"
  end

  test "8 mirror_unreachable: an unreachable mirror exits 3 UNVERIFIED, never 0 or 1" do
    fx = fixture()
    missing = Path.join(fx.root, "no-such-mirror.git")
    {output, status} = run(fx, @version, [{"CROSSWAKE_MIRROR_TAG_REMOTE", missing}])

    assert status == 3
    assert verdict(output) == "verdict=UNVERIFIED reason=mirror_unreachable"
    assert output =~ "attempt 3/3"
  end

  test "9 usage: a malformed or missing version exits 2" do
    fx = fixture()

    for args <- [["--version", "0.2"], ["--version", "1.2.3-rc1"], ["--version", "x.y.z"], []] do
      {output, status} = run_args(fx, args)
      assert status == 2, "args #{inspect(args)} exited #{status}"
      assert verdict(output) == "verdict=ERROR reason=usage"
    end
  end

  test "10 source_tree_missing: the released tag has no iOS package directory" do
    fx = fixture(package: false)
    {output, status} = run(fx)

    assert status == 1
    assert verdict(output) == "verdict=FAIL reason=source_tree_missing"
  end

  test "11 mirror_fetch_failed: a listed tag whose objects cannot be fetched exits 3" do
    fx = fixture()
    commit = git!(fx.mirror, ["rev-parse", "refs/tags/v#{@version}^{commit}"])
    bogus = String.duplicate("1", 40)
    refute commit == bogus

    # A ref that names an object the mirror does not have: ls-remote still lists it, fetch fails.
    # `git clone --bare` packs the tags, so rewrite that one line of packed-refs.
    packed = Path.join(fx.mirror, "packed-refs")
    original = File.read!(packed)

    rewritten =
      String.replace(
        original,
        commit <> " refs/tags/v#{@version}",
        bogus <> " refs/tags/v#{@version}"
      )

    refute rewritten == original
    File.write!(packed, rewritten)
    {output, status} = run(fx)

    assert status == 3
    assert verdict(output) == "verdict=UNVERIFIED reason=mirror_fetch_failed"
  end

  # ---- fixtures -------------------------------------------------------------------------

  # Builds a release repository (package directory, manifest, linked tags) and a bare mirror
  # whose v<version> commit holds a copy of that package directory at its root.
  defp fixture(opts \\ []) do
    root =
      Path.join(System.tmp_dir!(), "crosswake-mirror-tag-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf(root) end)

    release = Path.join(root, "release")
    File.mkdir_p!(release)
    git!(release, ["init", "-q"])

    if Keyword.get(opts, :package, true) do
      write_files(Path.join(release, @package_path), @package_files)
    else
      File.write!(Path.join(release, "README.md"), "no package here\n")
    end

    manifest_ios = Keyword.get(opts, :manifest_ios, @version)

    File.write!(
      Path.join(release, ".release-please-manifest.json"),
      ~s({\n  ".": "#{@version}",\n  "#{@package_path}": "#{manifest_ios}",\n  "packages/crosswake_threadline": "0.1.0"\n}\n)
    )

    git!(release, ["add", "-A"])
    git!(release, ["commit", "-q", "-m", "release commit"])

    if Keyword.get(opts, :ios_tag, true), do: git!(release, ["tag", "ios-core-v#{@version}"])

    case Keyword.get(opts, :hex_tag, :same_commit) do
      :same_commit ->
        git!(release, ["tag", "hex-v#{@version}"])

      :other_commit ->
        File.write!(Path.join(release, "NOTES.md"), "a later commit\n")
        git!(release, ["add", "-A"])
        git!(release, ["commit", "-q", "-m", "later commit"])
        git!(release, ["tag", "hex-v#{@version}"])
    end

    work = Path.join(root, "mirror_work")
    File.mkdir_p!(work)
    git!(work, ["init", "-q"])
    write_files(work, mirror_files(Keyword.get(opts, :mirror_mutation)))
    git!(work, ["add", "-A"])
    git!(work, ["commit", "-q", "-m", "split commit"])
    git!(work, ["tag", "v#{@version}"])
    git!(root, ["clone", "-q", "--bare", work, "mirror.git"])

    %{root: root, release: release, mirror: Path.join(root, "mirror.git")}
  end

  defp mirror_files(nil), do: @package_files

  defp mirror_files(:one_byte) do
    Enum.map(@package_files, fn
      {"Sources/CrosswakeShellCore/Core.swift", body} ->
        {"Sources/CrosswakeShellCore/Core.swift", body <> " "}

      other ->
        other
    end)
  end

  defp write_files(dir, files) do
    for {relative, body} <- files do
      path = Path.join(dir, relative)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, body)
    end
  end

  defp git!(dir, args) do
    {out, 0} =
      System.cmd(
        "git",
        [
          "-c",
          "commit.gpgsign=false",
          "-c",
          "tag.gpgsign=false",
          "-c",
          "init.defaultBranch=main" | args
        ],
        cd: dir,
        env: @git_env,
        stderr_to_stdout: true
      )

    String.trim(out)
  end

  defp run(fx, version \\ @version, extra_env \\ []) do
    run_args(fx, ["--version", version], extra_env)
  end

  defp run_args(fx, args, extra_env \\ []) do
    # Later entries win, so the per-test overrides come last.
    env =
      [
        {"CROSSWAKE_MIRROR_TAG_REMOTE", fx.mirror},
        {"CROSSWAKE_MIRROR_TAG_RELEASE_REPO", fx.release},
        {"CROSSWAKE_MIRROR_TAG_RETRY_SLEEP", "0"}
      ] ++ @git_env ++ extra_env

    System.cmd("bash", [@script | args], env: env, stderr_to_stdout: true)
  end

  defp last_line(output) do
    output |> String.trim_trailing() |> String.split("\n") |> List.last()
  end

  # The trailing `verdict=... reason=...` tokens of the last line.
  defp verdict(output) do
    line = last_line(output)

    case Regex.run(~r/(verdict=\S+(?: reason=\S+)?)$/, line, capture: :all_but_first) do
      [tokens] -> tokens
      nil -> "no verdict on last line: #{line}"
    end
  end
end
