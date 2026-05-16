defmodule Crosswake.Manifest.Types do
  @moduledoc """
  Typed manifest contract shared by manifest generation, compatibility checks,
  doctor diagnostics, and support-matrix rendering.
  """

  defmodule Root do
    @moduledoc false

    @enforce_keys [
      :manifest_schema_version,
      :crosswake_version,
      :generated_at,
      :host,
      :compatibility,
      :support_matrix,
      :capability_registry,
      :routes
    ]
    defstruct [
      :manifest_schema_version,
      :crosswake_version,
      :generated_at,
      :host,
      :compatibility,
      :support_matrix,
      capability_registry: %{},
      routes: %{}
    ]

    @type t :: %__MODULE__{
            manifest_schema_version: String.t(),
            crosswake_version: String.t(),
            generated_at: String.t(),
            host: Crosswake.Manifest.Types.Host.t(),
            compatibility: Crosswake.Manifest.Types.Compatibility.t(),
            support_matrix: Crosswake.Manifest.Types.SupportMatrix.t(),
            capability_registry: %{
              optional(String.t()) => Crosswake.Manifest.Types.Capability.t()
            },
            routes: %{optional(String.t()) => Crosswake.Manifest.Types.RouteEntry.t()}
          }
  end

  defmodule Host do
    @moduledoc false

    @enforce_keys [:phoenix_version, :live_view_version, :manifest_sources, :origin]
    defstruct [
      :phoenix_version,
      :live_view_version,
      :origin,
      manifest_sources: [:bundled, :cached, :remote]
    ]

    @type manifest_source :: :bundled | :cached | :remote

    @type t :: %__MODULE__{
            phoenix_version: String.t(),
            live_view_version: String.t(),
            manifest_sources: [manifest_source()],
            origin: String.t()
          }
  end

  defmodule Compatibility do
    @moduledoc false

    @enforce_keys [
      :manifest_schema_version,
      :bridge_protocol_version,
      :native_runtime_version,
      :supported_manifest_sources,
      :remote_updates
    ]
    defstruct [
      :manifest_schema_version,
      :bridge_protocol_version,
      :native_runtime_version,
      :remote_updates,
      supported_manifest_sources: [:bundled, :cached, :remote]
    ]

    @type remote_update_mode :: :versioned_replacement | :versioned_companion_data

    @type t :: %__MODULE__{
            manifest_schema_version: String.t(),
            bridge_protocol_version: String.t(),
            native_runtime_version: String.t(),
            supported_manifest_sources: [Crosswake.Manifest.Types.Host.manifest_source()],
            remote_updates: [remote_update_mode()]
          }
  end

  defmodule Capability do
    @moduledoc false

    @enforce_keys [:id, :version]
    defstruct [:id, :version, status: :supported]

    @type status :: :supported | :verification_required | :unsupported

    @type t :: %__MODULE__{
            id: String.t(),
            version: String.t(),
            status: status()
          }
  end

  defmodule RouteEntry do
    @moduledoc false

    @enforce_keys [:id, :path, :runtime]
    defstruct [
      :id,
      :path,
      :runtime,
      :offline,
      :cache_contract,
      :island_contract,
      :security,
      capabilities: [],
      packs: [],
      sync: [],
      allowlisted_origins: []
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            path: String.t(),
            runtime: Crosswake.Policy.Schema.runtime(),
            offline: Crosswake.Policy.Schema.offline(),
            cache_contract: Crosswake.Manifest.Types.CacheContract.t() | nil,
            island_contract: Crosswake.Manifest.Types.IslandContract.t() | nil,
            capabilities: [String.t()],
            packs: [String.t()],
            sync: [String.t()],
            security: Crosswake.Policy.Schema.security() | nil,
            allowlisted_origins: [String.t()]
          }
  end

  defmodule CacheContract do
    @moduledoc false

    @enforce_keys [:id, :staleness, :restrictions]
    defstruct [:id, :staleness, restrictions: []]

    @type staleness :: :best_effort
    @type restriction :: :read_only | :server_authoritative

    @type t :: %__MODULE__{
            id: String.t(),
            staleness: staleness(),
            restrictions: [restriction()]
          }
  end

  defmodule IslandContract do
    @moduledoc false

    @enforce_keys [:id, :storage, :reconciliation, :sync_seam]
    defstruct [:id, :storage, :reconciliation, :sync_seam]

    @type storage :: :sqlite
    @type reconciliation :: :explicit

    @type t :: %__MODULE__{
            id: String.t(),
            storage: storage(),
            reconciliation: reconciliation(),
            sync_seam: String.t()
          }
  end

  defmodule SupportMatrix do
    @moduledoc false

    @enforce_keys [:phoenix, :live_view, :ios, :android, :shells]
    defstruct phoenix: [], live_view: [], ios: [], android: [], shells: []

    @type t :: %__MODULE__{
            phoenix: [Crosswake.Manifest.Types.SupportEntry.t()],
            live_view: [Crosswake.Manifest.Types.SupportEntry.t()],
            ios: [Crosswake.Manifest.Types.SupportEntry.t()],
            android: [Crosswake.Manifest.Types.SupportEntry.t()],
            shells: [Crosswake.Manifest.Types.SupportEntry.t()]
          }
  end

  defmodule SupportEntry do
    @moduledoc false

    @enforce_keys [:target, :version, :status]
    defstruct [:target, :version, :status, :proof, :notes]

    @type t :: %__MODULE__{
            target: String.t(),
            version: String.t(),
            status: Crosswake.Manifest.Types.Capability.status(),
            proof: String.t() | nil,
            notes: String.t() | nil
          }
  end

  @manifest_schema_version "1.0.0"
  @bridge_protocol_version "1.0.0"
  @native_runtime_version "1.0.0"
  @default_origin "https://example.crosswake.invalid"

  @spec new_root(keyword()) :: Root.t()
  def new_root(attrs) when is_list(attrs) do
    struct!(Root, %{
      manifest_schema_version:
        Keyword.get(attrs, :manifest_schema_version, @manifest_schema_version),
      crosswake_version: Keyword.fetch!(attrs, :crosswake_version),
      generated_at: Keyword.fetch!(attrs, :generated_at),
      host: Keyword.fetch!(attrs, :host),
      compatibility: Keyword.fetch!(attrs, :compatibility),
      support_matrix: Keyword.fetch!(attrs, :support_matrix),
      capability_registry: Keyword.get(attrs, :capability_registry, %{}),
      routes: Keyword.get(attrs, :routes, %{})
    })
  end

  @spec new_host(keyword()) :: Host.t()
  def new_host(attrs \\ []) do
    struct!(Host, %{
      phoenix_version: Keyword.get(attrs, :phoenix_version, dependency_requirement(:phoenix)),
      live_view_version:
        Keyword.get(attrs, :live_view_version, dependency_requirement(:phoenix_live_view)),
      manifest_sources: Keyword.get(attrs, :manifest_sources, [:bundled, :cached, :remote]),
      origin: Keyword.get(attrs, :origin, @default_origin)
    })
  end

  @spec new_compatibility(keyword()) :: Compatibility.t()
  def new_compatibility(attrs \\ []) do
    struct!(Compatibility, %{
      manifest_schema_version:
        Keyword.get(attrs, :manifest_schema_version, @manifest_schema_version),
      bridge_protocol_version:
        Keyword.get(attrs, :bridge_protocol_version, @bridge_protocol_version),
      native_runtime_version:
        Keyword.get(attrs, :native_runtime_version, @native_runtime_version),
      supported_manifest_sources:
        Keyword.get(attrs, :supported_manifest_sources, [:bundled, :cached, :remote]),
      remote_updates:
        Keyword.get(attrs, :remote_updates, [:versioned_replacement, :versioned_companion_data])
    })
  end

  @spec new_capability(keyword()) :: Capability.t()
  def new_capability(attrs) when is_list(attrs) do
    struct!(Capability, %{
      id: Keyword.fetch!(attrs, :id),
      version: Keyword.get(attrs, :version, "1.0.0"),
      status: Keyword.get(attrs, :status, :supported)
    })
  end

  @spec new_route_entry(keyword()) :: RouteEntry.t()
  def new_route_entry(attrs) when is_list(attrs) do
    struct!(RouteEntry, %{
      id: Keyword.fetch!(attrs, :id),
      path: Keyword.fetch!(attrs, :path),
      runtime: Keyword.fetch!(attrs, :runtime),
      offline: Keyword.get(attrs, :offline, :unavailable),
      cache_contract: Keyword.get(attrs, :cache_contract),
      island_contract: Keyword.get(attrs, :island_contract),
      capabilities: Keyword.get(attrs, :capabilities, []),
      packs: Keyword.get(attrs, :packs, []),
      sync: Keyword.get(attrs, :sync, []),
      security: Keyword.get(attrs, :security),
      allowlisted_origins: Keyword.get(attrs, :allowlisted_origins, [])
    })
  end

  @spec new_cache_contract(keyword()) :: CacheContract.t()
  def new_cache_contract(attrs) when is_list(attrs) do
    struct!(CacheContract, %{
      id: Keyword.fetch!(attrs, :id),
      staleness: Keyword.get(attrs, :staleness, :best_effort),
      restrictions: Keyword.get(attrs, :restrictions, [:read_only, :server_authoritative])
    })
  end

  @spec new_island_contract(keyword()) :: IslandContract.t()
  def new_island_contract(attrs) when is_list(attrs) do
    struct!(IslandContract, %{
      id: Keyword.fetch!(attrs, :id),
      storage: Keyword.get(attrs, :storage, :sqlite),
      reconciliation: Keyword.get(attrs, :reconciliation, :explicit),
      sync_seam: Keyword.fetch!(attrs, :sync_seam)
    })
  end

  @spec new_support_matrix(keyword()) :: SupportMatrix.t()
  def new_support_matrix(attrs) when is_list(attrs) do
    struct!(SupportMatrix, %{
      phoenix: Keyword.get(attrs, :phoenix, []),
      live_view: Keyword.get(attrs, :live_view, []),
      ios: Keyword.get(attrs, :ios, []),
      android: Keyword.get(attrs, :android, []),
      shells: Keyword.get(attrs, :shells, [])
    })
  end

  @spec new_support_entry(keyword()) :: SupportEntry.t()
  def new_support_entry(attrs) when is_list(attrs) do
    struct!(SupportEntry, %{
      target: Keyword.fetch!(attrs, :target),
      version: Keyword.fetch!(attrs, :version),
      status: Keyword.fetch!(attrs, :status),
      proof: Keyword.get(attrs, :proof),
      notes: Keyword.get(attrs, :notes)
    })
  end

  @spec to_map(term()) :: term()
  def to_map(%Root{} = root) do
    %{
      "manifest_schema_version" => root.manifest_schema_version,
      "crosswake_version" => root.crosswake_version,
      "generated_at" => root.generated_at,
      "host" => to_map(root.host),
      "compatibility" => to_map(root.compatibility),
      "support_matrix" => to_map(root.support_matrix),
      "capability_registry" => to_map(root.capability_registry),
      "routes" => to_map(root.routes)
    }
  end

  def to_map(%Host{} = host) do
    %{
      "phoenix_version" => host.phoenix_version,
      "live_view_version" => host.live_view_version,
      "manifest_sources" => Enum.map(host.manifest_sources, &Atom.to_string/1),
      "origin" => host.origin
    }
  end

  def to_map(%Compatibility{} = compatibility) do
    %{
      "manifest_schema_version" => compatibility.manifest_schema_version,
      "bridge_protocol_version" => compatibility.bridge_protocol_version,
      "native_runtime_version" => compatibility.native_runtime_version,
      "supported_manifest_sources" =>
        Enum.map(compatibility.supported_manifest_sources, &Atom.to_string/1),
      "remote_updates" => Enum.map(compatibility.remote_updates, &Atom.to_string/1)
    }
  end

  def to_map(%Capability{} = capability) do
    %{
      "id" => capability.id,
      "version" => capability.version,
      "status" => format_status(capability.status)
    }
  end

  def to_map(%RouteEntry{} = route) do
    %{
      "id" => route.id,
      "path" => route.path,
      "runtime" => Atom.to_string(route.runtime),
      "offline" => Atom.to_string(route.offline),
      "cache_contract" => to_map(route.cache_contract),
      "island_contract" => to_map(route.island_contract),
      "capabilities" => route.capabilities,
      "packs" => route.packs,
      "sync" => route.sync,
      "security" => route.security && Atom.to_string(route.security),
      "allowlisted_origins" => route.allowlisted_origins
    }
  end

  def to_map(%CacheContract{} = contract) do
    %{
      "id" => contract.id,
      "staleness" => Atom.to_string(contract.staleness),
      "restrictions" => Enum.map(contract.restrictions, &Atom.to_string/1)
    }
  end

  def to_map(%IslandContract{} = contract) do
    %{
      "id" => contract.id,
      "storage" => Atom.to_string(contract.storage),
      "reconciliation" => Atom.to_string(contract.reconciliation),
      "sync_seam" => contract.sync_seam
    }
  end

  def to_map(%SupportMatrix{} = support_matrix) do
    %{
      "phoenix" => Enum.map(support_matrix.phoenix, &to_map/1),
      "live_view" => Enum.map(support_matrix.live_view, &to_map/1),
      "ios" => Enum.map(support_matrix.ios, &to_map/1),
      "android" => Enum.map(support_matrix.android, &to_map/1),
      "shells" => Enum.map(support_matrix.shells, &to_map/1)
    }
  end

  def to_map(%SupportEntry{} = support_entry) do
    %{
      "target" => support_entry.target,
      "version" => support_entry.version,
      "status" => format_status(support_entry.status),
      "proof" => support_entry.proof,
      "notes" => support_entry.notes
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def to_map(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), to_map(value)} end)
    |> Enum.into(%{})
  end

  def to_map(list) when is_list(list), do: Enum.map(list, &to_map/1)
  def to_map(value), do: value

  @spec default_origin() :: String.t()
  def default_origin, do: @default_origin

  defp dependency_requirement(app) do
    Mix.Project.config()
    |> Keyword.fetch!(:deps)
    |> Enum.find_value(fn
      {^app, requirement} when is_binary(requirement) -> requirement
      _other -> nil
    end)
  end

  defp format_status(:verification_required), do: "verification required"
  defp format_status(status), do: Atom.to_string(status)
end
