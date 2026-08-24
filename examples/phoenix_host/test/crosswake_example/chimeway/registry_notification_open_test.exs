defmodule CrosswakeExample.Chimeway.RegistryNotificationOpenTest do
  use ExUnit.Case, async: false

  alias CrosswakeExample.Chimeway.Registry
  alias CrosswakeExample.Chimeway.NotificationOpenIntent
  alias CrosswakeExample.Chimeway.NotificationOpenIntentEvent
  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias CrosswakeExample.Repo
  alias Crosswake.Companions.Chimeway.Resolver
  alias Crosswake.Manifest.Types.{Compatibility, Host, Root, RouteEntry}
  import Ecto.Query

  defp unique_ref(prefix) do
    "#{prefix}_#{System.system_time(:nanosecond)}_#{System.unique_integer([:positive])}"
  end

  defp auth_context(binding) do
    %{
      tenant_ref: binding.org_ref,
      subject_ref: binding.subject_ref,
      session_ref: binding.session_ref,
      session_version: binding.session_version
    }
  end

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
      subject_scope: :subject_session,
      subject_ref: unique_ref("sub"),
      org_ref: unique_ref("org"),
      session_ref: unique_ref("session"),
      session_version: 1,
      installation_ref: unique_ref("install"),
      provider: :apns,
      platform: :ios,
      environment: :production,
      app_identity_posture: :unknown,
      app_identity_ref: unique_ref("app"),
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

  test "issue_notification_open_intent/2 creates an intent and event", %{
    open_ref: open_ref,
    binding_ref: binding_ref
  } do
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

  test "consume_intent/1 structurally rejects expired intent", %{
    open_ref: open_ref,
    binding_ref: binding_ref,
    binding: binding
  } do
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
      auth_context: auth_context(binding)
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :expired
  end

  test "consume_intent/1 validates binding_ref mismatch", %{
    open_ref: open_ref,
    binding_ref: binding_ref
  } do
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
      binding_ref: unique_ref("other_binding"),
      provider: :apns,
      action_ref: "tap",
      auth_context: %{}
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :binding_mismatch
  end

  test "consume_intent/1 successfully consumes an issued intent", %{
    open_ref: open_ref,
    binding_ref: binding_ref,
    binding: binding
  } do
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
      auth_context: auth_context(binding)
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :valid

    intent = Repo.get_by!(NotificationOpenIntent, open_ref: open_ref)
    assert intent.state == "consumed"
    assert intent.consumed_at != nil

    event =
      Repo.one(
        from(e in NotificationOpenIntentEvent,
          where: e.open_intent_id == ^intent.id and e.event_type == "consumed"
        )
      )

    assert event != nil
    assert resolution.route_id == "dashboard"
    assert resolution.action_ref == "tap"
  end

  test "one default tap is consumed, authorized, and then denied as replay", %{
    open_ref: open_ref,
    binding_ref: binding_ref,
    binding: binding
  } do
    {:ok, %{intent: _}} =
      Registry.issue_notification_open_intent(%{
        open_ref: open_ref,
        binding_ref: binding_ref,
        route_id: "home",
        action_ref: "tap",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    manifest =
      struct(Root,
        compatibility:
          struct(Compatibility,
            manifest_schema_version: "2.0.0",
            bridge_protocol_version: "1.0.0",
            native_runtime_version: "1.0.0",
            supported_manifest_sources: [:bundled],
            remote_updates: []
          ),
        capability_registry: %{},
        host:
          struct(Host,
            phoenix_version: "1.7.0",
            live_view_version: "1.0.0",
            manifest_sources: [:bundled],
            origin: "https://test.example"
          ),
        routes: %{
          "home" => %RouteEntry{
            id: "home",
            path: "/home",
            runtime: :liveview,
            notification_open: %{actions: ["tap"]},
            entry: :external
          }
        }
      )

    evidence = %NotificationOpenEvidence{
      route_id: "untrusted-client-route",
      open_ref: open_ref,
      binding_ref: binding_ref,
      provider: :apns,
      action_ref: "untrusted-client-action",
      auth_context: auth_context(binding)
    }

    assert {:allow, decision} = Resolver.resolve(manifest, evidence, Registry)
    assert decision.route_id == "home"

    assert {:deny, denial} = Resolver.resolve(manifest, evidence, Registry)
    assert denial.code == "notification.open.replayed"
  end

  test "consume_intent/1 returns the stored action instead of client action", %{
    open_ref: open_ref,
    binding_ref: binding_ref,
    binding: binding
  } do
    attrs = %{
      open_ref: open_ref,
      binding_ref: binding_ref,
      route_id: "dashboard",
      action_ref: "approve",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    Registry.issue_notification_open_intent(attrs)

    evidence = %NotificationOpenEvidence{
      route_id: "dashboard",
      open_ref: open_ref,
      binding_ref: binding_ref,
      provider: :apns,
      action_ref: "tap",
      auth_context: auth_context(binding)
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :valid
    assert resolution.route_id == "dashboard"
    assert resolution.action_ref == "approve"
  end

  test "consume_intent/1 rejects a revoked binding", %{open_ref: open_ref, binding: binding} do
    attrs = %{
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      route_id: "dashboard",
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
    }

    Registry.issue_notification_open_intent(attrs)

    # Revoke the exact binding after issue; queued evidence must not become authority.
    binding |> Ecto.Changeset.change(%{state: :revoked}) |> Repo.update!()

    evidence = %NotificationOpenEvidence{
      route_id: "dashboard",
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      provider: :apns,
      action_ref: "tap",
      auth_context: auth_context(binding)
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :binding_revoked
  end

  test "consume_intent/1 does not consume an intent after its tenant authority changes", %{
    open_ref: open_ref,
    binding: binding
  } do
    {:ok, %{intent: intent}} =
      Registry.issue_notification_open_intent(%{
        open_ref: open_ref,
        binding_ref: binding.binding_ref,
        route_id: "dashboard",
        action_ref: "tap",
        tenant_ref: binding.org_ref,
        subject_ref: binding.subject_ref,
        session_ref: binding.session_ref,
        session_version: binding.session_version,
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    evidence = %NotificationOpenEvidence{
      route_id: "untrusted-client-route",
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      provider: :apns,
      action_ref: "untrusted-client-action",
      auth_context: %{
        tenant_ref: unique_ref("other_tenant"),
        subject_ref: binding.subject_ref,
        session_ref: binding.session_ref,
        session_version: binding.session_version
      }
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :binding_mismatch
    assert Repo.get!(NotificationOpenIntent, intent.id).state == "issued"

    assert Repo.aggregate(
             from(e in NotificationOpenIntentEvent, where: e.open_intent_id == ^intent.id),
             :count,
             :id
           ) == 1
  end

  test "consume_intent/1 does not consume an intent after its session version changes", %{
    open_ref: open_ref,
    binding: binding
  } do
    {:ok, %{intent: intent}} =
      Registry.issue_notification_open_intent(%{
        open_ref: open_ref,
        binding_ref: binding.binding_ref,
        route_id: "dashboard",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    evidence = %NotificationOpenEvidence{
      route_id: "untrusted-client-route",
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      provider: :apns,
      action_ref: "tap",
      auth_context: %{auth_context(binding) | session_version: binding.session_version + 1}
    }

    assert {:ok, resolution} = Registry.consume_intent(evidence)
    assert resolution.state == :binding_mismatch
    assert Repo.get!(NotificationOpenIntent, intent.id).state == "issued"
  end

  test "concurrent consumers have one valid winner, one replay, and one consumed event", %{
    open_ref: open_ref,
    binding: binding
  } do
    {:ok, %{intent: intent}} =
      Registry.issue_notification_open_intent(%{
        open_ref: open_ref,
        binding_ref: binding.binding_ref,
        route_id: "dashboard",
        action_ref: "approve",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    evidence = %NotificationOpenEvidence{
      route_id: "untrusted-client-route",
      open_ref: open_ref,
      binding_ref: binding.binding_ref,
      provider: :apns,
      action_ref: "untrusted-client-action",
      auth_context: auth_context(binding)
    }

    results =
      [
        Task.async(fn -> Registry.consume_intent(evidence) end),
        Task.async(fn -> Registry.consume_intent(evidence) end)
      ]
      |> Enum.map(&Task.await(&1, 5_000))

    assert Enum.count(results, fn {:ok, resolution} -> resolution.state == :valid end) == 1
    assert Enum.count(results, fn {:ok, resolution} -> resolution.state == :replayed end) == 1
    assert Repo.get!(NotificationOpenIntent, intent.id).state == "consumed"

    assert Repo.aggregate(
             from(e in NotificationOpenIntentEvent,
               where: e.open_intent_id == ^intent.id and e.event_type == "consumed"
             ),
             :count,
             :id
           ) == 1
  end
end
