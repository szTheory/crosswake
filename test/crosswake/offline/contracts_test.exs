defmodule Crosswake.Offline.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Contracts

  test "the study-session island contract names its sync seam, draft surface, queueing posture, and checkpoint requirements explicitly" do
    contract =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews"
      )

    assert contract.route_id == "study-session"
    assert contract.sync_seam == "study_reviews"
    assert contract.draft_surface == :study_session_draft
    assert contract.storage == :sqlite
    assert contract.journal_mode == :append_only
    assert contract.reconciliation == :explicit
    assert contract.checkpoint_requirement == :required
    assert contract.authoritative_source == :phoenix
  end

  test "cached routes carry explicit sqlite-backed hydration posture" do
    contract = Contracts.new_cache_route("lesson_library_v1", route_id: "library")

    assert contract.route_id == "library"
    assert contract.hydration == :sqlite_snapshot
    assert contract.storage == :sqlite
    assert contract.restrictions == [:read_only, :server_authoritative]
  end
end
