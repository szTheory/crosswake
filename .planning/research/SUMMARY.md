# Project Research Summary

**Project:** Crosswake
**Domain:** Phoenix-native mobile substrate library for iOS and Android apps
**Researched:** 2026-05-12
**Confidence:** HIGH

## Executive Summary

Crosswake should be built as a Phoenix-first policy compiler and runtime contract system, not as a shared UI framework. The consistent recommendation across the research is to keep Phoenix authoritative for route policy, manifest generation, compatibility truth, and server reconciliation, while iOS and Android shells own navigation chrome, native capabilities, local storage, background work, and native-only screens. The product should make runtime ownership explicit per route instead of promising “write once” behavior.

The recommended v1 approach is narrow and disciplined: ship a route policy DSL, compile it into a versioned manifest, enforce compatibility gates, provide thin native shells that can host LiveView routes, and expose only a small semantic bridge for allowlisted capabilities. Add explicit offline classes early, but do not claim true local-first support until one real offline island, one local journal/outbox, and one reconciliation seam are proven end to end.

The main risks are architectural drift and support dishonesty. If the bridge becomes a generic message bus, if offline is reduced to cache, or if support claims exceed example-host proof lanes, Crosswake will turn into an untestable WebView wrapper with a large blast radius. Mitigation is clear from the research: keep runtime boundaries explicit, fail closed on compatibility mismatch, ship doctor/diagnostic tooling early, and gate releases on deterministic proof lanes across Phoenix, iOS, and Android.

## Key Findings

### Recommended Stack

Crosswake should start as a monorepo with one Elixir core package plus in-repo iOS and Android shell libraries and example host apps. The stack choices are intentionally conservative: use current stable Phoenix/LiveView on the server, standard WebView primitives in native shells, SQLite-backed native stores for any real offline behavior, and explicit versioned JSON manifests as the contract across runtimes.

**Core technologies:**
- Elixir `1.19.x` + Erlang/OTP `28.x`: core library runtime and compiler baseline.
- Phoenix `1.8.x` + LiveView `1.1.x`: host framework and server-owned route runtime.
- Ecto `3.13.x` + NimbleOptions: manifest, policy, and config validation.
- Swift `6.2.x` + SwiftUI + `WKWebView`: iOS shell, native screens, and bounded bridge host.
- Kotlin `2.3.x` + Jetpack Compose + AndroidX WebKit: Android shell, native screens, and secure WebView bridge.
- GRDB.swift + Room: explicit SQLite-backed local storage for offline islands, drafts, journals, and packs.
- Telemetry + OpenTelemetry: domain events and cross-runtime tracing.
- GitHub Actions + release-please: proof lanes, release discipline, and support-matrix automation.

### Expected Features

The v1 table stakes are mostly contract features, not flashy native breadth. Teams should be able to declare route ownership, ship bounded device capabilities, handle deep links and notification entry, express offline behavior honestly, and verify compatibility before a route activates. The differentiators come later, once the base contracts stop moving.

**Must have (table stakes):**
- Route policy DSL with manifest generation and validation.
- Native shell contract for boot, navigation, lifecycle, and deep-link handoff.
- Bounded capability registry and typed bridge contract.
- Explicit offline policy per route, including cached-read and draft/outbox seams.
- Upload/download/media transfer seams at the contract level.
- Compatibility gating for manifests, binaries, bridge versions, and OTA-safe content.
- Security/privacy defaults for capabilities, caching, and route activation.
- Generators, doctor diagnostics, example hosts, and an honest support matrix.

**Should have (competitive):**
- One real offline island with local execution and reconciliation.
- Content/media packs tied to manifest and sync contracts.
- Native screen adapters for device-heavy flows.
- Phoenix-mounted diagnostics and manifest inspection UI.
- Route-class telemetry and rollout/kill-switch seams.

**Defer (v2+):**
- Broad companion ecosystem beyond the highest-leverage seams.
- Billing and provider-heavy abstractions in core.
- Universal UI abstractions or LiveView-driven native rendering.
- Desktop/browser-engine expansion.

### Architecture Approach

