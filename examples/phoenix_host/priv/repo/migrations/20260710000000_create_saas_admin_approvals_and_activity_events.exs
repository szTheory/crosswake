defmodule CrosswakeExample.Repo.Migrations.CreateSaasAdminApprovalsAndActivityEvents do
  use Ecto.Migration

  def change do
    create table(:saas_admin_approvals) do
      add(:approval_id, :string, null: false)
      add(:account_id, :string, null: false)
      add(:title, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:requested_by, :string, null: false)
      add(:reviewed_by, :string)
      add(:policy_id, :string, null: false)
      add(:support_ref, :string, null: false)
      add(:route_id, :string, null: false)
      add(:requested_at, :utc_datetime, null: false)
      add(:reviewed_at, :utc_datetime)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:saas_admin_approvals, [:approval_id]))
    create(index(:saas_admin_approvals, [:account_id]))
    create(index(:saas_admin_approvals, [:account_id, :status]))
    create(index(:saas_admin_approvals, [:route_id]))

    create table(:saas_admin_approval_activity_events) do
      add(:event_id, :string, null: false)
      add(:approval_id, :string, null: false)
      add(:account_id, :string, null: false)
      add(:actor_id, :string, null: false)
      add(:event_type, :string, null: false)
      add(:outcome, :string, null: false)
      add(:route_id, :string, null: false)
      add(:support_ref, :string, null: false)
      add(:occurred_at, :utc_datetime, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:saas_admin_approval_activity_events, [:event_id]))
    create(index(:saas_admin_approval_activity_events, [:account_id]))
    create(index(:saas_admin_approval_activity_events, [:approval_id]))
    create(index(:saas_admin_approval_activity_events, [:account_id, :approval_id]))
    create(index(:saas_admin_approval_activity_events, [:event_type]))
    create(index(:saas_admin_approval_activity_events, [:occurred_at]))
  end
end
