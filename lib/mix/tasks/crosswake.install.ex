defmodule Mix.Tasks.Crosswake.Install do
  use Mix.Task

  alias Crosswake.Install.Manifest
  alias Crosswake.Install.Patcher

  @shortdoc "Additively installs Crosswake into a Phoenix host"

  @moduledoc """
  Bootstraps a Phoenix host for Crosswake with explicit markers, a host-owned policy
  module, and a machine-readable install manifest.

  ## Patch what is canonical, print what is not (D-41)

  The installer patches the router and, when it can find one, the endpoint's static
  plug block that serves the library-owned bridge hook. Both are mechanical and
  identical across hosts.

  It PRINTS — never rewrites — the layout's module import, the socket constructor's
  hooks map, and the hook element. Those are host-authored: the import path depends on
  whether the host bundles JavaScript at all, and rewriting somebody's `LiveSocket`
  constructor under them is not an additive install.
  """

  @switches [
    target: :string,
    router: :string,
    endpoint: :string,
    web_module: :string,
    policy_module: :string,
    manifest_path: :string
  ]

  @impl Mix.Task
  def run(args) do
    Mix.shell().info("Crosswake installer: additive, idempotent, and marker-driven.")

    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    target = Path.expand(opts[:target] || File.cwd!())
    router_path = Path.expand(opts[:router] || infer_router_path!(target), target)
    web_module = opts[:web_module] || infer_web_module!(router_path)
    policy_module = opts[:policy_module] || "#{web_module}.Crosswake.Policy"
    policy_path = policy_path(target, router_path)

    manifest_path =
      Path.expand(opts[:manifest_path] || "priv/crosswake/install_manifest.json", target)

    {:ok, router_result} = Patcher.patch_router(router_path, policy_module)

    {policy_action, _policy_contents} =
      ensure_policy_module(policy_path, policy_module, router_path)

    endpoint_path = opts[:endpoint] && Path.expand(opts[:endpoint], target)
    {endpoint_summary, endpoint_files} = patch_endpoint(endpoint_path || infer_endpoint_path(target), target)

    {:ok, manifest_action} =
      Manifest.write(manifest_path, %{
        crosswake_version: Mix.Project.config()[:version] || "dev",
        router_path: Path.relative_to(router_path, target),
        web_module: web_module,
        policy_module: policy_module,
        files: %{
          created_or_reused:
            [
              Path.relative_to(router_path, target),
              Path.relative_to(policy_path, target),
              Path.relative_to(manifest_path, target)
            ] ++ endpoint_files
        },
        markers: Patcher.marker_lines()
      })

    Mix.shell().info("""
    Crosswake install complete for #{Path.basename(target)}
      router: #{Path.relative_to(router_path, target)} (#{format_router_actions(router_result.actions)})
      policy module: #{Path.relative_to(policy_path, target)} (#{policy_action})
      endpoint: #{endpoint_summary}
      install manifest: #{Path.relative_to(manifest_path, target)} (#{manifest_action})

    #{layout_wiring_notice()}
    """)
  end

  # Patch what is canonical (D-41). A host without a resolvable endpoint is NOT an
  # install failure — the block is four lines an adopter can place by hand, and
  # failing an additive installer over it would be worse than saying so.
  defp patch_endpoint(nil, _target) do
    {"not found (place the static plug block from `mix crosswake.gen.bridge_hook` by hand)", []}
  end

  defp patch_endpoint(endpoint_path, target) do
    case Patcher.patch_endpoint(endpoint_path) do
      {:ok, result} ->
        {"#{Path.relative_to(endpoint_path, target)} (#{format_router_actions(result.actions)})",
         [Path.relative_to(endpoint_path, target)]}

      {:error, reason} ->
        {"#{Path.relative_to(endpoint_path, target)} (skipped — #{reason})", []}
    end
  end

  defp infer_endpoint_path(target) do
    case Path.wildcard(Path.join([target, "lib", "*_web", "endpoint.ex"])) do
      [endpoint_path | _rest] -> endpoint_path
      [] -> nil
    end
  end

  # PRINT what is not canonical (D-41). Printed on every run, including a fully
  # idempotent second run: the layout wiring is the half the installer cannot verify,
  # and a socket that never attached raises a named error on the FIRST push — a
  # brand-new install-time failure surface every adopter hits exactly once.
  defp layout_wiring_notice do
    [import_line, hooks_map_line, hook_element] = Patcher.layout_wiring_lines()

    """
    Two things the installer will not write for you (they are host-authored):

      1. Import the bridge hook and register it in your socket's hooks map:

             #{import_line}
             #{hooks_map_line}

      2. Put ONE hook element on the page (client events broadcast to every mounted
         hook, so a second element posts every request to the shell twice):

             #{hook_element}

    And one thing that is neither: `Crosswake.Bridge.push/3` raises
    Crosswake.Bridge.NotMountedError on a socket that never called
    `Crosswake.Bridge.attach/1` (or used `on_mount: Crosswake.Bridge`). Crosswake
    never guesses a route id. Attach in mount/3 before you push.

    Confirm all of it with: mix crosswake.doctor
    """
  end

  defp infer_router_path!(target) do
    case Path.wildcard(Path.join([target, "lib", "*_web", "router.ex"])) do
      [router_path] ->
        router_path

      [] ->
        Mix.raise("could not find lib/*_web/router.ex under #{target}")

      paths ->
        Mix.raise(
          "found multiple router files, pass --router explicitly: #{Enum.join(paths, ", ")}"
        )
    end
  end

  defp infer_web_module!(router_path) do
    router_path
    |> Path.dirname()
    |> Path.basename()
    |> Macro.camelize()
  end

  defp policy_path(target, router_path) do
    router_dir = Path.dirname(router_path)
    Path.join([target, Path.relative_to(router_dir, target), "crosswake", "policy.ex"])
  end

  defp ensure_policy_module(path, policy_module, router_path) do
    File.mkdir_p!(Path.dirname(path))
    contents = policy_module_template(policy_module, router_path)

    case File.read(path) do
      {:ok, existing} ->
        {:reused, existing}

      {:error, :enoent} ->
        File.write!(path, contents)
        {:created, contents}

      {:error, reason} ->
        Mix.raise("could not write policy module #{path}: #{:file.format_error(reason)}")
    end
  end

  defp policy_module_template(policy_module, router_path) do
    module_template_path =
      Application.app_dir(:crosswake, "priv/templates/crosswake/policy_module.ex")

    router_module = router_module_from_path(router_path)

    EEx.eval_file(module_template_path,
      assigns: [policy_module: policy_module, router_module: router_module]
    )
  end

  defp router_module_from_path(router_path) do
    router_path
    |> Path.dirname()
    |> Path.basename()
    |> Kernel.<>(".Router")
    |> then(&Macro.camelize(&1))
  end

  defp format_router_actions(actions) do
    actions
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(", ")
  end
end
