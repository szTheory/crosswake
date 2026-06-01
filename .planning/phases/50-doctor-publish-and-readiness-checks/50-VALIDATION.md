---
phase: 50
slug: doctor-publish-and-readiness-checks
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
validated: 2026-06-01
---

# Phase 50 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/doctor/publish_readiness_test.exs` |
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
| 50-01-01 | 01 | 1 | DIAG-01, DIAG-02 | T-50-01, T-50-02 | Publish-readiness contract has stable fields, all required categories, and explicit blocking/result semantics. | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs` | yes | green |
| 50-01-02 | 01 | 1 | DIAG-01, DIAG-02 | T-50-01, T-50-03 | Readiness derivation uses deterministic local truth plus OperatorInspection and SupportMatrix without duplicating route inventory. | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs` | yes | green |
| 50-02-01 | 02 | 2 | DIAG-01, DIAG-02 | T-50-04, T-50-05 | Doctor report/formatters expose publish readiness only under `--check-publish` and preserve default doctor behavior. | integration | `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs` | yes | green |
| 50-02-02 | 02 | 2 | DIAG-01, DIAG-02 | T-50-04, T-50-06 | Mix task accepts `--check-publish`, emits human/JSON readiness output, and fails only on blocking readiness issues. | task | `mix test test/mix/tasks/crosswake_doctor_test.exs` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `test/crosswake/doctor/publish_readiness_test.exs` - reusable readiness contract, required category coverage, deferred-claim guardrails.
- [x] `test/crosswake/doctor/doctor_test.exs` - report integration and optional `publish_readiness` data.
- [x] `test/crosswake/doctor/formatter_test.exs` - concise human Publish readiness section.
- [x] `test/mix/tasks/crosswake_doctor_test.exs` - CLI flag, JSON gating, default-path regression, exit behavior.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DIAG-01, DIAG-02 | Phase 50 behaviors can be covered by ExUnit and Mix task tests. | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 150s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter after validation passes

**Approval:** automated validation pass 2026-06-01

## Validation Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 4 stale ledger statuses |
| Escalated | 0 |

Phase 50 already had automated coverage for DIAG-01 and DIAG-02. The retroactive validation pass updated stale `pending` ledger rows to `green`, marked Wave 0 complete, and removed unsupported `-x` flags from recorded Mix commands.

Verification evidence:

```bash
mix test test/crosswake/doctor/publish_readiness_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/mix/tasks/crosswake_doctor_test.exs
```

Result: 39 tests, 0 failures.

## Validation Re-Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

State A audit confirmed the Phase 50 validation ledger still covers every completed task and both requirements (`DIAG-01`, `DIAG-02`) through automated ExUnit and Mix task tests. No additional test files were needed.

Verification evidence:

```bash
mix test test/crosswake/doctor/publish_readiness_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/mix/tasks/crosswake_doctor_test.exs
```

Result: 39 tests, 0 failures.
