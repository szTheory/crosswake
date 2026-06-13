defmodule CrosswakeExample.Repo.Migrations.CreateCrosswakeAuditEvents do
  use Ecto.Migration

  def change do
    create table(:crosswake_audit_events) do
      add :thread_id, :string, null: false
      add :correlation_id, :string, null: false
      add :route_id, :string, null: false
      add :actor_ref, :string, null: false
      add :actor_kind, :string, null: false
      add :event_class, :string, null: false
      add :event_type, :string, null: false
      add :outcome, :string, null: false
      add :provenance, :string, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      add :recorded_at, :utc_datetime_usec, null: false
      add :idempotency_key, :string, null: false
      add :metadata, :map
      add :row_hash, :string
      add :prev_hash, :string
      # Host-optional extension beyond LEDG-02 contract — see CrosswakeExample.Audit.Ledger
      add :tier, :string
    end

    create unique_index(:crosswake_audit_events, [:idempotency_key])
  end
end
