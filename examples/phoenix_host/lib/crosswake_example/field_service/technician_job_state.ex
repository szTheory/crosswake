defmodule CrosswakeExample.FieldService.TechnicianJobState do
  @moduledoc """
  Narrow server-owned Fieldserv technician/job state.

  This is not an offline journal or outbox. It records the current server-side
  evidence status for the representative Fieldserv workflow.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses [
    "device_evidence_recorded",
    "backend_verification_pending",
    "backend_verified",
    "backend_rejected"
  ]

  schema "field_service_technician_job_states" do
    field(:job_id, :string)
    field(:technician_id, :string)
    field(:status, :string)
    field(:last_event_id, :string)
    field(:route_id, :string)
    field(:support_ref, :string)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(state, attrs) do
    state
    |> cast(attrs, [
      :job_id,
      :technician_id,
      :status,
      :last_event_id,
      :route_id,
      :support_ref,
      :metadata
    ])
    |> validate_required([
      :job_id,
      :technician_id,
      :status,
      :last_event_id,
      :route_id,
      :support_ref
    ])
    |> validate_inclusion(:status, @statuses)
    |> sanitize_metadata()
    |> unique_constraint(:job_id)
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
        "secret",
        :outbox,
        "outbox",
        :journal,
        "journal"
      ]
    end)
    |> Map.new(fn {key, value} -> {to_string(key), stringify_metadata_value(value)} end)
  end

  defp stringify_metadata_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_metadata_value(value), do: value
end
