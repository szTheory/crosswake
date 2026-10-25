defmodule Mix.Tasks.Crosswake.Inspect do
  use Mix.Task

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Formatter
  alias Crosswake.OperatorInspection.JSONFormatter
  alias Crosswake.Shell.IOSHostConfig

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
        nil -> with_host_origin(Formatter.render(document))
        "human" -> with_host_origin(Formatter.render(document))
        "json" -> JSONFormatter.render(document)
        other -> Mix.raise("unsupported format: #{inspect(other)}")
      end

    Mix.shell().info(output)
  end

  # Human output only (D-14): name the declared host origin, canonical form only (D-15).
  defp with_host_origin(rendered) do
    case Application.get_env(:crosswake, :ios_host) do
      nil ->
        rendered

      declaration ->
        case IOSHostConfig.normalize(declaration) do
          {:ok, %IOSHostConfig{origin_mode: :local_loopback, origin: origin}} ->
            host_origin_line(
              rendered,
              "host origin: #{origin} (local loopback mode, Simulator only, not production-ready)"
            )

          {:ok, %IOSHostConfig{origin: origin}} ->
            host_origin_line(rendered, "host origin: #{origin}")

          {:error, _reason} ->
            rendered
        end
    end
  end

  defp host_origin_line(rendered, line), do: String.trim_trailing(rendered, "\n") <> "\n" <> line

  defp router_module!(nil) do
    Mix.raise("pass --router Elixir.YourAppWeb.Router so inspect can compile Crosswake policy")
  end

  defp router_module!(name) when is_binary(name) do
    module =
      try do
        String.to_existing_atom(name)
      rescue
        ArgumentError -> Mix.raise("router module #{name} is not available")
      end

    if Code.ensure_loaded?(module) do
      module
    else
      Mix.raise("router module #{name} is not available")
    end
  end
end
