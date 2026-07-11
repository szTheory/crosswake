defmodule CrosswakeExample.FieldService.EvidenceEvent do
  @moduledoc """
  Append-only Fieldserv evidence workflow event.

  Metadata is limited to low-cardinality support context. It must not carry
  tokens, session refs, provider payloads, or native secret material.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @event_types [
    "inspection_started",
    "inspection_step_completed",
    "note_recorded_online",
    "capture_intent_requested",
    "device_evidence_recorded",
    "upload_prepare_requested",
    "backend_verification_started",
    "backend_verified_available",
    "backend_rejected",
    "offline_degraded_detected"
  ]

  @statuses [
    "device_evidence_recorded",
    "backend_verification_pending",
    "backend_verified",
    "backend_rejected"
  ]

  schema "field_service_evidence_events" do
    field(:event_id, :string)
    field(:job_id, :string)
    field(:evidence_id, :string)
    field(:asset_id, :string)
    field(:technician_id, :string)
    field(:event_type, :string)
    field(:status, :string)
    field(:route_id, :string)
    field(:support_ref, :string)
    field(:occurred_at, :utc_datetime)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  def event_types, do: @event_types
  def statuses, do: @statuses

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :event_id,
      :job_id,
      :evidence_id,
      :asset_id,
      :technician_id,
      :event_type,
      :status,
      :route_id,
      :support_ref,
      :occurred_at,
      :metadata
    ])
    |> validate_required([
      :event_id,
      :job_id,
      :evidence_id,
      :asset_id,
      :technician_id,
      :event_type,
      :status,
      :route_id,
      :support_ref,
      :occurred_at
    ])
    |> validate_inclusion(:event_type, @event_types)
    |> validate_inclusion(:status, @statuses)
    |> sanitize_metadata()
    |> unique_constraint(:event_id)
  end

  defp sanitize_metadata(changeset) do
    metadata = get_field(changeset, :metadata) || %{}
    put_change(changeset, :metadata, support_metadata(metadata))
  end

  defp support_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.reject(fn {key, _value} ->
      key in [
        :token,
        "token",
        :session,
        "session",
        :session_ref,
        "session_ref",
        :provider_payload,
        "provider_payload",
        :secret,
        "secret"
      ]
    end)
    |> Map.new(fn {key, value} -> {to_string(key), stringify_metadata_value(value)} end)
  end

  defp stringify_metadata_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_metadata_value(value), do: value
end
