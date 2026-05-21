defmodule Crosswake.Transfer.ContractsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Commands.FilePicker
  alias Crosswake.Transfer.Contracts
  alias Crosswake.Transfer.Runtime

  test "declares a typed versioned transfer contract with route-local states" do
    declaration =
      Contracts.new_declaration(
        id: "asset_upload",
        intent: :upload,
        source: :native_picker,
        verification: :required,
        media_types: ["image/*"]
      )

    assert declaration.protocol == "crosswake.transfer"
    assert declaration.version == "1.0.0"
    assert declaration.direction == :inbound
    assert declaration.source == :native_picker
    assert declaration.destination == nil
    assert declaration.verification == :required
    assert Contracts.transfer_states() == [
             :queued,
             :preparing,
             :transferring,
             :awaiting_network,
             :verifying,
             :complete,
             :failed,
             :canceled
           ]
  end

  test "file picker only accepts inbound native_picker transfer seams" do
    import_transfer =
      Contracts.new_declaration(
        id: "lesson_import",
        intent: :import,
        source: :native_picker,
        verification: :required,
        media_types: ["application/pdf"]
      )

    upload_transfer =
      Contracts.new_declaration(
        id: "asset_upload",
        intent: :upload,
        source: :native_picker,
        verification: :required,
        media_types: ["image/*"]
      )

    export_transfer =
      Contracts.new_declaration(
        id: "lesson_export",
        intent: :export,
        destination: :user_visible_files,
        verification: :required,
        media_types: ["application/pdf"]
      )

    capture_transfer =
      Contracts.new_declaration(
        id: "capture_upload",
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      )

    assert :ok = Contracts.validate_picker_declaration(import_transfer)
    assert :ok = Contracts.validate_picker_declaration(upload_transfer)
    assert {:error, :invalid_picker_intent} = Contracts.validate_picker_declaration(export_transfer)
    assert {:error, :invalid_picker_source} = Contracts.validate_picker_declaration(capture_transfer)
  end

  test "file picker item metadata stays normalized and nullable" do
    item =
      FilePicker.new_item(
        handle: "picked-1",
        name: nil,
        mime_type: "application/pdf",
        size_bytes: nil,
        native_type: "com.adobe.pdf"
      )

    assert item.handle == "picked-1"
    assert item.name == nil
    assert item.mime_type == "application/pdf"
    assert item.size_bytes == nil
    assert item.native_type == "com.adobe.pdf"
  end

  test "tracks transfer runtime state against the active route only" do
    status =
      Runtime.new_status(
        route_id: "library",
        active_route_id: "library",
        transfer_id: "asset_upload",
        state: :verifying
      )

    assert Runtime.route_local?(status)

    refute Runtime.route_local?(
             Runtime.new_status(
               route_id: "library",
               active_route_id: "camera",
               transfer_id: "asset_upload",
               state: :verifying
             )
           )
  end
end
