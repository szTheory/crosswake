defmodule Crosswake.Packs.RuntimeTest do
  use ExUnit.Case, async: true

  alias Crosswake.Packs.Inventory
  alias Crosswake.Packs.Runtime

  test "runtime derives available when the installed pack matches version and integrity truth" do
    record =
      Inventory.record(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.2.0",
        bytes: 2048,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 10:00:00Z]
      )

    lifecycle = Runtime.lifecycle("lesson_library@1.2.0", record)

    assert lifecycle.state == :available
    assert lifecycle.verification.integrity_status == :verified
  end

  test "runtime derives stale when installed version drifts from manifest truth" do
    record =
      Inventory.record(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.1.0",
        bytes: 2048,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 10:00:00Z]
      )

    lifecycle = Runtime.lifecycle("lesson_library@1.2.0", record)

    assert lifecycle.state == :stale
    assert lifecycle.stale_reason == :version_mismatch
  end

  test "runtime preserves last known available state when an inventory record is invalidated" do
    record =
      Inventory.record(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.2.0",
        bytes: 2048,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 10:00:00Z],
        status: :invalidating,
        invalidation_reason: :operator_reset,
        invalidated_at: ~U[2026-05-17 11:00:00Z],
        last_known_state: %{state: :available, version: "1.2.0"}
      )

    lifecycle = Runtime.lifecycle("lesson_library@1.2.0", record)

    assert lifecycle.state == :invalidating
    assert lifecycle.invalidation.reason == :operator_reset
    assert lifecycle.last_known_state == %{state: :available, version: "1.2.0"}
  end

  test "runtime exposes failed lifecycle when integrity verification is missing" do
    lifecycle =
      Runtime.lifecycle(
        "lesson_library@1.2.0",
        Inventory.record(
          pack_id: "lesson_library",
          required_version: "1.2.0",
          installed_version: "1.2.0",
          bytes: 2048,
          integrity_status: :pending,
          verified_at: nil
        )
      )

    assert lifecycle.state == :failed
    assert lifecycle.failure.reason == :verification_missing
  end
end
