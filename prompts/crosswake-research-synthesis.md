# Crosswake Research Synthesis

Purpose: compress the prompt lineage into one stable architecture story for future GSD and implementation work.

## Canonical Reading Order

Most authoritative to least authoritative:

1. `crosswake-brand-book.md`
2. `elixir-mobile-architecture-apptypes-stresstest-deep-research.md`
3. `elixir-mobile-apptypes-design-stresstest-deep-research.md`
4. `elixir-mobile-offlinesupport-flashcard-app-stresstest-deep-research.md`
5. `elixir-mobile-offlinesupport-stresstest-deep-research.md`
6. `elixir-mobile-oss-refined-plan-deep-research.md`
7. `elixir-mobile-oss-lib-deep-research.md`
8. `new elixir oss lib prompt.txt`

Use later docs to override earlier ones when they conflict.

## Stable Conclusions

The research converges on a few durable ideas:

- The problem is not "render Phoenix into native widgets."
- The problem is not "wrap a Phoenix app in a browser shell and hope for the best."
- The real opportunity is a Phoenix-native mobile substrate with explicit runtime boundaries.

Crosswake is strongest when it helps a team answer:

- which routes stay LiveView
- which routes can tolerate cached or degraded behavior
- which flows require local-first execution
- which flows must become native screens
- which device capabilities are required and how they are negotiated

## Evolution of the Idea

### Earliest phase

The earliest prompts framed the opportunity broadly:

- mobile support for Phoenix/LiveView
- hotwire-like ergonomics
- offline support
- native shells
- eventual desktop support
- strong CI/CD, DX, telemetry, and release automation

This phase was directionally useful but still too broad. It risked becoming a "best of all worlds" platform pitch.

### Middle phase

The middle research sharpened the offline problem:

- spotty connection handling is central, not incidental
- some product loops cannot depend on LiveView round-trips
- serious mobile support requires local data, mutation queues, and media handling
- app archetypes stress the architecture differently

This was the point where the project stopped looking like a general mobile wrapper and started looking like a runtime-policy system.

### Latest phase

The newest research made the architecture coherent:

- per-route runtime policy is the center of gravity
- LiveView, offline islands, native screens, and adapters are complementary, not competing worldviews
- bridge contracts must be semantic, versioned, and low-frequency
- security and compatibility constraints must be explicit
- app archetypes should determine runtime choices, not ideology

This is the version to preserve.

## Current Architecture Thesis

Crosswake should be designed around these primitives:

- route policy
- runtime manifest
- capability registry
- bridge contract
- native shell
- native screen
- offline island
- content pack
- media pack
- sync journal / outbox
- compatibility gate

The architecture should support a ladder of increasing native ownership:

1. LiveView
2. LiveView inside native shell
3. LiveView plus bounded native bridge components
4. cached/degraded routes
5. offline islands
6. native screens
7. specialized native SDK adapters

## Why This Framing Wins

This framing is stronger than the common alternatives.

### Better than "all web inside a shell"

It keeps Phoenix productive where Phoenix is already strong, while avoiding fake promises around offline, background media, camera, or platform-heavy flows.

### Better than "render native UI from LiveView"

It avoids coupling Crosswake to private or unstable rendering internals and avoids betting the project on upstream framework extensibility that may not exist.

### Better than "full custom cross-platform UI framework"

It preserves the Phoenix advantage instead of rebuilding a whole parallel UI ecosystem.

## Product Boundaries

Crosswake should explicitly preserve the following boundaries:

- server-centric screens can remain server-centric
- local-first loops deserve local execution
- device-heavy flows deserve native ownership
- the bridge is not a high-frequency rendering loop
- OTA or web updates cannot override incompatible native runtime assumptions
- app review, billing, permissions, and store policy are part of the design space

## Primary App Archetypes

The research points to a practical sweet spot:

- B2B SaaS portals and companion apps
- subscription apps with selective native flows
- learning/training/content apps with offline study or media loops
- mobile surfaces layered on top of existing Phoenix systems

These archetypes validate the architecture without requiring Crosswake to solve every possible category of mobile app.

## Anti-Patterns To Avoid

- marketing it as seamless universal UI
- hiding runtime boundaries behind convenience APIs
- routing high-frequency native state through LiveView
- assuming browser storage alone is enough for serious offline support
- supporting sensitive or stateful routes with unsafe caching defaults
- treating billing or entitlement success as client-local truth
- declaring broad support before proof lanes and docs exist

## Legacy Naming Note

Some earlier research uses names other than Crosswake. Those documents still contain useful technical reasoning, but all current planning, docs, and code should use **Crosswake** exclusively.
