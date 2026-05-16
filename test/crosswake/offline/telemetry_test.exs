defmodule Crosswake.Offline.TelemetryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Telemetry

  test "telemetry contract carries stable route-level metadata and terminal outcomes" do
    event =
      Telemetry.new_event(
        name: :terminal_outcome,
        route_id: "study-session",
        runtime: :offline_island,
        offline_mode: :local_first,
        sync_seam: "study_reviews",
        journal_entry_id: "journal-01",
        manifest_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-01",
        terminal_outcome: :conflict
      )

    assert :route_id in Telemetry.metadata_keys()
    assert :journal_entry_id in Telemetry.metadata_keys()
    assert Telemetry.terminal_outcomes() == [:accepted, :rejected, :conflict]
    assert event.sync_seam == "study_reviews"
    assert event.journal_entry_id == "journal-01"
    assert event.terminal_outcome == :conflict
  end
end
