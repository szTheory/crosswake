defmodule CrosswakeExample.Repo.Migrations.CreateChimewayTokenBindingEvents do
  use Ecto.Migration

  def change do
    create table(:chimeway_token_binding_events) do
      add(:event_ref, :string, null: false)
      add(:event_type, :string, null: false)
      add(:binding_ref, :string, null: false)
      add(:token_ref, :string)
      add(:token_fingerprint, :string)
      add(:provider, :string)
      add(:platform, :string)
      add(:environment, :string)
      add(:installation_ref, :string)
      add(:subject_scope, :string)
      add(:state_before, :string)
      add(:state_after, :string)
      add(:reason, :string)
      add(:feedback_event, :string)
      add(:notification_status, :string)
      add(:app_identity_posture, :string, default: "unknown")
      add(:occurred_at, :utc_datetime, null: false)
      add(:correlation_id, :string)
      add(:request_ref, :string)
      add(:actor_kind, :string, null: false)
      add(:proof_class, :string, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    # Unique audit event identity — append-only guarantee
    create(
      unique_index(:chimeway_token_binding_events, [:event_ref],
        name: :chimeway_token_binding_events_event_ref_index
      )
    )

    # Lookup indexes for audit queries
    create(index(:chimeway_token_binding_events, [:binding_ref]))
    create(index(:chimeway_token_binding_events, [:event_type]))
    create(index(:chimeway_token_binding_events, [:occurred_at]))
    create(index(:chimeway_token_binding_events, [:correlation_id]))
    create(index(:chimeway_token_binding_events, [:request_ref]))

    # No foreign key or cascade-delete path.
    # Audit rows are durable support-safe evidence and must not be deleted when
    # a binding row changes state or is superseded. Any cascade-delete path
    # would destroy the append-only audit guarantee.
  end
end
