# Phase 16: System Context Bridges - Pattern Map

**Mapped:** 2026-05-20
**Files analyzed:** 24
**Analogs found:** 24 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/policy/defaults.ex` | config | request-response | `lib/crosswake/policy/defaults.ex` | exact |
| `lib/crosswake/policy/schema.ex` | config | request-response | `lib/crosswake/policy/schema.ex` | exact |
| `lib/crosswake/policy/route.ex` | model | request-response | `lib/crosswake/policy/route.ex` | exact |
| `lib/crosswake/router/scope_defaults.ex` | utility | transform | `lib/crosswake/router/scope_defaults.ex` | exact |
| `lib/crosswake/policy/validator.ex` | utility | request-response | `lib/crosswake/policy/validator.ex` | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/manifest/builder.ex` | exact |
| `lib/crosswake/manifest/serializer.ex` | utility | file-I/O | `lib/crosswake/manifest/serializer.ex` | exact |
| `lib/crosswake/manifest/validator.ex` | utility | request-response | `lib/crosswake/manifest/validator.ex` | exact |
| `lib/crosswake/shell/activation.ex` | service | request-response | `lib/crosswake/shell/activation.ex` | exact |
| `lib/crosswake/compatibility/compatibility.ex` | service | request-response | `lib/crosswake/compatibility/compatibility.ex` | exact |
| `lib/crosswake/bridge/contract.ex` | model | request-response | `lib/crosswake/bridge/contract.ex` | exact |
| `lib/crosswake/bridge/registry.ex` | service | request-response | `lib/crosswake/bridge/registry.ex` | exact |
| `lib/crosswake/bridge/commands/permissions_status.ex` | model | request-response | `lib/crosswake/bridge/commands/app_info.ex` | role-match |
| `lib/crosswake/support_matrix/support_matrix.ex` | service | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `lib/crosswake/doctor/doctor.ex` | service | batch | `lib/crosswake/doctor/doctor.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | route | request-response | `examples/phoenix_host/lib/crosswake_example/router.ex` | exact |
| `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift` | controller | request-response | `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift` | exact |
| `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | controller | request-response | `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift` | exact |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt` | controller | request-response | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt` | exact |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | controller | request-response | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt` | exact |
| `test/crosswake/shell/activation_test.exs` | test | request-response | `test/crosswake/shell/activation_test.exs` | exact |
| `test/crosswake/bridge/registry_test.exs` | test | request-response | `test/crosswake/bridge/registry_test.exs` | exact |
| `test/crosswake/doctor/doctor_test.exs` | test | batch | `test/crosswake/doctor/doctor_test.exs` | exact |
| `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift` | test | request-response | `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift` | exact |
| `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/ActivationCoordinatorTest.kt` | test | request-response | `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/ActivationCoordinatorTest.kt` | exact |

## Pattern Assignments

### Deep-link route-entry metadata in policy DSL and validation

**Expected files:** `lib/crosswake/policy/defaults.ex`, `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/router/scope_defaults.ex`, `lib/crosswake/policy/validator.ex`, `examples/phoenix_host/lib/crosswake_example/router.ex`

**Best analogs:** `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/router/scope_defaults.ex`, `lib/crosswake/policy/validator.ex`

**Defaults + scope override pattern**  
Source: `lib/crosswake/policy/defaults.ex:6-14`, `lib/crosswake/router/scope_defaults.ex:19-25`, `:64-72`
```elixir
@route [
  offline: :unavailable,
  capabilities: [],
  packs: [],
  sync: []
]

nested_defaults =
  nested_defaults_ast
  |> Crosswake.Router.__eval_keyword!(caller)
  |> Merge.route_defaults(defaults)

merged_crosswake =
  defaults
  |> Merge.route_defaults(crosswake || [])
