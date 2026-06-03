defmodule CrosswakeExample.Repo.Migrations.CreateSigraStepUpIntents do
  use Ecto.Migration

  def change do
    create table(:sigra_step_up_intents) do
      add(:intent_ref, :string, null: false)
      add(:locator_digest, :string, null: false)
      add(:state, :string, null: false, default: "issued")
      add(:subject_ref, :string, null: false)
      add(:org_id, :string, null: false)
      add(:source_session_ref, :string, null: false)
      add(:expected_session_version, :integer, null: false)
      add(:device_ref, :string)
      add(:source_route_id, :string, null: false)
      add(:return_route_id, :string, null: false)
      add(:return_params, :map, null: false, default: %{})
      add(:required_assurance_level, :string, null: false)
      add(:required_auth_posture, :string, null: false)
      add(:max_auth_age_seconds, :integer, null: false)
      add(:challenge_kind, :string, null: false)
      add(:issued_at, :utc_datetime, null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:challenged_at, :utc_datetime)
      add(:consumed_at, :utc_datetime)
      add(:canceled_at, :utc_datetime)
      add(:revoked_at, :utc_datetime)
      add(:cancellation_reason, :string)
      add(:revocation_reason, :string)
      add(:audit_correlation_ref, :string, null: false)
      add(:projected_session_ref, :string, null: false)
      add(:projected_session_version, :integer, null: false)
      add(:projected_authority, :map, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:sigra_step_up_intents, [:intent_ref]))
    create(unique_index(:sigra_step_up_intents, [:locator_digest]))
    create(index(:sigra_step_up_intents, [:state]))
    create(index(:sigra_step_up_intents, [:expires_at]))
    create(index(:sigra_step_up_intents, [:source_session_ref]))
    create(index(:sigra_step_up_intents, [:audit_correlation_ref]))
  end
end
