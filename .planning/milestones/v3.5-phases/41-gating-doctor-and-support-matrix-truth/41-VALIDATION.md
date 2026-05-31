---
phase: 41
slug: gating-doctor-and-support-matrix-truth
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
---

# Phase 41 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase41_gating_doctor_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 41-01-01 | 01 | 1 | GATE-05 | — | N/A | unit | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc1` | ✅ | ✅ green |
| 41-01-02 | 01 | 1 | GATE-05 | — | N/A | unit | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --only sc2` | ✅ | ✅ green |
| 41-02-01 | 02 | 1 | GATE-05 | — | N/A | integration | `mix test test/crosswake/doctor/doctor_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase41_gating_doctor_test.exs` — hermetic proof test stubs for SC#1 (gating doctor category) and SC#2 (support-matrix gate-state column)

*Existing ExUnit infrastructure covers Phase 41 — no new framework install needed.*

---

## Manual-Only Verifications

*None — all verifications are automated. The Doctor formatted output check is covered by the GatingIntegrationRouter integration test in `test/crosswake/doctor/doctor_test.exs` (asserts `gating.route_gated` and `gating.flag_reference_unknown` codes appear in both `Formatter.render/1` human output and `JSONFormatter.render/1` JSON output). CI workflow: `.github/workflows/phase41-proof.yml`.*

---

## Validation Sign-Off

- [x] All tasks have automated verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
