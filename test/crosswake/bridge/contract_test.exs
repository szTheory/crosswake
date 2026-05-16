defmodule Crosswake.Bridge.ContractTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Denial
  alias Crosswake.Shell.Denial, as: ShellDenial

  test "bridge contract exposes only the explicit bounded transfer command vocabulary" do
    assert Contract.commands() == [
             "app.info.get",
             "haptics.impact",
             "files.pick",
             "transfer.download",
             "transfer.export",
             "transfer.import",
             "transfer.upload.prepare"
           ]

    assert Contract.command_supported?("transfer.download")
    assert Contract.command_supported?("transfer.export")
    assert Contract.command_supported?("transfer.import")
    assert Contract.command_supported?("transfer.upload.prepare")

    refute Contract.command_supported?("browser.open")
    refute Contract.command_supported?("share.sheet.present")
    refute Contract.command_supported?("transfer.url.open")
  end

  test "bridge requests carry the typed route, origin, active-route, version, and correlation fields" do
    request =
      Contract.new_request(
        command: "transfer.upload.prepare",
        capability: "transfer.upload.prepare",
        route_id: "camera",
        active_route_id: "camera",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "req-123",
        capabilities: %{"transfer.upload.prepare" => "1.0.0"},
        installed_packs: %{"shell.chrome" => "1.0.0"},
        payload: %{
          "transfer_id" => "capture_upload",
          "intent" => "upload",
          "source" => "native_capture",
          "verification" => "required"
        }
      )

    assert Contract.to_map(request) == %{
             "protocol" => "crosswake.bridge",
             "version" => "1.0.0",
             "command" => "transfer.upload.prepare",
             "capability" => "transfer.upload.prepare",
             "route_id" => "camera",
             "active_route_id" => "camera",
             "origin" => "https://example.crosswake.invalid",
             "native_runtime_version" => "1.0.0",
             "correlation_id" => "req-123",
             "capabilities" => %{"transfer.upload.prepare" => "1.0.0"},
             "installed_packs" => %{"shell.chrome" => "1.0.0"},
             "payload" => %{
               "transfer_id" => "capture_upload",
               "intent" => "upload",
               "source" => "native_capture",
               "verification" => "required"
             }
           }
  end

  test "bridge replies stay request reply only and carry typed denial payloads" do
    request =
      Contract.new_request(
        command: "files.pick",
        capability: "files.pick",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "req-456"
      )

    shell_denial =
      ShellDenial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch for dashboard",
        hint: "bind the route to an allowlisted origin before activating it"
      )

    denial = Denial.from_request(request, shell_denial)
    reply = Contract.deny_reply(request, denial)

    assert Contract.to_map(reply) == %{
             "protocol" => "crosswake.bridge",
             "version" => "1.0.0",
             "command" => "files.pick",
             "route_id" => "dashboard",
             "correlation_id" => "req-456",
             "status" => "deny",
             "payload" => %{},
             "denial" => %{
               "command" => "files.pick",
               "route_id" => "dashboard",
               "correlation_id" => "req-456",
               "denial" => %{
                 "reason" => "origin_denied",
                 "code" => "origin_denied",
                 "message" => "origin mismatch for dashboard",
                 "route_id" => "dashboard",
                 "hint" => "bind the route to an allowlisted origin before activating it"
               }
             }
           }
  end

  test "bridge contract stays request reply only and does not claim platform handlers" do
    refute Contract.command_supported?("ios.transfer.upload.prepare")
    refute Contract.command_supported?("android.transfer.upload.prepare")
    refute Contract.command_supported?("native.transfer.execute")
  end
end
