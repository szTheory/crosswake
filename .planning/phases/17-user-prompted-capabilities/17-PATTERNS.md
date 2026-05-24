# Phase 17: User-Prompted Capabilities - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/bridge/contract.ex` | model | request-response | `lib/crosswake/bridge/contract.ex` | exact |
| `lib/crosswake/bridge/registry.ex` | service | request-response | `lib/crosswake/bridge/registry.ex` | exact |
| `lib/crosswake/bridge/commands/notification_token.ex` | model | request-response | `lib/crosswake/bridge/commands/permissions_status.ex` | role-match |
| `lib/crosswake/bridge/commands/file_picker.ex` | model | request-response | `lib/crosswake/bridge/commands/share.ex` | role-match |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/manifest/builder.ex` | exact |
| `lib/crosswake/transfer/contracts.ex` | model | request-response | `lib/crosswake/transfer/contracts.ex` | exact |
| `test/support/router_fixtures.ex` | test | request-response | `test/support/router_fixtures.ex` | exact |
| `test/crosswake/bridge/contract_test.exs` | test | request-response | `test/crosswake/bridge/contract_test.exs` | exact |
| `test/crosswake/bridge/registry_test.exs` | test | request-response | `test/crosswake/bridge/registry_test.exs` | exact |
| `test/crosswake/manifest/manifest_test.exs` | test | transform | `test/crosswake/manifest/manifest_test.exs` | exact |
| `test/crosswake/transfer/contracts_test.exs` | test | request-response | `test/crosswake/transfer/contracts_test.exs` | exact |
| `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | controller | request-response | `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | exact |
| `examples/ios_shell_host/CrosswakeShell/NotificationTokenProvider.swift` | service | request-response | `examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift` | role-match |
| `examples/ios_shell_host/CrosswakeShell/FilePickerCoordinator.swift` | controller | file-I/O | `examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift` | dataflow-match |
| `examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift` | controller | file-I/O | `examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift` | exact |
| `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift` | test | request-response | `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift` | exact |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | controller | request-response | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | exact |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NotificationTokenProvider.kt` | service | request-response | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt` | role-match |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/FilePickerCoordinator.kt` | controller | file-I/O | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt` | dataflow-match |
| `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt` | test | request-response | `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt` | exact |

## Pattern Assignments

### Slice A: `notification_token` Elixir contract, registry, and manifest truth

**Targets:** `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/bridge/commands/notification_token.ex`, `lib/crosswake/manifest/builder.ex`, `test/crosswake/bridge/contract_test.exs`, `test/crosswake/bridge/registry_test.exs`

**Primary analogs:** `lib/crosswake/bridge/commands/permissions_status.ex`, `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/manifest/builder.ex`

**Command vocabulary and request/reply envelope**  
Source: [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:9)
```elixir
@protocol "crosswake.bridge"
@version "1.0.0"
@commands ~w(
  app.info.get
  haptics.impact
  permissions.status
  share.invoke
  files.pick
  transfer.download
  transfer.export
  transfer.import
  transfer.upload.prepare
)
```
Add the new low-level notification command here and keep the existing top-level request/reply envelope unchanged.

**Typed payload module pattern**  
Source: [lib/crosswake/bridge/commands/permissions_status.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/commands/permissions_status.ex:6)
```elixir
@supported_aliases ["notifications"]
@supported_statuses [:granted, :denied, :restricted]

defmodule Request do
  @enforce_keys [:alias]
  defstruct [:alias]
end

defmodule Response do
  @enforce_keys [:alias, :status]
  defstruct [:alias, :status, detail: %{}]
