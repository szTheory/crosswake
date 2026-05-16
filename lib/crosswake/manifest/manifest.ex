defmodule Crosswake.Manifest do
  @moduledoc """
  Canonical Phase 2 manifest compiler.
  """

  alias Crosswake.Manifest.Builder
  alias Crosswake.Manifest.Serializer
  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Validator
  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic

  @type result ::
          {:ok, %{manifest: Types.Root.t(), warnings: [term()]}}
          | {:error, Diagnostic.t()}

  @spec compile(Compiler.route_source(), keyword()) :: result()
  def compile(source, opts \\ []) do
    case Compiler.compile(source, opts) do
      {:ok, %{routes: routes, warnings: warnings}} ->
        managed_routes = managed_routes(source)
        manifest = Builder.build(routes, managed_routes, opts)
        errors = Validator.validate(manifest)

        case errors do
          [] ->
            {:ok, %{manifest: manifest, warnings: warnings}}

          _ ->
            {:error,
             Diagnostic.new(module: source_module(source), errors: errors, warnings: warnings)}
        end

      {:error, diagnostic} ->
        {:error, diagnostic}
    end
  end

  @spec write(String.t(), Types.Root.t()) :: {:ok, Serializer.action()}
  def write(path, %Types.Root{} = manifest), do: Serializer.write(path, manifest)

  @spec render(Types.Root.t()) :: String.t()
  def render(%Types.Root{} = manifest), do: Serializer.render(manifest)

  defp managed_routes(source) do
    source
    |> routes_from_source()
    |> Enum.filter(fn route ->
      route
      |> Map.get(:metadata, %{})
      |> Map.has_key?(:crosswake)
    end)
  end

  defp routes_from_source(source) when is_atom(source), do: source.__routes__()
  defp routes_from_source(source) when is_list(source), do: source

  defp source_module(source) when is_atom(source), do: source
  defp source_module(_source), do: nil
end
