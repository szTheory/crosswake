defmodule Crosswake.NativeEscape.ContractTest do
  use ExUnit.Case, async: true

  alias Crosswake.NativeEscape.Contract
  alias Crosswake.NativeEscape.Runtime
  alias Crosswake.Transfer.Contracts, as: TransferContracts

  test "supports one route-owned media capture purpose with explicit local staging and transfer handoff" do
    request =
      Contract.new_request(
        route_id: "capture",
        route_runtime: :native_screen,
        transfer_id: "capture_upload",
        permission_posture: :required,
        media_types: ["image/*"]
      )

    assert request.protocol == "crosswake.native_escape"
    assert request.version == "1.0.0"
    assert request.purpose == :media_capture
    assert Contract.purposes() == [:media_capture]

    local_capture =
      Contract.new_local_capture(
        capture_id: "capture-1",
        local_path: "/tmp/crosswake/capture-1.jpg",
        media_type: "image/jpeg",
        bytes: 2048
      )

    declared_transfer =
      TransferContracts.new_declaration(
        id: "capture_upload",
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      )

    assert {:ok, result} = Runtime.capture_local(request, local_capture, [declared_transfer])
    assert result.state == :captured_local
    assert result.local_capture == local_capture
    assert result.transfer_handoff.transfer_id == "capture_upload"
    assert result.transfer_handoff.transfer_intent == :upload
    assert result.transfer_handoff.transfer_protocol == TransferContracts.protocol()
  end

  test "keeps captured-local and transfer-complete states distinct" do
    request =
      Contract.new_request(
        route_id: "capture",
        route_runtime: :native_screen,
        transfer_id: "capture_upload",
        permission_posture: :granted,
        media_types: ["image/*"]
      )

    local_capture =
      Contract.new_local_capture(
        capture_id: "capture-2",
        local_path: "/tmp/crosswake/capture-2.jpg",
        media_type: "image/jpeg",
        bytes: 1024
      )

    declared_transfer =
      TransferContracts.new_declaration(
        id: "capture_upload",
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      )

    assert {:ok, captured} = Runtime.capture_local(request, local_capture, [declared_transfer])
    assert captured.state == :captured_local

    transfer_result =
      TransferContracts.new_result(
        route_id: "capture",
        transfer_id: "capture_upload",
        state: :complete,
        metadata: %{"remote_id" => "upload-123"}
      )

    assert {:ok, handed_off} = Runtime.complete_transfer(captured, transfer_result)
    assert handed_off.state == :transfer_complete
    assert handed_off.transfer_result == transfer_result
    refute handed_off.state == captured.state
  end

  test "fails closed for unsupported runtime ownership or undeclared transfer seams" do
    request =
      Contract.new_request(
        route_id: "capture",
        route_runtime: :live_view,
        transfer_id: "capture_upload",
        permission_posture: :required,
        media_types: ["image/*"]
      )

    local_capture =
      Contract.new_local_capture(
        capture_id: "capture-3",
        local_path: "/tmp/crosswake/capture-3.jpg",
        media_type: "image/jpeg",
        bytes: 512
      )

    assert {:error, denial} = Runtime.capture_local(request, local_capture, [])
    assert denial.reason == :native_screen_required

    native_request = %{request | route_runtime: :native_screen}
    assert {:error, denial} = Runtime.capture_local(native_request, local_capture, [])
    assert denial.reason == :undeclared_transfer_seam
  end
end
