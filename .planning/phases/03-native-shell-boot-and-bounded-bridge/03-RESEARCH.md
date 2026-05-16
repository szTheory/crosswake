# Phase 3: Native Shell Boot And Bounded Bridge - Research

**Researched:** 2026-05-14
**Domain:** Native shell boot, manifest-first route activation, and bounded bridge enforcement
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Shell scaffold shape
- **D-01:** Phase 3 should build a thin but real shell, not a placeholder wrapper and not a broad future-heavy chassis.
- **D-02:** The first shell must include native app boot, manifest loading, compatibility gating, route resolution, native navigation structure, deep-link/app-entry handling, bounded LiveView hosting, and a built-in diagnostics surface.
- **D-03:** The first shell must not prebuild speculative Phase 4/5 surfaces such as offline-island hosts, pack management UI, broad operator consoles, or native-screen registries beyond the seams directly required for Phase 3.
- **D-04:** Shell UX should make route truth visible: explicit unsupported/unavailable screens are part of the product contract, not cleanup work.

### Route activation and LiveView container
- **D-05:** Route activation should be manifest-first and native-first: app launch, universal/app links, notifications, and in-app navigation all normalize into a typed route activation request before any web container loads content.
- **D-06:** The shell should resolve the requested route against the bundled or cached manifest, run compatibility and allowlist checks, and only then mount the declared runtime.
- **D-07:** Declared `:live_view` routes should open inside a bounded same-origin `WKWebView`/Android `WebView` container after manifest, origin, runtime, and capability checks pass.
- **D-08:** Crosswake should not use a WebView-first bootstrap where in-page JavaScript asks the shell to hand off later. That approach drifts toward generic-wrapper behavior and checks route safety too late.
- **D-09:** Crosswake should not introduce a separate Hotwire-style path-rule or presentation overlay in Phase 3. Route ownership and primary activation truth stay in the Crosswake manifest; presentation defaults may live in shell code or minimal manifest-backed metadata, but not in a second routing system.
- **D-10:** Unsafe or unsupported routes must never silently fall back to a generic container. They should land on an explicit native denial or recovery surface, with only narrow safe fallback behavior when policy allows it.

### Bridge contract and first capability set
- **D-11:** The Phase 3 bridge should stay semantic, typed, versioned, request/reply-only, and low-frequency. It must not become a generic message bus, navigation authority, or render/state synchronization channel.
- **D-12:** Bridge command naming should stay noun-first and explicit, such as `app.info.get`, `haptics.impact`, and `files.pick`, rather than plugin-style raw method dispatch.
- **D-13:** The first bridge capability set should be small but useful: `app.info.get`, `haptics.impact`, and `files.pick`.
- **D-14:** The first capability set should deliberately exclude permission-heavy, camera-adjacent, clipboard, share-sheet, and other broad plugin surfaces until later phases prove where native-screen or adapter ownership is the better fit.
- **D-15:** Every bridge request must carry enough typed context for enforcement, including route identity, origin, capability/command identity, version identity, and correlation identity for request/reply handling.
- **D-16:** Capability allowlists and capability versions should come directly from manifest truth and route declarations, not from ad hoc native registration alone.

### Capability denial and failure behavior
- **D-17:** Crosswake should fail closed by default on route activation and capability execution.
- **D-18:** The shell should provide one standardized denial surface for route activation failures and one typed denial envelope for bridge failures, sharing the same reason vocabulary.
- **D-19:** Denial reasons should be stable and product-level, covering at least compatibility mismatch, undeclared or unavailable capability, origin denied, and inactive route. Debug surfaces may include deeper axis detail and hints; release-user copy should stay calm and support-oriented.
- **D-20:** Deep links should be checked before runtime boot. If denied, the shell should open a Crosswake-owned route-unavailable screen with only safe actions such as retry, open a declared safe fallback route, or update the app.
- **D-21:** In-app navigation failures should keep the current route stable and present denial UI as an interrupting native surface rather than partially navigating into the wrong runtime.
- **D-22:** Bridge denials must never execute side effects and must be easy to assert in tests and surface in diagnostics.

### Native packaging and generator posture
- **D-23:** Phase 3 should generate real host-owned native app projects, not placeholder text files and not regeneratable pseudo-owned native directories.
- **D-24:** iOS should use a real Xcode app target/project baseline. Crosswake may also generate a local reusable shell library or package, but not `Package.swift` executable targets as the primary app build system.
- **D-25:** Android should use a real Gradle/Android Studio app module baseline, optionally with a local reusable library module for Crosswake-owned runtime code.
- **D-26:** Crosswake’s public posture should be scaffold once, then patch-or-doc upgrades. Do not imply that the library safely re-owns or regenerates host-edited native apps after initial generation.
- **D-27:** Proof lanes should build the same class of host-owned native app artifact that adopters ship, so support claims reflect real installation paths rather than internal-only demo topology.

