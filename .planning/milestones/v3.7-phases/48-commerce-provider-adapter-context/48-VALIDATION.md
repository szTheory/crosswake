---
phase: 48
slug: commerce-provider-adapter-context
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/commerce test/crosswake/companions test/crosswake/doctor/publish_readiness_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45-90 seconds locally; Android/JVM advisory evidence remains CI-dependent |

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/commerce test/crosswake/companions test/crosswake/doctor/publish_readiness_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/proof/phase48_provider_adapter_proof_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green with `mix test`
- **Max feedback latency:** 90 seconds for local hermetic sampling

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | ADPT-01 | T-48-01 | StoreKit evidence maps to reconciliation without authority mutation | unit | `mix test test/crosswake/commerce test/crosswake/companions/store_kit_test.exs` | exists | pending |
| 48-01-02 | 01 | 1 | ADPT-01 | T-48-02 | StoreKit raw enums stay metadata-only | unit | `mix test test/crosswake/companions/store_kit_test.exs` | exists | pending |
| 48-02-01 | 02 | 1 | ADPT-02 | T-48-03 | Play purchase tokens become provider lineage, not order-id authority | unit | `mix test test/crosswake/companions/play_billing_test.exs` | exists | pending |
| 48-02-02 | 02 | 1 | ADPT-02 | T-48-04 | Pending Play evidence cannot grant access | unit | `mix test test/crosswake/commerce test/crosswake/companions/play_billing_test.exs` | exists | pending |
| 48-03-01 | 03 | 2 | ADPT-01, ADPT-02 | T-48-05 | One-shot intent/result contracts do not expose provider streams | unit | `mix test test/crosswake/commerce test/crosswake/companions` | exists | pending |
| 48-03-02 | 03 | 2 | ADPT-01, ADPT-02 | T-48-06 | Example-host swap target preserves backend projection | integration | `mix test test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | exists | pending |
| 48-04-01 | 04 | 2 | ADPT-03 | T-48-07 | Support and promotion rows remain criteria-as-code and demotable | unit | `mix test test/crosswake/proof/phase52_operator_truth_test.exs test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | exists | pending |
| 48-04-02 | 04 | 2 | ADPT-03 | T-48-08 | Doctor/readiness distinguishes shipped seams from advisory proof | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | exists | pending |
| 48-05-01 | 05 | 3 | ADPT-03 | T-48-09 | Public docs/changelog do not imply provider certification | docs-contract | `mix test test/crosswake/guides test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | exists | pending |
| 48-06-01 | 06 | 3 | ADPT-01, ADPT-02, ADPT-03 | T-48-10 | Hermetic proof blocks authority leakage; advisory workflow stays non-blocking | proof | `mix test test/crosswake/proof/phase48_provider_adapter_proof_test.exs` | exists | pending |

*Status: pending / green / red / flaky*

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| StoreKit sandbox purchase/restore | ADPT-01, ADPT-03 | Requires Apple account, App Store Connect product setup, and simulator/device context | Run the advisory StoreKit workflow after host credentials and products are configured; archive result as advisory evidence only. |
| Play Billing license-test purchase/restore | ADPT-02, ADPT-03 | Requires Play Console setup, license tester, signed build, and Android environment | Run the advisory Play Billing workflow after provider setup; archive result as advisory evidence only. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for local hermetic sampling
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-01
