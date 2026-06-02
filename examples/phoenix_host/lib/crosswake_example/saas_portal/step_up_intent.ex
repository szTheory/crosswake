defmodule CrosswakeExample.SaaSPortal.StepUpIntent do
  @moduledoc """
  Authoritative one-time Sigra step-up intent record for the example host.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @states ["issued", "challenged", "consumed", "expired", "canceled", "revoked"]

  schema "sigra_step_up_intents" do
    field(:intent_ref, :string)
    field(:locator_digest, :string)
    field(:state, :string, default: "issued")
    field(:subject_ref, :string)
    field(:org_id, :string)
    field(:source_session_ref, :string)
    field(:expected_session_version, :integer)
    field(:device_ref, :string)
    field(:source_route_id, :string)
    field(:return_route_id, :string)
    field(:return_params, :map, default: %{})
    field(:required_assurance_level, :string)
    field(:required_auth_posture, :string)
    field(:max_auth_age_seconds, :integer)
    field(:challenge_kind, :string)
    field(:issued_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
    field(:challenged_at, :utc_datetime)
    field(:consumed_at, :utc_datetime)
    field(:canceled_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
    field(:cancellation_reason, :string)
    field(:revocation_reason, :string)
    field(:audit_correlation_ref, :string)
    field(:projected_session_ref, :string)
    field(:projected_session_version, :integer)
    field(:projected_authority, :map)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(intent, attrs) do
    intent
    |> cast(attrs, [
      :intent_ref,
      :locator_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :device_ref,
      :source_route_id,
      :return_route_id,
      :return_params,
      :required_assurance_level,
      :required_auth_posture,
      :max_auth_age_seconds,
      :challenge_kind,
      :issued_at,
      :expires_at,
      :challenged_at,
      :consumed_at,
      :canceled_at,
      :revoked_at,
      :cancellation_reason,
      :revocation_reason,
      :audit_correlation_ref,
      :projected_session_ref,
      :projected_session_version,
      :projected_authority
    ])
    |> validate_required([
      :intent_ref,
      :locator_digest,
      :state,
      :subject_ref,
      :org_id,
      :source_session_ref,
      :expected_session_version,
      :source_route_id,
      :return_route_id,
      :required_assurance_level,
      :required_auth_posture,
      :max_auth_age_seconds,
      :challenge_kind,
      :issued_at,
      :expires_at,
      :audit_correlation_ref,
      :projected_session_ref,
      :projected_session_version,
      :projected_authority
    ])
    |> validate_inclusion(:state, @states)
    |> unique_constraint(:intent_ref)
    |> unique_constraint(:locator_digest)
  end
end
