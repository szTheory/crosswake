---
id: SEED-006
status: triggered
planted: 2026-07-27
triggered: 2026-08-03
planted_during: "Phase 153 iOS mirror unblock (v20.0 Native Controls Pack 1) — planted alongside SEED-005 while the native-shell + control vocabulary is fresh"
trigger_when: "Surface during Native Navigation Shell milestone planning, or whenever the roadmap turns to native app-shell chrome (tab bars / nav stacks), consumer-grade 'feels-native' fidelity, or a `nav_graph` in the manifest."
scope: Large
---

# SEED-006: Give Phoenix apps a native navigation shell (native tab bar + nav stack over LiveView content)

## Activation Update — First-Adopter Fast Track

The trigger is now satisfied by sanitized First B2C Adopter design evidence: the public-v1 shell
requires a small set of stable root tabs, pushed detail routes, and a long route-local study flow
whose `push_patch` transitions must not create native frames. This is adopter infrastructure, not
generic native-control breadth.

The activated v21 slice is intentionally narrower than this seed's original cross-platform
milestone:

- iOS first: host-owned native tabs, pushed details, edge-swipe/back, deep-link restoration needed
  by confirmed sanitized routes, accessibility focus handoff, and executable proof;
- a native-authoritative, versioned shell-navigation protocol in which `push_patch` is a native
  stack no-op and `push_navigate` is idempotent transition intent;
- synchronous declarative shell presence on the document root plus live safe-area CSS variables;
  keyboard occlusion remains a separate variable, not a safe-area mutation; and
- Android implementation, predictive-back proof, parity work, broad positioning, and generic
  navigation-framework claims remain outside v21.

Phase 161.1 is the urgent insertion for this bounded slice. The full Android renderer and any
generalized multi-adopter navigation product remain residual future work. The route graph cannot
be populated from guesses: TODO-002 must first receive sanitized route-policy rows.

## Thesis + Positioning Shift (read this first)

