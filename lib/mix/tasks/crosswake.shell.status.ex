defmodule Mix.Tasks.Crosswake.Shell.Status do
  use Mix.Task

  @shortdoc "Report whether generated native shells are up to date (exit 0/2/1)"

  @moduledoc """
  Read-only staleness check for generated Crosswake native shells.

  Locates `.crosswake/shell.json` manifests written by `mix crosswake.gen.shell`,
  compares the stamped `template_version` against the live current epoch, and
  reports a calm prose summary.

  ## Usage

      mix crosswake.shell.status
      mix crosswake.shell.status --target PATH
      mix crosswake.shell.status --format json

  ## Exit Codes

  | Code | Meaning |
  |------|---------|
  | 0    | All found shells are up-to-date, OR no `.crosswake/shell.json` found at all (not-a-shell) |
  | 2    | At least one shell is behind — regeneration recommended |
  | 1    | Error — bad or unreadable manifest (use `mix crosswake.gen.shell` to regenerate) |

  The not-a-shell path exits 0 so that CI in projects that have not adopted `gen.shell`
  is never broken by adding this check to a pipeline.

  ## Manifest Locations Probed (no `--target`)

  Without `--target`, the task probes three locations relative to the current working directory:

    - `native/ios/crosswake_shell/.crosswake/shell.json`
    - `native/android/crosswake_shell/.crosswake/shell.json`
    - `.crosswake/shell.json` (generic — for `--target` runs and single-platform directories)

  ## Options

    * `--target PATH` — check only `PATH/.crosswake/shell.json`
    * `--format json` — emit a machine-readable JSON payload

  """

  @switches [target: :string, format: :string]

  @platform_roots [
    {"ios", "native/ios/crosswake_shell"},
    {"android", "native/android/crosswake_shell"}
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("[crosswake] shell.status: invalid options: #{inspect(invalid)}")
    end

    format = Keyword.get(opts, :format, "human")

    unless format in ["human", "json"] do
      Mix.raise("[crosswake] shell.status: unsupported format: #{inspect(format)}")
    end

    current_version = Mix.Tasks.Crosswake.Gen.Shell.template_version()
    cwd = File.cwd!()

    platform_results =
      case opts[:target] do
        nil ->
          # Probe per-platform roots + generic cwd manifest
          platform_probes =
            Enum.map(@platform_roots, fn {platform, rel_root} ->
              manifest_path = Path.join([cwd, rel_root, ".crosswake", "shell.json"])
              {platform, check_manifest(manifest_path, current_version)}
            end)

          # Also probe generic cwd manifest (written by --target runs, or test helpers)
          generic_path = Path.join([cwd, ".crosswake", "shell.json"])

          generic_result = check_manifest(generic_path, current_version)

          case generic_result do
            :not_found ->
              # No generic manifest — return only the platform probes
              platform_probes

            _ ->
              # Generic manifest found — include it under a "generic" key
              # (merges into overall verdict alongside any platform manifests found)
              found_platform_results =
                Enum.reject(platform_probes, fn {_p, r} -> r == :not_found end)

              [{"generic", generic_result} | found_platform_results]
          end

        target_path ->
          # --target: check a single directory
          manifest_path =
            target_path
            |> Path.expand()
            |> Path.join(".crosswake/shell.json")

          platform = detect_platform_from_path(target_path)
          [{platform, check_manifest(manifest_path, current_version)}]
      end

    # Determine the overall status from per-platform results
    overall = overall_status(platform_results)

    case format do
      "json" -> emit_json(platform_results, overall, current_version)
      _ -> emit_human(platform_results, overall, current_version)
    end

    # Exit wiring (D-12)
    case overall do
      :up_to_date -> :ok
      :not_a_shell -> :ok
      {:behind, _} -> exit({:shutdown, 2})
      {:error, msg} -> Mix.raise("[crosswake] shell.status: #{msg}")
    end
  end

  # ---------------------------------------------------------------------------
  # Manifest checking
  # ---------------------------------------------------------------------------

  defp check_manifest(path, current_version) do
    case File.read(path) do
      {:error, :enoent} ->
        :not_found

      {:error, reason} ->
        {:error, "could not read #{path}: #{reason}"}

      {:ok, content} ->
        case Jason.decode(content) do
          {:error, _} ->
            {:error, "malformed JSON in #{path}"}

          {:ok, manifest} ->
            case Map.fetch(manifest, "template_version") do
              :error ->
                {:error, "missing required key `template_version` in #{path}"}

              {:ok, stamped} when not is_integer(stamped) ->
                {:error, "`template_version` must be an integer in #{path}"}

              {:ok, stamped} ->
                if stamped >= current_version do
                  {:up_to_date, stamped}
                else
                  {:behind, stamped}
                end
            end
        end
    end
  end

  # ---------------------------------------------------------------------------
  # Overall status aggregation
  # ---------------------------------------------------------------------------

  defp overall_status(platform_results) do
    verdicts = Enum.map(platform_results, fn {_platform, result} -> result end)

    cond do
      Enum.any?(verdicts, fn
        {:error, _} -> true
        _ -> false
      end) ->
        first_error =
          Enum.find_value(verdicts, fn
            {:error, msg} -> msg
            _ -> nil
          end)

        {:error, first_error}

      Enum.all?(verdicts, &(&1 == :not_found)) ->
        :not_a_shell

      Enum.any?(verdicts, fn
        {:behind, _} -> true
        _ -> false
      end) ->
        max_behind =
          Enum.map(verdicts, fn
            {:behind, stamped} -> stamped
            _ -> nil
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.min()

        {:behind, max_behind}

      true ->
        :up_to_date
    end
  end

  # ---------------------------------------------------------------------------
  # Human-readable output
  # ---------------------------------------------------------------------------

  defp emit_human(platform_results, overall, current_version) do
    found_results = Enum.reject(platform_results, fn {_p, r} -> r == :not_found end)

    case overall do
      :not_a_shell ->
        Mix.shell().info(
          "[crosswake] no .crosswake/shell.json found — nothing to check."
        )

      :up_to_date ->
        Mix.shell().info("[crosswake] generated shells are up to date.")

      {:behind, _} ->
        Enum.each(found_results, fn {platform, result} ->
          case result do
            {:behind, stamped} ->
              behind_count = current_version - stamped

              Mix.shell().info(
                "[crosswake] #{platform}: #{behind_count} template #{pluralize(behind_count, "version")} behind" <>
                  " (stamped #{stamped} → current #{current_version})."
              )

            {:up_to_date, _} ->
              Mix.shell().info("[crosswake] #{platform}: up to date.")

            _ ->
              :ok
          end
        end)

        Mix.shell().info("[crosswake] run `mix crosswake.gen.shell` to regenerate.")

      {:error, msg} ->
        Mix.shell().error("[crosswake] shell.status error: #{msg}")
    end
  end

  # ---------------------------------------------------------------------------
  # JSON output
  # ---------------------------------------------------------------------------

  defp emit_json(platform_results, overall, current_version) do
    platforms_map =
      platform_results
      |> Enum.reject(fn {_p, r} -> r == :not_found end)
      |> Map.new(fn {platform, result} ->
        entry =
          case result do
            {:up_to_date, stamped} ->
              %{
                status: "up_to_date",
                stamped_version: stamped,
                current_version: current_version,
                versions_behind: 0,
                highest_severity: nil
              }

            {:behind, stamped} ->
              %{
                status: "behind",
                stamped_version: stamped,
                current_version: current_version,
                versions_behind: current_version - stamped,
                highest_severity: "rebuild_required"
              }

            {:error, msg} ->
              %{
                status: "error",
                stamped_version: nil,
                current_version: current_version,
                versions_behind: nil,
                highest_severity: nil,
                error: msg
              }
          end

        {platform, entry}
      end)

    overall_status_str =
      case overall do
        :up_to_date -> "up_to_date"
        :not_a_shell -> "not_a_shell"
        {:behind, _} -> "behind"
        {:error, _} -> "error"
      end

    payload = %{
      status: overall_status_str,
      current_version: current_version,
      platforms: platforms_map
    }

    Mix.shell().info(Jason.encode!(payload, pretty: true))
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp pluralize(1, word), do: word
  defp pluralize(_, word), do: word <> "s"

  defp detect_platform_from_path(path) do
    cond do
      String.contains?(path, "ios") -> "ios"
      String.contains?(path, "android") -> "android"
      true -> "target"
    end
  end
end
