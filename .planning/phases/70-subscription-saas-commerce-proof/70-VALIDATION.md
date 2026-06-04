---
phase: 70
slug: subscription-saas-commerce-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 70 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` |
| **Full suite command** | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs test/crosswake/proof/phase34_paywall_corridor_proof_test.exs test/crosswake/proof/phase34_mock_storefront_test.exs test/crosswake/proof/phase48_provider_adapter_proof_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs test/crosswake/proof/phase34_paywall_corridor_proof_test.exs test/crosswake/proof/phase34_mock_storefront_test.exs test/crosswake/proof/phase48_provider_adapter_proof_test.exs`
- **Before `$gsd-verify-work`:** targeted Phase 70 proof, Phase 34/48 commerce regressions, and `mix compile --warnings-as-errors` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 70-01-01 | 01 | 0 | SAAS-01, SAAS-02 | T-70-01 | Provider/storefront evidence remains non-authoritative until backend projection verifies it. | proof | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` | ❌ W0 | ⬜ pending |
| 70-01-02 | 01 | 0 | SAAS-01 | T-70-02 | StoreKit and Play Billing purchase/restore facade evidence enters the provider-neutral inbox without provider vocabulary leakage into core entitlement states. | proof | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` | ❌ W0 | ⬜ pending |
| 70-01-03 | 01 | 0 | SAAS-02 | T-70-03 | Pending purchase/restore, duplicate replay, stale authority, revoked/refunded/expired outcomes, and direct override attempts fail closed. | proof | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` | ❌ W0 | ⬜ pending |
| 70-02-01 | 02 | 1 | SAAS-01, SAAS-02 | T-70-05 | Deterministic proof-only backend verifier emits authority-bearing snapshots only after verification and supports grant/deny/stale lifecycle outcomes. | proof | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` | ❌ W0 | ⬜ pending |
| 70-02-02 | 02 | 1 | SAAS-01, SAAS-02 | T-70-06 | StoreKit and Play Billing purchase/restore rows pass through facade, inbox, backend verifier, and projection before grant. | proof | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` | ❌ W0 | ⬜ pending |
| 70-02-03 | 02 | 1 | SAAS-02 | T-70-07 | Authority-fence negative matrix passes for direct override, replay, stale authority, pending states, denied lifecycle states, and invalid provider vocabulary. | proof | `mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs test/crosswake/proof/phase34_paywall_corridor_proof_test.exs test/crosswake/proof/phase34_mock_storefront_test.exs test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | ❌ W0 | ⬜ pending |
| 70-03-01 | 03 | 2 | SAAS-01 | T-70-08 | CI exposes a deterministic merge-blocking Phase 70 proof lane and keeps provider/device checks advisory. | workflow | `grep -q "mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs" .github/workflows/phase70-proof.yml && grep -q "continue-on-error: true" .github/workflows/phase70-proof.yml` | ❌ W0 | ⬜ pending |
| 70-03-02 | 03 | 2 | SAAS-01, SAAS-02 | T-70-09 | Paywall UI renders backend entitlement state honestly and accessibly without adding unscoped subscription-management behavior. | proof | `mix test test/crosswake/proof/phase35_paywall_live_test.exs --include requires_example_host` | ✅ | ⬜ pending |
| 70-03-03 | 03 | 2 | SAAS-01, SAAS-02 | T-70-10 | UI proof locks provider-neutral copy, accessible status region, and no subscription portal/provider vocabulary leakage. | proof | `mix test test/crosswake/proof/phase35_paywall_live_test.exs --include requires_example_host && mix test test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs test/crosswake/proof/phase34_paywall_corridor_proof_test.exs test/crosswake/proof/phase34_mock_storefront_test.exs test/crosswake/proof/phase48_provider_adapter_proof_test.exs && mix compile --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase70_subscription_saas_commerce_proof_test.exs` — RED proof scaffold for SAAS-01, SAAS-02, and all Phase 70 success criteria.
- [ ] Deterministic proof helpers or a pure example-host verifier extension if the current `MockBackend` cannot express denied/stale/refund/revoke/expired outcomes without wall-clock dependence.
- [ ] `.github/workflows/phase70-proof.yml` — targeted merge-blocking Phase 70 proof lane plus advisory provider/device lane.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
