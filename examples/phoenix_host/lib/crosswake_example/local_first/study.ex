defmodule CrosswakeExample.LocalFirst.Study do
  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def list_events do
    Repo.all(ReviewEvent)
  end

  def sync_events(events_payload) when is_list(events_payload) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {valid, rejections} =
      Enum.reduce(events_payload, {[], []}, fn payload, {valid_acc, rejections_acc} ->
        changeset = ReviewEvent.changeset(%ReviewEvent{}, payload)
        
        if changeset.valid? do
          map = 
            Ecto.Changeset.apply_changes(changeset)
            |> Map.from_struct()
            |> Map.drop([:__meta__, :id])
            |> Map.put(:inserted_at, now)
            |> Map.put(:updated_at, now)
            
          {[map | valid_acc], rejections_acc}
        else
          id = Map.get(payload, "client_mutation_id") || Map.get(payload, :client_mutation_id)
          errors = format_errors(changeset)
          {valid_acc, [%{client_mutation_id: id, errors: errors} | rejections_acc]}
        end
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:sync, ReviewEvent, Enum.reverse(valid),
      on_conflict: :nothing,
      conflict_target: :client_mutation_id,
      returning: true
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{sync: {count, records}}} ->
        {:ok, %{accepted_count: count, accepted_records: records, rejected: Enum.reverse(rejections)}}

      {:error, _, reason, _} ->
        {:error, reason}
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
