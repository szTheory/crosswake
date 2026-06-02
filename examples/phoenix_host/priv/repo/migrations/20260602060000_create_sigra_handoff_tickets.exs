defmodule CrosswakeExample.Repo.Migrations.CreateSigraHandoffTickets do
  use Ecto.Migration

  def change do
    create table(:sigra_handoff_tickets) do
      add(:ticket_ref, :string, null: false)
      add(:ticket_digest, :string, null: false)
      add(:state, :string, null: false, default: "issued")
      add(:subject_ref, :string, null: false)
      add(:org_id, :string, null: false)
      add(:source_session_ref, :string, null: false)
      add(:expected_session_version, :integer, null: false)
      add(:device_ref, :string)
      add(:binding_kind, :string, null: false, default: "session_route_intent")
      add(:intent_kind, :string, null: false, default: "session_handoff")
      add(:intent_ref, :string)
      add(:source_route_id, :string)
      add(:target_route_id, :string, null: false)
      add(:required_assurance_level, :string, null: false)
      add(:required_auth_posture, :string, null: false)
      add(:issued_at, :utc_datetime, null: false)
      add(:expires_at, :utc_datetime, null: false)
      add(:consumed_at, :utc_datetime)
      add(:revoked_at, :utc_datetime)
      add(:revocation_reason, :string)
      add(:audit_correlation_ref, :string, null: false)
      add(:projected_session_ref, :string, null: false)
      add(:projected_session_version, :integer, null: false)
      add(:projected_authority, :map, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:sigra_handoff_tickets, [:ticket_ref]))
    create(unique_index(:sigra_handoff_tickets, [:ticket_digest]))
    create(index(:sigra_handoff_tickets, [:state]))
    create(index(:sigra_handoff_tickets, [:expires_at]))
    create(index(:sigra_handoff_tickets, [:source_session_ref]))
    create(index(:sigra_handoff_tickets, [:audit_correlation_ref]))
  end
end
