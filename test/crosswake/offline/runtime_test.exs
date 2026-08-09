defmodule Crosswake.Offline.RuntimeTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Contracts
  alias Crosswake.Offline.Journal
  alias Crosswake.Offline.Runtime

  test "runtime names sqlite-backed cached hydration and study-session draft and journal durability on ios and android" do
    cache_contract = Contracts.new_cache_route("lesson_library_v1", route_id: "library")

    island_contract =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :manual
      )

    hydration = Runtime.cached_hydration(cache_contract)
    session = Runtime.study_session(island_contract)

    assert hydration.route_id == "library"
    assert hydration.storage == :sqlite
    assert hydration.hydration == :sqlite_snapshot
    assert hydration.writable == false

    assert session.route_id == "study-session"
    assert session.storage == :sqlite
    assert session.draft_surface == :study_session_draft
    assert session.journal_mode == :append_only
    assert session.replay_mode == :explicit
    assert session.platforms == [:ios, :android]
  end

  test "runtime queueing preserves phoenix-authoritative reconciliation rather than direct local mutation" do
    island_contract =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :manual
      )

    session = Runtime.study_session(island_contract)

    entry =
      Journal.new_entry(
        id: "journal-01",
        scope_ref: "v1.scope_fixture_alpha_01",
        route_id: "study-session",
        sync_seam: "study_reviews",
        operation: :grade_card,
        payload: %{"card_id" => "card-1", "grade" => "hard"},
        client_mutation_id: "mutation-01",
        idempotency_key: "study-session:mutation-01",
        base_checkpoint: "deck-42:v7"
      )

    assert session.authoritative_source == :phoenix
    assert session.direct_server_mutation == false
    assert {:ok, queued} = Runtime.queue_entry(session, entry)
    assert queued.status == :queued
  end

  test "runtime starts inert and fences an old scope before another activates" do
    inactive = Runtime.new_lifecycle()

    assert inactive.state == :inactive
    assert inactive.epoch == 0
    assert {:error, :scope_inactive} = Runtime.lease(inactive, "v1.scope_fixture_alpha_01", 0)

    assert {:ok, active} = Runtime.activate(inactive, "v1.scope_fixture_alpha_01")
    assert {:ok, _lease} = Runtime.lease(active, "v1.scope_fixture_alpha_01", 1)

    fenced = Runtime.fence(active)
    assert fenced.state == :inactive
    assert fenced.epoch == 2
    assert {:error, :scope_inactive} = Runtime.lease(fenced, "v1.scope_fixture_alpha_01", 1)
    assert {:ok, switched} = Runtime.activate(fenced, "v1.scope_fixture_bravo_01")
    assert {:error, :stale_lease} = Runtime.lease(switched, "v1.scope_fixture_alpha_01", 1)
    assert {:ok, _lease} = Runtime.lease(switched, "v1.scope_fixture_bravo_01", 3)
  end

  test "runtime retains unaccepted entries in journal order when replay is blocked" do
    entries = [:first, :second, :third]

    assert {:halted, [:second, :third]} =
             Runtime.drain(entries, fn
               :first -> :accepted
               :second -> :blocked
               :third -> :accepted
             end)
  end
end
