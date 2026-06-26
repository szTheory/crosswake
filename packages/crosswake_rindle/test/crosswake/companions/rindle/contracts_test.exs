defmodule Crosswake.Companions.Rindle.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Companions.Rindle.Contracts

  describe "media contract vocabularies" do
    test "locks the media state lane" do
      assert Contracts.media_state_vocabulary() == [:queued, :uploaded, :scanning, :available, :rejected]
    end

    test "normalizes canonical capture evidence sources" do
      assert Contracts.capture_evidence_source_vocabulary() == [:device, :backend, :scanner, :support]
      assert Contracts.canonical_capture_evidence_source("device") == {:ok, :device}

      assert {:error, {:invalid_source, details}} =
               Contracts.canonical_capture_evidence_source(:device_callback)

      assert Keyword.fetch!(details, :source) == :device_callback
    end
  end

  describe "upload grant contract" do
    test "constructs and validates a server-issued upload grant" do
      assert {:ok, grant} = Contracts.new_upload_grant(upload_grant_attrs())

      assert %Contracts.UploadGrant{} = grant
      assert grant.grant_id == "grant_123"
      assert grant.idempotency_key == "idem_123"
      assert grant.accepted_types == ["image/jpeg", "image/png"]
    end

    test "rejects a non-positive max_bytes value" do
      {:error, errors} = Contracts.new_upload_grant(upload_grant_attrs(%{max_bytes: 0}))

      assert {:max_bytes, {:invalid_positive_integer, 0}} in errors
    end

    test "rejects missing enforced keys without raising" do
      attrs = Map.delete(upload_grant_attrs(), :grant_id)

      assert {:error, upload_grant: message} = Contracts.new_upload_grant(attrs)
      assert message =~ "[:grant_id]"
    end
  end

  describe "capture evidence contract" do
    test "constructs and validates evidence that echoes grant identity" do
      assert {:ok, evidence} = Contracts.new_capture_evidence(capture_evidence_attrs())

      assert %Contracts.CaptureEvidence{} = evidence
      assert evidence.grant_id == "grant_123"
      assert evidence.idempotency_key == "idem_123"
      assert evidence.source == :device
    end

    test "rejects missing or empty idempotency keys" do
      {:error, errors} = Contracts.new_capture_evidence(capture_evidence_attrs(%{idempotency_key: ""}))

      assert {:idempotency_key, :required} in errors
    end

    test "rejects invalid source vocabulary" do
      {:error, errors} = Contracts.new_capture_evidence(capture_evidence_attrs(%{source: :device_callback}))

      assert {:source, {:invalid_source, details}} = List.keyfind(errors, :source, 0)
      assert Keyword.fetch!(details, :source) == :device_callback
    end

    test "rejects direct authority or availability metadata in evidence" do
      {:error, errors} =
        Contracts.new_capture_evidence(
          capture_evidence_attrs(%{trace_metadata: %{authority_state: :available}})
        )

      assert {:trace_metadata, {:authority_state, :forbidden}} in errors

      {:error, string_key_errors} =
        Contracts.new_capture_evidence(
          capture_evidence_attrs(%{trace_metadata: %{"availability_state" => "available"}})
        )

      assert {:trace_metadata, {:availability_state, :forbidden}} in string_key_errors
    end
  end

  describe "media object contract" do
    test "constructs and validates a backend-owned media object" do
      assert {:ok, media_object} = Contracts.new_media_object(media_object_attrs())

      assert %Contracts.MediaObject{} = media_object
      assert media_object.state == :uploaded
      assert media_object.media_object_id == "media_123"
    end

    test "rejects unknown media states" do
      {:error, errors} = Contracts.new_media_object(media_object_attrs(%{state: :committed}))

      assert {:state, {:invalid_state, :committed}} in errors
    end

    test "rejects available media without backend verification fields" do
      {:error, errors} = Contracts.new_media_object(media_object_attrs(%{state: :available}))

      assert {:state, :backend_verification_required} in errors
    end

    test "accepts available media with backend verification fields" do
      assert {:ok, media_object} =
               Contracts.new_media_object(
                 media_object_attrs(%{
                   state: :available,
                   verification_ref: "verify_123",
                   authoritative_at: "2026-05-31T00:00:00Z"
                 })
               )

      assert media_object.state == :available
    end
  end

  describe "backend verification availability path" do
    test "promotes scanning media to available only with backend verification fields" do
      media_object = media_object(%{state: :scanning})

      assert {:ok, verified} =
               Contracts.verified_media_object(media_object,
                 verification_ref: "ver_1",
                 authoritative_at: "2026-05-31T00:00:00Z"
               )

      assert verified.state == :available
      assert verified.verification_ref == "ver_1"
    end

    test "requires backend verification fields" do
      assert Contracts.verified_media_object(media_object(%{state: :scanning}), []) ==
               {:error, :backend_verification_required}
    end

    test "rejects queued and terminal source states" do
      opts = [verification_ref: "ver_1", authoritative_at: "2026-05-31T00:00:00Z"]

      assert Contracts.verified_media_object(media_object(%{state: :queued}), opts) ==
               {:error, {:invalid_source_state, :queued}}

      assert Contracts.verified_media_object(
               media_object(%{
                 state: :available,
                 verification_ref: "ver_1",
                 authoritative_at: "2026-05-31T00:00:00Z"
               }),
               opts
             ) == {:error, {:invalid_source_state, :available}}

      assert Contracts.verified_media_object(
               media_object(%{state: :rejected, rejection_reason: :virus_detected}),
               opts
             ) == {:error, {:invalid_source_state, :rejected}}
    end
  end

  defp upload_grant_attrs(overrides \\ %{}) do
    %{
      grant_id: "grant_123",
      idempotency_key: "idem_123",
      expires_at: "2026-05-31T00:15:00Z",
      max_bytes: 5_000_000,
      accepted_types: ["image/jpeg", "image/png"],
      key_prefix: "uploads/user_123/",
      storage_target: "mock",
      integrity_algorithms: ["sha256"]
    }
    |> Map.merge(overrides)
  end

  defp capture_evidence_attrs(overrides \\ %{}) do
    %{
      grant_id: "grant_123",
      idempotency_key: "idem_123",
      storage_key: "uploads/user_123/photo.jpg",
      mime: "image/jpeg",
      bytes: 1024,
      captured_at: "2026-05-31T00:01:00Z",
      client_upload_ref: "local_upload_123",
      content_hash: "sha256:abc123",
      correlation_id: "corr_1",
      trace_metadata: %{queue_ref: "local_1"},
      source: :device
    }
    |> Map.merge(overrides)
  end

  defp media_object(overrides) do
    struct!(Contracts.MediaObject, media_object_attrs(overrides))
  end

  defp media_object_attrs(overrides \\ %{}) do
    %{
      media_object_id: "media_123",
      subject_key: "user:user_123",
      storage_key: "uploads/user_123/photo.jpg",
      state: :uploaded,
      as_of: "2026-05-31T00:02:00Z",
      trace_metadata: %{grant_id: "grant_123"}
    }
    |> Map.merge(overrides)
  end
end