```

**Schema field addition pattern**  
Source: `lib/crosswake/policy/schema.ex:13-61`
```elixir
@schema NimbleOptions.new!([
  id: [...],
  runtime: [...],
  offline: [...],
  cache_contract: [...],
  island_contract: [...],
  capabilities: [...],
  packs: [...],
  sync: [...],
  transfers: [...],
  security: [...]
])
```
Add deep-link entry metadata here as a first-class field, not ad hoc metadata elsewhere.

**Route struct + post-schema semantic validation pattern**  
Source: `lib/crosswake/policy/route.ex:9-21`, `:36-47`, `:69-90`, `:122-151`
```elixir
@enforce_keys [:id, :runtime]
defstruct [
  :id,
  :runtime,
  :security,
  :cache_contract,
  :island_contract,
  offline: :unavailable,
  capabilities: [],
  packs: [],
  sync: [],
  transfers: []
]

with {:ok, validated} <- validate_offline_contracts(validated),
     {:ok, validated} <- validate_pack_requirements(validated),
     {:ok, validated} <- validate_transfer_declarations(validated) do
  {:ok, struct!(__MODULE__, validated)}
end
```
Deep-link approval semantics should follow this split: shape in `Schema`, cross-field invariants in `Route` and `Validator`.

**Route-policy metadata validation pattern**  
Source: `lib/crosswake/policy/validator.ex:34-42`, `:76-94`, `:95-113`
```elixir
[]
|> validate_runtime_offline(route)
|> validate_sync(route)
|> validate_security(route)
|> validate_capabilities(route)
|> validate_unique_list(route, :capabilities, route.capabilities)

%{
  key: :security,
  message: "security must be declared when offline, capability, pack, or sync policy is enabled",
  hint: "add security: :standard or security: :sensitive to the route policy"
}
```
Use this error shape for route-entry policy failures, including the explicit distinction between invalid metadata and risky widening.

**Example host declaration pattern**  
Source: `examples/phoenix_host/lib/crosswake_example/router.ex:54-71`, `:118-161`
```elixir
crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
  live "/approvals/:id", ApprovalLive,
    crosswake: [
      id: "saas-approval",
      runtime: :live_view,
      capabilities: ["haptics.impact"],
      offline: :cached_read_only,
      security: :standard
    ]
end
```
Phase 16 route-entry metadata should be declared inside `crosswake:` alongside other explicit route policy, with `crosswake_defaults` support for scope defaults and per-route override.

### Manifest route-entry serialization and validation

**Expected files:** `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`, `lib/crosswake/manifest/serializer.ex`, `lib/crosswake/manifest/validator.ex`

**Best analogs:** `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`, `lib/crosswake/manifest/serializer.ex`

**Typed manifest entry pattern**  
Source: `lib/crosswake/manifest/types.ex:127-156`
```elixir
defmodule RouteEntry do
  @enforce_keys [:id, :path, :runtime]
  defstruct [
    :id,
    :path,
    :runtime,
    :offline,
    :cache_contract,
    :island_contract,
    :security,
    capabilities: [],
    packs: [],
    sync: [],
    transfers: [],
    allowlisted_origins: []
  ]
end
```
Deep-link approval belongs here as stable manifest truth on the route entry, not in shell-only config.

**Manifest build pattern**  
Source: `lib/crosswake/manifest/builder.ex:63-83`
```elixir
entry =
  Types.new_route_entry(
    id: route.id,
    path: path,
    runtime: route.runtime,
    offline: route.offline,
    cache_contract: cache_contract(route),
    island_contract: island_contract(route),
    capabilities: route.capabilities,
    packs: route_pack_references(route.packs),
    sync: route.sync,
    transfers: transfer_seams(route.transfers),
    security: route.security,
    allowlisted_origins: [origin]
  )
```
Copy this pattern when threading route-entry policy from `Route` into manifest serialization.

**Capability metadata serialization pattern for `permissions.status`**  
Source: `lib/crosswake/manifest/builder.ex:138-200`
```elixir
[
  id: "permissions.status",
  family: "permissions.status",
  owner: :bounded_bridge,
  package_class: :example_docs_only,
  proof_class: :advisory,
  rebuild: :none,
  prerequisites: ["point-of-need permission snapshot", "declared route capability"],
  denial: "unavailable_capability",
  fallback: "route continues without native permission snapshot authority",
  guide: "guides/capabilities.md#bounded-bridge"
]
```
This is the existing catalog seam to promote from docs-only/advisory to actual Phase 16 support truth.

**Deterministic JSON serialization pattern**  
Source: `lib/crosswake/manifest/serializer.ex:10-18`, `:43-53`
```elixir
def render(%Types.Root{} = manifest) do
  manifest
  |> Types.to_map()
  |> ordered()
  |> Jason.encode_to_iodata!(pretty: true)
  |> IO.iodata_to_binary()
  |> Kernel.<>("\n")
