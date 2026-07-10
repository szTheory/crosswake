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
| 149-01-01 | 01 | 0 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | T-149-01..04 | RED contracts require fixture density, diagnostics derivation, server-authoritative approval, and gated e2e helper behavior before implementation | unit/browser contract | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs` | No, Wave 0 creates | pending |
| 149-02-01 | 02 | 1 | SAAS-01 | Plan 02 threat model | Fixture records are deterministic and do not introduce user-controlled data paths | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs` | No, Wave 0 | pending |
| 149-03-01 | 03 | 1 | SAAS-02, SAAS-03 | Plan 03 threat model | Diagnostics derive from compiled router metadata and lane catalog truth, not user-supplied params or prose-only labels | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/showcase/catalog_test.exs` | No, Wave 0 | pending |
| 149-04-01 | 04 | 2 | SAAS-04 | Plan 04 threat model | Approval authorization uses server-owned current user/account state and persists only mutable approval/activity evidence | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs` | No, Wave 0 | pending |
| 149-05-01 | 05 | 3 | SAAS-01, SAAS-02, SAAS-03 | Plan 05 threat model | AdminPilot pages render product context, route/support truth, and admin posture without widening into dashboard scope | render/unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/page_title_test.exs` | No, Wave 0 | pending |
| 149-06-01 | 06 | 4 | SAAS-04 | Plan 06 threat model | LiveView approve action remains server-authoritative and haptics is optional post-success confirmation | liveview | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs` | No, Wave 0 | pending |
| 149-07-01 | 07 | 5 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | Plan 07 threat model | Browser proof observes product flow and support truth through a compile-time-gated test helper without adding production auth/provider MFA | unit/browser | `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts` | Existing route tour, extend | pending |

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
