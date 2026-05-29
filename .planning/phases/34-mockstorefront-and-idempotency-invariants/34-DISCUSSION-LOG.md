# Phase 34: MockStorefront And Idempotency Invariants - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 34-MockStorefront And Idempotency Invariants
**Areas discussed:** Provider identity derivation, Restore identity semantics, Determinism / clock seam, Function/return shape + swap-doc
**Mode:** advisor (calibration tier `minimal_decisive`, technical framing — `NON_TECHNICAL_OWNER = false` via `technical_background: true` override)

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Provider identity derivation | How `simulate_purchase/1` synthesizes `provider_reference` + `evidence_ref` from `entry_id`, not `correlation_id` | ✓ |
| Restore identity semantics | What stable subject a mock restore resolves to (no `entry_id` in `RestoreIntent`) | ✓ |
| Determinism / clock seam | Whether `captured_at` is injectable for the hermetic Phase 36 proof | ✓ |
| Function/return shape + swap-doc | Raw struct vs `{:ok, _}`; `@moduledoc` swap-target wording | ✓ |

**User's choice:** All four areas selected.
**Notes:** No external researcher agents spawned — these are domain-modeling decisions against
already-read shipped contracts, not ecosystem-idiom questions. Decisive recommendations presented
directly per `minimal_decisive` calibration.

---

## A. Provider identity derivation

Recommendation accepted: `provider_reference := f(entry_id)`, `evidence_ref := g(entry_id,
event_kind)`, `correlation_id` flows to `trace_metadata` only. Holds the replay invariant because
`ReconciliationKeys.event_key/1` excludes `correlation_id`. (D-01..D-04)

**User's choice:** Recommended approach accepted (no objection raised).

---

## B. Restore identity semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed module constant | One `@subscription_entry_id` both purchase and restore anchor on; zero state; matches single-subscription scope (AF-04) | ✓ |
| Configurable via opts | `simulate_restore(intent, entry_id: ...)` defaulting to canonical; more flexible but threads an unused arg | |

**User's choice:** Fixed module constant.
**Notes:** Restore resolves to the one canonical subscription product so its evidence shares
`subject_key` with the prior purchase — honest "restore re-grants the previously-purchased sub."
(D-05..D-07)

---

## C. Determinism / clock seam

Recommendation accepted: optional `captured_at` keyword defaulting to
`DateTime.utc_now() |> DateTime.to_iso8601()`; refs stay pure-deterministic so no RNG/seed or
clock behaviour abstraction. Phase 36 proof injects a fixed timestamp. (D-08, D-09)

**User's choice:** Recommended approach accepted.

---

## D. Function / return shape + swap-doc

Recommendation accepted: return raw `%ReconciliationEvidence{}` (no `{:ok, _}`); `@moduledoc`
explicitly names `simulate_purchase/1` and `simulate_restore/1` as the StoreKit/Play Billing
swap targets (MOCK-03). (D-10, D-11)

**User's choice:** Recommended approach accepted; moduledoc wording left to Claude's discretion.

---

## Claude's Discretion

- Exact `provider_reference` / `evidence_ref` string prefixes and the concrete
  `@subscription_entry_id` value.
- Precise `@moduledoc` swap-target wording.
- String-concat vs private-helper for identity derivation.
- Exact structure of the replay invariant test and provider-vocabulary fence test.

## Deferred Ideas

- Reconciliation/LiveView wiring + `project_snapshot/2` → Phase 35.
- Merge-blocking full-lane proof + mock-boundary fence on
  `authority_mutation_allowed_from_evidence?/1` → Phase 36.
- `guides/commerce.md` walkthrough + docs-contract lock → Phase 37.
- Multi-product paywalls → out of scope (AF-04).
