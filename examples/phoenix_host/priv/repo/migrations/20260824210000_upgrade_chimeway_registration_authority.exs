defmodule CrosswakeExample.Repo.Migrations.UpgradeChimewayRegistrationAuthority do
  use Ecto.Migration

  def up do
    add_binding_identity_column()

    for {column, type} <- [
          {:tenant_ref, :string},
          {:subject_ref, :string},
          {:session_ref, :string},
          {:session_version, :integer}
        ] do
      add_intent_column(column, type)
    end

    # Authority is copied only from the exact durable binding relationship.
    # This statement has no row-derived SQL fragments and cannot invent scope.
    execute("""
    UPDATE chimeway_notification_open_intents
    SET tenant_ref = (SELECT org_ref FROM chimeway_token_bindings WHERE binding_ref = chimeway_notification_open_intents.binding_ref),
        subject_ref = (SELECT subject_ref FROM chimeway_token_bindings WHERE binding_ref = chimeway_notification_open_intents.binding_ref),
        session_ref = (SELECT session_ref FROM chimeway_token_bindings WHERE binding_ref = chimeway_notification_open_intents.binding_ref),
        session_version = (SELECT session_version FROM chimeway_token_bindings WHERE binding_ref = chimeway_notification_open_intents.binding_ref)
    WHERE EXISTS (SELECT 1 FROM chimeway_token_bindings WHERE binding_ref = chimeway_notification_open_intents.binding_ref)
    """)

    execute("""
    UPDATE chimeway_notification_open_intents
    SET state = 'revoked'
    WHERE NOT EXISTS (SELECT 1 FROM chimeway_token_bindings WHERE binding_ref = chimeway_notification_open_intents.binding_ref)
    """)

    # A legacy row with no authenticated app identity is never eligible for
    # delivery or route authority. The fixed marker is explicitly non-authoritative.
    execute("""
    UPDATE chimeway_token_bindings
    SET state = 'invalid', reason = 'app_identity_mismatch', invalidated_at = CURRENT_TIMESTAMP,
        app_identity_ref = 'legacy_non_authoritative'
    WHERE app_identity_ref IS NULL OR app_identity_ref = ''
    """)

    reconcile_active_collisions()
    reconcile_active_token_identity_collisions()
    replace_active_indexes()
  end

  def down do
    drop_active_indexes()

    create unique_index(:chimeway_token_bindings, [:token_fingerprint, :provider, :platform, :environment, :app_identity_posture],
             name: :chimeway_token_bindings_active_token_identity_index,
             where: "state = 'active'")

    create unique_index(:chimeway_token_bindings, [:subject_ref, :org_ref, :session_ref, :installation_ref, :provider, :platform, :environment, :app_identity_posture],
             name: :chimeway_token_bindings_active_subject_session_scope_index,
             where: "state = 'active' AND subject_scope = 'subject_session'")

    create unique_index(:chimeway_token_bindings, [:subject_ref, :org_ref, :installation_ref, :provider, :platform, :environment, :app_identity_posture],
             name: :chimeway_token_bindings_active_subject_installation_scope_index,
             where: "state = 'active' AND subject_scope = 'subject_installation'")

    for column <- [:session_version, :session_ref, :subject_ref, :tenant_ref] do
      if intent_column?(column) do
        alter table(:chimeway_notification_open_intents) do
          remove column
        end
      end
    end
  end

  defp add_binding_identity_column do
    unless binding_column?(:app_identity_ref) do
      alter table(:chimeway_token_bindings) do
        add :app_identity_ref, :string
      end
    end
  end

  defp add_intent_column(column, type) do
    unless intent_column?(column) do
      alter table(:chimeway_notification_open_intents) do
        add column, type
      end
    end
  end

  defp reconcile_active_collisions do
    execute("""
    WITH ranked AS (
      SELECT id, ROW_NUMBER() OVER (
        PARTITION BY subject_scope, subject_ref, org_ref, session_ref, session_version,
                     installation_ref, provider, platform, environment, app_identity_ref
        ORDER BY last_seen_at DESC, id DESC
      ) AS position
      FROM chimeway_token_bindings
      WHERE state = 'active'
    )
    UPDATE chimeway_token_bindings
    SET state = 'superseded', reason = 'token_rotated', superseded_at = CURRENT_TIMESTAMP
    WHERE id IN (SELECT id FROM ranked WHERE position > 1)
    """)
  end

  # Old posture-keyed active identities could legitimately retain the same
  # token selector in separate authority scopes. Reconcile that second new
  # uniqueness domain before its posture-independent index is created.
  defp reconcile_active_token_identity_collisions do
    execute("""
    WITH ranked AS (
      SELECT id, ROW_NUMBER() OVER (
        PARTITION BY token_fingerprint, provider, platform, environment, app_identity_ref
        ORDER BY last_seen_at DESC, id DESC
      ) AS position
      FROM chimeway_token_bindings
      WHERE state = 'active'
    )
    UPDATE chimeway_token_bindings
    SET state = 'superseded', reason = 'token_rotated', superseded_at = CURRENT_TIMESTAMP
    WHERE id IN (SELECT id FROM ranked WHERE position > 1)
    """)
  end

  defp replace_active_indexes do
    drop_active_indexes()

    create unique_index(:chimeway_token_bindings, [:token_fingerprint, :provider, :platform, :environment, :app_identity_ref],
             name: :chimeway_token_bindings_active_token_identity_index,
             where: "state = 'active'")

    create unique_index(:chimeway_token_bindings, [:subject_ref, :org_ref, :session_ref, :session_version, :installation_ref, :provider, :platform, :environment, :app_identity_ref],
             name: :chimeway_token_bindings_active_subject_session_scope_index,
             where: "state = 'active' AND subject_scope = 'subject_session'")

    create unique_index(:chimeway_token_bindings, [:subject_ref, :org_ref, :installation_ref, :provider, :platform, :environment, :app_identity_ref],
             name: :chimeway_token_bindings_active_subject_installation_scope_index,
             where: "state = 'active' AND subject_scope = 'subject_installation'")
  end

  defp drop_active_indexes do
    drop_if_exists index(:chimeway_token_bindings, [], name: :chimeway_token_bindings_active_token_identity_index)
    drop_if_exists index(:chimeway_token_bindings, [], name: :chimeway_token_bindings_active_subject_session_scope_index)
    drop_if_exists index(:chimeway_token_bindings, [], name: :chimeway_token_bindings_active_subject_installation_scope_index)
  end

  defp binding_column?(column), do: column?("chimeway_token_bindings", column)
  defp intent_column?(column), do: column?("chimeway_notification_open_intents", column)

  defp column?(table, column) do
    %{rows: rows} = repo().query!("PRAGMA table_info(" <> table <> ")")
    Enum.any?(rows, fn [_cid, name | _rest] -> name == Atom.to_string(column) end)
  end
end
