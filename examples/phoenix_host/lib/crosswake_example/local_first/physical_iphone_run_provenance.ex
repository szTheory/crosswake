defmodule CrosswakeExample.LocalFirst.PhysicalIphoneRunProvenance do
  @moduledoc false

  # This is a host-private, process-local proof ticket. It is deliberately not a
  # Crosswake contract and is never serialized into a device or evidence report.
  @table __MODULE__

  def start do
    ticket = %{
      nonce: opaque(),
      mutation_id:
        "00000000-0000-4000-8000-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower),
      state: :issued
    }

    true = :ets.insert_new(table(), {ticket.nonce, ticket})
    {:ok, ticket}
  rescue
    _ -> {:error, :unavailable}
  end

  def claim(nonce, mutation_id) when is_binary(nonce) and is_binary(mutation_id) do
    case :ets.take(table(), nonce) do
      [{^nonce, %{mutation_id: ^mutation_id, state: :issued} = ticket}] ->
        true = :ets.insert(table(), {nonce, %{ticket | state: :claimed}})
        :ok

      [{^nonce, ticket}] ->
        true = :ets.insert(table(), {nonce, ticket})
        {:error, :unavailable}

      [] ->
        {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def active?(nonce, mutation_id) when is_binary(nonce) and is_binary(mutation_id) do
    match?([{^nonce, %{mutation_id: ^mutation_id, state: :claimed}}], :ets.lookup(table(), nonce))
  rescue
    _ -> false
  end

  def cleanup(%{nonce: nonce}) when is_binary(nonce) do
    :ets.delete(table(), nonce)
    :ok
  rescue
    _ -> :ok
  end

  def cleanup(_), do: :ok

  defp table do
    case :ets.whereis(@table) do
      :undefined ->
        try do
          :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
        rescue
          ArgumentError -> @table
        end

      _ ->
        @table
    end
  end

  defp opaque, do: Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)
end
