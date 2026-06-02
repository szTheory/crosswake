defmodule Crosswake.Companions.Chimeway.TelemetryTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Chimeway.Telemetry

  @event_names [
    [:crosswake, :notification, :token, :observed],
    [:crosswake, :notification, :token, :bound],
    [:crosswake, :notification, :token, :rotated],
    [:crosswake, :notification, :token, :revoked],
    [:crosswake, :notification, :token, :stale],
    [:crosswake, :notification, :token, :invalidated],
    [:crosswake, :notification, :provider, :feedback]
  ]

  test "exposes exact ordered event names and metadata keys" do
    assert Telemetry.event_names() == @event_names

    assert Telemetry.metadata_keys() == [
             :provider,
             :platform,
             :environment,
             :state,
             :reason,
             :feedback_event,
             :notification_status,
             :app_identity_posture,
             :subject_scope,
             :proof_class,
             :correlation_id
           ]
  end

  test "drops forbidden atom and string keys while retaining safe metadata" do
    metadata =
      Telemetry.metadata(%{
        :provider => :apns,
        "platform" => :ios,
        :environment => :sandbox,
        :state => :active,
        :reason => :initial_bind,
        :feedback_event => :token_unregistered,
        :notification_status => :granted,
        :app_identity_posture => :matched,
        :subject_scope => :user,
        :proof_class => :hermetic,
        :correlation_id => "corr_123",
        :token => "raw_apns_token_should_not_leak_123",
        "raw_token" => "raw_apns_token_should_not_leak_123",
        :provider_payload => %{body: "secret"},
        "provider_response_body" => "secret"
      })

    assert metadata == %{
             provider: :apns,
             platform: :ios,
             environment: :sandbox,
             state: :active,
             reason: :initial_bind,
             feedback_event: :token_unregistered,
             notification_status: :granted,
             app_identity_posture: :matched,
             subject_scope: :user,
             proof_class: :hermetic,
             correlation_id: "corr_123"
           }
  end

  test "drops long strings negative integers unknown values and nils" do
    long = String.duplicate("x", 129)

    assert Telemetry.metadata(%{
             correlation_id: long,
             proof_class: :hermetic,
             state: -1,
             reason: nil,
             unknown: :value
           }) == %{proof_class: :hermetic}
  end

  test "serializes events without raw token aliases or provider payload bodies" do
    event =
      Telemetry.new_event(
        name: [:crosswake, :notification, :provider, :feedback],
        provider: :fcm,
        platform: :android,
        environment: :production,
        feedback_event: :provider_unavailable,
        proof_class: :hermetic
      )

    assert Telemetry.to_map(event) == %{
             "name" => "crosswake.notification.provider.feedback",
             "provider" => :fcm,
             "platform" => :android,
             "environment" => :production,
             "feedback_event" => :provider_unavailable,
             "proof_class" => :hermetic
           }
  end

  test "execute sanitizes metadata before emitting telemetry" do
    handler = self()
    event = [:crosswake, :notification, :token, :observed]

    :telemetry.attach(
      "chimeway-telemetry-test",
      event,
      fn _event, measurements, metadata, _config ->
        send(handler, {:telemetry, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach("chimeway-telemetry-test") end)

    assert :ok =
             Telemetry.execute(event, %{count: 1}, %{
               provider: :apns,
               token: "raw_apns_token_should_not_leak_123"
             })

    assert_receive {:telemetry, %{count: 1}, %{provider: :apns}}
  end
end
