---
phase: 108
slug: consumer-normalization
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
reconstructed: true
---

# Phase 108 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Reconstructed retroactively** from PLAN/SUMMARY/VERIFICATION artifacts (State B — no VALIDATION.md existed at execution time).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` (Elixir generator contract) + `node:test` (consumer drift gate, Phase 109) |
| **Config file** | None — both invoked directly |
| **Quick run command** | `node brandbook/tools/check-consumer-drift.mjs` |
| **Full suite command** | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs && node --test brandbook/tools/check-consumer-drift.test.mjs` |
| **Estimated runtime** | < 2 seconds (ExUnit ~0.2s + drift gate < 1s; both browser-free) |

---

## Sampling Rate

- **After every task commit:** Run `node brandbook/tools/check-consumer-drift.mjs` (scans all 5 normalized consumers in < 1s)
- **After every plan wave:** Run the full suite above
- **Before `/gsd:verify-work`:** Generator test green (9/9) AND drift gate exits 0
- **Max feedback latency:** ~2 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-01 | 01 | 1 | NORM-01 | T-108-01 / accept | Served `app.css` is semantic-token-only (no hex, no `--cw-primitive-*`, no `var()` fallbacks) | contract/drift | `node brandbook/tools/check-consumer-drift.mjs` | ✅ | ✅ green |
| 108-01-02 | 01 | 1 | NORM-01 | — / — | Unserved duplicate `assets/css/app.css` removed; one canonical stylesheet | static | `test ! -f examples/phoenix_host/assets/css/app.css` | ✅ | ✅ green |
| 108-01-03 | 01 | 1 | NORM-01 | T-108-01 / accept | Offline page `index.html.heex` links `tokens.css` + semantic-only (no Tailwind hex) | contract/drift | `node brandbook/tools/check-consumer-drift.mjs` | ✅ | ✅ green |
| 108-02-01 | 02 | 2 | NORM-02 | T-108-04 / mitigate | Vendored `offline.css` consumes `--cw-*` semantic tokens; never redefines them; `color-scheme` + `:focus-visible` outline present | contract/drift | `node brandbook/tools/check-consumer-drift.mjs` | ✅ | ✅ green |
| 108-02-02 | 02 | 2 | NORM-02 | — / — | `offline_page`/`offline_root` templates: zero Tailwind classes, `.cw-offline-*` only, a11y markup (role=status/list, h2) | contract | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ✅ | ✅ green |
| 108-02-03 | 02 | 2 | NORM-02 | T-108-04 / mitigate | Generator vendors `offline.css` via no-clobber `ensure_file`; stale Tailwind/esbuild block retired | contract | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ✅ | ✅ green |
| 108-03-01 | 03 | 3 | NORM-04 | — / — | Generator test pins semantic-token contract (cw-offline-, var(--cw-surface-default), no-clobber, link-order); refutes retired Tailwind assertions | contract | `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` | ✅ | ✅ green |
| 108-04-01 | 04 | 4 | NORM-01, NORM-02 | — / — | D-13 render-verify: all 6 states AA-pass in light + dark; D-06 outlined buttons ≥4.5:1; focus ring visible | manual (visual) | see Manual-Only table | ✅ | ✅ approved |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* The ExUnit generator test (`crosswake.gen.offline_ui_test.exs`, 9 tests) pins NORM-02/NORM-04. The structural/semantic-token contract for the example-host consumers (NORM-01) is pinned by the Phase 109 drift gate (`brandbook/tools/check-consumer-drift.mjs`), whose `MANIFEST` includes all three Phase 108 consumer files (`examples/phoenix_host/priv/static/css/app.css`, `priv/static/crosswake/offline.css`, `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex`). No framework install required — both `node:test` and ExUnit are built in.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Normalized consumers render correctly in BOTH light and dark mode (D-13 release gate): brand palette correct, secondary text legible (≥4.5:1), D-06 outlined status buttons legible in both modes, focus ring visible, no white-on-white / unstyled flash, no layout shift | NORM-01, NORM-02 | Visual correctness of browser-rendered output cannot be asserted programmatically; requires a human viewing Playwright/Chromium screenshots. WCAG contrast was measured during 108-04. | Open `.planning/milestones/v10.0-phases/108-consumer-normalization/render/` (7–9 screenshots) and confirm against `108-RENDER-VERIFY.md` per-state verdicts. **Already signed off** — `human_signoff: approved` in 108-04-SUMMARY.md and 108-VERIFICATION.md frontmatter (szTheory, 2026-06-14). |

*Note: the structural half of NORM-01 (semantic-token-only, no drift) IS automated by the drift gate above; only the inherently-visual half is manual.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are inherently-visual manual-only (108-04)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra covers all)
- [x] No watch-mode flags
- [x] Feedback latency < 2s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-14 (retroactive reconstruction; all automated coverage verified green in-session)

---

## Validation Audit 2026-06-14

| Metric | Count |
|--------|-------|
| Requirements audited | 3 (NORM-01, NORM-02, NORM-04) |
| COVERED (automated) | 3 |
| MANUAL-ONLY (inherently visual, signed off) | 1 (D-13 render gate) |
| Gaps found | 0 |
| Tests generated | 0 (existing infra + Phase 109 drift gate already cover every requirement) |
| Escalated | 0 |

**Evidence captured in-session:**
- `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` → 9 tests, 0 failures
- `node brandbook/tools/check-consumer-drift.mjs` → "All 5 consumer file(s) passed drift check." (exit 0)
- Drift `MANIFEST` confirmed to include all three Phase 108 consumer files.
