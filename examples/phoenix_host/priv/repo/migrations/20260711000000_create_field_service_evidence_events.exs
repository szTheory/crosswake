defmodule CrosswakeExample.Repo.Migrations.CreateFieldServiceEvidenceEvents do
  use Ecto.Migration

  def change do
    create table(:field_service_evidence_events) do
      add(:event_id, :string, null: false)
      add(:job_id, :string, null: false)
      add(:evidence_id, :string, null: false)
      add(:asset_id, :string, null: false)
      add(:technician_id, :string, null: false)
      add(:event_type, :string, null: false)
      add(:status, :string, null: false)
      add(:route_id, :string, null: false)
      add(:support_ref, :string, null: false)
      add(:occurred_at, :utc_datetime, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:field_service_evidence_events, [:event_id]))
    create(index(:field_service_evidence_events, [:job_id]))
    create(index(:field_service_evidence_events, [:evidence_id]))
    create(index(:field_service_evidence_events, [:job_id, :evidence_id]))
    create(index(:field_service_evidence_events, [:event_type]))
    create(index(:field_service_evidence_events, [:status]))

    create table(:field_service_technician_job_states) do
      add(:job_id, :string, null: false)
      add(:technician_id, :string, null: false)
      add(:status, :string, null: false)
      add(:last_event_id, :string, null: false)
      add(:route_id, :string, null: false)
      add(:support_ref, :string, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:field_service_technician_job_states, [:job_id]))
    create(index(:field_service_technician_job_states, [:technician_id]))
    create(index(:field_service_technician_job_states, [:status]))
    create(index(:field_service_technician_job_states, [:route_id]))
  end
end
