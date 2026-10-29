defmodule Crosswake.Policy.Compiler do
  @moduledoc """
  Compiles Crosswake-managed router metadata into normalized route policy.
  """

  alias Crosswake.Policy.Diagnostic
  alias Crosswake.Policy.Error
  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Validator
  alias Crosswake.Policy.Warning

  @type route_source :: module() | [map()]
  @type result ::
          {:ok, %{routes: [Route.t()], warnings: [term()]}}
          | {:error, Diagnostic.t()}

  @spec compile(route_source(), keyword()) :: result()
  def compile(source, opts \\ []) do
    routes = routes_from_source(source)
    source_module = source_module(source)
    registry = host_command_registry(source, opts)

    {managed_routes, unmanaged_routes} =
      Enum.split_with(routes, fn route ->
        route
        |> route_metadata()
        |> Map.has_key?(:crosswake)
      end)

    warnings = build_warnings(unmanaged_routes, source_module, opts)

    {compiled_pairs, errors} =
      Enum.reduce(managed_routes, {[], []}, fn route, {compiled, compile_errors} ->
        case normalize_route(route) do
          {:ok, compiled_route} ->
            {[{compiled_route, route} | compiled], compile_errors}

          {:error, error} ->
            {compiled, Enum.reverse(normalization_errors(route, error), compile_errors)}
        end
      end)

    compiled_pairs = Enum.reverse(compiled_pairs)
    {compiled_routes, compiled_sources} = Enum.unzip(compiled_pairs)

    errors =
      errors
      |> Enum.reverse()
      |> Kernel.++(duplicate_id_errors(compiled_pairs))
      |> Kernel.++(Validator.validate(compiled_routes, compiled_sources, host_commands: registry))

    case errors do
      [] ->
        emit_warnings(warnings, opts)
        {:ok, %{routes: compiled_routes, warnings: warnings}}

      _errors ->
        {:error, Diagnostic.new(module: source_module, errors: errors, warnings: [])}
    end
  end

  @doc false
  def host_command_registry(source, opts) do
    if is_atom(source) and not is_nil(source) and Code.ensure_loaded?(source) and
         function_exported?(source, :__crosswake_host_commands__, 0) do
      source.__crosswake_host_commands__()
    else
      Keyword.get(opts, :host_commands, [])
    end
  end

  defp routes_from_source(source) when is_atom(source), do: source.__routes__()
  defp routes_from_source(source) when is_list(source), do: source
  defp source_module(source) when is_atom(source), do: source
  defp source_module(_source), do: nil

  defp build_warnings(unmanaged_routes, source_module, opts) do
    if Keyword.get(opts, :warn_on_unmanaged?, false) and unmanaged_routes != [] do
      paths = Enum.map(unmanaged_routes, &Map.get(&1, :path))
      [Warning.unmanaged_routes(paths, source_module)]
    else
      []
    end
  end

  defp emit_warnings(warnings, opts) do
    if Keyword.get(opts, :emit_warnings?, false) do
      Enum.each(warnings, fn warning ->
        IO.warn(Warning.format(warning))
      end)
    end
  end

  defp normalize_route(route) do
    crosswake_options = route |> route_metadata() |> Map.fetch!(:crosswake)

    Route.new(crosswake_options)
  end

  # NimbleOptions 1.1.1 groups unknown option keys in one real ValidationError.
  # Keep its message but emit one atom-keyed policy diagnostic per option.
  defp normalization_errors(route, %NimbleOptions.ValidationError{key: keys} = error)
       when is_list(keys) and keys != [] do
    Enum.flat_map(keys, &normalization_errors(route, %{error | key: &1}))
  end

  defp normalization_errors(route, %NimbleOptions.ValidationError{} = error) do
    [
      error_details(route,
        key: validation_key(error),
        message: validation_message(error),
        hint: validation_hint(error)
      )
    ]
  end

  defp duplicate_id_errors(compiled_pairs) do
    compiled_pairs
    |> Enum.group_by(fn {route, _source} -> route.id end)
    |> Enum.flat_map(fn
      {_id, [_single]} ->
        []

      {id, duplicates} ->
        duplicates
        |> Enum.map(fn {_route, managed_route} ->
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

      String.contains?(message, "invalid value for :entry") ->
        "use entry: :internal_only | :external"

      String.contains?(message, "commerce declaration requires") ->
        "use commerce: [corridor: :subscription_default, role: :paywall_entry]"

      String.contains?(message, "commerce role") ->
        "use commerce: [corridor: :subscription_default, role: :paywall_entry]"

      true ->
        nil
    end
  end

  defp validation_key(%NimbleOptions.ValidationError{key: key})
       when is_atom(key) and not is_nil(key), do: key

  defp validation_key(%NimbleOptions.ValidationError{}),
    do: raise(ArgumentError, "unsupported structured route validation key")

  defp error_details(route, attrs) do
    route_id =
      attrs[:route_id] ||
        route_metadata(route)
        |> Map.get(:crosswake, [])
        |> Keyword.get(:id)
        |> normalize_identifier()

    source = Map.get(route, :source, %{})

    struct!(Error, %{
      key: attrs[:key],
      route_id: route_id,
      message: attrs[:message],
      hint: attrs[:hint],
      path: Map.get(route, :path),
      helper: Map.get(route, :helper),
      verb: Map.get(route, :verb),
      file: Map.get(source, :file),
      line: Map.get(source, :line)
    })
  end

  defp route_metadata(route) do
    Map.get(route, :metadata, %{})
  end

  defp normalize_identifier(nil), do: nil
  defp normalize_identifier(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_identifier(value), do: value
end
