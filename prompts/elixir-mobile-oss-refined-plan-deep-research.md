Keelway internals investigation memo

My refinement after digging deeper: Keelway should not be a Hotwire Native clone. It should be a Phoenix-native mobile shell + bridge toolkit that borrows Hotwire Native’s best internals, but reshapes them around Phoenix, LiveView, HEEx, Plug, Telemetry, ExUnit, and host-owned generated code.

The strongest architecture is a three-plane system:

1. Route/navigation plane — server-published path manifest tells native shells how to present routes: push, modal, replace, native screen, cacheable, offline-safe, billing-sensitive, etc.
2. Component/capability plane — web markup can progressively enhance into native actions/components: share, haptics, menu, sheet, camera, permissions, review prompt, audio, billing.
3. Server event/command plane — LiveViews/controllers can issue typed native commands and receive typed native events/acks with correlation IDs, telemetry, and fallbacks.

That differs from Hotwire Native because Phoenix/LiveView gives us a better server event model than Rails/Turbo alone. LiveView already supports pushing events from client to server and server to client through JS interop hooks; Keelway should use that instead of forcing every native interaction to be represented as a DOM controller. Phoenix LiveView’s JS interop supports pushEvent from hooks and push_event/3 from the server side, which gives Keelway a natural command/ack pathway.  ￼

The investigation below is intentionally written as a map of options, tradeoffs, and implementation shapes rather than a frozen spec.

⸻

1. What comparable systems teach us

1.1 Hotwire Native is the closest proven internal pattern

Hotwire Native’s strongest ideas are not “Rails-specific.” They are:

* A single native navigator coordinates visits.
* A shared WebView is reused across screens.
* Path configuration decides native presentation.
* Bridge Components connect HTML/JS to Swift/Kotlin components.
* Native screens can replace web screens for high-fidelity flows.

Hotwire Native’s iOS reference describes a Navigator that manages a UINavigationController stack and uses a single shared WKWebView instance, while the Android reference similarly describes a NavigatorHost/Navigator stack of HotwireFragment screens with a shared WebView. That shared-WebView model is important because it preserves session, page lifecycle, cookies, and perceived continuity.  ￼

Hotwire path configuration is also a major lesson. The docs show route rules with patterns, presentation properties, and local/remote configuration sources. Both iOS and Android docs recommend shipping a bundled local path configuration even when loading a remote config, so the app has navigation rules available offline and at first launch.  ￼

Keelway should copy the idea, not the exact API. Phoenix can do more than path config because it can publish route IDs, verified route metadata, bridge command allowlists, Telemetry labels, cache policies, and app-store-sensitive billing flags from a server-owned manifest.

1.2 Bridge Components are the best model for progressive native polish

Hotwire Native Bridge Components consist of three parts: HTML markup, a JavaScript/Stimulus controller, and a native Swift/Kotlin component. The docs show a button bridge component where JS sends a connect message with a title, native creates a native button, and a native reply triggers the web callback.  ￼

Joe Masilotti’s Bridge Components project is especially useful because it turns this pattern into a reusable component library. It includes components like alert, barcode scanner, biometrics lock, button, document scanner, form, haptic, location, menu, NFC, notification token, permissions, review prompt, search, share, theme, and toast.  ￼

The lesson: do not make app developers hand-roll native bridge plumbing for common mobile interactions. A premium v0.1/v0.2 Keelway should ship a small, boring, reliable core component set, then generate host-owned custom components for advanced use.

But Keelway should avoid requiring Stimulus. Phoenix projects do not universally use Stimulus, and LiveView already has hooks. So the web layer should be:

* a tiny @sztheory/keelway-bridge JS runtime,
* a LiveView hook adapter,
* optional Stimulus adapter,
* optional vanilla custom element/data-attribute adapter.

1.3 Turbo Native visit lifecycle is the right mental model for native screens

Turbo iOS exposes a visit proposal lifecycle: the session proposes a visit, the app chooses a view controller and action, and the shared WebView is attached to a Visitable screen. The same docs show intercepting a visit to show a native view controller instead of a web screen.  ￼

For Keelway, this maps cleanly to:

tap link / LiveView redirect
  -> native shell intercepts URL
  -> route manifest resolves URL
  -> presentation decision:
       web push
       web replace
       modal web
       native screen
       external browser
       blocked

The important design principle: the native shell, not the web page, owns navigation presentation. Phoenix can suggest via manifest, but native must retain final authority for safety and platform behavior.

1.4 Hotwire Native’s offline gap is the cautionary tale

Joe Masilotti’s writing is blunt: Hotwire Native did not support offline in the general sense, and HEY’s offline caching reportedly involved a large local proxy effort that was not abstracted. He points to Turbo/service-worker experimentation for offline behavior, but that is not the same as fully offline native app state.  ￼

So Keelway’s internal architecture must keep three things separate:

* web cache for read-only stale pages,
* native cache for known route snapshots/assets,
* sync engine for selected Ecto resources and queued mutations.

Do not let the core bridge imply that LiveView is offline-first.

1.5 LiveView Native is inspiring, but too risky as the foundation

The archived status changes the calculus. The main live_view_native repository is archived/read-only as of February 10, 2026, while related projects such as SwiftUI/Jetpack clients still exist or moved repositories.  ￼

LiveView Native’s conceptual lesson is still valuable: server-driven UI can be excellent when the renderer is designed for it. But Keelway should not depend on LiveView internals or try to compile HEEx into SwiftUI/Compose. The safer route is:

* treat LiveView as HTML/web transport,
* use native shell for presentation,
* use bridge protocol for native capabilities,
* leave true native rendering as optional research.

1.6 Capacitor’s lesson: native capability plugins need permission discipline

Capacitor’s plugin model is relevant because it bridges web JS to native Swift/Kotlin/Java/Objective-C plugins. Its docs explicitly frame plugins as native APIs exposed to web code, and its permission docs recommend checking permissions and showing app-specific context before requesting them.  ￼

Keelway should copy:

* capability registry,
* permission state checks,
* explicit permission request flows,
* per-feature native adapters.

Keelway should not copy:

* JS-toolchain-first orientation,
* large plugin sprawl,
* treating Phoenix as just a static web app inside a wrapper.

1.7 Tauri’s capabilities model is a strong security inspiration

Tauri’s permission/capability system is one of the best design inspirations for Keelway. Tauri capabilities define which frontend windows/webviews can access which commands, permissions, and scopes; if a webview does not match a capability, it has no IPC access.  ￼

Keelway should have a similar concept:

allow "/invoices/:id",
  commands: ["share.open", "document.preview"],
  capabilities: [:share, :document_preview],
  cache: :stale_while_revalidate
deny "/admin/*",
  commands: :all,
  cache: :never

This is more Phoenix-native than a global “all pages can call native commands” bridge.

1.8 React Native / Expo teach us to generate typed native boundaries

React Native’s new architecture uses specs and Codegen to generate platform-specific interfaces for native modules, and Expo Modules API aims to make Swift/Kotlin native modules more consistent with less boilerplate.  ￼

Keelway should copy the typed boundary discipline, not the frontend architecture:

* JSON Schema for bridge messages.
* Generated Swift/Kotlin decoders.
* Shared fixtures across Elixir/Swift/Kotlin/JS.
* Versioned capabilities.
* Contract tests as the source of truth.

1.9 Flutter platform channels teach us that cross-boundary calls are fine if typed and bounded

Flutter’s platform channels are the official mechanism for Dart-to-native communication. Flutter’s own performance investigation found that codec encode/decode dominated the cost more than the message copy itself, which reinforces that bridge payloads should be small, typed, and not chatty.  ￼

Keelway should avoid using the bridge for high-frequency UI updates. Do not stream every animation frame, audio progress tick, or list scroll event through Phoenix. Native should own high-frequency UI and audio loops.

1.10 Crux is worth studying, but probably not adopting in v0.1

Crux shares app behavior across iOS, Android, and web through a reusable Rust core with thin native shells. Its docs emphasize native UI layers around a shared Rust app core, and its examples model events, effects, and tests around shared state.  ￼

Crux is active, with crux_core releases continuing into May 2026, but it is also evolving and conceptually centered on shared Rust behavior rather than a Phoenix/LiveView server-centric app.  ￼

Keelway should copy Crux’s:

* event/effect discipline,
* testable shared contracts,
* thin native shell philosophy.

Keelway should not introduce Rust into v0.1 unless a specific shared native sync core becomes necessary.

⸻

2. Core internal model: three planes, not one bridge

The single biggest internal design decision is to not overload one mechanism.

A naïve bridge would say: “native and web send JSON messages to each other.” That is too vague and becomes a security and DX mess.

Keelway should split bridge responsibilities into three planes.

2.1 Route/navigation plane

This is manifest-driven. It determines how URLs behave in the native app.

{
  "version": "2026-05-12.1",
  "bridge_version": "0.1",
  "base_url": "https://app.example.com",
  "routes": [
    {
      "id": "home",
      "pattern": "/",
      "presentation": "root",
      "cache": {"strategy": "network_first", "ttl_seconds": 86400},
      "commands": ["haptic.play", "toast.show"]
    },
    {
      "id": "invoice_show",
      "pattern": "/invoices/:id",
      "presentation": "push",
      "cache": {"strategy": "stale_while_revalidate", "ttl_seconds": 604800},
      "commands": ["share.open", "document.preview"]
    },
    {
      "id": "billing_paywall",
      "pattern": "/billing",
      "presentation": "native_screen",
      "native_screen": "billing.paywall",
      "commands": ["purchase.start", "purchase.restore"],
      "cache": {"strategy": "never"}
    },
    {
      "id": "admin",
      "pattern": "/admin/*",
      "presentation": "external_or_blocked",
      "commands": [],
      "cache": {"strategy": "never"}
    }
  ]
}

