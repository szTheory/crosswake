# Phase 41: Gating Doctor And Support-Matrix Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 41-gating-doctor-and-support-matrix-truth
**Areas discussed:** Doctor output structure, Unknown gated_by severity, rolling_out (N%) data source, {:fallback_phoenix} doctor visibility

---

## Doctor output structure

**Q1: Separate 'Gating' category or append to companion findings?**

| Option | Description | Selected |
|--------|-------------|----------|
| New 'Gating' category | Dedicated sibling category — mirrors Phase 38's 'Companion Dependencies' and commerce corridors. Easier for operators to scan. | ✓ |
| Append to Companion category | Gating findings land inside existing companion section. Less clutter but mixes concerns. | |

**User's choice:** New 'Gating' category (Recommended)
**Notes:** Consistent with how each concern gets its own section.

---

**Q2: One finding per gated route vs. single summary finding?**

| Option | Description | Selected |
|--------|-------------|----------|
| One finding per gated route | Mirrors phase_19_commerce_corridor_posture. Makes per-route severity and details natural. | ✓ |
| Single summary finding | Simpler for many routes, but harder to attach per-route errors cleanly. | |

**User's choice:** One finding per gated route (Recommended)

---

**Q3: Severity for per-route informational finding?**

| Option | Description | Selected |
|--------|-------------|----------|
| :info | Gating is intentional config — communicates posture without implying a problem. | ✓ |
| :warning | Would create noise for intentionally-gated routes. | |

**User's choice:** :info (Recommended)

---

## Unknown gated_by severity

**Q1: Severity for unresolvable flag reference?**

| Option | Description | Selected |
|--------|-------------|----------|
| :error | Mirrors companion.dependency_missing. Unresolvable reference = gate can't evaluate. Merge-blocking. | ✓ |
| :warning | Less strict — route is still fail-closed. Advisory posture. | |

**User's choice:** :error (Recommended)

---

**Q2: Empty companions list handling?**

| Option | Description | Selected |
|--------|-------------|----------|
| Same :error per gated route | Each gated route fires "flag_reference_unknown" :error. Consistent with per-route pattern. | ✓ |
| Distinct 'no companions registered' :error | One top-level error. Cleaner signal but adds separate code path. | |

**User's choice:** Same :error per gated route (Recommended)

---

## rolling_out (N%) data source

**Q1: Where does rolling_out percentage come from?**

| Option | Description | Selected |
|--------|-------------|----------|
| Richer gate_status typespec: {:rolling_out, non_neg_integer()} | Companion.State.gate_status grows a tagged-tuple variant. Clean typed contract. | ✓ |
| Derive from report_state() details map | gate_status stays atom; percentage in details["rollout_percentage"]. Magic key concern. | |

**User's choice:** Richer gate_status typespec (Recommended)

---

**Q2: Should kill_switch_status also be extended?**

| Option | Description | Selected |
|--------|-------------|----------|
| Keep kill_switch_status as :inactive \| :active \| :unconfigured | Kill switches are binary — no percentage applies. | ✓ |
| Also extend kill_switch_status | Carry reason_string. No Phase 41 requirement driving this. | |

**User's choice:** Keep as-is (Recommended) — defer to Phase 42+

---

**Q3: Display mapping for gate-state column?**

| Option | Description | Selected |
|--------|-------------|----------|
| :active → 'gated', {:rolling_out, N} → 'rolling_out (N%)', active kill_switch → 'killed' | Clean semantic mapping. Kill switch takes precedence over gate_status. | ✓ |
| Let planner decide | Defer mapping. | |

**User's choice:** Locked mapping (Recommended)

---

## {:fallback_phoenix} doctor visibility

**Q1: How to surface on_unavailable: {:fallback_phoenix, route_id}?**

| Option | Description | Selected |
|--------|-------------|----------|
| Detail/hint on the per-route :info finding | Uses existing hint field. No extra finding noise. | ✓ |
| Separate :info finding per route with fallback | More visible but doubles findings per route. | |
| Silently in details map | Discoverable via --json but not highlighted. | |

**User's choice:** Detail/hint on the per-route :info finding (Recommended)

---

**Q2: Validate fallback route_id exists in manifest?**

| Option | Description | Selected |
|--------|-------------|----------|
| Validate and emit :warning if route_id unknown | Catches typos at doctor-run time. Consistent with unknown gated_by :error approach. | ✓ |
| Surface as-is, no validation | Simpler but typo'd route_id is silent until production. | |

**User's choice:** Validate and emit :warning (Recommended)

---

## Claude's Discretion

- Exact finding code strings (suggested: `"gating.route_registered"`, `"gating.flag_reference_unknown"`, `"gating.fallback_route_unknown"`)
- Whether to call `report_state/0` inside the gating check or reuse Phase 38's companion state
- Exact support-matrix accessor function name (suggested: `SupportMatrix.gating_truth/0`)
- Column label text and placement in rendered support-matrix output

## Deferred Ideas

- `kill_switch_status` richer typespec with reason string — Phase 42+
- Multiple companion gate-state rows in support matrix — Phase 42+
