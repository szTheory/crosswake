defmodule Crosswake.Offline.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Contracts

  test "the study-session island contract names its sync seam, draft surface, queueing posture, and checkpoint requirements explicitly" do
    contract =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :manual
      )

    assert contract.route_id == "study-session"
    assert contract.sync_seam == "study_reviews"
    assert contract.draft_surface == :study_session_draft
    assert contract.storage == :sqlite
    assert contract.journal_mode == :append_only
    assert contract.reconciliation == :explicit
    assert contract.checkpoint_requirement == :required
    assert contract.authoritative_source == :phoenix
    assert contract.storage_budget == 50_000_000
    assert contract.reserve_for_journal == 5_000_000
    assert contract.eviction == :manual
  end

  test "new_study_session_island/2 parses storage_budget and reserve_for_journal from {:mb, X} to integer bytes" do
    contract =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 100},
        reserve_for_journal: {:mb, 10},
        eviction: :volatile
      )

    assert contract.storage_budget == 100_000_000
    assert contract.reserve_for_journal == 10_000_000
  end

  test "new_study_session_island/2 strictly validates the eviction policy (accepts only :volatile or :manual)" do
    assert_raise ArgumentError, "invalid eviction policy: :invalid_policy. Allowed: :volatile or :manual", fn ->
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :invalid_policy
      )
    end
  end

  test "creating a contract without these new required fields raises an error" do
    assert_raise KeyError, fn ->
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews"
      )
    end
  end

  test "cached routes carry explicit sqlite-backed hydration posture" do
    contract = Contracts.new_cache_route("lesson_library_v1", route_id: "library")

    assert contract.route_id == "library"
    assert contract.hydration == :sqlite_snapshot
    assert contract.storage == :sqlite
    assert contract.restrictions == [:read_only, :server_authoritative]
  end
end
