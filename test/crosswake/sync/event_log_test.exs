defmodule Crosswake.Sync.EventLogTest do
  use ExUnit.Case, async: true

  alias Crosswake.Sync.EventLog.Entry

  describe "new_entry/1" do
    test "creates a valid Entry struct given valid attributes" do
      attrs = [
        idempotency_key: "key-123",
        route_id: "route-1",
        sync_seam: "seam-1",
        operation: :create,
        status: :queued
      ]

      entry = Crosswake.Sync.EventLog.new_entry(attrs)

      assert %Entry{} = entry
      assert entry.idempotency_key == "key-123"
      assert entry.route_id == "route-1"
      assert entry.sync_seam == "seam-1"
      assert entry.operation == :create
      assert entry.status == :queued
      assert entry.payload == %{} # default empty map
    end

    test "enforces required keys" do
      # Missing route_id
      attrs = [
        idempotency_key: "key-123",
        sync_seam: "seam-1",
        operation: :create,
        status: :queued
      ]

      assert_raise KeyError, fn ->
        Crosswake.Sync.EventLog.new_entry(attrs)
      end
    end
  end
end
