defmodule CrosswakeExample.Repo.Migrations.CreateSigraAuthReturnAuditEvents do
  use Ecto.Migration

  def change do
    create table(:sigra_auth_return_audit_events) do
      add(:event_id, :string, null: false)
      add(:event_type, :string, null: false)
      add(:auth_return_ref, :string, null: false)
      add(:attempt_ref, :string)
      add(:state_before, :string)
      add(:state_after, :string)
      add(:outcome, :string, null: false)
      add(:denial_code, :string)
      add(:occurred_at, :utc_datetime, null: false)
      add(:route_id, :string, null: false)
      add(:kind, :string, null: false)
      add(:source_session_ref, :string)
      add(:projected_session_ref, :string)
      add(:session_version_before, :integer)
      add(:session_version_after, :integer)
      add(:assurance_after, :string)
      add(:authn_methods_after, :map)
      add(:binding_result, :string)
      add(:request_ref, :string, null: false)
      add(:actor_kind, :string, null: false)
      add(:metadata, :map, default: %{})

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:sigra_auth_return_audit_events, [:event_id]))
    create(index(:sigra_auth_return_audit_events, [:auth_return_ref]))
    create(index(:sigra_auth_return_audit_events, [:attempt_ref]))
    create(index(:sigra_auth_return_audit_events, [:kind]))
    create(index(:sigra_auth_return_audit_events, [:denial_code]))
    create(index(:sigra_auth_return_audit_events, [:route_id]))
    create(index(:sigra_auth_return_audit_events, [:occurred_at]))
  end
end
