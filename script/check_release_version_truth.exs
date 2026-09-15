#!/usr/bin/env elixir

# Guards the defect class behind Phase 168 gap 3.
#
# After a failed release merge is rolled back, `.release-please-manifest.json`
# can be left BEHIND a version that is already published and tagged. Release
# Please then re-forms a candidate for that already-live version — which is how
# PR #158 came to propose an already-published 0.2.1, whose merge would have
# tagged over an immutable public tag and republished a live Hex version.
#
# Being AHEAD of the newest tag is the normal pre-release state and is OK.
# Being BEHIND it is the defect. Not being able to tell is BLOCKED, never OK.
#
# Exit codes: 0 OK, 1 FAIL, 2 BLOCKED.
defmodule Crosswake.ReleaseVersionTruth do
  @default_manifest ".release-please-manifest.json"

  # Release Please component -> tag prefix. The linked core trio only:
  # companions version independently (D-15, D-16) and are already covered by
  # script/check_release_as_staleness.sh.
  @components [
    {".", "hex-v"},
    {"packages/crosswake-shell-core-ios", "ios-core-v"},
    {"packages/crosswake-shell-core-android", "android-core-v"}
  ]

  def main(argv) do
    opts = parse(argv)

    with {:ok, manifest} <- read_manifest(opts[:manifest]),
         {:ok, tags} <- read_tags(opts[:tags_file]) do
      results = Enum.map(@components, &evaluate(&1, manifest, tags))
      report(results)
    else
      {:blocked, reason} -> blocked(reason)
    end
  end

  defp parse(argv), do: parse(argv, %{manifest: @default_manifest, tags_file: nil})
  defp parse([], acc), do: acc
  defp parse(["--manifest", v | rest], acc), do: parse(rest, %{acc | manifest: v})
  defp parse(["--tags-file", v | rest], acc), do: parse(rest, %{acc | tags_file: v})
  defp parse([_ | rest], acc), do: parse(rest, acc)

  defp read_manifest(path) do
    case File.read(path) do
      {:ok, body} ->
        decode_manifest(body, path)

      {:error, reason} ->
        {:blocked, "cannot read manifest #{path}: #{:file.format_error(reason)}"}
    end
  end

  defp decode_manifest(body, path) do
    case JSON.decode(body) do
      {:ok, map} when is_map(map) -> {:ok, map}
      _ -> {:blocked, "manifest #{path} is not a JSON object"}
    end
  end

  defp read_tags(nil) do
    case System.cmd("git", ["tag", "--list"], stderr_to_stdout: true) do
      {out, 0} -> {:ok, split_tags(out)}
      {out, code} -> {:blocked, "git tag --list failed (exit #{code}): #{String.trim(out)}"}
    end
  rescue
    e -> {:blocked, "git is unavailable: #{Exception.message(e)}"}
  end

  defp read_tags(path) do
    case File.read(path) do
      {:ok, body} ->
        {:ok, split_tags(body)}

      {:error, reason} ->
        {:blocked, "cannot read tags file #{path}: #{:file.format_error(reason)}"}
    end
  end

  defp split_tags(body) do
    body |> String.split("\n", trim: true) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp evaluate({key, prefix}, manifest, tags) do
    with {:ok, declared_raw} <- fetch_declared(manifest, key),
         {:ok, declared} <- parse_version(declared_raw, key),
         {:ok, newest} <- newest_published(tags, prefix, key) do
      verdict =
        case Version.compare(declared, newest) do
          :lt -> :fail
          _ -> :ok
        end

      %{
        key: key,
        declared: to_string(declared),
        newest: to_string(newest),
        verdict: verdict
      }
    else
      {:blocked, reason} ->
        %{key: key, declared: "?", newest: "?", verdict: :blocked, reason: reason}
    end
  end

  defp fetch_declared(manifest, key) do
    case Map.fetch(manifest, key) do
      {:ok, v} when is_binary(v) -> {:ok, v}
      {:ok, _} -> {:blocked, "manifest key #{key} is not a string"}
      :error -> {:blocked, "manifest has no key #{key}"}
    end
  end

  defp parse_version(raw, key) do
    case Version.parse(raw) do
      {:ok, v} ->
        {:ok, v}

      :error ->
        {:blocked, "declared version #{inspect(raw)} for #{key} is not a semantic version"}
    end
  end

  defp newest_published(tags, prefix, key) do
    published =
      tags
      |> Enum.filter(&String.starts_with?(&1, prefix))
      |> Enum.map(&String.replace_prefix(&1, prefix, ""))
      |> Enum.flat_map(fn raw ->
        case Version.parse(raw) do
          {:ok, v} -> [v]
          :error -> []
        end
      end)

    case published do
      [] -> {:blocked, "no tag matching #{prefix}<semver> is visible for #{key}"}
      versions -> {:ok, Enum.max_by(versions, & &1, Version)}
    end
  end

  defp report(results) do
    Enum.each(results, fn r ->
      case r.verdict do
        :ok ->
          IO.puts(
            "[crosswake] OK: #{r.key} - declared #{r.declared}, newest published #{r.newest}"
          )

        :fail ->
          IO.puts(
            "[crosswake] FAIL: #{r.key} - declared #{r.declared} is BEHIND newest published #{r.newest}"
          )

        :blocked ->
          IO.puts("[crosswake] BLOCKED: #{r.key} - #{r.reason}")
      end
    end)

    cond do
      Enum.any?(results, &(&1.verdict == :fail)) ->
        behind = results |> Enum.filter(&(&1.verdict == :fail)) |> Enum.map(& &1.key)

        IO.puts(
          "[crosswake] summary: FAIL - #{length(behind)} of #{length(results)} components declare a version behind published truth"
        )

        IO.puts(
          "[crosswake] next action: restore declared version truth to the published version in .release-please-manifest.json and its sibling coordinate files, then close any open Release Please pull request proposing that already-published version. Never move a published tag or republish a live package."
        )

        System.halt(1)

      Enum.any?(results, &(&1.verdict == :blocked)) ->
        IO.puts("[crosswake] summary: BLOCKED - published truth could not be established")

        IO.puts(
          "[crosswake] next action: run with full tag history (git fetch --tags, or a checkout with fetch-depth: 0) and a readable .release-please-manifest.json, then re-run. BLOCKED means unknown, not clean."
        )

        System.halt(2)

      true ->
        IO.puts(
          "[crosswake] summary: OK - all #{length(results)} linked core components declare a version at or ahead of published truth"
        )

        System.halt(0)
    end
  end

  defp blocked(reason) do
    IO.puts("[crosswake] BLOCKED: #{reason}")
    IO.puts("[crosswake] summary: BLOCKED - published truth could not be established")

    IO.puts(
      "[crosswake] next action: ensure .release-please-manifest.json is readable and tag history is available, then re-run. BLOCKED means unknown, not clean."
    )

    System.halt(2)
  end
end

Crosswake.ReleaseVersionTruth.main(System.argv())
