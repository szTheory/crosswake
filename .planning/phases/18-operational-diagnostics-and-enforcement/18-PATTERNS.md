# Phase 18: Operational Diagnostics and Enforcement - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 24
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/policy/validator.ex` | middleware | request-response | `lib/crosswake/policy/validator.ex` | exact |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/manifest/builder.ex` | exact |
| `lib/crosswake/bridge/registry.ex` | service | request-response | `lib/crosswake/bridge/registry.ex` | exact |
| `lib/crosswake/doctor/doctor.ex` | service | batch | `lib/crosswake/doctor/doctor.ex` | exact |
| `lib/crosswake/doctor/formatter.ex` | utility | transform | `lib/crosswake/doctor/formatter.ex` | exact |
| `lib/crosswake/doctor/json_formatter.ex` | utility | transform | `lib/crosswake/doctor/json_formatter.ex` | exact |
| `lib/mix/tasks/crosswake.doctor.ex` | config | request-response | `lib/mix/tasks/crosswake.doctor.ex` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | service | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `lib/crosswake/support_matrix/renderer.ex` | utility | file-I/O | `lib/crosswake/support_matrix/renderer.ex` | exact |
| `guides/bridge.md` | config | transform | `guides/bridge.md` | exact |
| `guides/capabilities.md` | config | transform | `guides/capabilities.md` | exact |
| `guides/native_shell.md` | config | transform | `guides/native_shell.md` | exact |
| `guides/support_matrix.md` | config | transform | `lib/crosswake/support_matrix/renderer.ex` | exact |
| `test/crosswake/bridge/registry_test.exs` | test | request-response | `test/crosswake/bridge/registry_test.exs` | exact |
| `test/crosswake/doctor/doctor_test.exs` | test | batch | `test/crosswake/doctor/doctor_test.exs` | exact |
| `test/crosswake/support_matrix/support_matrix_test.exs` | test | transform | `test/crosswake/support_matrix/support_matrix_test.exs` | exact |
| `test/crosswake/support_matrix/renderer_test.exs` | test | file-I/O | `test/crosswake/support_matrix/renderer_test.exs` | exact |
| `test/crosswake/shell/activation_test.exs` | test | request-response | `test/crosswake/shell/activation_test.exs` | exact |
| `test/support/router_fixtures.ex` | test | request-response | `test/support/router_fixtures.ex` | exact |
| `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | service | request-response | `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | exact |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | service | request-response | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | exact |
| `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift` | test | request-response | `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift` | exact |
| `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt` | test | request-response | `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt` | exact |
| `test/crosswake/proof/phase18_*_test.exs` | test | request-response | `test/crosswake/proof/phase8_selective_native_lane_test.exs` | role-match |

## Pattern Assignments

### `lib/crosswake/policy/validator.ex` (middleware, request-response)

**Analog:** `lib/crosswake/policy/validator.ex`

**Imports and module shape** (lines 1-8):
```elixir
defmodule Crosswake.Policy.Validator do
  @moduledoc """
  Semantic invariant checks for normalized Crosswake route policy.
  """

  alias Crosswake.Policy.Error
  alias Crosswake.Policy.Route
```

**Validation pipeline** (lines 45-56, 123-137):
```elixir
defp route_errors(route) do
  []
  |> validate_runtime_offline(route)
  |> validate_entry(route)
  |> validate_sync(route)
  |> validate_security(route)
  |> validate_capabilities(route)
end

defp validate_capabilities(errors, %Route{capabilities: capabilities}) do
  Enum.reduce(capabilities, errors, fn capability, acc ->
    if MapSet.member?(@known_capabilities, capability) do
      acc
    else
      [%{key: :capabilities, message: "unknown capability #{inspect(capability)}"} | acc]
    end
  end)
end
```

Use this pattern for any new family-normalization or compile-time rejection logic. Keep errors as `%{key, message, hint}` maps until `build_error/3`.

### `lib/crosswake/manifest/builder.ex` (service, transform)

**Analog:** `lib/crosswake/manifest/builder.ex`

**Manifest wiring** (lines 10-29, 31-46):
```elixir
@spec build([Route.t()], [map()], keyword()) :: Types.Root.t()
def build(routes, managed_routes, opts \\ [])
    when is_list(routes) and is_list(managed_routes) do
  capability_registry = capability_registry(routes)
  support_matrix =
    Keyword.get(opts, :support_matrix, Crosswake.SupportMatrix.canonical(capability_registry: capability_registry))

  Types.new_root(
    compatibility: compatibility,
    support_matrix: support_matrix,
    capability_registry: capability_registry,
    routes: route_entries(routes, managed_routes, host.origin)
  )
end
```

