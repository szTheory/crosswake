# Architecture Patterns

**Domain:** Phoenix-native mobile substrate for explicit per-route runtime ownership
**Project:** Crosswake
**Researched:** 2026-05-12
**Overall confidence:** HIGH for Phoenix/LiveView and mobile shell constraints, MEDIUM for exact native package split because that is a project choice rather than a dictated standard

## Recommended Architecture

Crosswake should be built as a **policy compiler plus runtime host system**, not as a UI framework. Phoenix remains the authority for route declaration, policy compilation, server truth, sync reconciliation, and compatibility gating. The iOS and Android shells remain the authority for device capabilities, local storage, background execution, and native screens. LiveView remains a route runtime, not the orchestration layer for every mobile concern.

The core rule is: **every crossing between Phoenix and native code must happen through a named contract**. That means no ad hoc JS messaging, no hidden capability reach-through, and no route behavior that depends on runtime guesses. Route policy should compile into a manifest that both Phoenix and the native shells consume, and all runtime decisions should be explainable from that manifest.

### System Shape

```text
Phoenix host app
  -> Crosswake.RoutePolicy DSL
  -> Crosswake.Manifest compiler
  -> Crosswake.Compatibility gate
  -> Crosswake.Capability registry
  -> Crosswake.Sync contracts
  -> Crosswake.Pack registry
  -> Crosswake.Diagnostics / operator surface

Compiled manifest
  -> shipped with host release
  -> loaded by iOS shell
  -> loaded by Android shell

Native shell
  -> Shell runtime host
  -> Route resolver
  -> LiveView container
  -> Bridge dispatcher
  -> Offline island host
  -> Native screen host
  -> Pack store
  -> Sync engine
  -> Capability adapters

Companions and integrations
  -> attach at auth, flagging, media, notifications, audit, health seams
  -> never bypass manifest, policy, or bridge contracts
```

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Crosswake.RoutePolicy` | DSL for declaring runtime, offline mode, capabilities, packs, sync seams, and sensitivity per route | Phoenix router, manifest compiler |
| `Crosswake.Manifest` | Compiles route policy into versioned runtime manifest consumed by shells and tests | RoutePolicy, compatibility gate, native shells |
| `Crosswake.Compatibility` | Enforces bridge version, pack schema version, shell minimum version, and route compatibility before a route activates | Manifest, native shell handshake, diagnostics |
| `Crosswake.Capabilities` | Defines capability names, versions, allowlists, and route-level activation rules | Manifest, bridge dispatcher, native adapters |
| `Crosswake.Packs` | Declares content pack and media pack contracts, integrity metadata, and install/update semantics | Manifest, sync contracts, native pack store |
| `Crosswake.Sync` | Defines journals, outboxes, reconciliation callbacks, idempotency keys, and server commit rules | Phoenix APIs/channels, native sync engine, audit |
| `Crosswake.Diagnostics` | Doctor tasks, manifest inspection, support matrix, route activation traces, compatibility failures | All components |
| Phoenix host routes/controllers/LiveViews | Serve server-owned routes and server truth, including sync endpoints and LiveView screens | RoutePolicy, Sync, Diagnostics |
| Native shell runtime host | Bootstraps app, loads manifest, resolves route ownership, coordinates shell navigation | Manifest, Compatibility, all native runtime hosts |
| LiveView container | Hosts server-owned screens in the shell and exposes bounded hook/bridge touchpoints | Native shell, bridge dispatcher, Phoenix LiveView |
| Bridge dispatcher | Single semantic request/reply channel for low-frequency native affordances | LiveView container, capability adapters, diagnostics |
| Offline island host | Runs local-first modules with local DB, journal, and sync adapters | Pack store, sync engine, capability adapters |
| Native screen host | Runs full native flows for camera, billing, audio capture, document scan, etc. | Shell navigation, capability adapters, sync engine |
| Pack store | Stores content/media packs, verifies integrity, exposes pack reads to offline islands and native screens | Manifest, sync engine |
| Sync engine | Replays outbox entries, refreshes packs, uploads media, reconciles conflicts, schedules background work | Phoenix Sync APIs, pack store, journal DB |
| Capability adapters | Thin per-capability native implementations behind route-scoped checks | Bridge dispatcher, native screen host, offline islands |

## Data Flow

### 1. Build-time flow

1. Phoenix route policy is declared alongside routes, not in a disconnected YAML file.
2. Crosswake compiles policies into a versioned manifest.
3. Manifest validation fails the build if a route references an unknown capability, pack, sync seam, or unsupported runtime mode.
4. The manifest is embedded into the host release and exported for native-shell fixtures and contract tests.

This is the first test seam. If policy cannot compile deterministically, the substrate is not ready.

### 2. App boot flow

1. Native shell starts and loads the bundled manifest.
2. Shell performs a compatibility handshake:
   - shell version
   - bridge version
   - supported capability versions
   - pack schema versions
3. If compatibility fails, the shell must degrade explicitly:
   - refuse route activation
   - route to supported fallback
   - expose a diagnostic reason

No route should activate on inferred compatibility.

### 3. Route activation flow

1. User navigates to a route or deep link.
2. Route resolver looks up the manifest entry.
3. The resolver chooses exactly one owner:
   - `:live_view`
   - `:live_view_with_bridge`
   - `:cached_read_only`
   - `:offline_island`
   - `:native_screen`
   - `:adapter`
4. Before activation, the shell checks:
   - current auth/session state
   - required capabilities
   - required packs installed
   - offline policy allowed for current connectivity
   - security sensitivity and cache restrictions
5. The chosen runtime receives a typed route context, not arbitrary global state.

### 4. LiveView in shell flow

Phoenix owns HTML and state transitions for server-centric routes. Native code owns shell navigation and only exposes bounded native affordances through the bridge. This lines up with LiveView’s official hook/event interop model, where the client can `pushEvent`, receive replies, and handle server-pushed events, but the integration point is still an event seam rather than a render loop.[1][2]

Implication: bridge calls should look like `camera.request_permission`, `haptics.impact`, or `files.pick_upload`, not raw JS-native message passing or high-frequency state sync.

### 5. Offline island flow

1. Route policy resolves to `offline_island`.
2. Shell verifies required content packs and local schema versions.
3. Offline island reads from local storage only.
4. User actions append journal entries or mutate local drafts.
5. Sync engine later ships journal entries to Phoenix, receives server outcomes, and reconciles local state.

This matches current Android guidance for offline-first apps: local storage should be the source read by upper layers, with repositories mediating local and network data rather than letting UI read directly from the network.[3][4]

Crosswake implication: an offline island should expose a **repository seam** and **journal seam**, never direct HTTP calls from island UI code.

### 6. Pack flow

1. Phoenix defines pack metadata and authorization rules.
2. Native shell downloads packs through the sync engine or pack installer.
3. Pack store verifies integrity and schema version before install.
4. Offline islands and native screens read packs as immutable inputs.
5. Pack refresh is separate from route rendering.

Treat packs as installable artifacts, not as incidental cache entries.

### 7. Sync flow

1. Server-authoritative writes from LiveView go directly to Phoenix.
2. Offline-island writes go into a journal/outbox first.
3. Sync engine batches and replays entries with idempotency keys.
4. Phoenix returns accept/reject/conflict results.
5. Local state is reconciled and diagnostics are emitted.
6. Background refresh and replay use the native platform schedulers, not LiveView timers:
   - Android persistent sync work belongs in WorkManager.[5]
   - iOS background refresh/processing belongs in `BGTaskScheduler`/background tasks.[6][7]

## Suggested Build Order

Build order should follow dependency truth, not demo flash.

1. **Route policy DSL and manifest compiler**
   - Everything else depends on explicit route truth.
   - Include compile-time validation and manifest golden tests first.

2. **Compatibility gate and diagnostics**
   - Before any shell sophistication, prove version mismatch behavior and support-matrix visibility.

3. **Minimal native shells for iOS and Android**
   - Boot app, load manifest, resolve route ownership, host a LiveView container, expose diagnostics.
   - No broad capability set yet.

4. **Bounded bridge and capability registry**
   - Add semantic request/reply bridge.
   - Start with a tiny capability set like haptics, app info, and file picker.
   - Conformance tests should prove route-scoped allowlists and version checks.

5. **LiveView-in-shell navigation contract**
   - Deep links, route activation, fallback behavior, auth/session handoff.
   - This is where Phoenix-native mobile credibility starts.

6. **Offline island contract**
   - Local storage schema, island repository interface, journal format, replay contract.
   - One serious example flow only.

7. **Pack system**
   - Content/media pack metadata, integrity checks, install/update lifecycle, test fixtures.

8. **Sync engine and reconciliation**
   - Background replay, idempotency, conflict handling, operator traces.

9. **Native screens and specialized adapters**
   - Add device-heavy flows only after route ownership and sync seams are stable.

10. **Companions and example integrations**
   - Layer in auth, flags, media, notifications, audit, and health once the core contracts are trustworthy.

## Patterns to Follow

### Pattern 1: Policy Compiles to Runtime Truth
**What:** Route declarations are the single source for runtime ownership and constraints.
**When:** Always.
**Example:**

```elixir
route "/study/session",
  runtime: {:offline_island, "study.session"},
  content_pack: :daily_study,
  sync: :study_reviews,
  capabilities: [:audio, :haptics],
  sensitivity: :private
