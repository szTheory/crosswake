defmodule CrosswakeExample.LocalFirst.StudyTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.LocalFirst.{ReviewEvent, Study}
  alias CrosswakeExample.Repo

  @scope "v1.scope_fixture_alpha_01"

  setup do
    Repo.delete_all(ReviewEvent)
    id = "study-#{System.unique_integer([:positive])}"
    on_exit(fn -> Repo.delete_all(ReviewEvent) end)
    %{event: %{"client_mutation_id" => id, "card_id" => 1, "rating" => "good"}}
  end

  test "accepted retry returns accepted while committing one scope-qualified effect", %{
    event: event
  } do
    assert {:ok, %{outcome: :accepted}} = Study.apply_one(@scope, event, %{})
    assert {:ok, %{outcome: :accepted}} = Study.apply_one(@scope, event, %{})
    assert Repo.aggregate(ReviewEvent, :count, :id) == 1
  end

  test "a pre-scope accepted event remains a global idempotency tombstone", %{event: event} do
    assert {:ok, legacy} =
             %ReviewEvent{}
             |> Ecto.Changeset.change(%{
               client_mutation_id: event["client_mutation_id"],
               card_id: event["card_id"],
               rating: event["rating"],
               status: "accepted",
               scope_ref: nil
             })
             |> Repo.insert()

    assert legacy.scope_ref == nil
    assert {:ok, %{outcome: :accepted}} = Study.apply_one(@scope, event, %{})
    assert [%ReviewEvent{id: id, scope_ref: nil}] = Repo.all(ReviewEvent)
    assert id == legacy.id
  end

  test "rollback leaves neither an idempotency decision nor a domain effect", %{event: event} do
    assert {:error, :transaction_failed} = Study.apply_one(@scope, event, %{rollback: true})
    assert Repo.aggregate(ReviewEvent, :count, :id) == 0

    assert {:ok, %{outcome: :accepted}} = Study.apply_one(@scope, event, %{})
    assert Repo.aggregate(ReviewEvent, :count, :id) == 1
  end

  test "a mutation ID owned by another scope is retained as a closed conflict", %{event: event} do
    other_scope = "v1.scope_fixture_beta_01"

    assert {:ok, %{outcome: :accepted}} = Study.apply_one(other_scope, event, %{})
    assert {:error, :scope_conflict} = Study.apply_one(@scope, event, %{})
    assert Repo.aggregate(ReviewEvent, :count, :id) == 1
  end

  test "concurrent same-scope retries commit one effect and return closed acceptance", %{
    event: event
  } do
    results =
      1..2
      |> Task.async_stream(fn _ -> Study.apply_one(@scope, event, %{}) end,
        max_concurrency: 2,
        timeout: 5_000,
        ordered: false
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert Enum.all?(results, &match?({:ok, %{outcome: :accepted}}, &1))
    assert Repo.aggregate(ReviewEvent, :count, :id) == 1
  end
end
