defmodule CrosswakeExample.LocalFirst.Study do
  @moduledoc false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def list_events, do: Repo.all(ReviewEvent)

  @spec apply_one(String.t(), map(), map()) :: {:ok, map()} | {:error, atom()}
  def apply_one(scope_ref, event, authority) when is_binary(scope_ref) and is_map(event) do
    id = Map.get(event, "client_mutation_id")

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
    |> Repo.transaction()
    |> case do
      {:ok, %{effect: :scope_conflict}} ->
        {:error, :scope_conflict}

      {:ok, %{effect: _record}} ->
        {:ok, %{client_mutation_id: id, outcome: :accepted}}

      {:error, _operation, _reason, _changes} ->
        {:error, :transaction_failed}
    end
  end

  def apply_one(_, _, _), do: {:error, :invalid_envelope}
end