end
```
`notification_token` should copy this shape: a narrow `Request`, a `Response` with normalized `notification_status`, and validation helpers that fail closed on unsupported inputs.

**Manifest-backed capability lookup pattern**  
Source: [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:11)
```elixir
@capability_commands %{
  "app.info.get" => "app.info.get",
  "haptics.impact" => "haptics.impact",
  "permissions.status" => "permissions.status",
  "files.pick" => "files.pick",
  "share.invoke" => "share.invoke"
}
```
Use this for `notification_token`: it is a capability-gated command, unlike picker-backed transfer flows.

**Family/version resolution pattern**  
Source: [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:83)
```elixir
with true <- capability_declared_on_route?(route, capability_id) || {:error, :undeclared_capability},
     %Capability{} = capability <-
       lookup_capability(manifest, capability_id) || {:error, :undeclared_capability} do
  {:ok,
   %Entry{
     command: command,
     capability: capability.family,
     version: capability.version,
     route_id: route.id,
     allowlisted_origins: route.allowlisted_origins
   }}
end
```
Keep `notification_token` on this path so route allowlisting and family-version resolution stay manifest-first.

**Capability catalog pattern**  
Source: [lib/crosswake/manifest/builder.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex:197)
```elixir
[
  id: "permissions.status",
  family: "permissions.status",
  owner: :bounded_bridge,
  package_class: :core,
  proof_class: :merge_blocking,
  rebuild: :none,
  prerequisites: [
    "declared route capability",
    "bounded bridge support",
    "notifications alias only"
  ],
  denial: "undeclared_capability",
  fallback: "route continues without native notification permission snapshot authority",
  guide: "guides/capabilities.md#bounded-bridge"
]
```
`notification_token` should reuse this metadata style, but keep its own prerequisites and evidence-only fallback language.

**Tests to copy**  
Source: [test/crosswake/bridge/contract_test.exs](/Users/jon/projects/crosswake/test/crosswake/bridge/contract_test.exs:8), [test/crosswake/bridge/registry_test.exs](/Users/jon/projects/crosswake/test/crosswake/bridge/registry_test.exs:45)
```elixir
assert Contract.commands() == [...]
assert Contract.command_supported?("permissions.status")

assert {:ok, entry} = Registry.lookup(manifest, "dashboard", "permissions.status")
assert entry.command == "permissions.status"
assert entry.capability == "permissions.status"
assert entry.version == "1.0.0"
```
Mirror these for the new notification command and its manifest resolution.

### Slice B: `file_picker` as a transfer-backed seam, not a free-standing capability

**Targets:** `lib/crosswake/bridge/registry.ex`, `lib/crosswake/bridge/commands/file_picker.ex`, `lib/crosswake/transfer/contracts.ex`, `lib/crosswake/manifest/builder.ex`, `test/support/router_fixtures.ex`, `test/crosswake/bridge/registry_test.exs`, `test/crosswake/manifest/manifest_test.exs`, `test/crosswake/transfer/contracts_test.exs`

**Primary analogs:** `lib/crosswake/transfer/contracts.ex`, `lib/crosswake/bridge/registry.ex`, `test/support/router_fixtures.ex`, `test/crosswake/manifest/manifest_test.exs`

**Transfer declaration shape**  
Source: [lib/crosswake/transfer/contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/transfer/contracts.ex:17)
```elixir
defmodule Declaration do
  @enforce_keys [
    :protocol,
    :version,
    :id,
    :intent,
    :direction,
    :verification
  ]
  defstruct [
    :protocol,
    :version,
    :id,
    :intent,
    :direction,
    :source,
    :destination,
    :verification,
    media_types: []
  ]
end
```
Do not invent a parallel picker declaration format. `file_picker` should consume `transfer_id` and rely on existing `intent/source/verification/media_types` truth.

**Inbound source validation pattern**  
Source: [lib/crosswake/transfer/contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/transfer/contracts.ex:184)
```elixir
defp validate_source(intent, nil) when intent in @inbound_intents,
  do: {:error, "source is required for #{intent} transfers"}