**Capability catalog metadata** (lines 139-249):
```elixir
[
  [id: "deep_link", family: "deep_link", proof_class: :merge_blocking, denial: "route_unavailable"],
  [id: "share", family: "share", proof_class: :advisory, denial: "unavailable_capability"],
  [id: "notification_token", family: "notification_token", package_class: :companion, rebuild: :companion_required],
  [id: "file_picker", family: "file_picker", prerequisites: ["declared transfer_id", "inbound native_picker transfer seam"], legacy_ids: ["files.pick"]]
]
```

Phase 18 should extend this catalog first, then derive doctor/support/docs from it.

### `lib/crosswake/bridge/registry.ex` (service, request-response)

**Analog:** `lib/crosswake/bridge/registry.ex`

**Command-to-family map** (lines 12-26):
```elixir
@capability_commands %{
  "app.info.get" => "app.info.get",
  "haptics.impact" => "haptics.impact",
  "permissions.status" => "permissions.status",
  "notifications.token.get" => "notification_token",
  "files.pick" => "file_picker",
  "share.invoke" => "share.invoke"
}
```

**Fail-closed lookup split** (lines 72-93, 96-138):
```elixir
with true <- command_supported?(command) || {:error, :unsupported_command},
     %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route} do
  lookup_entry(manifest, route, command, payload)
end

cond do
  command == "files.pick" -> file_picker_entry(route, command, payload)
  capability_id = Map.get(@capability_commands, command) -> capability_entry(manifest, route, command, capability_id)
  transfer_intent = Map.get(@transfer_commands, command) -> transfer_entry(route, command, transfer_intent)
end
```

**Transfer-backed picker exception** (lines 115-137):
```elixir
case Enum.find(route.transfers, &(&1.id == transfer_id)) do
  %TransferSeam{} = transfer ->
    case Contracts.validate_picker_declaration(transfer_declaration(transfer)) do
      :ok -> {:ok, %Entry{command: command, capability: "file_picker", version: transfer.version, route_id: route.id}}
      {:error, _reason} -> {:error, :undeclared_capability}
    end
  nil -> {:error, :undeclared_capability}
end
```

Planner should copy this exact split for any new enforcement or denial work. Do not treat `deep_link` like a bridge command.

### `lib/crosswake/doctor/doctor.ex` (service, batch)

**Analog:** `lib/crosswake/doctor/doctor.ex`

**Imports and report struct** (lines 1-30):
```elixir
defmodule Crosswake.Doctor do
  alias Crosswake.Bridge.Contract
  alias Crosswake.Bridge.Registry
  alias Crosswake.Doctor.Check
  alias Crosswake.Manifest
  alias Crosswake.Policy.Compiler
  alias Crosswake.SupportMatrix

  defmodule Report do
    defstruct [:status, :install_manifest, :manifest, shells: %{}, bridge: %{}, offline: %{}, support: %{}, findings: []]
  end
```

**Run orchestration** (lines 107-134):
```elixir
def run(opts \\ []) do
  {install_manifest, findings} = load_install_manifest(install_manifest_path)
  findings = findings ++ router_and_policy_findings(install_manifest, cwd)
  {manifest, findings} = compile_and_validate_manifest(findings, opts)
  {shells, bridge, support, phase_3_findings} = phase_3_posture(manifest, cwd, opts)
  %Report{status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok), ...}
end
```

**Support posture and findings** (lines 540-691):
```elixir
%{
  status: if(blocking_platforms == [], do: :supported, else: :verification_required),
  blocking_platforms: blocking_platforms,
  proof_statuses: proof_statuses,
  release_policy: release_policy_snapshot(manifest)
}

check(:error, "support_claim_verification_required", "support_posture", "...", "run mix crosswake.doctor --native-checks ...")
check(:advisory, "capability_proof_advisory", "capability_posture", "...", "advisory capabilities do not block standard CI ...")
```

**Artifact/remediation copy** (lines 704-772):
```elixir
check(if(ok?, do: :advisory, else: :warning), ..., "shell_activation", "...", "restore manifest-first activation and route unavailable artifacts: ...")
check(severity, code, "proof_posture", "#{shell.label} generated-project proof hook is #{proof_label(shell.proof.status)}", hint, %{...})
```

