# Phase 15: Base Capability Bridges - Pattern Map

**Mapped:** 2026-05-20 (simulated)
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/bridge/registry.ex` | registry | request-response | `lib/crosswake/bridge/registry.ex` | exact |
| `lib/crosswake/bridge/commands/haptics.ex` | model/struct | request-response | `lib/crosswake/bridge/contract.ex` | role-match |
| `lib/crosswake/bridge/commands/share.ex` | model/struct | request-response | `lib/crosswake/bridge/contract.ex` | role-match |
| `lib/crosswake/bridge/commands/app_info.ex` | model/struct | request-response | `lib/crosswake/bridge/contract.ex` | role-match |
| `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | controller | request-response | `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | exact |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | controller | request-response | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | exact |

## Pattern Assignments

### Elixir Registry: `lib/crosswake/bridge/registry.ex` (registry, request-response)

**Analog:** `lib/crosswake/bridge/registry.ex`

**Allowlist pattern** (lines 10-14):
```elixir
  @capability_commands %{
    "app.info.get" => "app.info.get",
    "haptics.impact" => "haptics.impact",
    "files.pick" => "files.pick"
  }
```
*Note: `share.invoke` must be added to this map.*

---

### Elixir Payload Structs: `lib/crosswake/bridge/commands/*.ex` (model/struct, request-response)

**Analog:** `lib/crosswake/bridge/contract.ex`

**Struct definition pattern** (lines 16-29):
```elixir
  defmodule Request do
    @moduledoc false

    @enforce_keys [
      :protocol,
      :version,
      :command
    ]
    defstruct [
      :protocol,
      :version,
      :command
    ]

    @type t :: %__MODULE__{
            protocol: String.t(),
            version: String.t(),
            command: String.t()
          }
  end
```
*Note: This pattern should be used to create well-typed payload structs for `share.invoke`, `haptics.impact`, and `app.info.get` payloads.*

---

### iOS Shell: `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` (controller, request-response)

**Analog:** `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`

**Command Enum pattern** (lines 8-11):
```swift
enum BridgeCommand: String, CaseIterable {
    case appInfoGet = "app.info.get"
    case hapticsImpact = "haptics.impact"
    case filesPick = "files.pick"
```

**Handler pattern** (lines 154-162):
```swift
        case .hapticsImpact:
            guard let requiredCapabilityVersion = session.capabilities[command.capability],
                  request.capabilities[command.capability] == requiredCapabilityVersion else {
                replySink(deny(request, reason: "unavailable_capability", message: "The requested capability is not available at the manifest-backed version.", hint: "Ship the declared capability version before retrying."))
                return
            }

            let style = request.payload["style"] ?? "medium"
            hapticsHandler(style)
            replySink(ok(request, payload: ["style": style]))
```
*Note: Replicate this case for `.shareInvoke`, validating capabilities and extracting strings like `url`, `text`, and `title` from `request.payload`.*

---

### Android Shell: `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` (controller, request-response)

**Analog:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`

**Command Enum pattern** (lines 8-12):
```kotlin
enum class BridgeCommand(val wireValue: String) {
    APP_INFO_GET("app.info.get"),
    HAPTICS_IMPACT("haptics.impact"),
    FILES_PICK("files.pick"),
```

**Handler pattern** (lines 124-133):
```kotlin
            BridgeCommand.HAPTICS_IMPACT -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val style = request.payload["style"] ?: "medium"
                    hapticsHandler(style)
                    ok(request, mapOf("style" to style))
                }
            }
```
*Note: Replicate this case for `BridgeCommand.SHARE_INVOKE`, validating capabilities and extracting string payloads.*

## Shared Patterns

### Capability Verification
**Source:** `BridgeChannel.swift` and `BridgeChannel.kt`
**Apply to:** All capability handler implementations
**Pattern:**
Both shells first verify that the command capability is present and matches the `session.capabilities` version requirement before extracting the payload and invoking the respective native handler. Denials must return `unavailable_capability`.

## Metadata

**Analog search scope:** `lib/crosswake/bridge/`, `examples/ios_shell_host/`, `examples/android_shell_host/`
**Files scanned:** 6
**Pattern extraction date:** 2026-05-20