**Thesis (one sentence):** Add a real native tab bar + navigation stack on iOS/Android that hosts Crosswake routes — the route/**nav graph declared once** in the manifest and rendered per-platform (native = real `UITabBar`+nav stack; web = its own idiom, e.g. hamburger) — so Phoenix apps feel native at the navigation seams users actually touch, à la Hotwire Native, while content stays server-driven LiveView.

**Positioning shift (explicit north-star, decided 2026-07-27):** This moves Crosswake's stated position toward **consumer-grade "feels-native"** — but the honest claim is **native *shell* fidelity, not native *app parity*.** Own the lane: *"Native navigation, native transitions, native screens where they matter — powered by your Phoenix app. Feels native. Ships from Phoenix."* Never claim "indistinguishable from native" (no web-content framework can, and Hotwire Native explicitly doesn't). Crosswake's existing emulator-evidence/support-truth discipline is the moat that lets it say "feels native" *more* credibly than competitors who assert it without proof — by gating the claim behind a new **native-shell-proven** tier. The brand-doc edits this implies are enumerated below as **follow-on work, NOT done in this seed.**

## You Are Here — Decided / Open / Where to look

**DECIDED (durable):**
- Native nav is a **shell-level** concern, NOT a bounded-bridge concern. The route-policy "navigation authority is a non-use-case for the bridge" rule is about the one-shot request/reply *bridge*; a nav container is stateful chrome that lives in the host-owned shell. No conflict with the architecture.
- Feasibility verdict: **no architectural blocker; a bounded additive extension.** The Crosswake library is a pure resolver; all rendering is host-owned; there is zero existing nav container to displace.
- Shape: keep the per-screen resolver/`ShellPresentation` **leaf** unchanged; add a container-level nav description; add an **additive ordered `nav_graph` manifest section** (modeled on the existing `commerce_corridors` precedent) + a route-level `nav:` authoring hint; **compiled + drift-gated, NOT remotely served.**
- Native chrome = **UIKit `UITabBarController` + per-tab `UINavigationController`** (iOS) / **single-Activity + Jetpack Navigation + `NavigationBarView`** (Android), host-owned generated code — the mature, Hotwire-proven choice for webview hosting in 2025 (not SwiftUI `NavigationStack`/Nav3 yet).
- Its own milestone ("Native Navigation Shell," `vNN.0`), peer of the controls packs.

**OPEN (must be resolved when the milestone is planned — do NOT treat as settled):**
- **The web↔native back-stack sync subsystem** (§The Hard Problem). Direction is clear (native stack authoritative), but the full reconcile protocol, LiveView `push_navigate`/`push_patch` interception, and back-gesture correctness are genuine design work.
- **The acceptable fidelity degree** — exactly where "feels native ~90-95%" lands and which screens must upgrade to `:native_screen`.
- **Tab-webview lifecycle default** (lazy+retain vs warm-pool) and the LiveView socket-per-tab budget.
- The **positioning brand-doc edits** (enumerated, not yet applied) — a real decision to ratify at activation.

**WHERE TO LOOK:** the `## Breadcrumbs` anchors below (code seams + prior art). Adjacent: [SEED-005](SEED-005-themable-web-control-equivalents.md) (themable web *controls* — a different axis; it explicitly EXCLUDES nav, which is why SEED-006 exists).

## Why This Matters

Web-rendered navigation — especially a hamburger menu — is the #1 tell that reads as "a website in an app." Native apps use a **bottom tab bar** for primary nav (thumb-reachable, instant, always visible) and native push/pop with the platform back gesture; that chrome is where "webby" is most detectable and where Crosswake can make things *actually native*. Today Crosswake keeps nav web-owned and its native shell is a thin single-screen host — so a Phoenix app built on it cannot present native tabs/stack, capping how native it can feel.

The reconciliation that makes this coherent (not a betrayal of the architecture): **Crosswake's core ideas compose with a nav shell unusually well.** The **manifest is already the single source of truth** for routes → it's the natural home to declare the nav graph once and render it per-platform. **Per-route ownership is literally the Hotwire Native model:** a native tab bar / nav stack is the container, and each screen it presents is filled by whatever Crosswake says owns that route (a `:live_view` webview or a `:native_screen`). The `RouteDelegate` registry that already lets native + web routes coexist is the exact seam to generalize from "one native screen" to "a nav container hosting many web/native screens."

## When to Surface

**Trigger:** Surface during Native Navigation Shell milestone planning, or whenever the roadmap turns to native app-shell chrome (tab bars / nav stacks), consumer-grade "feels-native" fidelity, or adding a `nav_graph` to the manifest.

Present during `$gsd-new-milestone` when the milestone scope matches any of these:
- the maintainer wants Phoenix apps to feel like polished consumer-grade native apps (native tabs, native transitions, native back gesture)
- the roadmap turns to the native SHELL's responsibilities beyond single-screen activation (nav container, multi-screen, back stack)
- planning turns to declaring navigation structure (tabs/stacks/deep-links) as manifest truth
- an explicit positioning decision toward consumer-grade "feels-native" is on the table
- adopter evidence shows teams blocked by web-only navigation / hamburger menus feeling un-native

## Scope Estimate

**Large** — its own milestone family (multiple phases): the `nav_graph` declaration + manifest section + validator; the native nav chrome in the host-owned shell (reintroducing webview hosting, growing the presentation model); the **web↔native back-stack sync subsystem** (the hard part); the webview + LiveView-socket lifecycle; accessibility across the native/web seam; a four-tier proof strategy; and the positioning/support-truth work. Depends on the v20 `Bridge.push/3` seam and shell maturity.

## Breadcrumbs

Code seams, decisions, and prior art (deep multi-lens research fan-out — 3 codebase + 10 stakeholder/ecosystem subagents, 2026-07-27). Anchors are file + symbol (line numbers are as-of-date and may drift):

**In-repo — the shell seam (host-owned rendering; pure resolver):**
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift` — `resolve(request:manifest:)` → one flat `ShellPresentation` (`.booting|.requiredPack|.nativeCapture|.liveView|.denied`); the library never renders. Android mirror `ActivationCoordinator.kt`.
- `packages/crosswake-shell-core-ios/.../CrosswakeDelegates.swift` — the `RouteDelegate` registry (`isRouteRegistered`, `registeredRoutes`); the native+web coexistence seam to generalize into a nav container.
- `crosswake-0.1.0/priv/templates/crosswake/shell/ios/LiveViewContainerViewController.swift.eex` + `.../android/.../LiveViewFragment.kt.eex` + `MainActivity.kt.eex` — the REAL WKWebView/WebView hosting (uses `.replace` with **no `addToBackStack`**). NOTE (2026-07-27): the shipping v2 generator (`lib/mix/tasks/crosswake.gen.shell.ex`) scaffolds only a state-display STUB — this hosting must be reintroduced/extended.
- `lib/mix/tasks/crosswake.gen.shell.ex` — scaffold-once, host-owned, `--diff` upgrade verb + `RebuildPolicy` OTA-safe/rebuild-required classification; where native nav chrome generates.

**In-repo — the manifest/route seam (declare the nav graph):**
- `lib/crosswake/policy/schema.ex` — the closed `crosswake:` route-policy NimbleOptions schema; where a route-level `nav:`/`presentation:` hint lands (additive → minor bump).
- `lib/crosswake/manifest/types.ex` (`Root`) + `lib/crosswake/manifest/validator.ex` (`validate_route_commerce_corridor_ref` idiom) + `builder.ex` — **`commerce_corridors` is the additive-top-level-section precedent** for an ordered `nav_graph` section; the validator pattern for dangling-ref + determinism checks to copy.
- `lib/crosswake/shell/activation.ex` — segment-wise URL→route path matching (deep-link resolution).
- `lib/crosswake/shell/denial.ex` — the typed denial vocabulary nav failure modes must reuse (never bespoke nav errors).
- **The web↔native navigation-intent seam does not exist yet** and must be built on `Crosswake.Bridge.push/3` (`lib/crosswake/bridge.ex`). CORRECTION (Phase 154, D-71/D-72): this bullet previously named `examples/phoenix_host/assets/js/app.js` as an *existing* nav-intent seam with a `transition` primitive and an `:in_app_navigation` source. That premise was false. The file was never served (absent from the endpoint's `Plug.Static` allowlist; the example host has no bundler), used a handler name (`crosswake`) neither shell registers, referenced a `window.CrosswakeAndroidBridge` object that exists nowhere, and its `{action, payload, timestamp}` message shape shared zero fields with the bridge wire contract. It was deleted in Phase 154. A navigation-intent control would be a NEW entry in the bounded command vocabulary (`Crosswake.Bridge.Contract.commands/0` + both native `BridgeCommand` enums, which `Crosswake.Bridge.CatalogGuard` holds in bidirectional parity) — plan it as new native work, not as generalizing something already shipped.

**Prior art:**
- [Hotwire Native path configuration](https://native.hotwired.dev/reference/path-configuration) + [navigation reference](https://native.hotwired.dev/reference/navigation) + [Masilotti's TurboNavigator](https://github.com/joemasilotti/TurboNavigator) — the direct template (path-config-as-graph, VisitProposal delegate, `state × context × presentation` matrix, per-tab session).
- [go_router `StatefulShellRoute`](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html) (per-tab independent stacks) + [React Navigation static API](https://reactnavigation.org/blog/2024/03/25/introducing-static-api/) (nav-as-config; and the *cautionary* nested-navigator deep-link pain).
- [Apple HIG tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) + [Material 3 navigation bar](https://m3.material.io/components/navigation-bar/guidelines) + [Android predictive back](https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back).
- [WKWebView VoiceOver focus-reset bug](https://github.com/matt-curtis/WKWebView-Voiceover-Focus-Reset-Bug-Demonstration) (the a11y seam hazard); [LiveView live-navigation](https://hexdocs.pm/phoenix_live_view/live-navigation.html) + [reconnect strategies](https://swmansion.com/blog/the-problem-of-reconnects-in-phoenix-live-view/) (the socket-lifecycle problem).

## Notes

Pre-staged **Native Navigation Shell** milestone (`vNN.0`, core-only). The design below is research-backed but the milestone must re-decide the OPEN items.

### Architecture reconciliation (durable)
Keep the pure resolver: `resolve(request, manifest) → ShellPresentation` stays the **per-destination leaf**, unchanged. Add a **container-level** description — `ShellNavigation` (ordered tabs, each `{routeId, title, symbol, stack: [ShellPresentation], selectedTab}`) produced by a new `resolveGraph(manifest) → ShellNavigation`. The Android coordinator's single `MutableStateFlow<ShellPresentation>` / iOS `@Published presentation` become the nav-graph stream; per-tab sessions replace the single session. **Nav chrome lives entirely in host-owned generated shell code** (`CrosswakeShellApp.swift`/`MainActivity.kt` + coordinator/viewmodel) — the library still only emits values, never a container.

### The nav-graph declaration (hybrid: route hints → ordered manifest section)
- **Route-level hint** (additive to `crosswake:` policy, all optional → minor bump): `nav: [tab: :home, icon: :house, title: "Home"]`, `nav: [present: :push, parent: :orders]`, `nav: [present: :modal]`. `present:` vocabulary borrowed from Hotwire: `push | modal | replace | replace_root | clear_all | native_screen`.
- **Central block** for structure/order that shouldn't smear across route lines: `crosswake_nav_graph do tabs [:home, :orders, :profile]; web present: :hamburger; native present: :tab_bar, back: :swipe end`. Tab list order = tab-bar order.
- Compile route hints INTO an **ordered** top-level `nav_graph` manifest section (a LIST for tabs — map order is not authoritative under the alphabetical serializer). Model on `commerce_corridors` but note nav is app-authored (arbitrary tabs), not a canonical fixed set.
- **Validate** (`validate_nav_graph/2`, reusing the corridor cross-ref + `%{key,message,hint}` idiom): every tab `root`/`stack`/`deep_links` id ∈ `routes`; unique tab ids + roots; a route in ≤1 stack; `present: :native_screen` only where `runtime: :native_screen`; deterministic ordering; additive versioning (absent `nav_graph` validates unchanged, no `manifest_schema_version` major bump).
- **Compiled + drift-gated, NOT remotely served.** Hotwire serves path-config remotely for release-free nav changes; that would bypass Crosswake's Validator + drift gate. Get the same benefit differently: the *compiled* nav_graph already rides the manifest's `[:bundled, :cached, :remote]` channel → release-free updates that stay validated.
- Deep links: a **flat** `route_id → path template` map (Crosswake resolves URLs segment-wise; avoid RN's hierarchy-mirroring nesting, the source of its deep-link bugs).

### The Hard Problem — web↔native back-stack sync (OPEN; the load-bearing subsystem)
The twist vs Hotwire: LiveView navigation is a *server-driven socket event*, not an HTTP request/response.
- **Source of truth: the native stack is authoritative; web history is subordinate and pruned to ~1 entry deep.** (LiveView reinforces this — `push_navigate` dismounts + remounts a fresh LiveView, so there's no persistent client history to preserve; each destination is naturally a fresh native screen.)
- **Intent protocol:** a client hook catches a `<.link navigate>` click / `push_navigate` BEFORE the socket round-trips, posts `{type:"transition", href, kind:"navigate"|"patch", requestId}` over the existing bridge; the native side resolves `href` through the nav_graph presentation table (Hotwire's `state × context × presentation → action` matrix, adopted verbatim), performs the stack op, THEN tells the webview to load with history *replaced* (not pushed). **`push_patch` MUST be a no-op for the native stack** (it only re-runs `handle_params` on the same screen) — this is the #1 LiveView-specific footgun (phantom native screens).
- **Back semantics:** iOS edge-swipe + nav-bar back → native pop (web history is 1-deep, nothing to reconcile). Android: **nav-bar/Up → `navigateUp()`; hardware/predictive back → `popBackStack()`** — they diverge on cold deep-link entry (`navigateUp` walks the synthetic parent chain and stays in-app; `popBackStack` on an empty stack must route home, never silently exit). Wire predictive-back (Android 14+) through `OnBackPressedDispatcher`.
- **Deep-link/restoration:** synthesize the FULL parent stack from the URL via the nav_graph (never drop the user on a rootless leaf); select the right TAB. Avoid RN's `initialRouteName`-ignored trap.
- **Socket continuity:** one LiveSocket per tab, persisted; screens within a tab share it. Add server helpers mirroring `recede_or_redirect_to` so LiveView can express "pop" intent.

### Native chrome + webview/socket lifecycle
- **iOS:** UIKit `UITabBarController` + one `UINavigationController` per tab; a shared/`per-tab` `WKWebView` swapped into `VisitableView`-style containers; SF Symbols tab items; `prefersLargeTitles` on stack roots (inline on pushed/modal); edge-swipe back is free from `interactivePopGestureRecognizer`. `:native_screen` pushes a plain `UIViewController` onto the same stack. Prefer UIKit over SwiftUI `NavigationStack` (iOS 18.4-era regressions; webview hosting needs `UIViewControllerRepresentable` anyway).
- **Android:** single-Activity + `NavHostFragment` + Material3 `NavigationBarView`, wired via `NavigationUI.setupWithNavController` (multiple back stacks per tab, predictive back, deep links built-in). Navigation3 (stable Nov 2025) is too new to bet the webview shell on.
- **Lifecycle default (OPEN, recommended):** lazy-create each tab's webview on first visit, **retain the webview instance** after (instant return), but **disconnect its LiveView socket when the tab is backgrounded/buried**, reconnect on foreground — bounds BEAM socket processes to *visited* tabs, not configured. Requires a **rehydration contract:** every LiveView reconnect-safe (state from URL params + PubSub/DB, guard on `get_connect_params(socket)["_mounts"]`; never trust cross-background `assigns`). Anti-flash: native skeleton per route + retained last-paint snapshot + a mandatory `webViewWebContentProcessDidTerminate` reload handler. Escape hatches: per-tab "eager warm" flag (home), stack-depth eviction threshold, opt-in keep-socket-alive for live tabs (chat), shared-webview low-memory mode.

### Accessibility (native chrome = win; the seam = hazard)
Native `UITabBar`/`BottomNavigationView` + `UINavigationController` give real tab/back/position traits and OS focus order for free (a genuine win over ARIA tablists). **BUT `WKWebView`/Android `WebView` reset or trap screen-reader focus on load** — so a tab switch or push lands focus unpredictably. Build a **focus-handoff bridge:** after the transition settles, post `.screenChanged`(iOS) / `ACTION_ACCESSIBILITY_FOCUS`(Android) targeting the webview's first heading, and **announce the destination route label** (the visual tab-selection cue has no audio equivalent across the seam). Emit one a11y contract per route from a single Elixir source → native traits AND ARIA (labels/selected/position); keep tab labels == the in-webview `<h1>`. Bridge `isReduceMotionEnabled`/animator-scale + RTL into the webview as CSS media/`dir`. Manual VoiceOver+TalkBack tab-and-push focus test is required UAT (not auto-caught).

### One graph → three idioms (HIG)
Portable 1:1: the section list, per-section stacks, "detail push" semantics. Platform-specific (renderer owns, NOT in the schema): the primary-nav container (iOS tab bar / Android bottom-nav-or-rail-by-width / web top-nav-or-drawer), the back affordance (edge-swipe / predictive-back / browser-back), per-screen primary action (FAB is Android-only), task-flow presentation (iOS sheet / Android full-screen dialog / web modal). **Keep primary sections to 3–5** (the iOS tab-bar constraint; satisfy it and Android/web follow). **Hamburger:** wrong as *primary* nav on native (esp. iOS — no drawer idiom; ~40% slower task completion vs tabs); fine for *secondary/long-tail* nav, Android drawer for long grouped lists, and web narrow-width collapse. Icons are semantic tokens (`:house`), mapped to SF Symbols / Material per-platform in generated chrome — never platform asset paths in the DSL. Emit safe-area insets (notch/Dynamic Island/home indicator) to LiveView.

### Proof strategy (four honest tiers — maps onto Crosswake's support-truth discipline)
- **Proven (hermetic, merge-blocking):** nav_graph compiles/validates/serializes deterministically (golden snapshot); intent-protocol wire-schema round-trips; `route → presentation` mapping totality; `deep_link → [stack frames]` reducer; **and "a LiveView link emits the correct intent"** via a bridge-message spy (instrumented build tapping the `WKScriptMessageHandler`/`@JavascriptInterface`). Assert the *message*, not pixels — this collapses the flaky boundary test into a deterministic one. The earlier UA-marker assumption is rejected: the harness must inject the same synchronous document-root shell marker as production, and tests must prove the marker exists before app CSS evaluates.
- **Emulator evidence (advisory):** XCUITest / Espresso+UI Automator drive the real tab bar / back-pop / deep-link-rebuild against **stable accessibility identifiers** (never labels), with current-route + stack-depth exposed as accessibility values to assert state.
- **Device-only (declare unprovable):** true gesture/interactive-pop fidelity, per-OEM back quirks, animation feel, real OS cold-start deep-link. Never let a green sim lane imply device fidelity.
- Add a **support-matrix row per claim** ("native push from web link", "deep-link stack rebuild", "tab back-stack retention") with its tier badge.

### Positioning / support-truth (the north-star, with guardrails)
Commit to **"native navigation shell, web-powered content, native where it matters — feels native, ships from Phoenix."** Claim native **shell** fidelity, never app parity or "indistinguishable." Scope "consumer-grade" to content/nav-driven apps (commerce, media, feeds, subscription/learning) — NOT GPU-custom-UI apps (games, pro-camera). Keep the "What this is not" list but **convert it from apology to stance** ("we tell you where the webview ends — that's why the native parts are actually native"). Add a **native-shell-proven** support tier so "feels native" is earned via the proof lanes, not asserted.
**Follow-on brand-doc edits (enumerate now, APPLY at milestone activation — NOT in this seed):** `brandbook/BRAND-SPEC.md` §1 (add native-shell-fidelity positioning + scoped "feels native" + consumer-grade audience) and its "What Crosswake is not" (reframe "not indistinguishable" as a deliberate honest ceiling); `README.md` "What this is not" (add an affirmative "what feels native" section) + the top one-liner (toward "native navigation shell for Phoenix apps"); `.planning/PROJECT.md` core-value/positioning; the support-truth label vocabulary (add the native-shell-proven tier).

### Requirement-category skeleton (for `/gsd-new-milestone`)
- **NAVG-*** — the declarative nav graph: route-level `nav:` hint + ordered `nav_graph` manifest section + `validate_nav_graph/2` (dangling-ref/determinism/presentation-coherence), compiled + drift-gated.
- **SHELL-*** — native nav chrome: `ShellNavigation` container value; host-owned generated `UITabBarController`+`UINavigationController` / `NavHost`+`NavigationBarView`; reintroduce/extend the 0.1.0 webview + native-screen hosting; generalize `RouteDelegate` to a nav container.
- **SYNC-*** — web↔native back-stack sync: native-authoritative stack, `push_navigate`/`push_patch` interception (`patch` = native no-op), Hotwire `state×context×presentation` matrix, back-gesture correctness (`navigateUp`/`popBackStack` split, predictive back), deep-link parent-stack synthesis + tab restoration.
- **LIFE-*** — webview + LiveView-socket lifecycle: lazy+retain webview, background socket disconnect, rehydration contract, anti-flash, escape-hatch flags.
- **A11Y-*** — the focus-handoff bridge; one-source a11y contract → native traits + ARIA; reduce-motion/RTL bridging; VoiceOver/TalkBack UAT.
- **PROOF-*** — the four-tier proof lanes + support-matrix rows per claim.
- **POS-*** — positioning/support-truth: the native-shell-proven tier + the ratified brand-doc edits.

Rough phase sketch: (1) NAVG — nav-graph declaration + manifest section + validator (hermetic, cheap, high-leverage first); (2) SHELL — native chrome + `ShellNavigation` + reintroduce hosting; (3) SYNC — the back-stack sync subsystem (the hard one); (4) LIFE + A11Y — lifecycle + the focus seam; (5) PROOF + POS — proof lanes + positioning ratification. Web renderer (hamburger/sidebar from the same graph) threads through phases 1–2.

### Constraints carried forward
- Native nav chrome is HOST-OWNED generated code (scaffold-once, `--diff` upgrade), never an importable component tier; the library stays a pure resolver emitting values.
- Nav validity is a **manifest invariant** (inherits doctor/compiler/gating/denial for free); route nav failures resolve through the existing `Shell.Denial`, never bespoke nav errors.
- Fail-closed; deterministic + drift-gated manifest; no remote ungoverned nav side-channel; don't drift into a generic plugin bus.
- Honesty: native SHELL fidelity, never app parity; every "feels native" claim earned via a proof tier.
