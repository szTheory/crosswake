---
phase: 21
slug: reconciliation-example
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-27
---

# Phase 21 — Validation Strategy

> Reconstructed Nyquist validation contract from completed Plan and Summary artifacts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` |
| **Full suite command** | `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs test/crosswake/guides/commerce_test.exs` |
| **Estimated runtime** | ~1 second |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` for code tasks and `mix test test/crosswake/guides/commerce_test.exs` for docs tasks.
- **After every plan wave:** Run `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs test/crosswake/guides/commerce_test.exs`.
- **Before `/gsd-verify-work`:** Full phase suite must be green.
- **Max feedback latency:** 10 seconds.

---

## Requirement Coverage Audit

| Requirement | Status | Evidence Tests | Notes |
|-------------|--------|----------------|-------|
| RECN-01 | COVERED | `test/crosswake/proof/phase21_reconciliation_example_test.exs`, `test/crosswake/guides/commerce_test.exs` | Covers source ingestion for `device/storefront/webhook/support` and non-authoritative behavior contracts. |
| RECN-02 | COVERED | `test/crosswake/proof/phase21_reconciliation_example_test.exs`, `test/crosswake/guides/commerce_test.exs` | Covers provider-aware `event_key`/`subject_key` idempotency and excludes transient `correlation_id` from authority identity. |
| RECN-03 | COVERED | `test/crosswake/proof/phase21_reconciliation_example_test.exs`, `test/crosswake/guides/commerce_test.exs` | Covers monotonic `as_of` enforcement and deterministic `stale/pending/denied/granted` projection outcomes. |

No PARTIAL or MISSING requirement coverage was found.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | RECN-02 | P21-01-T01, P21-01-T03 | Dual provider-aware keys; correlation IDs stay trace-only metadata. | unit/proof | `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` | ✅ | ✅ green |
| 21-01-02 | 01 | 1 | RECN-01 | P21-01-T04 | Inbox ingestion is append-only and non-authoritative for all canonical evidence sources. | unit/proof | `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` | ✅ | ✅ green |
| 21-01-03 | 01 | 1 | RECN-03 | P21-01-T02 | Projection updates enforce verified outcomes and monotonic `as_of` ordering. | unit/proof | `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` | ✅ | ✅ green |
| 21-01-04 | 01 | 1 | RECN-01, RECN-02, RECN-03 | P21-01-T01..T05 | Dedicated proof lane covers sources, replay safety, key semantics, precedence, stale rejection, and provider-neutral fences. | proof | `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` | ✅ | ✅ green |
| 21-02-01 | 02 | 2 | RECN-01 | P21-02-T01, P21-02-T02 | Guide section documents minimal backend-owned reconciliation flow and non-authoritative ingestion semantics. | docs-contract | `mix test test/crosswake/guides/commerce_test.exs` | ✅ | ✅ green |
| 21-02-02 | 02 | 2 | RECN-02, RECN-03 | P21-02-T03, P21-02-T05 | Guide locks dual-key semantics, `correlation_id` exclusion, and projection precedence contract. | docs-contract | `mix test test/crosswake/guides/commerce_test.exs` | ✅ | ✅ green |
| 21-02-03 | 02 | 2 | RECN-01, RECN-02, RECN-03 | P21-02-T02, P21-02-T04 | Docs tests and example-host README preserve provider-neutral, non-authoritative, example/docs-only boundaries. | docs-contract | `mix test test/crosswake/guides/commerce_test.exs` | ✅ | ✅ green |

*Status: ✅ green · ⚠️ partial/manual-only · ❌ missing/failing*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or inherited phase proof coverage.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references (none).
- [x] No watch-mode flags.
- [x] Feedback latency < 10s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-27