### Decision delegation posture
- **D-28:** Shift decisions left within GSD by default for this phase. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes the public product contract, support claims, compatibility policy, security posture, route-runtime taxonomy, or the host-owned-vs-library-owned ownership model.
- **D-29:** Internal implementation details such as exact module splits, native file organization, navigation stack implementation details, serialization helpers, fixture shape, and diagnostics presentation polish are agent discretion as long as they preserve the decisions above.

### the agent's Discretion
- Exact shell module and file boundaries on iOS and Android.
- Exact diagnostics screen layout and copy treatment in debug vs release builds.
- Exact typed field names for bridge envelopes, provided the semantic contract and enforcement posture stay intact.
- Exact presentation defaults for pushing or replacing LiveView-backed screens, so long as route ownership does not move out of the manifest-driven activation path.

### Deferred Ideas (OUT OF SCOPE)
- Separate path-rule or presentation overlay systems similar to Hotwire path configuration — deferred unless Phase 3 planning proves a minimal presentation metadata seam is unavoidable.
- Permission-heavy and broader plugin-style bridge capabilities such as camera, clipboard, share sheet, notifications, or generic permission brokers — defer to later native-screen, adapter, or companion-focused phases.
- Offline island hosts, journals, reconciliation UI, and pack-management UI — Phase 4 and Phase 5 work.
- Broad native-screen registries, device-heavy escape hatches, and media-heavy adapters — Phase 5 work.
- Regeneratable or continuously re-owned native project directories — deferred unless the product later takes a much more opinionated native-project-management posture.
- Companion/vendor integration abstractions — remain outside Phase 3 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MANI-03 | Native shells refuse to activate routes when manifest, bridge, capability, or pack compatibility checks fail. | Reuse and extend `Crosswake.Compatibility` + `Crosswake.Compatibility.RouteGate` as the single activation gate and denial vocabulary. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/compatibility/route_gate.ex] |
| SHELL-01 | iOS shell boots from manifest and hosts bounded LiveView in WebKit. | Use a real Xcode app target with `WKNavigationDelegate` and `WKUserContentController`-backed same-origin hosting. [CITED: https://developer.apple.com/documentation/WebKit/WKNavigationDelegate/webView%28_%3AdecidePolicyFor%3AdecisionHandler%3A%29-2ni62] [CITED: https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc] |
| SHELL-02 | Android shell boots from manifest and hosts bounded LiveView in WebView. | Use a real Gradle app module with `WebViewClient` gating and AndroidX WebKit message listener APIs. [CITED: https://developer.android.com/reference/android/webkit/WebViewClient.html] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] |
| SHELL-03 | Deep links and app entry open the runtime declared by route policy. | Normalize universal links/App Links and in-app intents into one native activation request before any container loads. [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about] |
| BRDG-01 | Typed, versioned, request/reply bridge. | Add one shared envelope contract plus native adapters only for `app.info.get`, `haptics.impact`, and `files.pick`. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |
| BRDG-02 | Capability registry allowlists capabilities by route. | Keep registry truth in the manifest’s `capability_registry` and per-route `capabilities` fields; do not duplicate it in native-only config. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| BRDG-03 | Bridge verifies active-route, origin, and compatibility constraints. | Extend current origin/version checks with active-route identity and denial envelopes wired into diagnostics. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/doctor/check.ex] |
</phase_requirements>

## Summary

Phase 3 should be planned as one contract-preserving expansion of Phase 2, not as a separate mobile product line. The repo already has the right Phoenix-side truth surfaces: a typed manifest root with compatibility and capability registry fields, route entries carrying capabilities and allowlisted origins, a layered compatibility evaluator, a fail-closed route gate, and structured doctor findings. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/compatibility/route_gate.ex] [VERIFIED: lib/crosswake/doctor/check.ex]

The planning shape should therefore be: upgrade `mix crosswake.gen.shell` from placeholder files to real host-owned native app projects; export manifest/fixture artifacts that those projects can boot from; normalize every app-entry path into one typed native activation request; gate activation through shared compatibility/capability/origin checks; and only then mount a bounded `WKWebView` or Android `WebView`. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs] [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about]