If a Phase 18 helper module is introduced, keep the `check/6` contract and explicit remediation style.

### `lib/crosswake/doctor/formatter.ex` (utility, transform)

**Analog:** `lib/crosswake/doctor/formatter.ex`

**Formatter entrypoint** (lines 8-24):
```elixir
@spec render(map()) :: String.t()
def render(report) do
  [
    "Crosswake doctor report",
    "status: #{Map.get(report, :status)}",
    format_support(Map.get(report, :support, %{})),
    format_shells(Map.get(report, :shells, %{})),
    format_findings(findings)
  ]
  |> Enum.reject(&(&1 in [nil, ""]))
  |> Enum.join("\n")
end
```

**Stable severity ordering** (lines 187-232):
```elixir
defp format_findings(findings) do
  findings
  |> Enum.sort_by(&severity_order/1)
  |> Enum.map(&format_check/1)
end

defp severity_order(%Check{severity: :error}), do: 0
defp severity_order(%Check{severity: :warning}), do: 1
defp severity_order(%Check{severity: :advisory}), do: 2
```

Mirror this ordering in any new doctor formatting surface.

### `lib/crosswake/doctor/json_formatter.ex` (utility, transform)

**Analog:** `lib/crosswake/doctor/json_formatter.ex`

**JSON formatter convention** (lines 1-6, 119-122):
```elixir
defmodule Crosswake.Doctor.JSONFormatter do
  alias Crosswake.Doctor.Check

  defp format_proof_status(:passed), do: "supported"
  defp format_proof_status(:verification_required), do: "verification required"
```

Keep string status formatting aligned with human formatter and support-matrix renderer.

### `lib/mix/tasks/crosswake.doctor.ex` (config, request-response)

**Analog:** `lib/mix/tasks/crosswake.doctor.ex`

**CLI task pattern** (lines 15-20, 23-50):
```elixir
@switches [format: :string, router: :string, install_manifest: :string, native_checks: :boolean]

def run(args) do
  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
  report = Doctor.run(route_source: router_module!(opts[:router]), ...)
  output = case opts[:format] do
    nil -> Formatter.render(report)
    "json" -> JSONFormatter.render(report)
  end
  Mix.shell().info(output)
  if report.status == :error, do: Mix.raise("Crosswake doctor found blocking issues")
end
```

### `lib/crosswake/support_matrix/support_matrix.ex` (service, transform)

**Analog:** `lib/crosswake/support_matrix/support_matrix.ex`

**Canonical typed source** (lines 17-24, 41-80):
```elixir
def canonical(opts \\ []) do
  capability_registry =
    Keyword.get_lazy(opts, :capability_registry, fn ->
      Crosswake.Manifest.Builder.capability_registry([])
    end)

  Types.new_support_matrix(
    phoenix: [...],
    ios: [...],
    android: [...],
    shells: [...],
    capability_families: capability_family_entries(capability_registry)
  )
end
```

**Validation guardrails** (lines 83-90, 135-149, 157-183):
```elixir
[]
|> validate_categories_present(support_matrix)
|> validate_exact_statuses(support_matrix)
|> validate_narrow_baseline(support_matrix)
|> validate_capability_families_present(support_matrix)
```

**Manifest-derived capability rows** (lines 327-343):
```elixir
capability_registry
|> Enum.map(fn {_id, capability} -> capability end)
|> Enum.filter(fn capability -> capability.id == capability.family end)
|> Enum.map(fn %Capability{} = capability ->
  Types.new_capability_support_entry(
    family: capability.family,
    proof_class: capability.proof_class,
    rebuild: capability.rebuild,
    prerequisites: capability.prerequisites
  )
end)
```

### `lib/crosswake/support_matrix/renderer.ex` (utility, file-I/O)

**Analog:** `lib/crosswake/support_matrix/renderer.ex`

**Deterministic Markdown rendering** (lines 15-23, 30-49):
```elixir
def render(%SupportMatrix{} = support_matrix) do
  [
    "# Crosswake Support Matrix",
    "## Status Legend",
    section("Phoenix", support_matrix.phoenix),
    capability_family_section(support_matrix.capability_families)
  ]
  |> Enum.join("\n")
end
```

**Idempotent write semantics** (lines 52-72):
```elixir
case File.read(path) do
  {:ok, ^contents} -> {:ok, :reused}
  {:ok, _previous} -> File.write!(path, contents); {:ok, :updated}
  {:error, :enoent} -> File.write!(path, contents); {:ok, :created}
end
```

