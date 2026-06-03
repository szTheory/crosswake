defmodule CrosswakeExample.Repo.Migrations.CreateChimewayNotificationOpenIntents do
  use Ecto.Migration

  def change do
    create table(:chimeway_notification_open_intents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :open_ref, :string, null: false
      add :binding_ref, :string, null: false
      add :route_id, :string, null: false
      add :action_ref, :string
      add :scope, :string
      add :metadata, :map
      add :state, :string, null: false, default: "issued"
      add :expires_at, :utc_datetime, null: false
      add :consumed_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:chimeway_notification_open_intents, [:open_ref])

    create table(:chimeway_notification_open_intent_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :open_intent_id, references(:chimeway_notification_open_intents, type: :binary_id, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :occurred_at, :utc_datetime, null: false
      add :details, :map
    end

    create index(:chimeway_notification_open_intent_events, [:open_intent_id])
  end
end