This plane should be loaded:

1. from a bundled native asset,
2. then from native cache,
3. then from the remote Phoenix endpoint.

That mirrors Hotwire Native’s local + cached + remote path configuration load order and preserves first-launch/offline behavior.  ￼

2.2 Component/capability plane

This is DOM/web-driven and progressive.

Example:

<.native_action
  name="share.open"
  payload={%{title: "Invoice ##{@invoice.number}", url: url(~p"/invoices/#{@invoice}")}}
  fallback_href={~p"/invoices/#{@invoice}/share"}
>
  Share invoice
</.native_action>

It renders usable HTML first:

<a
  href="/invoices/123/share"
  data-keelway-component="action"
  data-keelway-command="share.open"
  data-keelway-payload-id="payload-share-invoice-123"
>
  Share invoice
</a>
<script type="application/json" id="payload-share-invoice-123">
  {"title":"Invoice #123","url":"https://app.example.com/invoices/123"}
</script>

Then the JS runtime progressively enhances it if native capability exists. This is the Phoenix/HEEx version of Hotwire Bridge Components, whose documented shape is HTML + JS controller + native component.  ￼

2.3 Server event/command plane

This is LiveView-aware.

Example:

def handle_event("share", %{"id" => id}, socket) do
  invoice = Billing.get_invoice!(id)
  {:noreply,
   Keelway.LiveView.push_native(socket, "share.open", %{
     title: "Invoice #{invoice.number}",
     url: url(~p"/invoices/#{invoice}")
   })}
end

Flow:

LiveView server
  -> push_event("keelway:command", envelope)
  -> JS hook
  -> native bridge
  -> Swift/Kotlin component
  -> ack/error
  -> JS hook
  -> LiveView pushEvent("keelway:ack", ack)
  -> handle_native_ack / handle_native_event

This plane exists because Phoenix/LiveView has a server event model that Hotwire/Turbo does not have in the same way. It should be optional: plain Phoenix controllers and static pages still work through route/component planes.

⸻

3. Elixir package internals

3.1 Main package: keelway

Proposed module tree:

lib/
  keelway.ex
  keelway/application.ex
  keelway/config.ex
  keelway/platform.ex
  keelway/capability.ex
  keelway/plug/platform.ex
  keelway/plug/manifest.ex
  keelway/plug/security_headers.ex
  keelway/manifest.ex
  keelway/manifest/route.ex
  keelway/manifest/cache_policy.ex
  keelway/manifest/native_screen.ex
  keelway/manifest/signer.ex
  keelway/manifest/validator.ex
  keelway/route_policy.ex
  keelway/route_policy/rule.ex
  keelway/route_policy/compiler.ex
  keelway/route_policy/matcher.ex
  keelway/bridge.ex
  keelway/bridge/envelope.ex
  keelway/bridge/command.ex
  keelway/bridge/event.ex
  keelway/bridge/ack.ex
  keelway/bridge/error.ex
  keelway/bridge/registry.ex
  keelway/bridge/schema.ex
  keelway/bridge/security.ex
  keelway/bridge/controller.ex
  keelway/live_view.ex
  keelway/live_view/hook.ex
  keelway/live_view/native_action.ex
  keelway/component.ex
  keelway/components/native_action.ex
  keelway/components/native_button.ex
  keelway/components/offline_banner.ex
  keelway/components/capability_gate.ex
  keelway/telemetry.ex
  keelway/telemetry/metadata.ex
  keelway/test/fixture_case.ex
  keelway/test/bridge_replay.ex
  keelway/test/manifest_assertions.ex
  mix/tasks/keelway.install.ex
  mix/tasks/keelway.doctor.ex
  mix/tasks/keelway.gen.component.ex
  mix/tasks/keelway.gen.native_action.ex

Keelway.Config

Should normalize runtime config into a struct:

defmodule Keelway.Config do
  @enforce_keys [:otp_app, :endpoint, :app_name]
  defstruct [
    :otp_app,
    :endpoint,
    :repo,
    :app_name,
    :base_url,
    :telemetry_prefix,
    ios: [],
    android: [],
    bridge: [],
    cache: [],
    security: []
  ]
  def fetch!(otp_app \\ nil) do
    # resolve app env, endpoint URL, compatibility matrix, signing keys
  end
end

Design notes:

* Keep this runtime-oriented.
* Do not bake route policies at compile time unless explicitly requested.
* Config should have a Keelway.Config.inspectable/1 function that redacts secrets for mix keelway.doctor.

Keelway.Plug.Platform

This should parse platform context and assign a safe struct:

defmodule Keelway.Platform do
  @type os :: :ios | :android | :web | :desktop | :unknown
  @enforce_keys [:os, :native?]
  defstruct [
    :os,
    :app_version,
    :bridge_version,
    :runtime_id,
    :device_class,
    :capabilities,
    native?: false
  ]
end

Header convention:

Keelway-Platform: ios
Keelway-App-Version: 0.1.0
Keelway-Bridge-Version: 0.1
Keelway-Capabilities: share,haptics,push

Plug shape:

defmodule Keelway.Plug.Platform do
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    platform = Keelway.Platform.from_conn(conn)
    conn
    |> assign(:keelway_platform, platform)
    |> put_private(:keelway_native?, platform.native?)
  end
end

Why a Plug? Plug’s connection pipeline model is idiomatic Phoenix: composable transformations over Plug.Conn.  ￼

Anti-pattern: using User-Agent sniffing alone. Native apps should send explicit signed or at least structured headers. User-Agent can be an auxiliary signal, not the source of truth.

Keelway.RoutePolicy

This is one of the most important DX surfaces.

defmodule MyAppWeb.Mobile.RoutePolicy do
  use Keelway.RoutePolicy
  default presentation: :push,
          cache: :never,
          commands: []
  route "/", id: :home,
    presentation: :root,
    cache: {:network_first, ttl: {1, :day}},
    commands: ["haptic.play", "toast.show"]
  route "/invoices/:id", id: :invoice_show,
    presentation: :push,
    cache: {:stale_while_revalidate, ttl: {7, :days}},
    commands: ["share.open", "document.preview"]
  route "/billing", id: :billing_paywall,
    presentation: {:native_screen, "billing.paywall"},
    cache: :never,
    commands: ["purchase.start", "purchase.restore"]
  deny "/admin/*"
end

Internals:

RoutePolicy DSL
  -> compile rules into ordered matcher
  -> validate patterns
  -> generate manifest routes
  -> provide runtime match(url, platform)

Tradeoff: compile-time DSL vs runtime data.

* Compile-time DSL gives validation, docs, and generated manifests.
* Runtime data allows feature flags and dynamic rollout.
* Recommendation: support both. DSL generates default policy; host can provide a runtime callback for overrides.

@callback route_overrides(conn :: Plug.Conn.t(), route :: Keelway.Manifest.Route.t()) ::
            {:ok, Keelway.Manifest.Route.t()} | :deny

Keelway.Manifest

The manifest is the native shell’s contract.

Core APIs:

Keelway.Manifest.build(policy, opts)
Keelway.Manifest.sign(manifest, signer)
Keelway.Manifest.verify(manifest, key)
Keelway.Manifest.to_json(manifest)
Keelway.Manifest.route_for(manifest, url)

Controller:

defmodule Keelway.ManifestController do
  use Phoenix.Controller
  def show(conn, _params) do
    config = Keelway.Config.fetch!()
    platform = conn.assigns[:keelway_platform]
    manifest =
      config.route_policy
      |> Keelway.Manifest.build(platform: platform)
      |> Keelway.Manifest.sign(config)
    json(conn, manifest)
  end
end

Devil’s advocate: “Why not just let the server decide on every navigation request?”

Counter: native needs route decisions before the request completes, and it needs behavior offline. Hotwire’s docs explicitly recommend local bundled config and cache fallback for exactly this reason.  ￼

Keelway.Bridge

Bridge envelope:

defmodule Keelway.Bridge.Envelope do
  @enforce_keys [:protocol, :version, :id, :kind, :name, :payload]
  defstruct [
    :protocol,
    :version,
    :id,
    :kind,
    :name,
    :payload,
    :correlation_id,
    :idempotency_key,
    :route_id,
    :url,
    :origin,
    :platform,
    :capabilities,
    requires_ack?: false,
    timeout_ms: 5_000,
    metadata: %{}
  ]
  @type kind :: :command | :event | :ack | :error | :capabilities
end

Constructor:

defmodule Keelway.Bridge.Command do
  def new(name, payload, opts \\ []) when is_binary(name) and is_map(payload) do
    %Keelway.Bridge.Envelope{
      protocol: "keelway.bridge",
      version: Keyword.get(opts, :version, "0.1"),
      id: Keyword.get_lazy(opts, :id, &Keelway.ID.generate/0),
      kind: :command,
      name: name,
      payload: payload,
      correlation_id: Keyword.get(opts, :correlation_id),
      idempotency_key: Keyword.get(opts, :idempotency_key),
      route_id: Keyword.get(opts, :route_id),
      requires_ack?: Keyword.get(opts, :requires_ack?, true),
      timeout_ms: Keyword.get(opts, :timeout_ms, 5_000)
    }
  end
