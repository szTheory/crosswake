# Phase 1: Route Policy Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log records the alternatives considered and the synthesized recommendation chosen.

**Date:** 2026-05-12
**Phase:** 01-route-policy-foundation
**Areas discussed:** route policy declaration shape, runtime taxonomy and naming, route metadata surface, compile-time validation posture, generator and ownership boundaries

---

## Route policy declaration shape

| Option | Description | Selected |
|--------|-------------|----------|
| Router DSL extension | Declare Crosswake policy next to Phoenix routes with macro support and compile-time validation | |
| Separate module/manifest DSL | Keep policy in a separate module or registry and compile independently of the router | |
| Hybrid router + compiled policy module | Author in the router, normalize into policy data, and keep manifest generation downstream | ✓ |
| External JSON/TOML authoring | Use a native-consumable external manifest as the primary authoring surface | |

**User's choice:** Delegated to agent research-backed recommendation.
**Locked outcome:** Hybrid router-adjacent DSL with `crosswake:` route metadata and scope defaults, compiled into normalized policy data and Phoenix route metadata.
**Notes:** Chosen for least surprise, verified-route locality, and future manifest generation without duplicating route strings.

---

## Runtime taxonomy and naming

| Option | Description | Selected |
|--------|-------------|----------|
| `live_view`, `offline_island`, `native_screen` + orthogonal metadata | Small public surface with clear ownership classes | ✓ |
| Keep `adapter` as a fourth route class | Preserve broader ladder directly in the public DSL | |
| Expose the full internal capability ladder as route classes | Maximal explicitness in the public API | |

**User's choice:** Delegated to agent research-backed recommendation.
**Locked outcome:** Public runtime taxonomy is `:live_view`, `:offline_island`, `:native_screen`. `adapter` is reserved for later extension points, not route ownership.
**Notes:** Avoids category sprawl and keeps ownership distinct from capabilities or integration mechanisms.

---

## Route metadata surface

| Option | Description | Selected |
|--------|-------------|----------|
| Inline Crosswake opts on route macros | Strong DX, strong validation, router-local policy | ✓ |
| Reuse raw Phoenix/LiveView metadata maps only | Minimal novelty, weaker typing and semantic guidance | |
| Separate `Crosswake.Manifest.routes/0` registry | Cleaner standalone schema, but duplicates route truth | |

**User's choice:** Delegated to agent research-backed recommendation.
**Locked outcome:** Require `id` and `runtime`; default narrow route metadata; use typed option schemas plus semantic normalization; keep the Phase 1 surface focused on runtime, offline, capabilities, packs, sync, and security sensitivity.
**Notes:** Defaults should be honest and safe, not magical.

---

## Compile-time validation posture

| Option | Description | Selected |
|--------|-------------|----------|
| Permissive | Only syntax and basic shape errors fail at compile time | |
| Layered strictness | Local contradictions fail at compile time; environment and release truth defer to later checks | ✓ |
| Hardline | Full coverage and platform/release truth enforced at compile time | |

**User's choice:** Delegated to agent research-backed recommendation.
**Locked outcome:** Strict on local declarative truth, layered on world truth.
**Notes:** Compile-time errors should be contextual and actionable; full adoption breadth should not be blocked by environment-dependent checks.

---

## Generator and ownership boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal installer | Patch host app only and leave most setup manual | |
| Generator plus manifest bootstrap | Additive install plus shell scaffolding with explicit ownership boundaries | ✓ |
| Heavy app template | Full-stack scaffold as the main public entrypoint | |

**User's choice:** Delegated to agent research-backed recommendation.
**Locked outcome:** `mix crosswake.install` plus `mix crosswake.gen.shell ios|android` as the default public path.
**Notes:** Generated host and native files are host-owned; Crosswake should not masquerade as a replacement app framework.

---

## the agent's Discretion

- Downstream agents should make most implementation choices without reopening them unless the choice would materially alter public contract or product boundaries.
- Internal module boundaries, helper naming, warning phrasing, and exact implementation tactics remain discretionary.

## Deferred Ideas

- Desktop packaging and Electron support
- Billing/store-policy automation
- Advanced animation and audio subsystems
- Deep CI/CD, E2E proof-lane, telemetry, and release choreography details
- Companion-package integrations beyond the core route-policy contract
