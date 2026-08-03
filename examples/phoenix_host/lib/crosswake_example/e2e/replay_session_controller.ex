defmodule CrosswakeExample.E2E.ReplaySessionController do
  @moduledoc false

  use Phoenix.Controller, formats: [:json]

  import Plug.Conn

  @session_key :e2e_replay_session

  def create(conn, %{"action" => "establish"}),
    do: store(conn, %{"state" => "current", "principal" => "primary"})

  def create(conn, %{"action" => "switch"}),
    do: store(conn, %{"state" => "current", "principal" => "secondary"})

  def create(conn, %{"action" => "revoke"}), do: store(conn, %{"state" => "revoked"})

  def create(conn, %{"action" => "clear"}) do
    conn
    |> delete_session(@session_key)
    |> json(%{data: %{state: "updated"}})
  end

  def create(conn, _params),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: %{class: "invalid_request"}})

  defp store(conn, session) do
    conn
    |> put_session(@session_key, session)
    |> put_status(:created)
    |> json(%{data: %{state: "updated"}})
  end
end
