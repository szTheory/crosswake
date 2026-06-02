---
phase: 59
slug: chimeway-contract-and-token-binding-semantics
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Quick run command** | `mix test test/crosswake/companions/chimeway` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds quick, ~120 seconds full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/companions/chimeway`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | TOKN-01 | T-59-01 | Bridge token evidence remains evidence-only and raw token material is not retained in public Chimeway evidence structs. | unit | `mix test test/crosswake/companions/chimeway` | ❌ W0 | ⬜ pending |
| 59-01-02 | 01 | 1 | TOKN-02 | T-59-02 | Binding state/reason vocabulary covers active, rotated, revoked, stale, invalid, permission-denied, environment-mismatched, and app-identity-mismatched cases. | unit | `mix test test/crosswake/companions/chimeway` | ❌ W0 | ⬜ pending |
| 59-02-01 | 02 | 1 | TOKN-01 | T-59-03 | Safe token fingerprint/ref helpers prevent raw token leakage through `inspect/1`, `to_map/1`, errors, fixtures, and telemetry. | unit | `mix test test/crosswake/companions/chimeway` | ❌ W0 | ⬜ pending |
| 59-02-02 | 02 | 1 | TOKN-02 | T-59-04 | APNs/FCM provider feedback normalizes to canonical Chimeway feedback without leaking provider-native enums into route policy or binding state. | unit | `mix test test/crosswake/companions/chimeway` | ❌ W0 | ⬜ pending |
| 59-03-01 | 03 | 1 | TOKN-01, TOKN-02 | T-59-05 | Phase boundary proof asserts no delivery, notification-open resolver, provider credential, or support-matrix delivery claim is introduced in Phase 59. | unit/docs contract | `mix test test/crosswake/companions/chimeway` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/companions/chimeway/contracts_test.exs` — stubs for TOKN-01/TOKN-02 contract validation.
- [ ] `test/crosswake/companions/chimeway/telemetry_test.exs` — stubs for telemetry allowlist/forbidden-key redaction.
- [ ] `test/crosswake/companions/chimeway/redaction_test.exs` — stubs for raw-token non-leakage fixtures.
- [ ] No framework install required; ExUnit is already present.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-02