Crosswake should be structured as a policy compiler plus runtime host system. Phoenix defines route policy, compiles a manifest, enforces compatibility, and serves server truth. Native shells load that manifest, resolve route ownership, host LiveView where appropriate, dispatch bounded capability calls, run offline islands with local storage, and host native screens when platform ownership is required.

**Major components:**
1. `Crosswake.RoutePolicy` and `Crosswake.Manifest` — declare route ownership and compile runtime truth.
2. `Crosswake.Compatibility` and `Crosswake.Capabilities` — enforce version gates, allowlists, and activation checks.
3. Native shell runtime host — loads manifest, resolves routes, hosts LiveView/native/offline modes.
4. Bridge dispatcher — semantic low-frequency request/reply channel for allowlisted capabilities.
5. Offline island host, pack store, and sync engine — local-first storage, journals/outboxes, pack installs, and replay/reconciliation.
6. `Crosswake.Diagnostics` — doctor tasks, manifest inspection, support matrix, and route/compatibility traces.

### Critical Pitfalls

1. **Universal-runtime drift** — avoid any API or marketing that hides route ownership; every route must declare runtime, offline semantics, capabilities, and sensitivity.
2. **Bridge as render/state bus** — keep the bridge semantic, typed, low-frequency, and versioned; move interactive flows into native screens or offline islands.
3. **Fake offline support** — separate cached read-only from local-first mutation; require journals, drafts, outboxes, and reconciliation contracts before claiming serious offline capability.
4. **Weak capability trust boundaries** — enforce route-scoped allowlists, origin checks, active-route verification, and deny-by-default capability grants in core.
5. **Shell/web compatibility drift** — version manifest, bridge, capabilities, and pack schemas independently and fail closed on mismatch.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Core Contract and Install Truth
**Rationale:** Everything else depends on explicit route truth and narrow product boundaries.
**Delivers:** Route policy DSL, manifest compiler, compile-time validation, initial support policy, generator ownership model, example-host skeletons, and release-proof scaffolding.
**Addresses:** Route policy DSL, security defaults, compatibility contract foundation, diagnostics/proof posture.
**Avoids:** Universal-runtime drift, broad support claims without proof, generated-code ownership confusion, early billing/integration scope collapse.

### Phase 2: Compatibility, Shell Boot, and Bounded Bridge
**Rationale:** Before expanding features, prove that iOS and Android can load the manifest, resolve ownership, host LiveView, and reject invalid runtime combinations safely.
**Delivers:** Thin iOS/Android shells, compatibility handshake, route resolver, LiveView container, small typed bridge, capability registry, and doctor diagnostics.
**Uses:** Phoenix `1.8`, LiveView `1.1`, SwiftUI/`WKWebView`, Compose/WebView, JSON manifest, Telemetry.
**Implements:** `Crosswake.Compatibility`, `Crosswake.Capabilities`, native shell runtime host, bridge dispatcher.
**Avoids:** Bridge-as-bus, weak trust boundaries, shell/web drift, opaque setup failures.

### Phase 3: Honest Offline Contract
**Rationale:** Crosswake is not differentiated until it proves one credible local-first workflow, but offline should come only after route and shell contracts are stable.
**Delivers:** Offline route classes, one offline island, local draft store, journal/outbox schema, sync seam, reconciliation callbacks, and route-class telemetry.
**Addresses:** Explicit offline policy, draft/outbox seams, one serious differentiator.
**Avoids:** Fake offline claims, low-signal telemetry, cache stretched into local-first behavior.

### Phase 4: Packs, Transfers, and One Native Escape Hatch
**Rationale:** Once route policy and offline seams are real, prove asset-heavy and device-heavy flows with minimal additional surface.
**Delivers:** Pack registry, content/media pack install lifecycle, upload/download/media transfer seam, one native screen or adapter proof lane, and deeper diagnostics.
**Addresses:** Media transfer seams, native screen adapters, content/media packs.
**Avoids:** Pack mutation from UI code, uncontrolled capability growth, premature broad native abstraction.

### Phase 5: Companion Seams and Operational Hardening
**Rationale:** Integrations are valuable only after the substrate contract is trustworthy and observable.
**Delivers:** Carefully chosen companion seams, rollout/kill-switch integration points, mounted diagnostics UI, stronger support matrix, and hardened release/version policy.
**Addresses:** Notification/deep-link ecosystem, observability, staged rollout safety, operator support.
**Avoids:** Core bloat from vendors, monorepo/package version chaos, unsupported claims about ecosystem breadth.

