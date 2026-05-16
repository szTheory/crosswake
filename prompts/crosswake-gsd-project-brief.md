# Crosswake GSD Project Brief

Version: 0.1  
Purpose: Self-contained entry brief for `$gsd-new-project --auto @prompts/crosswake-gsd-project-brief.md`

## Project

**Name:** Crosswake  
**Package:** `crosswake`  
**Namespace:** `Crosswake`

Crosswake is a Phoenix-native mobile substrate for declaring which runtime owns each route: LiveView, offline island, native screen, or adapter.

Primary tagline: **Declare the crossing.**

Short positioning:

> Crosswake helps Phoenix teams ship mobile apps by making runtime boundaries explicit: server-centric screens stay LiveView, device-heavy flows go native, and local-first work lives in offline islands.

## What Crosswake Is

Crosswake should be planned as a greenfield open-source Elixir/Phoenix library project for shipping iOS and Android apps from Phoenix applications, while still supporting web and leaving room for later desktop packaging.

Core concepts:

- Route policy
- Runtime manifest
- Native shell
- Bridge contract
- Capability registry
- Offline islands
- Content packs and media packs
- Sync journals and reconciliation
- Native screens as disciplined escape hatches

The core product idea is not "one runtime everywhere." The core product idea is **explicit per-route runtime ownership**.

## What Crosswake Is Not

Crosswake should not be planned or marketed as any of the following:

- React Native for Phoenix
- Phoenix-flavored Flutter
- LiveView rendering native UI directly
- A generic WebView wrapper
- "Write once, run anywhere"
- "Offline magically works"

The architecture should stay boundary-aware and honest about what each runtime owns.

## Authoritative Architecture Stance

The latest research is authoritative. Earlier research docs are useful historical rationale, but they should not override these decisions.

Crosswake should be built around **route policy** and a **capability ladder**:

1. Plain Phoenix / LiveView for online-first server-centric screens
2. LiveView in a native shell for mobile polish and native navigation
3. LiveView plus bounded bridge components for low-frequency native affordances
4. Cached or degraded read-only routes where stale content is acceptable
5. Offline islands for local-first workflows that must function without LiveView round-trips
6. Native screens for device-heavy or platform-heavy flows
7. Native SDK adapters for specialized platform/vendor capabilities

Each mobile route should be able to declare:

- runtime mode
- offline policy
- capabilities required
- content pack or media pack needs
- sync resource or event journal
- security sensitivity / caching restrictions

Illustrative shape:

```elixir
route "/dashboard",
  runtime: :live_view,
  offline: :unavailable

route "/lesson/:id",
  runtime: :live_view,
  offline: {:cached_read_only, ttl: {14, :days}},
  media_pack: :lesson_assets

route "/study/session",
  runtime: {:offline_island, "study.session"},
  content_pack: :daily_study,
  sync: :study_reviews,
  capabilities: [:audio, :haptics]

route "/camera/capture",
  runtime: {:native_screen, "media.capture"},
  capabilities: [:camera, :microphone, :file_upload],
  sync: :media_uploads
```

## Architectural Priorities

Crosswake should favor these design choices:

- Phoenix-native routing and helpers rather than a JS-framework-first abstraction
- Explicit, versioned bridge contracts instead of ad hoc JS/native messaging
- Native shells and native screens where platform constraints demand them
- Offline-first semantics that distinguish cached reads, local drafts, append-only events, and server-authoritative commits
- Telemetry, diagnostics, and failure-mode visibility as first-class product surface
- Security defaults around route allowlists, origin allowlists, capability allowlists, and active-route checks
- Versioning for bridge protocol, runtime compatibility, content pack schemas, capability versions, and sync resources

## Product Thesis

The first version should make Phoenix mobile deployment credible for teams building:

- B2B SaaS and customer portals
- subscription apps with some native billing and mobile affordances
- local-first study/training/content apps
- apps that need selective native screens for camera, audio, media, file handling, notifications, or payments

Crosswake should be strongest where Phoenix and LiveView already shine, while providing explicit escape hatches for mobile-specific realities instead of hiding them.

## Early Scope Direction

The project initialization and roadmap should assume:

- iOS and Android are first-class targets
- web support remains part of the architecture
- desktop packaging is a later extension, not a v1 driver
- the initial value is route policy, shell/runtime contracts, and offline/native boundary design
- deep native feature breadth should be phased, not front-loaded

Likely early pillars:

- route policy DSL and manifest
- native shell contract
- bridge contract and versioning
- capability registry and capability checks
- offline island contract
- content pack / media pack abstractions
- sync journal / mutation outbox / reconciliation seams
- developer generators and honest docs

## House Style From Prior OSS Repos

Crosswake should inherit the proven OSS library style from the maintainer's recent Elixir/Phoenix projects:

- install truth and rough-edge truth matter as much as the happy path
- public support claims should be explicit and narrow
- fake or hermetic proof lanes should exist wherever external providers would otherwise dominate CI
- docs, examples, and release automation are part of the product contract
- mounted Phoenix-native admin/operator surfaces are acceptable when they materially improve adoption or operability
- optional dependencies should stay optional until their capability is enabled, with doctor tasks or equivalent diagnostics
- generators, package boundaries, and public API inventories should be intentional and documented

Use these supporting docs as prior research and design inputs:

- `prompts/crosswake-research-synthesis.md`
- `prompts/crosswake-elixir-oss-dna.md`
- `prompts/crosswake-integrations-and-companions.md`

## Integration Direction

Crosswake should be designed with meaningful first-party companion integrations in mind, but it should not force them into v1 core unless they clearly sharpen the core value.

Strong early companion candidates:

- `sigra` for auth/session/mobile account boundaries
- `rulestead` for route gating, runtime experiments, and remote config
- `rindle` for upload/media pack/media lifecycle concerns
- `chimeway` for notifications
- `threadline` for auditability and actor/action tracing
- `parapet` for SRE visibility and health signals

Later or bounded companions:

- `accrue`, `lattice_stripe`, `oarlock` for billing-related mobile surfaces
- `lockspire`, `relyra` for identity/provider/federation needs
- `mailglass` for lifecycle email and operator messaging
- `scrypath`, `scoria`, `rendro`, `cairnloop`, `kiln` where specific app archetypes justify it

The planning should classify integrations as:

- core
- first-party companion
- example/docs-only
- defer

## Delivery and Quality Expectations

Treat CI/CD, release discipline, and proof posture as product features.

Crosswake should likely adopt patterns such as:

- deterministic CI lanes
- generated-host or example-app proof
- docs-contract checks
- publish/release automation
- recovery-conscious release flow
- explicit compatibility/support matrix

It should also be planned with app-store and mobile-runtime realities in mind:

- app review constraints
- platform permissions
- billing policy boundaries
- OTA/runtime compatibility constraints
- reduced-motion/accessibility considerations
- spotty connectivity and low-power device behavior

## Naming and Legacy Research Notes

Crosswake is the active project name. Some older research docs may use other names. Treat those as legacy naming only. Preserve any useful technical insight, but standardize all current planning output on **Crosswake**.

## Instruction to GSD

Use this brief as the primary source of truth for project initialization.

- Do not re-litigate the project name.
- Do not collapse the architecture into "WebView wrapper" or "native renderer" framing.
- Do not assume one runtime should own every screen.
- Use the supporting docs as already-curated background research.
- Prefer decisive recommendations over broad option dumps unless a choice materially changes the public contract.
