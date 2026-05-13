defmodule Mix.Tasks.Crosswake.Install do
  use Mix.Task

  alias Crosswake.Install.Manifest
  alias Crosswake.Install.Patcher

  @shortdoc "Additively installs Crosswake into a Phoenix host"

  @moduledoc """
  Bootstraps a Phoenix host for Crosswake with explicit markers, a host-owned policy
  module, and a machine-readable install manifest.
  """

  @switches [
    target: :string,
    router: :string,
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

    {:ok, manifest_action} =
      Manifest.write(manifest_path, %{
        crosswake_version: Mix.Project.config()[:version] || "dev",
        router_path: Path.relative_to(router_path, target),
        web_module: web_module,
        policy_module: policy_module,
        files: %{
          created_or_reused: [
            Path.relative_to(router_path, target),
            Path.relative_to(policy_path, target),
            Path.relative_to(manifest_path, target)
          ]
        },
        markers: Patcher.marker_lines()
      })

    Mix.shell().info("""
    Crosswake install complete for #{Path.basename(target)}
      router: #{Path.relative_to(router_path, target)} (#{format_router_actions(router_result.actions)})
      policy module: #{Path.relative_to(policy_path, target)} (#{policy_action})
      install manifest: #{Path.relative_to(manifest_path, target)} (#{manifest_action})
    """)
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
