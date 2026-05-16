defmodule Crosswake.Transfer.ContractsTest do
  use ExUnit.Case, async: true

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
