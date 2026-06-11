---
phase: 101
slug: offline-ui-consolidation-polish
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-11
---

# Phase 101 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 101-02-01 | 02 | 2 | OFFC-01, OFFC-02, BRND-01, BRND-02 | — | N/A | unit | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake.gen.offline_ui_test.exs` — stubs for all requirements

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-11