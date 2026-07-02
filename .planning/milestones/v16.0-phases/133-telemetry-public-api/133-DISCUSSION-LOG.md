# Phase 133: Telemetry Public API - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-27
**Phase:** 133-telemetry-public-api
**Areas discussed:** Scope (instrument vs document-only), events/0 return shape, Companion events + core independence, Keathley naming enforcement

**Method:** User selected all four areas and requested deep research-then-recommend (per [[feedback-research-then-recommend]]): 3 parallel subagents researched Elixir/Phoenix telemetry idioms + ecosystem prior art (Oban/Ecto/Phoenix/Finch/telemetry_registry), the multi-package-without-compile-coupling problem, and the internal prompts/ research + brandbook. A single coherent recommendation set was synthesized and approved wholesale ("Yes — lock all").

**Scout correction:** research found the codebase already has a mature per-subsystem telemetry house pattern + 5 emitting Keathley-compliant `[:crosswake, ...]` span events — so the phase is an aggregating facade, not greenfield.

---

## Scope (instrument vs document-only)

| Option | Description | Selected |
|--------|-------------|----------|
| Instrument-now | Add emission across all subsystems so events/0 is broad | |
| Scaffold over real seed | events/0 = already-emitting events; defer breadth to additive minors | ✓ |
| Hybrid | Aggregate now + instrument 1-2 cheap gaps | |

**User's choice:** Scaffold over the real seed (D-01/02/03).
**Notes:** Contract test green from day one; matches how Ecto/Phoenix/Finch/Oban grew telemetry; reconcile existing declared-but-unemitted Sigra/Chimeway/Offline events into a reserved tier.

---

## events/0 return shape

| Option | Description | Selected |
|--------|-------------|----------|
| Flat name lists | `[[:crosswake,:sub,:start],...]` — matches current house pattern | |
| Self-describing maps | `%{event,description,measurements,metadata}`, runtime-aggregated | ✓ |

**User's choice:** Self-describing maps, runtime-aggregated (D-04/05/06).
**Notes:** Single source of truth for guide + contract test + future DASH-01 dashboard. Runtime (not compile-time) aggregation avoids the v7.0 SupportMatrix stale-`.beam` drift.

---

## Companion events + core independence

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Federated, no unified catalog | Each package exposes its own events/0; consumer merges by hand | |
| (b) Core hardcodes companion events | Static atom lists in core (dodges grep but recreates coupling) | |
| (c) Runtime registry via optional behaviour callback | Core walks `:companions` registry + `function_exported?/3` | ✓ |

**User's choice:** (c) optional `telemetry_events/0` callback + runtime merge (D-07..D-10).
**Notes:** Gives the unified TELEM-01 catalog AND honors core-independence in substance (core names no companion); extracted adapters self-declare; fail-closed with no companions configured.

---

## Keathley naming enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Normalize/rename in-tree + companion events | Breaking; clean | |
| Nothing in-tree; rindle is a package concern | In-tree already compliant; rindle normalizes in its own CHANGELOG | ✓ |

**User's choice:** No in-tree renames; rindle event normalization deferred to the `crosswake_rindle` package (D-11/D-12).
**Notes:** In-tree `[:crosswake, ...]` events already follow Keathley; the only non-compliant ones are in the pre-1.0 rindle package.

---

## Claude's Discretion

- The `reserved`-tier mechanism vs down-scoping (D-02), whether to ship `spannable_events/0` (D-06), exact `event_doc` typespec, module/file layout, and doc-generator approach — left to the planner, consistent with the locked decisions.

## Deferred Ideas

- Broad per-rule/per-diagnostic instrumentation → additive minors after 133.
- Rindle `[:rindle, :media, :transcode, stage]` normalization → `crosswake_rindle` package + CHANGELOG.
- DASH-01 operator dashboard (`crosswake_dashboard`) → deferred milestone; 133 is its prerequisite.
</content>
