---
phase: 107
slug: token-source-distribution
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
validated: 2026-06-14
---

# Phase 107 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node (`node:test` generator assertions) + ExUnit (Elixir generator task) |
| **Config file** | none — assertions are file-content greps + command output checks |
| **Quick run command** | `node --test brandbook/tools/compile-tokens.test.mjs` |
| **Full suite command** | `node --test brandbook/tools/compile-tokens.test.mjs && diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css && mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `node brandbook/tools/compile-tokens.js` and grep/test the affected output file
- **After every plan wave:** Run the full suite command (regenerate + byte-diff parity + relevant mix test)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-T1 | 107-01 | 1 | TOKN-04 / TOKN-05 | T-107-01, T-107-02 | N/A (build tooling, no runtime auth surface) | content-assert | `node brandbook/tools/compile-tokens.js` + grep `--cw-font-display`/`--cw-text-scale-md`/`--cw-radius-lg` | ✅ exists (extended) | ✅ green |
| 01-T2 | 107-01 | 1 | TOKN-04 / TOKN-05 | T-107-01, T-107-SC | N/A | unit + parity | `node --test brandbook/tools/compile-tokens.test.mjs && diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css` | ✅ created (25 tests pass) | ✅ green |
| 02-T1 | 107-02 | 2 | NORM-03 | T-107-03, T-107-04 | N/A (no-clobber copy) | integration | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ✅ exists (9 tests pass) | ✅ green |
| 02-T2 | 107-02 | 2 | NORM-03 | T-107-03, T-107-04 | N/A | content-assert | `diff priv/static/crosswake/tokens.css examples/phoenix_host/priv/static/css/tokens.css` + grep `/css/tokens.css` | ✅ (greppable) | ✅ green |
| 03-T1 | 107-03 | 1 | NORM-03 | T-107-05, T-107-SC | N/A (doc-only) | smoke | `test -f guides/tokens.md && grep -q 'node brandbook/tools/compile-tokens.js' guides/tokens.md && grep -q 'guides/tokens.md' mix.exs` | ✅ created | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] No new test framework — assertions are deterministic file-content greps, `node:test` unit tests, and `diff` parity checks against generated output.
- [x] 8 new Node tests in `brandbook/tools/compile-tokens.test.mjs` (font/dim presence + priv mirror existence + byte-identical parity) — created in Plan 01 Task 2. *(suite total now 25 tests, all green.)*
- [x] New assertions in `crosswake.gen.offline_ui_test.exs` (tokens.css copy + link-before-app.css ordering) — created in Plan 02 Task 1. *(suite total now 9 tests, all green.)*
- [x] `guides/tokens.md` created — Plan 03 Task 1.

*Existing infrastructure (Node `node:test` + ExUnit) covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Brand book still loads tokens.css via relative path | NORM-03 | Visual/browser load of frozen v9.0 brand book | Open `brandbook/index.html`, confirm token styles still apply (tokens.css output retained unchanged from v9.0 aside from the appended fonts/dimensions block) |

*All other phase behaviors have automated (greppable) verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated

---

## Validation Audit 2026-06-14

Retroactive Nyquist audit of completed phase (State A). All 5 per-task verifications re-run live against the working tree; all green. No gaps found — every requirement (TOKN-04, TOKN-05, NORM-03) has automated verification. No auditor spawn required.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Live re-run evidence (2026-06-14):**
- `node --test brandbook/tools/compile-tokens.test.mjs` → 25 pass / 0 fail
- `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` → 9 tests, 0 failures
- `diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css` → exit 0 (byte-identical)
- `diff priv/static/crosswake/tokens.css examples/phoenix_host/priv/static/css/tokens.css` → exit 0 (byte-identical)
- grep `--cw-font-display` / `--cw-text-scale-md` / `--cw-radius-lg` in tokens.css → all present
- doc smoke: `guides/tokens.md` exists + contains generate command + registered in `mix.exs` extras → pass
