# Phase 23: Commerce Support And Proof Closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `23-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 23-commerce-support-and-proof-closure
**Areas discussed:** Doctor diagnostics shape, Support matrix truth source and granularity, Merge-blocking vs advisory proof boundaries, Reviewer/storefront docs structure

---

## Doctor diagnostics shape

| Option | Description | Selected |
|--------|-------------|----------|
| Extend flat findings only | Minimal churn, but support/proof truth remains implicit and harder to operate. | |
| Typed `commerce` summary + existing findings | Explicit support truth plus stable enforcement stream, better parity across doctor/docs/support. | ✓ |
| Provider-probe core doctor | Realism but scope breach, flakiness risk, and provider leakage into core. | |

**User's choice:** Auto-selected recommended option (typed `commerce` summary + stable findings stream).
**Notes:** Emphasis placed on least surprise, explicit merge-blocking/advisory signals, and provider-neutral core contracts.

---

## Support matrix truth source and granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Code-owned typed canonical registry | Deterministic, testable, fail-closed, and already aligned with current renderer/parity posture. | ✓ |
| Manifest-first computed matrix | High host precision but weak stable library-level support truth and noisy churn. | |
| Docs/data-file-first truth | Easy editing but high drift risk and weaker semantic enforcement. | |

**User's choice:** Auto-selected recommended option (code-owned typed canonical support truth).
**Notes:** Granularity locked at contract surface level (not per-route explosion), with explicit proof class and rebuild posture fields.

---

## Merge-blocking vs advisory proof boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| All commerce proof merge-blocking | Max strictness but flaky/non-hermetic lanes degrade trust and throughput. | |
| Split hermetic blocking + advisory provider/storefront/device | Deterministic merge truth with honest advisory posture until adapter milestones. | ✓ |
| Minimal blocking + mostly advisory | Fast short-term throughput but weak support-claim integrity. | |

**User's choice:** Auto-selected recommended option (split deterministic blocking vs advisory lanes).
**Notes:** Branch-required checks should remain hermetic; advisory lanes publish evidence without redefining core claims.

---

## Reviewer/storefront docs structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single linear guide | Easy start, but weak scanability and blurry support/proof boundaries. | |
| Layered matrix-first docs hub | Clear claim boundaries, explicit advisory labels, better reviewer/operator usability. | ✓ |
| Checklist-only generated docs | Strong auditability, but weaker onboarding and conceptual clarity alone. | |

**User's choice:** Auto-selected recommended option (layered matrix-first docs hub).
**Notes:** Require explicit non-claims, reviewer note templates, canonical fallback wording, and role-based navigation.

---

## Claude's Discretion

- Exact naming/shape of doctor `commerce` payload fields.
- Exact CI job naming and artifact naming for advisory proof publication.
- Exact docs section ordering so long as proof-class labeling and non-claims remain explicit.

## Deferred Ideas

None — discussion stayed within Phase 23 scope.
