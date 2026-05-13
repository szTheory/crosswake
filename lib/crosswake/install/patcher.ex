defmodule Crosswake.Install.Patcher do
  @moduledoc """
  Applies explicit, idempotent Crosswake install patches to host-owned files.
  """

  @marker_start "# crosswake:install:start"
  @marker_end "# crosswake:install:end"

  @type patch_result :: %{
          router_file: String.t(),
          changed?: boolean(),
          actions: [atom()]
        }

  @spec patch_router(String.t(), String.t()) :: {:ok, patch_result()} | {:error, String.t()}
  def patch_router(router_path, policy_module) do
    case File.read(router_path) do
      {:ok, contents} ->
        with {:ok, patched_contents, actions} <- ensure_install_block(contents, policy_module) do
          changed? = patched_contents != contents

          if changed? do
            File.write!(router_path, patched_contents)
          end

          {:ok, %{router_file: router_path, changed?: changed?, actions: actions}}
        end

      {:error, reason} ->
        {:error, "could not read router file #{router_path}: #{:file.format_error(reason)}"}
    end
  end

  @spec marker_lines() :: [String.t()]
  def marker_lines do
    [@marker_start, @marker_end]
  end

  defp ensure_install_block(contents, policy_module) do
    cond do
      String.contains?(contents, @marker_start) and String.contains?(contents, @marker_end) ->
        {:ok, contents, [:marker_reused]}

      String.contains?(contents, "import Phoenix.LiveView.Router") ->
        patched =
          Regex.replace(
            ~r/^(\s*)import Phoenix\.LiveView\.Router(?:,.*)?$/m,
            contents,
            install_block("\\1", policy_module),
            global: false
          )

        {:ok, patched, [:marker_inserted, :live_view_import_patched]}

      regex_match = Regex.run(~r/^(\s*)use\s+.+:router\s*$/m, contents) ->
        indentation = List.last(regex_match)

        patched =
          Regex.replace(
            ~r/^(\s*use\s+.+:router\s*)$/m,
            contents,
            "\\1\n" <> install_block(indentation, policy_module),
            global: false
          )

        {:ok, patched, [:marker_inserted, :crosswake_import_added]}

      regex_match = Regex.run(~r/^(\s*)use\s+Phoenix\.Router.*$/m, contents) ->
        indentation = List.last(regex_match)

        patched =
          Regex.replace(
            ~r/^(\s*use\s+Phoenix\.Router.*)$/m,
            contents,
            "\\1\n" <> install_block(indentation, policy_module),
            global: false
          )

        {:ok, patched, [:marker_inserted, :crosswake_import_added]}

      true ->
        {:error,
         "could not find a Phoenix router declaration to patch; add the Crosswake imports manually"}
    end
  end

  defp install_block(indentation, policy_module) do
    [
      "#{indentation}#{@marker_start}",
      "#{indentation}import Phoenix.LiveView.Router, except: [live: 2, live: 3, live: 4]",
      "#{indentation}import Crosswake.Router",
      "#{indentation}@crosswake_policy_module #{policy_module}",
      "#{indentation}#{@marker_end}"
    ]
    |> Enum.join("\n")
  end
end
