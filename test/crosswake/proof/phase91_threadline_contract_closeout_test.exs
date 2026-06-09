defmodule Crosswake.Proof.Phase91ThreadlineContractCloseoutTest do
  use ExUnit.Case, async: false

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Denial
  alias Crosswake.Shell.Activation
  alias Crosswake.Threadline.Telemetry

  # Phase 91 closeout: lock the full published Threadline telemetry contract
  # (event names, metadata allowlist, forbidden-key denylist) plus the envelope
  # @version bump to 1.1.0 and thread_id field presence on all four envelopes.
  # Mirrors the phase58 closeout pattern (exact-list equality, forbidden-key
  # membership, execute/3 PII rejection via attached handler).

  test "Threadline.Telemetry event_names/0 is exactly the three request-span names" do
    assert Telemetry.event_names() == [
             [:crosswake, :threadline, :request, :start],
             [:crosswake, :threadline, :request, :stop],
             [:crosswake, :threadline, :request, :exception]
           ]
  end

  test "Threadline.Telemetry metadata_keys/0 is exactly the PROP-02 four-key allowlist" do
    assert Telemetry.metadata_keys() == [:thread_id, :correlation_id, :route_id, :source]
  end

  test "forbidden_metadata_keys/0 contains required PII fields and is disjoint from metadata_keys/0" do
    forbidden = Telemetry.forbidden_metadata_keys()
    allowed = Telemetry.metadata_keys()

    assert :actor_ref in forbidden
    assert :access_token in forbidden
    assert :user_agent in forbidden

    # forbidden and allowed must be disjoint
    assert MapSet.disjoint?(MapSet.new(forbidden), MapSet.new(allowed))
  end

  test "Telemetry.execute/3 returns :ok and strips forbidden keys from handler-received metadata" do
    handler_id = "phase91-closeout-pii-guard"
    parent = self()

    :telemetry.attach(
      handler_id,
      [:crosswake, :threadline, :request, :start],
      fn _name, _measurements, meta, _config ->
        send(parent, {:telemetry_meta, meta})
      end,
      nil
    )

    result =
      Telemetry.execute(
        [:crosswake, :threadline, :request, :start],
        %{},
        %{access_token: "secret-value", thread_id: "t-closeout-1", correlation_id: "corr-1"}
      )

    :telemetry.detach(handler_id)

    assert result == :ok

    assert_receive {:telemetry_meta, received_meta}, 1000

    assert Map.has_key?(received_meta, :thread_id)
    refute Map.has_key?(received_meta, :access_token)
  end

  test "Bridge.Contract.version/0 is 1.1.0 after Phase 91 Plan 02 version bump" do
    assert Contract.version() == "1.1.0"
  end

  test "all four envelope structs construct with thread_id field defaulting to nil" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-closeout"
      )

    assert %Contract.Request{thread_id: nil} = request

    reply = Contract.ok_reply(request, %{})
    assert %Contract.Reply{thread_id: nil} = reply

    shell_denial =
      Crosswake.Shell.Denial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch"
      )

    denial = Denial.from_request(request, shell_denial)
    assert %Denial{thread_id: nil} = denial

    activation_request =
      Activation.new_request(
        source: :cold_start,
        origin: "https://example.crosswake.invalid",
        manifest_source: :bundled,
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-act-closeout"
      )

    assert %Activation.Request{thread_id: nil} = activation_request
  end

  test "thread_id propagates through from-request helpers (PROP-04 wire-envelope foundation)" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-prop",
        thread_id: "thread-prop-1"
      )

    ok_reply = Contract.ok_reply(request, %{})
    assert ok_reply.thread_id == "thread-prop-1"

    shell_denial =
      Crosswake.Shell.Denial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch"
      )

    denial = Crosswake.Bridge.Denial.from_request(request, shell_denial)
    assert denial.thread_id == "thread-prop-1"

    deny_reply = Contract.deny_reply(request, denial)
    assert deny_reply.thread_id == "thread-prop-1"
  end
end
