---
phase: 135
slug: ci-ops-hardening-release-as-automation-proof-03
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-28
---

# Phase 135 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir / `mix test`) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` |
| **Full suite command** | `mix test` (hermetic suite) |
| **Estimated runtime** | ~quick: <10s · full: ~minutes |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs`
- **After every plan wave:** Run `mix test` (hermetic suite)
- **Before `/gsd-verify-work`:** Full hermetic suite must be green (1173/0 baseline)
- **Max feedback latency:** ~10 seconds (proof test)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 135-01-01 | 01 | 1 | PROOF-03 | — | SC1 staleness guard RED→GREEN (GIT_DIR fixture) | unit | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase135_ci_ops_proof_test.exs` — proof test covering SC1–SC5 for PROOF-03

*Existing ExUnit hermetic infrastructure covers framework needs — no install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real `release-as-cleanup` PR + `release-failure-alert` issue firing | PROOF-03 | Live GitHub side effects — deferred to next companion release | Validated structurally in-phase; live confirmation organic at sigra/chimeway/threadline release |
| Actual required-check registration | PROOF-03 | Irreversible admin/branch-protection action post origin-sync | `DRY_RUN=0 script/register_required_checks.sh` per `135-REQUIRED-CHECKS-REGISTRATION.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
