defmodule Crosswake.Offline.Runtime do
  @moduledoc """
  Executable runtime contract for cached hydration and the study-session island.
  """

  alias Crosswake.Offline.Contracts
  alias Crosswake.Offline.Journal

  defmodule CachedHydration do
    @moduledoc false

    @enforce_keys [:route_id, :storage, :hydration, :writable]
    defstruct [:route_id, :storage, :hydration, :writable]

    @type t :: %__MODULE__{
            route_id: String.t(),
            storage: :sqlite,
            hydration: :sqlite_snapshot,
            writable: false
          }
  end

  defmodule StudySession do
    @moduledoc false

    @enforce_keys [
      :route_id,
      :storage,
      :draft_surface,
      :journal_mode,
      :replay_mode,
      :platforms,
      :authoritative_source,
      :direct_server_mutation
    ]
    defstruct [
      :route_id,
      :storage,
      :draft_surface,
      :journal_mode,
      :replay_mode,
      :platforms,
      :authoritative_source,
      :direct_server_mutation
    ]

    @type platform :: :ios | :android

    @type t :: %__MODULE__{
            route_id: String.t(),
            storage: :sqlite,
            draft_surface: :study_session_draft,
            journal_mode: :append_only,
            replay_mode: :explicit,
            platforms: [platform()],
            authoritative_source: :phoenix,
            direct_server_mutation: false
          }
  end

  @spec cached_hydration(Contracts.CacheRoute.t()) :: CachedHydration.t()
  def cached_hydration(%Contracts.CacheRoute{} = contract) do
    %CachedHydration{
      route_id: contract.route_id,
      storage: contract.storage,
      hydration: contract.hydration,
      writable: false
    }
  end

  @spec study_session(Contracts.StudySessionIsland.t()) :: StudySession.t()
  def study_session(%Contracts.StudySessionIsland{} = contract) do
    %StudySession{
      route_id: contract.route_id,
      storage: contract.storage,
      draft_surface: contract.draft_surface,
      journal_mode: contract.journal_mode,
      replay_mode: contract.reconciliation,
      platforms: [:ios, :android],
      authoritative_source: contract.authoritative_source,
      direct_server_mutation: false
    }
  end

  @spec queue_entry(StudySession.t(), Journal.Entry.t()) :: {:ok, Journal.Entry.t()}
  def queue_entry(%StudySession{journal_mode: :append_only}, %Journal.Entry{} = entry) do
    {:ok, %{entry | status: :queued}}
  end
end
