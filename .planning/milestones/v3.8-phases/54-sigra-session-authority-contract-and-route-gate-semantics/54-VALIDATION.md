---
phase: 54
slug: sigra-session-authority-contract-and-route-gate-semantics
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 54 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` |
| **Full suite command** | `mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/policy/schema_test.exs test/crosswake/compatibility/route_gate_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/policy/schema_test.exs test/crosswake/compatibility/route_gate_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds for targeted checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 54-01-01 | 01 | 1 | SESS-01 | T-54-01 | Backend authority structs validate lifecycle, assurance, expiry, remembered, cached, and revocation/version fields; evidence lanes cannot smuggle authority keys. | unit/proof | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ✅ W0 | ✅ green |
| 54-01-02 | 01 | 1 | DIAG-01 | T-54-02 | Auth denial code registry is stable, low-cardinality, and shell-safe detail allowlist excludes sensitive fields. | unit/proof | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ✅ W0 | ✅ green |
| 54-02-01 | 02 | 1 | SESS-03 | T-54-05 | Routes declare explicit auth posture; sensitive and recent-auth routes resolve to `:strict_recent`; `:cached_read_only_ok` blocked on mutation/admin/billing routes. | unit | `mix test test/crosswake/policy/schema_test.exs` | ✅ W0 | ✅ green |
| 54-03-01 | 03 | 2 | SESS-02 | T-54-09 | `evaluate_route_auth/3` denies missing/invalid context, non-active, expired, revoked, version-mismatched, weak-assurance, stale, remembered, and cached-invalid postures with canonical codes. | proof | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ✅ W0 | ✅ green |
| 54-03-02 | 03 | 2 | SESS-02 | T-54-11 | `RouteGate.evaluate/4` preserves kill-switch → companion gate → Sigra auth → compatibility/commerce precedence. | integration | `mix test test/crosswake/compatibility/route_gate_test.exs` | ✅ W0 | ✅ green |
| 54-04-01 | 04 | 3 | DIAG-01 | T-54-13 | Doctor, support matrix, operator inspection, and publish readiness expose full session-authority truth without leaking secrets or claiming Phase 55-57 machinery. | proof/docs | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ✅ W0 | ✅ green |
| 54-05-01 | 05 | 4 | SESS-01, SESS-02, SESS-03, DIAG-01 | T-54-17 | Public guides describe shipped session-authority evaluator and auth-posture semantics; merge-blocking proof locks denial taxonomy, route posture, support truth, and explicit non-claims for Phases 55-57. | proof/docs | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All Wave 0 requirements were satisfied during implementation:

- `test/crosswake/proof/phase54_sigra_session_authority_test.exs` — merge-blocking proof for SESS-01, SESS-02, SESS-03, and DIAG-01. ✅
- `test/crosswake/compatibility/route_gate_test.exs` — explicit remembered/cached posture denial coverage. ✅
- `test/crosswake/companions/sigra/contracts_test.exs` — extended for rich authority struct/validator coverage. ✅

---

## Manual-Only Verifications

All Phase 54 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 7 tasks (SESS-01, SESS-02, SESS-03, DIAG-01; T-54-01 … T-54-20) verify through the merge-blocking proof `test/crosswake/proof/phase54_sigra_session_authority_test.exs` plus supporting focused suites. Audit re-ran the proof (`7 tests, 0 failures`), the full phase focused suite (`mix test test/crosswake/companions/sigra/contracts_test.exs test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/policy/schema_test.exs test/crosswake/compatibility/route_gate_test.exs` → `43 tests, 0 failures`), and the layered Phase 54-58 proof lane (`40 tests, 0 failures`). Per-Task Map statuses advanced ⬜ pending → ✅ green. Wave 0 checkbox updated to ✅. Frontmatter advanced from `status: draft` / `nyquist_compliant: false` / `wave_0_complete: false` to `status: validated` / `nyquist_compliant: true` / `wave_0_complete: true`. Sign-Off checkboxes fully checked. No MISSING or PARTIAL requirements remain; no new tests required. Phase 54 is Nyquist-compliant.
