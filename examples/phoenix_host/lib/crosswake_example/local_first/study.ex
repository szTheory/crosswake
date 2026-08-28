defmodule CrosswakeExample.LocalFirst.Study do
  @moduledoc false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def list_events, do: Repo.all(ReviewEvent)

  @spec apply_one(String.t(), map(), map()) :: {:ok, map()} | {:error, atom()}
  def apply_one(scope_ref, event, authority) when is_binary(scope_ref) and is_map(event) do
    id = Map.get(event, "client_mutation_id")

    with :ok <- authorize(authority) do
      Ecto.Multi.new()
      |> Ecto.Multi.run(:effect, fn repo, _changes ->
        if Map.get(authority, :rollback) do
          {:error, :forced_rollback}
        else
          %ReviewEvent{}
          |> ReviewEvent.changeset(persistence_attrs(scope_ref, event))
          |> repo.insert()
        end
      end)
      |> transact(scope_ref, id)
      |> outcome_after_insert(scope_ref, id)
    end
  end

  def apply_one(_, _, _), do: {:error, :invalid_envelope}

  defp persistence_attrs(scope_ref, event) do
    event
    |> Map.take([
      "client_mutation_id",
      "card_id",
      "rating",
      "free_form_answer",
      "physical_proof_nonce"
    ])
    |> Map.put("scope_ref", scope_ref)
  end

  defp authorize(%{denied: true}), do: {:error, :authority_denied}
  defp authorize(_authority), do: :ok

  defp transact(transaction, scope_ref, id) do
    Repo.transaction(transaction)
  rescue
    Exqlite.Error -> {:race, race_outcome(scope_ref, id)}
  end

  defp outcome_after_insert({:race, result}, _scope_ref, _id), do: result

  defp outcome_after_insert({:ok, %{effect: %ReviewEvent{}}}, _scope_ref, id),
    do: {:ok, %{client_mutation_id: id, outcome: :accepted}}

  # Ecto surfaces the named global and scoped uniqueness constraints as a
  # changeset error. The persisted row is read only after that failed insert,
  # so the database — not a speculative query — remains idempotency authority.
  defp outcome_after_insert({:error, :effect, %Ecto.Changeset{}, _changes}, scope_ref, id),
    do: race_outcome(scope_ref, id)

  defp outcome_after_insert({:error, _operation, _reason, _changes}, scope_ref, id),
    do: current_outcome(scope_ref, id)

  defp current_outcome(scope_ref, id) do
    case Repo.get_by(ReviewEvent, client_mutation_id: id) do
      %ReviewEvent{scope_ref: nil} -> {:error, :scope_conflict}
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
