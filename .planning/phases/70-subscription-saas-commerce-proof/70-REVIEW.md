---
status: clean
phase: 70-subscription-saas-commerce-proof
files_reviewed: 5
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
---

# Phase 70 Advisory Code Review

No concrete bugs, security issues, CI footguns, test false positives, or Phase 70 scope creep were found in the reviewed files.

## Scope Reviewed

- `.github/workflows/phase70-proof.yml`
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend_verifier.ex`
- `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex`
- `test/crosswake/proof/phase35_paywall_live_test.exs`
- `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`

## Review Notes

- The Phase 70 workflow keeps the hermetic proof merge-blocking and provider/device checks advisory, with pinned actions and `permissions: contents: read`.
- The deterministic backend verifier remains proof-only, fixed-time, and authority-bearing only through emitted `%Crosswake.Commerce.Contracts.EntitlementSnapshot{}` values.
- The Paywall LiveView still routes subscribe/restore through storefront evidence, reconciliation ingestion, and backend projection instead of granting authority directly from client/storefront success.
- The Phase 70 proof covers StoreKit and Play Billing purchase/restore paths, replay identity, stale authority, pending projection rejection, denied lifecycle outcomes, invalid provider vocabulary, and hermeticity guards.
- The Paywall LiveView proof locks provider-neutral copy, accessible status regions, and absence of subscription-management/account-portal vocabulary across the four existing states.

## Residual Risks And Test Gaps

- The advisory provider sandbox/device job is still a placeholder by design. It verifies CI posture and credential gating, not real StoreKit or Play Billing sandbox behavior.
- `phase35_paywall_live_test.exs` calls LiveView callbacks directly rather than driving a browser or full Endpoint. That matches the existing proof style, but it does not validate client-side loading/disabled button behavior.
- The Paywall status block renders derived-state summaries, not full effective-period/reference data, because the current LiveView assigns do not carry the complete entitlement snapshot. This is consistent with the Phase 70 scope note to avoid inventing subscription-management behavior.

## Verification

- `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` - PASS, 13 tests, 0 failures.
- `mix test test/crosswake/proof/phase35_paywall_live_test.exs --include requires_example_host` - PASS, 12 tests, 0 failures.
- `mix compile --warnings-as-errors` - PASS.
