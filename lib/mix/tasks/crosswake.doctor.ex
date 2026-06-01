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
        route_source: router_module!(opts[:router]),
        install_manifest_path: opts[:install_manifest],
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
