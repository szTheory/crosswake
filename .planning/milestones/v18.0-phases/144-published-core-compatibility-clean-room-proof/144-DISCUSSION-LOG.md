# Phase 144: Published-Core Compatibility & Clean-Room Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 144-Published-Core Compatibility & Clean-Room Proof
**Areas discussed:** Dependency Proof Exactness, Fresh Router Doctor Proof, Merge-Blocking Guardrails, Package Matrix Coverage

---

## Dependency Proof Exactness

| Option | Description | Selected |
|--------|-------------|----------|
| Local `mix.exs` floor + exact companion pin | Simple and close to current script, but proves checkout state rather than published package metadata. | |
| Hex release metadata floor + exact companion pin | Derives the core requirement from the published package under test and pins the companion exactly. | X |
| Resolver/lockfile-derived proof | Proves actual dependency resolution after `deps.get`, but cannot be the floor authority by itself. | |
| Static compatibility matrix | Fast docs drift guard, but not release truth. | |

**User's choice:** User selected all gray areas and asked for subagent research plus one-shot recommendations.
**Notes:** Recommendation locks Hex release metadata as the floor authority and uses lockfile assertions as postconditions.

---

## Fresh Router Doctor Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Mix-task-owned load path | `crosswake.doctor` owns host-code readiness through `@requirements ["app.config"]` or equivalent. | X |
| Harness-owned precompile/preload | Minimal script repair, but proves the harness more than the doctor task. | |
| Doctor fallback compile-on-miss | Localized fallback, but risks Mix task state footguns and misleading errors. | |
| Router source/path proof | Useful supplemental unit fixture, but bypasses adopter-like Mix app behavior. | |

**User's choice:** User delegated recommendation after research.
**Notes:** Recommendation makes the doctor task responsible for loading fresh routers, while the clean-room harness avoids pre-loading the router as the proof.

---

## Merge-Blocking Guardrails

| Option | Description | Selected |
|--------|-------------|----------|
| Extend existing Elixir semantic scanner + ExUnit fixtures | Deterministic, repo-local, stable check IDs, and can encode Crosswake release policy. | X |
| Add `actionlint` | Useful generic syntax/shell lint, but cannot prove Crosswake package identity policy and currently conflicts with `queue: max`. | |
| Introduce YAML parser | More structured reads, but still needs expression-policy checks and adds dependency weight. | |
| Generate workflow policy from release graph contract | Strong future source-of-truth option, but overbuilt for Phase 144. | |

**User's choice:** User delegated recommendation after research.
**Notes:** Recommendation keeps the semantic scanner authoritative and treats actionlint as deferred/additive.

---

## Package Matrix Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| All five packages, common structural proof with package-specific smoke profiles | Covers the whole package family while preserving package-specific optional dependency and observer semantics. | X |
| Only newer `~> 0.2` packages | Smaller but leaves older public packages with weaker family guarantees. | |
| Tiered all-package proof | Balanced fallback if CI cost becomes a blocker, but risks shallow proof becoming accepted as equivalent. | |

**User's choice:** User delegated recommendation after research.
**Notes:** Recommendation covers `rulestead`, `rindle`, `sigra`, `chimeway`, and `threadline`; assertions vary by package profile.

---

## Claude's Discretion

- Helper names, JSON parsing mechanics, and exact ExUnit organization are left to downstream planning.
- Policy choices are locked unless official Hex, Mix, GitHub Actions, or Release Please behavior contradicts the research.

## Deferred Ideas

- Phase 145: native registry recovery/backfill and missing iOS `v0.2.0` mirror tag.
- Phase 146: final release-status text/JSON/live-probe DX.
- Future: generated release graph contract or structured YAML parser if scanner brittleness becomes real.
- Future: additive actionlint lane once pinned tooling supports current GitHub `queue: max`.
