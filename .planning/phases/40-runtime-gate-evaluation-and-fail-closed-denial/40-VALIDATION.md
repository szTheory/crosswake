---
phase: 40
slug: runtime-gate-evaluation-and-fail-closed-denial
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 40 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 1 | GATE-03 | — | gate_denied denial produced with flag_key, reason, variant, evaluated_at | unit | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` | ❌ W0 | ⬜ pending |
| 40-01-02 | 01 | 1 | GATE-04 | — | kill_switch_active short-circuits ahead of all other gate checks | unit | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` | ❌ W0 | ⬜ pending |
| 40-01-03 | 01 | 1 | GATE-03 | — | unavailable flag snapshot defaults to :deny | unit | `mix test test/crosswake/proof/phase40_gate_evaluation_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase40_gate_evaluation_test.exs` — stubs for GATE-03, GATE-04

*Existing ExUnit infrastructure covers all other phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Doctor output shows `on_unavailable: :fallback_phoenix` carve-out as deliberate choice | GATE-03 | Requires running Doctor in context of a real route config | Run doctor output check against a route with `on_unavailable: :fallback_phoenix` and verify carve-out is labeled as deliberate |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