defp validate_source(_intent, value) when value in @sources, do: {:ok, value}
```
`native_picker` remains the gate. Planner should keep picker semantics tied to inbound transfers only.

**Route fixture pattern for picker-backed import**  
Source: [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:57)
```elixir
live "/library", Crosswake.TestSupport.LibraryLive,
  crosswake: [
    id: "library",
    cache_contract: :lesson_library_v1,
    packs: [[id: :lesson_library, version: "1.2.0", kind: :content]],
    transfers: [
      [
        id: :lesson_import,
        intent: :import,
        source: :native_picker,
        verification: :required,
        media_types: ["application/pdf"]
      ]
    ]
  ]
```
This is the exact Phase 17 picker route fixture to extend. Prefer more `native_picker` transfer examples over adding ambient `file_picker` route capabilities.

**Manifest route transfer serialization**  
Source: [lib/crosswake/manifest/builder.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex:123)
```elixir
defp transfer_seams(transfers) do
  Enum.map(transfers, fn transfer ->
    Types.new_transfer_seam(
      id: transfer.id,
      intent: transfer.intent,
      direction: transfer.direction,
      source: transfer.source,
      destination: transfer.destination,
      verification: transfer.verification,
      media_types: transfer.media_types
    )
  end)
end
```
Keep picker-relevant truth on the transfer seam; do not duplicate MIME or verification data in a separate manifest subtree.

**Registry transfer-entry pattern**  
Source: [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:115)
```elixir
defp transfer_entry(route, command, transfer_intent) do
  case Enum.find(route.transfers, &match_transfer_command?(&1, transfer_intent)) do
    %TransferSeam{} = transfer ->
      {:ok,
       %Entry{
         command: command,
         capability: command,
         version: transfer.version,
         route_id: route.id,
         allowlisted_origins: route.allowlisted_origins
       }}
```
This is the closest existing seam for `file_picker`. Phase 17 likely needs a variant that resolves `files.pick` by `transfer_id` and `source: :native_picker`, not by a route capability flag alone.

**Tests to copy**  
Source: [test/crosswake/manifest/manifest_test.exs](/Users/jon/projects/crosswake/test/crosswake/manifest/manifest_test.exs:106), [test/crosswake/transfer/contracts_test.exs](/Users/jon/projects/crosswake/test/crosswake/transfer/contracts_test.exs:7)
```elixir
assert Enum.map(library_transfers, & &1.id) == [
  "lesson_import",
  "lesson_export",
  "lesson_download"
]
assert Enum.map(library_transfers, & &1.intent) == [:import, :export, :download]

declaration =
  Contracts.new_declaration(
    id: "asset_upload",
    intent: :upload,
    source: :native_picker,
    verification: :required,
    media_types: ["image/*"]
  )
