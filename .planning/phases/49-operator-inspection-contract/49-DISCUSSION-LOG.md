# Phase 49: Operator Inspection Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 49-Operator Inspection Contract
**Areas discussed:** Inspection surface boundary, machine-readable schema, readiness vocabulary

---

## Inspection Surface Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone task and module | `mix crosswake.inspect --format human\|json` backed by `Crosswake.OperatorInspection`; clear operator intent and stable JSON contract. | |
| Doctor-only extension | Fold inspection into `mix crosswake.doctor --inspect`; reuses diagnostics pipeline but overloads doctor semantics. | |
| Manifest/support-matrix only | Treat existing manifest/support APIs as the inspection API; maximal reuse but poor operator DX and weak discoverability. | |
| Hybrid standalone inspector backed by canonical truth | New inspect task and core module source truth from manifest/support/doctor data; doctor may consume it later. | yes |

**User's choice:** Consider all options with subagent-backed research and return a cohesive recommendation.

**Notes:** Research recommended the hybrid. It preserves a clean inventory/readiness boundary while keeping doctor findings-first. It follows ecosystem precedent where human inspection and machine JSON are explicit public surfaces and avoids making CI scrape diagnostic prose.

---

## Machine-Readable Schema

| Option | Description | Selected |
|--------|-------------|----------|
| Route-centric primary | Route entries are authoritative; cross-cutting queries scan routes unless indexes are added. | |
| Section-centric | Top-level capability/companion/auth/notification sections; readable by domain but risks contradictory joins. | |
| Finding-centric | Diagnostics records are primary; good for CI annotations but absence-as-truth is dangerous. | |
| Manifest extension | Embed a versioned operator inspection document alongside manifest truth. | |
| Route-centric with derived indexes and findings | Route entries are authoritative; indexes and findings are derived sidecars. | yes |

**User's choice:** Consider all options with subagent-backed research and return a cohesive recommendation.

**Notes:** Research recommended a versioned route-centric document with derived indexes and findings. Locked top-level categories are `schema_version`, `generated_at`, `crosswake_version`, `source`, `summary`, `routes`, `indexes`, `findings`, and `provenance`.

---

## Readiness Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse Crosswake split vocabularies | Keep support status, severity, proof class, rebuild class, denial reason, and gate state as separate axes. | yes |
| Kubernetes-like Conditions only | Familiar operator model but booleans can be mistaken for global health. | |
| Doctor severity led | Strong triage but severity is not support truth. | |
| Custom unified readiness state | Simple human column but hides independent fail-closed dimensions. | |
| Current vocabularies plus condition-like records | Preserve Crosswake terms and add machine-readable condition wrappers. | yes |

**User's choice:** Consider all options with subagent-backed research and return a cohesive recommendation.

**Notes:** Research recommended preserving existing Crosswake vocabularies and using condition-like records only as derived wrappers. The inspector must not collapse advisory proof, rebuild requirements, auth predicates, provider readiness, or notification-token snapshots into a single global green state.

---

## the agent's Discretion

- Exact module and formatter names are planner discretion if the public boundary remains `mix crosswake.inspect` plus `Crosswake.OperatorInspection`.
- Exact index set is planner discretion if route entries remain authoritative.
- Exact human output layout is planner discretion if it stays concise, route-centric, and non-authoritative relative to JSON.
- Exact Phase 50 doctor integration is planner discretion; bias toward reusing the inspection core rather than adding duplicate readiness logic.

## Deferred Ideas

- `mix crosswake.doctor --check-publish` readiness findings belong to Phase 50.
- Support-matrix and native rebuild public guidance expansion belongs to Phase 51.
- Operator proof lanes and docs-contract locks belong to Phase 52.
- Provider adapters, full Sigra machinery, Chimeway delivery, and standalone shell packages remain future milestone work.
