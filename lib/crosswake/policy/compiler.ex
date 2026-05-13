defmodule Crosswake.Policy.Compiler do
  @moduledoc """
  Compiles Crosswake-managed router metadata into normalized route policy.
  """

  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Validator

  @type route_source :: module() | [map()]
  @type compile_error :: %{
          message: String.t(),
          hint: String.t() | nil,
          key: atom() | nil,
          path: String.t() | nil,
          helper: String.t() | nil,
          verb: atom() | nil,
          route_id: String.t() | nil,
          file: String.t() | nil,
          line: pos_integer() | nil
        }

  @type result ::
          {:ok, %{routes: [Route.t()], warnings: [term()]}}
          | {:error, %{errors: [compile_error()], warnings: [term()]}}

  @spec compile(route_source()) :: result()
  def compile(source) do
    routes = routes_from_source(source)

    {managed_routes, _unmanaged_routes} =
      Enum.split_with(routes, fn route ->
        route
        |> route_metadata()
        |> Map.has_key?(:crosswake)
      end)

    {compiled_routes, errors} =
      Enum.reduce(managed_routes, {[], []}, fn route, {compiled, compile_errors} ->
        case normalize_route(route) do
          {:ok, compiled_route} -> {[compiled_route | compiled], compile_errors}
          {:error, error} -> {compiled, [error | compile_errors]}
        end
      end)

    compiled_routes = Enum.reverse(compiled_routes)

    errors =
      errors
      |> Enum.reverse()
      |> Kernel.++(duplicate_id_errors(compiled_routes, managed_routes))
      |> Kernel.++(Validator.validate(compiled_routes, managed_routes))

    case errors do
      [] -> {:ok, %{routes: compiled_routes, warnings: []}}
      _errors -> {:error, %{errors: errors, warnings: []}}
    end
  end

  defp routes_from_source(source) when is_atom(source), do: source.__routes__()
  defp routes_from_source(source) when is_list(source), do: source

  defp normalize_route(route) do
    crosswake_options = route |> route_metadata() |> Map.fetch!(:crosswake)

    case Route.new(crosswake_options) do
      {:ok, compiled_route} ->
        {:ok, compiled_route}

      {:error, error} ->
        {:error,
         error_details(route,
           key: validation_key(Exception.message(error)),
           message: validation_message(error),
           hint: validation_hint(error)
         )}
    end
  end

  defp duplicate_id_errors(compiled_routes, managed_routes) do
    compiled_routes
    |> Enum.with_index()
    |> Enum.group_by(fn {route, _index} -> route.id end)
    |> Enum.flat_map(fn
      {_id, [_single]} ->
        []

      {id, duplicates} ->
        duplicates
        |> Enum.map(fn {_route, index} ->
          managed_route = Enum.at(managed_routes, index)

          error_details(managed_route,
            key: :id,
            route_id: id,
            message: "duplicate id #{inspect(id)} across Crosswake-managed routes",
            hint: "give each Crosswake-managed route a unique :id"
          )
        end)
    end)
  end

  defp validation_message(error) do
    message = Exception.message(error)

    cond do
      String.contains?(message, "required option :runtime") ->
        "missing required :runtime declaration"

      String.contains?(message, "required option :id") ->
        "missing required :id declaration"

      true ->
        message
    end
  end

  defp validation_hint(error) do
    message = Exception.message(error)

    cond do
      String.contains?(message, "required option :runtime") ->
        "add runtime: :live_view | :offline_island | :native_screen to the route policy"

      String.contains?(message, "required option :id") ->
        "add a unique :id to the route policy"

      String.contains?(message, "runtime :adapter") ->
        "use runtime: :live_view | :offline_island | :native_screen; :adapter stays reserved for future extension"

      String.contains?(message, "invalid value for :offline") ->
        "use offline: :unavailable | :cached_read_only | :local_first"

      true ->
        nil
    end
  end

  defp validation_key(message) do
    cond do
      String.contains?(message, ":runtime") -> :runtime
      String.contains?(message, ":offline") -> :offline
      String.contains?(message, ":id") -> :id
      true -> nil
    end
  end

  defp error_details(route, attrs) do
    route_id =
      attrs[:route_id] ||
        route_metadata(route)
        |> Map.get(:crosswake, [])
        |> Keyword.get(:id)
        |> normalize_identifier()

    source = Map.get(route, :source, %{})

    %{
      key: attrs[:key],
      route_id: route_id,
      message: attrs[:message],
      hint: attrs[:hint],
      path: Map.get(route, :path),
      helper: Map.get(route, :helper),
      verb: Map.get(route, :verb),
      file: Map.get(source, :file),
      line: Map.get(source, :line)
    }
  end

  defp route_metadata(route) do
    Map.get(route, :metadata, %{})
  end

  defp normalize_identifier(nil), do: nil
  defp normalize_identifier(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_identifier(value), do: value
end
