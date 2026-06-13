defmodule CrosswakeExample.E2E.SyncStateController do
  use Phoenix.Controller

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def show(conn, %{"client_mutation_id" => id}) do
    case Repo.get_by(ReviewEvent, client_mutation_id: id) do
      nil ->
        json(conn, %{synced: false})
      record ->
        json(conn, %{synced: true, status: record.status})
    end
  end
end
