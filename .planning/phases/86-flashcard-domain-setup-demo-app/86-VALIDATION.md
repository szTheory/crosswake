---
phase: 86
slug: flashcard-domain-setup-demo-app
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 86 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `examples/phoenix_host/test/test_helper.exs` |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 86-01-01 | 01 | 1 | DEMO-01 | — | N/A | unit | `mix test test/crosswake_example/flashcards_test.exs` | ❌ W0 | ⬜ pending |
| 86-01-02 | 01 | 1 | DEMO-01 | — | N/A | unit | `mix test test/crosswake_example/flashcards_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/test/crosswake_example/flashcards_test.exs`
- [ ] `examples/phoenix_host/test/support/flashcards_fixtures.ex`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | DEMO-01 | All phase behaviors have automated verification. | N/A |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