The bridge should be deliberately small. Both platform docs and the project’s own prompt lineage support an origin-scoped, request/reply-only channel and argue against broad plugin exposure or chatty JS/native state loops. [CITED: https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] [CITED: https://developer.android.com/develop/ui/views/layout/webapps/webview] [VERIFIED: prompts/elixir-mobile-oss-refined-plan-deep-research.md] [VERIFIED: prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md]

**Primary recommendation:** Plan Phase 3 in six slices: shared activation/denial contract, generator + manifest artifacts, iOS shell, Android shell, bounded bridge, and shell-aware diagnostics/proof fixtures. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/research/ARCHITECTURE.md]

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` file was present in the repo root during research, so there are no extra project-local directives beyond `AGENTS.md` and `.planning/*`. [VERIFIED: filesystem check]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Manifest compilation and shell fixture export | API / Backend | CDN / Static | Manifest truth is already produced in Elixir by `Crosswake.Manifest` and should stay server-owned, while shells consume bundled artifacts. [VERIFIED: lib/crosswake/manifest/manifest.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| App boot and deep-link normalization | Browser / Client | API / Backend | Universal links/App Links arrive in the native app process first, but must normalize to manifest route IDs and host origins emitted by Phoenix. [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about] [VERIFIED: lib/crosswake/manifest/types.ex] |
| Route activation gating and denial UI | Browser / Client | API / Backend | Activation happens in the shell before any web container loads, but the decision inputs are the manifest compatibility and route rules already modeled in Elixir. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/compatibility/route_gate.ex] |
| Bounded LiveView hosting | Browser / Client | API / Backend | `WKWebView`/`WebView` host the route at runtime, while Phoenix remains authority for the same-origin URL and LiveView content. [CITED: https://developer.apple.com/documentation/WebKit/WKNavigationDelegate/webView%28_%3AdecidePolicyFor%3AdecisionHandler%3A%29-2ni62] [CITED: https://developer.android.com/reference/android/webkit/WebViewClient.html] |
| Bridge contract/schema and fixtures | API / Backend | Browser / Client | The typed contract should be generated and versioned from repo-owned truth, then decoded/enforced by the native shells. [VERIFIED: prompts/elixir-mobile-oss-refined-plan-deep-research.md] [VERIFIED: lib/crosswake/doctor/check.ex] |
| Capability adapter execution | Browser / Client | API / Backend | Native code owns app-info, haptics, and file picking side effects, but allowlisting and version rules come from manifest route truth. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| Developer diagnostics | API / Backend | Browser / Client | `mix crosswake.doctor` is the existing operator surface, and Phase 3 should add shell findings/fixtures into that same vocabulary instead of inventing a second diagnostics contract. [VERIFIED: lib/crosswake/doctor/doctor.ex] [VERIFIED: lib/crosswake/doctor/formatter.ex] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` | Core manifest, compatibility, generator, and diagnostics code. | This is the repo baseline and all current Phase 1-2 surfaces already target it. [VERIFIED: mix.exs] |
| Phoenix | `~> 1.8` | Host routing source consumed by policy and manifest compilation. | Crosswake is explicitly Phoenix-first rather than JS-framework-first. [VERIFIED: mix.exs] [VERIFIED: .planning/PROJECT.md] |
| Phoenix LiveView | `~> 1.1` | Server-owned route runtime hosted inside the bounded native container. | Phase 3 success criteria are explicitly about hosting declared LiveView routes, not replacing them. [VERIFIED: mix.exs] [VERIFIED: .planning/ROADMAP.md] |
| Jason | `~> 1.4` | Manifest and fixture serialization. | Doctor already decodes JSON and the Phase 3 shells need stable bundled JSON artifacts. [VERIFIED: mix.exs] [VERIFIED: lib/crosswake/doctor/doctor.ex] |
| iOS `WKWebView` + `WKNavigationDelegate` + `WKUserContentController` | Platform SDK | Same-origin hosting, navigation gating, and typed JS/native message handling on iOS. | Apple documents these as the standard hooks for allowing/canceling navigation and bridging JS messages to native handlers. [CITED: https://developer.apple.com/documentation/WebKit/WKNavigationDelegate/webView%28_%3AdecidePolicyFor%3AdecisionHandler%3A%29-2ni62] [CITED: https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc] |
| Android `WebView` + `WebViewClient` + AndroidX WebKit `1.15.0` | `1.15.0` | Same-origin hosting, navigation interception, and origin-scoped message listening on Android. | Android documents `WebViewClient` for navigation control and AndroidX WebKit as the safer compatibility layer for newer WebView capabilities; the current Jetpack release page shows `androidx.webkit:webkit:1.15.0`. [CITED: https://developer.android.com/reference/android/webkit/WebViewClient.html] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] [CITED: https://developer.android.com/jetpack/androidx/releases/webkit?hl=en] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Crosswake.Manifest.Types` | repo surface | Canonical manifest root, compatibility truth, capability registry, and route entries. | Use as the only Phoenix-side data contract for shell boot and bridge allowlists. [VERIFIED: lib/crosswake/manifest/types.ex] |
| `Crosswake.Compatibility` + `RouteGate` | repo surface | Layered route activation checks and fail-closed decisions. | Use for both native activation gating and test fixtures for denied routes. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/compatibility/route_gate.ex] |
| `Crosswake.Doctor` surfaces | repo surface | Shared diagnostics vocabulary, severity sorting, and operator-facing output. | Use for manifest/shell/bridge setup findings and proof-lane failures. [VERIFIED: lib/crosswake/doctor/doctor.ex] [VERIFIED: lib/crosswake/doctor/check.ex] [VERIFIED: lib/crosswake/doctor/formatter.ex] |
| `mix crosswake.gen.shell` | repo surface | Host-owned native project generation seam. | Evolve this task instead of adding a second shell generator. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manifest-first native activation | WebView-first boot then JS handoff | Reject this; it delays safety checks until after web content loads and violates locked Decisions D-05 through D-10. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |
| AndroidX WebKit `addWebMessageListener` | `addJavascriptInterface()` | Reject broad `addJavascriptInterface()` for the primary bridge because Android warns it exposes a Java object to all frames; keep it only as an explicit fallback if ever required later. [CITED: https://developer.android.com/reference/android/webkit/WebView.html] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] |
| Single manifest-owned route truth | Separate path-rule overlay | Reject a second routing system in Phase 3 because the context explicitly defers it. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
# Android shell module
# implementation("androidx.webkit:webkit:1.15.0")
```

**Version verification:** Repo dependency versions were verified from [`mix.exs`](/Users/jon/projects/crosswake/mix.exs:6). AndroidX WebKit `1.15.0` was verified from the official Jetpack release page during this session. [VERIFIED: mix.exs] [CITED: https://developer.android.com/jetpack/androidx/releases/webkit?hl=en]

## Architecture Patterns

### System Architecture Diagram

```text
App launch / universal link / App Link / notification tap
  -> Native entry handler (iOS Scene/AppDelegate | Android Activity intent)
  -> ActivationRequest {url, source, route_id?, origin, manifest_source}
  -> Manifest loader (bundled -> cached)
  -> Compatibility + RouteGate evaluation
      -> deny -> Native RouteUnavailable screen + debug details
      -> allow
         -> runtime = :live_view
            -> bounded WKWebView / WebView
            -> same-origin navigation delegate
            -> typed bridge adapter
         -> runtime = :native_screen or :offline_island
            -> explicit unsupported screen in Phase 3
```

The key planning rule is that every inbound path becomes an `ActivationRequest` before a web container exists. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

### Recommended Project Structure

```text
lib/
├── crosswake/shell/activation.ex        # shared activation request + denial vocabulary [ASSUMED]
├── crosswake/shell/fixtures.ex          # bundled shell fixture/export helpers [ASSUMED]
├── crosswake/bridge/envelope.ex         # typed request/reply structs and validation [ASSUMED]
├── crosswake/bridge/registry.ex         # route + capability allowlist lookup [ASSUMED]
└── mix/tasks/crosswake.gen.shell.ex     # real native project generation entrypoint

priv/
└── templates/crosswake/shell/           # Xcode / Gradle project templates [ASSUMED]

native/
├── ios/crosswake_shell/                 # host-owned Xcode app project output [ASSUMED]
└── android/crosswake_shell/             # host-owned Gradle app module output [ASSUMED]

test/
├── crosswake/shell/                     # activation and denial tests [ASSUMED]
├── crosswake/bridge/                    # envelope, registry, and denial tests [ASSUMED]
└── mix/tasks/                           # generator assertions
```

This split follows the repo’s existing pattern of small single-purpose Elixir modules and focused tests while keeping native output host-owned and reviewable. [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: lib/crosswake/compatibility/route_gate.ex] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs]

### Pattern 1: Native-First Activation Pipeline
**What:** Normalize every app entry into a typed activation request, then resolve and gate it before creating or reusing a web container. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

**When to use:** App cold start, resumed universal link/App Link, notification tap, and in-app URL navigation. [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about]

**Example:**
```elixir
# Source: project pattern derived from RouteGate + Manifest.Types
%ActivationRequest{
  route_id: "dashboard",
  url: "https://example.com/dashboard",
  origin: "https://example.com",
  source: :deep_link,
  manifest_source: :bundled
}
|> Crosswake.Shell.Activation.resolve(manifest, target)
```

### Pattern 2: One Denial Vocabulary Across Elixir and Native
**What:** Keep route-activation denials and bridge denials on the same stable reason set: compatibility mismatch, undeclared capability, unavailable capability, origin denied, inactive route. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

**When to use:** Route unavailable screens, bridge replies, doctor findings, and proof fixtures. [VERIFIED: lib/crosswake/doctor/check.ex] [VERIFIED: lib/crosswake/doctor/formatter.ex]

**Example:**
```elixir
# Source: project pattern from lib/crosswake/compatibility/compatibility.ex
%{
  reason: :origin_denied,
  route_id: "dashboard",
  required: ["https://example.com"],
  available: "https://evil.example"
}
```

### Pattern 3: Typed Request/Reply Bridge Only
**What:** Bridge envelopes should carry protocol version, command, route ID, origin, correlation ID, and payload; replies should return `ok` or typed denial/error, never side effects plus opaque strings. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

**When to use:** `app.info.get`, `haptics.impact`, and `files.pick` only in Phase 3. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

**Example:**
```json
{
  "protocol": "crosswake.bridge",
  "version": "1.0.0",
  "route_id": "dashboard",
  "origin": "https://example.com",
  "command": "app.info.get",
  "capability": "app.info.get",
  "correlation_id": "01JV9X...",
  "payload": {}
}
```

### Pattern 4: Generator Owns Scaffolding, Not Lifecycle
**What:** Keep generator behavior scaffold-once and idempotent where possible, but do not claim safe regeneration of host-edited native apps. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

**When to use:** `mix crosswake.gen.shell` template upgrades and docs. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs]

### Anti-Patterns to Avoid
- **Placeholder shell inflation:** Do not keep Phase 1 text stubs and layer runtime promises around them; replace them with real Xcode/Gradle app projects. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex]
- **WebView as routing authority:** Do not let in-page JS decide runtime ownership or denial fallback. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
- **Global bridge exposure:** Do not expose native commands to all origins or all frames. [CITED: https://developer.android.com/reference/android/webkit/WebView.html] [CITED: https://webkit.org/blog/10882/app-bound-domains/]
- **Silent fallback to generic web container:** Unsafe routes must land on explicit denial UI. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route gating | A second mobile-only rule engine | `Crosswake.Compatibility` + `Crosswake.Compatibility.RouteGate` | The repo already has layered version/capability/origin checks and a fail-closed decision shape. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/compatibility/route_gate.ex] |
| iOS JS/native bridge | Custom string eval tunnel | `WKUserContentController` message handlers and navigation policy delegates | Apple exposes these as the standard JS bridge and navigation interception surfaces. [CITED: https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc] [CITED: https://developer.apple.com/documentation/WebKit/WKNavigationDelegate/webView%28_%3AdecidePolicyFor%3AdecisionHandler%3A%29-2ni62] |
| Android primary bridge | Broad `addJavascriptInterface()` plugin bus | AndroidX WebKit `addWebMessageListener` with allowed origins | Android’s docs warn that `addJavascriptInterface()` injects into all frames; AndroidX WebKit gives origin-aware message listeners with replies. [CITED: https://developer.android.com/reference/android/webkit/WebView.html] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat.WebMessageListener] |
| Deep-link routing heuristics | Per-screen ad hoc URL parsing | OS universal links/App Links -> one `ActivationRequest` normalization seam | Both platforms deliver incoming verified links to app entrypoints that should be normalized centrally. [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about] |
| Diagnostics surface | Separate native-only error taxonomy | `Crosswake.Doctor.Check`-style codes, hints, severities, and details | The existing doctor surface is already the product’s operator truth vocabulary. [VERIFIED: lib/crosswake/doctor/check.ex] [VERIFIED: lib/crosswake/doctor/formatter.ex] |

**Key insight:** Phase 3 should extend existing contract surfaces into native runtime code, not invent parallel mobile-only truth. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/research/ARCHITECTURE.md]

## Common Pitfalls

### Pitfall 1: WebView-First Boot
**What goes wrong:** The app loads a URL immediately, then tries to infer route ownership or deep-link intent from in-page JavaScript. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
**Why it happens:** It looks faster to reuse a generic WebView shell than to normalize route activation first. [VERIFIED: .planning/STATE.md]
**How to avoid:** Make route activation a native pipeline whose output is either denial UI or a declared runtime mount. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
**Warning signs:** Route denials happen after HTML loads, or unsupported routes render in a generic container. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

### Pitfall 2: Android Bridge Exposure Through All Frames
**What goes wrong:** Bridge calls become reachable from iframes or non-allowlisted origins. [CITED: https://developer.android.com/reference/android/webkit/WebView.html]
**Why it happens:** `addJavascriptInterface()` injects the object into all frames and is easy to overuse as a generic plugin bus. [CITED: https://developer.android.com/reference/android/webkit/WebView.html]
**How to avoid:** Prefer AndroidX WebKit `addWebMessageListener`, check `sourceOrigin`, require `isMainFrame`, and bind allowed origin rules from manifest truth. [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat.WebMessageListener] [VERIFIED: lib/crosswake/manifest/types.ex]
**Warning signs:** Wildcard origins, bridge handlers with no route context, or bridge requests that arrive before route activation completes. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

### Pitfall 3: iOS Domain Drift
**What goes wrong:** The shell’s WebKit bridge works on domains the app did not mean to trust, or bridging breaks once privacy restrictions are tightened. [CITED: https://webkit.org/blog/10882/app-bound-domains/]
**Why it happens:** `WKWebView` is easy to treat like a generic in-app browser, but App-Bound Domains deliberately restrict powerful APIs to declared domains. [CITED: https://webkit.org/blog/10882/app-bound-domains/]
**How to avoid:** Keep first-party shell browsing same-origin, use associated domains for app entry, and plan App-Bound Domains as the recommended default posture for trusted content. [CITED: https://developer.apple.com/documentation/xcode/supporting-associated-domains?preferredLanguage=occ] [CITED: https://webkit.org/blog/10882/app-bound-domains/]
**Warning signs:** External auth/help/support domains loaded in the same bridged container without explicit browser handoff rules. [CITED: https://webkit.org/blog/10882/app-bound-domains/]

### Pitfall 4: Generator Claims That Exceed Ownership Reality
**What goes wrong:** The public install path implies Crosswake can safely re-own native projects after users edit them. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
**Why it happens:** Shell generators often drift into black-box ownership. [VERIFIED: prompts/crosswake-elixir-oss-dna.md]
**How to avoid:** Keep native projects host-owned, document patch/manual upgrade paths, and test generation output rather than regeneration magic. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs]
**Warning signs:** Commands named “sync shell” or templates that overwrite user-edited project files. [ASSUMED]

## Code Examples

Verified patterns from official and repo sources:

### Route Gate Before Container Mount
```elixir
# Source: lib/crosswake/compatibility/route_gate.ex
target = %Crosswake.Compatibility.Target{
  manifest_schema_version: "1.0.0",
  bridge_protocol_version: "1.0.0",
  native_runtime_version: "1.0.0",
  origin: "https://example.com",
  manifest_source: :bundled,
  capabilities: %{"app.info.get" => "1.0.0"}
}

decision = Crosswake.Compatibility.RouteGate.evaluate(manifest, "dashboard", target)
```

### iOS Navigation Interception
```swift
// Source: https://developer.apple.com/documentation/WebKit/WKNavigationDelegate/webView%28_%3AdecidePolicyFor%3AdecisionHandler%3A%29-2ni62
func webView(
  _ webView: WKWebView,
  decidePolicyFor navigationAction: WKNavigationAction,
  decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
) {
  // normalize URL -> ActivationRequest, then allow or cancel
}
```

### Android Origin-Scoped Web Message Listener
```kotlin
// Source: https://developer.android.com/reference/androidx/webkit/WebViewCompat
WebViewCompat.addWebMessageListener(
  webView,
  "CrosswakeBridge",
  setOf("https://example.com"),
  JavaScriptExecutionWorld.DEFAULT,
  listener
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Placeholder shell text files | Real host-owned Xcode and Gradle app projects | Phase 3 locked decision set on 2026-05-14. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] | Proof lanes start matching what adopters actually ship. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |
| Generic JS/native message bus | Typed semantic request/reply bridge | Project thesis and Phase 3 decisions keep the bridge low-frequency and versioned. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] | Better testability, smaller trust surface, and clearer denials. [VERIFIED: .planning/research/ARCHITECTURE.md] |
| WebView-first route handoff | Manifest-first activation request | Phase 3 Decisions D-05 through D-10. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] | Unsafe routes can fail closed before any content loads. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |
| Broad bridge APIs on arbitrary domains | Origin-scoped handlers and first-party hosting | Current Apple and Android guidance favors explicit origin/domain controls. [CITED: https://webkit.org/blog/10882/app-bound-domains/] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] | Security posture becomes explainable and testable. [VERIFIED: .planning/PROJECT.md] |

**Deprecated/outdated:**
- Placeholder Phase 1 shell fixtures as the primary native artifact are outdated for Phase 3 implementation work. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex]
- Broad `addJavascriptInterface()` as the default Android bridge posture is outdated for this project’s bounded-bridge contract. [CITED: https://developer.android.com/reference/android/webkit/WebView.html] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The planner should introduce new Elixir modules under `lib/crosswake/shell/*` and `lib/crosswake/bridge/*` instead of another naming split. | Recommended Project Structure | Low; the exact module names can move without changing the contract design. |
| A2 | Native generated output should live under `native/ios/crosswake_shell` and `native/android/crosswake_shell` after the Phase 3 upgrade. | Recommended Project Structure | Low; the generator can choose different output roots if docs/tests stay aligned. |
| A3 | A shell-aware proof slice should include native denial fixtures even though full cross-platform CI proof lanes remain a later requirement. | Summary / likely plan slices | Medium; if deferred too far, Phase 3 support claims may get ahead of proof. |
| A4 | Commands or templates that overwrite user-edited native project files are a realistic warning sign to watch for during implementation. | Common Pitfalls | Low; this is a heuristic, not a contract requirement. |
| A5 | Push/replace/modal defaults stay native-code policy in Phase 3 without new manifest presentation metadata. | Resolved | Low; the plan keeps presentation defaults in native code unless activation truth would otherwise drift from the manifest-driven path. |
| A6 | The generated iOS shell adopts App-Bound Domains in Phase 3 as the default posture for trusted LiveView hosting. | Resolved | Low; first-party same-origin hosting aligns with the locked security posture, so the plan treats App-Bound Domains as required rather than optional hardening. |

## Open Questions (RESOLVED)

1. **How much manifest metadata is needed for native presentation defaults?**
   - What we know: The context defers any separate path-rule overlay and allows only minimal manifest-backed metadata if unavoidable. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]
   - Resolution: Keep push/replace/modal defaults in native code for Phase 3. They may key off runtime and denial state, but they must not introduce a second routing or presentation-truth system. Add manifest presentation metadata only if a concrete activation-truth test proves the native defaults would drift from manifest-owned route ownership. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

2. **Should iOS adopt App-Bound Domains in the first implementation slice or as a hardening follow-up inside Phase 3?**
   - What we know: App-Bound Domains restrict powerful `WKWebView` APIs to declared domains and fit Crosswake’s first-party shell posture. [CITED: https://webkit.org/blog/10882/app-bound-domains/]
   - Resolution: Treat App-Bound Domains as a Phase 3 hardening requirement for trusted iOS LiveView hosting. The generated Xcode baseline should declare the app-bound domains and the `WKWebView` container should stay first-party and same-origin. External web flows that would require broader browsing authority remain out of scope for this phase and must not weaken the default posture. [CITED: https://webkit.org/blog/10882/app-bound-domains/] [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Mix / Elixir | Manifest, generator, compatibility, tests | ✓ | `Mix 1.19.5`, `OTP 28` | — [VERIFIED: local command] |
| Xcode | iOS shell generation and XCTest/build verification | ✓ | `Xcode 26.0.1` | — [VERIFIED: local command] |
| Swift | iOS shell source compilation | ✓ | `Swift 6.2` | — [VERIFIED: local command] |
| Java runtime | Android shell build | ✗ | — | None [VERIFIED: local command] |
| Gradle | Android shell build | ✗ | — | None [VERIFIED: local command] |
| `adb` | Android emulator/device smoke tests | ✗ | — | None [VERIFIED: local command] |

**Missing dependencies with no fallback in the current shell session:**
- Android execution proof is currently blocked on a local Java runtime, Gradle, and `adb`; the Phase 3 plan therefore needs a generated-project proof hook that provisions or locates the standard Android toolchain before claiming support. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Respect Phoenix-owned session/auth state at activation time; do not let deep links bypass server-authenticated route truth. [VERIFIED: .planning/research/ARCHITECTURE.md] |
| V3 Session Management | yes | Keep LiveView hosting same-origin and route browser-only or external content out of the bridged container. [VERIFIED: lib/crosswake/manifest/builder.ex] [CITED: https://webkit.org/blog/10882/app-bound-domains/] |
| V4 Access Control | yes | Enforce route allowlists, capability allowlists, active-route checks, and fail-closed denials. [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] |
| V5 Input Validation | yes | Validate bridge envelope fields, manifest versions, route IDs, origins, and command payloads before side effects. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/doctor/check.ex] |
| V6 Cryptography | no | Use platform TLS, verified App Links/universal links, and never add custom crypto in Phase 3. [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Deep-link parameter abuse | Spoofing / Tampering | Normalize URLs into `ActivationRequest`, validate route presence, and deny before container mount. [CITED: https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app] [CITED: https://developer.android.com/training/app-links/about] |
| Cross-frame bridge injection | Elevation of Privilege | Require origin-scoped listeners, main-frame checks, and manifest allowlists. [CITED: https://developer.android.com/reference/android/webkit/WebView.html] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat.WebMessageListener] |
| Capability escalation from undeclared routes | Elevation of Privilege | Use manifest `capability_registry` plus per-route capability lists as the only allowlist source. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| Silent compatibility drift | Tampering / DoS | Gate on manifest schema, bridge protocol, native runtime version, and manifest source before activation. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] |
| Unsafe fallback to generic container | Information Disclosure | Show explicit route-unavailable surfaces instead of partially loading unsupported content. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- [`mix.exs`](/Users/jon/projects/crosswake/mix.exs:6) - repo dependency baselines and package posture
- [`03-CONTEXT.md`](/Users/jon/projects/crosswake/.planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md:1) - locked Phase 3 scope and decisions
- [`lib/crosswake/manifest/types.ex`](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex:1) - manifest root, compatibility, route, and capability shapes
- [`lib/crosswake/manifest/builder.ex`](/Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex:1) - route-first manifest assembly and origin allowlists
- [`lib/crosswake/compatibility/compatibility.ex`](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex:1) - layered compatibility checks
- [`lib/crosswake/compatibility/route_gate.ex`](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex:1) - fail-closed decision surface
- [`lib/crosswake/doctor/doctor.ex`](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex:1) - structured diagnostics orchestration
- [`lib/mix/tasks/crosswake.gen.shell.ex`](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:1) - current shell generation seam
- [`test/mix/tasks/crosswake_gen_shell_test.exs`](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_gen_shell_test.exs:1) - current generator ownership assertions
- [`test/support/router_fixtures.ex`](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:40) - representative route/runtime/capability fixtures
- https://developer.apple.com/documentation/Xcode/supporting-universal-links-in-your-app - iOS universal-link entry handling
- https://developer.apple.com/documentation/webkit/wkusercontentcontroller?language=objc - iOS message-handler bridge surface
- https://developer.apple.com/documentation/WebKit/WKNavigationDelegate/webView%28_%3AdecidePolicyFor%3AdecisionHandler%3A%29-2ni62 - iOS navigation allow/cancel hook
- https://developer.android.com/training/app-links/about - Android App Links behavior and verification
- https://developer.android.com/reference/android/webkit/WebViewClient.html - Android navigation interception
- https://developer.android.com/reference/androidx/webkit/WebViewCompat - AndroidX WebKit message-listener API
- https://developer.android.com/reference/androidx/webkit/WebViewCompat.WebMessageListener - source origin and reply details

### Secondary (MEDIUM confidence)
- https://developer.android.com/develop/ui/views/layout/webapps/webview - Android WebView guidance and `addJavascriptInterface()` caution
- https://developer.android.com/reference/android/webkit/WebView.html - Android `addJavascriptInterface()` security warning
- https://developer.android.com/jetpack/androidx/releases/webkit?hl=en - AndroidX WebKit current stable release reference
- https://developer.apple.com/documentation/xcode/supporting-associated-domains?preferredLanguage=occ - iOS associated domain setup
- https://webkit.org/blog/10882/app-bound-domains/ - WebKit App-Bound Domains security posture

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo dependencies, existing contract surfaces, and platform APIs were all verified directly. [VERIFIED: mix.exs] [VERIFIED: lib/crosswake/manifest/types.ex] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat]
- Architecture: HIGH - the phase context, roadmap, project state, and repo architecture docs all align on manifest-first, fail-closed shell design. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/research/ARCHITECTURE.md]
- Pitfalls: HIGH - the main failure modes are directly supported by locked decisions plus Apple/Android WebView guidance. [VERIFIED: .planning/phases/03-native-shell-boot-and-bounded-bridge/03-CONTEXT.md] [CITED: https://developer.android.com/reference/android/webkit/WebView.html] [CITED: https://webkit.org/blog/10882/app-bound-domains/]

**Research date:** 2026-05-14
**Valid until:** 2026-06-13