end
```
Do not add shell-local manifest encoders. Extend `Types.to_map/1` and let the serializer stay generic.

**Manifest route validation pattern**  
Source: `lib/crosswake/manifest/validator.ex:80-87`, `:89-122`
```elixir
[]
|> validate_route_field(route, :path, route.path)
|> validate_route_field(route, :runtime, route.runtime)
|> validate_route_capabilities(route, capability_registry)
|> validate_route_packs(route, pack_registry)
|> validate_route_transfers(route)
```
Route-entry manifest validation for deep-link metadata should plug in here, with route-scoped errors and hints.

### Activation denial reasons and manifest-first deep-link gating

**Expected files:** `lib/crosswake/shell/activation.ex`, `lib/crosswake/compatibility/compatibility.ex`, iOS/Android `ActivationCoordinator`

**Best analogs:** `lib/crosswake/shell/activation.ex`, `lib/crosswake/compatibility/compatibility.ex`

**Shared activation request/decision contract**  
Source: `lib/crosswake/shell/activation.ex:11-37`, `:43-57`, `:79-91`
```elixir
defmodule Request do
  @enforce_keys [
    :source,
    :origin,
    :manifest_source,
    :bridge_protocol_version,
    :native_runtime_version,
    :correlation_id
  ]
end

def resolve(%Root{} = manifest, %Request{} = request) do
  route_id = request.route_id || route_id_from_url(manifest, request.url)
  decision = RouteGate.evaluate(manifest, route_id, target_from_request(request))
```
Phase 16 deep-link entry approval should extend this contract, not bypass it with shell-only checks.

**Activation denial mapping pattern**  
Source: `lib/crosswake/shell/activation.ex:173-193`
```elixir
if Map.has_key?(manifest.routes, route_id) do
  Denial.new(
    reason: :compatibility_mismatch,
    route_id: route_id,
    message: "Activation denied before runtime boot.",
    details: %{reasons: Map.get(decision, :reasons, [])}
  )
else
  Denial.new(
    reason: :inactive_route,
    route_id: route_id,
    message: "The requested route is not active in the manifest.",
    hint: "refresh the bundled manifest before opening the route"
  )
end
```
This is the nearest analog for the new distinction Phase 16 needs: keep `inactive_route` for unknown paths, add a separate reason for known route but not approved for external entry.

**Compatibility-to-denial reason pattern**  
Source: `lib/crosswake/compatibility/compatibility.ex:99-145`
```elixir
case finding.axis do
  :route -> {:inactive_route, recovery_for(:inactive_route, opts), %{}}
  :active_route -> {:inactive_route, recovery_for(:inactive_route, opts), %{}}
  :origin -> {:origin_denied, %{}, %{}}
  :bridge_command -> {:undeclared_capability, %{}, capability_details(finding)}
  :capability_registry -> {:undeclared_capability, %{}, capability_details(finding)}
  :capability_version -> {:unavailable_capability, %{}, capability_details(finding)}
  :pack_version -> {:pack_incompatible, recovery_for(:pack_incompatible, opts), pack_details(finding, opts)}
  _other -> {:compatibility_mismatch, recovery_for(:compatibility_mismatch, opts), %{}}
end
```
Add the new external-entry denial reason here too if Phase 16 surfaces it through compatibility/activation findings.

**Recovery/safe fallback pattern**  
Source: `lib/crosswake/compatibility/compatibility.ex:669-690`
```elixir
defp recovery_for(:inactive_route, opts) do
  case Keyword.get(opts, :fallback_route_id) do
    nil -> %{}
    fallback_route_id -> %{mode: :safe_fallback, fallback_route_id: fallback_route_id, actions: [:retry, :open_safe_fallback]}
  end
