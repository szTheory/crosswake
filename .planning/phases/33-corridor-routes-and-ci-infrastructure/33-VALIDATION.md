---
phase: 33
slug: corridor-routes-and-ci-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `mix.exs` / `test/test_helper.exs` (existing — no Wave 0 install) |
| **Quick run command** | `mix compile --warnings-as-errors` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix compile --warnings-as-errors`
- **After every plan wave:** Run `mix test --exclude requires_example_host`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | PWAL-01 | — | N/A | unit | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |

*Planner fills the remaining rows. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements (ExUnit + mix already present).*

---

## Manual-Only Verifications

*All phase behaviors have automated verification (compile + manifest introspection + workflow-file assertions). No route is hit at runtime in Phase 33.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
