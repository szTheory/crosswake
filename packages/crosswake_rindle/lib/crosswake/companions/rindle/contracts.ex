defmodule Crosswake.Companions.Rindle.Contracts do
  @moduledoc """
  Typed media seam contracts for the first-party Rindle companion.

  These structs model server-issued upload grants, device capture evidence, and
  backend-owned media availability state. Device evidence can report an upload;
  it cannot directly make media available.
  """

  defmodule UploadGrant do
    @moduledoc """
    Backend-issued permission to upload one media object.
    """
    @enforce_keys [
      :grant_id,
      :idempotency_key,
      :expires_at,
      :max_bytes,
      :accepted_types,
      :key_prefix,
      :storage_target
    ]
    defstruct [
      :grant_id,
      :idempotency_key,
      :expires_at,
      :max_bytes,
      :accepted_types,
      :key_prefix,
      :storage_target,
      integrity_algorithms: []
    ]

    @type t :: %__MODULE__{
            grant_id: String.t(),
            idempotency_key: String.t(),
            expires_at: String.t(),
            max_bytes: pos_integer(),
            accepted_types: [String.t()],
            key_prefix: String.t(),
            storage_target: String.t(),
            integrity_algorithms: [String.t()]
          }
  end

  defmodule CaptureEvidence do
    @moduledoc """
    Evidence reported after a device or native upload attempt.

    This evidence echoes server-issued grant identity and records observations.
    It is not an availability or authority lane.
    """
    @enforce_keys [:grant_id, :idempotency_key, :storage_key, :mime, :bytes, :captured_at]
    defstruct [
      :grant_id,
      :idempotency_key,
      :storage_key,
      :mime,
      :bytes,
      :captured_at,
      :client_upload_ref,
      :content_hash,
      :multipart,
      :correlation_id,
      :trace_metadata,
      source: :device
    ]

    @type source :: :device | :backend | :scanner | :support

    @type t :: %__MODULE__{
            grant_id: String.t(),
            idempotency_key: String.t(),
            storage_key: String.t(),
            mime: String.t(),
            bytes: pos_integer(),
            captured_at: String.t(),
            client_upload_ref: String.t() | nil,
            content_hash: String.t() | nil,
            multipart: map() | nil,
            correlation_id: String.t() | nil,
            trace_metadata: map() | nil,
            source: source()
          }
  end

  defmodule MediaObject do
    @moduledoc """
    Backend-owned media projection and availability state.
    """
    @enforce_keys [:media_object_id, :subject_key, :storage_key, :state, :as_of]
    defstruct [
      :media_object_id,
      :subject_key,
      :storage_key,
      :state,
      :as_of,
      :verification_ref,
      :rejection_reason,
      :authoritative_at,
      :trace_metadata
    ]

    @type state :: :queued | :uploaded | :scanning | :available | :rejected

    @type t :: %__MODULE__{
            media_object_id: String.t(),
            subject_key: String.t(),
            storage_key: String.t(),
            state: state(),
            as_of: String.t() | non_neg_integer(),
            verification_ref: String.t() | nil,
            rejection_reason: String.t() | atom() | nil,
            authoritative_at: String.t() | nil,
            trace_metadata: map() | nil
          }
  end

  @media_state_vocabulary [:queued, :uploaded, :scanning, :available, :rejected]
  @capture_evidence_source_vocabulary [:device, :backend, :scanner, :support]
  @capture_evidence_source_by_string Map.new(@capture_evidence_source_vocabulary, &{Atom.to_string(&1), &1})

  @spec media_state_vocabulary() :: [MediaObject.state()]
  def media_state_vocabulary, do: @media_state_vocabulary

  @spec capture_evidence_source_vocabulary() :: [CaptureEvidence.source()]
  def capture_evidence_source_vocabulary, do: @capture_evidence_source_vocabulary

  @spec canonical_capture_evidence_source(term()) ::
          {:ok, CaptureEvidence.source()} | {:error, {:invalid_source, keyword()}}
  def canonical_capture_evidence_source(source) when is_atom(source) do
    if source in @capture_evidence_source_vocabulary do
      {:ok, source}
    else
      {:error, {:invalid_source, invalid_source_details(source)}}
    end
  end

  def canonical_capture_evidence_source(source) when is_binary(source) do
    case Map.fetch(@capture_evidence_source_by_string, source) do
      {:ok, canonical_source} -> {:ok, canonical_source}
      :error -> {:error, {:invalid_source, invalid_source_details(source)}}
    end
  end

  def canonical_capture_evidence_source(source) do
    {:error, {:invalid_source, invalid_source_details(source)}}
  end

  @spec new_upload_grant(map() | keyword()) :: {:ok, UploadGrant.t()} | {:error, keyword()}
  def new_upload_grant(attrs), do: build_and_validate(attrs, UploadGrant, &validate_upload_grant/1, :upload_grant)

  @spec new_capture_evidence(map() | keyword()) :: {:ok, CaptureEvidence.t()} | {:error, keyword()}
  def new_capture_evidence(attrs), do: build_and_validate(attrs, CaptureEvidence, &validate_capture_evidence/1, :capture_evidence)

  @spec new_media_object(map() | keyword()) :: {:ok, MediaObject.t()} | {:error, keyword()}
  def new_media_object(attrs), do: build_and_validate(attrs, MediaObject, &validate_media_object/1, :media_object)

  @spec validate_upload_grant(UploadGrant.t()) :: :ok | {:error, keyword()}
  def validate_upload_grant(%UploadGrant{} = grant) do
    []
    |> validate_required_string(:grant_id, grant.grant_id)
    |> validate_required_string(:idempotency_key, grant.idempotency_key)
    |> validate_required_string(:expires_at, grant.expires_at)
    |> validate_positive_integer(:max_bytes, grant.max_bytes)
    |> validate_string_list(:accepted_types, grant.accepted_types)
    |> validate_required_string(:key_prefix, grant.key_prefix)
    |> validate_required_string(:storage_target, grant.storage_target)
    |> to_validation_result()
  end

  def validate_upload_grant(_grant), do: {:error, [upload_grant: :invalid_contract]}

  @spec validate_capture_evidence(CaptureEvidence.t()) :: :ok | {:error, keyword()}
  def validate_capture_evidence(%CaptureEvidence{} = evidence) do
    []
    |> validate_required_string(:grant_id, evidence.grant_id)
    |> validate_required_string(:idempotency_key, evidence.idempotency_key)
    |> validate_required_string(:storage_key, evidence.storage_key)
    |> validate_required_string(:mime, evidence.mime)
    |> validate_positive_integer(:bytes, evidence.bytes)
    |> validate_evidence_source(evidence.source)
    |> reject_trace_authority_lane(evidence.trace_metadata)
    |> to_validation_result()
  end

  def validate_capture_evidence(_evidence), do: {:error, [capture_evidence: :invalid_contract]}

  @spec validate_media_object(MediaObject.t()) :: :ok | {:error, keyword()}
  def validate_media_object(%MediaObject{} = media_object) do
    []
    |> validate_required_string(:media_object_id, media_object.media_object_id)
    |> validate_required_string(:subject_key, media_object.subject_key)
    |> validate_required_string(:storage_key, media_object.storage_key)
    |> validate_media_state(media_object.state)
    |> validate_available_backend_fields(media_object)
    |> validate_rejected_reason(media_object)
    |> to_validation_result()
  end

  def validate_media_object(_media_object), do: {:error, [media_object: :invalid_contract]}

  @spec verified_media_object(MediaObject.t(), keyword()) ::
          {:ok, MediaObject.t()} | {:error, :backend_verification_required | {:invalid_source_state, term()}}
  def verified_media_object(%MediaObject{state: state} = media_object, opts) when state in [:uploaded, :scanning] do
    verification_ref = Keyword.get(opts, :verification_ref)
    authoritative_at = Keyword.get(opts, :authoritative_at)

    if present_string?(verification_ref) and present_string?(authoritative_at) do
      verified = %{
        media_object
        | state: :available,
          verification_ref: verification_ref,
          authoritative_at: authoritative_at,
          trace_metadata: Keyword.get(opts, :trace_metadata, media_object.trace_metadata)
      }

      {:ok, verified}
    else
      {:error, :backend_verification_required}
    end
  end

  def verified_media_object(%MediaObject{state: state}, _opts), do: {:error, {:invalid_source_state, state}}

  defp build_and_validate(attrs, module, validator, error_key) when is_list(attrs) do
    attrs
    |> Map.new()
    |> build_and_validate(module, validator, error_key)
  end

  defp build_and_validate(attrs, module, validator, error_key) when is_map(attrs) do
    with {:ok, contract} <- build_struct(module, attrs, error_key),
         :ok <- validator.(contract) do
      {:ok, contract}
    end
  end

  defp build_and_validate(_attrs, _module, _validator, error_key), do: {:error, [{error_key, :invalid_attrs}]}

  defp build_struct(module, attrs, error_key) do
    try do
      {:ok, struct!(module, attrs)}
    rescue
      error in [ArgumentError, KeyError] -> {:error, [{error_key, Exception.message(error)}]}
    end
  end

  defp validate_required_string(errors, field, value) do
    if present_string?(value), do: errors, else: [{field, :required} | errors]
  end

  defp validate_positive_integer(errors, _field, value) when is_integer(value) and value > 0, do: errors
  defp validate_positive_integer(errors, field, value), do: [{field, {:invalid_positive_integer, value}} | errors]

  defp validate_string_list(errors, field, values) when is_list(values) and values != [] do
    if Enum.all?(values, &present_string?/1), do: errors, else: [{field, :invalid_string_list} | errors]
  end

  defp validate_string_list(errors, field, _values), do: [{field, :invalid_string_list} | errors]

  defp validate_evidence_source(errors, source) do
    case canonical_capture_evidence_source(source) do
      {:ok, _source} -> errors
      {:error, reason} -> [{:source, reason} | errors]
    end
  end

  defp reject_trace_authority_lane(errors, trace_metadata) when is_map(trace_metadata) do
    errors
    |> reject_trace_key(trace_metadata, :authority_state)
    |> reject_trace_key(trace_metadata, :availability_state)
  end

  defp reject_trace_authority_lane(errors, _trace_metadata), do: errors

  defp reject_trace_key(errors, trace_metadata, key) do
    if Map.has_key?(trace_metadata, key) or Map.has_key?(trace_metadata, Atom.to_string(key)) do
      [{:trace_metadata, {key, :forbidden}} | errors]
    else
      errors
    end
  end

  defp validate_media_state(errors, state) do
    if state in @media_state_vocabulary do
      errors
    else
      [{:state, {:invalid_state, state}} | errors]
    end
  end

  defp validate_available_backend_fields(errors, %MediaObject{state: :available} = media_object) do
    if present_string?(media_object.verification_ref) and present_string?(media_object.authoritative_at) do
      errors
    else
      [{:state, :backend_verification_required} | errors]
    end
  end

  defp validate_available_backend_fields(errors, _media_object), do: errors

  defp validate_rejected_reason(errors, %MediaObject{state: :rejected, rejection_reason: reason}) do
    if present_value?(reason), do: errors, else: [{:state, :rejection_reason_required} | errors]
  end

  defp validate_rejected_reason(errors, _media_object), do: errors

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""
  defp present_value?(value) when is_binary(value), do: present_string?(value)
  defp present_value?(nil), do: false
  defp present_value?(_value), do: true

  defp invalid_source_details(source) do
    [
      source: source,
      allowed_sources: @capture_evidence_source_vocabulary,
      hint: "Use one of :device | :backend | :scanner | :support"
    ]
  end

  defp to_validation_result([]), do: :ok
  defp to_validation_result(errors), do: {:error, Enum.reverse(errors)}
end
