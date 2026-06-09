---
phase: 92
slug: server-propagation-plug-liveview
status: draft
nyquist_compliant: true
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
| 92-01-T1 | 92-01 | 1 | PROP-01 | T-92-04 | `Id.generate/0` mints CSPRNG-backed RFC-4122 v4 UUIDs | unit | `mix test test/crosswake/threadline/id_test.exs` | ❌ W0 | ⬜ pending |
| 92-01-T2 | 92-01 | 1 | PROP-01 | T-92-01,T-92-03 | Plug never overwrites inbound thread id; rejects forbidden/PII keys via Phase 91 allowlist guard | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ W0 | ⬜ pending |
| 92-02-T1 | 92-02 | 1 | PROP-03 | T-92L-02,T-92L-03 | on_mount never crashes static render; reads connect params only when connected; never mints | unit | `mix test test/crosswake/live/threadline_test.exs` | ❌ W0 | ⬜ pending |
| 92-03-T1 | 92-03 | 2 | PROP-01,PROP-03 | T-92P-01,T-92P-02 | Hermetic merge-blocking proof asserts full Plug + on_mount contracts | proof | `mix test test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | ❌ W0 | ⬜ pending |
| 92-03-T2 | 92-03 | 2 | PROP-01,PROP-03 | T-92P-SC | Hex `@version` bump 0.1.1→0.1.2 | unit | `grep -c '@version "0.1.2"' mix.exs` | ✅ exists | ⬜ pending |

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
