---
phase: 63
slug: hermetic-proof-and-advisory-promotion-criteria
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 63 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs` |
| **Full suite command** | `mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs test/crosswake/proof/phase63_advisory_proof_test.exs test/crosswake/planning/closeout_verifier_test.exs --include advisory_only` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs test/crosswake/proof/phase63_advisory_proof_test.exs test/crosswake/planning/closeout_verifier_test.exs --include advisory_only`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 63-01-01 | 01 | 1 | PROOF-01 | — | Hermetic seam proof runs without live network connectivity; token binding, route resolution, and telemetry redaction are all proven; raw synthetic token does not appear in `Inspect` output or telemetry events. | proof | `mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs` | ✅ W0 | ✅ green |
| 63-02-01 | 02 | 1 | PROOF-02 | — | Advisory proof (tagged `:advisory_only`) asserts that SupportMatrix delivery capabilities carry `proof_class: :advisory` and `delivery_supported: false`; advisory tests do not block standard CI merge. | proof | `mix test test/crosswake/proof/phase63_advisory_proof_test.exs --include advisory_only` | ✅ W0 | ✅ green |
| 63-03-01 | 03 | 2 | PROOF-01, PROOF-02 | — | `CloseoutVerifier` enforces v3.9 milestone requirement mappings and phase verifications; all closeout checks pass with 741 total tests green. | proof | `mix test test/crosswake/planning/closeout_verifier_test.exs` | ✅ W0 | ✅ green |
| 63-03-02 | 03 | 2 | PROOF-01, PROOF-02 | — | ROADMAP.md milestone v3.9 is marked SHIPPED (2026-06-03); Phase 63 is marked complete in roadmap state. | docs contract | `mix test test/crosswake/planning/closeout_verifier_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The phase created `test/crosswake/proof/phase63_notification_seam_proof_test.exs` (PROOF-01) and `test/crosswake/proof/phase63_advisory_proof_test.exs` (PROOF-02) as the two merge-blocking proof lanes. The advisory proof carries `@moduletag :advisory_only` and is excluded from the default CI run; it must be run with `--include advisory_only` to observe its 2 tests. CloseoutVerifier tests confirm the v3.9 milestone closeout contract.

---

## Manual-Only Verifications

All Phase 63 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 4 tasks (PROOF-01/02) verify through the two phase-63 proof tests and the closeout verifier. Audit re-ran the seam proof (`mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs` → `1 test, 0 failures`), the advisory proof (`mix test test/crosswake/proof/phase63_advisory_proof_test.exs --include advisory_only` → `2 tests, 0 failures`), and the full phase suite including the closeout verifier (`mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs test/crosswake/proof/phase63_advisory_proof_test.exs test/crosswake/planning/closeout_verifier_test.exs --include advisory_only` → `12 tests, 0 failures`). Note: advisory proof tests are tagged `:advisory_only` and excluded from the default suite; they must be run with `--include advisory_only` for full coverage. Per-Task Map statuses set to ✅ green. No MISSING or PARTIAL requirements. Phase 63 is Nyquist-compliant.
