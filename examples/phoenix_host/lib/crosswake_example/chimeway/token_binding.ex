defmodule CrosswakeExample.Chimeway.TokenBinding do
  @moduledoc """
  Mutable backend-owned projection of Chimeway notification token binding lifecycle.

  Stores only `token_ref` and `token_fingerprint` — never raw APNs/FCM token
  material. Subject, org, and session identity comes from backend context only;
  token possession does not choose these fields.

  Enforces closed Chimeway vocabularies via `Ecto.Enum` backed by string columns.
  Active-identity and authority-scope uniqueness rules use named unique constraints
  that match the partial unique indexes in the binding migration.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CrosswakeExample.Chimeway.MetadataSanitizer

  @subject_scopes [:subject_session, :subject_installation]

  schema "chimeway_token_bindings" do
    field(:binding_ref, :string)
    field(:subject_scope, Ecto.Enum, values: @subject_scopes)
    field(:subject_ref, :string)
    field(:org_ref, :string)
    field(:session_ref, :string)
    field(:session_version, :integer)
    field(:installation_ref, :string)
    field(:provider, Ecto.Enum, values: [:apns, :fcm])
    field(:platform, Ecto.Enum, values: [:ios, :android])
    field(:environment, Ecto.Enum, values: [:sandbox, :production, :development, :unknown])

    field(:app_identity_posture, Ecto.Enum,
      values: [:matched, :mismatched, :unknown],
      default: :unknown
    )

    field(:app_identity_ref, :string)
    field(:token_ref, :string)
    field(:token_fingerprint, :string)

    field(:notification_status, Ecto.Enum, values: [:granted, :denied, :restricted])

    field(:state, Ecto.Enum, values: [:active, :superseded, :revoked, :stale, :invalid])

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

    field(:bound_at, :utc_datetime)
    field(:last_seen_at, :utc_datetime)
    field(:superseded_at, :utc_datetime)
    field(:revoked_at, :utc_datetime)
    field(:stale_at, :utc_datetime)
    field(:invalidated_at, :utc_datetime)
    field(:audit_correlation_ref, :string)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  @required [
    :binding_ref,
    :subject_scope,
    :subject_ref,
    :org_ref,
    :installation_ref,
    :provider,
    :platform,
    :environment,
    :token_ref,
    :token_fingerprint,
    :notification_status,
    :state,
    :reason,
    :bound_at,
    :last_seen_at,
    :audit_correlation_ref
  ]

  @optional [
    :session_ref,
    :session_version,
    :app_identity_posture,
    :app_identity_ref,
    :superseded_at,
    :revoked_at,
    :stale_at,
    :invalidated_at,
    :metadata
  ]

  @doc false
  def changeset(binding, attrs) do
    binding
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_scope_consistency()
    |> sanitize_metadata()
    |> unique_constraint(:binding_ref,
      name: :chimeway_token_bindings_binding_ref_index
    )
    |> unique_constraint(
      [
        :token_fingerprint,
        :provider,
        :platform,
        :environment,
        :app_identity_posture,
        :app_identity_ref
      ],
      name: :chimeway_token_bindings_active_token_identity_index
    )
    |> unique_constraint(
      [
        :subject_ref,
        :org_ref,
        :session_ref,
        :session_version,
        :installation_ref,
        :provider,
        :platform,
        :environment,
        :app_identity_posture,
        :app_identity_ref
      ],
      name: :chimeway_token_bindings_active_subject_session_scope_index
    )
    |> unique_constraint(
      [
        :subject_ref,
        :org_ref,
        :installation_ref,
        :provider,
        :platform,
        :environment,
        :app_identity_posture,
        :app_identity_ref
      ],
      name: :chimeway_token_bindings_active_subject_installation_scope_index
    )
  end

  defp validate_scope_consistency(changeset) do
    case get_field(changeset, :subject_scope) do
      :subject_session ->
        # WR-05: session_version is semantically required for session-scoped bindings;
        # without it, version-guarded revocation (D-21) always matches the nil-version row.
        changeset
        |> validate_required([:session_ref, :session_version])
        |> validate_number(:session_version, greater_than_or_equal_to: 0)

      :subject_installation ->
        changeset

      _other ->
        changeset
    end
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
