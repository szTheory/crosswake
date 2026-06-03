defmodule CrosswakeExample.Chimeway.RegistryNotificationOpenTest do
  use ExUnit.Case

  alias CrosswakeExample.Chimeway.Registry
  alias CrosswakeExample.Chimeway.NotificationOpenIntent
  alias CrosswakeExample.Chimeway.NotificationOpenIntentEvent
  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias CrosswakeExample.Repo
  import Ecto.Query

  # We use unique keys to avoid SQLite locking/collision issues in parallel test execution
  defp unique_ref(prefix), do: "#{prefix}_#{:erlang.unique_integer([:positive])}"

  setup do
    open_ref = unique_ref("open")
    binding_ref = unique_ref("bnd")

    # Create a dummy active binding so the check "not revoked" passes, although we might need an actual binding row?
    # Actually, let's see if consume_intent checks the token binding table!
    # "ensure the referenced Chimeway binding is not revoked" -> decision D-04
    # Let's insert a binding first
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    binding = %CrosswakeExample.Chimeway.TokenBinding{
      binding_ref: binding_ref,
      subject_scope: :subject_installation,
      subject_ref: unique_ref("sub"),
      org_ref: unique_ref("org"),
      installation_ref: "install_123",
      provider: :apns,
      platform: :ios,
      environment: :production,
      token_ref: unique_ref("tok"),
      token_fingerprint: unique_ref("fp"),
      notification_status: :granted,
      state: :active,
      reason: :initial_bind,
      audit_correlation_ref: unique_ref("corr"),
      bound_at: now,
      last_seen_at: now
    }
    binding = Repo.insert!(binding)

    %{open_ref: open_ref, binding_ref: binding_ref, binding: binding}
  end

  test "issue_notification_open_intent/2 creates an intent and event", %{open_ref: open_ref, binding_ref: binding_ref} do
    attrs = %{
      open_ref: open_ref,
      binding_ref: binding_ref,
      route_id: "dashboard",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    assert {:ok, %{intent: intent, event: event}} = Registry.issue_notification_open_intent(attrs)

    assert intent.open_ref == open_ref
    assert intent.state == "issued"
    assert event.event_type == "issued"
    assert event.open_intent_id == intent.id
  end

  test "consume_intent/1 structurally rejects expired intent", %{open_ref: open_ref, binding_ref: binding_ref} do
    attrs = %{
      open_ref: open_ref,
      binding_ref: binding_ref,
      route_id: "dashboard",
      expires_at: DateTime.add(DateTime.utc_now(), -3600, :second)
    }
    {:ok, %{intent: _}} = Registry.issue_notification_open_intent(attrs)

    evidence = %NotificationOpenEvidence{
      route_id: "dashboard",
      open_ref: open_ref,
      binding_ref: binding_ref,
      provider: :apns,
      action_ref: "tap",
      auth_context: %{}
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :expired
  end

  test "consume_intent/1 validates binding_ref mismatch", %{open_ref: open_ref, binding_ref: binding_ref} do
    attrs = %{
      open_ref: open_ref,
      binding_ref: binding_ref,
      route_id: "dashboard",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }
    Registry.issue_notification_open_intent(attrs)

    evidence = %NotificationOpenEvidence{
      route_id: "dashboard",
      open_ref: open_ref,
      binding_ref: "other_binding", # mismatch
      provider: :apns,
      action_ref: "tap",
      auth_context: %{}
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :binding_mismatch
  end

  test "consume_intent/1 successfully consumes an issued intent", %{open_ref: open_ref, binding_ref: binding_ref} do
    attrs = %{
      open_ref: open_ref,
      binding_ref: binding_ref,
      route_id: "dashboard",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }
    Registry.issue_notification_open_intent(attrs)

    evidence = %NotificationOpenEvidence{
      route_id: "dashboard",
      open_ref: open_ref,
      binding_ref: binding_ref,
      provider: :apns,
      action_ref: "tap",
      auth_context: %{}
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :valid

    intent = Repo.get_by!(NotificationOpenIntent, open_ref: open_ref)
    assert intent.state == "consumed"
    assert intent.consumed_at != nil

    event = Repo.one(from e in NotificationOpenIntentEvent, where: e.open_intent_id == ^intent.id and e.event_type == "consumed")
    assert event != nil
  end

  test "consume_intent/1 rejects a revoked binding", %{open_ref: open_ref, binding: binding} do
    # Revoke the binding
    binding |> Ecto.Changeset.change(%{state: :revoked}) |> Repo.update!()

    attrs = %{
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      route_id: "dashboard",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }
    Registry.issue_notification_open_intent(attrs)

    evidence = %NotificationOpenEvidence{
      route_id: "dashboard",
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      provider: :apns,
      action_ref: "tap",
      auth_context: %{}
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :revoked
  end
end
