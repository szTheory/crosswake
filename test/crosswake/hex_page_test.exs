defmodule Crosswake.HexPageTest do
  @moduledoc """
  Automated verification of the Phase 30 ("hex page polish") deliverables.

  Replaces the manual conversational UAT with a hermetic, deterministic test
  that requires zero human steps. Three concerns, mapping 1:1 to the original
  UAT checkpoints:

    1. README + guide markdown links are hex-safe (relative only to files
       actually shipped in the package; everything else must be an absolute URL).
    2. The HexDocs sidebar grouping config (`groups_for_modules` /
       `groups_for_extras` / `extras`) is well-formed and points at real
       modules and files.
    3. The hex package `:files` allowlist ships the right files and none of the
       banned internal directories (mirrors `script/verify_hex_tarball.sh` at
       the config layer, without a build).

  No network, no build, no provider SDK — safe to run on every `mix test`.
  """
  use ExUnit.Case, async: true

  @root File.cwd!()

  defp config, do: Mix.Project.config()

  # Top-level entries shipped in the hex package, e.g. ["lib", "guides", ...].
  defp shipped_files, do: config()[:package][:files]

  # A repo-relative path is "shipped" if it equals, or lives under, an allowlist entry.
  defp shipped?(rel_path) do
    Enum.any?(shipped_files(), fn entry ->
      rel_path == entry or String.starts_with?(rel_path, entry <> "/")
    end)
  end

  # Strip fenced code blocks (``` ... ```) so code samples don't register as links.
  defp strip_code_fences(content) do
    content
    |> String.split("\n")
    |> Enum.reduce({[], false}, fn line, {kept, in_fence?} ->
      if String.starts_with?(String.trim_leading(line), "```") do
        {kept, not in_fence?}
      else
        if in_fence?, do: {kept, in_fence?}, else: {[line | kept], in_fence?}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  @link_regex ~r/\[[^\]]*\]\(([^)]+)\)/

  # Extract relative link targets from a markdown file, skipping anchors and
  # absolute/external URLs. Returns repo-relative target paths (anchors stripped).
  defp relative_link_targets(md_rel_path) do
    base_dir = Path.dirname(md_rel_path)

    (Path.join(@root, md_rel_path) |> File.read!() |> strip_code_fences())
    |> then(&Regex.scan(@link_regex, &1))
    |> Enum.map(fn [_full, url] -> url |> String.split(~r/\s+/, parts: 2) |> hd() end)
    |> Enum.reject(fn url ->
      url == "" or String.starts_with?(url, "#") or
        String.starts_with?(url, "http://") or String.starts_with?(url, "https://") or
        String.starts_with?(url, "mailto:") or String.contains?(url, "://")
    end)
    |> Enum.map(fn url -> url |> String.split("#") |> hd() end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn target ->
      abs = Path.expand(target, Path.join(@root, base_dir))
      {target, Path.relative_to(abs, @root), abs}
    end)
  end

  defp markdown_files do
    ["README.md" | Path.wildcard("guides/*.md")]
  end

  describe "README + guide link hygiene (UAT 1)" do
    test "every relative markdown link points at a file shipped in the hex package" do
      violations =
        for md <- markdown_files(),
            {target, rel, abs} <- relative_link_targets(md),
            reason = link_violation(target, rel, abs),
            reason != nil do
          "#{md}: [..](#{target}) — #{reason}"
        end

      assert violations == [],
             "Hex-unsafe markdown links found (relative links must point at " <>
               "package-shipped files; link to anything else as an absolute " <>
               "GitHub URL):\n  " <> Enum.join(violations, "\n  ")
    end
  end

  defp link_violation(target, rel, abs) do
    cond do
      # Absolute filesystem path (e.g. a leaked /Users/... local path). Never a
      # valid HexDocs link, regardless of whether it happens to exist on the
      # machine running the test — checked first so the result is deterministic
      # across local and CI environments.
      String.starts_with?(target, "/") ->
        "absolute filesystem path '#{target}' (not a valid HexDocs link)"

      not File.exists?(abs) ->
        "target does not exist on disk"

      not shipped?(rel) ->
        "relative link to non-package path '#{rel}' (404s on HexDocs)"

      true ->
        nil
    end
  end

  describe "HexDocs sidebar grouping config (UAT 2)" do
    test "groups_for_modules defines the expected groups and references real modules" do
      gfm = config()[:docs][:groups_for_modules]

      for group <- [:Policy, :Bridge, :Manifest, :Capabilities] do
        assert Keyword.has_key?(gfm, group),
               "groups_for_modules is missing the :#{group} group"
      end

      for {_group, spec} <- gfm, is_list(spec), mod <- spec do
        assert Code.ensure_loaded?(mod),
               "groups_for_modules references #{inspect(mod)}, which does not exist"
      end
    end

    test "groups_for_extras defines the expected groups" do
      gfe = config()[:docs][:groups_for_extras]

      for group <- [:Setup, :Capabilities] do
        assert Keyword.has_key?(gfe, group),
               "groups_for_extras is missing the :#{group} group"
      end
    end

    test "every extras entry resolves to a file on disk" do
      for entry <- config()[:docs][:extras] do
        path = if is_binary(entry), do: entry, else: elem(entry, 0) |> to_string()

        assert File.exists?(Path.join(@root, path)),
               "docs extras references '#{path}', which is missing on disk"
      end
    end

    test "no guide file is orphaned from the docs extras list" do
      referenced =
        config()[:docs][:extras]
        |> Enum.map(fn entry -> if is_binary(entry), do: entry, else: elem(entry, 0) |> to_string() end)
        |> MapSet.new()

      orphans = Enum.reject(Path.wildcard("guides/*.md"), &MapSet.member?(referenced, &1))

      assert orphans == [],
             "Guides exist on disk but are not listed in docs `:extras` " <>
               "(they will not appear in HexDocs): #{inspect(orphans)}"
    end
  end

  describe "hex package file allowlist (UAT 3 & 4)" do
    test "package ships the expected files" do
      files = shipped_files()

      for expected <- ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides) do
        assert expected in files,
               "package :files is missing expected entry '#{expected}'"
      end
    end

    test "package excludes banned internal paths" do
      files = shipped_files()

      for banned <- ~w(examples test script .planning prompts native .github AGENTS.md) do
        refute banned in files,
               "package :files must not include banned internal path '#{banned}'"
      end
    end

    test "package metadata required for hex publish is present" do
      package = config()[:package]

      assert package[:name] == "crosswake"
      assert is_list(package[:licenses]) and package[:licenses] != []
      assert is_map(package[:links]) and map_size(package[:links]) > 0
      assert is_binary(config()[:description]) and config()[:description] != ""
    end
  end
end