end

Registry:

defmodule Keelway.Bridge.Registry do
  def allowed?(%Envelope{name: name, route_id: route_id}, platform) do
    # look up manifest route command allowlist + capability negotiation
  end
end

Security checks:

validate protocol version
validate origin/base URL
validate route_id/url match
validate command is allowlisted for route
validate native capability exists
validate payload schema
validate idempotency if side-effecting
emit telemetry

Keelway.LiveView

Keep it small.

defmodule Keelway.LiveView do
  defmacro __using__(_opts) do
    quote do
      import Keelway.LiveView,
        only: [
          native?: 1,
          native_capability?: 2,
          push_native: 3,
          push_native: 4
        ]
      @before_compile Keelway.LiveView
    end
  end
  def native?(socket), do: socket.assigns[:keelway_platform].native? == true
  def native_capability?(socket, capability) do
    capability in Map.get(socket.assigns[:keelway_platform] || %{}, :capabilities, [])
  end
  def push_native(socket, name, payload, opts \\ []) do
    envelope = Keelway.Bridge.Command.new(name, payload, opts)
    Phoenix.LiveView.push_event(socket, "keelway:command", %{
      envelope: Keelway.Bridge.Envelope.to_map(envelope)
    })
  end
end

LiveView hooks can attach lifecycle behavior through on_mount and other lifecycle hooks; Keelway should use public LiveView lifecycle APIs rather than renderer internals.  ￼

Keelway.Component

Provide HEEx function components, not mandatory JS framework components.

defmodule Keelway.Component do
  use Phoenix.Component
  attr :name, :string, required: true
  attr :payload, :map, default: %{}
  attr :fallback_href, :string, default: nil
  attr :requires, :list, default: []
  slot :inner_block, required: true
  def native_action(assigns) do
    assigns =
      assign_new(assigns, :payload_id, fn ->
        "keelway-payload-" <> Keelway.ID.generate()
      end)
    ~H"""
    <a
      href={@fallback_href || "#"}
      data-keelway-component="native-action"
      data-keelway-command={@name}
      data-keelway-payload-id={@payload_id}
      data-keelway-requires={Enum.join(@requires, ",")}
    >
      {render_slot(@inner_block)}
    </a>
    <script id={@payload_id} type="application/json">
      {Phoenix.HTML.raw(Jason.encode!(@payload))}
    </script>
    """
  end
end

Security note: for sensitive payloads, prefer server-side command tokens over embedding JSON in HTML.

<.native_action
  name="document.preview"
  payload={%{token: @preview_token}}
>
  Preview PDF
</.native_action>

Keelway.Telemetry

Telemetry events should be emitted through wrappers:

defmodule Keelway.Telemetry do
  def command_start(envelope, metadata) do
    :telemetry.execute(
      [:keelway, :bridge, :command, :start],
      %{system_time: System.system_time()},
      safe_metadata(envelope, metadata)
    )
  end
end

Phoenix itself documents Telemetry as the mechanism for instrumentation, and Phoenix applications already use telemetry for endpoint/router/socket events.  ￼

⸻

4. Web bridge JS internals

Keelway should have a small JS package:

assets/
  js/
    keelway/
      index.ts
      bridge.ts
      live_view_hook.ts
      dom_components.ts
      capability_registry.ts
      errors.ts

No heavy framework dependency.

4.1 Runtime shape

export type BridgeEnvelope = {
  protocol: "keelway.bridge"
  version: string
  id: string
  kind: "command" | "event" | "ack" | "error" | "capabilities"
  name: string
  payload: Record<string, unknown>
  correlation_id?: string
  idempotency_key?: string
  route_id?: string
  url?: string
  origin?: string
  requires_ack?: boolean
  timeout_ms?: number
  metadata?: Record<string, unknown>
}
export interface NativeTransport {
  available(): boolean
  post(envelope: BridgeEnvelope): Promise<BridgeEnvelope>
}
export class KeelwayBridge {
  constructor(private transports: NativeTransport[]) {}
  async post(envelope: BridgeEnvelope): Promise<BridgeEnvelope> {
    const transport = this.transports.find(t => t.available())
    if (!transport) {
      return {
        protocol: "keelway.bridge",
        version: envelope.version,
        id: crypto.randomUUID(),
        kind: "error",
        name: "bridge.unavailable",
        correlation_id: envelope.id,
        payload: { reason: "no_native_transport" }
      }
    }
    return transport.post(envelope)
  }
}

4.2 iOS transport

export class IOSWebKitTransport implements NativeTransport {
  available(): boolean {
    return !!window.webkit?.messageHandlers?.Keelway
  }
  post(envelope: BridgeEnvelope): Promise<BridgeEnvelope> {
    window.webkit.messageHandlers.Keelway.postMessage(envelope)
    // Baseline WKScriptMessageHandler is fire-and-forget.
    // Ack can come back through injected JS callback.
    return waitForAck(envelope.id, envelope.timeout_ms ?? 5000)
  }
}

Apple’s WKScriptMessageHandler is the documented surface for receiving JavaScript messages from a web view, and WKWebView is the native WebKit view for embedding web content.  ￼

4.3 Android transport

export class AndroidWebMessageTransport implements NativeTransport {
  available(): boolean {
    return !!window.Keelway?.postMessage
  }
  post(envelope: BridgeEnvelope): Promise<BridgeEnvelope> {
    window.Keelway.postMessage(JSON.stringify(envelope))
    return waitForAck(envelope.id, envelope.timeout_ms ?? 5000)
  }
}

On Android, avoid broad addJavascriptInterface where possible. Android documents that addJavascriptInterface exposes the object to all frames, including iframes, and OWASP recommends origin-scoped messaging over legacy JS bridges where possible.  ￼

Use WebViewCompat.addWebMessageListener with explicit allowed origins where supported, registering before page load. Android’s docs show adding a web message listener with allowed origin rules, and OWASP warns against wildcard target origins.  ￼

4.4 LiveView hook

export const KeelwayLiveViewHook = {
  mounted() {
    this.bridge = window.Keelway.bridge
    this.handleEvent("keelway:command", async ({ envelope }) => {
      const ack = await this.bridge.post(envelope)
      this.pushEvent("keelway:ack", { envelope: ack })
    })
    window.Keelway.onNativeEvent = (envelope) => {
      this.pushEvent("keelway:event", { envelope })
    }
  },
  destroyed() {
    window.Keelway.onNativeEvent = undefined
  }
}

This lets Phoenix LiveView remain the server authority while native owns the actual native interaction.

⸻

5. iOS package internals: KeelwayKit

5.1 Proposed Swift package structure

native/ios/
  Package.swift
  Sources/
    KeelwayKit/
      Keelway.swift
      KeelwayConfiguration.swift
      Shell/
        KeelwayShellViewController.swift
        KeelwaySceneDelegateAdapter.swift
        KeelwayAppDelegateAdapter.swift
      Web/
        KeelwayWebViewFactory.swift
        KeelwayNavigationDelegate.swift
        KeelwayScriptBridge.swift
        KeelwayCookiePolicy.swift
        KeelwayUserAgent.swift
      Navigation/
        KeelwayNavigator.swift
        RouteDecision.swift
        RouteMatcher.swift
        PresentationCoordinator.swift
        NativeScreenFactory.swift
      Manifest/
        Manifest.swift
        ManifestLoader.swift
        ManifestCache.swift
        ManifestSignatureVerifier.swift
        ManifestRoute.swift
      Bridge/
        BridgeEnvelope.swift
        BridgeRouter.swift
        BridgeComponent.swift
        BridgeComponentRegistry.swift
        BridgeReply.swift
        BridgeError.swift
        AckStore.swift
      Components/
        Core/
          ShareComponent.swift
          HapticComponent.swift
          AlertComponent.swift
          MenuComponent.swift
          ToastComponent.swift
          PermissionComponent.swift
          ReviewPromptComponent.swift
      Capabilities/
        Capability.swift
        CapabilityRegistry.swift
        PermissionState.swift
      Offline/
        NativePageCache.swift
        ReachabilityMonitor.swift
        CachedPageViewController.swift
        OfflineBannerController.swift
      Billing/
        StoreKitPurchaseCoordinator.swift
        StoreKitReceiptVerifierClient.swift
        PurchaseStateMapper.swift
      Push/
        PushTokenCoordinator.swift
        DeepLinkRouter.swift
      Media/
        CameraCoordinator.swift
        FilePickerCoordinator.swift
        ShareSheetCoordinator.swift
      Audio/
        AudioSessionCoordinator.swift
        AudioPlaybackCoordinator.swift
        BackgroundAudioCoordinator.swift
      Telemetry/
        TelemetryEvent.swift
        TelemetrySink.swift
        OSLogTelemetrySink.swift
  Tests/
    KeelwayKitTests/

5.2 Configuration

public struct KeelwayConfiguration {
    public let baseURL: URL
    public let appName: String
    public let bundledManifestName: String
    public let remoteManifestURL: URL
    public let allowedOrigins: Set<String>
    public let appBoundDomains: Set<String>
    public let telemetrySink: TelemetrySink
    public let nativeScreens: NativeScreenFactory
    public let components: [BridgeComponent.Type]
}

Usage:

let config = KeelwayConfiguration(
    baseURL: URL(string: "https://app.example.com")!,
    appName: "My SaaS",
    bundledManifestName: "keelway_manifest",
    remoteManifestURL: URL(string: "https://app.example.com/keelway/manifest.json")!,
    allowedOrigins: ["https://app.example.com"],
    appBoundDomains: ["app.example.com"],
    telemetrySink: OSLogTelemetrySink(),
    nativeScreens: MyNativeScreens(),
    components: KeelwayCoreComponents.all + [InvoicePreviewComponent.self]
)
Keelway.start(configuration: config)

5.3 WebView factory

public final class KeelwayWebViewFactory {
    private let configuration: KeelwayConfiguration
    private let bridgeRouter: BridgeRouter
    public func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(bridgeRouter, name: "Keelway")
        config.userContentController = userContentController
        config.limitsNavigationsToAppBoundDomains = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = userAgent()
        return webView
    }
}

Apple documents limitsNavigationsToAppBoundDomains as a way to limit a web view’s navigation to app-bound domains, and WebKit’s App-Bound Domains article frames it as a privacy/security feature for in-app browsing.  ￼

Tradeoff: App-Bound Domains can be restrictive, especially for OAuth, support widgets, or external content. Keelway should ship it as the recommended default for first-party shells, with explicit docs for external auth/browser handoff.

5.4 Navigator

public final class KeelwayNavigator: NSObject {
    private let navigationController: UINavigationController
    private let webView: WKWebView
    private let manifest: Manifest
    private let presentationCoordinator: PresentationCoordinator
    public func open(_ url: URL) {
        let decision = manifest.decide(url)
        switch decision.presentation {
        case .root:
            showWeb(url, action: .replaceRoot)
        case .push:
            showWeb(url, action: .push)
        case .modal:
            showWeb(url, action: .modal)
        case .nativeScreen(let name):
            showNativeScreen(name, url: url)
        case .external:
            openExternal(url)
        case .blocked:
            showBlocked(url)
        }
    }
}

This copies the good part of Turbo/Hotwire Native: native owns the visit proposal and screen presentation. Turbo iOS’s docs show the app receiving proposed visits and choosing how to present them, including showing native view controllers.  ￼

5.5 One shared WebView or many?

Recommendation: one shared WebView per navigation context, not one global WebView for the whole app and not one per screen.

* Root navigation stack: one shared WebView.
* Modal navigation stack: separate WebView/session if needed.
* Auth/external browser: separate ASWebAuthenticationSession/SafariViewController where appropriate.
* Background/offline cache: no visible WebView required.

Turbo iOS’s advanced docs recommend separate sessions for separate navigation contexts, such as one session for modal flows and another for main navigation.  ￼

5.6 Bridge component shape

public protocol KeelwayBridgeComponent: AnyObject {
    static var name: String { get }
    init(context: BridgeContext)
    func onAttach()
    func onDetach()
    func receive(_ message: BridgeEnvelope) async -> BridgeReply
}

Example:

public final class ShareComponent: KeelwayBridgeComponent {
    public static let name = "share.open"
    private let context: BridgeContext
    public init(context: BridgeContext) {
        self.context = context
    }
    public func onAttach() {}
    public func onDetach() {}
    public func receive(_ message: BridgeEnvelope) async -> BridgeReply {
        guard let title = message.payload["title"] as? String,
              let urlString = message.payload["url"] as? String,
              let url = URL(string: urlString) else {
            return .error(message, code: "invalid_payload")
        }
        let activity = UIActivityViewController(
            activityItems: [title, url],
            applicationActivities: nil
        )
        await context.presenter.present(activity)
        return .ok(message, payload: ["completed": true])
    }
}

Joe’s Bridge Components include a production-oriented share component, haptic component, alert component, menu component, permissions component, review prompt component, and more; that library is the best concrete reference for Keelway’s iOS component ergonomics.  ￼

5.7 Bridge router

public final class BridgeRouter: NSObject, WKScriptMessageHandler {
    private let registry: BridgeComponentRegistry
    private let security: BridgeSecurityPolicy
    private let telemetry: TelemetrySink
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        Task {
            do {
                let envelope = try BridgeEnvelope.decode(message.body)
                try security.validate(envelope, frameInfo: message.frameInfo)
                telemetry.emit(.bridgeCommandStart(envelope))
                let reply = try await registry.dispatch(envelope)
                telemetry.emit(.bridgeCommandStop(envelope, reply))
                await sendReplyToWeb(reply)
            } catch {
                telemetry.emit(.bridgeCommandException(error))
                await sendErrorToWeb(error)
            }
        }
    }
}

Security considerations:

* Validate origin.
* Validate main-frame vs iframe.
* Validate command allowlist from manifest.
* Validate payload schema.
* Validate route URL matches active visible destination.
* Do not execute native commands for pages outside app origin.
* Do not expose bridge globally to arbitrary external domains.

5.8 iOS anti-patterns

Avoid:

* evaluating arbitrary JS strings as a bridge mechanism;
* one-off if command == "..." switch statements spread through view controllers;
* native actions callable from any page;
* silently falling back to web when a privileged command fails;
* creating new WKWebView for every route;
* storing billing receipts or auth tokens in bridge logs;
* assuming app-bound domains work with every OAuth/provider flow.

⸻

6. Android package internals

6.1 Proposed Kotlin package structure

native/android/keelway/
  src/main/java/io/sztheory/keelway/
    Keelway.kt
    KeelwayConfig.kt
    shell/
      KeelwayActivity.kt
      KeelwayFragment.kt
      KeelwayApplicationDelegate.kt
    web/
      KeelwayWebViewFactory.kt
      KeelwayWebChromeClient.kt
      KeelwayWebViewClient.kt
      KeelwayWebMessageBridge.kt
      KeelwayUserAgent.kt
      WebViewPolicy.kt
    navigation/
      KeelwayNavigator.kt
      NavigatorHost.kt
      RouteDecision.kt
      RouteMatcher.kt
      PresentationCoordinator.kt
      NativeScreenFactory.kt
    manifest/
      Manifest.kt
      ManifestLoader.kt
      ManifestCache.kt
      ManifestSignatureVerifier.kt
      ManifestRoute.kt
    bridge/
      BridgeEnvelope.kt
      BridgeRouter.kt
      BridgeComponent.kt
      BridgeComponentFactory.kt
      BridgeComponentRegistry.kt
      BridgeReply.kt
      BridgeError.kt
      AckStore.kt
    components/core/
      ShareComponent.kt
      HapticComponent.kt
      AlertComponent.kt
      MenuComponent.kt
      ToastComponent.kt
      PermissionComponent.kt
      ReviewPromptComponent.kt
    capability/
      Capability.kt
      CapabilityRegistry.kt
      PermissionState.kt
    offline/
      NativePageCache.kt
      NetworkMonitor.kt
      CachedPageFragment.kt
      OfflineBannerController.kt
    billing/
      PlayBillingCoordinator.kt
      PurchaseStateMapper.kt
    push/
      PushTokenCoordinator.kt
      DeepLinkRouter.kt
    media/
      CameraCoordinator.kt
      FilePickerCoordinator.kt
      ShareSheetCoordinator.kt
    audio/
      Media3PlaybackService.kt
      AudioSessionCoordinator.kt
      PlaybackCoordinator.kt
    telemetry/
      TelemetryEvent.kt
      TelemetrySink.kt
      LogcatTelemetrySink.kt
  src/test/java/...
  src/androidTest/java/...

6.2 Android configuration

data class KeelwayConfig(
    val baseUrl: HttpUrl,
    val appName: String,
    val bundledManifestAsset: String = "keelway_manifest.json",
    val remoteManifestUrl: HttpUrl,
    val allowedOrigins: Set<String>,
    val components: List<BridgeComponentFactory>,
    val nativeScreenFactory: NativeScreenFactory,
    val telemetrySink: TelemetrySink
)

Registration:

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Keelway.start(
            this,
            KeelwayConfig(
                baseUrl = "https://app.example.com".toHttpUrl(),
                remoteManifestUrl = "https://app.example.com/keelway/manifest.json".toHttpUrl(),
                allowedOrigins = setOf("https://app.example.com"),
                components = KeelwayCoreComponents.all + listOf(InvoicePreviewComponent.factory()),
                nativeScreenFactory = MyNativeScreens(),
                telemetrySink = LogcatTelemetrySink()
            )
        )
    }
}

Hotwire Native Android Bridge Components register native component factories in an application-level setup, and Joe’s Bridge Components Android install path follows a similar registration pattern.  ￼

6.3 WebView factory and bridge

class KeelwayWebViewFactory(
    private val context: Context,
    private val config: KeelwayConfig,
    private val bridgeRouter: BridgeRouter
) {
    fun create(): WebView {
        val webView = WebView(context)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        WebViewCompat.addWebMessageListener(
            webView,
            "Keelway",
            config.allowedOrigins.toSet(),
            bridgeRouter
        )
        webView.webViewClient = KeelwayWebViewClient(config)
        webView.webChromeClient = KeelwayWebChromeClient()
        return webView
    }
}

Use WebViewCompat.addWebMessageListener and explicit origins where available. Android’s docs show this style of native API bridge with a specific listener name and allowed origin rules, and Android’s WebView security guidance warns about broad native bridge exposure.  ￼

Fallback for older platforms:

if (!WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER)) {
    // Either:
    // 1. disable native bridge on unsupported WebView versions, or
    // 2. use addJavascriptInterface only for app-bound first-party pages
    //    with strict docs and a scary warning.
}

