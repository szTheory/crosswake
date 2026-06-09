defmodule Crosswake.Threadline.TelemetryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Threadline.Telemetry

  # -----------------------------------------------------------------------
  # Contract: event names — exact list equality (published contract)
  # -----------------------------------------------------------------------

  test "event_names/0 returns exactly the three request-span names" do
    assert Telemetry.event_names() == [
             [:crosswake, :threadline, :request, :start],
             [:crosswake, :threadline, :request, :stop],
             [:crosswake, :threadline, :request, :exception]
           ]
  end

  # -----------------------------------------------------------------------
  # Contract: metadata keys — exact list equality (PROP-02 fixed set)
  # -----------------------------------------------------------------------

  test "metadata_keys/0 returns exactly [:thread_id, :correlation_id, :route_id, :source]" do
    assert Telemetry.metadata_keys() == [:thread_id, :correlation_id, :route_id, :source]
  end

  # -----------------------------------------------------------------------
  # Contract: forbidden_metadata_keys — includes PII fields and is disjoint from allowlist
  # -----------------------------------------------------------------------

  test "forbidden_metadata_keys/0 includes expected PII fields" do
    forbidden = Telemetry.forbidden_metadata_keys()
    assert :actor_ref in forbidden
    assert :access_token in forbidden
    assert :email in forbidden
    assert :ip in forbidden
    assert :user_agent in forbidden
    assert :session_ref in forbidden
    assert :subject_ref in forbidden
  end

  test "forbidden_metadata_keys/0 is disjoint from metadata_keys/0" do
    forbidden = MapSet.new(Telemetry.forbidden_metadata_keys())
    allowed = MapSet.new(Telemetry.metadata_keys())
    intersection = MapSet.intersection(forbidden, allowed)
    assert MapSet.size(intersection) == 0,
           "Overlap between forbidden and allowed keys: #{inspect(MapSet.to_list(intersection))}"
  end

  # -----------------------------------------------------------------------
  # Contract: metadata/1 — drops forbidden keys, unknown keys, nil values
  # -----------------------------------------------------------------------

  test "metadata/1 keeps only allowlisted safe keys and drops forbidden and unknown keys" do
    metadata =
      Telemetry.metadata(%{
        thread_id: "tid-safe",
        correlation_id: "cid-safe",
        route_id: "my-route",
        source: :inbound,
        access_token: "secret",
        actor_ref: "pii-ref",
        email: "user@example.com",
        user_agent: "Mozilla/5.0",
        session_ref: "sess_secret",
        subject_ref: "sub_secret",
        unknown_high_cardinality: "do not include",
        another_unknown: 12_345
      })

    assert metadata == %{
             thread_id: "tid-safe",
             correlation_id: "cid-safe",
             route_id: "my-route",
             source: :inbound
           }
  end

  test "metadata/1 does not raise on forbidden keys — silent drop" do
    assert %{} = Telemetry.metadata(%{access_token: "secret", actor_ref: "pii"})
  end

  # -----------------------------------------------------------------------
  # Contract: metadata/1 — nil-valued allowlisted keys are dropped
  # -----------------------------------------------------------------------

  test "metadata/1 drops nil-valued allowlisted keys" do
    metadata =
      Telemetry.metadata(%{
        thread_id: nil,
        correlation_id: "cid-ok",
        route_id: nil,
        source: nil
      })

    assert metadata == %{correlation_id: "cid-ok"}
  end

  # -----------------------------------------------------------------------
  # Contract: safe_value?/1 — cardinality bound on binary values (128 chars)
  # -----------------------------------------------------------------------

  test "metadata/1 drops a >128-char binary value for an allowlisted key" do
    long_value = String.duplicate("x", 129)
    metadata = Telemetry.metadata(%{thread_id: long_value})
    refute Map.has_key?(metadata, :thread_id)
  end

  test "metadata/1 keeps a binary value of exactly 128 chars for an allowlisted key" do
    exact_value = String.duplicate("x", 128)
    metadata = Telemetry.metadata(%{thread_id: exact_value})
    assert metadata == %{thread_id: exact_value}
  end

  # -----------------------------------------------------------------------
  # Contract: valid_event_name?/1
  # -----------------------------------------------------------------------

  test "valid_event_name?/1 returns true for a declared event name" do
    assert Telemetry.valid_event_name?([:crosswake, :threadline, :request, :start])
    assert Telemetry.valid_event_name?([:crosswake, :threadline, :request, :stop])
    assert Telemetry.valid_event_name?([:crosswake, :threadline, :request, :exception])
  end

  test "valid_event_name?/1 returns false for an undeclared event name" do
    refute Telemetry.valid_event_name?([:crosswake, :threadline, :bridge, :start])
    refute Telemetry.valid_event_name?([:crosswake, :auth, :session, :evaluate, :start])
    refute Telemetry.valid_event_name?(:not_a_list)
  end

  # -----------------------------------------------------------------------
  # Contract: execute/3 — routes metadata through metadata/1, forbidden keys absent
  # -----------------------------------------------------------------------

  test "execute/3 with forbidden metadata returns :ok and does not raise" do
    event_name = [:crosswake, :threadline, :request, :start]
    handler_id = "test-threadline-telemetry-#{System.unique_integer()}"

    :telemetry.attach(
      handler_id,
      event_name,
      fn ^event_name, _measurements, metadata, _config ->
        send(self(), {:telemetry_received, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    result =
      Telemetry.execute(
        event_name,
        %{duration: 42},
        %{
          thread_id: "tid-ok",
          correlation_id: "cid-ok",
          access_token: "should-be-dropped",
          actor_ref: "pii-should-be-dropped",
          email: "pii@example.com"
        }
      )

    assert result == :ok

    assert_receive {:telemetry_received, received_metadata}
    refute Map.has_key?(received_metadata, :access_token)
    refute Map.has_key?(received_metadata, :actor_ref)
    refute Map.has_key?(received_metadata, :email)
    assert received_metadata[:thread_id] == "tid-ok"
    assert received_metadata[:correlation_id] == "cid-ok"
  end
end
