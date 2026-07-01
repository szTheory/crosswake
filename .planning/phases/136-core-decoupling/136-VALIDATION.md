---
phase: 136
slug: core-decoupling
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 136 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/phase136_decouple_proof_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green + `mix compile --warnings-as-errors`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | DECOUPLE-01..06 | — | fail-closed deny on missing companion | unit + property | `mix test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · (planner fills this map from PLAN.md tasks)*

---

## Wave 0 Requirements

- [ ] `test/crosswake/phase136_decouple_proof_test.exs` — the five backstop tests (companion raises → rescued deny; zero-companion reserved set empty; multiple auth-authority → first + warning; `baseline_forbidden_metadata_keys/0` public API; forbidden-key set captured at attach time)
- [ ] Existing infrastructure (ExUnit) covers the remaining phase requirements — no framework install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zero-companion `mix compile --warnings-as-errors` | DECOUPLE-01 | Requires temporarily removing companion deps from mix.exs / clean-room compile | Documented as a CI clean-room lane; not a per-task ExUnit assertion |

*Most phase behaviors have automated verification; the zero-dep compile is a compile-mode check, not a runtime assertion.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
