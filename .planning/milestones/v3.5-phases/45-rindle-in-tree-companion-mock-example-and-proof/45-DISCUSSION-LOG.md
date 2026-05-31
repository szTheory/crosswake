# Phase 45: Rindle In-Tree Companion, Mock Example, And Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 45-rindle-in-tree-companion-mock-example-and-proof
**Areas discussed:** Mock surface and API boundary, example-host flow, proof and optional dependency isolation

---

## Mock Surface And API Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Library-shipped full mock module | Put the mock upload/verify workflow under `lib/crosswake/companions/rindle`; strongest reuse but risks making Crosswake own app workflow. | |
| Example-host-only mock | Keep all mock workflow code in `examples/phoenix_host`; cleanest core boundary but weaker reuse and higher drift risk. | |
| Split invariant helpers + example orchestration | Core owns invariant helpers and companion contract; example host owns workflow. | yes |

**User's choice:** Discuss all areas with sub-agent research and produce one cohesive recommendation.
**Notes:** Advisor research recommended the split. It best preserves Crosswake's
route-boundary thesis while improving DX through reusable invariants.

---

## Example-Host Flow

| Option | Description | Selected |
|--------|-------------|----------|
| LiveView proof page with explicit media modules | Route in `phoenix_host` shows honest state transitions while modules keep evidence/projection boundaries clear. | yes |
| Module-only proof | Smallest deterministic proof, but weak adopter-facing DX and no user-visible state copy. | |
| Controller/API proof | Realistic backend upload shape but more boilerplate and less aligned with existing commerce walkthrough. | |
| Native/bridge-ish capture simulation | Closest to real capture but high scope and proof fragility for Phase 45. | |

**User's choice:** Discuss all areas with sub-agent research and produce one cohesive recommendation.
**Notes:** Advisor research recommended `/media/proof` as a LiveView-first teaching
surface backed by `MockCapture`, `ReconciliationInbox`, and `MediaProjection`.

---

## Proof And Optional Dependency Isolation

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror Phase 43 for Rindle | Conditional `MIX_INCLUDE_RINDLE=1`, merge-blocking hermetic lane, advisory scheduled lane, separate advisory test. | yes |
| Hermetic-only | Smallest scope, but loses dependency-present verification and promotion-path visibility. | |
| Separate explicit advisory test target | Clean absent-vs-present assertion semantics; essentially the selected Phase 43 mirrored pattern. | yes |
| Fake `Rindle` module fixture | Fast but not a real integration signal and risks false confidence. | |

**User's choice:** Discuss all areas with sub-agent research and produce one cohesive recommendation.
**Notes:** Advisor research recommended mirroring Phase 43 exactly: `Code.ensure_loaded?(Rindle)`,
`MIX_INCLUDE_RINDLE=1`, `:advisory_only` dependency-present test, and a
`phase45-proof.yml` workflow.

---

## the agent's Discretion

- Exact example module names may change if planner finds a better local naming pattern.
- Exact helper location is planner discretion; core helpers are allowed only for reusable invariants.
- Exact CI runner/cron/timeout values should follow existing proof workflow patterns.

## Deferred Ideas

- Real Rindle adapter and provider/storage behavior.
- Native capture/bridge proof.
- Upload progress, resumability, multipart/provider SDKs, variants, scanning, thumbnails, and CDN delivery.
- Full Rindle guide section and cross-companion docs-contract parity, owned by Phase 47.
