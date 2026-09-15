defmodule Crosswake.Proof.Phase168VersionTruthTest do
  @moduledoc """
  Proves `script/check_release_version_truth.exs` detects the defect class behind
  Phase 168 gap 3: a `.release-please-manifest.json` left BEHIND the newest
  published tag after a post-publication rollback.

  That state is what re-armed Release Please to propose an already-live `0.2.1`
  (PR #158). The guard must catch it deterministically from fixtures, not only
  from whatever the repository happens to look like today.
  """

  use ExUnit.Case, async: true

  @script "script/check_release_version_truth.exs"

  @components %{
    "." => "hex-v",
    "packages/crosswake-shell-core-ios" => "ios-core-v",
    "packages/crosswake-shell-core-android" => "android-core-v"
  }

  defp tmp!(name) do
    dir = Path.join(System.tmp_dir!(), "cw-p168-vt-#{name}-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit_rm(dir)
    dir
  end

  defp on_exit_rm(dir), do: ExUnit.Callbacks.on_exit(fn -> File.rm_rf(dir) end)

  defp write_manifest!(dir, map) do
    path = Path.join(dir, "manifest.json")
    File.write!(path, Jason.encode!(map))
    path
  end

  defp write_tags!(dir, tags) do
    path = Path.join(dir, "tags.txt")
    File.write!(path, Enum.join(tags, "\n") <> "\n")
    path
  end

  defp run(args) do
    System.cmd("elixir", [@script | args], stderr_to_stdout: true, cd: File.cwd!())
  end

  defp all_at(version) do
    Map.new(@components, fn {key, _prefix} -> {key, version} end)
  end

  defp tags_at(version) do
    Enum.map(@components, fn {_key, prefix} -> "#{prefix}#{version}" end)
  end

  describe "manifest behind published tags" do
    test "FAILs with exit 1 and names component, declared, newest, and one next action" do
      dir = tmp!("behind")
      manifest = write_manifest!(dir, all_at("0.2.0"))
      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 1, "expected FAIL exit 1, got #{code}\n#{out}"
      assert out =~ "FAIL"
      assert out =~ "0.2.0"
      assert out =~ "0.2.1"
      assert out =~ "."
      assert out =~ ~r/next action/i
    end

    test "FAILs when only one of the three components is behind" do
      dir = tmp!("one-behind")

      manifest =
        write_manifest!(
          dir,
          all_at("0.2.1") |> Map.put("packages/crosswake-shell-core-ios", "0.2.0")
        )

      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 1, "expected FAIL exit 1, got #{code}\n#{out}"
      assert out =~ "packages/crosswake-shell-core-ios"
    end
  end

  describe "manifest equal to or ahead of published tags" do
    test "equal is OK with exit 0" do
      dir = tmp!("equal")
      manifest = write_manifest!(dir, all_at("0.2.1"))
      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 0, "expected OK exit 0, got #{code}\n#{out}"
      assert out =~ "OK"
    end

    test "ahead is OK with exit 0 — the normal pre-release state" do
      dir = tmp!("ahead")
      manifest = write_manifest!(dir, all_at("0.3.0"))
      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 0, "expected OK exit 0 for ahead, got #{code}\n#{out}"
    end
  end

  describe "BLOCKED is never collapsed into OK" do
    test "no matching tag for a component is BLOCKED with exit 2" do
      dir = tmp!("no-tag")
      manifest = write_manifest!(dir, all_at("0.2.1"))
      tags = write_tags!(dir, ["hex-v0.2.1", "ios-core-v0.2.1"])

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 2, "expected BLOCKED exit 2, got #{code}\n#{out}"
      assert out =~ "BLOCKED"
      assert out =~ "packages/crosswake-shell-core-android"
    end

    test "unreadable manifest is BLOCKED with exit 2" do
      dir = tmp!("no-manifest")
      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", Path.join(dir, "absent.json"), "--tags-file", tags])

      assert code == 2, "expected BLOCKED exit 2, got #{code}\n#{out}"
      assert out =~ "BLOCKED"
    end

    test "missing manifest key is BLOCKED with exit 2" do
      dir = tmp!("missing-key")
      manifest = write_manifest!(dir, Map.delete(all_at("0.2.1"), "."))
      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 2, "expected BLOCKED exit 2, got #{code}\n#{out}"
      assert out =~ "BLOCKED"
    end

    test "unparsable declared version is BLOCKED with exit 2" do
      dir = tmp!("bad-version")
      manifest = write_manifest!(dir, all_at("not-a-version"))
      tags = write_tags!(dir, tags_at("0.2.1"))

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 2, "expected BLOCKED exit 2, got #{code}\n#{out}"
      assert out =~ "BLOCKED"
    end
  end

  describe "tag selection" do
    test "non-conforming tag names are ignored, neither failing nor becoming newest" do
      dir = tmp!("junk-tags")
      manifest = write_manifest!(dir, all_at("0.2.1"))

      tags =
        write_tags!(dir, tags_at("0.2.1") ++ ["hex-vNOPE", "hex-v", "random", "hex-v9.9.9-junk~"])

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 0, "junk tags must not change the verdict, got #{code}\n#{out}"
    end

    test "newest is semantic, not lexicographic — 0.10.0 beats 0.9.0" do
      dir = tmp!("semver")
      manifest = write_manifest!(dir, all_at("0.9.0"))

      tags =
        write_tags!(
          dir,
          Enum.flat_map(@components, fn {_k, p} -> ["#{p}0.9.0", "#{p}0.10.0"] end)
        )

      {out, code} = run(["--manifest", manifest, "--tags-file", tags])

      assert code == 1, "0.9.0 declared vs 0.10.0 published must FAIL, got #{code}\n#{out}"
      assert out =~ "0.10.0"
    end
  end

  describe "against the real repository" do
    test "exits 0 when release tags are visible, or BLOCKED with a stated reason when not" do
      {out, code} = run([])

      tags_visible? =
        case System.cmd("git", ["tag", "--list", "hex-v*"], stderr_to_stdout: true) do
          {listing, 0} -> String.trim(listing) != ""
          _ -> false
        end

      if tags_visible? do
        assert code == 0,
               "release tags are visible, so the restored repository must pass; got #{code}\n#{out}"

        assert out =~ "OK"
      else
        assert code == 2,
               "no release tags visible, so the guard must report BLOCKED, not OK; got #{code}\n#{out}"

        assert out =~ "BLOCKED"
      end
    end

    test "guard mutates nothing" do
      before = File.read!(".release-please-manifest.json")
      {_out, _code} = run([])
      assert File.read!(".release-please-manifest.json") == before
    end
  end
end
