defmodule Crosswake.Offline.JournalTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Journal

  test "scope suffix boundaries and rejected diagnostics have a closed value-free contract" do
    suffix = String.duplicate("a", 16)
    canary = Enum.join(["REJECTED", "SCOPE", "PROBE"], "-")

    cases = [
      {:suffix_15, "v1." <> String.duplicate("a", 15), :reject},
      {:suffix_16, "v1." <> suffix, :accept},
      {:suffix_128, "v1." <> String.duplicate("a", 128), :accept},
      {:suffix_129, "v1." <> String.duplicate("a", 129), :reject},
      {:ascii_alphabet, "v1." <> "Az09_-" <> suffix, :accept},
      {:lf, "v1." <> suffix <> "\n", :reject},
      {:crlf, "v1." <> suffix <> "\r\n", :reject},
      {:embedded_lf, "v1." <> suffix <> "\n" <> canary, :reject},
      {:prefix, canary <> "v1." <> suffix, :reject},
      {:suffix, "v1." <> suffix <> "." <> canary, :reject},
      {:nul, "v1." <> suffix <> <<0>>, :reject},
      {:spaces, "v1." <> suffix <> " " <> canary, :reject},
      {nil, nil, :reject},
      {:integer, 16, :reject},
      {:float, 16.0, :reject},
      {:list, ["v1.", suffix, canary], :reject},
      {:map, %{probe: canary}, :reject},
      {:atom, :invalid_scope, :reject},
      {:empty, "", :reject},
      {:singleton, "v1.x", :reject},
      {:multibyte, "v1." <> String.duplicate("é", 16), :reject},
      {:lookalike, "v1." <> String.duplicate("а", 16), :reject},
      {:version_lookalike, "ｖ1." <> suffix, :reject},
      {:invalid_encoding, "v1." <> suffix <> <<255>>, :reject}
    ]

    assert length(cases) == 24
    assert MapSet.size(MapSet.new(cases, &elem(&1, 0))) == 24
    assert Enum.count(cases, &(elem(&1, 2) == :accept)) == 3

    for {id, input, verdict} <- cases do
      if verdict == :accept do
        assert Journal.scope_ref!(input) == input, "scope case #{id}"
      else
        output =
          ExUnit.CaptureLog.capture_log(fn ->
            error =
              assert_raise ArgumentError, "CW-OFFLINE-SCOPE-REF", fn ->
                Journal.scope_ref!(input)
              end

            assert Map.from_struct(error) == %{
                     message: "CW-OFFLINE-SCOPE-REF",
                     __exception__: true
                   }

            assert inspect(error) == "%ArgumentError{message: \"CW-OFFLINE-SCOPE-REF\"}"

            assert Exception.format_banner(:error, error) ==
                     "** (ArgumentError) CW-OFFLINE-SCOPE-REF"

            proof = Jason.encode!(%{case_id: id, result: "rejected", rule: error.message})
            refute proof =~ canary
            refute inspect(error) =~ canary
          end)

        assert output == "", "scope case #{id} emitted a log"
      end
    end
  end

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
