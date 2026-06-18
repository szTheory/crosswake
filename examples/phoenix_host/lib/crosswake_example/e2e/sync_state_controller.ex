defmodule CrosswakeExample.E2E.SyncStateController do
  @moduledoc """
  Test-only endpoint for asserting server-side sync state in E2E specs.

  Mounted only in :test and :e2e environments (see router.ex ~line 378).
  Never mounted in :prod. See Phase 114 GUARD-02 for the enforced assertion.
  """
  use Phoenix.Controller, formats: [:json]

  import Ecto.Query, warn: false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  def show(conn, %{"client_mutation_id" => id}) do
    # count MUST be scoped to the id — bare aggregate counts the whole table (> 1 in multi-test runs)
    count =
      from(r in ReviewEvent, where: r.client_mutation_id == ^id)
      |> Repo.aggregate(:count, :id)

    case Repo.get_by(ReviewEvent, client_mutation_id: id) do
      nil ->
        json(conn, %{synced: false, count: 0})

      record ->
        json(conn, %{synced: true, status: record.status, count: count})
    end
  end
end
