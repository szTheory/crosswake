defmodule CrosswakeExample.Chimeway.TokenBindingEvent do
  @moduledoc """
  Append-only Chimeway token binding lifecycle audit event record.

  Audit rows are first-class durable evidence written in the same transaction
  as binding lifecycle changes. They are never updated or deleted.

  Only allowlisted fields are accepted. Raw token material, provider payload
  bodies, notification content, route params, and PII are forbidden in metadata
  per D-27 and D-28.

  `actor_kind` is locked to [:backend, :provider, :maintenance].
  `proof_class` is locked to [:hermetic, :advisory, :not_applicable].
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CrosswakeExample.Chimeway.MetadataSanitizer

  schema "chimeway_token_binding_events" do
    field(:event_ref, :string)
    field(:event_type, Ecto.Enum, values: [:observed, :bound, :rotated, :revoked, :stale, :invalidated, :feedback])
    field(:binding_ref, :string)
    field(:token_ref, :string)
    field(:token_fingerprint, :string)
    field(:provider, Ecto.Enum, values: [:apns, :fcm])
    field(:platform, Ecto.Enum, values: [:ios, :android])
    field(:environment, Ecto.Enum, values: [:sandbox, :production, :development, :unknown])
    field(:installation_ref, :string)
    field(:subject_scope, Ecto.Enum, values: [:subject_session, :subject_installation])

    field(:state_before, Ecto.Enum,
      values: [:active, :superseded, :revoked, :stale, :invalid]
    )

    field(:state_after, Ecto.Enum,
      values: [:active, :superseded, :revoked, :stale, :invalid]
    )

    field(:reason, Ecto.Enum,
      values: [
        :initial_bind,
        :token_rotated,
        :logout_revoked,
        :session_revoked,
        :permission_denied,
        :provider_unregistered,
        :provider_invalid_token,
        :environment_mismatch,
        :app_identity_mismatch,
        :staleness_pruned,
        :manual_revocation
      ]
    )

    field(:feedback_event, Ecto.Enum,
      values: [
        :token_unregistered,
        :token_invalid,
        :environment_mismatch,
        :app_identity_mismatch,
        :credentials_invalid,
        :provider_throttled,
        :provider_unavailable,
        :delivery_accepted,
        :delivery_failed
      ]
    )

    field(:notification_status, Ecto.Enum, values: [:granted, :denied, :restricted])

    field(:app_identity_posture, Ecto.Enum,
      values: [:matched, :mismatched, :unknown],
      default: :unknown
    )

    field(:occurred_at, :utc_datetime)
    field(:correlation_id, :string)
    field(:request_ref, :string)
    field(:actor_kind, Ecto.Enum, values: [:backend, :provider, :maintenance])
    field(:proof_class, Ecto.Enum, values: [:hermetic, :advisory, :not_applicable])
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  @required [
    :event_ref,
    :event_type,
    :binding_ref,
    :occurred_at,
    :actor_kind,
    :proof_class
  ]

  @optional [
    :token_ref,
    :token_fingerprint,
    :provider,
    :platform,
    :environment,
    :installation_ref,
    :subject_scope,
    :state_before,
    :state_after,
    :reason,
    :feedback_event,
    :notification_status,
    :app_identity_posture,
    :correlation_id,
    :request_ref,
    :metadata
  ]

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> sanitize_metadata()
    |> unique_constraint(:event_ref,
      name: :chimeway_token_binding_events_event_ref_index
    )
  end

  defp sanitize_metadata(changeset) do
    case get_change(changeset, :metadata) do
      nil ->
        changeset

      metadata ->
        put_change(changeset, :metadata, MetadataSanitizer.sanitize(metadata))
    end
  end
end
