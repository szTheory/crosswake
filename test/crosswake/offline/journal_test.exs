defmodule Crosswake.Offline.JournalTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Journal

  test "journal entries are immutable and carry replay metadata" do
    committed_at = DateTime.from_naive!(~N[2026-05-16 22:00:00], "Etc/UTC")

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
        base_checkpoint: "deck-42:v7",
        committed_at: committed_at
      )

    assert entry.route_id == "study-session"
    assert entry.scope_ref == "v1.scope_fixture_alpha_01"
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

  test "journal entries require a bounded versioned opaque scope without echoing rejected input" do
    invalid_scope = "v1.scope fixture with spaces"

    error =
      assert_raise ArgumentError, "CW-OFFLINE-SCOPE-REF", fn ->
        Journal.new_entry(
          id: "journal-invalid-scope",
          scope_ref: invalid_scope,
          route_id: "study-session",
          sync_seam: "study_reviews",
          operation: :grade_card,
          client_mutation_id: "mutation-invalid-scope",
          idempotency_key: "study-session:mutation-invalid-scope",
          base_checkpoint: "deck-42:v7"
        )
      end

    refute Exception.message(error) =~ invalid_scope
  end

  test "journal entries reject a missing scope with the same stable rule" do
    assert_raise ArgumentError, "CW-OFFLINE-SCOPE-REF", fn ->
      Journal.new_entry(
        id: "journal-missing-scope",
        route_id: "study-session",
        sync_seam: "study_reviews",
        operation: :grade_card,
        client_mutation_id: "mutation-missing-scope",
        idempotency_key: "study-session:mutation-missing-scope",
        base_checkpoint: "deck-42:v7"
      )
    end
  end
end
