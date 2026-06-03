---
phase: 47
slug: companion-arc-guide-and-milestone-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/guides/companions_test.exs test/crosswake/proof/phase47_companion_arc_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Estimated runtime** | ~60 seconds targeted, ~180 seconds full hermetic |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/guides/companions_test.exs test/crosswake/proof/phase47_companion_arc_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host --exclude advisory_only`
- **Before `$gsd-verify-work`:** Full hermetic suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | PROOF-02 | T-47-01 | Guide claims cannot drift from live companion/support/doctor truth | docs-contract | `mix test test/crosswake/guides/companions_test.exs` | ✅ | ⬜ pending |
| 47-01-02 | 01 | 1 | PROOF-02 | T-47-02 | Enabled missing optional dependencies fail closed with doctor `:error` findings | proof | `mix test test/crosswake/proof/phase47_companion_arc_test.exs` | ❌ W0 | ⬜ pending |
| 47-01-03 | 01 | 1 | PROOF-02 | T-47-03 | Hermetic merge path excludes advisory-only dependency-present assertions | integration | `mix test --exclude requires_example_host --exclude advisory_only` | ✅ | ⬜ pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase47_companion_arc_test.exs` — aggregate milestone proof for PROOF-02
- [ ] Extend `test/crosswake/guides/companions_test.exs` helpers for live-code parity assertions

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
