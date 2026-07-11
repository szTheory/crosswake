defmodule CrosswakeExample.SaaSPortal.ApprovalActivityEvent do
  @moduledoc """
  Append-only AdminPilot approval activity evidence.

  Event metadata is intentionally low-cardinality support context. It must not
  carry tokens, session refs, provider payloads, or other auth secrets.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @event_types ["approval_seeded", "approval_approved"]
  @outcomes ["seeded", "approved", "denied"]

  schema "saas_admin_approval_activity_events" do
    field(:event_id, :string)
    field(:approval_id, :string)
    field(:account_id, :string)
    field(:actor_id, :string)
    field(:event_type, :string)
    field(:outcome, :string)
    field(:route_id, :string)
    field(:support_ref, :string)
    field(:occurred_at, :utc_datetime)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  def event_types, do: @event_types
  def outcomes, do: @outcomes

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_id,
      :approval_id,
      :account_id,
      :actor_id,
      :event_type,
      :outcome,
      :route_id,
      :support_ref,
      :occurred_at,
      :metadata
    ])
    |> validate_required([
      :event_id,
      :approval_id,
      :account_id,
      :actor_id,
      :event_type,
      :outcome,
      :route_id,
      :support_ref,
      :occurred_at
    ])
    |> validate_inclusion(:event_type, @event_types)
    |> validate_inclusion(:outcome, @outcomes)
    |> unique_constraint(:event_id)
  end
end