end
```
Use the same fail-closed but recoverable posture for external-entry denials.

### Bridge command registration and `permissions.status` handling

**Expected files:** `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/bridge/commands/permissions_status.ex`, iOS/Android `BridgeChannel`

**Best analogs:** `lib/crosswake/bridge/registry.ex`, `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/commands/app_info.ex`

**Command registration pattern**  
Source: `lib/crosswake/bridge/registry.ex:11-16`, `:40-49`, `:82-98`
```elixir
@capability_commands %{
  "app.info.get" => "app.info.get",
  "haptics.impact" => "haptics.impact",
  "files.pick" => "files.pick",
  "share.invoke" => "share.invoke"
}

def command_capability(command) do
  Map.get(@capability_commands, command) || if(Map.has_key?(@transfer_commands, command), do: command)
end

with true <- capability_declared_on_route?(route, capability_id) || {:error, :undeclared_capability},
     %Capability{} = capability <- lookup_capability(manifest, capability_id) || {:error, :undeclared_capability} do
  {:ok, %Entry{command: command, capability: capability.family, version: capability.version, route_id: route.id}}
end
```
Register `permissions.status` as another manifest-backed bounded command here. Do not special-case it outside the registry.

**Bridge envelope pattern**  
Source: `lib/crosswake/bridge/contract.ex:22-49`, `:67-93`, `:140-159`
```elixir
defmodule Request do
  @enforce_keys [:protocol, :version, :command, :capability, :route_id, :active_route_id, :origin, :native_runtime_version, :correlation_id]
  defstruct [..., capabilities: %{}, installed_packs: %{}, payload: %{}]
end

def ok_reply(%Request{} = request, payload \\ %{}) when is_map(payload) do
  new_reply(command: request.command, route_id: request.route_id, correlation_id: request.correlation_id, status: :ok, payload: payload)
end
```
`permissions.status` should use the same request/reply envelope with normalized status in `payload`.

**Typed payload module pattern**  
Source: `lib/crosswake/bridge/commands/app_info.ex:6-25`, `lib/crosswake/bridge/commands/share.ex:6-16`
```elixir
defmodule Request do
  @enforce_keys [:style]
  defstruct [:style]
end

defmodule Response do
  @enforce_keys [:version, :build, :bundle_id]
  defstruct [:version, :build, :bundle_id]
end
```
Model `permissions.status` as a tiny request/response struct pair: request keyed by permission alias or capability prerequisite, response keyed by normalized status plus optional detail.

**Elixir command validation pattern**  
Source: `lib/crosswake/compatibility/compatibility.ex:445-540`
```elixir
case Registry.command_capability(request.command) do
  nil ->
    finding(..., "bridge command #{request.command} is outside the bounded Phase 3 command set", ...)

  capability_id ->
    errors
    |> validate_bridge_capability_identity(route, request, capability_id)
    |> validate_bridge_capability_route(route, capability_id)
    |> validate_bridge_capability_version(route, registry, request, capability_id)
end
```
Use this exact validation chain for `permissions.status`; do not make permission queries bypass capability allowlisting.

### Support-matrix and doctor truth for `deep_link` and `permissions.status`

**Expected files:** `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/doctor/doctor.ex`

**Best analogs:** `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/manifest/builder.ex`

**Capability-family support entry derivation**  
Source: `lib/crosswake/support_matrix/support_matrix.ex:327-343`
```elixir
capability_registry
|> Enum.map(fn {_id, capability} -> capability end)
|> Enum.filter(fn capability -> capability.id == capability.family end)
|> Enum.map(fn %Capability{} = capability ->
  Types.new_capability_support_entry(
    family: capability.family,
    owner: capability.owner,
    package_class: capability.package_class,
    proof_class: capability.proof_class,
    rebuild: capability.rebuild,
    prerequisites: capability.prerequisites,
    denial: capability.denial,
    fallback: capability.fallback,
    guide: capability.guide
  )
end)
```
If Phase 16 promotes `permissions.status`, this is where support truth becomes public.

**Doctor bridge posture pattern**  
Source: `lib/crosswake/doctor/doctor.ex:490-537`, `:591-617`
```elixir
command_posture =
  Enum.map(Registry.allowed_commands(), fn command ->
    capability = Registry.command_capability(command)
    ...
    %{command: command, capability: capability, declared_on_routes: routes, manifest_version: capability_entry && capability_entry.version, executable?: routes != [] and capability_entry != nil}
  end)

