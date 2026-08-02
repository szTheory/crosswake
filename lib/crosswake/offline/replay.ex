defmodule Crosswake.Offline.Replay do
  @moduledoc """
  Typed replay request and outcome contract for the study-session exemplar.
  """

  alias Crosswake.Offline.Journal.Entry

  defmodule Request do
    @moduledoc false

    @enforce_keys [
      :scope_ref,
      :route_id,
      :sync_seam,
      :journal_entry_id,
      :client_mutation_id,
      :idempotency_key,
      :base_checkpoint,
      :payload
    ]
    defstruct [
      :scope_ref,
      :route_id,
      :sync_seam,
      :journal_entry_id,
      :client_mutation_id,
      :idempotency_key,
      :base_checkpoint,
      :payload
    ]

    @type t :: %__MODULE__{
            scope_ref: String.t(),
            route_id: String.t(),
            sync_seam: String.t(),
            journal_entry_id: String.t(),
            client_mutation_id: String.t(),
            idempotency_key: String.t(),
            base_checkpoint: String.t(),
            payload: map()
          }
  end

  defmodule Outcome do
    @moduledoc false

    @enforce_keys [:status, :route_id, :sync_seam, :journal_entry_id]
    defstruct [
      :status,
      :route_id,
      :sync_seam,
      :journal_entry_id,
      :authoritative_state,
      :checkpoint,
      :reason
    ]

    @type status :: :accepted | :rejected | :conflict

    @type t :: %__MODULE__{
            status: status(),
            route_id: String.t(),
            sync_seam: String.t(),
            journal_entry_id: String.t(),
            authoritative_state: map() | nil,
            checkpoint: String.t() | nil,
            reason: String.t() | nil
          }
  end

  @spec new_request(keyword()) :: Request.t()
  def new_request(attrs) when is_list(attrs) do
    struct!(Request, %{
      scope_ref: Keyword.fetch!(attrs, :scope_ref),
      route_id: Keyword.fetch!(attrs, :route_id),
      sync_seam: Keyword.fetch!(attrs, :sync_seam),
      journal_entry_id: Keyword.fetch!(attrs, :journal_entry_id),
      client_mutation_id: Keyword.fetch!(attrs, :client_mutation_id),
      idempotency_key: Keyword.fetch!(attrs, :idempotency_key),
      base_checkpoint: Keyword.fetch!(attrs, :base_checkpoint),
      payload: Keyword.get(attrs, :payload, %{})
    })
  end

  @spec request_for_entry(Entry.t()) :: Request.t()
  def request_for_entry(%Entry{} = entry) do
    new_request(
      scope_ref: entry.scope_ref,
      route_id: entry.route_id,
      sync_seam: entry.sync_seam,
      journal_entry_id: entry.id,
      client_mutation_id: entry.client_mutation_id,
      idempotency_key: entry.idempotency_key,
      base_checkpoint: entry.base_checkpoint,
      payload: entry.payload
    )
  end

  @spec accepted(Request.t(), keyword()) :: Outcome.t()
  def accepted(%Request{} = request, attrs \\ []) do
    new_outcome(:accepted, request, attrs)
  end

  @spec rejected(Request.t(), keyword()) :: Outcome.t()
  def rejected(%Request{} = request, attrs \\ []) do
    new_outcome(:rejected, request, attrs)
  end

  @spec conflict(Request.t(), keyword()) :: Outcome.t()
  def conflict(%Request{} = request, attrs \\ []) do
    new_outcome(:conflict, request, attrs)
  end

  @spec to_map(Request.t() | Outcome.t()) :: map()
  def to_map(%Request{} = request) do
    %{
      "scope_ref" => request.scope_ref,
      "route_id" => request.route_id,
      "sync_seam" => request.sync_seam,
      "journal_entry_id" => request.journal_entry_id,
      "client_mutation_id" => request.client_mutation_id,
      "idempotency_key" => request.idempotency_key,
      "base_checkpoint" => request.base_checkpoint,
      "payload" => request.payload
    }
  end

  def to_map(%Outcome{} = outcome) do
    %{
      "status" => Atom.to_string(outcome.status),
      "route_id" => outcome.route_id,
      "sync_seam" => outcome.sync_seam,
      "journal_entry_id" => outcome.journal_entry_id,
      "authoritative_state" => outcome.authoritative_state,
      "checkpoint" => outcome.checkpoint,
      "reason" => outcome.reason
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp new_outcome(status, %Request{} = request, attrs) do
    struct!(Outcome, %{
      status: status,
      route_id: request.route_id,
      sync_seam: request.sync_seam,
      journal_entry_id: request.journal_entry_id,
      authoritative_state: Keyword.get(attrs, :authoritative_state),
      checkpoint: Keyword.get(attrs, :checkpoint),
      reason: Keyword.get(attrs, :reason)
    })
  end
end
