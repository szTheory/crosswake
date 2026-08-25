defmodule CrosswakeExample.Chimeway.NotificationOpenIntent do
  @moduledoc """
  Authoritative one-time Chimeway notification open intent record for the example host.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CrosswakeExample.Chimeway.MetadataSanitizer

  @states ["issued", "consumed", "revoked"]
  @scopes ["subject_session", "subject_installation"]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "chimeway_notification_open_intents" do
    field(:open_ref, :string)
    field(:binding_ref, :string)
    field(:tenant_ref, :string)
    field(:subject_ref, :string)
    field(:session_ref, :string)
    field(:session_version, :integer)
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
    attrs = normalize_metadata_attr(attrs)

    intent
    |> cast(attrs, [
      :open_ref,
      :binding_ref,
      :tenant_ref,
      :subject_ref,
      :session_ref,
      :session_version,
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
      :tenant_ref,
      :subject_ref,
      :route_id,
      :scope,
      :state,
      :expires_at
    ])
    |> sanitize_metadata()
    |> validate_inclusion(:scope, @scopes)
    |> validate_scope_consistency()
    |> validate_inclusion(:state, @states)
    |> unique_constraint(:open_ref)
  end

  defp validate_scope_consistency(changeset) do
    case get_field(changeset, :scope) do
      "subject_session" ->
        changeset
        |> validate_required([:session_ref, :session_version])
        |> validate_number(:session_version, greater_than_or_equal_to: 0)

      "subject_installation" ->
        if is_nil(get_field(changeset, :session_ref)) and
             is_nil(get_field(changeset, :session_version)) do
          changeset
        else
          add_error(changeset, :scope, "requires nil session authority")
        end

      _ ->
        changeset
    end
  end

  defp sanitize_metadata(changeset) do
    case get_change(changeset, :metadata) do
      nil -> changeset
      metadata ->
        put_change(changeset, :metadata, MetadataSanitizer.sanitize_notification_open(metadata))
    end
  end

  defp normalize_metadata_attr(attrs) when is_map(attrs) do
    case Map.fetch(attrs, :metadata) do
      {:ok, metadata} when not is_map(metadata) -> Map.put(attrs, :metadata, %{})
      {:ok, _metadata} -> attrs
      :error -> normalize_string_metadata_attr(attrs)
    end
  end

  defp normalize_metadata_attr(attrs), do: attrs

  defp normalize_string_metadata_attr(attrs) do
    case Map.fetch(attrs, "metadata") do
      {:ok, metadata} when not is_map(metadata) -> Map.put(attrs, "metadata", %{})
      _ -> attrs
    end
  end
end
