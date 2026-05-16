defmodule Crosswake.Offline.ReplayTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Journal
  alias Crosswake.Offline.Replay

  test "replay requests are typed and route-scoped from journal entries" do
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

    request = Replay.request_for_entry(entry)

    assert request.route_id == "study-session"
    assert request.sync_seam == "study_reviews"
    assert request.journal_entry_id == "journal-01"
    assert request.idempotency_key == "study-session:mutation-01"
  end

  test "replay outcomes are explicit accepted rejected or conflict results" do
    request =
      Replay.new_request(
        route_id: "study-session",
        sync_seam: "study_reviews",
        journal_entry_id: "journal-01",
        client_mutation_id: "mutation-01",
        idempotency_key: "study-session:mutation-01",
        base_checkpoint: "deck-42:v7",
        payload: %{"card_id" => "card-1", "grade" => "hard"}
      )

    accepted =
      Replay.accepted(
        request,
        checkpoint: "deck-42:v8",
        authoritative_state: %{"streak" => 8}
      )

    rejected = Replay.rejected(request, reason: "validation_failed")
    conflict = Replay.conflict(request, checkpoint: "deck-42:v9", reason: "checkpoint_mismatch")

    assert accepted.status == :accepted
    assert accepted.checkpoint == "deck-42:v8"
    assert accepted.authoritative_state == %{"streak" => 8}
    assert rejected.status == :rejected
    assert rejected.reason == "validation_failed"
    assert conflict.status == :conflict
    assert conflict.reason == "checkpoint_mismatch"
  end
end