Recommendation: do not support insecure fallback by default. Let host apps opt into legacy fallback with a config flag and docs.

6.4 Navigator

class KeelwayNavigator(
    private val host: NavigatorHost,
    private val webView: WebView,
    private val manifest: Manifest,
    private val presenter: PresentationCoordinator
) {
    fun open(url: HttpUrl) {
        when (val decision = manifest.decide(url)) {
            is RouteDecision.Root -> presenter.replaceRoot(webView, url)
            is RouteDecision.Push -> presenter.push(webView, url)
            is RouteDecision.Modal -> presenter.presentModal(webView, url)
            is RouteDecision.NativeScreen -> presenter.showNativeScreen(decision.name, url)
            is RouteDecision.External -> presenter.openExternal(url)
            is RouteDecision.Blocked -> presenter.showBlocked(url)
        }
    }
}

Hotwire Native Android’s reference architecture is directly relevant: an Activity hosts one or more navigator hosts; each navigator manages a stack and a shared WebView.  ￼

6.5 Bridge component interface

interface BridgeComponent {
    val name: String
    fun onAttach(context: BridgeContext) {}
    fun onDetach() {}
    suspend fun onReceive(message: BridgeEnvelope): BridgeReply
}

Example:

class ShareComponent(
    private val context: BridgeContext
) : BridgeComponent {
    override val name = "share.open"
    override suspend fun onReceive(message: BridgeEnvelope): BridgeReply {
        val title = message.payload["title"] as? String
            ?: return BridgeReply.error(message, "invalid_payload")
        val url = message.payload["url"] as? String
            ?: return BridgeReply.error(message, "invalid_payload")
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, "$title\n$url")
        }
        context.activity.startActivity(Intent.createChooser(intent, title))
        return BridgeReply.ok(message, mapOf("completed" to true))
    }
}

Hotwire Native Android’s bridge component source shows useful lifecycle ideas: components receive messages, can reply, and lifecycle methods like start/stop are delegated from the bridge. The implementation also ties message dispatch to the active destination and resolved URL, which is a critical safety pattern Keelway should copy.  ￼

6.6 Android anti-patterns

Avoid:

* addJavascriptInterface for all pages;
* allowedOriginRules = setOf("*");
* bridge commands from iframes;
* bridge commands not tied to active route;
* huge Activity classes containing navigation, WebView, permissions, billing, and bridge logic;
* native components that hold stale Activity references;
* app-store billing logic mixed into generic bridge dispatcher;
* MediaPlayer hacks for background audio.

For audio, Android Media3 recommends connecting a MediaSession to a player, and background playback should live in a service-backed architecture.  ￼

⸻

7. Bridge protocol deep dive

7.1 Envelope

{
  "protocol": "keelway.bridge",
  "version": "0.1",
  "id": "01HYZV62CA9G4Z7FPYV9CE3J4T",
  "kind": "command",
  "name": "share.open",
  "direction": "server_to_native",
  "payload": {
    "title": "Invoice #123",
    "url": "https://app.example.com/invoices/123"
  },
  "correlation_id": null,
  "idempotency_key": "share-invoice-123",
  "route_id": "invoice_show",
  "url": "https://app.example.com/invoices/123",
  "origin": "https://app.example.com",
  "requires_ack": true,
  "timeout_ms": 5000,
  "metadata": {
    "app_version": "0.1.0",
    "platform": "ios"
  }
}

7.2 Ack

{
  "protocol": "keelway.bridge",
  "version": "0.1",
  "id": "01HYZV68H10TH7KBHG88T8V1YT",
  "kind": "ack",
  "name": "share.open",
  "correlation_id": "01HYZV62CA9G4Z7FPYV9CE3J4T",
  "payload": {
    "status": "ok",
    "completed": true
  },
  "metadata": {
    "duration_ms": 322
  }
}

7.3 Error

{
  "protocol": "keelway.bridge",
  "version": "0.1",
  "id": "01HYZV6CBWE0EBJ7PT3P4VWBV7",
  "kind": "error",
  "name": "share.open",
  "correlation_id": "01HYZV62CA9G4Z7FPYV9CE3J4T",
  "payload": {
    "code": "missing_capability",
    "message": "The native share capability is not available.",
    "fallback": "web"
  }
}

7.4 Naming convention

Use dotted names:

navigation.proposed
navigation.accepted
navigation.rejected
share.open
haptic.play
toast.show
alert.show
menu.show
permission.check
permission.request
camera.capture
file.pick
media.upload.prepare
purchase.start
purchase.restore
purchase.verified
purchase.failed
audio.play
audio.pause
audio.queue.set
sync.mutation.queue
sync.mutation.flush

Avoid:

doThing
nativeEvent
mobileAction
run
callback

Bridge names are public API. Make them boring and discoverable.

7.5 Capability negotiation

Native announces:

{
  "kind": "capabilities",
  "name": "capabilities.announced",
  "payload": {
    "bridge_version": "0.1",
    "platform": "ios",
    "app_version": "0.1.0",
    "capabilities": {
      "share.open": "1.0",
      "haptic.play": "1.0",
      "purchase.start": "0.1",
      "audio.play": "0.1"
    }
  }
}

Server persists only low-risk state:

%Keelway.Platform{
  os: :ios,
  native?: true,
  app_version: Version.parse!("0.1.0"),
  bridge_version: Version.parse!("0.1.0"),
  capabilities: %{
    "share.open" => Version.parse!("1.0.0"),
    "haptic.play" => Version.parse!("1.0.0")
  }
}

Do not put raw device IDs or user IDs in capability metrics.

7.6 Payload schemas

Each command gets a schema:

{
  "$id": "https://schemas.keelway.dev/bridge/v1/share.open.json",
  "type": "object",
  "required": ["title", "url"],
  "properties": {
    "title": {"type": "string", "maxLength": 120},
    "url": {"type": "string", "format": "uri"}
  },
  "additionalProperties": false
}

Elixir validates server-side. Swift/Kotlin decode strongly. JS validates in dev mode. Contract tests replay examples.

The RN/Expo lesson applies here: typed specs/codegen boundaries reduce runtime surprises and native/web mismatch.  ￼

⸻

8. Bridge components: design options and recommendation

Option A: Hotwire-style DOM components only

Everything is represented as DOM markup. Native components attach to web elements.

Pros

* Progressive enhancement is natural.
* Works for static HTML, controllers, LiveView.
* Easy fallback.
* Mirrors Hotwire Bridge Components.

Cons

* Awkward for server-initiated actions.
* Payloads can leak into HTML if careless.
* Complex lifecycle if LiveView patches DOM frequently.
* Harder for non-visual commands like purchase.restore.

Use for

* buttons
* menus
* forms
* haptics
* share
* toasts
* review prompts
* simple permissions

Option B: LiveView command bridge only

Everything goes through push_event and native replies.

Pros

* Excellent for Phoenix/LiveView.
* Typed command/ack flow.
* Server can coordinate state.
* Easy telemetry.

Cons

* Does not work for non-LiveView pages unless JS adapter exists.
* Less progressive fallback.
* Can become too server-chatty.
* Offline impossible for server-originated commands.

Use for

* billing verification flows
* async native actions
* server-triggered sheets
* support/review prompts
* workflows needing server state

Option C: Native screens only

Use manifest to replace many web screens with Swift/Kotlin screens.

Pros

* Best UX.
* Great for billing, audio, camera, onboarding.
* Native performance.

Cons

* More native code.
* Less web reuse.
* Risk of duplicate frontend logic.
* Harder OSS DX.

Use for

* paywalls
* camera/document scanner
* background audio player
* push permission onboarding
* security/biometric flows
* complex offline conflict UI

Recommendation: all three, with clear boundaries

* DOM components for progressive native polish.
* LiveView commands for server-aware workflows.
* Native screens for high-fidelity flows.

This is the strongest “best of all worlds” pattern.

⸻

9. Native core components to ship first

Do not ship 30 components in v0.1. But define the component architecture so the list can grow.

v0.1 core

share.open
haptic.play
toast.show
alert.show
navigation.open
capabilities.announced
connection.changed

v0.2 core

menu.show
sheet.show
permission.check
permission.request
push.token.register
review.prompt
file.pick
camera.capture.basic

v0.3 core

purchase.start
purchase.restore
audio.play
audio.pause
audio.queue.set
media.upload.prepare
sync.status

Component anatomy

A component has:

name
schema
required capabilities
allowed route contexts
native implementation
web fallback
telemetry events
fixtures
docs

Example docs entry:

name: share.open
platforms: [ios, android]
introduced: 0.1.0
payload_schema: contracts/bridge/v1/share.open.schema.json
requires:
  - native share sheet
fallback:
  - copy link
  - open web share route
telemetry:
  - [:keelway, :bridge, :command, :start]
  - [:keelway, :bridge, :command, :stop]
errors:
  - invalid_payload
  - missing_capability
  - cancelled
  - permission_denied

⸻

10. Route manifest internals

10.1 Rule resolution

Hotwire path config rules are read in order, and later matching rules override earlier ones. Keelway can use the same idea, but should make precedence explicit in docs and tests.  ￼

Suggested resolution:

base defaults
  -> matching route rules in declared order
  -> platform-specific overrides
  -> runtime callback overrides
  -> security deny rules

Example:

route "/billing", id: :billing,
  presentation: :push,
  cache: :never,
  commands: []
platform :ios do
  route "/billing",
    presentation: {:native_screen, "billing.paywall"},
    commands: ["purchase.start", "purchase.restore"]
end

10.2 Manifest signing

Should manifest be signed?

Argument against signing

* Adds key management.
* HTTPS already protects transport.
* Native app can pin/validate host.

Argument for signing

* Native app may cache remote manifest.
* Manifest controls privileged command allowlists.
* A compromised intermediate cache/CDN or mistaken endpoint should not silently grant new native powers.

Recommendation:

* v0.1: support unsigned local/remote manifest over HTTPS.
* v0.2: add optional signed manifest.
* v1.0: recommend signing for production.

{
  "manifest": { "...": "..." },
  "signature": {
    "alg": "Ed25519",
    "kid": "2026-05-main",
    "value": "base64..."
  }
}

10.3 Sensitive route flags

Some routes should never cache and should have restricted bridge power:

sensitive "/auth/*",
  cache: :never,
  commands: [],
  external_auth: true
sensitive "/billing/checkout",
  cache: :never,
  commands: ["purchase.start"],
  log_payloads: false

This matters because app-store billing, auth, and PII all intersect with WebView security.

⸻

11. Offline internals

Keelway core should not include full sync, but the architecture must leave room.

11.1 Core offline objects

NativePageCache
  key: route_id + normalized_url + user_scope_hash
  html_snapshot or web archive
  timestamp
  manifest_version
  cache_strategy
  ttl
  privacy_class
ConnectionMonitor
  online/offline
  expensive/constrained network
  last_recovered_at
OfflineStatePresenter
  banner
  stale badge
  retry view
  cached page view

11.2 Why native cache should be separate from service worker

Service workers can intercept network requests and serve cached responses, and MDN describes common cache strategies like cache-first, network-first, and stale-while-revalidate.  ￼

But WebView behavior, app lifecycle, and service-worker support differ by platform and version. Native page cache should be the reliable shell-level fallback; service worker should be an optimization for web/PWA and asset caching.

11.3 Sync package internals

keelway_sync/
  lib/
    keelway/sync.ex
    keelway/sync/resource.ex
    keelway/sync/resource_registry.ex
    keelway/sync/controller.ex
    keelway/sync/checkpoint.ex
    keelway/sync/mutation.ex
    keelway/sync/mutation_queue.ex
    keelway/sync/conflict.ex
    keelway/sync/conflict_resolver.ex
    keelway/sync/tombstone.ex
    keelway/sync/idempotency.ex
    keelway/sync/telemetry.ex

Resource DSL:

defmodule MyApp.Mobile.TodoSync do
  use Keelway.Sync.Resource,
    name: :todos,
    schema: MyApp.Todos.Todo,
    repo: MyApp.Repo,
    scope: :current_user
  fields [:id, :title, :completed, :updated_at]
  version_field :lock_version
  deleted_at_field :deleted_at
  cache :network_first, ttl: {7, :days}
  mutations [:create, :update, :delete],
    idempotency_key: true,
    conflict: MyApp.Mobile.TodoConflictResolver
end

Do not let this infer arbitrary schemas. Host apps should explicitly choose fields, scopes, mutation types, and conflict behavior.

11.4 Native SQLite shape

CREATE TABLE keelway_resource_rows (
  resource TEXT NOT NULL,
  id TEXT NOT NULL,
  version INTEGER,
  payload_json TEXT NOT NULL,
  updated_at TEXT,
  deleted_at TEXT,
  scope_hash TEXT NOT NULL,
  PRIMARY KEY (resource, id, scope_hash)
);
CREATE TABLE keelway_mutation_queue (
  id TEXT PRIMARY KEY,
  resource TEXT NOT NULL,
  operation TEXT NOT NULL,
  row_id TEXT,
  base_version INTEGER,
  payload_json TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  created_at TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error_json TEXT
);

11.5 Offline anti-pattern

Do not expose this API:

use Keelway.Sync.Resource, schema: MyApp.Anything
sync_everything true

That creates security, privacy, performance, and conflict-resolution bugs.

⸻

12. Billing internals

Billing should be a separate package because it carries app-store and entitlement risk.

12.1 Package structure

keelway_billing/
  lib/
    keelway/billing.ex
    keelway/billing/purchase_intent.ex
    keelway/billing/provider.ex
    keelway/billing/receipt_verifier.ex
    keelway/billing/subscription_state.ex
    keelway/billing/entitlement_mapper.ex
    keelway/billing/apple.ex
    keelway/billing/apple/transaction.ex
    keelway/billing/apple/server_notification.ex
    keelway/billing/google.ex
    keelway/billing/google/purchase_token.ex
    keelway/billing/google/rtdn.ex
    keelway/billing/accrue_adapter.ex
    keelway/billing/test_fixtures.ex

12.2 Flow

Phoenix paywall
  -> bridge purchase.start
  -> native StoreKit / Play Billing
  -> native sends transaction/purchase token
  -> Phoenix verifies server-side
  -> entitlement adapter updates host billing state
  -> LiveView/app refreshes entitlement

Apple StoreKit transactions are signed as JWS, App Store Server API returns signed transaction and renewal information, and App Store Server Notifications provide real-time server-to-server purchase lifecycle events.  ￼

Google Play Billing requires client purchase flow plus server verification using purchase tokens, and Google’s real-time developer notification docs say to call the Google Play Developer API after receiving RTDN messages.  ￼

12.3 Native purchase component

iOS:

public final class StoreKitPurchaseCoordinator: KeelwayBridgeComponent {
    public static let name = "purchase.start"
    public func receive(_ message: BridgeEnvelope) async -> BridgeReply {
        // decode product_id
        // load Product.products(for:)
        // purchase
        // return signed transaction fields to server/web
    }
}

Android:

class PlayBillingCoordinator(
    private val billingClient: BillingClient
) : BridgeComponent {
    override val name = "purchase.start"
    override suspend fun onReceive(message: BridgeEnvelope): BridgeReply {
        // decode product id
        // query product details
        // launch billing flow
        // return purchase token to server/web
    }
}

12.4 Hard rule

Native success does not equal entitlement success.

case Keelway.Billing.verify(provider_payload) do
  {:ok, verified_event} ->
    MyApp.Billing.apply_verified_purchase(verified_event)
  {:error, reason} ->
    # show pending/failed verification
end

12.5 Billing anti-patterns

Avoid:

* mapping purchase success directly to subscription active;
* mixing Stripe/Paddle checkout into in-app digital goods flow without policy review;
* storing raw receipts in telemetry;
* failing to support restore purchases;
* ignoring refunds/grace/account-hold states;
* hiding billing policy nuance in a magic adapter.

Google’s Play billing policy is in flux, including regional/user-choice billing APIs and 2026 policy changes, so Keelway should document that teams must verify current store terms before release.  ￼

⸻

13. Push/media/audio internals

13.1 keelway_push

keelway_push/
  device_registry.ex
  deep_link.ex
  payload.ex
  token_event.ex
  chimeway_adapter.ex

Native:

PushTokenCoordinator
DeepLinkRouter
NotificationPermissionComponent
NotificationOpenEvent

Design:

* Native obtains token.
* Native sends push.token.register.
* Phoenix validates session.
* Host stores token or delegates to chimeway.
* Deep links resolve through manifest before navigation.

13.2 keelway_media

keelway_media/
  capture_intent.ex
  upload_intent.ex
  upload_session.ex
  rindle_adapter.ex

Native:

CameraCoordinator
PhotoPickerCoordinator
DocumentPickerCoordinator
UploadCoordinator

Design:

* Phoenix creates upload intent.
* Native captures/picks file.
* Native uploads directly to signed URL or host endpoint.
* Phoenix/Rindle receives lifecycle event.

13.3 keelway_audio

This may deserve its own package later.

Native audio should not be controlled by LiveView diffs. Apple’s AVFoundation family covers audiovisual media, and Android Media3 recommends a service/media-session architecture for background playback.  ￼

Internal shape:

audio/
  AudioPlaybackCoordinator
  PlaybackQueue
  PlaybackState
  AudioCache
  BackgroundAudioService
  NowPlayingInfoAdapter

Bridge commands:

audio.queue.set
audio.play
audio.pause
audio.seek
audio.state.changed

Anti-pattern: sending frequent playback progress updates to Phoenix. Instead, native owns progress and sends coarse state changes.

⸻

14. DX and troubleshooting internals

The daily developer experience matters as much as architecture.

14.1 Install flow

mix igniter.install keelway
mix keelway.install

Generated files:

lib/my_app_web/mobile/route_policy.ex
lib/my_app_web/mobile/bridge_handler.ex
lib/my_app_web/mobile/components.ex
assets/js/keelway.js
priv/keelway/manifest.local.json
native/ios/
native/android/
test/support/keelway_case.ex

14.2 Doctor task

mix keelway.doctor

Checks:

✓ Phoenix endpoint configured
✓ Route policy compiles
✓ Manifest endpoint responds
✓ Manifest has bundled fallback
✓ Admin/auth routes are not cacheable
✓ Billing routes are marked sensitive
✓ Bridge JS hook installed
✓ Telemetry prefix configured
✓ iOS app-bound domains configured
✓ Android allowed origins configured
✓ No wildcard native bridge origins
✓ Contract fixtures pass

14.3 Native debug screen

Debug-only native menu:

