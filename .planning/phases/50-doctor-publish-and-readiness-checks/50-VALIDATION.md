---
phase: 50
slug: doctor-publish-and-readiness-checks
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 50 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/doctor/publish_readiness_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90-150 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted ExUnit command from the plan.
- **After Wave 1:** Run `mix test test/crosswake/doctor/publish_readiness_test.exs`.
- **After Wave 2:** Run `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/mix/tasks/crosswake_doctor_test.exs`.
- **Before `$gsd-verify-work`:** Full suite must be green or every gap must be documented with explicit `deferred_with_reason`.
- **Max feedback latency:** 150 seconds for targeted Phase 50 checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 50-01-01 | 01 | 1 | DIAG-01, DIAG-02 | T-50-01, T-50-02 | Publish-readiness contract has stable fields, all required categories, and explicit blocking/result semantics. | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs -x` | W0 | pending |
| 50-01-02 | 01 | 1 | DIAG-01, DIAG-02 | T-50-01, T-50-03 | Readiness derivation uses deterministic local truth plus OperatorInspection and SupportMatrix without duplicating route inventory. | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs` | W0 | pending |
| 50-02-01 | 02 | 2 | DIAG-01, DIAG-02 | T-50-04, T-50-05 | Doctor report/formatters expose publish readiness only under `--check-publish` and preserve default doctor behavior. | integration | `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs -x` | W0 | pending |
| 50-02-02 | 02 | 2 | DIAG-01, DIAG-02 | T-50-04, T-50-06 | Mix task accepts `--check-publish`, emits human/JSON readiness output, and fails only on blocking readiness issues. | task | `mix test test/mix/tasks/crosswake_doctor_test.exs -x` | W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/doctor/publish_readiness_test.exs` - reusable readiness contract, required category coverage, deferred-claim guardrails.
- [ ] `test/crosswake/doctor/doctor_test.exs` - report integration and optional `publish_readiness` data.
- [ ] `test/crosswake/doctor/formatter_test.exs` - concise human Publish readiness section.
- [ ] `test/mix/tasks/crosswake_doctor_test.exs` - CLI flag, JSON gating, default-path regression, exit behavior.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DIAG-01, DIAG-02 | Phase 50 behaviors can be covered by ExUnit and Mix task tests. | N/A |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 150s for targeted checks
- [ ] `nyquist_compliant: true` set in frontmatter after validation passes

**Approval:** pending
