---
phase: 52
slug: operator-proof-and-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~30-90 seconds for quick proof, project-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase52_operator_truth_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds for the focused Phase 52 proof

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | PROOF-01 / PROOF-02 | T-52-01 | Drift failures identify stable proof ids, source truth, observed drift, path, and remediation. | integration | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` | ❌ W0 | ⬜ pending |
| 52-02-01 | 02 | 1 | PROOF-01 / PROOF-02 | T-52-02 | Hermetic operator proof locks inspection, doctor, support, denial, rebuild, promotion, and guide non-claim truth. | integration | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` | ❌ W0 | ⬜ pending |
| 52-03-01 | 03 | 2 | PROOF-01 / PROOF-02 | T-52-03 | CI keeps merge-blocking hermetic proof separate from advisory provider/device/native visibility. | ci | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase52_operator_truth_test.exs` — central PROOF-01/PROOF-02 rollup.
- [ ] `test/support/proof_assertions.ex` — stable proof id assertion helpers, if needed to keep failures actionable.
- [ ] `.github/workflows/phase52-proof.yml` — required/advisory lane topology.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | PROOF-01 / PROOF-02 | Phase 52 proof must be hermetic and automated. | All phase behaviors have automated verification. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s for focused proof
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
