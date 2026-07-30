defmodule Crosswake.Install.Patcher do
  @moduledoc """
  Applies explicit, idempotent Crosswake install patches to host-owned files.

  ## Patch what is canonical, print what is not (D-41)

  The endpoint's static plug block is mechanical and identical across every host, so
  it is PATCHED inside the same markers the router patch uses. The layout's module
  import and the socket constructor's hooks map are not mechanical — the import path
  depends on whether the host bundles JavaScript at all, and the `LiveSocket`
  constructor is host-authored — so those are PRINTED for the adopter to place, never
  rewritten under them.
  """

  @marker_start "# crosswake:install:start"
  @marker_end "# crosswake:install:end"

  @hook_name "CrosswakeBridge"
  @static_at "/crosswake"
  @hook_asset "crosswake.esm.js"

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

  @doc """
  The LiveView hook name the layout registers and the markup references.
  """
  @spec hook_name() :: String.t()
  def hook_name, do: @hook_name

  @doc """
  The public URL the endpoint's static plug serves the library-owned hook from.
  """
  @spec hook_url() :: String.t()
  def hook_url, do: "#{@static_at}/#{@hook_asset}"

  @doc """
  The canonical endpoint static plug block — the part of the wiring that IS
  mechanical and therefore gets patched (D-41).

  It mirrors the shape of the `:phoenix` and `:phoenix_live_view` blocks a Phoenix
  host already carries, serving the hook from the `:crosswake` application's own
  `priv/static` directory at the `/crosswake` prefix.
  """
  @spec endpoint_static_plug_block(String.t()) :: String.t()
  def endpoint_static_plug_block(indentation \\ "  ") do
    [
      "#{indentation}#{@marker_start}",
      "#{indentation}plug(Plug.Static,",
      "#{indentation}  at: \"#{@static_at}\",",
      "#{indentation}  from: :crosswake,",
      "#{indentation}  gzip: false,",
      "#{indentation}  only: ~w(#{@hook_asset})",
      "#{indentation})",
      "#{indentation}#{@marker_end}"
    ]
    |> Enum.join("\n")
  end

  @doc """
  The layout fragments Crosswake PRINTS rather than patches (D-41): the module-script
  import, the hooks-map entry on the socket constructor, and the single hook element.
  """
  @spec layout_wiring_lines() :: [String.t()]
  def layout_wiring_lines do
    [
      "import {#{@hook_name}} from \"#{hook_url()}\";",
      "const liveSocket = new LiveSocket(\"/live\", Socket, {params, hooks: {#{@hook_name}}});",
      "<div id=\"crosswake-bridge\" phx-hook=\"#{@hook_name}\" phx-update=\"ignore\"></div>"
    ]
  end

  @doc """
  Adds the canonical Crosswake static plug block to a host endpoint, inside the same
  idempotent markers `patch_router/2` uses.

  Returns `{:ok, result}` when the endpoint was patched or already carried the
  markers, and `{:error, reason}` when no endpoint declaration could be found — the
  installer prints that as guidance rather than failing the install, because an
  adopter can always place the block by hand.
  """
  @spec patch_endpoint(String.t()) :: {:ok, patch_result()} | {:error, String.t()}
  def patch_endpoint(endpoint_path) do
    case File.read(endpoint_path) do
      {:ok, contents} ->
        with {:ok, patched_contents, actions} <- ensure_endpoint_block(contents) do
          changed? = patched_contents != contents

          if changed? do
            File.write!(endpoint_path, patched_contents)
          end

          {:ok, %{router_file: endpoint_path, changed?: changed?, actions: actions}}
        end

      {:error, reason} ->
        {:error, "could not read endpoint file #{endpoint_path}: #{:file.format_error(reason)}"}
    end
  end

  defp ensure_endpoint_block(contents) do
    cond do
      String.contains?(contents, @marker_start) and String.contains?(contents, @marker_end) ->
        {:ok, contents, [:marker_reused]}

      regex_match = Regex.run(~r/^(\s*)use\s+Phoenix\.Endpoint.*$/m, contents) ->
        indentation = List.last(regex_match)

        patched =
          Regex.replace(
            ~r/^(\s*use\s+Phoenix\.Endpoint.*)$/m,
            contents,
            "\\1\n\n" <> endpoint_static_plug_block(indentation),
            global: false
          )

        {:ok, patched, [:marker_inserted, :endpoint_static_plug_added]}

      true ->
        {:error,
         "could not find a Phoenix endpoint declaration to patch; add the Crosswake static plug block manually"}
    end
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

        {:ok, patched, [:marker_inserted, :live_view_import_replaced]}

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
      "#{indentation}import Phoenix.Router, except: [get: 3, get: 4, post: 3, post: 4, put: 3, put: 4, patch: 3, patch: 4, delete: 3, delete: 4, options: 3, options: 4, head: 3, head: 4]",
      "#{indentation}import Crosswake.Router",
      "#{indentation}@crosswake_policy_module #{policy_module}",
      "#{indentation}#{@marker_end}"
    ]
    |> Enum.join("\n")
  end
end