Keelway Debug
  App version
  Bridge version
  Manifest version
  Manifest source: bundled/cached/remote
  Current route ID
  Current capabilities
  Cookie/session status
  Connection status
  Last 50 bridge events
  Mutation queue depth
  Cache entries
  Billing sandbox status

This is a huge DX win. Mobile bugs are often “it works in browser but not in app.” The library should make invisible shell state visible.

14.4 LiveDashboard panel

Expose:

* app versions seen,
* command latency,
* missing capability count,
* offline durations,
* cache hit/miss,
* mutation queue depth,
* billing verification failures,
* native crash breadcrumbs if host wires them.

⸻

15. Testing internals

15.1 Contract fixture strategy

Contracts should be first-class repo artifacts:

contracts/
  bridge/v1/envelope.schema.json
  bridge/v1/share.open.schema.json
  bridge/v1/haptic.play.schema.json
fixtures/
  bridge/share.open.ok.json
  bridge/share.open.missing_capability.json
  bridge/haptic.play.permission_denied.json

All four runtimes test the same files:

* Elixir ExUnit.
* Swift XCTest.
* Kotlin JUnit.
* JS Vitest.

15.2 Elixir tests

Phoenix’s testing stack uses ExUnit, and Phoenix.LiveViewTest can test LiveViews through the server process without needing a browser for many interactions.  ￼

Example:

describe "native commands" do
  test "invoice route allows share.open" do
    manifest = MyAppWeb.Mobile.RoutePolicy.manifest()
    assert Keelway.Manifest.allowed?(manifest, "/invoices/123", "share.open")
  end
  test "admin route denies all native commands" do
    refute Keelway.Manifest.allowed?(manifest, "/admin/users", "share.open")
  end
  test "LiveView pushes valid native command envelope" do
    {:ok, view, _html} = live(conn, "/invoices/123")
    view
    |> element("button", "Share")
    |> render_click()
    assert_push_event(view, "keelway:command", %{envelope: envelope})
    assert envelope["name"] == "share.open"
  end
end

15.3 Native unit tests

iOS XCTest:

func testShareOpenDecodesFixture() throws {
    let envelope = try BridgeEnvelope.fixture("share.open.ok")
    XCTAssertEqual(envelope.name, "share.open")
}
func testBridgeRejectsWrongOrigin() async throws {
    let router = BridgeRouter(security: .allowedOrigins(["https://app.example.com"]))
    let result = await router.dispatch(fixtureFrom: "wrong-origin")
    XCTAssertEqual(result.errorCode, "origin_not_allowed")
}

Android JUnit:

@Test
fun shareOpenDecodesFixture() {
    val envelope = BridgeEnvelope.fixture("share.open.ok")
    assertEquals("share.open", envelope.name)
}
@Test
fun bridgeRejectsWildcardOriginInProduction() {
    assertFailsWith<InvalidConfigException> {
        WebViewPolicy(allowedOrigins = setOf("*"), environment = Production)
    }
}

15.4 E2E

Use Playwright for web/PWA/network conditions and Maestro for mobile smoke.

Playwright supports mobile device emulation and network mocking/inspection, useful for service worker and offline-cache tests.  ￼

Maestro is a simple open-source mobile UI testing framework for Android/iOS/web with YAML flows, while Appium is the broader WebDriver-based automation ecosystem. Keelway should start with Maestro for v0.1 smoke tests and document Appium for teams that need enterprise-level device farm compatibility.  ￼

Example Maestro flow:

appId: com.example.mysaas
---
- launchApp
- assertVisible: "My SaaS"
- tapOn: "Invoices"
- tapOn: "Invoice #123"
- tapOn: "Share"
- assertVisible: "Share"

15.5 Native UI tests

Espresso remains useful for Android developer-facing UI tests; Android’s docs describe Espresso as concise, reliable, and synchronized with UI actions.  ￼

Use Espresso/XCTest for component-level native screens; keep full app smoke in Maestro.

⸻

16. Decision dialectics

16.1 Should Keelway use Stimulus?

Pro-Stimulus

* Hotwire Bridge Components already use it.
* Great for DOM-attached controllers.
* Many Rails examples exist.

Anti-Stimulus

* Phoenix does not require it.
* LiveView hooks already exist.
* Adds JS ecosystem assumptions.

Recommendation

Do not require Stimulus. Provide optional Stimulus adapter.

import { KeelwayStimulusController } from "@sztheory/keelway-bridge/stimulus"

Core should be vanilla JS + LiveView hook.

16.2 Should Keelway use one shared WebView?

Pro

* Better session continuity.
* Mirrors Turbo/Hotwire Native.
* Less memory.
* Native stack feels coherent.

Anti

* Harder if multiple screens need independent state.
* Modal flows can interfere.
* Some WebView bugs become global.

Recommendation

One shared WebView per navigator context. Separate context for modals/auth/native-owned flows. This mirrors Turbo’s advice to use multiple sessions for separate navigation contexts.  ￼

16.3 Should route policy live in Phoenix router?

Option:

live "/invoices/:id", InvoiceLive,
  mobile: [presentation: :push, commands: ["share.open"]]

Pros

* Co-located.
* Obvious.

Cons

* Phoenix router macros are not designed for arbitrary mobile policy complexity.
* Harder to keep optional.
* Can pollute normal web routing.

Recommendation: separate Mobile.RoutePolicy, with optional helpers to import route names from router. Keep Phoenix router clean.

16.4 Should the native shell call Phoenix manifest before every navigation?

Pros

* Server is always fresh.
* Feature flags easy.

Cons

* Bad offline.
* Slow navigation.
* Native cannot decide before request.
* More failure states.

Recommendation: local/cached/remote manifest with periodic refresh. Server can still redirect/deny at HTTP layer.

16.5 Should Keelway bridge commands be strings or atoms?

External protocol should use strings:

"name": "share.open"

Elixir APIs may accept atoms for local ergonomics:

push_native(socket, :share_open, payload)

But convert to canonical strings immediately. Atoms are not appropriate for untrusted external payloads.

16.6 Should payload schemas be generated from Elixir structs?

Possible tools:

* JSON Schema generated from Elixir metadata.
* OpenAPI-ish definitions.
* Hand-written schemas.
* Protocol-based validation.

Recommendation:

* v0.1: hand-written JSON schema fixtures for core commands.
* v0.2: behaviour-based schema providers.
* v1.0: optional codegen for Swift/Kotlin.

Do not block v0.1 on perfect codegen.

16.7 Should Android support old WebView bridge fallback?

Pro

* More devices.
* Simpler compatibility story.

Anti

* addJavascriptInterface is risky.
* Legacy Android bridge vulnerabilities are well-known.
* Wildcard bridge exposure creates severe issues.

Recommendation: default to modern origin-scoped message bridge; legacy fallback must be explicit and noisy. Android and OWASP both warn about insecure native bridge exposure and wildcard origin messaging.  ￼

16.8 Should Keelway generate native code into host app or ship black-box shells?

Generated host-owned code

Pros:

* Easy to customize.
* Fits szTheory host-owned philosophy.
* App teams can debug.

Cons:

* More files.
* Harder upgrades.

Black-box shell

Pros:

* Fast install.
* Easier updates.

Cons:

* Harder customization.
* Debugging opaque.
* Less trust.

Recommendation: ship reusable native packages plus generated host-owned entrypoints. Core internals stay packaged; app-specific wiring is generated and editable.

⸻

17. Premium UX internals

17.1 Navigation polish

Native shells should own:

* swipe-back,
* modal detents/sheets,
* large titles where appropriate,
* safe areas,
* status bar style,
* loading progress,
* pull-to-refresh,
* native error screens.

17.2 Motion and haptics

Apple’s Human Interface Guidelines emphasize motion that gives realistic feedback and follows user expectations, and also stress accessibility/reduced-motion accommodations.  ￼

Internal design:

public enum HapticKind: String, Codable {
    case success
    case warning
    case error
    case selection
    case impactLight
    case impactMedium
    case impactHeavy
}

Bridge command:

{
  "name": "haptic.play",
  "payload": {"kind": "success"}
}

Rules:

* Never haptic-spam.
* Tie haptics to meaningful state changes.
* Disable/reduce if accessibility settings or platform constraints require it.
* No haptics for background events.

17.3 Loading states

Native should provide route-aware loading states:

root launch skeleton
push route spinner/progress bar
modal loading sheet
cached stale page badge
offline fallback screen
auth expired screen
billing verification pending

17.4 Review prompts

Review prompt should be a bridge component but policy-gated:

Keelway.Reputation.maybe_prompt(socket,
  reason: :support_resolved_positive,
  cooldown: {90, :days}
)

Native component:

review.prompt

Never prompt after:

* crash,
* refund,
* failed purchase,
* support escalation,
* sync conflict,
* permission denial.

⸻

18. Security internals

18.1 Trust boundaries

Phoenix server: trusted business authority
Native shell: trusted app runtime, but user-controlled device
WebView page: trusted only if origin + route + manifest allow it
JS bridge payload: untrusted until validated
Native command result: untrusted until verified server-side if it affects entitlement/security

18.2 Route-based command allowlist

route "/billing",
  commands: ["purchase.start", "purchase.restore"]
route "/settings",
  commands: ["permission.request", "push.token.register"]
deny "/admin/*"

18.3 Origin controls

iOS:

* allowedOrigins.
* app-bound domains where feasible.
* check frame info.
* avoid commands from iframes.

