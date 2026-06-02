defmodule CrosswakeExample.Repo.Migrations.CreateSigraHandoffAuditEvents do
  use Ecto.Migration

  def change do
    create table(:sigra_handoff_audit_events) do
      add(:event_id, :string, null: false)
      add(:event_type, :string, null: false)
      add(:handoff_ref, :string, null: false)
      add(:ticket_ref, :string)
      add(:state_before, :string)
      add(:state_after, :string)
      add(:outcome, :string, null: false)
      add(:denial_code, :string)
      add(:occurred_at, :utc_datetime, null: false)
      add(:route_id, :string, null: false)
      add(:intent_kind, :string, null: false)
      add(:intent_ref, :string)
      add(:source_session_ref, :string)
      add(:projected_session_ref, :string)
      add(:session_version_before, :integer)
      add(:session_version_after, :integer)
      add(:assurance_after, :string)
      add(:authn_methods_after, :map)
      add(:binding_result, :string)
      add(:request_ref, :string, null: false)
      add(:actor_kind, :string, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:sigra_handoff_audit_events, [:event_id]))
    create(index(:sigra_handoff_audit_events, [:ticket_ref]))
    create(index(:sigra_handoff_audit_events, [:handoff_ref]))
    create(index(:sigra_handoff_audit_events, [:event_type]))
    create(index(:sigra_handoff_audit_events, [:occurred_at]))
    create(index(:sigra_handoff_audit_events, [:request_ref]))
  end
end
