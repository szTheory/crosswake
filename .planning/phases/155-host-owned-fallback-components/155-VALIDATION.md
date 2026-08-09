---
phase: 155
slug: host-owned-fallback-components
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-30
---

# Phase 155 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `155-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir core) + Playwright `@playwright/test` (browser, `examples/phoenix_host`) + Node test runner (`brandbook/tools/*.mjs`) |
| **Config file** | `mix.exs` (ExUnit, no separate config) / `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `mix test <targeted file>` · `node brandbook/tools/contrast.test.mjs` · `npx playwright test e2e/native_controls_fallback.spec.ts` |
| **Full suite command** | `mix test --warnings-as-errors` (core) · `npx playwright test` (unfiltered, matches the real `e2e-proof` CI step) |
| **Estimated runtime** | ~60s targeted ExUnit · ~5–10 min full `mix test` · ~3–6 min unfiltered Playwright |

---

## Sampling Rate

- **After every task commit:** Run `mix test <targeted file>` and/or `node brandbook/tools/contrast.test.mjs` / `node brandbook/tools/check-consumer-drift.mjs` — whichever the task touches.
- **After every plan wave:** Run `mix test --warnings-as-errors` (core); for any wave touching `examples/phoenix_host`, also `mix compile --warnings-as-errors` there.
- **Before `/gsd-verify-work`:** `npx playwright test` (unfiltered) green, plus `node script/check-e2e-honesty.mjs` and `node brandbook/tools/check-consumer-drift.mjs` green.
- **Max feedback latency:** 60 seconds (targeted ExUnit)

---

## Per-Task Verification Map

<!-- Task IDs are assigned by gsd-planner. Rows below are seeded per REQUIREMENT from
     155-RESEARCH.md § Phase Requirements → Test Map; /gsd-validate-phase expands them
     to one row per task once PLAN.md task IDs exist. -->

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | FALL-01 | — | Generator copies confirm-modal + action-menu verbatim; no-clobber on second run; stamped | unit | `mix test test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FALL-02 | — | No importable `Crosswake.UI.*` module; guard's six rules enforced with anti-vacuity twin | unit | `mix test test/crosswake/component_tier_guard_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FALL-02 (D-50/D-51) | — | `resolve/2` never raises on an unattached socket; distinct `UnknownCapabilityFamilyError` on vocabulary miss | unit | `mix test test/crosswake/bridge_test.exs` | ⚠️ file exists, new cases | ⬜ pending |
| TBD | TBD | TBD | PROOF-01 | — | Browser proves fallback renders (A1), fails closed on undeclared (A2), never silently degrades (A3) | e2e | `npx playwright test e2e/native_controls_fallback.spec.ts` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | FALL-01/02 (contrast) | — | New/fixed tokens meet contrast floors, including the focus-ring gate hole | unit | `node brandbook/tools/contrast.test.mjs` | ⚠️ file exists, new assertions | ⬜ pending |
| TBD | TBD | TBD | FALL-01 (drift) | — | New template files gated against brand-color drift | structural | `node brandbook/tools/check-consumer-drift.mjs` | ⚠️ file exists, MANIFEST entries | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` — FALL-01 (no-clobber, stamp, printed output)
- [ ] `test/crosswake/component_tier_guard_test.exs` — FALL-02 (six rules + anti-vacuity twin, positive/negative controls per D-37)
- [ ] `examples/phoenix_host/e2e/native_controls_fallback.spec.ts` — PROOF-01 (A1/A2/A3)
- [ ] `examples/phoenix_host/lib/crosswake_example/e2e/` — new `/_e2e/undeclared-control` route + controller for A2, plus the `CROSSWAKE_PROOF_BREAK_FALLBACK` mutation control (D-47)
- [ ] Extend `test/crosswake/bridge_test.exs` — D-50 (`resolve/2` on unattached socket) and D-51 (`UnknownCapabilityFamilyError`)
- [ ] Framework install: **none** — ExUnit, Playwright, and the Node test runner are all already present; only new test files are needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*Target: all phase behaviors have automated verification. Per Phase 135 / PROOF-03 shift-left discipline, any behavior landing here must justify why it is genuine human judgment rather than a timing-gated check that CI can own.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
