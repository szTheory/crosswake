---
phase: 21
slug: reconciliation-example
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-27
---

# Phase 21 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| External evidence edges -> Phoenix reconciliation inbox | Device/storefront/webhook/support signals enter backend-owned ingest and are normalized as non-authoritative evidence attempts. | Reconciliation evidence (`provider`, `provider_reference`, `event_kind`, `evidence_ref`, trace metadata) |
| Reconciliation outcomes -> authoritative entitlement snapshot | Verified outcomes cross from evidence processing into one backend authority projection with monotonic ordering. | `entitlement_snapshot` lanes (`authority`, `access`, `reconciliation`, `freshness`, `as_of`) |
| Guide and README contract -> adopter implementation behavior | Public docs and example-host wording influence production host logic and support expectations, so wording must remain boundary-safe and provider-neutral. | Documentation copy for idempotency, authority semantics, and scope boundaries |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| P21-01-T01 | spoofing | Evidence identity keys | mitigate | `event_key/subject_key` are provider-aware and keep `correlation_id` trace-only in `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex`; validated by `test/crosswake/proof/phase21_reconciliation_example_test.exs` ("correlation id variation..."). | closed |
| P21-01-T02 | tampering | Snapshot projection ordering | mitigate | Monotonic `as_of` guard rejects stale overwrites and emits `:stale_authority` in `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`; validated by proof test "project_snapshot blocks out-of-order as_of updates fail-closed". | closed |
| P21-01-T03 | repudiation | Replay handling | mitigate | Ingestion emits deterministic `replay?` metadata and replay-safe outcomes in `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`; validated by proof test "duplicate event keys are replay-safe and non-failing". | closed |
| P21-01-T04 | elevation_of_privilege | Evidence-to-authority path | mitigate | Ingest path explicitly non-authoritative and cannot set authority/access (`reconciliation_inbox.ex`), while authority updates require verified reconciliation outcomes in projection (`entitlement_projection.ex`); validated by proof tests for no authority/access fields on attempts. | closed |
| P21-01-T05 | information_disclosure | Provider-specific leakage into normalized contracts | mitigate | Example reconciliation modules are provider-neutral and covered by forbidden-token assertions in `test/crosswake/proof/phase21_reconciliation_example_test.exs` ("example reconciliation modules remain provider-neutral"). | closed |
| P21-02-T01 | spoofing | Guide authority/evidence semantics | mitigate | Commerce guide explicitly states ingestion is non-authoritative and backend projection owns authority in `guides/commerce.md`; locked by `test/crosswake/guides/commerce_test.exs` assertions for this wording. | closed |
| P21-02-T02 | tampering | Docs drift from executable example behavior | mitigate | Docs contract tests enforce exact reconciliation and precedence terminology in `test/crosswake/guides/commerce_test.exs`, preventing silent drift from implementation semantics in `guides/commerce.md`. | closed |
| P21-02-T03 | repudiation | Idempotency ambiguity | mitigate | Guide requires explicit dual-key semantics (`event_key`, `subject_key`) and correlation-id exclusion in `guides/commerce.md`; assertions are locked in `test/crosswake/guides/commerce_test.exs`. | closed |
| P21-02-T04 | information_disclosure | Provider-specific vocabulary leakage | mitigate | Reconciliation/lifecycle guide sections are guarded by negative checks (`storekit`, `play_billing`, `revenuecat`) in `test/crosswake/guides/commerce_test.exs`. | closed |
| P21-02-T05 | elevation_of_privilege | Docs implying evidence can grant access | mitigate | Guide precedence table and non-authoritative wording preserve backend-owned authority and non-granting pending states in `guides/commerce.md`; enforced by docs tests for reconciliation section semantics. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-27 | 10 | 10 | 0 | Codex (`/gsd-secure-phase 21`) |

---

## Security Audit 2026-05-27

| Metric | Count |
|--------|-------|
| Threats found | 10 |
| Closed | 10 |
| Open | 0 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-27
