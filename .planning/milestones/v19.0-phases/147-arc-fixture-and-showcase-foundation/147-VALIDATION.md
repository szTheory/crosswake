---
phase: 147
slug: arc-fixture-and-showcase-foundation
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-09
updated: 2026-07-09
---

# Phase 147 - Validation Strategy

Per-phase validation contract for the v19 showcase foundation, deterministic reset path, route-owner/support labels, and first-run discovery.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix 1.19.x, plus Playwright Test 1.60.x for browser route-tour coverage |
| **Config file** | `examples/phoenix_host/test/test_helper.exs`; `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `cd examples/phoenix_host && mix test test/crosswake_example/showcase` |
| **Full suite command** | `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts` |
| **Estimated runtime** | ~90 seconds focused; full suite depends on local deps/server boot |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/phoenix_host && mix test test/crosswake_example/showcase` once Wave 0 creates showcase tests.
- **After every plan wave:** Run `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts`.
- **Before `/gsd:verify-work`:** Full example-host ExUnit suite plus targeted route-tour/hub Playwright proof must be green.
- **Max feedback latency:** 90 seconds for focused showcase tests after Wave 0 exists.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 147-W0-01 | 147-04 | 2 | SHOW-01 | T-147-01 | Hub renders static, escaped server-side catalog copy and visible labels | LiveView render + browser UAT | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/hub_live_test.exs` | yes | green |
| 147-W0-02 | 147-03 | 1 | SHOW-02 | T-147-02 | Reset contract mutates only fixed server-side resources and returns stable counts/digest | ExUnit integration + Mix task | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/reset_test.exs && mix showcase.reset` | yes | green |
| 147-W0-03 | 147-02 | 1 | SHOW-03 | T-147-03 | Catalog labels and route IDs match compiled Crosswake route metadata | ExUnit structural | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs` | yes | green |
| 147-W0-04 | 147-05 | 3 | SHOW-04 | T-147-04 | First-run copy points to the showcase first while keeping proof commands explicit | docs/shell structural + route tour | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/guides/see_it_run_test.exs test/crosswake/guides/see_it_run_banner_test.exs test/crosswake/guides/readme_see_it_run_test.exs` | yes | green |
| 147-W0-05 | 147-01 | 1 | ARC-01, ARC-02, ARC-03 | T-147-05 | Planning docs preserve v19 showcase -> v20 controls -> later follow-ons without claiming v19 native-control breadth | docs structural | `mix test test/crosswake/planning/milestone_arc_closeout_parity_test.exs` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` verifies showcased route IDs, paths, runtime/offline/security posture, allowed labels, and support-copy vocabulary against compiled route metadata, including the Learning/Training lane's `/offline` target.
- [x] `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` verifies reset idempotency, no duplicate persisted rows, stable counts, stable digest, and explicit browser-state non-claim.
- [x] `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` verifies `/` renders SaaS/admin, field-service, and learning/training cards with visible route-owner/support labels.
- [x] Docs/banner text guards verify `bin/see-it-run.sh`, README, `guides/see_it_run.md`, and `examples/QUICK_START.md` advertise the showcase first and proof lanes second.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Status |
|----------|-------------|------------|-------------------|--------|
| First-screen polish across desktop and mobile widths | SHOW-01, SHOW-03 | Visual composition and first-viewport hierarchy need browser review in addition to source assertions | Run the example host, open `http://localhost:4700/` at desktop and mobile widths, confirm all three lanes are visible or immediately scannable, labels are readable text, and unsupported/future pressure is not overstated. | completed by browser UAT; evidence in `uat-screenshots/` |
| Reduced-motion and dark/light/system behavior feel acceptable | SHOW-01 | Browser/user preference rendering needs viewport/theme execution | Toggle light/dark/system and reduced-motion preferences, then confirm the hub remains readable with visible focus rings and no hidden content. | completed by browser UAT; evidence in `uat-screenshots/` |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency under 90 seconds for focused showcase tests.
- [x] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and are green.

**Approval:** passed 2026-07-09.

## Validation Audit 2026-07-09

| Metric | Count |
|--------|-------|
| Requirements covered | 7 |
| Automated proof groups green | 5 |
| Browser UAT scenarios green | 4 |
| Escalated manual-only gaps | 0 |

Evidence:

- `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/hub_live_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/e2e/showcase_reset_controller_test.exs test/crosswake_example/router_test.exs` -> 18 tests, 0 failures.
- `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` -> 2 tests passed.
- `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/guides/see_it_run_test.exs test/crosswake/guides/see_it_run_banner_test.exs test/crosswake/guides/readme_see_it_run_test.exs` -> 31 tests, 0 failures.
- Browser UAT matrix -> desktop/mobile, light/dark, reduced motion, `learningHref=/offline`, no overflow, visible focus, no overlaps.
