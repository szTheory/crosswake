defmodule Crosswake.Offline.Contracts do
  @moduledoc """
  Typed Phase 4 offline contract surfaces for the cached-route and study-session
  exemplar.
  """

  alias Crosswake.Manifest.Types

  defmodule CacheRoute do
    @moduledoc false

    @enforce_keys [:id, :route_id, :staleness, :hydration, :storage, :restrictions]
    defstruct [:id, :route_id, :staleness, :hydration, :storage, restrictions: []]

    @type restriction :: :read_only | :server_authoritative

    @type t :: %__MODULE__{
            id: String.t(),
            route_id: String.t(),
            staleness: :best_effort,
            hydration: :sqlite_snapshot,
            storage: :sqlite,
            restrictions: [restriction()]
          }
  end

  defmodule StudySessionIsland do
    @moduledoc false

    @enforce_keys [
      :id,
      :route_id,
      :sync_seam,
      :draft_surface,
      :storage,
      :journal_mode,
      :reconciliation,
      :checkpoint_requirement,
      :authoritative_source
    ]
    defstruct [
      :id,
      :route_id,
      :sync_seam,
      :draft_surface,
      :storage,
      :journal_mode,
      :reconciliation,
      :checkpoint_requirement,
      :authoritative_source
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            route_id: String.t(),
            sync_seam: String.t(),
            draft_surface: :study_session_draft,
            storage: :sqlite,
            journal_mode: :append_only,
            reconciliation: :explicit,
            checkpoint_requirement: :required,
            authoritative_source: :phoenix
          }
  end

  @spec new_cache_route(String.t(), keyword()) :: CacheRoute.t()
  def new_cache_route(id, attrs \\ []) when is_binary(id) and is_list(attrs) do
    struct!(CacheRoute, %{
      id: id,
      route_id: Keyword.fetch!(attrs, :route_id),
      staleness: Keyword.get(attrs, :staleness, :best_effort),
      hydration: Keyword.get(attrs, :hydration, :sqlite_snapshot),
      storage: Keyword.get(attrs, :storage, :sqlite),
      restrictions: Keyword.get(attrs, :restrictions, [:read_only, :server_authoritative])
    })
  end

  @spec new_study_session_island(String.t(), keyword()) :: StudySessionIsland.t()
  def new_study_session_island(id, attrs \\ []) when is_binary(id) and is_list(attrs) do
    struct!(StudySessionIsland, %{
      id: id,
      route_id: Keyword.fetch!(attrs, :route_id),
      sync_seam: Keyword.fetch!(attrs, :sync_seam),
      draft_surface: Keyword.get(attrs, :draft_surface, :study_session_draft),
      storage: Keyword.get(attrs, :storage, :sqlite),
      journal_mode: Keyword.get(attrs, :journal_mode, :append_only),
      reconciliation: Keyword.get(attrs, :reconciliation, :explicit),
      checkpoint_requirement: Keyword.get(attrs, :checkpoint_requirement, :required),
      authoritative_source: Keyword.get(attrs, :authoritative_source, :phoenix)
    })
  end

  @spec cache_contract(CacheRoute.t()) :: Types.CacheContract.t()
  def cache_contract(%CacheRoute{} = contract) do
    Types.new_cache_contract(
      id: contract.id,
      staleness: contract.staleness,
      hydration: contract.hydration,
      storage: contract.storage,
      restrictions: contract.restrictions
    )
  end

  @spec island_contract(StudySessionIsland.t()) :: Types.IslandContract.t()
  def island_contract(%StudySessionIsland{} = contract) do
    Types.new_island_contract(
      id: contract.id,
      storage: contract.storage,
      draft_surface: contract.draft_surface,
      journal_mode: contract.journal_mode,
      reconciliation: contract.reconciliation,
      checkpoint_requirement: contract.checkpoint_requirement,
      authoritative_source: contract.authoritative_source,
      sync_seam: contract.sync_seam
    )
  end
end
