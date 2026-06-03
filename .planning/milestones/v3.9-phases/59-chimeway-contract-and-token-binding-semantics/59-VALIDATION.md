---
phase: 59
slug: chimeway-contract-and-token-binding-semantics
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs` |
| **Full suite command** | `mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | TOKN-01 | T-59-01 | Bridge token evidence remains evidence-only and raw token material is not retained in public Chimeway evidence structs. | proof | `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs` | ✅ W0 | ✅ green |
| 59-01-02 | 01 | 1 | TOKN-02 | T-59-02 | Binding state/reason vocabulary covers active, rotated, revoked, stale, invalid, permission-denied, environment-mismatched, and app-identity-mismatched cases. | proof | `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs` | ✅ W0 | ✅ green |
| 59-02-01 | 02 | 1 | TOKN-01 | T-59-03 | Safe token fingerprint/ref helpers prevent raw token leakage through `inspect/1`, `to_map/1`, errors, fixtures, and telemetry. | proof | `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs` | ✅ W0 | ✅ green |
| 59-02-02 | 02 | 1 | TOKN-02 | T-59-04 | APNs/FCM provider feedback normalizes to canonical Chimeway feedback without leaking provider-native enums into route policy or binding state. | proof | `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs` | ✅ W0 | ✅ green |
| 59-03-01 | 03 | 1 | TOKN-01, TOKN-02 | T-59-05 | Phase boundary proof asserts no delivery, notification-open resolver, provider credential, or support-matrix delivery claim is introduced in Phase 59. | proof | `mix test test/crosswake/proof/phase59_chimeway_contract_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The phase created `test/crosswake/proof/phase59_chimeway_contract_test.exs` during implementation and uses it as the merge-blocking TOKN-01/TOKN-02 proof lane. Supporting unit tests in `test/crosswake/companions/chimeway/` (contracts_test, redaction_test, telemetry_test) were created as part of wave execution and are green.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-02

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 5 tasks (TOKN-01/TOKN-02, T-59-01 … T-59-05) verify through the single merge-blocking proof `test/crosswake/proof/phase59_chimeway_contract_test.exs`. Audit re-ran the proof (`5 tests, 0 failures`) and the full phase suite (`mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs` → `36 tests, 0 failures`). Per-Task Map statuses advanced ⬜ pending → ✅ green. Wave 0 flag corrected to true — all test files shipped in plans 59-01 through 59-03. No MISSING or PARTIAL requirements; no auditor agent or new tests required. Phase 59 is Nyquist-compliant.
