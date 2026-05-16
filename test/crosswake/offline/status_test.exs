defmodule Crosswake.Offline.StatusTest do
  use ExUnit.Case, async: true

  alias Crosswake.Offline.Status

  test "cached stale and local-first replay states are clearly distinct" do
    assert :cached_read_only in Status.states()
    assert :stale in Status.states()
    assert :saved_locally in Status.states()
    assert :queued_for_replay in Status.states()
  end

  test "conflict-required and replay-failed states carry hints without changing the stable vocabulary" do
    failed = Status.new(:replay_failed, hint: "retry when connectivity returns")
    conflict = Status.new(:conflict_requires_attention, details: %{route_id: "study-session"})

    assert failed.state == :replay_failed
    assert failed.hint == "retry when connectivity returns"
    assert conflict.state == :conflict_requires_attention
    assert conflict.details == %{route_id: "study-session"}
  end
end
