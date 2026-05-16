# Crosswake

## What This Is

Crosswake is a Phoenix-native open-source library for shipping iOS and Android apps from Phoenix applications without pretending one runtime should own every screen. It lets Phoenix teams declare per-route runtime ownership so server-centric screens can stay LiveView, local-first workflows can live in offline islands, and device-heavy flows can move into disciplined native screens or adapters.

## Core Value

Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## Requirements

### Validated

- [x] Provide a Phoenix-native route policy DSL that declares runtime mode, offline policy, required capabilities, pack needs, sync seams, and security sensitivity per route. Validated in Phase 1: Route Policy Foundation.
- [x] Provide additive generators/installers for host Phoenix setup and native shell bootstrap that keep ownership boundaries explicit. Validated in Phase 1: Route Policy Foundation.
- [x] Generate and validate a runtime manifest and compatibility contract that native shells, bridges, and host Phoenix apps can trust. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Ship developer-facing doctor diagnostics plus honest compatibility and support documentation as part of the public product contract. Validated in Phase 2: Manifest Truth And Compatibility.
- [x] Treat diagnostics, compatibility truth, and failure-mode visibility as first-class product surfaces. Validated in Phase 2: Manifest Truth And Compatibility.

### Active

- [ ] Define a versioned bridge contract for bounded native affordances instead of ad hoc messaging.
- [ ] Establish a capability registry with explicit allowlists, versioning, and active-route checks.
- [ ] Support offline semantics that clearly separate cached read-only routes, local drafts, append-only journals, reconciliation, and server-authoritative commits.
- [ ] Create disciplined contracts for offline islands, native screens, content packs, media packs, and sync journals/outboxes.
- [ ] Ship the remaining example-host proof lanes as part of the public product contract.

### Out of Scope

- Universal UI abstraction across all screens — it conflicts with the project thesis that runtime ownership should be explicit and per-route.
- LiveView rendering native widgets directly — it would over-couple the library to unstable or private rendering internals.
- Generic "wrap your app in a WebView" positioning — it hides the architecture boundaries Crosswake is supposed to clarify.
- Deep first-version native feature breadth — v1 should establish route policy and runtime contracts before broad adapter coverage.
- Desktop packaging as a v1 driver — it is a later extension after mobile-first architecture proves out.
- Magical offline guarantees — offline behavior must stay explicit about cacheability, local ownership, and reconciliation.

## Context

Crosswake is being planned as a greenfield Elixir/Phoenix OSS library with iOS and Android as first-class targets and web remaining part of the architecture. The authoritative architecture stance is route policy plus a capability ladder: plain Phoenix/LiveView, LiveView inside a native shell, bounded bridge components, cached/degraded routes, offline islands, native screens, and specialized native SDK adapters. Supporting research emphasizes that the project should not market itself as React Native for Phoenix, Flutter for Phoenix, a generic WebView wrapper, or a "write once, run anywhere" platform.

The strongest early app archetypes are Phoenix-backed SaaS portals, subscription apps with selective native flows, and local-first study/training/content apps. The initial value should come from route policy, shell/runtime contracts, offline/native boundary design, and honest support claims rather than wide native capability breadth. Companion integrations are relevant context: `sigra`, `rulestead`, `rindle`, `chimeway`, and `threadline` are plausible first-party companions; billing, identity-provider, and other vendor-heavy integrations should stay deferred or example-only until the core contract is stable.

The maintainer's OSS house style materially constrains the project. Install truth matters as much as the happy path. Public support claims must be narrow and documented. Proof lanes, docs-contract checks, release automation, and recovery-conscious publishing are part of the product. Generated host code, optional dependencies, and operator-facing diagnostics should be intentional and honest.

## Constraints

- **Tech stack**: Phoenix-native Elixir library with mobile shell integration seams — the product must extend Phoenix instead of replacing it with a JS-framework-first abstraction.
- **Platform**: iOS and Android are first-class in v1 — runtime contracts must respect app review, permission, billing, and OTA compatibility realities.
- **Architecture**: Per-route runtime ownership is authoritative — solution design cannot collapse into single-runtime ideology.
- **Security**: Route allowlists, origin allowlists, capability allowlists, active-route checks, and cache sensitivity need explicit defaults — mobile/runtime boundaries increase the blast radius of vague trust assumptions.
- **Proof posture**: Deterministic CI, example-host verification, docs integrity, and release discipline are required early — support claims must be proven, not aspirational.
- **Scope**: Native capability breadth must be phased — the first milestone should prove the contract surface before broad integrations.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Center the product on route policy and runtime ownership | The strongest research convergence is that explicit boundaries are the core differentiator | Validated in Phase 1 |
| Use a capability ladder instead of a single runtime model | Different route classes need different ownership and honesty about tradeoffs | Validated in Phase 2 via manifest/runtime/support contract layering |
| Treat bridge contracts as bounded, semantic, and versioned | High-frequency or ad hoc cross-runtime messaging would make the system fragile and misleading | — Pending |
| Plan iOS and Android as first-class, web-inclusive targets | Mobile credibility is the project goal, while Phoenix web remains part of the architecture | Validated in Phase 2 via explicit support matrix and compatibility baselines |
| Keep deep desktop packaging and broad adapters out of v1 core | Early scope should validate the contract surface before expanding platform breadth | — Pending |
| Make diagnostics, proof lanes, and docs part of the public contract | This matches the maintainer's proven OSS style and reduces support ambiguity | Further validated in Phase 2 via `mix crosswake.doctor`, generated support docs, and compatibility guidance |

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
*Last updated: 2026-05-14 after Phase 2 completion*