Android:

* WebViewCompat.addWebMessageListener.
* explicit allowedOriginRules.
* no wildcard in production.
* avoid legacy addJavascriptInterface.

Android’s bridge security docs and OWASP guidance make this non-negotiable.  ￼

18.4 Deep links

Deep-link event:

{
  "name": "navigation.proposed",
  "payload": {
    "url": "https://app.example.com/invoices/123",
    "source": "universal_link"
  }
}

Validation:

* host/domain allowlist,
* route manifest match,
* optional signed action token for privileged operations,
* no direct mutation by deep link without server confirmation.

18.5 Session/auth

Do not invent a new auth system.

Options:

1. Cookie/session WebView auth — easiest, Phoenix-native.
2. Token handoff — useful for native APIs/sync, but higher risk.
3. OAuth external browser session — use platform auth session/browser for providers.

Keelway should support session-cookie default and document token handoff for sync/native APIs. It should integrate optionally with sigra, not require it.

⸻

19. App-store-sensitive internals

Billing and review rules are moving targets. The technical architecture must make policy-sensitive behavior explicit.

19.1 Billing route metadata

route "/billing",
  id: :billing,
  presentation: {:native_screen, "billing.paywall"},
  cache: :never,
  commands: ["purchase.start", "purchase.restore"],
  policy_class: :digital_goods_subscription

19.2 Purchase intent

defmodule Keelway.Billing.PurchaseIntent do
  @enforce_keys [:provider, :product_id, :user_scope, :return_to]
  defstruct [
    :provider,
    :product_id,
    :offer_id,
    :user_scope,
    :return_to,
    :metadata
  ]
end

19.3 Verification callback

@callback verify_purchase(provider_payload :: map(), context :: map()) ::
            {:ok, Keelway.Billing.VerifiedPurchase.t()}
            | {:error, Keelway.Billing.VerificationError.t()}

19.4 Entitlement adapter

defmodule MyApp.Mobile.AccrueEntitlementAdapter do
  @behaviour Keelway.Billing.EntitlementMapper
  def apply_purchase(%Keelway.Billing.VerifiedPurchase{} = purchase) do
    Accrue.apply_entitlement(...)
  end
end

The server-verification posture is essential because Apple and Google both provide server-side purchase/subscription APIs/notifications that should drive durable entitlement state.  ￼

⸻

20. API ergonomics stress test

20.1 Minimal install

# config/config.exs
config :keelway,
  otp_app: :my_app,
  endpoint: MyAppWeb.Endpoint,
  app_name: "My SaaS",
  route_policy: MyAppWeb.Mobile.RoutePolicy,
  telemetry_prefix: [:my_app, :mobile]
# router.ex
pipeline :mobile do
  plug Keelway.Plug.Platform
  plug Keelway.Plug.Manifest
end
scope "/", MyAppWeb do
  pipe_through [:browser, :mobile]
  live "/", HomeLive
  live "/invoices/:id", InvoiceLive
end
defmodule MyAppWeb.Mobile.RoutePolicy do
  use Keelway.RoutePolicy
  route "/", id: :home, presentation: :root
  route "/invoices/:id", id: :invoice_show,
    presentation: :push,
    commands: ["share.open"]
end

20.2 First native action

defmodule MyAppWeb.InvoiceLive do
  use MyAppWeb, :live_view
  use Keelway.LiveView
  def render(assigns) do
    ~H"""
    <button phx-click="share">Share</button>
    """
  end
  def handle_event("share", _params, socket) do
    {:noreply,
     push_native(socket, "share.open", %{
       title: "Invoice #{@invoice.number}",
       url: url(~p"/invoices/#{@invoice}")
     })}
  end
  def handle_event("keelway:ack", %{"envelope" => envelope}, socket) do
    case envelope["payload"]["status"] do
      "ok" -> {:noreply, socket}
      "missing_capability" -> {:noreply, put_flash(socket, :info, "Copy the invoice link instead.")}
    end
  end
end

Potential improvement: hide keelway:ack plumbing behind handle_native_ack/3.

def handle_native_ack("share.open", :ok, _payload, socket) do
  {:noreply, socket}
end

20.3 Native component with web fallback

<.native_action
  name="share.open"
  payload={%{title: "Invoice #{@invoice.number}", url: url(~p"/invoices/#{@invoice}")}}
  fallback_href={~p"/invoices/#{@invoice}/share"}
  requires={[:share]}
>
  Share
</.native_action>

This is better for links/buttons that should work on web too.

20.4 Native screen route

route "/billing",
  id: :billing,
  presentation: {:native_screen, "billing.paywall"},
  commands: ["purchase.start", "purchase.restore"],
  cache: :never

Swift:

struct MyNativeScreens: NativeScreenFactory {
    func makeScreen(name: String, url: URL, context: NativeScreenContext) -> UIViewController? {
        switch name {
        case "billing.paywall":
            return PaywallViewController(context: context)
        default:
            return nil
        }
    }
}

Kotlin:

class MyNativeScreens : NativeScreenFactory {
    override fun create(name: String, url: HttpUrl, context: NativeScreenContext): Fragment? =
        when (name) {
            "billing.paywall" -> PaywallFragment.newInstance(url.toString())
            else -> null
        }
}

⸻

21. Anti-pattern catalog

21.1 “Just wrap the website”

What goes wrong: users get bad navigation, web loading, broken permissions, weak offline, and store review surprises.

Prevention: native navigation, route manifest, native error/loading states, bridge capabilities, app-store docs.

Residual risk: some apps still need true native screens.

21.2 “Everything is a bridge command”

What goes wrong: chatty bridge, hard-to-debug UI, server owns too much.

Prevention: native owns high-frequency interactions; bridge only semantic commands/events.

Residual risk: developers may overuse bridge anyway. Provide lint/doctor warnings.

21.3 “Any page can call native”

What goes wrong: XSS or embedded iframe invokes privileged native commands.

Prevention: origin allowlist, route allowlist, command allowlist, payload schema, active destination checks.

Residual risk: first-party XSS remains high impact.

21.4 “Service workers solve offline”

What goes wrong: cached pages appear interactive but cannot save; platform differences surprise users.

Prevention: distinguish cached read-only vs sync-capable resources; native stale UI.

Residual risk: user expectations remain hard.

21.5 “Receipt == entitlement”

What goes wrong: fraud, refunds ignored, grace/account hold mishandled.

Prevention: server verification, provider notifications, entitlement mapper.

Residual risk: provider API outages and policy changes.

21.6 “One native mega-module”

What goes wrong: impossible to test or customize.

Prevention: navigator, manifest, bridge, components, billing, audio, media, telemetry as separate modules.

Residual risk: examples can still grow too complex.

21.7 “No debug surface”

What goes wrong: developers cannot tell if bug is Phoenix, JS, native, manifest, cache, or store.

Prevention: native debug screen, LiveDashboard panel, mix keelway.doctor, bridge logs.

Residual risk: production logs must remain privacy-safe.

⸻

22. Strongest prototype spikes

Before committing to full build, I would run these spikes.

Spike 1: minimal bridge across all runtimes

* Elixir command struct.
* JS hook.
* Swift WKScriptMessageHandler.
* Android WebViewCompat.addWebMessageListener.
* One command: haptic.play or share.open.
* Contract fixture test in Elixir/Swift/Kotlin.

Success: same fixture passes on all runtimes.

Spike 2: manifest-driven navigation

* Phoenix route policy.
* Native bundled manifest.
* Remote manifest refresh.
* iOS/Android route matcher.
* Push vs modal vs native screen.

Success: link tap changes native presentation without changing web page.

Spike 3: LiveView command/ack

* LiveView button.
* push_native.
* Native action.
* Ack back into LiveView.
* Missing capability fallback.

Success: deterministic test with fake native ack.

Spike 4: Android bridge security

* Implement WebMessageListener.
* Verify origin allowlist.
* Verify iframe cannot call command.
* Verify wildcard rejected in production config.

Success: failing security fixtures are blocked.

Spike 5: offline cached route

* cache home route,
* kill network,
* app shows stale cached home,
* sensitive route refuses cache.

Success: no misleading interactivity.

Spike 6: billing protocol only

* Define purchase.start envelope/schema.
* iOS/Android fake native purchase component.
* Server fake verification.
* Accrue adapter stub.

Success: entitlement only changes after server verification.

⸻

23. Refined recommendation

The original recommendation still holds, but with sharper internals:

Keelway should be a Phoenix-native route manifest + bridge component + LiveView command toolkit with small Swift/Kotlin shells.

The key internal decisions I would defend:

1. One shared WebView per navigator context, copied from Turbo/Hotwire Native.
2. Bundled + cached + remote manifest, copied from Hotwire Native path config.
3. Three bridge planes, because Phoenix/LiveView can do more than DOM-only bridge components.
4. HEEx/LiveView-first web integration, with optional Stimulus adapter.
5. Origin-scoped native bridge, especially on Android.
6. Typed JSON schema contracts and shared fixtures, inspired by React Native/Expo codegen discipline.
7. Native owns high-frequency UX, especially animation/audio.
8. Offline is explicit and limited, with sync as an opt-in package.
9. Billing is separate and server-verified, with no policy magic.
10. Debuggability is a first-class feature, not an afterthought.

A concise internal motto:

Keelway should make native mobile feel like a first-class Phoenix deployment target, without pretending Phoenix has become a native renderer or offline-first framework.