Use this for `guides/support_matrix.md`; do not hand-edit the guide as primary truth.

### `guides/bridge.md` (config, transform)

**Analog:** `guides/bridge.md`

**Public framing pattern** (lines 1-20):
```md
Crosswake exposes one typed, versioned, request/reply-only bridge.
... its public framing is family-first rather than command-first:
...
`deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.
```

**Enforcement checklist** (lines 38-52):
```md
Before any side effect runs, Crosswake checks:
- The active route matches `route_id`
- The route exists in the manifest
- The origin is allowlisted for the route
- The command is in the bounded Phase 3 allowlist
```

Phase 18 guide edits should update command drift but keep this family-first posture.

### `guides/capabilities.md` (config, transform)

**Analog:** `guides/capabilities.md`

**Capability-family framing** (lines 22-25, 45, 53-65):
```md
Capability families are public vocabulary. Bridge commands are subordinate protocol details.
`deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.
`file_picker` keeps the route Phoenix-owned only when it stays subordinate to an inbound `source: :native_picker` transfer seam.
```

### `guides/native_shell.md` (config, transform)

**Analog:** `guides/native_shell.md`

**Activation-first boundary** (lines 32-47):
```md
Every app-entry path normalizes into one activation request before any web container exists.
`deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.
- Denied deep links open a Crosswake-owned `route unavailable` screen.
```

**Proof-hook section** (lines 60-76):
```md
Published shell support is proof-backed by:
- `bash script/verify_phase5_example_hosts.sh`
Generated-host verification remains part of the contract:
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`
```

### `guides/support_matrix.md` (config, transform)

**Analog:** `lib/crosswake/support_matrix/renderer.ex`

**Generated-guide shape** (current output lines 44-63):
```md
## Capability Families
| Family | Owner | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |
| app_info | bounded_bridge | core | merge-blocking | none | ... |
| deep_link | bounded_bridge | core | merge-blocking | none | ... |
| notification_token | bounded_bridge | companion | advisory | companion-required | ... |
```

Planner should treat this as generated output, not a hand-maintained source.

### `test/crosswake/bridge/registry_test.exs` (test, request-response)

**Analog:** `test/crosswake/bridge/registry_test.exs`

**Allowlist assertion pattern** (lines 11-37):
```elixir
assert Registry.allowed_commands() == [
  "app.info.get",
  "files.pick",
  "notifications.token.get",
  "share.invoke",
  "transfer.upload.prepare"
]
refute Registry.command_supported?("share.sheet.present")
```

**Fail-closed picker cases** (lines 79-117):
```elixir
assert {:ok, entry} = Registry.lookup(manifest, "library", "files.pick", %{"transfer_id" => "lesson_import"})
assert {:error, :undeclared_capability} = Registry.lookup(manifest, "dashboard", "files.pick")
assert {:error, :undeclared_capability} = Registry.lookup(manifest, "library", "files.pick", %{})
```

### `test/crosswake/doctor/doctor_test.exs` (test, batch)

**Analog:** `test/crosswake/doctor/doctor_test.exs`

**Fixture setup style** (lines 26-70):
```elixir
setup do
  target = Path.join(System.tmp_dir!(), "crosswake-doctor-#{System.unique_integer([:positive])}")
  File.write!(router_path, """
  defmodule DemoWeb.Router do
    # crosswake:install:start
    import Crosswake.Router
    # crosswake:install:end
  end
  """)
  write_shell_artifacts!(target)
end
```

**Structured finding assertions** (lines 73-124, 126-176):
```elixir
assert report.support.status == :verification_required
assert Enum.any?(report.findings, &(&1.check == "proof_posture" and &1.code == "proof_hook_verification_required"))
assert human =~ "support posture: supported"
assert decoded["shells"]["ios"]["proof"]["status"] == "supported"
```

### `test/crosswake/support_matrix/support_matrix_test.exs` (test, transform)

**Analog:** `test/crosswake/support_matrix/support_matrix_test.exs`

**Typed support truth tests** (lines 7-40, 71-116):
```elixir
matrix = SupportMatrix.canonical()
assert root_map["support_matrix"]["capability_families"] != []

matrix = SupportMatrix.canonical(capability_registry: capability_registry)
assert matrix.capability_families == [
  Types.new_capability_support_entry(family: "haptics", proof_class: :merge_blocking, ...)
]
```

### `test/crosswake/support_matrix/renderer_test.exs` (test, file-I/O)

