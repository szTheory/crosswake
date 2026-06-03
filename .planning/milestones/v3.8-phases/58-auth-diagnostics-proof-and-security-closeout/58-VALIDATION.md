---
phase: 58
slug: auth-diagnostics-proof-and-security-closeout
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 58 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/companions/sigra/telemetry_test.exs test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` |
| **Full suite command** | `mix compile --warnings-as-errors && mix closeout.verify --security-only --security-closeout .planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md && mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/proof/phase55_session_handoff_tickets_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs test/crosswake/proof/phase57_auth_return_boundaries_test.exs test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs test/crosswake/companions/sigra/telemetry_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/guides/companions_test.exs test/mix/tasks/closeout_verify_test.exs` |
| **Estimated runtime** | ~60-180 seconds locally, CI-dependent |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the touched surface when possible.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 3 minutes for quick checks; full lane before wave/phase closeout.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 1 | DIAG-02 | T-58-telemetry | Auth telemetry registry exposes stable event names, low-cardinality metadata, forbidden secret keys, and diagnostic-evidence-only posture. | unit/proof | `mix test test/crosswake/companions/sigra/telemetry_test.exs test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | ✅ W0 | ✅ green |
| 58-01-02 | 01 | 1 | DIAG-03 | T-58-truth | Support matrix, doctor, publish readiness, operator inspection, and guides distinguish shipped full Sigra contract truth from host readiness and advisory provider/device proof. | proof/docs | `mix test test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/guides/companions_test.exs` | ✅ W0 | ✅ green |
| 58-01-03 | 01 | 1 | PROOF-01 | T-58-closeout | Security closeout blocks unresolved high/critical findings, preserves provider/device non-claims, and reviews auth surfaces with evidence-backed STRIDE rows. | proof/cli | `mix closeout.verify --security-only --security-closeout .planning/phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md && mix test test/mix/tasks/closeout_verify_test.exs test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | ✅ W0 | ✅ green |
| 58-01-04 | 01 | 1 | PROOF-01 | T-58-ci | Phase 58 workflow keeps hermetic proof merge-blocking and advisory provider/device proof non-promoting. | source/proof | `mix test test/crosswake/planning/closeout_ci_parity_test.exs` | ✅ W0 | ✅ green |
| 58-01-05 | 02 | 2 | DIAG-02, DIAG-03, PROOF-01 | T-58-regression | Phase 54-58 layered proof remains green after closeout hardening. | integration/proof | `mix test test/crosswake/proof/phase54_sigra_session_authority_test.exs test/crosswake/proof/phase55_session_handoff_tickets_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs test/crosswake/proof/phase57_auth_return_boundaries_test.exs test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- [x] ExUnit infrastructure exists.
- [x] Phase 54-58 proof tests exist or are Phase 58 planned targets.
- [x] `mix closeout.verify` exists.
- [x] Phase 58 security artifact exists.
- [x] Phase 58 workflow exists.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Provider/device OAuth/passkey/native auth proof remains advisory | PROOF-01 | Device/provider proof is intentionally not a merge-blocking support claim in Phase 58. | Confirm `.github/workflows/phase58-proof.yml` keeps advisory provider/device lane scheduled/manual and `continue-on-error: true`; confirm guides/support matrix do not promote provider/device proof. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target defined.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-02; audit confirmed 2026-06-03

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 5 tasks (DIAG-02, DIAG-03, PROOF-01; T-58-telemetry, T-58-truth, T-58-closeout, T-58-ci, T-58-regression) verify through the merge-blocking proof `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` and supporting suites. Audit re-ran the proof (`4 tests, 0 failures`) and the layered Phase 54-58 proof lane (`40 tests, 0 failures`). Per-Task Map statuses advanced from `pending` → `✅ green`, `File Exists` updated from `yes` → `✅ W0`, `TBD` plan IDs resolved to `01`/`02`. Frontmatter advanced from `status: draft` to `status: validated`. Provider/device OAuth, passkey SDK, native auth UI, and refresh-token orchestration remain correctly deferred as advisory-only per Manual-Only Verifications and `58-SECURITY.md`. No MISSING or PARTIAL requirements remain. Phase 58 is Nyquist-compliant.
