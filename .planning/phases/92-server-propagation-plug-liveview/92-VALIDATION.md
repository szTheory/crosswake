---
phase: 92
slug: server-propagation-plug-liveview
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-09
---

# Phase 92 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in, Elixir 1.18) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/plug/ test/crosswake/live/ test/crosswake/threadline/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command scoped to the touched module's test file
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (filled by planner) | — | — | PROP-01 | — | Plug never overwrites inbound thread id; rejects forbidden/PII keys via Phase 91 allowlist guard | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ W0 | ⬜ pending |
| (filled by planner) | — | — | PROP-03 | — | on_mount never crashes static render; reads connect params only when connected | unit | `mix test test/crosswake/live/threadline_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/threadline/id_test.exs` — UUID v4 generator stubs
- [ ] `test/crosswake/plug/threadline_test.exs` — stubs for PROP-01
- [ ] `test/crosswake/live/threadline_test.exs` — stubs for PROP-03

Existing ExUnit infrastructure covers framework needs — no install required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LiveView WebSocket mount carries thread_id end-to-end in a real Phoenix app | PROP-03 | Requires a running Phoenix host with a browser WebSocket connection | Run `examples/phoenix_host`, open a LiveView page, confirm `crosswake_thread_id` appears in `Logger.metadata` for the LiveView process |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