check(
  if(unsupported == [], do: :advisory, else: :warning),
  ...,
  "bounded bridge exposes #{Enum.join(bridge.allowed_commands, ", ")} and denies #{Enum.join(bridge.denial_reasons, ", ")}",
  unsupported_message,
  %{protocol: bridge.protocol, version: bridge.version, commands: bridge.command_posture}
)
```
Use this to expose `permissions.status` registration and whether it is actually executable on any declared route.

**Doctor shell activation posture pattern**  
Source: `lib/crosswake/doctor/doctor.ex:703-724`
```elixir
check(
  if(ok?, do: :advisory, else: :warning),
  if(ok?, do: "shell_activation_ready", else: "shell_activation_incomplete"),
  "shell_activation",
  "#{shell.label} shell is manifest-first and exposes route unavailable + pack_incompatible denial surfaces",
  ...
)
```
Extend this pattern for deep-link approval truth so doctor can distinguish inactive path from blocked external entry.

### iOS shell activation and deep-link denial

**Expected files:** `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift`

**Best analog:** `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift`

**Incoming URL normalization pattern**  
Source: `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift:79-93`, `:243-250`, `:403-418`
```swift
static func forIncomingURL(_ url: URL, source: ActivationSource, seededBy baseline: ActivationRequest) -> ActivationRequest {
    ActivationRequest(
        routeID: nil,
        url: url,
        source: source,
        origin: url.crosswakeOrigin ?? baseline.origin,
        ...
    )
}

func openURL(_ url: URL) {
    handleIncomingURL(url, source: .deepLink)
}
```
This is the right seam for manifest-first deep-link approval. Keep it activation-only, not bridge-driven.

**Manifest route resolution and denial pattern**  
Source: `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift:305-315`, `:368-377`, `:465-487`
```swift
guard let route = route(for: request, manifest: manifest) else {
    return .denied(
        denial(
            reason: .inactiveRoute,
            routeID: request.routeID,
            manifest: manifest,
            message: "This route is not active in the bundled manifest.",
            hint: "Retry after shipping an updated shell manifest."
        )
    )
}

private func denial(..., actions: [RouteUnavailableAction] = [.retry]) -> RouteDenialPresentation {
    ...
    if ... let fallbackURL = fallbackURL(manifest: manifest) {
        recovery.append(.safeFallback(fallbackURL))
    }
}
```
Add the new external-entry denial alongside this existing presentation builder.

**Current route match seam**  
Source: `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift:25-40`, `:157-185`
The Swift tests already rely on manifest path matching, including `"/native/claims/:id/capture"`. Phase 16 deep-link approval should reuse this surface and add approval metadata checks before allowing mount.

### iOS bounded bridge handler pattern

**Expected files:** `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`

**Best analog:** `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift`

**Command enum and capability identity pattern**  
Source: `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift:8-27`, `:171-173`
```swift
enum BridgeCommand: String, CaseIterable {
    case appInfoGet = "app.info.get"
    case hapticsImpact = "haptics.impact"
    case shareInvoke = "share.invoke"
    case filesPick = "files.pick"
    ...
    var capability: String { rawValue }
}

guard let command = BridgeCommand(rawValue: request.command), request.capability == command.capability else {
    replySink(deny(request, reason: "undeclared_capability", ...))
    return
}
```
Add `permissions.status` here if the native shell handles it through the existing bounded bridge.

**Per-command handler pattern**  
Source: `examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift:187-239`
```swift
case .appInfoGet:
    guard let requiredCapabilityVersion = session.capabilities[command.capability],
          request.capabilities[command.capability] == requiredCapabilityVersion else {
        replySink(deny(request, reason: "unavailable_capability", ...))
        return
    }
    replySink(ok(request, payload: appInfoProvider()))
```
`permissions.status` should follow this exact command branch structure: version gate, invoke native provider, return normalized payload.

### Android shell activation and deep-link denial

**Expected files:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt`

