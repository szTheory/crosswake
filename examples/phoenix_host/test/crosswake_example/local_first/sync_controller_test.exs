defmodule CrosswakeExample.LocalFirst.SyncControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias CrosswakeExample.LocalFirst.{ReviewEvent, SyncController}
  alias CrosswakeExample.Repo

  @scope "v1.scope_fixture_alpha_01"

  setup do
    Repo.delete_all(ReviewEvent)
    on_exit(fn -> Repo.delete_all(ReviewEvent) end)
    :ok
  end

  test "a changed feature state prevents event N while retaining earlier accepted effects" do
    events = [event("one"), event("two")]
    counter = :counters.new(1, [])

    feature = fn _route ->
      :counters.add(counter, 1, 1)
      if :counters.get(counter, 1) == 1, do: :allow, else: :deny
    end

    assert {:ok, %{accepted_records: [%{client_mutation_id: "one"}], halted: :feature_disabled}} =
             SyncController.sync_events(build_conn(), @scope, events, feature: feature)

    assert Repo.aggregate(ReviewEvent, :count, :id) == 1
  end

  test "wholly blocked input has a typed non-success envelope" do
    conn =
      SyncController.sync(build_conn(), %{"scope_ref" => "invalid", "events" => [event("one")]})

    assert conn.status == 403
    assert %{"error" => %{"class" => "invalid_envelope"}} = Jason.decode!(conn.resp_body)
  end

  test "a persisted rejection stays out of the accepted prefix and halts later events" do
    assert {:ok, rejected} =
             %ReviewEvent{}
             |> Ecto.Changeset.change(%{
               client_mutation_id: "rejected",
               card_id: 1,
               rating: "good",
               status: "rejected",
               scope_ref: @scope
             })
             |> Repo.insert()

    assert {:ok,
            %{
              accepted_records: [],
              rejected: [%{client_mutation_id: "rejected", outcome: :rejected}],
              halted: :rejected
            }} =
             SyncController.sync_events(build_conn(), @scope, [event("rejected"), event("later")])

    assert [^rejected] = Repo.all(ReviewEvent)
  end

  defp event(id), do: %{"client_mutation_id" => id, "card_id" => 1, "rating" => "good"}
end
