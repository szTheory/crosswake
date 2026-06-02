defmodule CrosswakeExample.SaaSPortal.HandoffTicket do
  @moduledoc """
  Authoritative one-time Sigra handoff ticket record for the example host.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @states ["issued", "redeemed", "expired", "revoked"]
  @binding_kinds ["session_route_intent", "session_route_intent_device"]

  schema "sigra_handoff_tickets" do
    field(:ticket_ref, :string)
    field(:ticket_digest, :string)
    field(:state, :string, default: "issued")
    field(:subject_ref, :string)
    field(:org_id, :string)
    field(:source_session_ref, :string)
    field(:expected_session_version, :integer)
    field(:device_ref, :string)
    field(:binding_kind, :string, default: "session_route_intent")
    field(:intent_kind, :string, default: "session_handoff")
    field(:intent_ref, :string)
    field(:source_route_id, :string)
    field(:target_route_id, :string)
    field(:required_assurance_level, :string)
    field(:required_auth_posture, :string)
    field(:issued_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
    field(:consumed_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
    field(:revocation_reason, :string)
    field(:audit_correlation_ref, :string)
    field(:projected_session_ref, :string)
    field(:projected_session_version, :integer)
    field(:projected_authority, :map)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [
      :ticket_ref,
      :ticket_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :device_ref,
      :binding_kind,
      :intent_kind,
      :intent_ref,
      :source_route_id,
      :target_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :issued_at,
      :expires_at,
      :consumed_at,
      :revoked_at,
      :revocation_reason,
      :audit_correlation_ref,
      :projected_session_ref,
      :projected_session_version,
      :projected_authority
    ])
    |> validate_required([
      :ticket_ref,
      :ticket_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :binding_kind,
      :intent_kind,
      :target_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :issued_at,
      :expires_at,
      :audit_correlation_ref,
      :projected_session_ref,
      :projected_session_version,
      :projected_authority
    ])
    |> validate_inclusion(:state, @states)
    |> validate_inclusion(:binding_kind, @binding_kinds)
    |> unique_constraint(:ticket_ref)
    |> unique_constraint(:ticket_digest)
  end
end
