defmodule CrosswakeExample.Repo.Migrations.CreateChimewayTokenBindings do
  use Ecto.Migration

  def change do
    create table(:chimeway_token_bindings) do
      add(:binding_ref, :string, null: false)
      add(:subject_scope, :string, null: false)
      add(:subject_ref, :string, null: false)
      add(:org_ref, :string, null: false)
      add(:session_ref, :string)
      add(:session_version, :integer)
      add(:installation_ref, :string, null: false)
      add(:provider, :string, null: false)
      add(:platform, :string, null: false)
      add(:environment, :string, null: false)
      add(:app_identity_posture, :string, null: false, default: "unknown")
      add(:app_identity_ref, :string, null: false)
      add(:token_ref, :string, null: false)
      add(:token_fingerprint, :string, null: false)
      add(:notification_status, :string, null: false)
      add(:state, :string, null: false)
      add(:reason, :string, null: false)
      add(:bound_at, :utc_datetime, null: false)
      add(:last_seen_at, :utc_datetime, null: false)
      add(:superseded_at, :utc_datetime)
      add(:revoked_at, :utc_datetime)
      add(:stale_at, :utc_datetime)
      add(:invalidated_at, :utc_datetime)
      add(:audit_correlation_ref, :string, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    # Unique binding identity
    create(
      unique_index(:chimeway_token_bindings, [:binding_ref],
        name: :chimeway_token_bindings_binding_ref_index
      )
    )

    # Lookup indexes
    create(index(:chimeway_token_bindings, [:subject_ref, :org_ref]))
    create(index(:chimeway_token_bindings, [:session_ref]))
    create(index(:chimeway_token_bindings, [:installation_ref]))
    create(index(:chimeway_token_bindings, [:token_fingerprint]))
    create(index(:chimeway_token_bindings, [:state, :last_seen_at]))

    # Partial unique: active token fingerprint identity (D-10)
    # Prevents two active rows for the same token identity across provider/platform/env/posture
    create(
      unique_index(
        :chimeway_token_bindings,
        [
          :token_fingerprint,
          :provider,
          :platform,
          :environment,
          :app_identity_posture,
          :app_identity_ref
        ],
        name: :chimeway_token_bindings_active_token_identity_index,
        where: "state = 'active'"
      )
    )

    # Partial unique: active subject-session authority scope (D-11)
    # Prevents two active rows for the same authenticated session binding scope
    create(
      unique_index(
        :chimeway_token_bindings,
        [
          :subject_ref,
          :org_ref,
          :session_ref,
          :session_version,
          :installation_ref,
          :provider,
          :platform,
          :environment,
          :app_identity_posture,
          :app_identity_ref
        ],
        name: :chimeway_token_bindings_active_subject_session_scope_index,
        where: "state = 'active' AND subject_scope = 'subject_session'"
      )
    )

    # Partial unique: active subject-installation authority scope (D-12)
    # Separate index that excludes nullable session_ref to avoid null-uniqueness surprises
    create(
      unique_index(
        :chimeway_token_bindings,
        [
          :subject_ref,
          :org_ref,
          :installation_ref,
          :provider,
          :platform,
          :environment,
          :app_identity_posture,
          :app_identity_ref
        ],
        name: :chimeway_token_bindings_active_subject_installation_scope_index,
        where: "state = 'active' AND subject_scope = 'subject_installation'"
      )
    )
  end
end
