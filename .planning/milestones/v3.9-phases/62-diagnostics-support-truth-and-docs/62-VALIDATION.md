---
phase: 62
slug: diagnostics-support-truth-and-docs
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 62 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/support_matrix_test.exs` |
| **Full suite command** | `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs test/crosswake/support_matrix_test.exs test/crosswake/companions/chimeway/telemetry_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/support_matrix/renderer_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/support_matrix_test.exs`
- **After every plan wave:** Run full suite command above
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 62-01-01 | 01 | 1 | DIAG-02 | — | Chimeway telemetry exposes stable `notification.open.*` event names (`received`, `resolved`, `denied`) and adds `route_id`, `action_ref`, `denial_code` to metadata keys. | unit | `mix test test/crosswake/companions/chimeway/telemetry_test.exs` | ✅ W0 | ✅ green |
| 62-01-02 | 01 | 1 | DIAG-01 | — | SupportMatrix `notification_support_truth/0` accurately reports token binding and open routing as fully supported while push delivery execution remains deferred and unsupported. | unit | `mix test test/crosswake/support_matrix_test.exs` | ✅ W0 | ✅ green |
| 62-02-01 | 02 | 1 | DIAG-01 | — | `OperatorInspection` computes and exposes `open_routing_active` for each route based on the `notification_open` policy attribute, giving operators truthful per-route inspection. | unit | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` | ✅ W0 | ✅ green |
| 62-03-01 | 03 | 2 | DIAG-01, DIAG-02 | — | Doctor CLI surfaces missing delivery support warnings and telemetry contracts via `phase_62_notification_findings`; findings dynamically pull from `SupportMatrix.notification_support_truth/0`. | unit | `mix test test/crosswake/doctor/doctor_test.exs` | ✅ W0 | ✅ green |
| 62-03-02 | 03 | 2 | DIAG-01, DIAG-02 | — | `mix crosswake.doctor` task correctly invokes Doctor and formats notification findings for operator consumption. | unit | `mix test test/mix/tasks/crosswake_doctor_test.exs` | ✅ W0 | ✅ green |
| 62-04-01 | 04 | 3 | DIAG-01, DIAG-02 | — | `guides/support_matrix.md` is generated from `SupportMatrix.Renderer` and maintains exact parity with programmatic `SupportMatrix` truth; notification support sections declare token binding/open routing as supported and push delivery as deferred. | unit | `mix test test/crosswake/support_matrix/renderer_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The phase modified existing test files across plans 62-01 through 62-04. All test files for the diagnostics subsystem (`telemetry_test.exs`, `support_matrix_test.exs`, `operator_inspection_test.exs`, `doctor_test.exs`, `crosswake_doctor_test.exs`, `renderer_test.exs`) were already present and extended during implementation.

---

## Manual-Only Verifications

All Phase 62 behaviors have automated verification.

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

All 6 tasks (DIAG-01/02) verify through the diagnostics test suite. Audit re-ran the full phase suite (`mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs test/crosswake/support_matrix_test.exs test/crosswake/companions/chimeway/telemetry_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/support_matrix/renderer_test.exs` → `50 tests, 0 failures`). Ledger created from scratch using 62-01 through 62-04 SUMMARYs and 62-VERIFICATION.md (status: passed, 2/2 must-haves). No MISSING or PARTIAL requirements. Phase 62 is Nyquist-compliant.
