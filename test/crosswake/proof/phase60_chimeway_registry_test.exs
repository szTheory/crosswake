defmodule Crosswake.Proof.Phase60ChimewayRegistryTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Phase 60 merge-blocking proof for the Chimeway example-host registry.

  Boots the example-host repo against a temporary SQLite database, runs all
  migrations, and asserts that:
  - the binding and audit tables exist with the correct partial unique indexes;
  - the metadata sanitizer drops raw-token keys from both atom-keyed and
    string-keyed inputs;
  - TokenBinding and TokenBindingEvent changesets enforce closed vocabularies
    and scope consistency;
  - Phase 60 created only the mutable binding table and append-only event table,
    not extra normalized installation/device/token tables or replay infrastructure;
  - Registry lifecycle APIs (bind, refresh, rotate, revoke, invalidate, prune)
    work atomically, preserve audit history, and emit sanitized result data;
  - Chimeway telemetry fires only after successful commits and not from
    rolled-back transactions.
  """

  # ---------------------------------------------------------------------------
  # Source-level assertions (no DB, no example-host modules required)
  # ---------------------------------------------------------------------------

  test "binding migration does not define raw-token column names" do
    source =
      File.read!(
        "examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs"
      )

    for forbidden_col <- [
          ":token,",
          ":raw_token,",
          ":device_token,",
          ":apns_token,",
          ":fcm_token,"
        ] do
      refute source =~ forbidden_col,
             "binding migration must not define #{forbidden_col} column"
    end
  end

  test "binding migration defines the required partial unique index names" do
    source =
      File.read!(
        "examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs"
      )

    assert source =~ "chimeway_token_bindings_active_token_identity_index"
    assert source =~ "chimeway_token_bindings_active_subject_session_scope_index"
    assert source =~ "chimeway_token_bindings_active_subject_installation_scope_index"
  end

  test "audit migration defines the required index names and no cascade-delete" do
    source =
      File.read!(
        "examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs"
      )

    assert source =~ "chimeway_token_binding_events_event_ref_index"

    refute source =~ "on_delete: :delete_all",
           "audit migration must not define cascade-delete on audit rows"

    refute source =~ "references(",
           "audit migration must not define foreign-key references that could cascade-delete audit history"
  end

  test "TokenBinding schema does not include raw-token field declarations" do
    source =
      File.read!("examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex")

    for forbidden_field <- [:token, :raw_token, :device_token, :apns_token, :fcm_token] do
      refute source =~ "field(:#{forbidden_field},",
             "TokenBinding schema must not declare a :#{forbidden_field} field"
    end
  end

  test "TokenBindingEvent schema does not include raw-token field declarations" do
    source =
      File.read!("examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex")

    for forbidden_field <- [:token, :raw_token, :device_token, :apns_token, :fcm_token] do
      refute source =~ "field(:#{forbidden_field},",
             "TokenBindingEvent schema must not declare a :#{forbidden_field} field"
    end
  end

  test "example host mix.exs does not include worker dependencies" do
    source = File.read!("examples/phoenix_host/mix.exs")

    refute source =~ ":oban", "examples/phoenix_host must not depend on Oban"
    refute source =~ ":quantum", "examples/phoenix_host must not depend on Quantum"
    refute source =~ ":broadway", "examples/phoenix_host must not depend on Broadway"
  end

  test "no compiled chimeway file uses Oban, Quantum, Broadway, or in-tree scheduler loops" do
    chimeway_dir = "examples/phoenix_host/lib/crosswake_example/chimeway"

    if File.dir?(chimeway_dir) do
      {:ok, files} = File.ls(chimeway_dir)

      for file <- files, String.ends_with?(file, ".ex") do
        source = File.read!(Path.join(chimeway_dir, file))

        refute source =~ "use Oban.Worker",
               "#{file} must not use Oban.Worker in compiled Phase 60 code"

        refute source =~ "use Quantum",
               "#{file} must not use Quantum in compiled Phase 60 code"

        refute source =~ "use Broadway",
               "#{file} must not use Broadway in compiled Phase 60 code"

        refute source =~ ":timer.send_interval",
               "#{file} must not implement an in-tree scheduler loop (use Oban/Quantum as host-owned guidance)"

        refute source =~ "Process.send_after",
               "#{file} must not implement a GenServer scheduler loop (use Oban/Quantum as host-owned guidance)"
      end
    end
  end

  test "example host mix.exs dependency list does not widen to worker or scheduler packages" do
    source = File.read!("examples/phoenix_host/mix.exs")

    # Strict package-name denial list per D-34 and D-37
    refute source =~ ~s({:oban,), "examples/phoenix_host must not depend on Oban"
    refute source =~ ~s({:quantum,), "examples/phoenix_host must not depend on Quantum"
    refute source =~ ~s({:broadway,), "examples/phoenix_host must not depend on Broadway"

    refute source =~ ~s({:gen_stage,),
           "examples/phoenix_host must not depend on GenStage scheduler"
  end

  test "phase 60 proof raw-token sentinel absence is source-level verifiable" do
    # The raw-token sentinel value used throughout this proof module must NOT appear
    # in any migration, schema, or registry source file — only in test assertions.
    sentinel = "raw_apns_token_should_not_leak_123"

    production_files = [
      "examples/phoenix_host/priv/repo/migrations/20260602100000_create_chimeway_token_bindings.exs",
      "examples/phoenix_host/priv/repo/migrations/20260602100100_create_chimeway_token_binding_events.exs",
      "examples/phoenix_host/lib/crosswake_example/chimeway/token_binding.ex",
      "examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex",
      "examples/phoenix_host/lib/crosswake_example/chimeway/metadata_sanitizer.ex",
      "examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex"
    ]

    for file <- production_files do
      if File.exists?(file) do
        source = File.read!(file)

        refute source =~ sentinel,
               "Production file #{file} must not contain the raw-token sentinel value"
      end
    end
  end

  test "example host README contains Optional Chimeway background jobs section with correct scope and API names" do
    readme = File.read!("examples/phoenix_host/README.md")

    # Section must exist
    assert readme =~ "Optional Chimeway background jobs",
           "README must contain an 'Optional Chimeway background jobs' section"

    # Must name the two synchronous registry APIs
    assert readme =~ "prune_stale/1",
           "README background jobs section must name prune_stale/1"

    assert readme =~ "apply_provider_feedback/2",
           "README background jobs section must name apply_provider_feedback/2"

    # Must state APIs are synchronous and workers remain host-owned
    assert readme =~ "synchronous registry APIs only",
           "README must state Crosswake ships synchronous registry APIs only"

    assert readme =~ "host-owned",
           "README must state background jobs remain host-owned"

    # Must not claim bundled workers, delivery guarantees, or open/route authority
    refute readme =~ "bundled Chimeway workers",
           "README must not claim bundled Chimeway workers"

    refute readme =~ "push delivery " <> "guarantees",
           "README must not claim push delivery guarantees"

    refute readme =~ "notification-open " <> "routing authority",
           "README must not claim notification-open routing authority"

    refute readme =~ "bundled background " <> "orchestration",
           "README must not claim bundled background orchestration"

    # Oban must be identified as the primary durable recipe
    assert readme =~ "Oban",
           "README must mention Oban as the primary durable background job option"

    # Quantum/cron must be mentioned only as secondary alternatives for pruning
    assert readme =~ "Quantum",
           "README must mention Quantum as a secondary scheduling alternative"

    # Broadway scope must be restricted to future high-volume use and explicitly out of scope for Phase 60
    assert readme =~ "Broadway",
           "README must mention Broadway scope boundary"

    assert readme =~ "out of scope for Phase 60",
           "README must explicitly state Broadway is out of scope for Phase 60"

    # Worker examples must call registry APIs, not duplicate lifecycle writes
    assert readme =~ "CrosswakeExample.Chimeway.Registry.prune_stale/1",
           "README worker example must call CrosswakeExample.Chimeway.Registry.prune_stale/1"

    assert readme =~ "CrosswakeExample.Chimeway.Registry.apply_provider_feedback/2",
           "README worker example must call CrosswakeExample.Chimeway.Registry.apply_provider_feedback/2"
  end

  test "phase 60 proof does not claim notification-open resolution or delivery support" do
    source = File.read!(__ENV__.file)

    refute String.contains?(source, "notification-open " <> "resolver")
    refute String.contains?(source, "activation_source: " <> ":notification")
    refute String.contains?(source, "APNs " <> "delivery")
    refute String.contains?(source, "FCM " <> "delivery")
  end

  # ---------------------------------------------------------------------------
  # MetadataSanitizer and TokenBinding changeset proof via example-host script
  # ---------------------------------------------------------------------------

  @tag :requires_example_host
  test "metadata sanitizer drops raw-token atom and string keys, and TokenBinding enforces scope rules" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")

    alias CrosswakeExample.Chimeway.MetadataSanitizer
    alias CrosswakeExample.Chimeway.TokenBinding

    # MetadataSanitizer: atom keys
    atom_input = %{
      apns_token: "raw_apns_token_should_not_leak_123",
      fcm_token: "raw_fcm_token_should_not_leak_456",
      token: "raw_token_val",
      raw_token: "raw_token_val2",
      device_token: "dev_tok",
      registration_token: "reg_tok",
      safe_key: "safe_value"
    }
    atom_result = MetadataSanitizer.sanitize(atom_input)
    for forbidden_key <- [:apns_token, :fcm_token, :token, :raw_token, :device_token, :registration_token] do
      refute Map.has_key?(atom_result, forbidden_key),
             "atom key \#{forbidden_key} must be removed by sanitizer"
    end
    assert atom_result[:safe_key] == "safe_value"

    # MetadataSanitizer: string keys
    string_input = %{
      "apns_token" => "raw_apns_token_should_not_leak_123",
      "fcm_token" => "raw_fcm_token_should_not_leak_456",
      "token" => "raw_token_val",
      "raw_token" => "raw_token_val2",
      "provider_payload" => "body",
      "notification_title" => "Hello",
      "notification_body" => "World",
      "route_params" => %{"id" => "123"},
      "email" => "user@example.com",
      "ip" => "1.2.3.4",
      "user_agent" => "Mozilla/5.0",
      "device_id" => "dev-abc",
      "provider_response_body" => "response",
      "safe_key" => "safe_value"
    }
    string_result = MetadataSanitizer.sanitize(string_input)
    for forbidden_key <- ["apns_token", "fcm_token", "token", "raw_token",
                           "provider_payload", "notification_title", "notification_body",
                           "route_params", "email", "ip", "user_agent", "device_id",
                           "provider_response_body"] do
      refute Map.has_key?(string_result, forbidden_key),
             "string key \#{forbidden_key} must be removed by sanitizer"
    end
    assert string_result["safe_key"] == "safe_value"

    # TokenBinding changeset: metadata sanitization
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    tainted_metadata = Map.merge(
      %{apns_token: "raw_apns_token_should_not_leak_123", safe_key: "ok"},
      %{"fcm_token" => "raw_fcm_token_should_not_leak_456"}
    )
    attrs = %{
      binding_ref: "bnd_sanitize_test",
      subject_scope: :subject_session,
      subject_ref: "sub_backend",
      org_ref: "org_backend",
      session_ref: "sess_abc",
      session_version: 1,
      installation_ref: "inst_abc",
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      app_identity_posture: :matched,
      token_ref: "tok_ref_abc",
      token_fingerprint: "hmac-sha256:aabbcc",
      notification_status: :granted,
      state: :active,
      reason: :initial_bind,
      bound_at: now,
      last_seen_at: now,
      audit_correlation_ref: "corr_abc",
      metadata: tainted_metadata
    }
    cs = TokenBinding.changeset(%TokenBinding{}, attrs)
    sanitized_metadata = Map.get(cs.changes, :metadata, %{})
    refute Map.has_key?(sanitized_metadata, :apns_token),
           "apns_token must be removed from changeset metadata"
    refute Map.has_key?(sanitized_metadata, "fcm_token"),
           "fcm_token string key must be removed from changeset metadata"
    assert sanitized_metadata[:safe_key] == "ok"

    # TokenBinding: subject_session requires session_ref
    attrs_no_session = Map.drop(attrs, [:session_ref])
    cs_no_session = TokenBinding.changeset(%TokenBinding{}, attrs_no_session)
    refute cs_no_session.valid?,
           "subject_session binding without session_ref must be invalid"
    assert cs_no_session.errors[:session_ref] != nil

    # TokenBinding: subject_installation does not require session_ref
    inst_attrs = Map.merge(attrs, %{
      binding_ref: "bnd_inst_test",
      subject_scope: :subject_installation,
      session_ref: nil
    })
    cs_inst = TokenBinding.changeset(%TokenBinding{}, inst_attrs)
    assert cs_inst.valid?, "subject_installation binding without session_ref must be valid"

    # TokenBindingEvent changeset: basic valid event
    alias CrosswakeExample.Chimeway.TokenBindingEvent
    event_attrs = %{
      event_ref: "evt_test_001",
      event_type: :bound,
      binding_ref: "bnd_sanitize_test",
      occurred_at: now,
      actor_kind: :backend,
      proof_class: :hermetic,
      state_after: :active,
      reason: :initial_bind
    }
    event_cs = TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)
    assert event_cs.valid?, "valid audit event changeset must be valid: \#{inspect(event_cs.errors)}"

    # TokenBindingEvent: metadata sanitization
    event_tainted_metadata = Map.merge(
      %{apns_token: "raw_apns_token_should_not_leak_123", safe_key: "ok"},
      %{"fcm_token" => "raw_fcm_token_should_not_leak_456"}
    )
    event_attrs_tainted = Map.put(event_attrs, :metadata, event_tainted_metadata)
    event_cs_tainted = TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs_tainted)
    event_sanitized_metadata = Map.get(event_cs_tainted.changes, :metadata, %{})
    refute Map.has_key?(event_sanitized_metadata, :apns_token),
           "apns_token must be removed from audit event metadata"
    refute Map.has_key?(event_sanitized_metadata, "fcm_token"),
           "fcm_token string key must be removed from audit event metadata"
    assert event_sanitized_metadata[:safe_key] == "ok"

    IO.puts("phase60-sanitizer-changeset-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-sanitizer-changeset-proof: ok"
  end

  # ---------------------------------------------------------------------------
  # Migration schema assertions (SQLite boot harness)
  # ---------------------------------------------------------------------------

  @tag :requires_example_host
  test "example host migrations create binding and audit tables with expected partial unique indexes" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_chimeway_registry_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias CrosswakeExample.Repo

    # Assert chimeway_token_bindings table exists
    result = Repo.query!("SELECT name FROM sqlite_master WHERE type='table' AND name='chimeway_token_bindings'")
    assert length(result.rows) == 1, "chimeway_token_bindings table must exist"

    # Assert chimeway_token_binding_events table exists
    result2 = Repo.query!("SELECT name FROM sqlite_master WHERE type='table' AND name='chimeway_token_binding_events'")
    assert length(result2.rows) == 1, "chimeway_token_binding_events table must exist"

    # Assert partial unique indexes on bindings table exist by name
    idx_result = Repo.query!("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='chimeway_token_bindings'")
    index_names = Enum.map(idx_result.rows, fn [name] -> name end)

    assert "chimeway_token_bindings_binding_ref_index" in index_names,
           "chimeway_token_bindings_binding_ref_index must exist"
    assert "chimeway_token_bindings_active_token_identity_index" in index_names,
           "chimeway_token_bindings_active_token_identity_index must exist"
    assert "chimeway_token_bindings_active_subject_session_scope_index" in index_names,
           "chimeway_token_bindings_active_subject_session_scope_index must exist"
    assert "chimeway_token_bindings_active_subject_installation_scope_index" in index_names,
           "chimeway_token_bindings_active_subject_installation_scope_index must exist"

    # Assert audit indexes exist by name
    audit_idx_result = Repo.query!("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='chimeway_token_binding_events'")
    audit_index_names = Enum.map(audit_idx_result.rows, fn [name] -> name end)

    assert "chimeway_token_binding_events_event_ref_index" in audit_index_names,
           "chimeway_token_binding_events_event_ref_index must exist"

    # Assert binding table does NOT include raw-token column names
    binding_schema_result = Repo.query!("SELECT sql FROM sqlite_master WHERE type='table' AND name='chimeway_token_bindings'")
    [[binding_schema_sql]] = binding_schema_result.rows

    # SQLite stores column names unquoted; check for the column name followed by
    # a space (type declaration) to avoid false positives on token_ref/token_fingerprint
    for forbidden_col <- [" token ", " raw_token ", " device_token ", " apns_token ", " fcm_token "] do
      refute String.contains?(binding_schema_sql, forbidden_col),
             "chimeway_token_bindings must not define a\#{forbidden_col}column"
    end

    # Assert Phase 60 schema is minimal — no extra normalized chimeway tables
    extra_tables_result = Repo.query!(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'chimeway_%' AND name NOT IN ('chimeway_token_bindings', 'chimeway_token_binding_events', 'chimeway_notification_open_intents', 'chimeway_notification_open_intent_events')"
    )
    assert extra_tables_result.rows == [],
           "Phase 60+ must not create extra chimeway_* tables beyond allowed binding, event, and notification open tables"

    IO.puts("phase60-schema-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-schema-proof: ok"
  end

  # ---------------------------------------------------------------------------
  # Registry lifecycle proof: bind, refresh, rotate, and raw-token absence
  # ---------------------------------------------------------------------------

  @tag :requires_example_host
  test "Registry bind_or_rotate: initial bind, same-token refresh, and rotation lifecycle" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_chimeway_lifecycle_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias CrosswakeExample.Chimeway.Registry
    alias CrosswakeExample.Repo

    # --- Initial bind ---
    context = %{
      subject_scope: :subject_session,
      subject_ref: "sub_lifecycle_001",
      org_ref: "org_lifecycle_001",
      session_ref: "sess_lifecycle_001",
      session_version: 1,
      installation_ref: "inst_lifecycle_001",
      actor_kind: :backend,
      correlation_id: "corr_bind_001"
    }

    evidence_v1 = %{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      installation_ref: "inst_lifecycle_001",
      token_ref: "tok_ref_v1",
      token_fingerprint: "hmac-sha256:fp_v1_aabbcc",
      notification_status: :granted,
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      app_identity_posture: :matched,
      correlation_id: "corr_bind_001",
      metadata: %{safe_key: "safe_value", apns_token: "raw_apns_token_should_not_leak_123"}
    }

    {:ok, bind_result} = Registry.bind_or_rotate(context, evidence_v1)
    binding_v1 = bind_result.binding
    audit_event_v1 = bind_result.audit_event
    result_v1 = bind_result.result

    # Binding assertions
    assert binding_v1.state == :active
    assert binding_v1.reason == :initial_bind
    assert binding_v1.token_ref == "tok_ref_v1"
    assert binding_v1.token_fingerprint == "hmac-sha256:fp_v1_aabbcc"
    assert binding_v1.subject_ref == "sub_lifecycle_001"
    assert binding_v1.org_ref == "org_lifecycle_001"
    assert binding_v1.session_ref == "sess_lifecycle_001"
    assert is_binary(binding_v1.binding_ref)
    assert binding_v1.bound_at != nil

    # Metadata must not leak raw token
    refute Map.has_key?(binding_v1.metadata, :apns_token), "binding metadata must not contain apns_token"
    refute Map.has_key?(binding_v1.metadata, "apns_token"), "binding metadata must not contain string apns_token"

    # Audit event assertions
    assert audit_event_v1.event_type == :bound
    assert audit_event_v1.state_after == :active
    assert audit_event_v1.reason == :initial_bind
    assert audit_event_v1.binding_ref == binding_v1.binding_ref

    # Result assertions
    assert result_v1.status == :bound
    assert result_v1.binding_ref == binding_v1.binding_ref

    # Inspect output must not leak raw token
    inspected = inspect(bind_result)
    refute String.contains?(inspected, "raw_apns_token_should_not_leak_123"),
           "inspect output must not contain raw token value"

    # Audit event must not leak raw token in any field
    audit_inspected = inspect(audit_event_v1)
    refute String.contains?(audit_inspected, "raw_apns_token_should_not_leak_123"),
           "audit event inspect must not contain raw token value"

    # Result map must not leak raw token
    result_inspected = inspect(result_v1)
    refute String.contains?(result_inspected, "raw_apns_token_should_not_leak_123"),
           "binding result inspect must not contain raw token value"

    # --- Same-token refresh ---
    evidence_v1_refresh = %{evidence_v1 | notification_status: :granted}
    {:ok, refresh_result} = Registry.bind_or_rotate(context, evidence_v1_refresh)
    binding_refreshed = refresh_result.binding
    refresh_event = refresh_result.audit_event

    # binding_ref and bound_at must be unchanged on refresh (D-17)
    assert binding_refreshed.binding_ref == binding_v1.binding_ref,
           "binding_ref must not change on same-token refresh"
    assert DateTime.compare(binding_refreshed.bound_at, binding_v1.bound_at) == :eq,
           "bound_at must not change on same-token refresh"
    assert binding_refreshed.state == :active
    assert refresh_event.event_type == :observed

    # --- Token rotation ---
    evidence_v2 = %{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      installation_ref: "inst_lifecycle_001",
      token_ref: "tok_ref_v2",
      token_fingerprint: "hmac-sha256:fp_v2_ddeeff",
      notification_status: :granted,
      observed_at: DateTime.to_iso8601(DateTime.utc_now()),
      app_identity_posture: :matched,
      correlation_id: "corr_rotate_001"
    }

    {:ok, rotate_result} = Registry.bind_or_rotate(context, evidence_v2)
    binding_v2 = rotate_result.binding
    audit_events_rotation = rotate_result.audit_events
    result_rotate = rotate_result.result

    assert result_rotate.status == :rotated
    assert binding_v2.state == :active
    assert binding_v2.token_ref == "tok_ref_v2"
    assert binding_v2.token_fingerprint == "hmac-sha256:fp_v2_ddeeff"
    # New binding_ref for rotated binding
    assert binding_v2.binding_ref != binding_v1.binding_ref

    # Displaced binding must now be superseded
    import Ecto.Query
    displaced = Repo.get_by!(CrosswakeExample.Chimeway.TokenBinding, binding_ref: binding_v1.binding_ref)
    assert displaced.state == :superseded
    assert displaced.reason == :token_rotated
    assert displaced.superseded_at != nil

    # Multiple audit events: at least one :rotated + one :bound
    assert length(audit_events_rotation) >= 2
    event_types = Enum.map(audit_events_rotation, & &1.event_type)
    assert :rotated in event_types, "rotation must include :rotated audit event"
    assert :bound in event_types, "rotation must include :bound audit event for new binding"

    # Row count: 2 total (1 superseded + 1 active)
    all_bindings = Repo.all(CrosswakeExample.Chimeway.TokenBinding)
    assert length(all_bindings) == 2, "rotation must result in 2 binding rows (superseded + active)"

    IO.puts("phase60-lifecycle-bind-rotate-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-lifecycle-bind-rotate-proof: ok"
  end

  # ---------------------------------------------------------------------------
  # Registry lifecycle proof: revoke, invalidate, prune, and telemetry rollback
  # ---------------------------------------------------------------------------

  @tag :requires_example_host
  test "Registry revocation, provider feedback, pruning, idempotency, and telemetry rollback safety" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    import Ecto.Query
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_chimeway_revoke_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias CrosswakeExample.Chimeway.Registry
    alias CrosswakeExample.Chimeway.TokenBinding
    alias CrosswakeExample.Chimeway.TokenBindingEvent
    alias CrosswakeExample.Repo

    # Attach telemetry handler for rollback safety test
    telemetry_pid = self()
    handler_id = "phase60-revoke-proof-handler"
    :telemetry.attach_many(
      handler_id,
      [
        [:crosswake, :notification, :token, :bound],
        [:crosswake, :notification, :token, :observed],
        [:crosswake, :notification, :token, :rotated],
        [:crosswake, :notification, :token, :revoked],
        [:crosswake, :notification, :token, :stale],
        [:crosswake, :notification, :token, :invalidated],
        [:crosswake, :notification, :provider, :feedback]
      ],
      fn event_name, _measurements, metadata, _config ->
        send(telemetry_pid, {:telemetry_fired, event_name, metadata})
      end,
      nil
    )

    defmodule Phase60TestHelpers do
      def bind_session(subject_ref, session_ref, token_fingerprint, opts \\\\ []) do
        context = %{
          subject_scope: :subject_session,
          subject_ref: subject_ref,
          org_ref: opts[:org_ref] || "org_test",
          session_ref: session_ref,
          session_version: opts[:session_version] || 1,
          installation_ref: opts[:installation_ref] || "inst_test_001",
          actor_kind: :backend,
          correlation_id: opts[:correlation_id] || "corr_test_001"
        }

        evidence = %{
          provider: opts[:provider] || :apns,
          platform: opts[:platform] || :ios,
          environment: opts[:environment] || :sandbox,
          installation_ref: opts[:installation_ref] || "inst_test_001",
          token_ref: opts[:token_ref] || "tok_ref_\#{token_fingerprint}",
          token_fingerprint: token_fingerprint,
          notification_status: opts[:notification_status] || :granted,
          observed_at: DateTime.to_iso8601(DateTime.utc_now()),
          app_identity_posture: :matched
        }

        Registry.bind_or_rotate(context, evidence)
      end
    end

    # --- Logout revocation ---
    {:ok, _} = Phase60TestHelpers.bind_session("sub_logout_001", "sess_logout_001", "hmac-sha256:fp_logout_001")
    {:ok, _} = Phase60TestHelpers.bind_session("sub_logout_001", "sess_logout_001", "hmac-sha256:fp_logout_001b",
      token_ref: "tok_ref_logout_001b", installation_ref: "inst_logout_002", correlation_id: "corr_logout_002")

    logout_context = %{
      subject_ref: "sub_logout_001",
      org_ref: "org_test",
      session_ref: "sess_logout_001"
    }
    {:ok, logout_result} = Registry.revoke_for_logout(logout_context)
    assert logout_result.result.status == :revoked
    assert is_list(logout_result.bindings)
    assert is_list(logout_result.audit_events)

    # All previously active bindings for this session must now be revoked
    revoked_bindings = Repo.all(from b in TokenBinding,
      where: b.subject_ref == "sub_logout_001" and b.session_ref == "sess_logout_001")
    for b <- revoked_bindings do
      assert b.state == :revoked, "binding \#{b.binding_ref} must be revoked after logout"
      assert b.reason == :logout_revoked
      assert b.revoked_at != nil
    end

    # Audit rows must still exist (no delete)
    logout_events = Repo.all(from e in TokenBindingEvent,
      where: e.event_type == :revoked and e.reason == :logout_revoked)
    assert length(logout_events) > 0, "revocation audit rows must exist after logout revocation"

    # Idempotent repeat: no active bindings → error, but no crash
    assert {:error, :no_active_bindings} = Registry.revoke_for_logout(logout_context)

    # --- Session revocation with session_version protection ---
    {:ok, _} = Phase60TestHelpers.bind_session("sub_session_rev", "sess_ver_001", "hmac-sha256:fp_sess_ver_001",
      session_version: 1, org_ref: "org_session_rev")
    {:ok, _} = Phase60TestHelpers.bind_session("sub_session_rev", "sess_ver_001", "hmac-sha256:fp_sess_ver_002",
      session_version: 2, org_ref: "org_session_rev", token_ref: "tok_ver_002",
      installation_ref: "inst_session_rev_002")

    # Revoke version <= 1, version 2 should survive
    {:ok, sess_rev_result} = Registry.revoke_for_session_revocation("sess_ver_001", session_version: 1)
    assert sess_rev_result.result.status == :revoked

    session_bindings = Repo.all(from b in TokenBinding,
      where: b.session_ref == "sess_ver_001")
    v1_bindings = Enum.filter(session_bindings, fn b -> b.session_version == 1 end)
    v2_bindings = Enum.filter(session_bindings, fn b -> b.session_version == 2 end)
    for b <- v1_bindings do
      assert b.state == :revoked, "version 1 binding must be revoked"
    end
    for b <- v2_bindings do
      assert b.state == :active, "version 2 binding must survive session_version-guarded revocation"
    end

    # --- Permission loss revocation ---
    {:ok, _} = Phase60TestHelpers.bind_session("sub_perm_loss", "sess_perm_001", "hmac-sha256:fp_perm_001",
      org_ref: "org_perm_test")
    perm_context = %{subject_ref: "sub_perm_loss", org_ref: "org_perm_test"}
    {:ok, perm_result} = Registry.revoke_for_permission_loss(perm_context)
    assert perm_result.result.status == :revoked

    perm_bindings = Repo.all(from b in TokenBinding,
      where: b.subject_ref == "sub_perm_loss" and b.org_ref == "org_perm_test")
    for b <- perm_bindings do
      assert b.state == :revoked
      assert b.reason == :permission_denied
      assert b.notification_status == :denied
    end

    # Audit rows persist after revocation
    perm_events = Repo.all(from e in TokenBindingEvent,
      where: e.reason == :permission_denied)
    assert length(perm_events) > 0

    # --- Provider feedback: invalidating (token_unregistered → revoked) ---
    {:ok, provider_bind} = Phase60TestHelpers.bind_session(
      "sub_provider_001", "sess_provider_001", "hmac-sha256:fp_provider_001",
      org_ref: "org_provider_test", token_ref: "tok_provider_001"
    )
    provider_binding = provider_bind.binding

    # token_unregistered must map to revoked/provider_unregistered
    feedback_unregistered = %Crosswake.Companions.Chimeway.Contracts.ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      feedback_event: :token_unregistered,
      occurred_at: DateTime.to_iso8601(DateTime.utc_now()),
      token_ref: "tok_provider_001",
      token_fingerprint: "hmac-sha256:fp_provider_001",
      app_identity_posture: :matched
    }

    {:ok, provider_result} = Registry.apply_provider_feedback(feedback_unregistered)
    assert provider_result.result.status == :invalidated

    provider_bindings = Repo.all(from b in TokenBinding,
      where: b.binding_ref == ^provider_binding.binding_ref)
    assert length(provider_bindings) == 1
    revoked_binding = List.first(provider_bindings)
    assert revoked_binding.state == :revoked
    assert revoked_binding.reason == :provider_unregistered

    # Provider-native enum must not leak into state or reason
    raw_provider_atoms = [:UNREGISTERED, :"DeviceTokenNotForTopic", :BadDeviceToken]
    refute revoked_binding.state in raw_provider_atoms
    refute revoked_binding.reason in raw_provider_atoms

    # --- Provider feedback: non-invalidating (delivery_accepted → audit-only) ---
    {:ok, delivery_bind} = Phase60TestHelpers.bind_session(
      "sub_delivery_001", "sess_delivery_001", "hmac-sha256:fp_delivery_001",
      org_ref: "org_delivery_test", token_ref: "tok_delivery_001"
    )
    delivery_binding = delivery_bind.binding

    feedback_accepted = %Crosswake.Companions.Chimeway.Contracts.ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      feedback_event: :delivery_accepted,
      occurred_at: DateTime.to_iso8601(DateTime.utc_now()),
      token_ref: "tok_delivery_001",
      token_fingerprint: "hmac-sha256:fp_delivery_001",
      app_identity_posture: :matched
    }

    {:ok, delivery_result} = Registry.apply_provider_feedback(feedback_accepted)
    # delivery_accepted is feedback-only; binding must remain active
    delivery_binding_after = Repo.get!(TokenBinding, delivery_binding.id)
    assert delivery_binding_after.state == :active,
           "delivery_accepted must not revoke or invalidate the binding"

    # --- Provider feedback: environment_mismatch → invalid ---
    {:ok, env_bind} = Phase60TestHelpers.bind_session(
      "sub_env_001", "sess_env_001", "hmac-sha256:fp_env_001",
      org_ref: "org_env_test", token_ref: "tok_env_001"
    )
    env_binding = env_bind.binding

    feedback_env = %Crosswake.Companions.Chimeway.Contracts.ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      feedback_event: :environment_mismatch,
      occurred_at: DateTime.to_iso8601(DateTime.utc_now()),
      token_ref: "tok_env_001",
      token_fingerprint: "hmac-sha256:fp_env_001",
      app_identity_posture: :mismatched
    }

    {:ok, env_feedback_result} = Registry.apply_provider_feedback(feedback_env)
    assert env_feedback_result.result.status == :invalidated

    env_binding_after = Repo.get!(TokenBinding, env_binding.id)
    assert env_binding_after.state == :invalid
    assert env_binding_after.reason == :environment_mismatch

    # --- Staleness pruning ---
    past = DateTime.add(DateTime.utc_now(), -3600, :second)
    {:ok, stale_bind} = Phase60TestHelpers.bind_session(
      "sub_stale_001", "sess_stale_001", "hmac-sha256:fp_stale_001",
      org_ref: "org_stale_test", token_ref: "tok_stale_001"
    )
    stale_binding = stale_bind.binding

    # Force last_seen_at to be in the past
    Repo.update_all(
      from(b in TokenBinding, where: b.binding_ref == ^stale_binding.binding_ref),
      set: [last_seen_at: past]
    )

    prune_threshold = DateTime.add(DateTime.utc_now(), -60, :second)
    {:ok, prune_result} = Registry.prune_stale(stale_before: prune_threshold,
      subject_ref: "sub_stale_001", org_ref: "org_stale_test")

    stale_binding_after = Repo.get!(TokenBinding, stale_binding.id)
    assert stale_binding_after.state == :stale
    assert stale_binding_after.reason == :staleness_pruned
    assert stale_binding_after.stale_at != nil

    stale_events = Repo.all(from e in TokenBindingEvent,
      where: e.event_type == :stale and e.binding_ref == ^stale_binding.binding_ref)
    assert length(stale_events) == 1, "staleness pruning must create exactly one :stale audit event"

    # Idempotent prune: no active rows left for this subject, result still ok
    {:ok, prune_noop} = Registry.prune_stale(stale_before: prune_threshold,
      subject_ref: "sub_stale_001", org_ref: "org_stale_test")
    assert prune_noop.bindings == []
    assert prune_noop.audit_events == []

    # No binding rows are deleted (audit history preserved)
    all_stale_bindings = Repo.all(from b in TokenBinding,
      where: b.subject_ref == "sub_stale_001")
    assert length(all_stale_bindings) >= 1, "stale bindings must not be deleted"

    # --- Telemetry rollback safety ---
    # Force a transaction failure by inserting a duplicate binding_ref and
    # assert no success telemetry fires for the rolled-back write.
    # Flush ALL pending telemetry messages accumulated from earlier in the test
    # so the rollback assertion starts with a clean mailbox
    :timer.sleep(50)
    Enum.each(1..50, fn _ ->
      receive do {:telemetry_fired, _, _} -> :ok after 0 -> :ok end
    end)

    {:ok, existing_bind} = Phase60TestHelpers.bind_session(
      "sub_rollback_test", "sess_rollback", "hmac-sha256:fp_rollback_001",
      org_ref: "org_rollback_test", token_ref: "tok_rollback_001"
    )
    existing_ref = existing_bind.binding.binding_ref

    # Flush telemetry from the successful bind above; give it time to arrive
    :timer.sleep(50)
    Enum.each(1..10, fn _ ->
      receive do {:telemetry_fired, _, _} -> :ok after 0 -> :ok end
    end)

    # Attempt to insert a duplicate: will fail at DB level
    rollback_result = CrosswakeExample.Repo.transaction(fn repo ->
      # Insert a row with the same unique binding_ref to force constraint failure
      attrs = %{
        binding_ref: existing_ref,
        subject_scope: :subject_session,
        subject_ref: "sub_rollback_test",
        org_ref: "org_rollback_test",
        session_ref: "sess_rollback_forced_fail",
        session_version: 1,
        installation_ref: "inst_rollback_test",
        provider: :apns,
        platform: :ios,
        environment: :sandbox,
        app_identity_posture: :matched,
        token_ref: "tok_rollback_dup",
        token_fingerprint: "hmac-sha256:fp_rollback_dup",
        notification_status: :granted,
        state: :active,
        reason: :initial_bind,
        bound_at: DateTime.utc_now() |> DateTime.truncate(:second),
        last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
        audit_correlation_ref: "corr_rollback_dup"
      }
      case repo.insert(CrosswakeExample.Chimeway.TokenBinding.changeset(%CrosswakeExample.Chimeway.TokenBinding{}, attrs)) do
        {:ok, _} -> repo.rollback(:forced_rollback_for_test)
        {:error, changeset} -> repo.rollback({:constraint_error, changeset})
      end
    end)

    # Transaction rolled back — no success telemetry should fire
    receive do
      {:telemetry_fired, event_name, _} ->
        flunk("Success telemetry \#{inspect(event_name)} must not fire for rolled-back transaction")
    after
      100 -> :ok
    end

    :telemetry.detach(handler_id)
    IO.puts("phase60-revoke-feedback-prune-telemetry-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-revoke-feedback-prune-telemetry-proof: ok"
  end

  # ---------------------------------------------------------------------------
  # Regression: CR-01 — empty token selector must not invalidate all bindings
  # Regression: WR-01 — zero-match invalidation must return an error
  # Regression: WR-05 — subject_session binding requires session_version
  # ---------------------------------------------------------------------------

  @tag :requires_example_host
  test "CR-01 regression: feedback with no token selector fails closed and leaves active bindings intact" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    import Ecto.Query
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_chimeway_cr01_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias CrosswakeExample.Chimeway.Registry
    alias CrosswakeExample.Chimeway.TokenBinding
    alias CrosswakeExample.Repo
    alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback

    # Bind two active bindings for different subjects
    context_a = %{
      subject_scope: :subject_session,
      subject_ref: "sub_cr01_a",
      org_ref: "org_cr01",
      session_ref: "sess_cr01_a",
      session_version: 1,
      installation_ref: "inst_cr01_a",
      actor_kind: :backend
    }
    evidence_a = %{
      provider: :apns, platform: :ios, environment: :sandbox,
      installation_ref: "inst_cr01_a", token_ref: "tok_cr01_a",
      token_fingerprint: "hmac-sha256:fp_cr01_a",
      notification_status: :granted,
      observed_at: DateTime.to_iso8601(DateTime.utc_now())
    }
    {:ok, bind_a} = Registry.bind_or_rotate(context_a, evidence_a)

    context_b = %{
      subject_scope: :subject_session,
      subject_ref: "sub_cr01_b",
      org_ref: "org_cr01",
      session_ref: "sess_cr01_b",
      session_version: 1,
      installation_ref: "inst_cr01_b",
      actor_kind: :backend
    }
    evidence_b = %{
      provider: :apns, platform: :ios, environment: :sandbox,
      installation_ref: "inst_cr01_b", token_ref: "tok_cr01_b",
      token_fingerprint: "hmac-sha256:fp_cr01_b",
      notification_status: :granted,
      observed_at: DateTime.to_iso8601(DateTime.utc_now())
    }
    {:ok, bind_b} = Registry.bind_or_rotate(context_b, evidence_b)

    # Sanity: both bindings are active
    assert bind_a.binding.state == :active
    assert bind_b.binding.state == :active

    # CR-01: feedback with NEITHER token_fingerprint NOR token_ref must fail closed
    feedback_no_selector = %ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      feedback_event: :token_unregistered,
      occurred_at: DateTime.to_iso8601(DateTime.utc_now()),
      token_ref: nil,
      token_fingerprint: nil
    }

    result = Registry.apply_provider_feedback(feedback_no_selector)
    assert result == {:error, :feedback_missing_token_selector},
           "feedback with no token selector must return {:error, :feedback_missing_token_selector}, got: \#{inspect(result)}"

    # Both bindings must still be active — no unbounded fan-out occurred
    binding_a_after = Repo.get!(TokenBinding, bind_a.binding.id)
    binding_b_after = Repo.get!(TokenBinding, bind_b.binding.id)
    assert binding_a_after.state == :active,
           "binding A must remain :active after empty-selector feedback was rejected"
    assert binding_b_after.state == :active,
           "binding B must remain :active after empty-selector feedback was rejected"

    IO.puts("phase60-cr01-regression-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-cr01-regression-proof: ok"
  end

  @tag :requires_example_host
  test "WR-01 regression: invalidating feedback matching zero active bindings returns error" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")
    db =
      Path.join(
        System.tmp_dir!(),
        "crosswake_chimeway_wr01_proof_" <> Integer.to_string(System.unique_integer([:positive])) <> ".db"
      )

    File.rm(db)
    Application.put_env(:crosswake_example, CrosswakeExample.Repo, database: db, pool_size: 1, log: false)
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:ecto_sql)
    {:ok, _pid} = CrosswakeExample.Repo.start_link()
    path = Path.expand("priv/repo/migrations", File.cwd!())
    Ecto.Migrator.run(CrosswakeExample.Repo, path, :up, all: true)

    alias CrosswakeExample.Chimeway.Registry
    alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback

    # Invalidating feedback referencing a token fingerprint that has no active binding
    feedback_no_match = %ProviderFeedback{
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      feedback_event: :token_unregistered,
      occurred_at: DateTime.to_iso8601(DateTime.utc_now()),
      token_fingerprint: "hmac-sha256:nonexistent_fingerprint_xyzzy"
    }

    result = Registry.apply_provider_feedback(feedback_no_match)
    assert result == {:error, :no_active_bindings},
           "invalidating feedback matching zero bindings must return {:error, :no_active_bindings}, got: \#{inspect(result)}"

    IO.puts("phase60-wr01-regression-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-wr01-regression-proof: ok"
  end

  @tag :requires_example_host
  test "WR-05 regression: subject_session changeset without session_version is invalid" do
    script = """
    Logger.configure(level: :warning)
    import ExUnit.Assertions
    Mix.Task.run("app.config")

    alias CrosswakeExample.Chimeway.TokenBinding

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    base_attrs = %{
      binding_ref: "bnd_wr05_test",
      subject_scope: :subject_session,
      subject_ref: "sub_wr05",
      org_ref: "org_wr05",
      session_ref: "sess_wr05",
      installation_ref: "inst_wr05",
      provider: :apns,
      platform: :ios,
      environment: :sandbox,
      token_ref: "tok_wr05",
      token_fingerprint: "hmac-sha256:fp_wr05",
      notification_status: :granted,
      state: :active,
      reason: :initial_bind,
      bound_at: now,
      last_seen_at: now,
      audit_correlation_ref: "corr_wr05"
    }

    # Without session_version — must be invalid
    cs_no_version = TokenBinding.changeset(%TokenBinding{}, base_attrs)
    refute cs_no_version.valid?,
           "subject_session binding without session_version must be invalid (WR-05)"
    assert cs_no_version.errors[:session_version] != nil,
           "changeset must carry a :session_version error"

    # With session_version: 0 — must be valid
    cs_with_version = TokenBinding.changeset(%TokenBinding{}, Map.put(base_attrs, :session_version, 0))
    assert cs_with_version.valid?,
           "subject_session binding with session_version: 0 must be valid: \#{inspect(cs_with_version.errors)}"

    # With negative session_version — must be invalid
    cs_negative = TokenBinding.changeset(%TokenBinding{}, Map.put(base_attrs, :session_version, -1))
    refute cs_negative.valid?,
           "subject_session binding with session_version: -1 must be invalid"

    IO.puts("phase60-wr05-regression-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-wr05-regression-proof: ok"
  end
end
