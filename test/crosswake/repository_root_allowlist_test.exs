defmodule Crosswake.RepositoryRootAllowlistTest do
  # HYG-01: the repository root holds only allowlisted files and no tracked path
  # anywhere is a git bundle. Reads the live index relative to the cwd.
  use ExUnit.Case, async: true

  @root_allowlist [
    # container build context filter
    ".dockerignore",
    # mix format configuration
    ".formatter.exs",
    # git ignore rules
    ".gitignore",
    # release-please version manifest
    ".release-please-manifest.json",
    # asdf/mise toolchain pins
    ".tool-versions",
    # agent guide
    "AGENTS.md",
    # release changelog
    "CHANGELOG.md",
    # contributor guide
    "CONTRIBUTING.md",
    # license text
    "LICENSE",
    # project readme
    "README.md",
    # read by test/crosswake/proof/phase69_docs_contract_parity_test.exs
    "gen_manifest.exs",
    # mix project
    "mix.exs",
    # dependency lock
    "mix.lock",
    # node tooling manifest
    "package.json",
    # release-please configuration
    "release-please-config.json"
  ]

  def root_violations(paths, allowlist) do
    paths
    |> Enum.reject(&String.contains?(&1, "/"))
    |> Enum.reject(&(&1 in allowlist))
  end

  def bundle_violations(paths), do: Enum.filter(paths, &String.ends_with?(&1, ".bundle"))

  defp tracked_paths do
    {out, 0} = System.cmd("git", ["ls-files", "-z"])
    String.split(out, <<0>>, trim: true)
  end

  test "pure: allowlisted root files are accepted" do
    assert root_violations(["mix.exs", "README.md"], @root_allowlist) == []
  end

  test "pure: a non-allowlisted root file is flagged, nested files are ignored" do
    assert root_violations(["mix.exs", "scratch.py", "lib/x.py"], @root_allowlist) == [
             "scratch.py"
           ]
  end

  test "pure: bundle paths are flagged anywhere" do
    assert bundle_violations(["lib/a.ex", "x/y.bundle", "z.bundle"]) == ["x/y.bundle", "z.bundle"]
  end

  test "live: root holds only allowlisted files and no bundle is tracked" do
    paths = tracked_paths()
    root = Enum.reject(paths, &String.contains?(&1, "/"))

    assert length(root) >= 10,
           "git ls-files returned #{length(root)} root entries; listing failed?"

    assert root_violations(paths, @root_allowlist) == []
    assert bundle_violations(paths) == []
  end
end
