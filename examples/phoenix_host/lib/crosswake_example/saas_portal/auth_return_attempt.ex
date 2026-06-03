defmodule CrosswakeExample.SaaSPortal.AuthReturnAttempt do
  @moduledoc """
  Example-host Sigra auth-return attempt record.

  This schema is host-owned. Crosswake core defines pure contracts; Phoenix hosts
  own the durable replay, expiry, and audit source used before authority
  promotion.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "sigra_auth_return_attempts" do
    field(:attempt_ref, :string)
    field(:attempt_digest, :string)
    field(:kind, Ecto.Enum, values: [:oauth, :passkey, :native_auth])
    field(:state, Ecto.Enum, values: [:issued, :consumed, :expired, :revoked])
    field(:subject_ref, :string)
    field(:org_id, :string)
    field(:source_session_ref, :string)
    field(:expected_session_version, :integer)
    field(:device_ref, :string)
    field(:route_id, :string)
    field(:return_route_id, :string)

    field(:transport, Ecto.Enum,
      values: [:http_callback, :verified_https_link, :custom_scheme, :bridge_event]
    )

    field(:link_verification, Ecto.Enum,
      values: [:verified, :unverified, :missing, :stale, :unknown, :not_applicable]
    )

    field(:state_digest, :string)
    field(:nonce_digest, :string)
    field(:pkce_challenge_digest, :string)
    field(:pkce_method, :string)
    field(:expected_callback, :string)
    field(:provider_audience, :string)
    field(:return_params, :map, default: %{})
    field(:issued_at, :utc_datetime)
    field(:expires_at, :utc_datetime)
    field(:consumed_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
    field(:revocation_reason, :string)
    field(:audit_correlation_ref, :string)
    field(:projected_session_authority, :map)

    timestamps(type: :utc_datetime)
  end

  @required [
    :attempt_ref,
    :attempt_digest,
    :kind,
    :state,
    :subject_ref,
    :org_id,
    :source_session_ref,
    :expected_session_version,
    :route_id,
    :return_route_id,
    :transport,
    :link_verification,
    :issued_at,
    :expires_at,
    :audit_correlation_ref,
    :projected_session_authority
  ]

  @optional [
    :device_ref,
    :state_digest,
    :nonce_digest,
    :pkce_challenge_digest,
    :pkce_method,
    :expected_callback,
    :provider_audience,
    :return_params,
    :consumed_at,
    :revoked_at,
    :revocation_reason
  ]

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:attempt_ref)
    |> unique_constraint(:attempt_digest)
  end
end
