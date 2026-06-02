---
phase: 56
slug: step-up-intent-and-plug-liveview-ceremony
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs`; example-host proof uses `examples/phoenix_host/mix.exs` through root support helpers |
| **Quick run command** | `mix test test/crosswake/companions/sigra/step_up_test.exs --trace` |
| **Full suite command** | `mix test test/crosswake/companions/sigra/step_up_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-local `<automated>` command.
- **After every plan wave:** Run `mix test test/crosswake/companions/sigra/step_up_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` once both files exist.
- **Before `$gsd-verify-work`:** Phase 56 focused proof plus touched support/docs parity tests must be green.
- **Max feedback latency:** 90 seconds for focused commands.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | STEP-01 | T-56-01 / T-56-02 | Step-up locator rejects authority-bearing fields and record lifecycle is closed. | unit | `mix test test/crosswake/companions/sigra/step_up_test.exs --trace` | W0 | pending |
| 56-01-02 | 01 | 1 | STEP-01 | T-56-03 | `auth.step_up_intent.*` codes preserve public `:step_up_required` and sanitize shell details. | unit/proof | `mix test test/crosswake/companions/sigra/step_up_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` | W0 | pending |
| 56-02-01 | 02 | 2 | STEP-01, STEP-03 | T-56-04 / T-56-05 | Example-host intent issue/consume/cancel/revoke/expire uses server record authority and one-time conditional consume. | proof | `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` | W0 | pending |
| 56-02-02 | 02 | 2 | STEP-03 | T-56-06 / T-56-07 | Completion projects `SessionAuthorityLane`, renews host session instructions, rotates CSRF posture, and revalidates manifest route target. | proof | `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` | W0 | pending |
| 56-03-01 | 03 | 3 | STEP-02 | T-56-08 | Plug and LiveView adapters call the same ceremony core and fail closed into identical challenge decisions. | unit/proof | `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` | W0 | pending |
| 56-03-02 | 03 | 3 | STEP-02, STEP-03 | T-56-09 | Plug redirects/halts and LiveView redirects/halts without duplicating route assurance/freshness logic or leaving stale socket state. | proof | `mix test test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` | W0 | pending |
| 56-04-01 | 04 | 4 | STEP-01, STEP-02, STEP-03 | T-56-10 | Doctor/support/operator/docs truth says ceremony shipped and later auth-return/provider/native UI claims remain deferred. | docs/proof | `mix test test/crosswake/guides/companions_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/operator_inspection/json_formatter_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` | W0 | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

Existing infrastructure covers Phase 56 requirements. Plans should create or extend:

- `test/crosswake/companions/sigra/step_up_test.exs`
- `test/crosswake/proof/phase56_step_up_ceremony_test.exs`
- Existing docs/support/operator/doctor parity tests listed above

---

## Manual-Only Verifications

All Phase 56 behaviors have automated hermetic verification. Provider/device OAuth, passkey, native auth return, and native auth UI checks are out of scope for this phase.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for focused proof commands
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-02
