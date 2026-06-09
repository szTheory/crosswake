defmodule Crosswake.Shell.Activation do
  @moduledoc """
  Shared activation contract for native shell entrypoints.
  """

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.Root
  alias Crosswake.Manifest.Types.RouteEntry
  alias Crosswake.Shell.Denial

  defmodule Request do
    @moduledoc false

    @enforce_keys [
      :source,
      :origin,
      :manifest_source,
      :bridge_protocol_version,
      :native_runtime_version,
      :correlation_id
    ]
    defstruct [
      :route_id,
      :url,
      :source,
      :origin,
      :manifest_source,
      :bridge_protocol_version,
      :native_runtime_version,
      :correlation_id,
      thread_id: nil,
      declared_pack_requirements: %{},
      installed_packs: %{},
      capabilities: %{}
    ]

    @type source :: :cold_start | :deep_link | :notification | :in_app_navigation

    @type t :: %__MODULE__{
            route_id: String.t() | nil,
            url: String.t() | nil,
            source: source(),
            origin: String.t(),
            manifest_source: :bundled | :cached | :remote,
            bridge_protocol_version: String.t(),
            native_runtime_version: String.t(),
            correlation_id: String.t(),
            thread_id: String.t() | nil,
            declared_pack_requirements: %{optional(String.t()) => String.t()},
            installed_packs: %{optional(String.t()) => String.t()},
            capabilities: %{optional(String.t()) => String.t()}
          }
  end

  defmodule Decision do
    @moduledoc false

    @enforce_keys [:status, :request, :route_id]
    defstruct [:status, :request, :route_id, :runtime, :route_path, :denial]

    @type t :: %__MODULE__{
            status: :allow | :deny,
            request: Request.t(),
            route_id: String.t(),
            runtime: atom() | nil,
            route_path: String.t() | nil,
            denial: Denial.t() | nil
          }
  end

  @spec new_request(keyword()) :: Request.t()
  def new_request(attrs) when is_list(attrs) do
    url = Keyword.get(attrs, :url)
    origin = Keyword.get_lazy(attrs, :origin, fn -> origin_from_url(url) end)

    struct!(Request, %{
      route_id: Keyword.get(attrs, :route_id),
      url: url,
      source: Keyword.fetch!(attrs, :source),
      origin: origin,
      manifest_source: Keyword.get(attrs, :manifest_source, :bundled),
      bridge_protocol_version: Keyword.fetch!(attrs, :bridge_protocol_version),
      native_runtime_version: Keyword.fetch!(attrs, :native_runtime_version),
      correlation_id: Keyword.fetch!(attrs, :correlation_id),
      thread_id: Keyword.get(attrs, :thread_id),
      declared_pack_requirements: Keyword.get(attrs, :declared_pack_requirements, %{}),
      installed_packs: Keyword.get(attrs, :installed_packs, %{}),
      capabilities: Keyword.get(attrs, :capabilities, %{})
    })
  end

  @spec resolve(Root.t(), Request.t()) :: Decision.t()
  def resolve(%Root{} = manifest, %Request{} = request) do
    route_id = request.route_id || route_id_from_url(manifest, request.url)

    decision =
      RouteGate.evaluate(
        manifest,
        route_id,
        target_from_request(request),
        activation_source: request.source
      )

    case decision.status do
      :allow ->
        route = Map.fetch!(manifest.routes, route_id)
        allow(request, route)

      :deny ->
        denial = Map.get(decision, :denial) || denial_from_gate(manifest, route_id, decision)

        if commerce_corridor_denial?(denial) do
          deny(
            request,
            route_id,
            enrich_commerce_corridor_denial(denial, manifest, route_id)
          )
        else
          deny(request, route_id, denial)
        end
    end
  end

  @spec allow(Request.t(), RouteEntry.t()) :: Decision.t()
  def allow(%Request{} = request, %RouteEntry{} = route) do
    %Decision{
      status: :allow,
      request: request,
      route_id: route.id,
      runtime: route.runtime,
      route_path: route.path,
      denial: nil
    }
  end

  @spec deny(Request.t(), String.t(), Denial.t()) :: Decision.t()
  def deny(%Request{} = request, route_id, %Denial{} = denial) when is_binary(route_id) do
    %Decision{
      status: :deny,
      request: request,
      route_id: route_id,
      runtime: nil,
      route_path: nil,
      denial: denial
    }
  end

  @spec to_map(Request.t() | Decision.t()) :: map()
  def to_map(%Request{} = request) do
    %{
      "route_id" => request.route_id,
      "url" => request.url,
      "source" => Atom.to_string(request.source),
      "origin" => request.origin,
      "manifest_source" => Atom.to_string(request.manifest_source),
      "bridge_protocol_version" => request.bridge_protocol_version,
      "native_runtime_version" => request.native_runtime_version,
      "correlation_id" => request.correlation_id,
      "thread_id" => request.thread_id,
      "declared_pack_requirements" => Types.to_map(request.declared_pack_requirements),
      "installed_packs" => Types.to_map(request.installed_packs),
      "capabilities" => Types.to_map(request.capabilities)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def to_map(%Decision{} = decision) do
    %{
      "status" => Atom.to_string(decision.status),
      "route_id" => decision.route_id,
      "runtime" => decision.runtime && Atom.to_string(decision.runtime),
      "route_path" => decision.route_path,
      "request" => to_map(decision.request),
      "denial" => decision.denial && Denial.to_map(decision.denial)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp target_from_request(%Request{} = request) do
    %Target{
      manifest_schema_version: "1.0.0",
      bridge_protocol_version: request.bridge_protocol_version,
      native_runtime_version: request.native_runtime_version,
      origin: request.origin,
      manifest_source: request.manifest_source,
      capabilities: request.capabilities,
      packs: request.installed_packs
    }
  end

  defp route_id_from_url(_manifest, nil), do: nil

  defp route_id_from_url(%Root{} = manifest, url) do
    path = URI.parse(url).path

    Enum.find_value(manifest.routes, fn {route_id, route} ->
      if route_path_matches?(route.path, path), do: route_id
    end)
  end

  defp origin_from_url(nil), do: Types.default_origin()

  defp origin_from_url(url) do
    uri = URI.parse(url)

    case uri do
      %URI{scheme: scheme, host: host} when is_binary(scheme) and is_binary(host) ->
        scheme <> "://" <> host <> port_suffix(uri)

      _other ->
        Types.default_origin()
    end
  end

  defp denial_from_gate(%Root{} = manifest, route_id, decision) do
    if denial = Map.get(decision, :denial) do
      denial
    else
      if Map.has_key?(manifest.routes, route_id) do
        Denial.new(
          reason: :compatibility_mismatch,
          route_id: route_id,
          message: "Activation denied before runtime boot.",
          details: %{reasons: Map.get(decision, :reasons, [])}
        )
      else
        Denial.new(
          reason: :inactive_route,
          route_id: route_id,
          message: "The requested route is not active in the manifest.",
          hint: "refresh the bundled manifest before opening the route"
        )
      end
    end
  end

  defp commerce_corridor_denial?(%Denial{reason: :commerce_corridor}), do: true
  defp commerce_corridor_denial?(_denial), do: false

  defp enrich_commerce_corridor_denial(%Denial{} = denial, %Root{} = manifest, route_id) do
    route_commerce =
      manifest.routes
      |> Map.get(route_id)
      |> case do
        %RouteEntry{commerce: commerce} -> commerce
        _other -> nil
      end

    details =
      denial.details
      |> maybe_put(:corridor_ref, route_commerce && route_commerce.corridor_ref)
      |> maybe_put(:role, route_commerce && route_commerce.role)
      |> maybe_put(:failing_prerequisite, failing_prerequisite(denial))
      |> maybe_put(:failing_moment, route_commerce && route_commerce.role)

    recovery =
      denial.recovery
      |> Map.put(:fallback, :return_to_phoenix_guidance)
      |> Map.put(:next_step, :declare_corridor_or_disable_commerce_route)
      |> Map.put(:guidance, :return_to_phoenix_guidance)
      |> Map.update(:actions, default_corridor_actions(), fn actions ->
        actions
        |> List.wrap()
        |> Kernel.++(default_corridor_actions())
        |> Enum.uniq()
      end)

    %Denial{denial | details: details, recovery: recovery}
  end

  defp default_corridor_actions do
    [:return_to_phoenix_guidance, :declare_corridor_or_disable_commerce_route]
  end

  defp failing_prerequisite(%Denial{code: "commerce.corridor.undeclared"}),
    do: :declare_corridor_or_disable_commerce_route

  defp failing_prerequisite(%Denial{code: "commerce.corridor.prerequisite_missing"}),
    do: :declare_corridor_or_disable_commerce_route

  defp failing_prerequisite(%Denial{code: "commerce.corridor.runtime_incompatible"}),
    do: :return_to_phoenix_guidance

  defp failing_prerequisite(%Denial{code: "commerce.corridor.policy_blocked"}),
    do: :declare_corridor_or_disable_commerce_route

  defp failing_prerequisite(_denial), do: nil

  defp route_path_matches?(route_path, request_path)
       when is_binary(route_path) and is_binary(request_path) do
    route_segments = path_segments(route_path)
    request_segments = path_segments(request_path)

    length(route_segments) == length(request_segments) and
      Enum.zip(route_segments, request_segments)
      |> Enum.all?(fn {route_segment, request_segment} ->
        String.starts_with?(route_segment, ":") or route_segment == request_segment
      end)
  end

  defp route_path_matches?(_route_path, _request_path), do: false

  defp path_segments(path) do
    path
    |> String.trim("/")
    |> String.split("/", trim: true)
  end

  defp port_suffix(%URI{port: nil}), do: ""
  defp port_suffix(%URI{scheme: "https", port: 443}), do: ""
  defp port_suffix(%URI{scheme: "http", port: 80}), do: ""
  defp port_suffix(%URI{port: port}), do: ":#{port}"

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
