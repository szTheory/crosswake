defmodule Crosswake.Bridge.ContractTest do
  use ExUnit.Case, async: true

  alias Crosswake.Bridge.Commands.NotificationToken
  alias Crosswake.Bridge.Commands.PermissionsStatus
  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Denial
  alias Crosswake.Shell.Denial, as: ShellDenial

  test "bridge contract exposes only the explicit bounded transfer command vocabulary" do
    assert Contract.commands() == [
             "app.info.get",
             "haptics.impact",
             "permissions.status",
             "notifications.token.get",
             "share.invoke",
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
    assert Contract.command_supported?("permissions.status")
    assert Contract.command_supported?("notifications.token.get")

    refute Contract.command_supported?("browser.open")
    refute Contract.command_supported?("share.sheet.present")
    refute Contract.command_supported?("transfer.url.open")
  end

  test "notification_token stays a one-shot typed command with provider-explicit evidence replies" do
    assert {:ok, %NotificationToken.Request{}} = NotificationToken.new_request([])

    assert {:error, :unsupported_option} =
             NotificationToken.new_request(alias: "notifications")

    response =
      NotificationToken.new_response(
        provider: :apns,
        token: "apns-token",
        notification_status: :granted,
        detail: %{"environment" => "sandbox"}
      )

    assert response.provider == "apns"
    assert response.token == "apns-token"
    assert response.notification_status == :granted
    assert response.detail == %{"environment" => "sandbox"}
    assert NotificationToken.supported_statuses() == PermissionsStatus.supported_statuses()
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
             "version" => "1.1.0",
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
             "version" => "1.1.0",
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

  # thread_id tests (Task 1 - 91-02)

  test "Request, Reply, and Denial structs accept an optional thread_id defaulting to nil" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-1"
      )

    assert is_nil(request.thread_id)

    reply = Contract.new_reply(
      command: "haptics.impact",
      route_id: "dashboard",
      correlation_id: "corr-1",
      status: :ok
    )

    assert is_nil(reply.thread_id)

    shell_denial =
      ShellDenial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch"
      )

    denial = Denial.new(
      command: "haptics.impact",
      route_id: "dashboard",
      correlation_id: "corr-1",
      denial: shell_denial
    )

    assert is_nil(denial.thread_id)
  end

  test "thread_id round-trips through new_request when provided" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-t",
        thread_id: "thread-abc"
      )

    assert request.thread_id == "thread-abc"
  end

  test "ok_reply propagates thread_id from request" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-2",
        thread_id: "thread-xyz"
      )

    reply = Contract.ok_reply(request, %{})
    assert reply.thread_id == "thread-xyz"
  end

  test "deny_reply propagates thread_id from request" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-3",
        thread_id: "thread-deny"
      )

    shell_denial =
      ShellDenial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch"
      )

    denial = Denial.from_request(request, shell_denial)
    reply = Contract.deny_reply(request, denial)

    assert reply.thread_id == "thread-deny"
  end

  test "Denial.from_request propagates thread_id from request" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-4",
        thread_id: "thread-from-req"
      )

    shell_denial =
      ShellDenial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch"
      )

    denial = Denial.from_request(request, shell_denial)
    assert denial.thread_id == "thread-from-req"
  end

  test "Request.to_map omits thread_id key when nil" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-nil"
      )

    map = Contract.to_map(request)
    refute Map.has_key?(map, "thread_id")
  end

  test "Request.to_map includes thread_id when present" do
    request =
      Contract.new_request(
        command: "haptics.impact",
        capability: "haptics.impact",
        route_id: "dashboard",
        active_route_id: "dashboard",
        origin: "https://example.crosswake.invalid",
        native_runtime_version: "1.0.0",
        correlation_id: "corr-t2",
        thread_id: "t-1"
      )

    map = Contract.to_map(request)
    assert map["thread_id"] == "t-1"
  end

  test "Denial.to_map omits thread_id when nil and includes it when present" do
    shell_denial =
      ShellDenial.new(
        reason: :origin_denied,
        route_id: "dashboard",
        message: "origin mismatch"
      )

    denial_nil = Denial.new(
      command: "haptics.impact",
      route_id: "dashboard",
      correlation_id: "corr-d1",
      denial: shell_denial
    )

    map_nil = Denial.to_map(denial_nil)
    refute Map.has_key?(map_nil, "thread_id")

    denial_with =
      Denial.new(
        command: "haptics.impact",
        route_id: "dashboard",
        correlation_id: "corr-d2",
        denial: shell_denial,
        thread_id: "t-denial"
      )

    map_with = Denial.to_map(denial_with)
    assert map_with["thread_id"] == "t-denial"
  end
end
