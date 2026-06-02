defmodule CrosswakeExample.SaaSPortal.AuthReturnAuditEvent do
  @moduledoc """
  Example-host append-only Sigra auth-return audit event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "sigra_auth_return_audit_events" do
    field(:event_id, :string)
    field(:event_type, Ecto.Enum, values: [:issue, :validate, :consume, :expire, :revoke, :deny])
    field(:auth_return_ref, :string)
    field(:attempt_ref, :string)
    field(:state_before, Ecto.Enum, values: [:issued, :consumed, :expired, :revoked])
    field(:state_after, Ecto.Enum, values: [:issued, :consumed, :expired, :revoked])
    field(:outcome, Ecto.Enum, values: [:allowed, :denied])
    field(:denial_code, :string)
    field(:occurred_at, :utc_datetime)
    field(:route_id, :string)
    field(:kind, Ecto.Enum, values: [:oauth, :passkey, :native_auth])
    field(:source_session_ref, :string)
    field(:projected_session_ref, :string)
    field(:session_version_before, :integer)
    field(:session_version_after, :integer)
    field(:assurance_after, Ecto.Enum, values: [:none, :password, :mfa, :phishing_resistant])
    field(:authn_methods_after, :map)
    field(:binding_result, :string)
    field(:request_ref, :string)
    field(:actor_kind, :string)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  @required [
    :event_id,
    :event_type,
    :auth_return_ref,
    :outcome,
    :occurred_at,
    :route_id,
    :kind,
    :request_ref,
    :actor_kind
  ]

  @optional [
    :attempt_ref,
    :state_before,
    :state_after,
    :denial_code,
    :source_session_ref,
    :projected_session_ref,
    :session_version_before,
    :session_version_after,
    :assurance_after,
    :authn_methods_after,
    :binding_result,
    :metadata
  ]

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:event_id)
  end
end
