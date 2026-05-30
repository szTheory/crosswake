---
phase: 42
slug: rulestead-in-tree-companion-and-mock-example
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 42 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib) |
| **Config file** | `test/test_helper.exs` — `ExUnit.start()` |
| **Quick run command** | `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 42-??-01 | 01 | 1 | COMP-01 | — | Companion satisfies all 6 callbacks | unit | `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs` | ❌ W0 | ⬜ pending |
| 42-??-02 | 01 | 1 | COMP-02 | T-gate-bypass | Doctor :error for enabled + library absent | unit | same | ❌ W0 | ⬜ pending |
| 42-??-03 | 01 | 1 | COMP-03 | — | `lib/crosswake/companions/rulestead/` directory; telemetry spans fire | unit | same | ❌ W0 | ⬜ pending |
| 42-??-04 | 01 | 1 | GATE-02 | T-state-leak | MockFlagSource: no-network runtime lookup | unit | same | ❌ W0 | ⬜ pending |
| 42-??-05 | 01 | 1 | GATE-03 | — | `:gated` → `:gate_denied` denial | unit | same | ❌ W0 | ⬜ pending |
| 42-??-06 | 01 | 1 | GATE-04 | T-nil-return | `:killed` → kill-switch denial; route_gated? skipped | unit | same | ❌ W0 | ⬜ pending |
| 42-??-07 | 01 | 1 | GATE-05 | — | Clean doctor output with mock configured | unit | same | ❌ W0 | ⬜ pending |
| 42-??-08 | 02 | 2 | GATE-01 | — | `gated_by: :my_flag` route compiles + binds in manifest | integration | `mix test --exclude requires_example_host` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase42_rulestead_companion_test.exs` — SC#1, SC#2, SC#3 proof stubs (`async: false`, `Application.put_env` + `on_exit`)
- [ ] `lib/crosswake/companions/rulestead.ex` (or `lib/crosswake/companions/rulestead/rulestead.ex`) — main companion module skeleton
- [ ] `lib/crosswake/companions/rulestead/mock_flag_source.ex` — named Agent process skeleton

*Existing test infrastructure requires no changes — the new proof file is untagged and picked up by `mix test --exclude requires_example_host` automatically.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All three gate states visually confirmed in phoenix_host `/gating` route | GATE-01, GATE-03, GATE-04 | Requires running phoenix_host dev server | `iex -S mix phx.server`, call `MockFlagSource.set_flag(:my_flag, :gated)` then `:killed` then `{:rolling_out, 50}`, observe route response |

---

## Threat Model (ASVS L1)

| Threat | STRIDE | Mitigation |
|--------|--------|------------|
| Gate bypass via disabled companion | Elevation of privilege | `enabled?/1` defaults `false`; companion must be explicitly enabled in config |
| MockFlagSource state leaking between test runs | Tampering (test reliability) | `start_supervised!` in ExUnit setup ensures Agent is fresh per test |
| `kill_switch_active?` returning nil instead of false | Fail-open | Callback contract enforces `boolean()` return; companion must not return nil |
| `validate_dependency/0` swallowing errors | Tampering | Returns typed `{:error, [module()]}` — no catch-all exception swallowing |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
