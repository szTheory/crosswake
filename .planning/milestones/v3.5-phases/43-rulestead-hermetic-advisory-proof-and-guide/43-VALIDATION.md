---
phase: 43
slug: rulestead-hermetic-advisory-proof-and-guide
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-30
---

# Phase 43 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/guides/companions_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --exclude requires_example_host`
- **After every plan wave:** Run `mix test --exclude requires_example_host`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 43-01-01 | 01 | 1 | PROOF-01 | — | hermetic lane compiles without rulestead | integration | `mix test --exclude requires_example_host` | ✅ | ⬜ pending |
| 43-01-02 | 01 | 1 | PROOF-01 | — | advisory lane passes with rulestead present | integration | `MIX_INCLUDE_RULESTEAD=1 mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs` | ❌ W0 | ⬜ pending |
| 43-02-01 | 02 | 2 | PROOF-02 | — | docs-contract anchors match live code | unit | `mix test test/crosswake/guides/companions_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase43_rulestead_advisory_test.exs` — advisory assertion file (`:ok` path)
- [ ] `test/crosswake/guides/companions_test.exs` — docs-contract test for companions.md

*Existing ExUnit infrastructure covers all other test needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `phase43-proof.yml` hermetic CI job passes on PR | PROOF-01 | Requires GitHub Actions environment | Push branch, verify merge-blocking job green |
| Advisory CI job runs with `continue-on-error: true` | PROOF-01 | Requires schedule/dispatch trigger | Trigger `workflow_dispatch` on advisory job |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
