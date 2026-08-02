defmodule CrosswakeExample.E2E.SyncStateControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Ecto.Query, warn: false

  alias CrosswakeExample.Repo
  alias CrosswakeExample.LocalFirst.ReviewEvent

  # Generate unique IDs per test run for deterministic cleanup
  defp unique_id(suffix), do: "test-#{System.unique_integer([:positive])}-#{suffix}"

  test "count is scoped to client_mutation_id — not a whole-table aggregate" do
    id_a = unique_id("a")
    id_b = unique_id("b")

    # Insert two rows with DISTINCT client_mutation_id values
    {:ok, _} =
      Repo.insert(
        ReviewEvent.changeset(%ReviewEvent{}, %{
          scope_ref: "v1.scope_fixture_alpha_01",
          client_mutation_id: id_a,
          card_id: 1,
          rating: "good",
          status: "accepted"
        })
      )

    {:ok, _} =
      Repo.insert(
        ReviewEvent.changeset(%ReviewEvent{}, %{
          scope_ref: "v1.scope_fixture_alpha_01",
          client_mutation_id: id_b,
          card_id: 2,
          rating: "hard",
          status: "rejected"
        })
      )

    on_exit(fn ->
      ids = [id_a, id_b]
      Repo.delete_all(from(r in ReviewEvent, where: r.client_mutation_id in ^ids))
    end)

    # Exercise the real controller show/2 directly — avoids ConnCase dependency
    conn_a = build_conn()

    conn_a =
      CrosswakeExample.E2E.SyncStateController.show(conn_a, %{"client_mutation_id" => id_a})

    body_a = Jason.decode!(conn_a.resp_body)

    # count MUST be 1 — if it were a whole-table aggregate it would be >= 2
    assert body_a["synced"] == true
    assert body_a["count"] == 1

    # Exercise for id_b independently — also count == 1
    conn_b = build_conn()

    conn_b =
      CrosswakeExample.E2E.SyncStateController.show(conn_b, %{"client_mutation_id" => id_b})

    body_b = Jason.decode!(conn_b.resp_body)

    assert body_b["synced"] == true
    assert body_b["count"] == 1
  end

  test "non-existent client_mutation_id returns synced: false, count: 0" do
    missing_id = unique_id("missing")
    conn = build_conn()

    conn =
      CrosswakeExample.E2E.SyncStateController.show(conn, %{"client_mutation_id" => missing_id})

    body = Jason.decode!(conn.resp_body)

    assert body["synced"] == false
    assert body["count"] == 0
  end
end