```
Phase 17 tests should keep file-picker behavior anchored to transfer seams and `native_picker` declarations.

### Slice C: iOS shell notification and picker handlers

**Targets:** `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`, `examples/ios_shell_host/CrosswakeShell/NotificationTokenProvider.swift`, `examples/ios_shell_host/CrosswakeShell/FilePickerCoordinator.swift`, `examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift`, `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift`

**Primary analogs:** `PermissionStatusProvider.swift`, `TransferCoordinator.swift`, `BridgeChannel.swift`, `BridgeChannelTests.swift`

**Dispatch injection pattern**  
Source: [examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift:117)
```swift
private let appInfoProvider: () -> [String: String]
private let hapticsHandler: (String) -> Void
private let permissionStatusProvider: (String) -> [String: String]?
private let shareHandler: ([String: String]) -> Void
private let filesPickHandler: ([String: String]) -> [String: String]
private let transferCoordinator: TransferCoordinator?
```
New iOS notification and picker helpers should be injected here, not hard-coded into `BridgeChannel`.

**Guard-and-dispatch pattern**  
Source: [examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift:161)
```swift
guard request.protocolName == Self.protocolName,
      request.version == session.bridgeProtocolVersion,
      request.nativeRuntimeVersion == session.nativeRuntimeVersion else {
    return deny(request, reason: "compatibility_mismatch", message: "Bridge protocol or runtime mismatch.", hint: "Update the shell before retrying this bridge request.")
}
...
guard let requiredCapabilityVersion = session.capabilities[command.capability],
      request.capabilities[command.capability] == requiredCapabilityVersion else {
    return deny(request, reason: "unavailable_capability", message: "The requested capability is not available at the manifest-backed version.", hint: "Ship the declared capability version before retrying.")
}
```
Keep this unchanged for `notification_token`. For picker, add any transfer-specific checks after the same bridge guards.

**Normalized notifications payload pattern**  
Source: [examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift:11)
```swift
center.getNotificationSettings { settings in
    let authorizationStatus = settings.authorizationStatus
    let normalizedStatus: String

    switch authorizationStatus {
    case .authorized, .provisional, .ephemeral:
        normalizedStatus = "granted"
    case .denied, .notDetermined:
        normalizedStatus = "denied"
    @unknown default:
        normalizedStatus = "restricted"
    }
```
`NotificationTokenProvider.swift` should copy this normalization vocabulary and add token/detail fields without prompting.

**Transfer-backed transition pattern**  
Source: [examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift:46)
```swift
guard let transferCommand = TransferCommand(rawValue: command),
      let transferID = payload["transfer_id"],
      let seam = declaredTransfer(id: transferID, matching: transferCommand) else {
    return nil
}
```
`FilePickerCoordinator.swift` should mirror this lookup discipline: require `transfer_id`, resolve a declared seam, and fail nil when the route has no matching `native_picker` transfer.

**Bridge test pattern**  
Source: [examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift:20)
```swift
let reply = channel.evaluate(
    BridgeRequestEnvelope(
        protocolName: BridgeChannel.protocolName,
        version: "1.0.0",
        command: "permissions.status",
        capability: "permissions.status",
        routeID: "dashboard",
        activeRouteID: "dashboard",
        origin: "https://example.crosswake.invalid",
        nativeRuntimeVersion: "1.0.0",
        correlationID: "perm-1",
        capabilities: ["permissions.status": "1.0.0"],
        installedPacks: [:],
        payload: ["alias": "notifications"]
    )
)
```
Phase 17 iOS tests should stay in this style: construct a request envelope, inject a fake provider/coordinator, and assert exact `status`, payload fields, or denial reasons.

### Slice D: Android shell notification and picker handlers

**Targets:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NotificationTokenProvider.kt`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/FilePickerCoordinator.kt`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt`, `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt`

**Primary analogs:** `PermissionStatusProvider.kt`, `transfer/TransferCoordinator.kt`, `BridgeChannel.kt`, `BridgeChannelTest.kt`

**Constructor-injected handler pattern**  
Source: [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt:34)
```kotlin
class BridgeChannel(
    private var session: LiveViewSession,
    private val transferCoordinator: TransferCoordinator?,
    private val appInfoProvider: () -> Map<String, String>,
    private val hapticsHandler: (String) -> Unit,
    private val permissionStatusProvider: (String) -> Map<String, String>?,
    private val shareHandler: (Map<String, String>) -> Unit,
    private val filesPickHandler: (Map<String, String>) -> Map<String, String>
)
```
Keep the Android shell in this style. New helpers should be separate classes passed into the bridge.

**Capability/version denial pattern**  
Source: [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt:123)
```kotlin
val requiredCapabilityVersion = session.capabilities[command.capability]
if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
} else {
    ok(request, payload)
}
```
Use this exact pattern for `notification_token`.

**Android notifications-status detail pattern**  
Source: [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt:18)
```kotlin
val notificationsEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
val payload = mutableMapOf(
    "alias" to "notifications",
    "status" to if (notificationsEnabled) "granted" else "denied",
    "detail.notifications_enabled" to notificationsEnabled.toString()
)
```
`NotificationTokenProvider.kt` should reuse this normalized status vocabulary and append token/prerequisite detail rather than prompt ownership.

**Route-local transfer execution pattern**  
Source: [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt:45)
```kotlin
val transferCommand = TransferCommand.fromWireValue(command) ?: return null
val transferId = payload["transfer_id"] ?: return null
val seam = declaredTransfer(transferId, transferCommand) ?: return null
```
Android picker work should follow this route-local lookup model and return nil for undeclared seams.

**Bridge test pattern**  
Source: [examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt:24)
```kotlin
val reply = JSONObject(
    channel.evaluateForTesting(
        request(
            payload = mapOf("alias" to "notifications"),
            capabilities = mapOf("permissions.status" to "1.0.0")
        )
    )
)
```
Keep Phase 17 Android tests in this single-request, JSON-assert style.

## Shared Patterns

### Bounded bridge guard order
**Sources:** [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:141), [examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift:161), [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt:86)  
Apply to: All new bridge commands and native handlers
```text
protocol/runtime check
-> active route check
-> origin allowlist check
-> command/capability match
-> manifest capability or transfer seam check
-> typed ok/deny reply
```

### Notification status vocabulary reuse
**Sources:** [lib/crosswake/bridge/commands/permissions_status.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/commands/permissions_status.ex:6), [examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift:18), [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt:18)  
Apply to: `notification_token` Elixir struct plus both native token providers  
Use only `granted`, `denied`, `restricted` for the primary field. Put platform nuance under `detail.*`.

### Picker is justified by transfer seams
**Sources:** [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:57), [lib/crosswake/transfer/contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/transfer/contracts.ex:124), [examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift:110), [examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt:98)  
Apply to: `file_picker` Elixir module, registry logic, and both native picker coordinators  
Require `transfer_id`. Resolve the route-local seam. Return typed staged evidence, not ambient filesystem authority.

## Recommended Ownership Slices

1. **Elixir notification slice**
   `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/bridge/commands/notification_token.ex`, `lib/crosswake/manifest/builder.ex`, `test/crosswake/bridge/contract_test.exs`, `test/crosswake/bridge/registry_test.exs`

2. **Elixir picker-transfer slice**
   `lib/crosswake/bridge/commands/file_picker.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/transfer/contracts.ex`, `test/support/router_fixtures.ex`, `test/crosswake/manifest/manifest_test.exs`, `test/crosswake/transfer/contracts_test.exs`

3. **iOS shell slice**
   `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`, `examples/ios_shell_host/CrosswakeShell/NotificationTokenProvider.swift`, `examples/ios_shell_host/CrosswakeShell/FilePickerCoordinator.swift`, `examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift`, `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift`

4. **Android shell slice**
   `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NotificationTokenProvider.kt`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/FilePickerCoordinator.kt`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt`, `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt`

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/crosswake/bridge/commands/notification_token.ex` | model | request-response | No existing Elixir bridge command returns both evidence data and normalized notification status. |
| `examples/ios_shell_host/CrosswakeShell/NotificationTokenProvider.swift` | service | request-response | No checked-in iOS token fetcher exists yet; closest analog is read-only notification status lookup. |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NotificationTokenProvider.kt` | service | request-response | No checked-in Android token fetcher exists yet; closest analog is read-only notification status lookup. |
| `examples/ios_shell_host/CrosswakeShell/FilePickerCoordinator.swift` | controller | file-I/O | No current iOS picker coordinator exists; closest analog is transfer seam staging and bridge dispatch. |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/FilePickerCoordinator.kt` | controller | file-I/O | No current Android picker coordinator exists; closest analog is transfer seam staging and bridge dispatch. |

## Metadata

**Analog search scope:** `lib/crosswake/bridge`, `lib/crosswake/manifest`, `lib/crosswake/transfer`, `test/crosswake/bridge`, `test/crosswake/manifest`, `test/crosswake/transfer`, `test/support`, `examples/ios_shell_host`, `examples/android_shell_host`  
**Files scanned:** 20  
**Pattern extraction date:** 2026-05-21
