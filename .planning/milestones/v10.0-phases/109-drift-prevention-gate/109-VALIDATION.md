---
phase: 109
slug: drift-prevention-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 109 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `node:test` (built-in, Node 22.x) — no new dependency |
| **Config file** | None — invoked directly |
| **Quick run command** | `node brandbook/tools/check-consumer-drift.mjs` |
| **Full suite command** | `node --test brandbook/tools/check-consumer-drift.test.mjs` |
| **Estimated runtime** | < 1 second (purely textual, no browser) |

---

## Sampling Rate

- **After every task commit:** Run `node brandbook/tools/check-consumer-drift.mjs`
- **After every plan wave:** Run `node --test brandbook/tools/check-consumer-drift.test.mjs`
- **Before `/gsd:verify-work`:** Full `brand-structural` job logic must pass (gate exits 0 on the current clean tree)
- **Max feedback latency:** ~1 second

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-01-* | 01 | 1 | PROOF-01 (SC #4) | — / — | One-command local runner exits 0 on clean tree | integration | `node brandbook/tools/check-consumer-drift.mjs` | ❌ W0 | ⬜ pending |
| 109-02-* | 02 | 2 | PROOF-01 (SC #1) | — / — | Fails (exit 1) on hardcoded brand hex in a consumer | unit/contract | `node --test brandbook/tools/check-consumer-drift.test.mjs` | ❌ W0 | ⬜ pending |
| 109-02-* | 02 | 2 | PROOF-01 (SC #2) | — / — | Fails (exit 1) when a CSS consumer loses all `var(--cw-` refs | unit/contract | `node --test brandbook/tools/check-consumer-drift.test.mjs` | ❌ W0 | ⬜ pending |
| 109-02-* | 02 | 2 | PROOF-01 (manifest) | — / — | All 5 manifest paths exist + green baseline (exit 0) | unit/contract | `node --test brandbook/tools/check-consumer-drift.test.mjs` | ❌ W0 | ⬜ pending |
| 109-02-* | 02 | 2 | PROOF-01 (guards) | — / — | `#id` selector, `rgba()` shadow, and CSS `display:flex` NOT flagged | unit/contract | `node --test brandbook/tools/check-consumer-drift.test.mjs` | ❌ W0 | ⬜ pending |
| 109-03-* | 03 | 3 | PROOF-01 (SC #3) | — / — | Runs in `brand-structural` before Playwright install; browser-free, OS-deterministic | integration | CI run + local `node brandbook/tools/check-consumer-drift.mjs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `brandbook/tools/check-consumer-drift.mjs` — main drift check script (created Wave 1; no test infra needed beyond built-in `node:test`)
- [ ] `brandbook/tools/check-consumer-drift.test.mjs` — contract/pin test with synthetic injected-hex and stripped-`var` fixtures (created Wave 2)
- [ ] No framework install — `node:test` is built in (Node 22.x)

*The check script and its contract test are themselves the validation deliverables; there is no pre-existing suite to stub against. Synthetic fixtures (in-memory or temp-file) drive the negative cases without mutating real consumers.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cross-OS determinism (macOS == Linux CI) | PROOF-01 (SC #3) | Requires a real CI run on Linux to compare against local macOS | Run `node brandbook/tools/check-consumer-drift.mjs` locally; confirm identical pass/fail and report against the GitHub Actions `brand-structural` job log |

*All other phase behaviors have automated verification via the contract test.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 2s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
