defmodule CrosswakeExample.Repo.Migrations.CreateSigraAuthReturnAttempts do
  use Ecto.Migration

  def change do
    create table(:sigra_auth_return_attempts) do
      add(:attempt_ref, :string, null: false)
      add(:attempt_digest, :string, null: false)
      add(:kind, :string, null: false)
      add(:state, :string, null: false)
      add(:subject_ref, :string, null: false)
      add(:org_id, :string, null: false)
      add(:source_session_ref, :string, null: false)
      add(:expected_session_version, :integer, null: false)
      add(:device_ref, :string)
      add(:route_id, :string, null: false)
      add(:return_route_id, :string, null: false)
      add(:transport, :string, null: false)
      add(:link_verification, :string, null: false)
      add(:state_digest, :string)
      add(:nonce_digest, :string)
      add(:pkce_challenge_digest, :string)
      add(:pkce_method, :string)
      add(:expected_callback, :string)
      add(:provider_audience, :string)
      add(:return_params, :map, default: %{})
      add(:issued_at, :utc_datetime, null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:consumed_at, :utc_datetime)
      add(:revoked_at, :utc_datetime)
      add(:revocation_reason, :string)
      add(:audit_correlation_ref, :string, null: false)
      add(:projected_session_authority, :map, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:sigra_auth_return_attempts, [:attempt_ref]))
    create(unique_index(:sigra_auth_return_attempts, [:attempt_digest]))
    create(index(:sigra_auth_return_attempts, [:kind]))
    create(index(:sigra_auth_return_attempts, [:state]))
    create(index(:sigra_auth_return_attempts, [:expires_at]))
    create(index(:sigra_auth_return_attempts, [:source_session_ref]))
    create(index(:sigra_auth_return_attempts, [:route_id]))
    create(index(:sigra_auth_return_attempts, [:return_route_id]))
    create(index(:sigra_auth_return_attempts, [:audit_correlation_ref]))
  end
end
