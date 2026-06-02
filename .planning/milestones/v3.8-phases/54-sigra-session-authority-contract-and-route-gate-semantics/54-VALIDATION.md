---
phase: 54
slug: sigra-session-authority-contract-and-route-gate-semantics
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds for targeted checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 0 | SESS-01 | T-54-01 | Backend authority structs validate lifecycle, assurance, expiry, remembered, and revocation/version fields. | unit | `mix test test/crosswake/companions/sigra/contracts_test.exs` | ✅ | ⬜ pending |
| 54-01-02 | 01 | 0 | DIAG-01 | T-54-02 | Auth denial code registry is stable, low-cardinality, and excludes sensitive fields. | unit/proof | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ❌ W0 | ⬜ pending |
| 54-02-01 | 02 | 1 | SESS-02 | T-54-03 | RouteGate denies missing, invalid, inactive, expired, revoked/version-mismatched, weak, and stale authority fail-closed. | integration | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ❌ W0 | ⬜ pending |
| 54-02-02 | 02 | 1 | SESS-03 | T-54-04 | Remembered and cached auth cannot satisfy sensitive/recent-auth routes unless route posture explicitly allows weaker behavior. | integration | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ❌ W0 | ⬜ pending |
| 54-03-01 | 03 | 2 | DIAG-01 | T-54-05 | Doctor, support matrix, operator inspection, guide, and docs-contract truth expose full Sigra session authority without leaking secrets or claiming Phase 55-57 machinery. | proof/docs | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/guides/companions_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase54_sigra_session_authority_test.exs` — merge-blocking proof for SESS-01, SESS-02, SESS-03, and DIAG-01.
- [ ] `test/crosswake/compatibility/route_gate_test.exs` or the Phase 54 proof file — explicit remembered/cached posture denial coverage.
- [ ] Existing `test/crosswake/companions/sigra/contracts_test.exs` — extend rather than replace for rich authority struct/validator coverage.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