```

The compiled manifest should be what both the Phoenix host and native shells test against.

### Pattern 2: Semantic Bridge Only
**What:** Expose named commands and events, not arbitrary payload tunnels.
**When:** For low-frequency affordances from LiveView routes.
**Instead of:** `postMessage("camera", payload)`
**Use:** `Crosswake.Bridge.request("camera.capture", params, reply: true)`

### Pattern 3: Offline Islands are Local-First Mini-Systems
**What:** Each island owns local reads, local mutation rules, journal append logic, and sync mapping.
**When:** For flows that must survive network loss.
**Example boundary:**

```text
Island UI
  -> Island Repository
  -> Local DB + Draft Store
  -> Journal Append
  -> Sync Mapper
```

### Pattern 4: Native Screens are Escape Hatches, not Prestige Features
**What:** Use full native ownership where platform behavior is the real requirement.
**When:** Camera capture, in-app purchase flows, background media, heavy document/file workflows, platform SDK integrations.

### Pattern 5: Operator Truth is a First-Class Surface
**What:** Ship route inspectors, manifest viewers, compatibility reports, and doctor commands early.
**When:** From the first milestone.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Bridge as UI Runtime
**What:** Streaming high-frequency UI state or render intent over the bridge.
**Why bad:** It creates an undocumented second rendering system and fights LiveView’s event model.
**Instead:** Keep LiveView server-owned or move the flow into an offline island or native screen.

### Anti-Pattern 2: Hidden Route Ownership
**What:** Letting a route decide at runtime through heuristics whether it is LiveView, cached, or native.
**Why bad:** It destroys testability and support honesty.
**Instead:** Declare ownership in route policy and compile it into the manifest.

### Anti-Pattern 3: Cache Equals Offline
**What:** Treating WebView cache as sufficient offline support.
**Why bad:** Serious offline workflows need local data models, mutation queues, and reconciliation.
**Instead:** Reserve cache for degraded read-only routes and use offline islands for local-first loops.

### Anti-Pattern 4: Integrations in Core Contracts
**What:** Embedding auth, billing, media vendors, or notification providers into the core manifest and bridge model.
**Why bad:** It bloats the trust surface before the substrate is stable.
**Instead:** Keep the core generic and attach integrations at explicit seams.

### Anti-Pattern 5: Pack Mutation from UI Code
**What:** Letting route code mutate installed packs directly.
**Why bad:** Pack integrity and version drift become untestable.
**Instead:** Treat packs as versioned installed artifacts managed by the pack store and sync engine.

## Where Integrations Belong

| Integration Area | Where It Belongs | Why |
|------------------|------------------|-----|
| `sigra` auth/session flows | Companion seam at shell bootstrap, route gating, and auth-sensitive native screens | Auth is common, but should not redefine the core route manifest |
| `rulestead` flags/remote config | Companion seam at route activation and rollout controls | Good for gating runtime modes and kill switches without baking policy evaluation into core |
| `rindle` uploads/media | Companion seam at media packs, upload adapters, and native capture flows | Media is central for some apps but too broad for v1 core |
| `chimeway` notifications | Companion seam for deep link routing and notification truth | Useful, but not part of core runtime ownership |
| `threadline` audit | Companion seam for route decisions, sync replay, and operator traces | High leverage for supportability without changing architecture fundamentals |
| `parapet` health/SLO | Example or later companion at diagnostics and journey health | Valuable once route classes are real in production |

## Where Integrations Should Stay Out

| Area | Keep Out Of | Reason |
|------|-------------|--------|
| Billing/provider SDKs | Core route policy and bridge vocabulary | Provider rules and store policy are too volatile for v1 core |
| Identity federation specifics | Manifest compiler and shell bootstrap defaults | Too domain-specific for the substrate layer |
| App-specific domain search/AI/docs features | Core packs and sync contracts | They belong in downstream apps, not the substrate |
| Provider-specific network/retry logic | Generic sync engine contract | Sync engine should define seam shape, not encode every vendor |

## Testability Model

Crosswake should be testable at five seams:

1. **Compile-time tests**
   - route policy validation
   - manifest golden snapshots
   - capability and pack reference checks

2. **Contract tests**
   - shell handshake compatibility
   - bridge request/reply schemas
   - sync journal schema and idempotency

3. **Host integration tests**
   - Phoenix route activation
   - fallback behavior
   - auth and sensitivity rules

4. **Native conformance tests**
   - shell loads manifest
   - plugin/adapters register correctly
   - route-scoped capability denial works

5. **End-to-end proof lanes**
   - example host app
   - one offline island
   - one native screen
   - one companion integration path

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Manifest complexity | Single manifest file, compile-time checks | Add manifest diff tooling and stricter support matrix | Add version negotiation discipline and long-tail compatibility tracking |
| Offline storage | Simple local DB per island | Schema migration tooling and pack pruning | Strong pack lifecycle rules, storage quotas, and background maintenance |
| Sync volume | Basic replay loop | Batching, retries, idempotency metrics | Backpressure controls, partitioned sync resources, conflict observability |
| Native capability surface | Small allowlist | Capability-version compatibility matrix | Split optional adapters and companion packages aggressively |
| Operator support | Doctor commands and manifest viewer | Route-level diagnostics and replay traces | Fleet-style health views and release correlation |

## Roadmap Implications

The first milestone should stop after proving: route policy compilation, shell handshake, LiveView-in-shell hosting, and a bounded bridge. Do not front-load offline islands, packs, sync, and native screens all at once.

The second milestone should add exactly one offline island with one pack type and one replayable sync seam. That is the point where Crosswake becomes more than a shell.

The third milestone should add one native-screen proof lane plus companion seams, because integrations are only useful after core ownership boundaries are already trustworthy.

## Sources

1. Phoenix LiveView JS interop guide: https://hexdocs.pm/phoenix_live_view/js-interop.html
2. Phoenix LiveView docs for `push_event/3`: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
3. Android Developers, offline-first architecture: https://developer.android.com/topic/architecture/data-layer/offline-first
4. Android Developers, data layer guidance: https://developer.android.com/topic/architecture/data-layer
5. Android Developers, WorkManager persistent background work: https://developer.android.com/develop/background-work/background-tasks/persistent
6. Apple background tasks overview: https://developer.apple.com/documentation/backgroundtasks/refreshing-and-maintaining-your-app-using-background-tasks
7. Apple background task scheduling details: https://developer.apple.com/documentation/uikit/using-background-tasks-to-update-your-app
8. Phoenix routing scopes and pipelines: https://hexdocs.pm/phoenix/Phoenix.Router.html
9. Capacitor custom plugin registration docs, used only as evidence that native bridge plugins must be explicitly registered per platform: https://capacitorjs.com/docs/ios/custom-code and https://capacitorjs.com/docs/android/custom-code

