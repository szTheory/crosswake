defmodule Crosswake.Sync.EventLog do
  @moduledoc """
  Core structs for the sync event log.
  """

  defmodule Entry do
    @moduledoc false

    @enforce_keys [:idempotency_key, :route_id, :sync_seam, :operation, :status]
    defstruct [
      :idempotency_key,
      :route_id,
      :sync_seam,
      :operation,
      :payload,
      :status,
      :authoritative_state,
      :reason
    ]

    @type status :: :queued | :processing | :completed | :failed | :conflict

    @type t :: %__MODULE__{
            idempotency_key: String.t(),
            route_id: String.t(),
            sync_seam: String.t(),
            operation: atom(),
            payload: map() | nil,
            status: status(),
            authoritative_state: map() | nil,
            reason: String.t() | nil
          }
  end

  @spec new_entry(keyword()) :: Entry.t()
  def new_entry(attrs) when is_list(attrs) do
    struct!(Entry, %{
      idempotency_key: Keyword.fetch!(attrs, :idempotency_key),
      route_id: Keyword.fetch!(attrs, :route_id),
      sync_seam: Keyword.fetch!(attrs, :sync_seam),
      operation: Keyword.fetch!(attrs, :operation),
      payload: Keyword.get(attrs, :payload, %{}),
      status: Keyword.get(attrs, :status, :queued),
      authoritative_state: Keyword.get(attrs, :authoritative_state),
      reason: Keyword.get(attrs, :reason)
    })
  end
end
