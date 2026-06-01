---
phase: 53
slug: release-continuity-and-closeout-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/planning/closeout_verifier_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds for the targeted closeout verifier test; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/planning/closeout_verifier_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/planning test/crosswake/doctor/publish_readiness_test.exs test/crosswake/hex_page_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds for the targeted per-task verifier check; broader wave checks may exceed this because they intentionally include release/docs parity.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 53-01-01 | 01 | 1 | REL-01 | T-53-01 | malformed or missing closeout evidence fails closed | unit | `mix test test/crosswake/planning/closeout_verifier_test.exs` | ❌ W0 | ⬜ pending |
| 53-01-02 | 01 | 1 | REL-01 | T-53-02 | release/changelog truth distinguishes `[Unreleased]` from published Hex version `0.1.0` | unit/integration | `mix test test/crosswake/doctor/publish_readiness_test.exs test/crosswake/hex_page_test.exs` | ✅ | ⬜ pending |
| 53-02-01 | 02 | 2 | REL-01 | T-53-03 | closeout verifier is runnable through `mix closeout.verify` and returns actionable stable-id failures | task/integration | `mix test test/crosswake/planning/closeout_verifier_test.exs` | ❌ W0 | ⬜ pending |
| 53-03-01 | 03 | 3 | REL-01 | T-53-04 | milestone archive/reset and next-step routing remain explicit and non-duplicative | unit/docs parity | `mix test test/crosswake/planning/milestone_arc_closeout_parity_test.exs test/crosswake/planning/closeout_verifier_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/planning/closeout_verifier_test.exs` — stubs for REL-01 fail-closed closeout verifier behavior.
- [ ] `lib/crosswake/planning/closeout_verifier.ex` — validator module shape for stable check ids and structured results.
- [ ] `lib/mix/tasks/closeout.verify.ex` — thin Mix task wrapper over the shared validator.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Durable lesson wording in `PROJECT.md` / `MILESTONE-ARC.md` | REL-01 | The verifier can enforce existence and routing, but editorial quality of strategic prose remains maintainer judgment. | Review the final closeout diff and confirm it does not duplicate or contradict the strategic queue. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for per-task verifier checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
