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

  defmodule Lifecycle do
    @moduledoc false

    @enforce_keys [:state, :scope_ref, :epoch]
    defstruct [:state, :scope_ref, :epoch]

    @type state :: :inactive | :active | :stopping

    @type t :: %__MODULE__{
            state: state(),
            scope_ref: String.t() | nil,
            epoch: non_neg_integer()
          }
  end

  @scope_ref_pattern ~r/^v[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}$/

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

  @spec new_lifecycle() :: Lifecycle.t()
  def new_lifecycle, do: %Lifecycle{state: :inactive, scope_ref: nil, epoch: 0}

  @spec activate(Lifecycle.t(), String.t()) :: {:ok, Lifecycle.t()} | {:error, :scope_inactive}
  def activate(%Lifecycle{state: :inactive, epoch: epoch}, scope_ref) when is_binary(scope_ref) do
    if Regex.match?(@scope_ref_pattern, scope_ref) do
      {:ok, %Lifecycle{state: :active, scope_ref: scope_ref, epoch: epoch + 1}}
    else
      {:error, :scope_inactive}
    end
  end

  def activate(%Lifecycle{}, _scope_ref), do: {:error, :scope_inactive}

  @spec fence(Lifecycle.t()) :: Lifecycle.t()
  def fence(%Lifecycle{} = lifecycle) do
    %Lifecycle{state: :inactive, scope_ref: nil, epoch: lifecycle.epoch + 1}
  end

  @spec lease(Lifecycle.t(), String.t(), non_neg_integer()) ::
          {:ok, %{scope_ref: String.t(), epoch: non_neg_integer()}}
          | {:error, :scope_inactive | :stale_lease}
  def lease(%Lifecycle{state: :active, scope_ref: scope_ref, epoch: epoch}, scope_ref, epoch),
    do: {:ok, %{scope_ref: scope_ref, epoch: epoch}}

  def lease(%Lifecycle{state: :active}, _scope_ref, _epoch), do: {:error, :stale_lease}
  def lease(%Lifecycle{}, _scope_ref, _epoch), do: {:error, :scope_inactive}

  @spec drain([term()], (term() -> :accepted | :rejected | :conflict | :blocked)) ::
          {:complete | :halted, [term()]}
  def drain(entries, admit) when is_list(entries) and is_function(admit, 1) do
    drain_entries(entries, admit, [])
  end

  @spec queue_entry(StudySession.t(), Journal.Entry.t()) :: {:ok, Journal.Entry.t()}
  def queue_entry(%StudySession{journal_mode: :append_only}, %Journal.Entry{} = entry) do
    {:ok, %{entry | status: :queued}}
  end

  defp drain_entries([], _admit, retained), do: {:complete, Enum.reverse(retained)}

  defp drain_entries([entry | rest], admit, retained) do
    case admit.(entry) do
      :accepted -> drain_entries(rest, admit, retained)
      :blocked -> {:halted, Enum.reverse(retained, [entry | rest])}
      :rejected -> drain_entries(rest, admit, [entry | retained])
      :conflict -> drain_entries(rest, admit, [entry | retained])
    end
  end
end
