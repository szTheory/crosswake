defmodule CrosswakeExample.LocalFirst.SyncController do
  use Phoenix.Controller, formats: [:json]
  alias CrosswakeExample.LocalFirst.Study

  def sync(conn, %{"events" => events}) when is_list(events) do
    case Study.sync_events(events) do
      {:ok, result} ->
        json(conn, %{data: result})
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: to_string(reason)})
    end
  end

  def sync(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid payload, expected 'events' list"})
  end
end
