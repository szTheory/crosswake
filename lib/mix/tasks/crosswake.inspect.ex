defmodule Mix.Tasks.Crosswake.Inspect do
  use Mix.Task

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Formatter
  alias Crosswake.OperatorInspection.JSONFormatter

  @shortdoc "Inspect route-level Crosswake operator readiness"

  @moduledoc """
  Emits a route-authoritative Crosswake operator inspection document.
  """

  @switches [
    format: :string,
    router: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    document =
      OperatorInspection.inspect(
        route_source: router_module!(opts[:router]),
        cwd: File.cwd!()
      )

    output =
      case opts[:format] do
        nil -> Formatter.render(document)
        "human" -> Formatter.render(document)
        "json" -> JSONFormatter.render(document)
        other -> Mix.raise("unsupported format: #{inspect(other)}")
      end

    Mix.shell().info(output)
  end

  defp router_module!(nil) do
    Mix.raise("pass --router Elixir.YourAppWeb.Router so inspect can compile Crosswake policy")
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
