defmodule Crosswake.Packs.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Packs.Contracts
  alias Crosswake.Packs.Inventory

  test "pack lifecycle states encode install verify availability stale invalidation and failure metadata" do
    available =
      Contracts.available(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.2.0",
        bytes: 2048,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 09:00:00Z]
      )

    installing =
      Contracts.installing(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        stage: :verifying
      )

    stale =
      Contracts.stale(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.1.0",
        bytes: 2048,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 08:00:00Z],
        stale_reason: :version_mismatch
      )

    failed =
      Contracts.failed(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        failure_reason: :checksum_mismatch,
        retry_hint: :retry
      )

    assert available.state == :available
    assert available.verification.verified_at == ~U[2026-05-17 09:00:00Z]
    assert available.verification.integrity_status == :verified

    assert installing.state == :installing
    assert installing.install.stage == :verifying

    assert stale.state == :stale
    assert stale.stale_reason == :version_mismatch

    assert failed.state == :failed
    assert failed.failure.reason == :checksum_mismatch
    assert failed.failure.retry_hint == :retry
  end

  test "installed-pack inventory records required version installed version bytes integrity and verification timestamp" do
    record =
      Inventory.record(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.2.0",
        bytes: 4096,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 10:00:00Z]
      )

    assert record.pack_id == "lesson_library"
    assert record.required_version == "1.2.0"
    assert record.installed_version == "1.2.0"
    assert record.bytes == 4096
    assert record.integrity_status == :verified
    assert record.verified_at == ~U[2026-05-17 10:00:00Z]
  end

  test "invalidation preserves the last known state for deterministic retry or update paths" do
    record =
      Inventory.record(
        pack_id: "lesson_library",
        required_version: "1.2.0",
        installed_version: "1.2.0",
        bytes: 4096,
        integrity_status: :verified,
        verified_at: ~U[2026-05-17 10:00:00Z]
      )

    available = Contracts.from_inventory(record)

    invalidating =
      Contracts.invalidate(
        available,
        reason: :manifest_replaced,
        invalidated_at: ~U[2026-05-17 11:00:00Z]
      )

    assert invalidating.state == :invalidating
    assert invalidating.invalidation.reason == :manifest_replaced
    assert invalidating.invalidation.invalidated_at == ~U[2026-05-17 11:00:00Z]
    assert invalidating.last_known_state.state == :available
    assert invalidating.last_known_state.version == "1.2.0"
  end
end
