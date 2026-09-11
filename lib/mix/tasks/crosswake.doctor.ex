defmodule Mix.Tasks.Crosswake.Doctor do
  use Mix.Task

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter

  @shortdoc "Diagnose Crosswake install, policy, manifest, and support truth"
  @requirements ["app.config"]

  @moduledoc """
  Runs host-truth-first diagnostics over installer state, route-policy compilation,
  manifest validity, and support-matrix consistency.
  """

  @switches [
    format: :string,
    router: :string,
    install_manifest: :string,
    native_targets: :string,
    native_checks: :boolean,
    check_publish: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    args = normalize_args(args)
    {check_publish?, args} = pop_flag(args, "--check-publish")
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
    {check_publish_from_invalid?, invalid} = pop_invalid_flag(invalid, "--check-publish")
    check_publish? = check_publish? or check_publish_from_invalid?

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    report =
      Doctor.run(
        route_source: router_module!(opts[:router], opts[:install_manifest]),
        install_manifest_path: opts[:install_manifest],
        native_targets: native_targets!(opts[:native_targets]),
        check_native_tools?: opts[:native_checks],
        check_publish?: check_publish? or opts[:check_publish],
        cwd: File.cwd!()
      )

    output =
      case opts[:format] do
        nil -> Formatter.render(report)
        "human" -> Formatter.render(report)
        "json" -> JSONFormatter.render(report)
        other -> Mix.raise("unsupported format: #{inspect(other)}")
      end

    Mix.shell().info(output)

    if report.status == :error do
      Mix.raise("Crosswake doctor found blocking issues")
    end
  end

  defp pop_flag(args, flag) do
    {matches, rest} = Enum.split_with(args, &(&1 == flag))
    {matches != [], rest}
  end

  defp pop_invalid_flag(invalid, flag) do
    {matches, rest} =
      Enum.split_with(invalid, fn
        {candidate, _value} -> to_string(candidate) == flag
        candidate -> to_string(candidate) == flag
      end)

    {matches != [], rest}
  end

  defp normalize_args(args) do
    Enum.flat_map(args, fn
      {flag, nil} -> [to_string(flag)]
      {flag, value} when is_binary(value) -> [to_string(flag), value]
      arg when is_binary(arg) -> [arg]
    end)
  end

  defp router_module!(nil, install_manifest_path) do
    path = Path.expand(install_manifest_path || "priv/crosswake/install_manifest.json")

    with {:ok, contents} <- File.read(path),
         {:ok, manifest} <- Jason.decode(contents),
         {:ok, module} <- router_from_install_manifest(manifest) do
      validate_router_module!(module, inspect(module))
    else
      _error ->
        Mix.raise(
          "could not discover the router from #{path}; run mix crosswake.install or pass --router Elixir.YourAppWeb.Router"
        )
    end
  end

  defp router_module!(name, _install_manifest_path) when is_binary(name) do
    module = module_from_name(name)
    validate_router_module!(module, name)
  end

  defp validate_router_module!(module, display_name) do
    unless ensure_router_loaded?(module) do
      Mix.raise("router module #{display_name} is not available after app.config and compile")
    end

    unless phoenix_router?(module) do
      Mix.raise(
        "router module #{display_name} loaded but is not a Phoenix router (__routes__/0 missing)"
      )
    end

    module
  end

  defp router_from_install_manifest(%{"router_module" => name}) when is_binary(name) do
    {:ok, module_from_name(name)}
  end

  defp router_from_install_manifest(%{"policy_module" => name}) when is_binary(name) do
    policy_module = module_from_name(name)

    if ensure_module_loaded?(policy_module) and function_exported?(policy_module, :router, 0) do
      case policy_module.router() do
        module when is_atom(module) -> {:ok, module}
        _other -> :error
      end
    else
      :error
    end
  end

  defp router_from_install_manifest(_manifest), do: :error

  defp module_from_name("Elixir." <> _ = name), do: String.to_atom(name)

  defp module_from_name(name) do
    name
    |> String.split(".", trim: true)
    |> Module.concat()
  end

  defp ensure_router_loaded?(module) do
    router_loaded?(module) || compile_and_reload_router?(module)
  end

  defp ensure_module_loaded?(module) do
    module_loaded?(module) || compile_and_reload_module?(module)
  end

  defp module_loaded?(module), do: Code.ensure_loaded?(module)

  defp compile_and_reload_module?(module) do
    Mix.Task.reenable("compile")
    Mix.Task.run("compile")
    Mix.Task.reenable("loadpaths")
    Mix.Task.run("loadpaths")
    module_loaded?(module)
  rescue
    Mix.Error -> false
  end

  defp compile_and_reload_router?(module) do
    Mix.Task.reenable("compile")
    Mix.Task.run("compile")
    Mix.Task.reenable("loadpaths")
    Mix.Task.run("loadpaths")
    router_loaded?(module)
  rescue
    Mix.Error -> false
  end

  defp router_loaded?(module) do
    Code.ensure_loaded?(module)
  end

  defp phoenix_router?(module) do
    function_exported?(module, :__routes__, 0)
  end

  defp native_targets!(nil), do: :auto
  defp native_targets!("auto"), do: :auto
  defp native_targets!("none"), do: []
  defp native_targets!("ios"), do: [:ios]
  defp native_targets!("android"), do: [:android]
  defp native_targets!("all"), do: [:ios, :android]

  defp native_targets!(other) do
    Mix.raise(
      "unsupported --native-targets value #{inspect(other)}; use auto, none, ios, android, or all"
    )
  end
end
