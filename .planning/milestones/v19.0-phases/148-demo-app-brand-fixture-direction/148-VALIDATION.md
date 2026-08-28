---
phase: 148
slug: demo-app-brand-fixture-direction
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-12
updated: 2026-07-12
---

# Phase 148 - Validation Strategy

Retroactive Nyquist validation for the Crosswake root showcase brand, three fictional demo-app micro-brands, fixture-density briefs, and root-hub visual/support-truth checks.

This phase was completed without plan `SUMMARY.md` files. The validation map is reconstructed from `148-VERIFICATION.md`, `.planning/REQUIREMENTS.md`, and the live example-host test suite.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix 1.19.x, plus Playwright Test 1.60.x for browser route-tour coverage |
| **Config file** | `examples/phoenix_host/test/test_helper.exs`; `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/branding_test.exs test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs` |
| **Full suite command** | `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts` |
| **Estimated runtime** | ~30 seconds focused; full suite/browser route tour depends on local deps/server boot |

---

## Sampling Rate

- **After every task commit:** Run the quick showcase brand command.
- **After every plan wave:** Run `cd examples/phoenix_host && mix test`.
- **Before `/gsd:verify-work`:** Run `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts`.
- **Max feedback latency:** No more than two implementation tasks may pass without focused ExUnit coverage.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 148-RETRO-01 | no plan summary | retroactive | BRAND-01 | T-148-01 | Root showcase remains Crosswake-owned, serves the real lockup assets, and does not present the old example-host product copy. | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/branding_test.exs test/crosswake_example/showcase/hub_live_test.exs && npx playwright test e2e/route_tour.spec.ts` | yes | green |
| 148-RETRO-02 | no plan summary | retroactive | BRAND-02 | T-148-02 | AdminPilot, Fieldserv, and LearnLoop remain fixed fictional demo-app identities with non-Crosswake names and distinct style hooks. | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/branding_test.exs test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs && npx playwright test e2e/route_tour.spec.ts` | yes | green |
| 148-RETRO-03 | no plan summary | retroactive | BRAND-03 | T-148-03 | Fixture briefs require realistic organization, people, records, activity, and pressure data for each lane. | unit/render | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/branding_test.exs test/crosswake_example/showcase/hub_live_test.exs` | yes | green |
| 148-RETRO-04 | no plan summary | retroactive | BRAND-04 | T-148-04 | Root-hub rendering, brand distinctness, fixture-density content, mobile containment, focus, and support-label honesty are covered before screenshots are treated as collateral. | unit/browser/visual UAT | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/branding_test.exs test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs test/crosswake_example/router_test.exs && npx playwright test e2e/route_tour.spec.ts` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `examples/phoenix_host/test/crosswake_example/showcase/branding_test.exs` verifies the Crosswake root brand, served lockup asset paths, stable fictional demo-app identities, unique style identifiers, and fixture-density thresholds.
- [x] `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` verifies each lane is bound to its fixed brand, route IDs/paths match compiled router metadata, and support/runtime labels remain allowlisted and honest.
- [x] `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` verifies the root hub renders Crosswake-owned copy, branded lane previews, fixture records/activity, CTAs, runtime/support labels, and proof routes one click deeper.
- [x] `examples/phoenix_host/e2e/route_tour.spec.ts` verifies loaded Crosswake logo assets, distinct rendered brand card styles, fixture preview text, support labels, mobile dark reduced-motion containment, and visible keyboard focus before screenshot capture.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| Desktop-light and mobile-dark-reduced visual polish | BRAND-04 | Visual composition, first-viewport hierarchy, and screenshot quality require inspection in addition to semantic assertions. | Run the example host at `http://localhost:4700/`, inspect desktop 1440x1000 and mobile 390x844 dark/reduced-motion views, and confirm no overflow, visible focus, loaded logo, readable fixtures, and visible support labels. | completed in `148-VERIFICATION.md`; screenshots in `uat-screenshots/` |

---

## Validation Sign-Off

- [x] All phase requirements have automated verification targets.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test references.
- [x] No watch-mode flags.
- [x] Feedback latency remains under the focused command budget.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** validated 2026-07-12.

## Validation Audit 2026-07-12

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Requirements covered | 4 |
| Automated proof groups green | 4 |
| Manual-only visual UAT items | 1 |

Evidence:

- `148-VERIFICATION.md` records 4/4 BRAND requirements verified, focused example-host tests passed, route-tour passed, `git diff --check` passed, and desktop/mobile visual UAT passed.
- `cd examples/phoenix_host && mix test test/crosswake_example/showcase/branding_test.exs test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs test/crosswake_example/router_test.exs` -> 24 tests, 0 failures.
- `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` -> 2 tests passed.
- The retroactive audit found no missing automated behavior for BRAND-01 through BRAND-04.
- No new test files were generated because existing ExUnit and Playwright coverage already targets the phase requirements.
