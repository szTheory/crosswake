---
phase: 51
slug: support-matrix-and-native-rebuild-truth
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-01
---

# Phase 51 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-90 seconds for focused tests; full suite runtime depends on local environment |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs`
- **After every plan wave:** Run focused support/inspection/doctor/guide tests listed below.
- **Before `$gsd-verify-work`:** `mix test` full suite must be green.
- **Max feedback latency:** One focused ExUnit run per task.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | SUPP-01 | T-51-01 | Support/proof/severity/rebuild/action axes stay separate and machine-visible. | unit/contract | `mix test test/crosswake/support_matrix/support_matrix_test.exs` | ✅ | ⬜ pending |
| 51-01-02 | 01 | 1 | SUPP-01 | T-51-02 | Operator/doctor consumers derive from canonical support truth without inventing support states. | integration/contract | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/doctor/publish_readiness_test.exs` | ✅ | ⬜ pending |
| 51-02-01 | 02 | 2 | SUPP-02 | T-51-03 | Public support guidance exposes rebuild requirements, promotion criteria, and deferred non-claims. | docs-contract | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/guides/companions_test.exs test/crosswake/guides/capabilities_test.exs` | ✅ | ⬜ pending |

*Status: pending until plans assign exact task IDs.*

---

## Wave 0 Requirements

- [ ] Add or update support-matrix tests for `action_class` vocabulary and promotion-rule shape.
- [ ] Add or update renderer/docs tests for rebuild/action columns and explicit non-claims.
- [ ] Add or update inspection/doctor tests only where Phase 51 adds new machine fields.

---

## Manual-Only Verifications

All Phase 51 behaviors should have automated verification. Human review is still useful for guide wording, but it cannot replace generated/parity tests.

---

## Validation Sign-Off

- [x] All tasks require automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all new test-file references.
- [x] No watch-mode flags.
- [x] Feedback latency bounded by focused ExUnit runs.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution
