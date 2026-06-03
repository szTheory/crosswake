defmodule CrosswakeExample.Chimeway.NotificationOpenIntent do
  @moduledoc """
  Authoritative one-time Chimeway notification open intent record for the example host.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @states ["issued", "consumed", "revoked"]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "chimeway_notification_open_intents" do
    field(:open_ref, :string)
    field(:binding_ref, :string)
    field(:route_id, :string)
    field(:action_ref, :string)
    field(:scope, :string)
    field(:metadata, :map)
    field(:state, :string, default: "issued")
    field(:expires_at, :utc_datetime)
    field(:consumed_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(intent, attrs) do
    intent
    |> cast(attrs, [
      :open_ref,
      :binding_ref,
      :route_id,
      :action_ref,
      :scope,
      :metadata,
      :state,
      :expires_at,
      :consumed_at
    ])
    |> validate_required([
      :open_ref,
      :binding_ref,
      :route_id,
      :state,
      :expires_at
    ])
    |> validate_inclusion(:state, @states)
    |> unique_constraint(:open_ref)
  end
end
