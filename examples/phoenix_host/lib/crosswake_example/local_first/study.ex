defmodule CrosswakeExample.LocalFirst.Study do
  @moduledoc false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def list_events, do: Repo.all(ReviewEvent)

  @spec apply_one(String.t(), map(), map()) :: {:ok, map()} | {:error, atom()}
  def apply_one(scope_ref, event, _authority) when is_binary(scope_ref) and is_map(event) do
    id = Map.get(event, "client_mutation_id")

    Ecto.Multi.new()
    |> Ecto.Multi.run(:idempotency, fn repo, _changes ->
      case repo.get_by(ReviewEvent, scope_ref: scope_ref, client_mutation_id: id) do
        nil -> {:ok, :new}
        %ReviewEvent{} = record -> {:ok, {:duplicate, record}}
      end
    end)
    |> Ecto.Multi.run(:effect, fn repo, %{idempotency: state} ->
      case state do
        {:duplicate, record} ->
          {:ok, record}

        :new ->
          %ReviewEvent{}
          |> ReviewEvent.changeset(Map.put(event, "scope_ref", scope_ref))
          |> repo.insert()
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{effect: record}} ->
        {:ok, %{client_mutation_id: record.client_mutation_id, outcome: :accepted}}

      {:error, _operation, _reason, _changes} ->
        {:error, :transaction_failed}
    end
  end

  def apply_one(_, _, _), do: {:error, :invalid_envelope}
end
