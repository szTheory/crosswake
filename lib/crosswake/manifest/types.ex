defmodule Crosswake.Manifest.Types do
  @moduledoc """
  Typed manifest contract shared by manifest generation, compatibility checks,
  doctor diagnostics, and support-matrix rendering.
  """

  alias Crosswake.Transfer.Contracts

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
      :pack_registry,
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
      pack_registry: %{},
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
            pack_registry: %{
              optional(String.t()) => Crosswake.Manifest.Types.PackEntry.t()
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
    defstruct [
      :id,
      :version,
      :family,
      :owner,
      :package_class,
      :proof_class,
      :rebuild,
      :denial,
      :fallback,
      :guide,
      status: :supported,
      prerequisites: [],
      legacy_ids: []
    ]

    @type status :: :supported | :verification_required | :unsupported
    @type owner :: :bounded_bridge | :native_screen | :backend_seam | :defer
    @type package_class :: :core | :companion | :example_docs_only | :defer
    @type proof_class :: :merge_blocking | :advisory
    @type rebuild :: :none | :native_required | :companion_required

    @type t :: %__MODULE__{
            id: String.t(),
            version: String.t(),
            status: status(),
            family: String.t(),
            owner: owner(),
            package_class: package_class(),
            proof_class: proof_class(),
            rebuild: rebuild(),
            prerequisites: [String.t()],
            denial: String.t(),
            fallback: String.t(),
            guide: String.t(),
            legacy_ids: [String.t()]
          }
  end

  defmodule PackEntry do
    @moduledoc false

    @enforce_keys [:id, :version, :kind]
    defstruct [:id, :version, :kind, :integrity]

    @type t :: %__MODULE__{
            id: String.t(),
            version: String.t(),
            kind: Crosswake.Policy.Schema.pack_kind(),
            integrity: Crosswake.Policy.Schema.pack_integrity() | nil
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
      transfers: [],
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
            transfers: [Crosswake.Manifest.Types.TransferSeam.t()],
            security: Crosswake.Policy.Schema.security() | nil,
            allowlisted_origins: [String.t()]
          }
  end

  defmodule TransferSeam do
    @moduledoc false

    @enforce_keys [
      :protocol,
      :version,
      :id,
      :intent,
      :direction,
      :verification
    ]
    defstruct [
      :protocol,
      :version,
      :id,
      :intent,
      :direction,
      :source,
      :destination,
      :verification,
      media_types: [],
      states: []
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            id: String.t(),
            intent: Contracts.intent(),
            direction: Contracts.direction(),
            source: Contracts.source() | nil,
            destination: Contracts.destination() | nil,
            verification: Contracts.verification(),
            media_types: [String.t()],
            states: [Contracts.state()]
          }
  end

  defmodule CacheContract do
    @moduledoc false

    @enforce_keys [:id, :staleness, :hydration, :storage, :restrictions]
    defstruct [:id, :staleness, :hydration, :storage, restrictions: []]

    @type staleness :: :best_effort
    @type hydration :: :sqlite_snapshot
    @type storage :: :sqlite
    @type restriction :: :read_only | :server_authoritative

    @type t :: %__MODULE__{
            id: String.t(),
            staleness: staleness(),
            hydration: hydration(),
            storage: storage(),
            restrictions: [restriction()]
          }
  end

  defmodule IslandContract do
    @moduledoc false

    @enforce_keys [
      :id,
      :storage,
      :draft_surface,
      :journal_mode,
      :reconciliation,
      :checkpoint_requirement,
      :authoritative_source,
      :sync_seam
    ]
    defstruct [
      :id,
      :storage,
      :draft_surface,
      :journal_mode,
      :reconciliation,
      :checkpoint_requirement,
      :authoritative_source,
      :sync_seam
    ]

    @type storage :: :sqlite
    @type draft_surface :: :study_session_draft
    @type journal_mode :: :append_only
    @type reconciliation :: :explicit
    @type checkpoint_requirement :: :required
    @type authoritative_source :: :phoenix

    @type t :: %__MODULE__{
            id: String.t(),
            storage: storage(),
            draft_surface: draft_surface(),
            journal_mode: journal_mode(),
            reconciliation: reconciliation(),
            checkpoint_requirement: checkpoint_requirement(),
            authoritative_source: authoritative_source(),
            sync_seam: String.t()
          }
  end

  defmodule SupportMatrix do
    @moduledoc false

    @enforce_keys [
      :phoenix,
      :live_view,
      :ios,
      :android,
      :shells,
      :capability_families,
      :package_surfaces,
      :release_boundaries,
      :change_classes
    ]
    defstruct phoenix: [],
              live_view: [],
              ios: [],
              android: [],
              shells: [],
              capability_families: [],
              package_surfaces: [],
              release_boundaries: [],
              change_classes: []

    @type t :: %__MODULE__{
            phoenix: [Crosswake.Manifest.Types.SupportEntry.t()],
            live_view: [Crosswake.Manifest.Types.SupportEntry.t()],
            ios: [Crosswake.Manifest.Types.SupportEntry.t()],
            android: [Crosswake.Manifest.Types.SupportEntry.t()],
            shells: [Crosswake.Manifest.Types.SupportEntry.t()],
            capability_families: [Crosswake.Manifest.Types.CapabilitySupportEntry.t()],
            package_surfaces: [Crosswake.Manifest.Types.PackageSurfaceEntry.t()],
            release_boundaries: [Crosswake.Manifest.Types.ReleaseBoundaryEntry.t()],
            change_classes: [Crosswake.Manifest.Types.ChangeClassEntry.t()]
          }
  end

  defmodule SupportEntry do
    @moduledoc false

    @enforce_keys [:target, :version, :status]
    defstruct [:target, :version, :status, :proof, :notes, :boundary_link]

    @type t :: %__MODULE__{
            target: String.t(),
            version: String.t(),
            status: Crosswake.Manifest.Types.Capability.status(),
            proof: String.t() | nil,
            notes: String.t() | nil,
            boundary_link: String.t() | nil
          }
  end

  defmodule CapabilitySupportEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:family, :owner, :package_class, :proof_class, :rebuild]
    defstruct [
      :family,
      :owner,
      :package_class,
      :proof_class,
      :rebuild,
      prerequisites: [],
      denial: nil,
      fallback: nil,
      guide: nil
    ]

    @type t :: %__MODULE__{
            family: String.t(),
            owner: Capability.owner(),
            package_class: Capability.package_class(),
            proof_class: Capability.proof_class(),
            rebuild: Capability.rebuild(),
            prerequisites: [String.t()],
            denial: String.t() | nil,
            fallback: String.t() | nil,
            guide: String.t() | nil
          }
  end

  defmodule PackageSurfaceEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:surface, :package_class, :why, :release_burden, :guide]
    defstruct [:surface, :package_class, :why, :release_burden, :guide]

    @type t :: %__MODULE__{
            surface: String.t(),
            package_class: Capability.package_class(),
            why: String.t(),
            release_burden: String.t(),
            guide: String.t()
          }
  end

  defmodule ReleaseBoundaryEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:target, :versioning, :compatibility_contract, :release_rule]
    defstruct [
      :target,
      :versioning,
      :compatibility_contract,
      :release_rule
    ]

    @type t :: %__MODULE__{
            target: String.t(),
            versioning: String.t(),
            compatibility_contract: String.t(),
            release_rule: String.t()
          }
  end

  defmodule ChangeClassEntry do
    @moduledoc false
    @derive Jason.Encoder

    @enforce_keys [:change_class, :what_changed, :adopter_action, :compatibility_signal, :required_proof]
    defstruct [
      :change_class,
      :what_changed,
      :adopter_action,
      :compatibility_signal,
      :required_proof
    ]

    @type t :: %__MODULE__{
            change_class: String.t(),
            what_changed: String.t(),
            adopter_action: String.t(),
            compatibility_signal: String.t(),
            required_proof: String.t()
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
      pack_registry: Keyword.get(attrs, :pack_registry, %{}),
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
      status: Keyword.get(attrs, :status, :supported),
      family: Keyword.get(attrs, :family, Keyword.fetch!(attrs, :id)),
      owner: Keyword.get(attrs, :owner, :defer),
      package_class: Keyword.get(attrs, :package_class, :defer),
      proof_class: Keyword.get(attrs, :proof_class, :advisory),
      rebuild: Keyword.get(attrs, :rebuild, :none),
      prerequisites: Keyword.get(attrs, :prerequisites, ["declared route support"]),
      denial: Keyword.get(attrs, :denial, "unavailable_capability"),
      fallback: Keyword.get(attrs, :fallback, "fail_closed"),
      guide: Keyword.get(attrs, :guide, "guides/capabilities.md"),
      legacy_ids: Keyword.get(attrs, :legacy_ids, [])
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
      transfers: Keyword.get(attrs, :transfers, []),
      security: Keyword.get(attrs, :security),
      allowlisted_origins: Keyword.get(attrs, :allowlisted_origins, [])
    })
  end

  @spec new_transfer_seam(keyword()) :: TransferSeam.t()
  def new_transfer_seam(attrs) when is_list(attrs) do
    struct!(TransferSeam, %{
      protocol: Keyword.get(attrs, :protocol, Contracts.protocol()),
      version: Keyword.get(attrs, :version, Contracts.version()),
      id: Keyword.fetch!(attrs, :id),
      intent: Keyword.fetch!(attrs, :intent),
      direction: Keyword.fetch!(attrs, :direction),
      source: Keyword.get(attrs, :source),
      destination: Keyword.get(attrs, :destination),
      verification: Keyword.fetch!(attrs, :verification),
      media_types: Keyword.get(attrs, :media_types, []),
      states: Keyword.get(attrs, :states, Contracts.transfer_states())
    })
  end

  @spec new_pack_entry(keyword()) :: PackEntry.t()
  def new_pack_entry(attrs) when is_list(attrs) do
    struct!(PackEntry, %{
      id: Keyword.fetch!(attrs, :id),
      version: Keyword.fetch!(attrs, :version),
      kind: Keyword.fetch!(attrs, :kind),
      integrity: Keyword.get(attrs, :integrity)
    })
  end

  @spec new_cache_contract(keyword()) :: CacheContract.t()
  def new_cache_contract(attrs) when is_list(attrs) do
    struct!(CacheContract, %{
      id: Keyword.fetch!(attrs, :id),
      staleness: Keyword.get(attrs, :staleness, :best_effort),
      hydration: Keyword.get(attrs, :hydration, :sqlite_snapshot),
      storage: Keyword.get(attrs, :storage, :sqlite),
      restrictions: Keyword.get(attrs, :restrictions, [:read_only, :server_authoritative])
    })
  end

  @spec new_island_contract(keyword()) :: IslandContract.t()
  def new_island_contract(attrs) when is_list(attrs) do
    struct!(IslandContract, %{
      id: Keyword.fetch!(attrs, :id),
      storage: Keyword.get(attrs, :storage, :sqlite),
      draft_surface: Keyword.get(attrs, :draft_surface, :study_session_draft),
      journal_mode: Keyword.get(attrs, :journal_mode, :append_only),
      reconciliation: Keyword.get(attrs, :reconciliation, :explicit),
      checkpoint_requirement: Keyword.get(attrs, :checkpoint_requirement, :required),
      authoritative_source: Keyword.get(attrs, :authoritative_source, :phoenix),
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
      shells: Keyword.get(attrs, :shells, []),
      capability_families: Keyword.get(attrs, :capability_families, []),
      package_surfaces: Keyword.get(attrs, :package_surfaces, []),
      release_boundaries: Keyword.get(attrs, :release_boundaries, []),
      change_classes: Keyword.get(attrs, :change_classes, [])
    })
  end

  @spec new_support_entry(keyword()) :: SupportEntry.t()
  def new_support_entry(attrs) when is_list(attrs) do
    struct!(SupportEntry, %{
      target: Keyword.fetch!(attrs, :target),
      version: Keyword.fetch!(attrs, :version),
      status: Keyword.fetch!(attrs, :status),
      proof: Keyword.get(attrs, :proof),
      notes: Keyword.get(attrs, :notes),
      boundary_link: Keyword.get(attrs, :boundary_link)
    })
  end

  @spec new_capability_support_entry(keyword()) :: CapabilitySupportEntry.t()
  def new_capability_support_entry(attrs) when is_list(attrs) do
    struct!(CapabilitySupportEntry, %{
      family: Keyword.fetch!(attrs, :family),
      owner: Keyword.fetch!(attrs, :owner),
      package_class: Keyword.fetch!(attrs, :package_class),
      proof_class: Keyword.fetch!(attrs, :proof_class),
      rebuild: Keyword.fetch!(attrs, :rebuild),
      prerequisites: Keyword.get(attrs, :prerequisites, []),
      denial: Keyword.get(attrs, :denial),
      fallback: Keyword.get(attrs, :fallback),
      guide: Keyword.get(attrs, :guide)
    })
  end

  @spec new_package_surface_entry(keyword()) :: PackageSurfaceEntry.t()
  def new_package_surface_entry(attrs) when is_list(attrs) do
    struct!(PackageSurfaceEntry, %{
      surface: Keyword.fetch!(attrs, :surface),
      package_class: Keyword.fetch!(attrs, :package_class),
      why: Keyword.fetch!(attrs, :why),
      release_burden: Keyword.fetch!(attrs, :release_burden),
      guide: Keyword.fetch!(attrs, :guide)
    })
  end

  @spec new_release_boundary_entry(keyword()) :: ReleaseBoundaryEntry.t()
  def new_release_boundary_entry(attrs) when is_list(attrs) do
    struct!(ReleaseBoundaryEntry, %{
      target: Keyword.fetch!(attrs, :target),
      versioning: Keyword.fetch!(attrs, :versioning),
      compatibility_contract: Keyword.fetch!(attrs, :compatibility_contract),
      release_rule: Keyword.fetch!(attrs, :release_rule)
    })
  end

  @spec new_change_class_entry(keyword()) :: ChangeClassEntry.t()
  def new_change_class_entry(attrs) when is_list(attrs) do
    struct!(ChangeClassEntry, %{
      change_class: Keyword.fetch!(attrs, :change_class),
      what_changed: Keyword.fetch!(attrs, :what_changed),
      adopter_action: Keyword.fetch!(attrs, :adopter_action),
      compatibility_signal: Keyword.fetch!(attrs, :compatibility_signal),
      required_proof: Keyword.fetch!(attrs, :required_proof)
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
      "pack_registry" => to_map(root.pack_registry),
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
      "family" => capability.family,
      "owner" => Atom.to_string(capability.owner),
      "package_class" => format_package_class(capability.package_class),
      "proof_class" => format_proof_class(capability.proof_class),
      "rebuild" => format_rebuild(capability.rebuild),
      "prerequisites" => capability.prerequisites,
      "denial" => capability.denial,
      "fallback" => capability.fallback,
      "guide" => capability.guide,
      "legacy_ids" => capability.legacy_ids,
      "version" => capability.version,
      "status" => format_status(capability.status)
    }
  end

  def to_map(%PackEntry{} = pack_entry) do
    %{
      "id" => pack_entry.id,
      "version" => pack_entry.version,
      "kind" => Atom.to_string(pack_entry.kind),
      "integrity" => to_map(pack_entry.integrity)
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
      "transfers" => Enum.map(route.transfers, &to_map/1),
      "security" => route.security && Atom.to_string(route.security),
      "allowlisted_origins" => route.allowlisted_origins
    }
  end

  def to_map(%TransferSeam{} = seam) do
    %{
      "protocol" => seam.protocol,
      "version" => seam.version,
      "id" => seam.id,
      "intent" => Atom.to_string(seam.intent),
      "direction" => Atom.to_string(seam.direction),
      "source" => seam.source && Atom.to_string(seam.source),
      "destination" => seam.destination && Atom.to_string(seam.destination),
      "verification" => Atom.to_string(seam.verification),
      "media_types" => seam.media_types,
      "states" => Enum.map(seam.states, &Atom.to_string/1)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def to_map(%CacheContract{} = contract) do
    %{
      "id" => contract.id,
      "staleness" => Atom.to_string(contract.staleness),
      "hydration" => Atom.to_string(contract.hydration),
      "storage" => Atom.to_string(contract.storage),
      "restrictions" => Enum.map(contract.restrictions, &Atom.to_string/1)
    }
  end

  def to_map(%IslandContract{} = contract) do
    %{
      "id" => contract.id,
      "storage" => Atom.to_string(contract.storage),
      "draft_surface" => Atom.to_string(contract.draft_surface),
      "journal_mode" => Atom.to_string(contract.journal_mode),
      "reconciliation" => Atom.to_string(contract.reconciliation),
      "checkpoint_requirement" => Atom.to_string(contract.checkpoint_requirement),
      "authoritative_source" => Atom.to_string(contract.authoritative_source),
      "sync_seam" => contract.sync_seam
    }
  end

  def to_map(%SupportMatrix{} = support_matrix) do
    %{
      "phoenix" => Enum.map(support_matrix.phoenix, &to_map/1),
      "live_view" => Enum.map(support_matrix.live_view, &to_map/1),
      "ios" => Enum.map(support_matrix.ios, &to_map/1),
      "android" => Enum.map(support_matrix.android, &to_map/1),
      "shells" => Enum.map(support_matrix.shells, &to_map/1),
      "capability_families" => Enum.map(support_matrix.capability_families, &to_map/1),
      "package_surfaces" => Enum.map(support_matrix.package_surfaces, &to_map/1),
      "release_boundaries" => Enum.map(support_matrix.release_boundaries, &to_map/1),
      "change_classes" => Enum.map(support_matrix.change_classes, &to_map/1)
    }
  end

  def to_map(%SupportEntry{} = support_entry) do
    %{
      "target" => support_entry.target,
      "version" => support_entry.version,
      "status" => format_status(support_entry.status),
      "proof" => support_entry.proof,
      "notes" => support_entry.notes,
      "boundary_link" => support_entry.boundary_link
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def to_map(%CapabilitySupportEntry{} = support_entry) do
    %{
      "family" => support_entry.family,
      "owner" => Atom.to_string(support_entry.owner),
      "package_class" => format_package_class(support_entry.package_class),
      "proof_class" => format_proof_class(support_entry.proof_class),
      "rebuild" => format_rebuild(support_entry.rebuild),
      "prerequisites" => support_entry.prerequisites,
      "denial" => support_entry.denial,
      "fallback" => support_entry.fallback,
      "guide" => support_entry.guide
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def to_map(%PackageSurfaceEntry{} = entry) do
    %{
      "surface" => entry.surface,
      "package_class" => format_package_class(entry.package_class),
      "why" => entry.why,
      "release_burden" => entry.release_burden,
      "guide" => entry.guide
    }
  end

  def to_map(%ReleaseBoundaryEntry{} = entry) do
    %{
      "target" => entry.target,
      "versioning" => entry.versioning,
      "compatibility_contract" => entry.compatibility_contract,
      "release_rule" => entry.release_rule
    }
  end

  def to_map(%ChangeClassEntry{} = entry) do
    %{
      "change_class" => entry.change_class,
      "what_changed" => entry.what_changed,
      "adopter_action" => entry.adopter_action,
      "compatibility_signal" => entry.compatibility_signal,
      "required_proof" => entry.required_proof
    }
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
  defp format_package_class(:example_docs_only), do: "example/docs-only"
  defp format_package_class(package_class), do: Atom.to_string(package_class)
  defp format_proof_class(:merge_blocking), do: "merge-blocking"
  defp format_proof_class(proof_class), do: Atom.to_string(proof_class)
  defp format_rebuild(:native_required), do: "native-required"
  defp format_rebuild(:companion_required), do: "companion-required"
  defp format_rebuild(rebuild), do: Atom.to_string(rebuild)
end
