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
    not extra normalized installation/device/token tables or replay infrastructure.
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
      File.read!(
        "examples/phoenix_host/lib/crosswake_example/chimeway/token_binding_event.ex"
      )

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

  test "no compiled chimeway file uses Oban, Quantum, or Broadway worker behaviours" do
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
      end
    end
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
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'chimeway_%' AND name NOT IN ('chimeway_token_bindings', 'chimeway_token_binding_events')"
    )
    assert extra_tables_result.rows == [],
           "Phase 60 must not create extra chimeway_* tables beyond binding and event tables"

    IO.puts("phase60-schema-proof: ok")
    """

    assert {output, 0} =
             System.cmd("mix", ["run", "--no-start", "-e", script],
               cd: "examples/phoenix_host",
               stderr_to_stdout: true
             )

    assert output =~ "phase60-schema-proof: ok"
  end
end
