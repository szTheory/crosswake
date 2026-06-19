---
phase: 119
slug: native-evidence-classification
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-19
updated: 2026-06-19
---

# Phase 119 - Validation Strategy

> Retroactive Nyquist validation audit for Phase 119: native evidence classification.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + ExDoc |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/guides/native_evidence_drift_test.exs` |
| **Full suite command** | `mix test test/mix/tasks/crosswake_gen_shell_test.exs test/crosswake/doctor/publish_readiness_test.exs && mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs && mix test test/crosswake/guides/native_evidence_drift_test.exs && mix docs` |
| **Estimated runtime** | ~3 seconds for targeted ExUnit commands; `mix docs` runtime depends on ExDoc warning volume |

---

## Sampling Rate

- **After every task commit:** Run the task's listed targeted `mix test` command.
- **After every plan wave:** Run all affected Phase 119 ExUnit commands.
- **Before `/gsd:verify-work`:** Run all targeted ExUnit commands plus `mix docs`.
- **Max feedback latency:** < 30 seconds for targeted ExUnit checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | NATIVE-01 | T-119-01 / T-119-02 | Checked-in iOS and Android hosts resolve published coordinates by default while preserving explicit `--local` maintainer paths. | integration/docs | `mix test test/mix/tasks/crosswake_gen_shell_test.exs test/crosswake/doctor/publish_readiness_test.exs` | yes | green |
| 119-01-02 | 01 | 1 | NATIVE-01 | T-119-03 | Checked-in host READMEs label public-coordinate proof without implying simulator, emulator, or physical-device support. | integration/docs | `mix test test/mix/tasks/crosswake_gen_shell_test.exs test/crosswake/doctor/publish_readiness_test.exs` | yes | green |
| 119-02-01 | 02 | 1 | NATIVE-02 | T-119-04 / T-119-05 | Public native docs reuse evidence labels beside commands, paths, and captions without overclaiming device support. | docs/render | `mix docs` | yes | green with pre-existing warnings |
| 119-02-02 | 02 | 1 | NATIVE-02 | T-119-06 | Canonical support-matrix source and renderer preserve checked-in public-coordinate proof and related label vocabulary. | unit/render | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` | yes | green |
| 119-03-01 | 03 | 2 | DRIFT-03 | T-119-07 / T-119-08 / T-119-09 | Native evidence drift guard fails closed on stale coordinates, missing labels, stale Android truth, and native support overclaims. | unit/docs-scanner | `mix test test/crosswake/guides/native_evidence_drift_test.exs` | yes | green |
| 119-03-02 | 03 | 2 | DRIFT-03 | T-119-07 / T-119-08 / T-119-09 | Synthetic regressions prove the scanner catches silent iOS local refs, stale/dynamic Android coordinates, missing labels, stale Android UAT wording, and support overclaims. | unit/synthetic | `mix test test/crosswake/guides/native_evidence_drift_test.exs` | yes | green |

*Status: green = command passed during validation audit.*

---

## Requirement Coverage

| Requirement | Coverage | Evidence |
|-------------|----------|----------|
| NATIVE-01 | COVERED | `test/mix/tasks/crosswake_gen_shell_test.exs`, `test/crosswake/doctor/publish_readiness_test.exs`, and `test/crosswake/guides/native_evidence_drift_test.exs` cover published host coordinates and no silent checked-in local defaults. |
| NATIVE-02 | COVERED | `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/support_matrix/support_matrix_test.exs`, `test/crosswake/guides/native_evidence_drift_test.exs`, and `mix docs` cover canonical label rendering and public docs buildability. |
| DRIFT-03 | COVERED | `test/crosswake/guides/native_evidence_drift_test.exs` defines the source-derived scanner and synthetic regressions for stale native evidence truth. |

---

## Wave 0 Requirements

Existing infrastructure covers all Phase 119 requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Audit 2026-06-19

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

### Commands Run

| Command | Result | Notes |
|---------|--------|-------|
| `mix test test/mix/tasks/crosswake_gen_shell_test.exs test/crosswake/doctor/publish_readiness_test.exs` | pass | 13 tests, 0 failures |
| `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` | pass | 66 tests, 0 failures |
| `mix test test/crosswake/guides/native_evidence_drift_test.exs` | pass | 10 tests, 0 failures |
| `mix docs` | pass | Completed with pre-existing hidden-module and documentation-reference warnings |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or existing test infrastructure.
- [x] Sampling continuity: no three consecutive tasks lack automated verification.
- [x] Existing infrastructure covers all missing references.
- [x] No watch-mode flags are required.
- [x] Feedback latency is below 30 seconds for targeted ExUnit commands.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** approved 2026-06-19
