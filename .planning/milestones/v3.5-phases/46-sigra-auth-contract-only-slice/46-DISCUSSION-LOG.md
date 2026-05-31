# Phase 46: Sigra Auth Contract-Only Slice - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 46-Sigra Auth Contract-Only Slice
**Areas discussed:** Contract shape, RouteGate semantics, Doctor/support truth

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| All core areas | Clarify contract shape, route predicate semantics, and diagnostics/support posture together; this best preserves the auth boundary. | yes |
| Contract only | Focus on AuthContext and SessionAuthorityLane, leaving route-gate and diagnostics details mostly to the planner. | |
| Gate/support only | Focus on auth_min_level, requires_recent_auth, :step_up_required, doctor, and support-matrix truth. | |

**User's choice:** discuss/consider all and use subagent-backed research for
pros/cons/tradeoffs, ecosystem lessons, great DX, and one cohesive recommendation.

**Notes:** User specifically requested recommendations that cohere with the
project vision, principle of least surprise, Phoenix/Elixir ecosystem idioms,
and prompt-corpus research.

---

## Contract Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Layered typed contracts | `AuthContext` + `SessionAuthorityLane` + `StepUpChallenge` + explicit evidence lane, with constructors/validators mirroring commerce/rindle. | yes |
| Flattened AuthContext | Single struct mixing authority and evidence fields, plus a predicate evaluator. | |
| Ecto embedded_schema | Ecto changeset-backed contract validation. | |

**User's choice:** approved the recommendation.

**Notes:** Research favored layered typed contracts as the least-surprise
Crosswake shape. Flattening authority/evidence was rejected as future migration
and security risk. Ecto was rejected for the core seam because this is a pure
runtime contract layer, not persistence/form validation.

---

## RouteGate Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Route-local core predicates | Add `auth_min_level` and `requires_recent_auth` to DSL/manifest and evaluate in `RouteGate` using backend-owned auth context. | yes |
| Companion-only auth decision | Let a Sigra companion own auth allow/deny behavior with minimal core DSL. | |
| Phoenix/Plug-only gate | Keep auth primarily in host Phoenix router/plugs and have Crosswake mirror little or none of it. | |

**User's choice:** approved the recommendation.

**Notes:** Route-local predicates preserve Crosswake's route-policy thesis and
give the shell canonical fail-closed semantics. Companion-only and Plug-only
approaches were rejected because they fragment manifest truth and weaken
operator support visibility.

---

## Doctor And Support Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated auth doctor/support truth | Add auth route diagnostics and support-matrix contract truth parallel to gating/commerce. | yes |
| Minimal doctor-only findings | Emit route predicate findings but keep support matrix mostly static. | |
| Full auth_summary runtime surface | Add a richer auth summary now, mirroring commerce_summary. | |

**User's choice:** approved the recommendation.

**Notes:** Dedicated auth truth matches existing product-surface posture without
overbuilding full runtime machinery. The richer `auth_summary` idea was kept as
a future option but explicitly not selected for Phase 46.

---

## the agent's Discretion

- Exact module names under `Crosswake.Companions.Sigra`.
- Exact auth-level vocabulary names, provided they are closed and ordered.
- Exact `requires_recent_auth` input syntax, with a bias toward seconds.
- Exact doctor code names, provided they remain auth-specific and stable.
- Exact test file names.

## Deferred Ideas

- Real Sigra optional dependency/advisory lane.
- Session handoff tickets.
- Step-up ceremony and UX.
- Native passkey escape hatch.
- OAuth Auth-Code + PKCE implementation.
- Refresh-token rotation grace-window behavior.
- Chimeway and Threadline consumers of the auth contract.
