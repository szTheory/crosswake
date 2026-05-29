---
phase: 21-reconciliation-example
phase_number: 21
status: passed
verified_at: 2026-05-27
requirements:
  - RECN-01
  - RECN-02
  - RECN-03
---

# Phase 21 Verification

## Goal Check

Phase 21 goal verified: Crosswake provides a minimal Phoenix-owned reconciliation inbox and entitlement projection example, with provider-aware idempotency and deterministic derived-state semantics.

## Coverage Score

- Requirements passed: 3/3 (100%)
- Key implementation artifacts verified: 3/3
- Key docs artifacts verified: 2/2
- Key test suites passed: 2/2
- Overall verification score: 100%

## Requirement Verdicts

### RECN-01 — Minimal Phoenix-owned reconciliation inbox example for purchase/restore/webhook/support evidence

**Verdict:** PASS

**Evidence**
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
  - `ingest_evidence/2` exists.
  - Canonical source handling exists for `:device`, `:storefront`, `:webhook`, and `:support`.
  - Ingestion status outcomes are non-authoritative (`:awaiting_verification`, `:verification_failed`).
  - Module documentation explicitly states ingestion does not mutate authority or grant access.
- `test/crosswake/proof/phase21_reconciliation_example_test.exs`
  - Source coverage test validates all four evidence sources.
  - Unknown event-kind path validates non-authoritative failure status.
- `guides/commerce.md`
  - `## Minimal Reconciliation Inbox Example` includes `purchase`, `restore`, `webhook`, and `support`.
  - Explicitly states ingestion outcomes are non-authoritative and projection remains backend-owned.

### RECN-02 — Provider-aware idempotency guidance over transient correlation IDs

**Verdict:** PASS

**Evidence**
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex`
  - `event_key/1` uses provider-aware fields (`provider`, `provider_reference`, `event_kind`, `evidence_ref`).
  - `subject_key/1,2` uses provider-aware identity with optional `group_id`.
  - `correlation_id` is trace metadata only and excluded from authority identity keys.
- `test/crosswake/proof/phase21_reconciliation_example_test.exs`
  - Replay/idempotency test validates duplicate `event_key` handling (`replay?` true, non-failing).
  - Correlation-id variation test proves identity keys are unchanged across different correlation IDs.
- `guides/commerce.md`
  - Locks dual-key contract wording (`event_key`, `subject_key`) and explicit `correlation_id` exclusion.

### RECN-03 — One authoritative entitlement snapshot projection with stale/pending/denied/granted clarity

**Verdict:** PASS

**Evidence**
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
  - `project_snapshot/2` enforces verified-reconciliation gating and monotonic `as_of` ordering.
  - Stale incoming snapshots are fail-closed as `{:error, {:stale_authority, ...}}`.
  - `derived_state/1` deterministically maps to `:stale`, `:pending`, `:denied`, `:granted`.
- `test/crosswake/proof/phase21_reconciliation_example_test.exs`
  - Derived-state precedence test covers stale/pending/denied/granted.
  - Out-of-order `as_of` rejection test validates stale-authority fail-closed behavior.
- `guides/commerce.md`
  - Includes deterministic precedence table and monotonic `as_of` guidance.

## Checks Run

1. `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs`
   - Result: PASS (`8 tests, 0 failures`)
2. `mix test test/crosswake/guides/commerce_test.exs`
   - Result: PASS (`9 tests, 0 failures`)
3. Content contract checks (`rg`) on:
   - Reconciliation key/idempotency semantics
   - Inbox source/status semantics
   - Projection precedence and monotonicity semantics
   - Provider-neutral vocabulary fences in example modules
   - Commerce guide and README requirement language
   - Result: PASS (required matches present; no forbidden provider tokens in Phase 21 example modules)

## Must-Have Truth Cross-Reference

- Backend-owned entitlement authority preserved; ingestion remains non-authoritative.
- Evidence from purchase/restore/webhook/support advances reconciliation state without direct entitlement grants.
- Idempotency uses provider-aware dual keys and excludes transient correlation IDs from authority identity.
- Example remains provider-neutral and scoped to example/docs-only guidance (no provider adapter implementation or core billing engine claims).

## Gaps / Human Verification

- No blocking gaps found for RECN-01/02/03.
- No additional human-only verification is required for Phase 21 requirement closure.
