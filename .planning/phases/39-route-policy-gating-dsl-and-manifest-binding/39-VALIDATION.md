---
phase: 39
slug: route-policy-gating-dsl-and-manifest-binding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | GATE-01 | — | Invalid `gated_by` values rejected at compile time | unit | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` | ❌ W0 | ⬜ pending |
| 39-01-02 | 01 | 1 | GATE-01 | — | `on_unavailable` without `gated_by` is rejected | unit | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` | ❌ W0 | ⬜ pending |
| 39-02-01 | 02 | 2 | GATE-02 | — | `RouteEntry.gated_by` carries atom key, not flag value | unit | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` | ❌ W0 | ⬜ pending |
| 39-02-02 | 02 | 2 | GATE-02 | — | `to_map/1` serializes `gated_by`/`on_unavailable`; nil routes omit keys | unit | `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase39_route_policy_gating_test.exs` — new proof test stubs for GATE-01 and GATE-02

*All other infrastructure already exists — ExUnit is the project test framework and `phase34-proof.yml` picks up untagged proof tests automatically.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Doctor output shows `gated_by` field for gated routes | GATE-02 SC#2 | SC#2 doctor visibility requires runtime Doctor.run/1 invocation | Run `mix crosswake.doctor` on a sample app with a gated route; verify output mentions the `gated_by` binding |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