### Phase Ordering Rationale

- Route policy and manifest compilation must come first because every later feature depends on explicit runtime ownership and compatibility truth.
- Shell boot and bridge work should precede offline islands; otherwise offline semantics will be designed against unstable runtime boundaries.
- Offline islands, packs, and sync belong together, but only after there is a proven shell/runtime contract to carry them.
- Native screens and integrations should be added only after the bridge and policy contracts are stable enough to avoid redesign.
- Diagnostics and proof lanes should start in Phase 1 and deepen each phase, because support honesty is part of the product, not follow-up tooling.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Offline island storage, journal schema, replay semantics, background execution, and conflict resolution need phase-specific implementation research.
- **Phase 4:** Pack lifecycle, media transfer behavior, and the chosen native-screen proof lane need tighter platform-level research.
- **Phase 5:** Companion integration boundaries, remote config/rollout safety, and notification/provider specifics need targeted follow-up.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Phoenix DSL design, manifest validation, monorepo package layout, and docs/proof-lane scaffolding are already well-defined by the current research.
- **Phase 2:** Standard iOS/Android shell boot, WebView hosting, compatibility gating, and bounded bridge patterns are well-supported by official docs and should move directly into planning.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core server and native-shell choices are backed by official platform and framework docs; only the exact package split remains a project choice. |
| Features | HIGH | The feature set converges strongly around route policy, capability contracts, diagnostics, and explicit offline semantics. |
| Architecture | HIGH | The policy-compiler plus runtime-host model is consistent across all research outputs and aligns with platform constraints. |
| Pitfalls | MEDIUM-HIGH | The major failure modes are clear and well-supported, though some app-review and provider-specific details will remain contextual. |

**Overall confidence:** HIGH

### Gaps to Address

- **Manifest schema details:** Final field set, version negotiation rules, and support-matrix policy still need concrete specification during roadmap planning.
- **Generator ownership model:** The exact split between library-owned and host-owned files needs explicit rules before scaffolding expands.
- **Offline island reference flow:** Crosswake needs one named exemplar workflow early to constrain storage, journal, and reconciliation design.
- **Pack contract scope:** The first supported pack type should be deliberately narrow; otherwise pack and sync design will sprawl.
- **Companion prioritization:** Research names likely companions, but roadmap planning still needs a strict rule for what stays core, companion, example-only, or deferred.
- **Release choreography:** The research recommends publishing the Elixir package first and proving native shells in-repo, but the exact promotion criteria for separate native artifacts still need definition.

## Sources

### Primary (HIGH confidence)
- [PROJECT.md](../PROJECT.md) — project thesis, scope, constraints, and maintainer OSS posture
- [STACK.md](./STACK.md) — recommended technologies, versions, package shape, and anti-stack guidance
- [FEATURES.md](./FEATURES.md) — v1 table stakes, differentiators, anti-features, and dependency order
- [ARCHITECTURE.md](./ARCHITECTURE.md) — component boundaries, data flow, build order, and patterns
- [PITFALLS.md](./PITFALLS.md) — critical risks, phase warnings, and prevention strategies
- https://hexdocs.pm/phoenix/Phoenix.html — Phoenix baseline
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html — LiveView runtime and interop
- https://developer.apple.com/documentation/webkit — iOS WebKit shell primitives
- https://developer.android.com/reference/androidx/webkit/package-summary — Android WebView shell primitives

### Secondary (MEDIUM confidence)
- https://developer.android.com/topic/architecture/data-layer/offline-first — offline-first data guidance informing island/repository design
- https://developer.apple.com/documentation/backgroundtasks/refreshing-and-maintaining-your-app-using-background-tasks — iOS background work guidance for sync and replay
- https://developer.android.com/develop/background-work/background-tasks/persistent — WorkManager guidance for Android sync execution
- https://developer.apple.com/app-store/review/guidelines/ — app review constraints shaping scope boundaries
- https://support.google.com/googleplay/android-developer/answer/10281818 — Google Play billing constraints shaping integration deferrals

---
*Research completed: 2026-05-12*
*Ready for roadmap: yes*