**Analog:** `test/crosswake/support_matrix/renderer_test.exs`

**Renderer idempotence + guide-lock tests** (lines 7-27, 29-55, 77-101):
```elixir
assert rendered_once == rendered_twice
assert {:ok, :created} = Renderer.write(path, matrix)
assert {:ok, :updated} = Renderer.write(path, updated_matrix)
assert File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())
```

### `test/crosswake/shell/activation_test.exs` (test, request-response)

**Analog:** `test/crosswake/shell/activation_test.exs`

**Deep-link stays activation-only** (lines 12-70, 114-171):
```elixir
Activation.new_request(url: "#{Types.default_origin()}/dashboard", source: :deep_link, manifest_source: :cached, ...)
assert %Decision{status: :deny, denial: %Denial{reason: :external_entry_denied}} = deny_decision
assert %Decision{status: :allow, route_id: "capture"} = decision
```

Use this for any new Phase 18 activation proof. Do not route `deep_link` through bridge tests.

### `test/support/router_fixtures.ex` (test, request-response)

**Analog:** `test/support/router_fixtures.ex`

**Managed router declarations** (lines 52-121):
```elixir
live "/library", Crosswake.TestSupport.LibraryLive,
  crosswake: [
    id: "library",
    transfers: [[id: :lesson_import, intent: :import, source: :native_picker, verification: :required]]
  ]

live "/camera", Crosswake.TestSupport.CameraLive, :capture,
  crosswake: [id: "camera", runtime: :native_screen, capabilities: [:camera], ...]
```

This is the pattern source for any new ExUnit router fixture covering picker, notification, or deep-link proof.

### `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` (service, request-response)

**Analog:** `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`

**Enum + capability mapping** (lines 8-29):
```swift
enum BridgeCommand: String, CaseIterable {
    case notificationsTokenGet = "notifications.token.get"
    case shareInvoke = "share.invoke"
    case filesPick = "files.pick"

    var capability: String {
        case .notificationsTokenGet: return "notification_token"
        case .filesPick: return "file_picker"
    }
}
```

**Fail-closed evaluation** (lines 187-360):
```swift
guard request.protocolName == Self.protocolName, ... else {
    completion(deny(request, reason: "compatibility_mismatch", ...)); return
}
guard let command = BridgeCommand(rawValue: request.command), request.capability == command.capability else {
    completion(deny(request, reason: "undeclared_capability", ...)); return
}
case .notificationsTokenGet:
    guard let permissionPayload = permissionStatusProvider("notifications") else { ... }
case .filesPick:
    filesPickHandler(request.payload, request.correlationID) { ... }
```

### `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` (service, request-response)

**Analog:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`

**Enum + capability mapping** (lines 9-36):
```kotlin
enum class BridgeCommand(val wireValue: String) {
    NOTIFICATIONS_TOKEN_GET("notifications.token.get"),
    SHARE_INVOKE("share.invoke"),
    FILES_PICK("files.pick");

    val capability: String
        get() = when (this) {
            NOTIFICATIONS_TOKEN_GET -> "notification_token"
            FILES_PICK -> "file_picker"
            else -> wireValue
        }
}
```

**Android denial and deferred picker handling** (lines 96-244):
```kotlin
if (request.origin != session.allowedOrigin) {
    return deny(request, "origin_denied", ...)
}
if (request.capability != command.capability) {
    return deny(request, "undeclared_capability", ...)
}
BridgeCommand.FILES_PICK -> {
    when (val result = filesPickHandler(request.payload, request.correlationId)) {
        is FilesPickResult.Immediate -> ok(request, result.payload)
        is FilesPickResult.Deferred -> ...
    }
}
```

### `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift` (test, request-response)

**Analog:** `examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift`

**Notification-token proof style** (lines 89-110):
```swift
let reply = await evaluate(channel, request: request(command: "notifications.token.get", capability: "notification_token", ...))
XCTAssertEqual(reply.status, "ok")
XCTAssertEqual(reply.payload["provider"], "apns")
XCTAssertEqual(reply.payload["detail.snapshot_source"], "app_delegate")
```

**Picker proof style** (lines 215-308):
```swift
XCTAssertEqual(reply.payload["transfer_id"], "lesson_import")
XCTAssertEqual(reply.payload["outcome"], "canceled")
XCTAssertEqual(reply.denial?.denial.reason, "undeclared_capability")
```

### `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt` (test, request-response)

**Analog:** `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt`

**Notification-token proof style** (lines 66-138):
```kotlin
val reply = evaluate(channel, request(command = "notifications.token.get", capability = "notification_token", ...))
assertEquals("ok", reply.getString("status"))
assertEquals("fcm", reply.payload().getString("provider"))
```

**Picker proof style** (lines 140-203):
```kotlin
assertEquals("lesson_import", reply.payload().getString("transfer_id"))
assertEquals("staged://lesson_import/asset-1", reply.payload().getString("items.0.handle"))
assertEquals("canceled", reply.payload().getString("status"))
```

### `test/crosswake/proof/phase18_*_test.exs` (test, request-response)

**Analog:** `test/crosswake/proof/phase8_selective_native_lane_test.exs`

**Proof-lane structure** (lines 1-18, 20-57):
```elixir
Code.require_file("../../support/example_host.exs", __DIR__)

