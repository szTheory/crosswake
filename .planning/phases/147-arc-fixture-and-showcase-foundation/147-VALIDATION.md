---
phase: 147
slug: arc-fixture-and-showcase-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-09
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
| 147-W0-01 | TBD | 0 | SHOW-01 | T-147-01 | Hub renders static, escaped server-side catalog copy and visible labels | LiveView render | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/hub_live_test.exs` | no - Wave 0 | pending |
| 147-W0-02 | TBD | 0 | SHOW-02 | T-147-02 | Reset contract mutates only fixed server-side resources and returns stable counts/digest | ExUnit integration | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/reset_test.exs` | no - Wave 0 | pending |
| 147-W0-03 | TBD | 0 | SHOW-03 | T-147-03 | Catalog labels and route IDs match compiled Crosswake route metadata | ExUnit structural | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs` | no - Wave 0 | pending |
| 147-W0-04 | TBD | 0 | SHOW-04 | T-147-04 | First-run copy points to the showcase first while keeping proof commands explicit | docs/shell structural | `rg "showcase" bin/see-it-run.sh README.md guides/see_it_run.md examples/QUICK_START.md` | yes | pending |
| 147-W0-05 | TBD | 0 | ARC-01, ARC-02, ARC-03 | T-147-05 | Planning docs preserve v19 showcase -> v20 controls -> later follow-ons without claiming v19 native-control breadth | docs structural | `rg "Native Controls Pack 1|SEED-002|SEED-003|SEED-004" .planning/PROJECT.md .planning/STATE.md .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/MILESTONE-ARC.md` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` verifies showcased route IDs, paths, runtime/offline/security posture, allowed labels, and support-copy vocabulary against compiled route metadata.
- [ ] `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` verifies reset idempotency, no duplicate persisted rows, stable counts, stable digest, and explicit browser-state non-claim.
- [ ] `examples/phoenix_host/test/crosswake_example/showcase/hub_live_test.exs` verifies `/` renders SaaS/admin, field-service, and learning/training cards with visible route-owner/support labels.
- [ ] Optional docs/banner text guard verifies `bin/see-it-run.sh`, README, `guides/see_it_run.md`, and `examples/QUICK_START.md` advertise the showcase first and proof lanes second.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First-screen polish across desktop and mobile widths | SHOW-01, SHOW-03 | Visual composition and first-viewport hierarchy need human review in addition to source assertions | Run the example host, open `http://localhost:4700/` at desktop and mobile widths, confirm all three lanes are visible or immediately scannable, labels are readable text, and unsupported/future pressure is not overstated. |
| Reduced-motion and dark/light/system behavior feel acceptable | SHOW-01 | Browser/user preference rendering is hard to prove fully with the planned structural tests | Toggle light/dark/system and reduced-motion preferences, then confirm the hub remains readable with visible focus rings and no hidden content. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency under 90 seconds for focused showcase tests.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 tests exist and are green.

**Approval:** pending.
