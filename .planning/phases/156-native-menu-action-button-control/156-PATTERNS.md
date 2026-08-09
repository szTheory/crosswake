# Phase 156: Native Menu & Action-Button Control - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 21 new/modified file targets inferred from CONTEXT.md and RESEARCH.md
**Analogs found:** 21 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/policy/schema.ex` | config/model | request-response | `commerce` / `notification_open` schema entries in same file | exact |
| `lib/crosswake/policy/route.ex` | model | request-response | `commerce`, `notification_open`, `transfers` fields in same file | exact |
| `lib/crosswake/policy/validator.ex` | service/validator | request-response | `validate_commerce/2`, `validate_unique_list/4` in same file | exact |
| `lib/crosswake/manifest/types.ex` | model/serializer | transform | `Capability`, `RouteEntry`, `new_route_commerce/1` in same file | exact |
| `lib/crosswake/manifest/builder.ex` | service | transform | `capability_catalog/0`, `route_entries/3`, `route_commerce/1` in same file | exact |
| `lib/crosswake/bridge/contract.ex` | model/contract | request-response | current `Request`, `Reply`, `@commands`, `to_map/1` | exact |
| `lib/crosswake/bridge/registry.ex` | service | request-response | family-to-command map and `capability_entry/4` | exact |
| `lib/crosswake/bridge/commands/action_menu.ex` | utility/validator | request-response | `Crosswake.Transfer.Contracts`-style private validation plus `Registry.file_picker_entry/3` payload validation | role-match |
| `lib/crosswake/bridge.ex` | service | event-driven request-response | `push/3`, `resolve/2`, in-flight and fact handling in same file | exact |
| `lib/crosswake/shell/denial.ex` | model | request-response | existing `:unavailable_capability`, `:undeclared_capability`, `:shell_unreachable` denial model | exact |
| `priv/static/crosswake.esm.js` | hook/transport | event-driven request-response | `BridgeSession.dispatch/1`, `bridgeFacts/1`, `reportUnreachable/2` | exact |
| `test/js/crosswake_esm_test.mjs` | test | event-driven request-response | transport/fact/ack tests in same file | exact |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | native service | request-response | `BridgeCommand`, `BridgeRequestEnvelope`, haptics/share/files dispatch | exact |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActionMenuPresenter.swift` | native service | event-driven request-response | `FilesPickHandler` deferred callback and delegate/presenter seams in `BridgeChannel.swift` | role-match |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` | test | batch/vector | existing committed vector harness | exact |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt` | native service | request-response | `BridgeCommand`, `BridgeRequestEnvelope`, haptics/share/files dispatch | exact |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActionMenuPresenter.kt` | native service | event-driven request-response | `FilesPickDelegate` deferred result path and BridgeChannel delegate checks | role-match |
| `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` | test | batch/vector | existing committed vector harness | exact |
| `test/fixtures/bridge_contract_vectors.json` | fixture/config | batch/vector | existing canonical vector corpus | exact |
| `packages/*/bridge_contract_vectors.json` mirrors | fixture/config | batch/vector | existing generated native mirrors | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` | component/controller | event-driven request-response | current fallback + haptics seam integration | exact |

## Pattern Assignments

### Route Policy And Manifest Files

**Apply to:** `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/policy/validator.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/manifest/builder.ex`

**Analogs:** structured policy siblings `commerce`, `notification_open`, `transfers`; capability catalog entries `haptics`, `share`, `file_picker`.

**Schema pattern** (`lib/crosswake/policy/schema.ex` lines 85-93, 137-140):
```elixir
capabilities: [
  type: {:list, {:custom, __MODULE__, :validate_identifier, []}},
  default: [],
  type_spec: quote(do: [String.t()])
],
commerce: [
  type: {:custom, __MODULE__, :validate_commerce_declaration, []},
  type_spec: quote(do: commerce_declaration() | nil)
],
notification_open: [
  type: {:custom, __MODULE__, :validate_notification_open, []},
  type_spec: quote(do: notification_open_declaration() | nil)
]
```

**Route struct pattern** (`lib/crosswake/policy/route.ex` lines 26-47, 71-87):
```elixir
@enforce_keys [:id, :runtime]
defstruct [
  :id,
  :runtime,
  :commerce,
  :notification_open,
  capabilities: [],
  transfers: []
]

def new(options) when is_list(options) do
  options
  |> merged_options()
  |> Schema.validate()
  |> case do
    {:ok, validated} ->
      with {:ok, validated} <- validate_commerce_declaration(validated),
           {:ok, validated} <- validate_transfer_declarations(validated) do
        {:ok, struct!(__MODULE__, validated)}
      end
  end
end
```

**Semantic validation pattern** (`lib/crosswake/policy/validator.ex` lines 37-49, 116-131, 190-202):
```elixir
defp route_errors(route) do
  []
  |> validate_capabilities(route)
  |> validate_commerce(route)
  |> validate_unique_list(route, :capabilities, route.capabilities)
  |> validate_unique_transfer_ids(route)
end

defp validate_capabilities(errors, %Route{capabilities: capabilities}) do
  Enum.reduce(capabilities, errors, fn capability, acc ->
    if MapSet.member?(@known_capabilities, capability), do: acc, else: [%{key: :capabilities} | acc]
  end)
end
```

**Manifest route-entry pattern** (`lib/crosswake/manifest/builder.ex` lines 117-146):
```elixir
Types.new_route_entry(
  id: route.id,
  path: path,
  runtime: route.runtime,
  offline: route.offline,
  commerce: route_commerce(route),
  capabilities: route.capabilities,
  transfers: transfer_seams(route.transfers),
  notification_open: route.notification_open
)
```

**Capability catalog pattern** (`lib/crosswake/manifest/builder.ex` lines 280-307, 347-364):
```elixir
[
  id: "haptics",
  family: "haptics",
  owner: :bounded_bridge,
  package_class: :core,
  proof_class: :merge_blocking,
  rebuild: :none,
  interaction: :fire_and_forget,
  prerequisites: ["declared route capability", "bounded bridge support"],
  denial: "undeclared_capability",
  fallback: "Phoenix route continues without native confirmation feedback",
  guide: "guides/bridge.md#bounded-bridge"
]
```

For `action_menu`, copy this catalog shape but set `interaction: :user_answer`, `rebuild: :native_required`, `proof_class: :merge_blocking`, `owner: :bounded_bridge`, and `package_class: :core`.

### Bridge Contract, Registry, And Runtime Validation

**Apply to:** `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/bridge/commands/action_menu.ex`, `lib/crosswake/bridge.ex`, `lib/crosswake/shell/denial.ex`

**Analog:** Phase 154 control seam plus current bounded commands.

**Closed command vocabulary pattern** (`lib/crosswake/bridge/contract.ex` lines 9-22, 102-112):
```elixir
@protocol "crosswake.bridge"
@version "1.1.0"
@commands ~w(
  app.info.get
  haptics.impact
  share.invoke
  files.pick
)

def version, do: @version
def commands, do: @commands
def command_supported?(command), do: command in @commands
```

Add `action_menu.present` here and bump `@version` to `1.2.0`. Keep the vocabulary static.

**Request/reply serialization pattern** (`lib/crosswake/bridge/contract.ex` lines 114-130, 148-158, 172-188):
```elixir
def new_request(attrs) when is_list(attrs) do
  struct!(Request, %{
    command: Keyword.fetch!(attrs, :command),
    capability: Keyword.fetch!(attrs, :capability),
    payload: Keyword.get(attrs, :payload, %{})
  })
end

def ok_reply(%Request{} = request, payload \\ %{}) when is_map(payload) do
  new_reply(command: request.command, route_id: request.route_id, status: :ok, payload: payload)
end

def to_map(%Request{} = request) do
  %{"payload" => Types.to_map(request.payload)}
end
```

**Family-to-command mapping pattern** (`lib/crosswake/bridge/registry.ex` lines 12-19, 68-85, 124-140):
```elixir
@capability_commands %{
  "haptics.impact" => "haptics",
  "share.invoke" => "share"
}

def capability_command(capability_family) when is_binary(capability_family) do
  Enum.find_value(@capability_commands, fn {command, capability} ->
    if capability == capability_family, do: command
  end)
end

defp capability_entry(manifest, route, command, capability_id) do
  with %Capability{} = capability <- lookup_capability(manifest, capability_id),
       true <- capability_declared_on_route?(route, capability) do
    {:ok, %Entry{command: command, capability: capability.family, version: capability.version}}
  end
end
```

Add `"action_menu.present" => "action_menu"` and keep route authorization manifest-backed.

**Public push and exactly-once pattern** (`lib/crosswake/bridge.ex` lines 224-249, 303-318, 324-369):
```elixir
def push(%Phoenix.LiveView.Socket{} = socket, capability_family, opts \\ []) do
  state = fetch_state!(socket)

  case Registry.capability_command(capability_family) do
    nil -> raise_unknown_capability_family!(socket, capability_family)
    command ->
      case Registry.lookup(state.manifest, state.route_id, command) do
        {:ok, entry} -> dispatch(socket, state, entry, command, capability_family, opts)
        {:error, :undeclared_capability} -> raise_undeclared_capability!(state, socket, capability_family)
      end
  end
end

def resolve(%Phoenix.LiveView.Socket{} = socket, ref) do
  case maybe_fetch_state(socket) do
    nil -> socket
    state -> # compare/delete by ref
  end
end
```

Add `anchor_id:` handling to `dispatch/6` as metadata for `action_menu`, without adding a second public dispatcher.

**Failure fact to denial pattern** (`lib/crosswake/bridge.ex` lines 385-400, 417-429, 449-460):
```elixir
defp handle_bridge_event(@unreachable_event, payload, socket) do
  moment = normalize_failing_moment(Map.get(payload, "moment"))

  {:halt,
   resolve_and_deliver(socket, correlation_id_from(payload), fn ->
     %Reply{
       status: :deny,
       denial: Denial.new(reason: :shell_unreachable, details: %{failing_moment: moment})
     }
   end)}
end
```

For stale `action_menu` binaries, add a distinct hook fact event that Elixir converts to `Denial.new(reason: :unavailable_capability, details: %{failing_moment: :native_capability_unavailable})`. Do not relabel arbitrary native enum misses.

**Denial vocabulary pattern** (`lib/crosswake/shell/denial.ex` lines 14-33, 84-99, 102-114):
```elixir
@reasons [
  :undeclared_capability,
  :unavailable_capability,
  :shell_unreachable
]

def new(attrs) when is_list(attrs) do
  struct!(__MODULE__, %{
    reason: Keyword.fetch!(attrs, :reason),
    code: Keyword.get(attrs, :code, Atom.to_string(reason)),
    message: Keyword.fetch!(attrs, :message),
    details: details
  })
end
```

### JavaScript Hook, Anchor, Preflight, And Cancellation

**Apply to:** `priv/static/crosswake.esm.js`, `test/js/crosswake_esm_test.mjs`

**Analog:** existing hook transport/fact ownership and Node tests.

**Fact and transport split pattern** (`priv/static/crosswake.esm.js` lines 73-105):
```javascript
export function findTransport(scope) {
  const root = scope || globalThis;
  const handler = root.webkit?.messageHandlers?.crosswakeBridge;
  if (handler && typeof handler.postMessage === "function") return handler;

  const injected = root.crosswakeBridge;
  if (injected && typeof injected.postMessage === "function") return injected;

  return null;
}

export function bridgeFacts(scope) {
  const injected = (scope || globalThis).crosswakeBridge;
  return {
    capabilities: injected?.capabilities || {},
    threadId: typeof injected?.threadId === "string" ? injected.threadId : null
  };
}
```

**Dispatch/fact pattern** (`priv/static/crosswake.esm.js` lines 187-209, 253-257):
```javascript
dispatch(payload) {
  const correlationId = correlationIdOf(payload);
  this.pushEvent(ACK_EVENT, { correlation_id: correlationId });

  const transport = findTransport(this.scope);
  if (!transport) {
    this.reportUnreachable(correlationId, MOMENT_NO_TRANSPORT);
    return;
  }

  transport.postMessage(JSON.stringify(payload));
  this.armReplyTimer(correlationId, replyTimeoutFor(payload, this.element));
}

reportUnreachable(correlationId, moment) {
  this.clearInFlight(correlationId);
  this.pushEvent(UNREACHABLE_EVENT, { correlation_id: correlationId, moment: moment });
}
```

Add anchor resolution before native post for `action_menu.present`: `document.getElementById(anchor_id)`, nonzero visible rect, viewport metadata, and fail-closed fact when invalid. Add stale-binary preflight using `bridgeFacts(scope).capabilities.action_menu`.

**Hook test pattern** (`test/js/crosswake_esm_test.mjs` lines 35-52, 139-162, 196-204):
```javascript
function envelope(overrides) {
  return Object.assign({
    command: "haptics.impact",
    capability: "haptics",
    correlation_id: "cwbridge-e1-abc",
    payload: { style: "light" }
  }, overrides || {});
}

test("with no transport at all the hook posts nothing and reports the no_transport moment", () => {
  const trace = newTrace();
  const session = newSession({}, trace);
  session.dispatch(envelope());
  assert.deepEqual(pushedEvents(trace), [ACK_EVENT, UNREACHABLE_EVENT]);
});
```

Add tests for valid anchor metadata, missing/zero/offscreen anchor denial fact, old-shell capability preflight, and cancellation clearing a pending native request.

### Native Swift Bridge And Presenter

**Apply to:** `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`, new private presenter source, Swift tests.

**Analog:** `BridgeCommand`, `BridgeRequestEnvelope`, haptics/share/files dispatch.

**Enum/envelope pattern** (`BridgeChannel.swift` lines 8-31, 43-56):
```swift
public enum BridgeCommand: String, CaseIterable {
    case hapticsImpact = "haptics.impact"
    case shareInvoke = "share.invoke"
    case filesPick = "files.pick"

    public var capability: String {
        switch self {
        case .filesPick: return "file_picker"
        default: return rawValue
        }
    }
}

public struct BridgeRequestEnvelope: Codable, Equatable {
    public let command: String
    public let capability: String
    public let payload: [String: String]
}
```

Add `.actionMenuPresent = "action_menu.present"` and map capability to `"action_menu"`. Widen payload/reply payload from `[String: String]` to a structured JSON value type before adding action-list vectors.

**Guard/dispatch pattern** (`BridgeChannel.swift` lines 180-208, 323-357):
```swift
guard let command = BridgeCommand(rawValue: request.command), request.capability == command.capability else {
    completion(deny(request, reason: "undeclared_capability", message: "...", hint: "..."))
    return
}

case .shareInvoke:
    guard capabilityAvailable(for: command, request: request) else {
        completion(unavailableCapability(request))
        return
    }
    guard let shareDelegate = config.shareDelegate else {
        completion(deny(request, reason: "undeclared_capability", message: "Share delegate is not configured.", hint: "Implement ShareDelegate."))
        return
    }
    shareDelegate.invoke(payload: request.payload)
    completion(ok(request, payload: [:]))
```

For `action_menu.present`, insert the same compatibility/capability guard first, then decode/validate the action model, call a presenter protocol, and reply exactly once with `%{"outcome": "selected", "action_id": id}` or `%{"outcome": "dismissed"}`.

**Reply helpers pattern** (`BridgeChannel.swift` lines 396-448):
```swift
private func capabilityAvailable(for command: BridgeCommand, request: BridgeRequestEnvelope) -> Bool {
    guard let requiredCapabilityVersion = session.capabilities[command.capability] else { return false }
    return SemVer.compatible(provides: request.capabilities[command.capability], demands: requiredCapabilityVersion)
}

private func ok(_ request: BridgeRequestEnvelope, payload: [String: String]) -> BridgeReplyEnvelope { ... }
private func deny(_ request: BridgeRequestEnvelope, reason: String, message: String, hint: String) -> BridgeReplyEnvelope { ... }
```

Keep native menu denials in the existing reply envelope shape.

### Native Android Bridge And Presenter

**Apply to:** `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt`, new private presenter source, Android tests.

**Analog:** `BridgeCommand`, `BridgeRequestEnvelope`, `evaluate`, delegate dispatch.

**Enum/envelope pattern** (`BridgeChannel.kt` lines 9-40, 354-380):
```kotlin
enum class BridgeCommand(val wireValue: String) {
    HAPTICS_IMPACT("haptics.impact"),
    SHARE_INVOKE("share.invoke"),
    FILES_PICK("files.pick");

    val capability: String
        get() = when (this) {
            FILES_PICK -> "file_picker"
            else -> wireValue
        }
}

data class BridgeRequestEnvelope(
    val command: String,
    val capability: String,
    val payload: Map<String, String>
)
```

Add `ACTION_MENU_PRESENT("action_menu.present")`, map to `"action_menu"`, and widen payload to structured JSON (`JsonElement` or equivalent) instead of string coercion.

**Dispatch pattern** (`BridgeChannel.kt` lines 115-125, 207-219):
```kotlin
val command = BridgeCommand.fromWireValue(request.command)
    ?: return deny(request, "undeclared_capability", "The bridge command is outside...", "Use ... only.")

if (request.capability != command.capability) {
    return deny(request, "undeclared_capability", "The bridge envelope capability does not match...", "Align...")
}

BridgeCommand.SHARE_INVOKE -> {
    if (!capabilityAvailable(command, request)) {
        deny(request, "unavailable_capability", "The requested capability is not available...", "Ship...")
    } else {
        config.shareDelegate?.invoke(request.payload)
        ok(request, emptyMap())
    }
}
```

For `action_menu.present`, keep `PopupMenu` behind a private presenter interface so JVM vectors can fake selection/dismissal without emulator evidence.

**Reply helpers pattern** (`BridgeChannel.kt` lines 308-350):
```kotlin
private fun capabilityAvailable(command: BridgeCommand, request: BridgeRequestEnvelope): Boolean {
    val required = session.capabilities[command.capability] ?: return false
    return SemVer.compatible(provides = request.capabilities[command.capability], demands = required)
}

private fun ok(request: BridgeRequestEnvelope, payload: Map<String, String>): String { ... }
private fun deny(request: BridgeRequestEnvelope, reason: String, message: String, hint: String): String { ... }
```

### Native Vector Harnesses

**Apply to:** `test/fixtures/bridge_contract_vectors.json`, native mirror fixtures, `BridgeConformanceTests.swift`, `BridgeConformanceTest.kt`

**Analog:** existing committed vector corpus and hostless test loops.

**Swift vector pattern** (`BridgeConformanceTests.swift` lines 6-15, 168-200, 211-245):
```swift
struct BridgeVectorsFile: Codable {
    let bridgeProtocolVersion: String
    let nativeRuntimeVersion: String
    let vectors: [BridgeVector]
}

func makeRequest(bridgeProtocolVersion: String, override requestOverride: RequestOverride) -> BridgeRequestEnvelope {
    return BridgeRequestEnvelope(
        protocolName: "crosswake.bridge",
        version: version,
        command: command,
        capability: capability,
        payload: [:]
    )
}

for vector in vectorsFile.vectors {
    let session = makeSession(bridgeProtocolVersion: bridgeVersion, override: vector.sessionOverride)
    let request = makeRequest(bridgeProtocolVersion: bridgeVersion, override: vector.requestOverride)
    channel.evaluate(request) { reply = $0 }
    XCTAssertEqual(reply?.status, vector.expectedOutcome)
}
```

**Android vector pattern** (`BridgeConformanceTest.kt` lines 14-20, 124-151, 156-227):
```kotlin
@Before
fun loadVectors() {
    val text = javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!
        .bufferedReader().readText()
    vectorsJson = JSONObject(text)
    bridgeVersion = vectorsJson.getString("bridge_protocol_version")
}

@Test
fun `all bridge contract vectors pass status and denial-reason assertions`() {
    val vectors = vectorsJson.getJSONArray("vectors")
    for (i in 0 until vectors.length()) {
        val vector = vectors.getJSONObject(i)
        val request = applyRequestOverride(baseRequest, requestOverride)
        val replyJson = JSONObject(channel.evaluateForTesting(request))
        assertEquals(expectedOutcome, replyJson.getString("status"))
    }
}
```

Extend the JSON schema only once in `test/fixtures/bridge_contract_vectors.json`, regenerate mirrors, and ensure both native harnesses exercise fake action-menu presenter selection/dismissal.

### Example LiveView And Generated Fallback

**Apply to:** `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`, generated fallback artifact, route-tour/evidence tests.

**Analog:** Phase 155 fallback-first example and Phase 154 haptics seam.

**Imports/assigns pattern** (`approval_live.ex` lines 1-14, 33-57):
```elixir
defmodule CrosswakeExample.SaaSPortal.ApprovalLive do
  use Phoenix.LiveView

  alias Crosswake.Bridge
  alias CrosswakeExampleWeb.CrosswakeFallbacks

  @bridge_route_id "saas-approval"

  def mount(_params, _session, socket) do
    socket
    |> assign(crosswake_manifest: Policy.manifest(), crosswake_route_id: @bridge_route_id)
    |> assign(menu_open: false, menu_actions: @native_controls_menu_actions)
    |> Bridge.attach()
  end
end
```

**Frozen runtime action projection pattern** (`approval_live.ex` lines 22-31):
```elixir
@native_controls_menu_actions [
  %{id: "flag", label: "Flag for review", destructive: false, icon: nil},
  %{id: nil, label: "Reassign job — needs a supervisor", destructive: false, icon: nil},
  %{id: "delete", label: "Delete job", destructive: true, icon: nil}
]
```

Reuse this shape exactly for the native action-menu payload. Validate labels, ids, destructive flags, and `icon: nil` before dispatch.

**Fallback event handling pattern** (`approval_live.ex` lines 140-185):
```elixir
def handle_event("open_action_menu", _params, socket) do
  {:noreply, assign(socket, menu_open: true)}
end

def handle_event("crosswake_fallback_answer", %{"id" => id}, socket) do
  case Enum.find(socket.assigns.menu_actions, &(&1.id == id)) do
    %{destructive: true} -> {:noreply, assign(socket, menu_open: false, destructive_confirm_open: true)}
    %{destructive: false} -> {:noreply, assign(socket, menu_open: false, confirm_demo_notice: "Flagged for review.")}
    nil -> {:noreply, assign(socket, menu_open: false)}
  end
end

def handle_event("crosswake_fallback_dismiss", _params, socket) do
  {:noreply, assign(socket, confirm_open: false, destructive_confirm_open: false, menu_open: false)}
end
```

Phase 156 should add the `Bridge.push(socket, "action_menu", ref: ..., payload: %{"actions" => actions}, anchor_id: ..., timeout: :infinity)` call to the open path while preserving the fallback assign.

**Fallback render pattern** (`approval_live.ex` lines 337-353):
```elixir
<button
  type="button"
  id="native-controls-menu-trigger"
  aria-expanded={@menu_open}
  aria-controls="native-controls-menu-demo"
  phx-click="open_action_menu"
>
  Job actions
</button>

<CrosswakeFallbacks.action_menu
  id="native-controls-menu-demo"
  trigger_id="native-controls-menu-trigger"
  open={@menu_open}
  actions={@menu_actions}
/>
```

Use the same trigger id for fallback `aria-controls`/focus return and `anchor_id:`.

**Generated action-menu contract pattern** (`priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex` lines 191-232):
```elixir
@doc """
An action menu — a centred modal listing allowlisted actions...

actions :: [%{id: String.t() | nil, label: String.t(), destructive: boolean(), icon: nil}]

A row whose `id` is `nil` renders disabled, with `label` carrying its own reason inline.
Selecting an enabled row emits `select-with-id`; dismissing emits `dismiss`.
A destructive row's click does not emit a mutation directly.
"""
```

Native presenters must preserve the same disabled/destructive/dismiss semantics, not invent a second menu projection.

## Shared Patterns

### Route Policy Is Authority

**Source:** `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, `lib/crosswake/policy/validator.ex`
**Apply to:** all route-policy, manifest, bridge registry, and runtime validator work.

Pattern: declare `action_menu:` as a sibling structured key, require `capabilities: ["action_menu"]`, and reject mismatches as authoring/runtime validation failures before native dispatch.

### Fallback-First Native Enhancement

**Source:** `approval_live.ex` lines 140-185 and 337-353; fallback template lines 191-232.
**Apply to:** example route and adopter guidance.

Pattern: render the host-owned fallback from assigns in the same round trip, then invoke native as enhancement. Denial leaves fallback usable; selection/dismissal closes fallback through existing LiveView handlers.

### Exactly-Once Reply Handling

**Source:** `lib/crosswake/bridge.ex` lines 92-113, 303-318, 499-520.
**Apply to:** native reply path, fallback `resolve/2`, cancellation, telemetry.

Pattern: both fallback and native compete for one `ref`/correlation. First terminal answer deletes the in-flight entry; late replies are dropped before adopter code and should emit bounded telemetry.

### Denials Are Constructed In Elixir

**Source:** `priv/static/crosswake.esm.js` lines 20-26, 253-257; `lib/crosswake/bridge.ex` lines 385-400; `lib/crosswake/shell/denial.ex` lines 84-114.
**Apply to:** no transport, invalid anchor, stale binary preflight, native denial replies.

Pattern: hook reports facts; Elixir constructs `Crosswake.Shell.Denial` and owns microcopy. Native may return protocol denials for requests it actually receives.

### Native Chrome Is Platform-Owned

**Source:** existing native delegate dispatch in `BridgeChannel.swift` and `BridgeChannel.kt`.
**Apply to:** new Swift/Android action-menu presenters.

Pattern: keep compatibility/origin/route/capability guards in `BridgeChannel`, put platform UI behind a bounded presenter/delegate, and test presenter models/callbacks hostlessly.

### Vector Proof Is Canonical

**Source:** `test/fixtures/bridge_contract_vectors.json`, Swift and Kotlin bridge conformance tests.
**Apply to:** PROOF-03.

Pattern: add action-menu vectors to the canonical fixture, regenerate platform mirrors, and have both native harnesses load the same file. Include selected, dismissed, disabled row, malformed payload, duplicate id, unknown id, missing capability, and route mismatch cases.

## No Analog Found

All inferred file targets have a close local analog. New native presenter files do not have a literal existing `ActionMenuPresenter`, but the role and data flow match the existing native delegate/deferred callback patterns in `BridgeChannel.swift` and `BridgeChannel.kt`.

## Metadata

**Analog search scope:** `lib/crosswake`, `priv/static`, `priv/templates`, `examples/phoenix_host`, `packages/crosswake-shell-core-ios`, `packages/crosswake-shell-core-android`, `test`
**Files scanned:** targeted scan over 21 phase files plus grep across bridge/policy/native/proof surfaces
**Pattern extraction date:** 2026-07-31
