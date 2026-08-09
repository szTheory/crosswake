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

  @type patch_action ::
          :marker_reused
          | :marker_stale
          | :marker_inserted
          | :endpoint_static_plug_added
          | :live_view_import_replaced
          | :crosswake_import_added

  @type patch_result :: %{
          router_file: String.t(),
          changed?: boolean(),
          actions: [patch_action()]
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

  @tokens_asset "tokens.css"

  @doc """
  The public URL the endpoint's static plug serves the library's compiled
  `tokens.css` from (Phase 155 D-26). One served copy — hosts never carry their
  own `tokens.css`.
  """
  @spec tokens_url() :: String.t()
  def tokens_url, do: "#{@static_at}/#{@tokens_asset}"

  @doc """
  The canonical endpoint static plug block — the part of the wiring that IS
  mechanical and therefore gets patched (D-41).

  It mirrors the shape of the `:phoenix` and `:phoenix_live_view` blocks a Phoenix
  host already carries, serving the hook AND the library's compiled `tokens.css`
  from the `:crosswake` application's own `priv/static` directory at the
  `/crosswake` prefix (Phase 155 D-26 — one served copy, no host-side duplicate).
  """
  @spec endpoint_static_plug_block(String.t()) :: String.t()
  def endpoint_static_plug_block(indentation \\ "  ") do
    [
      "#{indentation}#{@marker_start}",
      "#{indentation}plug(Plug.Static,",
      "#{indentation}  at: \"#{@static_at}\",",
      "#{indentation}  from: :crosswake,",
      "#{indentation}  gzip: false,",
      # Literal `only: ~w(crosswake.esm.js tokens.css)`, not interpolated — the
      # exact two asset names stay grep-able verbatim on this line, even though
      # @hook_asset/@tokens_asset name the same strings for hook_url/0 and
      # tokens_url/0 above.
      "#{indentation}  only: ~w(crosswake.esm.js tokens.css)",
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

  # Content reconciliation (D-52). Markers existing is not sufficient on its own —
  # a Phase 154 adopter's marker body still reads the pre-155 `only:` list, so the
  # widened tokens.css entry never reaches them unless the CONTENT inside the
  # markers is diffed against the current canonical block.
  #
  # Byte-equal (modulo trailing whitespace) -> the existing reuse action, file
  # unchanged. Different -> a distinct `:marker_stale` action, file STILL
  # unchanged — this reconciler reports, it never rewrites a block that sits
  # inside a file the adopter owns (T-155-13).
  defp ensure_endpoint_block(contents) do
    cond do
      String.contains?(contents, @marker_start) and String.contains?(contents, @marker_end) ->
        case extract_marker_block(contents) do
          {:ok, existing_block, indentation} ->
            canonical_block = endpoint_static_plug_block(indentation)

            if normalize_block(existing_block) == normalize_block(canonical_block) do
              {:ok, contents, [:marker_reused]}
            else
              {:ok, contents, [:marker_stale]}
            end

          :error ->
            # Markers are present but not in the well-formed shape this
            # reconciler can parse (e.g. hand-edited past recognition) —
            # fall back to the historical presence-only behavior rather
            # than raising.
            {:ok, contents, [:marker_reused]}
        end

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

  # Extracts the substring from the marker-start line through the marker-end
  # line (inclusive, so indentation comparison is meaningful) plus the detected
  # leading indentation of the marker-start line.
  defp extract_marker_block(contents) do
    regex =
      ~r/^([ \t]*)#{Regex.escape(@marker_start)}.*?^[ \t]*#{Regex.escape(@marker_end)}[ \t]*$/ms

    case Regex.run(regex, contents) do
      [full_match, indentation] -> {:ok, full_match, indentation}
      nil -> :error
    end
  end

  defp normalize_block(text) do
    text
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.join("\n")
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
