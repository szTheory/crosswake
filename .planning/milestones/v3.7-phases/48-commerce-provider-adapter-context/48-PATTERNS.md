# Phase 48: Commerce Provider Adapter Context - Pattern Map

**Mapped:** 2026-06-01
**Status:** Complete

## Target Surfaces

| Target | Role | Closest Existing Analog | Pattern To Reuse |
|--------|------|-------------------------|------------------|
| `lib/crosswake/companions/store_kit.ex` | StoreKit companion seam | `lib/crosswake/companions/rindle.ex` | Thin `@behaviour Crosswake.Companion`, fail-closed optional dependency check, typed `report_state/0`. |
| `lib/crosswake/companions/store_kit/evidence.ex` | StoreKit evidence normalizer | `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` | Build `ReconciliationEvidence`; keep provider payload out of core. |
| `lib/crosswake/companions/store_kit/result.ex` | StoreKit purchase/restore result taxonomy | `lib/crosswake/commerce/contracts.ex` | Closed structs and vocabularies; no raw provider enum public surface. |
| `lib/crosswake/companions/play_billing.ex` | Play Billing companion seam | `lib/crosswake/companions/rindle.ex` | Optional dependency diagnostics and state snapshot. |
| `lib/crosswake/companions/play_billing/evidence.ex` | Play Billing evidence normalizer | `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` | Separate event key inputs from subject key lineage. |
| `lib/crosswake/commerce/provider_evidence.ex` | Shared provider vocabulary | `lib/crosswake/commerce/reconciliation.ex` | Closed event-kind vocabulary and fail-closed unknown handling. |
| `lib/crosswake/support_matrix/support_matrix.ex` | Support/promotion truth | Phase 51 support rows and existing promotion rules | Keep support status, proof class, action class, rebuild class, and promotion rule separate. |
| `lib/crosswake/doctor/publish_readiness.ex` | Publish readiness | Existing `provider_adapter_readiness_check/2` | Replace "not shipped" blanket with shipped seam + advisory proof details. |
| `lib/crosswake/operator_inspection.ex` | Route readiness | Existing commerce support/promotion derivation | Continue deriving from route role and support matrix. |
| `guides/commerce.md` / `guides/support_matrix.md` | Public docs | Phase 23/51 docs-contract pattern | Generated canonical truth plus authored advisory provider playbooks. |
| `test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | Merge-blocking proof | `test/crosswake/proof/phase52_operator_truth_test.exs` | Stable IDs, normalized fixtures, docs/source parity assertions. |
| `.github/workflows/phase48-proof.yml` | Proof lane | `.github/workflows/phase52-proof.yml` | Hermetic merge-blocking job plus advisory provider visibility job. |

## Code Excerpts To Preserve

`Crosswake.Commerce.Reconciliation.ingest_evidence/2`:

- Rejects `authority_state` in opts with `:authority_lane_mutation_forbidden`.
- Maps success-like evidence to `:awaiting_verification` unless `verified_projection: true`.
- Never returns an authority-lane state from evidence alone.

`CrosswakeExample.Commerce.ReconciliationKeys`:

- `event_key = event::provider::provider_reference::event_kind::evidence_ref`
- `subject_key = subject::provider::provider_reference`
- `correlation_id` is trace metadata only.

`Crosswake.SupportMatrix.promotion_rules/0`:

- Four provider claim IDs already exist:
  - `purchase_intent.provider.storekit`
  - `restore_intent.provider.storekit`
  - `purchase_intent.provider.play_billing`
  - `restore_intent.provider.play_billing`
- Each promotion rule must keep required evidence, docs anchors, check IDs, action class, failure budget, freshness window, and demotion trigger.

## Implementation Notes

- Prefer adding provider-specific modules under `lib/crosswake/companions/` over widening `Crosswake.Commerce.Contracts` into a provider SDK abstraction.
- If shared helper functions are needed, keep them in `Crosswake.Commerce.ProviderEvidence` and expose only closed vocabularies plus normalization helpers.
- Keep provider identifiers stable and lowercase: `"storekit"` and `"play_billing"`.
- Do not rename existing support statuses or proof classes; existing tests assert them.
- Docs should update non-claims from "not shipped in v3.6" to "v3.7 seams shipped; environment-sensitive provider proof remains advisory unless promoted."

## Pattern Map Complete
