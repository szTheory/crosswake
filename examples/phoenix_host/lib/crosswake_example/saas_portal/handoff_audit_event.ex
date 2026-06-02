defmodule CrosswakeExample.SaaSPortal.HandoffAuditEvent do
  @moduledoc """
  Append-only Sigra handoff lifecycle evidence for the example host.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @event_types ["issue", "redeem", "revoke", "expire", "deny"]
  @outcomes ["allowed", "denied"]

  schema "sigra_handoff_audit_events" do
    field(:event_id, :string)
    field(:event_type, :string)
    field(:handoff_ref, :string)
    field(:ticket_ref, :string)
    field(:state_before, :string)
    field(:state_after, :string)
    field(:outcome, :string)
    field(:denial_code, :string)
    field(:occurred_at, :utc_datetime)
    field(:route_id, :string)
    field(:intent_kind, :string)
    field(:intent_ref, :string)
    field(:source_session_ref, :string)
    field(:projected_session_ref, :string)
    field(:session_version_before, :integer)
    field(:session_version_after, :integer)
    field(:assurance_after, :string)
    field(:authn_methods_after, :map)
    field(:binding_result, :string)
    field(:request_ref, :string)
    field(:actor_kind, :string)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_id,
      :event_type,
      :handoff_ref,
      :ticket_ref,
      :state_before,
      :state_after,
      :outcome,
      :denial_code,
      :occurred_at,
      :route_id,
      :intent_kind,
      :intent_ref,
      :source_session_ref,
      :projected_session_ref,
      :session_version_before,
      :session_version_after,
      :assurance_after,
      :authn_methods_after,
      :binding_result,
      :request_ref,
      :actor_kind,
      :metadata
    ])
    |> validate_required([
      :event_id,
      :event_type,
      :handoff_ref,
      :outcome,
      :occurred_at,
      :route_id,
      :intent_kind,
      :request_ref,
      :actor_kind
    ])
    |> validate_inclusion(:event_type, @event_types)
    |> validate_inclusion(:outcome, @outcomes)
    |> unique_constraint(:event_id)
  end
end
