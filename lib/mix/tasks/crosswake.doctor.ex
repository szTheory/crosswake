defmodule Mix.Tasks.Crosswake.Doctor do
  use Mix.Task

  alias Crosswake.Doctor
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter

  @shortdoc "Diagnose Crosswake install, policy, manifest, and support truth"

  @moduledoc """
  Runs host-truth-first diagnostics over installer state, route-policy compilation,
  manifest validity, and support-matrix consistency.
  """

  @switches [
    format: :string,
    router: :string,
    install_manifest: :string,
    native_checks: :boolean,
    check_publish: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    report =
      Doctor.run(
        route_source: router_module!(opts[:router]),
        install_manifest_path: opts[:install_manifest],
        check_native_tools?: opts[:native_checks],
        check_publish?: opts[:check_publish],
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

  defp router_module!(nil) do
    Mix.raise("pass --router Elixir.YourAppWeb.Router so doctor can compile Crosswake policy")
  end

  defp router_module!(name) when is_binary(name) do
    module = String.to_atom(name)

    if Code.ensure_loaded?(module) do
      module
    else
      Mix.raise("router module #{name} is not available")
    end
  end
end
