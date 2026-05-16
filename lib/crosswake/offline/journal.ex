defmodule Crosswake.Offline.Journal do
  @moduledoc """
  Immutable journal contract for committed offline study-session actions.
  """

  defmodule Entry do
    @moduledoc false

    @enforce_keys [
      :id,
      :route_id,
      :sync_seam,
      :operation,
      :payload,
      :client_mutation_id,
      :idempotency_key,
      :base_checkpoint,
      :committed_at,
      :status
    ]
    defstruct [
      :id,
      :route_id,
      :sync_seam,
      :operation,
      :payload,
      :client_mutation_id,
      :idempotency_key,
      :base_checkpoint,
      :committed_at,
      :status
    ]

    @type status :: :queued | :replaying | :accepted | :rejected | :conflict

    @type t :: %__MODULE__{
            id: String.t(),
            route_id: String.t(),
            sync_seam: String.t(),
            operation: atom(),
            payload: map(),
            client_mutation_id: String.t(),
            idempotency_key: String.t(),
            base_checkpoint: String.t(),
            committed_at: DateTime.t(),
            status: status()
          }
  end

  @spec new_entry(keyword()) :: Entry.t()
  def new_entry(attrs) when is_list(attrs) do
    struct!(Entry, %{
      id: Keyword.fetch!(attrs, :id),
      route_id: Keyword.fetch!(attrs, :route_id),
      sync_seam: Keyword.fetch!(attrs, :sync_seam),
      operation: Keyword.fetch!(attrs, :operation),
      payload: Keyword.get(attrs, :payload, %{}),
      client_mutation_id: Keyword.fetch!(attrs, :client_mutation_id),
      idempotency_key: Keyword.fetch!(attrs, :idempotency_key),
      base_checkpoint: Keyword.fetch!(attrs, :base_checkpoint),
      committed_at:
        Keyword.get_lazy(attrs, :committed_at, fn ->
          DateTime.utc_now() |> DateTime.truncate(:second)
        end),
      status: Keyword.get(attrs, :status, :queued)
    })
  end

  @spec replaying(Entry.t()) :: Entry.t()
  def replaying(%Entry{} = entry), do: %{entry | status: :replaying}

  @spec to_map(Entry.t()) :: map()
  def to_map(%Entry{} = entry) do
    %{
      "id" => entry.id,
      "route_id" => entry.route_id,
      "sync_seam" => entry.sync_seam,
      "operation" => Atom.to_string(entry.operation),
      "payload" => entry.payload,
      "client_mutation_id" => entry.client_mutation_id,
      "idempotency_key" => entry.idempotency_key,
      "base_checkpoint" => entry.base_checkpoint,
      "committed_at" => DateTime.to_iso8601(entry.committed_at),
      "status" => Atom.to_string(entry.status)
    }
  end
end
