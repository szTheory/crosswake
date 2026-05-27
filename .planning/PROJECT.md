# Crosswake

## What This Is

Crosswake is a Phoenix-native open-source library for shipping iOS and Android apps from Phoenix applications without pretending one runtime should own every screen. It lets Phoenix teams declare per-route runtime ownership so server-centric screens can stay LiveView, local-first workflows can live in offline islands, and device-heavy flows can move into disciplined native screens or adapters.

## Core Value

Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## Current State

Crosswake shipped `v3.1 Native Capabilities and Bridge Expansion` on `2026-05-27`.

`v3.1` delivered the first official low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`) through the bounded bridge thesis, with route-local enforcement, doctor/support truth, and CI-backed proof across Elixir, checked-in iOS shell code, and Android JVM bridge tests.

`v3.2 Commerce And Entitlement Seams` remains active with `Phase 19 Commerce Route Corridors` complete. The milestone now has provider-neutral route/corridor declarations, canonical fail-closed `commerce.corridor.*` denial semantics, and baseline support/doctor/public guide parity in place before provider adapters ship.

## Current Milestone: v3.2 Commerce And Entitlement Seams

**Goal:** Make Crosswake's commerce seam usable and provable for Phoenix teams while keeping entitlement truth backend-owned and native/storefront provider work outside core.

**Target features:**
- Commerce route/corridor declarations that separate Phoenix-owned paywall/account surfaces from native-screen or companion-owned purchase loops.
- Typed purchase, restore, reconciliation, and entitlement lifecycle semantics that keep device/storefront events as evidence.
- Minimal Phoenix-owned reconciliation inbox and entitlement projection example for host apps.
- Doctor, support-matrix, reviewer/storefront, and proof-lane guidance for commerce prerequisites and fallbacks.

**Why now:** `v3.0` locked the commerce vocabulary and package boundary, and `v3.1` proved bounded native capability delivery. Commerce is the next strategic arc candidate before wider companion or archetype expansion.

## Requirements

### Validated

- [x] Provide a Phoenix-native route policy DSL that declares runtime mode, offline policy, required capabilities, pack needs, sync seams, and security sensitivity per route. Validated in Phase 1: Route Policy Foundation.
- [x] Provide additive generators/installers for host Phoenix setup and native shell bootstrap that keep ownership boundaries explicit. Validated in Phase 1: Route Policy Foundation.
- [x] Generate and validate a runtime manifest and compatibility contract that native shells, bridges, and host Phoenix apps can trust. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Ship developer-facing doctor diagnostics plus honest compatibility and support documentation as part of the public product contract. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Treat diagnostics, compatibility truth, and failure-mode visibility as first-class product surfaces. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Support offline semantics that clearly separate cached read-only routes, local drafts, append-only journals, reconciliation, and server-authoritative commits. Validated in Phase 4: Honest Offline Contract.
- [x] Create disciplined contracts for offline islands and sync journals/outboxes without widening into generic sync claims. Validated in Phase 4: Honest Offline Contract.
- [x] Define a versioned bridge contract for bounded native affordances instead of ad hoc messaging. Validated in Phase 3: Native Shell Boot And Bounded Bridge.
- [x] Establish a capability registry with explicit allowlists, versioning, and active-route checks. Validated in Phase 3: Native Shell Boot And Bounded Bridge.
- [x] Ship example-host proof lanes and deterministic CI that verify the public install path across Phoenix, iOS, and Android surfaces. Validated in Phase 5: Packs, Native Escape, And Proof Lanes.
- [x] Validate the v1 substrate against three adopter-shaped exemplar lanes: Phoenix-backed SaaS portal, selective-native mobile flow, and local-first study or content flow. Validated across Phases 7-10.
- [x] Harden route-policy, manifest, shell, bridge, pack, transfer, and offline contracts where exemplar pressure exposes adopter-facing gaps. Validated in Phase 10: Cross-Profile Hardening, Proof, And Guidance.
- [x] Publish proof, diagnostics, and guidance that make exemplar support and rough-edge truth part of the public product contract. Validated in Phase 10: Cross-Profile Hardening, Proof, And Guidance.
- [x] Freeze capability-family taxonomy and route-owner decision rules before shipping new capability families. Validated in Phase 11: Capability Taxonomy And Contract Rubric.
- [x] Classify `core`, `companion`, `example/docs-only`, and deferred surfaces with explicit release and rebuild rules. Validated in Phase 12: Packaging Ledger And Release Boundaries.
- [x] Define Phoenix-facing commerce and entitlement seams that keep entitlement truth backend-owned. Validated in Phase 13: Commerce And Entitlement Contract.
- [x] Extend doctor, support-matrix, and proof-lane posture so future capability claims remain honest. Validated in Phase 14: Proof, Doctor, And Support Truth.
- [x] Ship the first low-frequency bounded native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, and `file_picker`) without widening into high-frequency bridge authority. Validated across Phases 15-17.
- [x] Enforce v3.1 capability declarations route-locally and keep missing prerequisites fail-closed with explicit doctor and support-matrix truth. Validated in Phase 18.
- [x] Prove the v3.1 capability surface through layered Elixir, checked-in iOS shell, and Android JVM CI proof lanes. Validated by Phase 18 Proof run `26498172516`.
- [x] Phoenix teams can declare commerce-sensitive routes that distinguish Phoenix-owned paywall/account surfaces from native-screen or companion-owned storefront loops. Validated in Phase 19: Commerce Route Corridors.
- [x] Crosswake can render commerce route/corridor declarations into manifest and support truth without exposing provider-specific route-policy vocabulary. Validated in Phase 19: Commerce Route Corridors.
- [x] Unsupported or undeclared commerce corridors fail closed with explicit denial/fallback reasons instead of silent WebView or bridge fallback. Validated in Phase 19: Commerce Route Corridors.

### Active

- [ ] Phoenix teams can use normalized purchase, restore, reconciliation, and entitlement snapshot semantics without treating device callbacks as entitlement authority.
- [ ] Host apps can follow a minimal backend reconciliation inbox and entitlement projection example that keeps idempotency and provider verification outside Crosswake core.
- [ ] Adopters can see explicit doctor, support-matrix, reviewer/storefront, fallback, and proof guidance for commerce claims before provider adapters ship.

### Out of Scope

- Universal UI abstraction across all screens — it conflicts with the project thesis that runtime ownership should be explicit and per-route.
- LiveView rendering native widgets directly — it would over-couple the library to unstable or private rendering internals.
- Generic "wrap your app in a WebView" positioning — it hides the architecture boundaries Crosswake is supposed to clarify.
- Shipping a broad capability catalog in `v3.0` — this milestone should decide what belongs where before implementing many new families.
- Store-specific billing implementation in `v3.2` — this milestone operationalizes the core seam, while provider adapters and storefront SDK code remain companion or future work.
- Generic plugin-bus semantics for native or companion integrations — Crosswake must preserve typed, bounded, route-local seams.
- Desktop packaging as a near-term arc driver — it remains a later extension after the mobile-first companion posture is mature.
- Magical offline guarantees — offline behavior must stay explicit about cacheability, local ownership, and reconciliation.

## Context

Crosswake is being planned as a greenfield Elixir/Phoenix OSS library with iOS and Android as first-class targets and web remaining part of the architecture. The authoritative architecture stance is route policy plus a capability ladder: plain Phoenix/LiveView, LiveView inside a native shell, bounded bridge components, cached/degraded routes, offline islands, native screens, and specialized native SDK adapters. Supporting research emphasizes that the project should not market itself as React Native for Phoenix, Flutter for Phoenix, a generic WebView wrapper, or a "write once, run anywhere" platform.

The strongest early app archetypes are Phoenix-backed SaaS portals, subscription apps with selective native flows, and local-first study/training/content apps. The initial value should come from route policy, shell/runtime contracts, offline/native boundary design, and honest support claims rather than wide native capability breadth. Companion integrations are relevant context: `sigra`, `rulestead`, `rindle`, `chimeway`, and `threadline` are plausible first-party companions; billing, identity-provider, and other vendor-heavy integrations should stay deferred or example-only until the core contract is stable.

The maintainer's OSS house style materially constrains the project. Install truth matters as much as the happy path. Public support claims must be narrow and documented. Proof lanes, docs-contract checks, release automation, and recovery-conscious publishing are part of the product. Generated host code, optional dependencies, and operator-facing diagnostics should be intentional and honest.

The strategic source of truth for the current sequence is `.planning/MILESTONE-ARC.md`. `v3.2` activates the commerce candidate as operational seam work, building on the harvested post-`v2.0` capability and commerce seed plus the Phase 13 contract substrate.

## Constraints

- **Tech stack**: Phoenix-native Elixir library with mobile shell integration seams — the product must extend Phoenix instead of replacing it with a JS-framework-first abstraction.
- **Platform**: iOS and Android are first-class in v1 — runtime contracts must respect app review, permission, billing, and OTA compatibility realities.
- **Architecture**: Per-route runtime ownership is authoritative — solution design cannot collapse into single-runtime ideology.
- **Security**: Route allowlists, origin allowlists, capability allowlists, active-route checks, and cache sensitivity need explicit defaults — mobile/runtime boundaries increase the blast radius of vague trust assumptions.
- **Proof posture**: Deterministic CI, example-host verification, docs integrity, and release discipline are required early — support claims must be proven, not aspirational.
- **Scope**: Native capability breadth must be phased — `v3.0` should lock contract and packaging truth before wider capability delivery.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Center the product on route policy and runtime ownership | The strongest research convergence is that explicit boundaries are the core differentiator | Validated in Phase 1 |
| Use a capability ladder instead of a single runtime model | Different route classes need different ownership and honesty about tradeoffs | Validated in Phase 2 via manifest/runtime/support contract layering |
| Treat bridge contracts as bounded, semantic, and versioned | High-frequency or ad hoc cross-runtime messaging would make the system fragile and misleading | Validated in Phase 3 via typed bridge envelopes, manifest-backed allowlists, and fail-closed native channels |
| Keep offline claims route-local, typed, and narrow | Cached read-only degradation and local-first mutation need visibly different contracts and proof posture | Validated in Phase 4 via cache/island contracts, replay outcomes, doctor posture, and the hermetic offline proof lane |
| Plan iOS and Android as first-class, web-inclusive targets | Mobile credibility is the project goal, while Phoenix web remains part of the architecture | Validated in Phase 2 via explicit support matrix and compatibility baselines |
| Keep deep desktop packaging and broad adapters out of v1 core | Early scope should validate the contract surface before expanding platform breadth | — Pending |
| Make diagnostics, proof lanes, and docs part of the public contract | This matches the maintainer's proven OSS style and reduces support ambiguity | Further validated in Phase 2 via `mix crosswake.doctor`, generated support docs, and compatibility guidance |
| Treat checked-in example hosts as the public proof artifact class and generated hosts as secondary verification | Proof-backed support needed a stable adopter-facing install path rather than host-local scaffolding alone | Validated in Phase 5 |
| Use adopter-shaped stress profiles as the first v2 milestone | Realistic product pressure should reveal the next core fixes before Crosswake expands official native capability breadth | Validated in Milestone v2.0 |
| Treat exemplars as proof artifacts, not product templates | The milestone should validate architectural fit without turning Crosswake into a starter-app bundle | Validated in Milestone v2.0 |
| Publish one adopter-profile matrix plus a shared example-host lane contract before exemplar implementation | Locking profile vocabulary, non-goals, and artifact boundaries first reduces scope drift in Phases 7-10 | Validated in Phase 6 |
| Prove the Phoenix SaaS lane as one authenticated LiveView-first approvals slice with one bounded haptics seam | The first exemplar needed credible product pressure without drifting into offline, transfer-first, or native-screen breadth | Validated in Phase 7 |
| Route-pattern deep links in checked-in shells must match manifest paths with dynamic segments | The SaaS approval route exposed that exact-path matching denied valid `/saas/.../:id` deep links and broke proof-backed shell activation | Validated in Phase 7 |
| Sequence post-v2 capability expansion as contracts-first milestone work | Locking taxonomy, packaging, commerce seams, and support truth before feature breadth reduces plugin-sprawl and support dishonesty risk | Validated through Phases 11-18 |
| Ship native capabilities only when they remain low-frequency, typed, and route-local | v3.1 proved value in bounded affordances while avoiding continuous client authority | Validated in Milestone v3.1 |
| Split proof lanes by evidence class when emulator/device proof slows iteration | Android JVM bridge truth closed quickly in CI once separated from emulator-backed connected tests | Validated in Phase 18 closeout |
| Operationalize commerce as a backend-owned seam before provider adapters | Apple and Google purchase ecosystems both require native storefront evidence plus backend verification/lifecycle truth, matching Crosswake's Phase 13 contract posture | Active in Milestone v3.2 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-27 after completing Phase 19 Commerce Route Corridors*