defmodule Crosswake.Proof.Phase8SelectiveNativeLaneTest do
  use ExUnit.Case, async: false
  alias Crosswake.Manifest

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()
    :ok
  end
end
```

**Manifest assertion style** (lines 20-57):
```elixir
assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)
capture_route = manifest.routes["selective-native-claim-capture"]
assert capture_route.runtime == :native_screen
assert transfer.source == :native_capture
```

For the implied Phase 18 acceptance slice, keep it narrow and manifest-backed like this. Do not build one giant hero flow.

## Shared Patterns

### Family-First Public DSL, Command-Aware Runtime
**Source:** `lib/crosswake/policy/validator.ex:123-137`, `lib/crosswake/bridge/registry.ex:80-113`, `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift:205-215`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt:112-122`
**Apply to:** validator, registry, both shell bridge channels, bridge guide
```elixir
if MapSet.member?(@known_capabilities, capability) do
  acc
else
  [%{key: :capabilities, message: "unknown capability #{inspect(capability)}"} | acc]
end
```

### `file_picker` Is Transfer-Backed, Not Ambient
**Source:** `lib/crosswake/bridge/registry.ex:115-137`, `test/support/router_fixtures.ex:57-92`, `guides/capabilities.md:58-65`
**Apply to:** registry, doctor wording, support rows, bridge tests, any new proof slice
```elixir
case Enum.find(route.transfers, &(&1.id == transfer_id)) do
  %TransferSeam{} = transfer -> Contracts.validate_picker_declaration(transfer_declaration(transfer))
  nil -> {:error, :undeclared_capability}
end
```

### Manifest Metadata Is the Operational Truth Source
**Source:** `lib/crosswake/manifest/builder.ex:139-249`, `lib/crosswake/support_matrix/support_matrix.ex:327-343`, `lib/crosswake/support_matrix/renderer.ex:86-166`
**Apply to:** manifest builder, support matrix, doctor release-policy snapshot, guides
```elixir
Types.new_capability_support_entry(
  family: capability.family,
  proof_class: capability.proof_class,
  rebuild: capability.rebuild,
  prerequisites: capability.prerequisites,
  denial: capability.denial
)
```

### Doctor Findings Must Be Typed and Remediation-Oriented
**Source:** `lib/crosswake/doctor/doctor.ex:638-772`, `lib/crosswake/doctor/formatter.ex:194-232`, `lib/mix/tasks/crosswake.doctor.ex:46-49`
**Apply to:** doctor core, formatters, CLI exit behavior, doctor tests
```elixir
check(
  :error,
  "support_claim_verification_required",
  "support_posture",
  "...",
  "run mix crosswake.doctor --native-checks ..."
)
```

### `deep_link` Proof Stays in Activation, Not Bridge
**Source:** `test/crosswake/shell/activation_test.exs:114-171`, `guides/native_shell.md:32-47`, `guides/bridge.md:16-20`
**Apply to:** activation tests, native-shell guide, support truth wording
```elixir
assert %Decision{
         status: :deny,
         route_id: "dashboard",
         denial: %Denial{reason: :external_entry_denied}
       } = deny_decision
```

## No Analog Found

None. Every likely Phase 18 surface already has a close in-repo analog. The only implied new file is the narrow proof-lane test, and `test/crosswake/proof/phase8_selective_native_lane_test.exs` is the correct structural analog.

## Metadata

**Analog search scope:** `lib/crosswake`, `test/crosswake`, `test/support`, `guides`, `examples/ios_shell_host`, `examples/android_shell_host`
**Files scanned:** 24 anchor files plus one proof-lane analog
**Pattern extraction date:** 2026-05-21