**Best analog:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt`

**Intent normalization pattern**  
Source: `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt:53-87`, `:409-420`
```kotlin
fun forIncomingUrl(url: String, source: ActivationSource, baseline: ActivationRequest): ActivationRequest {
    return ActivationRequest(
        routeId = null,
        url = url,
        source = source,
        origin = originFromUrl(url) ?: baseline.origin,
        ...
    )
}

private fun normalizeIntent(intent: Intent?, baseline: ActivationRequest, fallbackSource: ActivationSource): ActivationRequest {
    val url = intent?.dataString
    val source = when {
        intent?.action == Intent.ACTION_VIEW && url != null -> ActivationSource.DEEP_LINK
        else -> fallbackSource
    }
```
This is the Android deep-link seam to extend with explicit route-entry approval.

**Denied presentation builder pattern**  
Source: `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt:286-296`, `:469-493`
```kotlin
val route = routeForRequest(manifest, request)
    ?: return ShellPresentation.Denied(
        denial(
            manifest = manifest,
            reason = RouteDenialReason.INACTIVE_ROUTE,
            routeId = request.routeId,
            message = "This route is not active in the bundled manifest.",
            hint = "Retry after shipping an updated shell manifest."
        )
    )

private fun denial(...): RouteDenialPresentation {
    val safeFallback = fallbackUrl(manifest)
    ...
}
```
Mirror the new blocked-external-entry denial here so both shells stay vocabulary-compatible.

### Android bounded bridge handler pattern

**Expected files:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`

**Best analog:** `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`

**Registration + evaluation pattern**  
Source: `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt:9-30`, `:84-118`
```kotlin
enum class BridgeCommand(val wireValue: String) {
    APP_INFO_GET("app.info.get"),
    HAPTICS_IMPACT("haptics.impact"),
    SHARE_INVOKE("share.invoke"),
    FILES_PICK("files.pick"),
    ...
}

private fun evaluate(request: BridgeRequestEnvelope): String {
    if (request.protocol != PROTOCOL || request.version != session.bridgeProtocolVersion || request.nativeRuntimeVersion != session.nativeRuntimeVersion) {
        return deny(request, "compatibility_mismatch", ...)
    }
    ...
}
```
Use this as the Android analog for `permissions.status`.

**Native command branch pattern**  
Source: `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt:121-159`
```kotlin
BridgeCommand.APP_INFO_GET -> {
    val requiredCapabilityVersion = session.capabilities[command.capability]
    if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
        deny(request, "unavailable_capability", ...)
    } else {
        ok(request, appInfoProvider())
    }
}
```
Permissions-status querying should be another low-frequency branch with a small payload map, not a new asynchronous bus.

### Proof tests to copy

**Expected files:** `test/crosswake/shell/activation_test.exs`, `test/crosswake/bridge/registry_test.exs`, `test/crosswake/doctor/doctor_test.exs`, `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift`, `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/ActivationCoordinatorTest.kt`

**Best analogs:** exact file matches above

**Elixir activation proof pattern**  
Source: `test/crosswake/shell/activation_test.exs:72-112`, `:114-180`
```elixir
assert %Decision{status: :allow, route_id: "dashboard", denial: nil} = allow_decision
assert %Decision{status: :deny, route_id: "missing", denial: %Denial{reason: :inactive_route}} = deny_decision

assert Enum.map(denials, & &1.reason) == [
  :compatibility_mismatch,
  :undeclared_capability,
  :unavailable_capability,
  :origin_denied,
  :inactive_route,
  :pack_incompatible
]
```
Add a proof for the new deep-link denial reason here.

**Registry proof pattern**  
Source: `test/crosswake/bridge/registry_test.exs:8-18`, `:32-40`, `:53-77`
```elixir
assert Registry.allowed_commands() == [...]
assert {:ok, entry} = Registry.lookup(manifest, "dashboard", "haptics.impact")
assert {:error, :undeclared_capability} = Registry.lookup(manifest, "dashboard", "files.pick")
```
Copy this for `permissions.status`: command allowlist, manifest version lookup, and fail-closed undeclared cases.

**Doctor proof pattern**  
Source: `test/crosswake/doctor/doctor_test.exs:71-121`
```elixir
assert report.bridge.allowed_commands == @allowed_bridge_commands
assert report.bridge.denial_reasons |> Enum.sort() == Enum.sort([...])
assert Enum.any?(report.findings, &(&1.check == "shell_activation" and &1.severity == :advisory))
assert Enum.any?(report.findings, &(&1.check == "bridge_posture" and &1.severity == :warning))
```
Use this to lock support truth for deep-link activation posture and `permissions.status` bridge posture.

**Native shell proof patterns**  
Source: `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift:25-57`, `examples/android_shell_host/app/src/test/java/dev/crosswake/shell/ActivationCoordinatorTest.kt:45-62`
```swift
coordinator.openURL(URL(string: "https://example.com/missing")!)
XCTAssertEqual(denial.reason, RouteDenialReason.inactiveRoute)
```

```kotlin
val presentation = coordinator.activate(
    ActivationRequest.forIncomingUrl("https://example.crosswake.invalid/missing", ActivationSource.DEEP_LINK, baselineRequest())
)
assertEquals(RouteDenialReason.INACTIVE_ROUTE, (presentation as ShellPresentation.Denied).denial.reason)
```
Phase 16 should add the complementary proof for “route exists but is not approved for external entry”.

## Shared Patterns

### Route-policy metadata additions must be explicit, scoped, and mergeable
**Sources:** `lib/crosswake/policy/defaults.ex:6-14`, `lib/crosswake/router/scope_defaults.ex:19-25`, `:64-72`

Apply to all deep-link route-entry metadata. Use `crosswake_defaults` for scope defaults and per-route `crosswake:` overrides; do not infer external-entry approval from path presence alone.

### Manifest truth remains the single source for shell activation
**Sources:** `lib/crosswake/manifest/builder.ex:63-83`, `lib/crosswake/shell/activation.ex:79-91`, `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift:305-315`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt:286-296`

Both shells already resolve activations from manifest-backed route entries. Phase 16 should extend that manifest truth with entry approval, not add parallel per-platform allowlists.

### Denial vocabulary must stay typed and shared
**Sources:** `lib/crosswake/compatibility/compatibility.ex:103-145`, `test/crosswake/shell/activation_test.exs:114-180`, `examples/ios_shell_host/CrosswakeShell/ActivationCoordinator.swift:17-24`, `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt:25-32`

Any new deep-link approval denial reason must be added consistently across Elixir, iOS, Android, and proof tests.

### Bounded bridge commands are registry-backed and route-allowlisted
**Sources:** `lib/crosswake/bridge/registry.ex:11-16`, `:56-98`; `lib/crosswake/compatibility/compatibility.ex:445-540`

`permissions.status` should be another bounded, semantic command. Do not special-case permission checks outside the registry or compatibility gates.

### Support truth flows from capability metadata into support matrix and doctor
**Sources:** `lib/crosswake/manifest/builder.ex:138-200`, `lib/crosswake/support_matrix/support_matrix.ex:327-343`, `lib/crosswake/doctor/doctor.ex:490-617`

If Phase 16 changes support class, prerequisites, denial, or rebuild posture for `deep_link` or `permissions.status`, update the capability catalog first so support matrix and doctor inherit the same truth.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/crosswake/bridge/commands/permissions_status.ex` | model | request-response | No existing bridge command currently returns a normalized enum plus optional platform detail; copy the tiny payload-module pattern from `app_info` and `share`, but the reply shape is new. |
| `examples/ios_shell_host/CrosswakeShell/PermissionStatusProvider.swift` | service | request-response | No dedicated iOS permission-query helper exists yet; implement behind `BridgeChannel` using the same injected-handler pattern used for `appInfoProvider`, `hapticsHandler`, and `filesPickHandler`. |
| `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/PermissionStatusProvider.kt` | service | request-response | No dedicated Android permission-query helper exists yet; implement behind `BridgeChannel` using the existing provider/handler branch pattern. |

## Metadata

**Analog search scope:** `lib/crosswake/`, `test/crosswake/`, `examples/ios_shell_host/`, `examples/android_shell_host/`, `examples/phoenix_host/`
**Files scanned:** 25
**Pattern extraction date:** 2026-05-20
