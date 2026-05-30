# Phase 39: Route-Policy Gating DSL And Manifest Binding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 39-route-policy-gating-dsl-and-manifest-binding
**Areas discussed:** Custom validator semantics, on_unavailable DSL scope, Doctor visibility (SC#2), Proof test strategy

---

## Custom Validator Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Any atom (not nil/true/false) | Accepts any atom; rejects booleans and nil; allows `:"feature.flag"`, `:"my-flag"` | |
| Snake_case atom identifier | Regex enforces snake_case shape; rejects quoted atoms with dots/hyphens, CamelCase | ✓ |
| You decide | Planner picks validation strictness | |

**User's choice:** Snake_case atom identifier (Approach B) — after advisor research
**Notes:** User requested ecosystem research before deciding. Research confirmed: FunWithFlags, Ecto, Absinthe, Oban all use snake_case atoms in DSL surfaces. External platform kebab-case keys belong at the companion adapter boundary (adapter does `Atom.to_string(route.gated_by)`). Clean `inspect/1` output (`:my_flag` not `:"my-flag"`) is decisive for doctor and denial details readability.

---

## on_unavailable DSL Scope

### In-scope or deferred?

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 39 — declare in DSL now | Add `on_unavailable` alongside `gated_by`; build-time posture recorded in manifest | ✓ |
| Phase 40 — runtime concern only | Phase 39 adds only `gated_by`; `on_unavailable` wired in Phase 40 | |
| You decide | Planner decides | |

**User's choice:** Phase 39 — declare it now, record in manifest

### Valid values

| Option | Description | Selected |
|--------|-------------|----------|
| `:deny \| {:fallback_phoenix, route_id}` | Default :deny; explicit tuple for fallback to Phoenix-owned route | ✓ |
| `:deny` only | Phase 39 locks fail-closed only; tuple form comes later | |
| You decide | Planner picks valid value set | |

**User's choice:** `:deny | {:fallback_phoenix, route_id}`

### Co-occurrence constraint

| Option | Description | Selected |
|--------|-------------|----------|
| Only valid when gated_by is set | Setting on_unavailable without gated_by is a compile error | ✓ |
| Any route can declare on_unavailable | More permissive | |
| You decide | Planner decides | |

**User's choice:** Only valid when `gated_by` is set (companion validation)

### Default value

| Option | Description | Selected |
|--------|-------------|----------|
| `:deny` (fail-closed by default) | Omitting on_unavailable when gated_by is set defaults to :deny | ✓ |
| Required (no default) | Must be explicit | |
| You decide | Planner decides | |

**User's choice:** `:deny` (fail-closed default)

### route_id validation

| Option | Description | Selected |
|--------|-------------|----------|
| Snake_case identifier only | Validated as atom at compile time; no cross-check against declared routes | ✓ |
| Cross-validate against declared routes | Compile-time check; tricky ordering concerns | |
| You decide | Planner decides | |

**User's choice:** Snake_case identifier only — cross-check is Phase 41 doctor scope

---

## Doctor Visibility (SC#2)

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest field only — introspection sufficient | SC#2 satisfied by manifest carrying gated_by; no new doctor code | |
| Minimal doctor annotation — gated routes noted in route section | Small tweak to doctor run/1; no new category | |
| You decide | Planner decides minimal touch | ✓ |

**User's choice:** Planner discretion — read `doctor.ex` to decide the minimal approach satisfying SC#2 without pre-empting Phase 41's full gating category.

---

## Proof Test Strategy

### File structure

| Option | Description | Selected |
|--------|-------------|----------|
| New phase39_*_test.exs file | Matches Phase 38 pattern; untagged; picked up by phase34-proof.yml | ✓ |
| Extend Phase 38 test file | Fewer files but mixed concerns | |
| You decide | Planner decides | |

**User's choice:** New `test/crosswake/proof/phase39_route_policy_gating_test.exs`

### Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| DSL validation errors (SC#1) | Invalid gated_by values produce clear NimbleOptions errors | ✓ |
| Manifest round-trip (SC#2/SC#3) | RouteEntry carries correct fields; to_map serializes them | ✓ |
| Introspection readability (SC#2) | Pattern-matchable fields; clean inspect output | ✓ |
| All of the above | Full coverage | ✓ |

**User's choice:** All of the above, plus SC#3 binding-vs-value split assertion (explicit: no `gated_by_value`/`flag_state` field on RouteEntry). Shift-left / DevOps mindset: happy paths + error cases + boundary conditions.

---

## Claude's Discretion

- Exact JSON shape for `{:fallback_phoenix, route_id}` in `to_map/1` (flat string vs nested map — must be reversible)
- Minimal doctor touch for SC#2 (manifest field only vs. route-listing annotation)
- `validate_flag_key/1` function name and location in `Policy.Schema`
- NimbleOptions schema entry shape for `on_unavailable` (`:or` type vs `:custom` validator)
- Describe/test block naming for the proof test (follow `phase38_companion_contract_test.exs` style)

## Deferred Ideas

- `{:fallback_phoenix, route_id}` cross-validation against declared routes — Phase 41 doctor
- Runtime gate evaluation (`route_gated?/2` → `RouteGate` wiring) — Phase 40
- Kill-switch short-circuit — Phase 40
- Full gating doctor category + runtime gate-state support-matrix column — Phase 41
- `crosswake_openfeature` companion adapter — v3.6+
