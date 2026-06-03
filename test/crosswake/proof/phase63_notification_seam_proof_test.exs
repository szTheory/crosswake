defmodule Crosswake.Proof.Phase63NotificationSeamProofTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Phase 63 merge-blocking proof for the notification seam.
  Validates token binding, open intent resolution, routing policy, and telemetry redaction.
  """

  # Shells into examples/phoenix_host via System.cmd; excluded from hermetic CI
  # lanes (deps not built there) and run locally, matching the project convention.
  @moduletag :requires_example_host

  test "end-to-end notification seam proof: binding, intent resolution, and telemetry redaction" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_notification_seam_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias CrosswakeExample.Chimeway.Registry
    alias Crosswake.Companions.Chimeway.Resolver
    alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
    alias Crosswake.Manifest.Types.Root
    alias Crosswake.Manifest.Types.RouteEntry

    # 1. Attach Telemetry for Token Bound
    telemetry_pid = self()
    handler_id = "phase63-seam-proof-handler"
    :telemetry.attach(
      handler_id,
      [:crosswake, :notification, :token, :bound],
      fn event_name, _measurements, metadata, _config ->
        send(telemetry_pid, {:telemetry_fired, event_name, metadata})
      end,
      nil
    )

    # 2. Simulate Token Binding
    context = %{
      subject_scope: :subject_session,
      subject_ref: "sub_user_1",
      org_ref: "org_1",
      session_ref: "sess_1",
      session_version: 1,
      installation_ref: "inst_1",
      actor_kind: :backend,
      correlation_id: "corr_bind_1"
    }

    # Include a synthetic raw token to prove it does not leak
    evidence = %{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      installation_ref: "inst_1",
      token_ref: "tok_ref_1",
      token_fingerprint: "hmac-sha256:fingerprint_abc",
      notification_status: :granted,
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      app_identity_posture: :matched,
      metadata: %{
        apns_token: "synthetic_raw_token_that_must_not_leak_12345",
        safe_key: "safe_value"
      }
    }

    {:ok, bind_result} = Registry.bind_or_rotate(context, evidence)
    binding_ref = bind_result.binding.binding_ref

    # 3. Assert Telemetry Redaction
    assert_receive {:telemetry_fired, [:crosswake, :notification, :token, :bound], metadata}, 1000

    # Metadata should have safe keys and no raw tokens
    assert metadata.provider == :apns
    refute Map.has_key?(metadata, :apns_token)
    refute Map.has_key?(metadata, "apns_token")

    # Ensure raw tokens do not leak via inspect
    inspected = inspect(bind_result)
    refute String.contains?(inspected, "synthetic_raw_token_that_must_not_leak_12345"),
           "inspect output must not contain raw token value"

    # 4. Issue Notification Open Intent
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires = DateTime.add(now, 3600, :second)
    intent_attrs = %{
      open_ref: "open_ref_123",
      binding_ref: binding_ref,
      route_id: "route_test_1",
      action_ref: "action_view",
      state: "issued",
      issued_at: now,
      expires_at: expires
    }

    {:ok, %{intent: intent}} = Registry.issue_notification_open_intent(intent_attrs)

    # 5. Resolve Intent using Resolver (simulates arriving evidence)
    open_evidence = %NotificationOpenEvidence{
      route_id: "route_test_1",
      open_ref: intent.open_ref,
      binding_ref: binding_ref,
      provider: :apns,
      action_ref: "action_view",
      auth_context: %{subject_ref: "sub_user_1"}
    }

    manifest = %Root{
      manifest_schema_version: "1.0.0",
      crosswake_version: "0.1.0",
      generated_at: DateTime.to_iso8601(DateTime.utc_now()),
      host: %Crosswake.Manifest.Types.Host{
        phoenix_version: "1.7.0",
        live_view_version: "0.19.0",
        origin: "https://example.com",
        manifest_sources: [:bundled]
      },
      compatibility: %Crosswake.Manifest.Types.Compatibility{
        manifest_schema_version: "1.0.0",
        bridge_protocol_version: "1.0.0",
        native_runtime_version: "1.0.0",
        supported_manifest_sources: [:bundled],
        remote_updates: []
      },
      support_matrix: %Crosswake.Manifest.Types.SupportMatrix{
        phoenix: [],
        live_view: [],
        ios: [],
        android: [],
        shells: [],
        capability_families: [],
        package_surfaces: [],
        release_boundaries: [],
        change_classes: []
      },
      capability_registry: %{},
      pack_registry: %{},
      commerce_corridors: %{},
      routes: %{
        "route_test_1" => %RouteEntry{
          id: "route_test_1",
          path: "/test",
          runtime: :shell,
          entry: :external,
          notification_open: [actions: ["action_view"]]
        }
      }
    }

    resolution_result = Resolver.resolve(manifest, open_evidence, Registry)

    # Ensure it allows the intent
    assert {:allow, decision} = resolution_result
    assert decision.status == :allow

    :telemetry.detach(handler_id)
    IO.puts("phase63-notification-seam-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase63-notification-seam-proof: ok"
  end
end
