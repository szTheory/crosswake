defmodule CrosswakeExample.Chimeway.NotificationOpenIntentEvent do
  @moduledoc """
  Audit log events for NotificationOpenIntent lifecycle.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "chimeway_notification_open_intent_events" do
    belongs_to(:open_intent, CrosswakeExample.Chimeway.NotificationOpenIntent, type: :binary_id)
    field(:event_type, :string)
    field(:occurred_at, :utc_datetime)
    field(:details, :map)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :open_intent_id,
      :event_type,
      :occurred_at,
      :details
    ])
    |> validate_required([
      :open_intent_id,
      :event_type,
      :occurred_at
    ])
  end
end
