defmodule CrosswakeExample.LocalFirst.Study do
  @moduledoc false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def list_events, do: Repo.all(ReviewEvent)

  @spec apply_one(String.t(), map(), map()) :: {:ok, map()} | {:error, atom()}
  def apply_one(scope_ref, event, authority) when is_binary(scope_ref) and is_map(event) do
    id = Map.get(event, "client_mutation_id")

    transaction =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:idempotency, fn repo, _changes ->
        case repo.get_by(ReviewEvent, client_mutation_id: id) do
          nil -> {:ok, :new}
          %ReviewEvent{scope_ref: nil} -> {:ok, :duplicate}
          %ReviewEvent{scope_ref: ^scope_ref} -> {:ok, :duplicate}
          %ReviewEvent{} -> {:ok, :scope_conflict}
        end
      end)
      |> Ecto.Multi.run(:effect, fn repo, %{idempotency: state} ->
        case state do
          :duplicate ->
            {:ok, :duplicate}

          :scope_conflict ->
            {:ok, :scope_conflict}

          :new ->
            if Map.get(authority, :rollback) do
              {:error, :forced_rollback}
            else
              %ReviewEvent{}
              |> ReviewEvent.changeset(Map.put(event, "scope_ref", scope_ref))
              |> repo.insert()
            end
        end
      end)

    transaction
    |> transact(scope_ref, id)
    |> case do
      {:race, result} ->
        result

      {:ok, %{effect: :scope_conflict}} ->
        {:error, :scope_conflict}

      {:ok, %{effect: :duplicate}} ->
        current_outcome(scope_ref, id)

      {:ok, %{effect: %ReviewEvent{}}} ->
        {:ok, %{client_mutation_id: id, outcome: :accepted}}

      {:error, _operation, _reason, _changes} ->
        current_outcome(scope_ref, id)
    end
  end

  def apply_one(_, _, _), do: {:error, :invalid_envelope}

  defp transact(transaction, scope_ref, id) do
    Repo.transaction(transaction)
  rescue
    Exqlite.Error -> {:race, race_outcome(scope_ref, id)}
  end

  defp current_outcome(scope_ref, id) do
    case Repo.get_by(ReviewEvent, client_mutation_id: id) do
      %ReviewEvent{scope_ref: nil} = review_event -> persisted_outcome(review_event, id)
      %ReviewEvent{scope_ref: ^scope_ref} = review_event -> persisted_outcome(review_event, id)
      %ReviewEvent{} -> {:error, :scope_conflict}
      nil -> {:error, :transaction_failed}
    end
  end

  defp persisted_outcome(%ReviewEvent{status: "accepted"}, id),
    do: {:ok, %{client_mutation_id: id, outcome: :accepted}}

  defp persisted_outcome(%ReviewEvent{status: "rejected"}, id),
    do: {:ok, %{client_mutation_id: id, outcome: :rejected}}

  defp persisted_outcome(_review_event, _id), do: {:error, :invalid_persisted_outcome}

  defp race_outcome(scope_ref, id, attempts \\ 3)

  defp race_outcome(scope_ref, id, attempts) do
    case current_outcome(scope_ref, id) do
      {:error, :transaction_failed} when attempts > 0 ->
        Process.sleep(10)
        race_outcome(scope_ref, id, attempts - 1)

      result ->
        result
    end
  end
end
