defmodule Crosswake.Offline.Journal do
  @moduledoc """
  Immutable journal contract for committed offline study-session actions.
  """

  defmodule Entry do
    @moduledoc false

    @enforce_keys [
      :id,
      :scope_ref,
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
      :scope_ref,
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
            scope_ref: String.t(),
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

  @scope_ref_pattern ~r/^v[1-9][0-9]*\.[A-Za-z0-9_-]{16,128}$/
  @scope_ref_error "CW-OFFLINE-SCOPE-REF"

  @spec new_entry(keyword()) :: Entry.t()
  def new_entry(attrs) when is_list(attrs) do
    scope_ref = attrs |> Keyword.fetch!(:scope_ref) |> validate_scope_ref!()

    struct!(Entry, %{
      id: Keyword.fetch!(attrs, :id),
      scope_ref: scope_ref,
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
      "scope_ref" => entry.scope_ref,
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

  defp validate_scope_ref!(scope_ref) when is_binary(scope_ref) do
    if Regex.match?(@scope_ref_pattern, scope_ref) do
      scope_ref
    else
      raise ArgumentError, @scope_ref_error
    end
  end

  defp validate_scope_ref!(_scope_ref), do: raise(ArgumentError, @scope_ref_error)
end
