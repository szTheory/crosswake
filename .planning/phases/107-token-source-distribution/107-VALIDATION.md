---
phase: 107
slug: token-source-distribution
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 107 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node (generator assertions) + ExUnit (Elixir generator task) |
| **Config file** | none — assertions are file-content greps + command output checks |
| **Quick run command** | `node brandbook/tools/compile-tokens.js && grep -c '^  --cw-' brandbook/tokens/tokens.css` |
| **Full suite command** | `node brandbook/tools/compile-tokens.js && diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css && mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `node brandbook/tools/compile-tokens.js` and grep the affected output file
- **After every plan wave:** Run the full suite command (regenerate + byte-diff parity + mix test)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | TOKN-04 / TOKN-05 / NORM-03 | — | N/A (build tooling, no runtime auth surface) | content-assert | `node brandbook/tools/compile-tokens.js` + grep | ❌ W0 | ⬜ pending |

*Planner fills this map. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No new test framework — assertions are deterministic file-content greps and `diff` parity checks against generated output.

*Existing infrastructure (Node + ExUnit) covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Brand book still loads tokens.css via relative path | NORM-03 | Visual/browser load of frozen v9.0 brand book | Open `brandbook/index.html`, confirm token styles still apply |

*All other phase behaviors have automated (greppable) verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
