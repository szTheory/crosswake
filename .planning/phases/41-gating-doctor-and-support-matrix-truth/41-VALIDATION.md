---
phase: 41
slug: gating-doctor-and-support-matrix-truth
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 41-01-01 | 01 | 1 | GATE-05 | — | N/A | unit | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --include sc1` | ❌ W0 | ⬜ pending |
| 41-01-02 | 01 | 1 | GATE-05 | — | N/A | unit | `mix test test/crosswake/proof/phase41_gating_doctor_test.exs --include sc2` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase41_gating_doctor_test.exs` — hermetic proof test stubs for SC#1 (gating doctor category) and SC#2 (support-matrix gate-state column)

*Existing ExUnit infrastructure covers Phase 41 — no new framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix crosswake.doctor` output format in a running dev console | GATE-05 | Full Mix task output requires a running app context | Run `iex -S mix` and call `Crosswake.Doctor.run/2` with a test manifest; inspect formatted output for "Gating" category heading |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
