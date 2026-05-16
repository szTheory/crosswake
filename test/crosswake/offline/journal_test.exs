defmodule Crosswake.Offline.JournalTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Journal

  test "journal entries are immutable and carry replay metadata" do
    committed_at = DateTime.from_naive!(~N[2026-05-16 22:00:00], "Etc/UTC")

    entry =
      Journal.new_entry(
        id: "journal-01",
        route_id: "study-session",
        sync_seam: "study_reviews",
        operation: :grade_card,
        payload: %{"card_id" => "card-1", "grade" => "hard"},
        client_mutation_id: "mutation-01",
        idempotency_key: "study-session:mutation-01",
        base_checkpoint: "deck-42:v7",
        committed_at: committed_at
      )

    assert entry.route_id == "study-session"
    assert entry.sync_seam == "study_reviews"
    assert entry.client_mutation_id == "mutation-01"
    assert entry.idempotency_key == "study-session:mutation-01"
    assert entry.base_checkpoint == "deck-42:v7"
    assert entry.status == :queued
    assert entry.committed_at == committed_at

    replaying = Journal.replaying(entry)

    assert replaying.status == :replaying
    assert entry.status == :queued
  end
end
