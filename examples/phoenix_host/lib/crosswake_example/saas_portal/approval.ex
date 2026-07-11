defmodule CrosswakeExample.SaaSPortal.Approval do
  @moduledoc """
  Persisted AdminPilot approval evidence.

  Static account, team, member, role, and settings context remains fixture-owned;
  this schema only records mutable approval workflow state.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ["pending", "approved", "rejected"]

  schema "saas_admin_approvals" do
    field(:approval_id, :string)
    field(:account_id, :string)
    field(:title, :string)
    field(:status, :string, default: "pending")
    field(:requested_by, :string)
    field(:reviewed_by, :string)
    field(:policy_id, :string)
    field(:support_ref, :string)
    field(:route_id, :string)
    field(:requested_at, :utc_datetime)
    field(:reviewed_at, :utc_datetime)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(approval, attrs) do
    approval
    |> cast(attrs, [
      :approval_id,
      :account_id,
      :title,
      :status,
      :requested_by,
      :reviewed_by,
      :policy_id,
      :support_ref,
      :route_id,
      :requested_at,
      :reviewed_at,
      :metadata
    ])
    |> validate_required([
      :approval_id,
      :account_id,
      :title,
      :status,
      :requested_by,
      :policy_id,
      :support_ref,
      :route_id,
      :requested_at
    ])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:approval_id)
  end
end
