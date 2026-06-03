# Phase 42: Rulestead In-Tree Companion And Mock Example - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 42-rulestead-in-tree-companion-and-mock-example
**Areas discussed:** Mock flag source model, Mock flag source location, Phoenix_host route design, validate_dependency/0 module target

---

## Mock flag source model

| Option | Description | Selected |
|--------|-------------|----------|
| Agent/ETS process | Named Agent stores flag_key => gate_state map; mutated at runtime via `set_flag/2` | ✓ |
| Config-time module swap | Behaviour/callback module; mock is a hardcoded stub; swapping = changing Application config | |
| ETS table by convention | Companion reads ETS table by predictable name; no process to start | |

**Sub-question — Agent store shape:**

| Option | Description | Selected |
|--------|-------------|----------|
| flag_key => gate state atom/tuple | `%{flag_atom => :gated \| {:rolling_out, pct} \| :killed}` | ✓ |
| flag_key => {:deny\|:pass, details} | Stores decision directly; companion just forwards stored value | |
| Claude decides | Open to Claude's judgment on shape | |

**User's choice:** Named Agent with `flag_key => gate_state` map.
**Notes:** Runtime mutability is key — the user wants to drive gate state changes during
local dev and hermetic proof without restarts. Storing gate state as semantic atoms
(`:gated`, `{:rolling_out, n}`, `:killed`) rather than pre-built decisions keeps the
companion responsible for the mapping logic.

---

## Mock flag source location

| Option | Description | Selected |
|--------|-------------|----------|
| In the companion lib | `lib/crosswake/companions/rulestead/mock_flag_source.ex` — distributed with library | ✓ |
| In phoenix_host only | `examples/phoenix_host/lib/` — example-only | |
| In test/support | `test/support/` — test-only, IEx seeding for local dev | |

**Sub-question — real adapter in Phase 42?**

| Option | Description | Selected |
|--------|-------------|----------|
| Mock-only for Phase 42 | Real Rulestead.Snapshot adapter deferred to Phase 43 | ✓ |
| Both real + mock | Phase 42 includes real adapter alongside mock | |

**User's choice:** MockFlagSource in companion lib; mock-only for Phase 42.
**Notes:** Putting the mock in the library makes it reusable for any host app's tests.
The real Rulestead.Snapshot integration belongs in Phase 43's advisory lane.

---

## Phoenix_host route design

| Option | Description | Selected |
|--------|-------------|----------|
| One route, mock-mutable | Single `/gating/beta-feature` route; state driven by mutating Agent | ✓ |
| Three routes, static mocks | Three routes with different flag names per gate state | |
| Claude decides | Open to Claude's judgment | |

**Sub-question — on_unavailable posture:**

| Option | Description | Selected |
|--------|-------------|----------|
| :deny | Fail closed, :halt transition | ✓ |
| {:fallback_phoenix, route_id} | Demonstrates redirect posture | |

**Sub-question — scope/path:**

| Option | Description | Selected |
|--------|-------------|----------|
| "/gating" scope | New sibling scope to /commerce and /study | ✓ |
| Under existing scope | Add to selective-native or saas_portal | |
| Claude decides | Open to Claude's judgment | |

**User's choice:** One route, `:deny`, under `/gating` scope.
**Notes:** Single mutable route keeps the example focused. Three separate routes would
suggest gate state is a per-route config rather than a runtime value.

---

## validate_dependency/0 module target

| Option | Description | Selected |
|--------|-------------|----------|
| Rulestead (top-level) | `Code.ensure_loaded?(Rulestead)` — root module only | ✓ |
| Rulestead.Snapshot | Checks the sub-module the companion actually uses | |
| Rulestead + Rulestead.Snapshot | Checks both; returns all missing modules | |

**User's choice:** `Rulestead` root module only.
**Notes:** Simple and consistent with Phase 38's validate_dependency pattern. The root
module is the canonical presence signal for the Hex package.

---

## Claude's Discretion

- Exact module layout within `lib/crosswake/companions/rulestead/` — single file vs. directory
- `Agent` vs bare `GenServer` for MockFlagSource
- Exact scaffold for the `/gating/beta-feature` LiveView/controller (name, what it renders)
- Proof test structure for SC#1–SC#3 (follows prior proof conventions)
- How `report_state/0` maps `:killed` to `gate_status` + `kill_switch_status` pairing

## Deferred Ideas

- Real `Rulestead.Snapshot` adapter — Phase 43 advisory lane
- `{:fallback_phoenix}` posture demonstration in phoenix_host — future docs or phase
- `kill_switch_status` richer typespec — still deferred from Phase 41
- Companion-supplied `reason`/`variant` via `finding.subject` — still Phase 40 D-05 deferred
