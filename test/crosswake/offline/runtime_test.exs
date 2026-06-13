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
end
