---
phase: 149
slug: saas-admin-showcase
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-10
---

# Phase 149 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix; Playwright 1.60.0 for browser route tour |
| **Config file** | `examples/phoenix_host/test/test_helper.exs`; `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs` |
| **Full suite command** | `cd examples/phoenix_host && mix test` |
| **Browser command** | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` |
| **Estimated runtime** | Quick: under 30 seconds; full suite/browser route tour depends on local server startup |

---

## Sampling Rate

- **After every task commit:** Run the narrowest focused ExUnit file touched by the task, then the quick run command once SaaS tests exist.
- **After every plan wave:** Run `cd examples/phoenix_host && mix test`.
- **Before `/gsd:verify-work`:** Run `cd examples/phoenix_host && mix test` and `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts`.
- **Max feedback latency:** No more than two implementation tasks may pass without an automated ExUnit command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 149-01-01 | 01 | 1 | SAAS-01 | N/A | Fixture records are deterministic and do not introduce user-controlled data paths | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs` | No, Wave 0 | pending |
| 149-02-01 | 02 | 1 | SAAS-02, SAAS-03 | T-149-01 | Diagnostics derive from backend/router truth, not user-supplied params | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/diagnostics_test.exs` | No, Wave 0 | pending |
| 149-03-01 | 03 | 2 | SAAS-04 | T-149-02 | Approval authorization uses server-owned current user/account state | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_test.exs` | No, Wave 0 | pending |
| 149-04-01 | 04 | 2 | SAAS-04 | T-149-03 | LiveView approve action remains server-authoritative and haptics is optional | liveview | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_live_test.exs` | No, Wave 0 | pending |
| 149-05-01 | 05 | 3 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | N/A | Browser proof observes product flow and support truth without requiring native APIs | browser | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` | Existing, extend | pending |

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` - covers SAAS-01 fixture density and reset digest components.
- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs` - covers SAAS-02 and SAAS-03 route metadata drift and support truth.
- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs` - covers SAAS-04 context authorization and optional approval/activity persistence.
- [ ] `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` - covers SAAS-04 LiveView action states.
- [ ] `examples/phoenix_host/e2e/route_tour.spec.ts` - extend existing route tour to click `dashboard -> approvals -> detail -> approve -> diagnostics`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Desktop/mobile visual containment across light, dark, system, reduced motion, and focus states | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | Browser route tour can prove semantic flow, but responsive clipping/focus quality still needs screenshot review unless a visual audit is added | Run the route tour locally, then inspect desktop and mobile screenshots for no horizontal overflow, no clipped badges/actions, visible focus, and readable contrast |

---

## Validation Sign-Off

- [ ] All tasks have automated verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing test references.
- [ ] No watch-mode flags in verification commands.
- [ ] Feedback latency remains under the command budget above.
- [ ] Set `nyquist_compliant: true` in frontmatter after Wave 0 tests exist and pass.

**Approval:** pending
