---
phase: 149
slug: saas-admin-showcase
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-10
---

# Phase 149 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Closeout Refresh

This closeout refresh file was refreshed during Phase 152.1 on 2026-07-12 to reflect the current verified closeout state from `149-VERIFICATION.md`. The refresh updates stale planning-time Wave 0 and approval metadata after the phase had already passed verification; it does not claim this metadata was historically accurate during every execution step.

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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command(s) | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|----------------------|-------------|--------|
| 149-01-01 | 01 | 0 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | T-149-01..04 | RED contracts require fixture density, diagnostics derivation, server-authoritative approval, and LiveView action states while rejecting syntax/compile/unexpected runtime failures | unit RED contract | `cd examples/phoenix_host && sh -c 'mix test --warnings-as-errors --no-start test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs --trace > /tmp/phase149-wave0-exunit-red.log 2>&1; status=$?; test "$status" -ne 0 && rg "AdminPilot fixture density contract" /tmp/phase149-wave0-exunit-red.log && rg "AdminPilot diagnostics route rows contract" /tmp/phase149-wave0-exunit-red.log && rg "AdminPilot approval schema persistence contract" /tmp/phase149-wave0-exunit-red.log && rg "AdminPilot approval queue LiveView contract" /tmp/phase149-wave0-exunit-red.log && ! rg "SyntaxError|CompileError|UndefinedFunctionError|FunctionClauseError|MatchError|ArgumentError|RuntimeError|KeyError|Protocol\\.UndefinedError|CaseClauseError|WithClauseError|BadMapError|BadBooleanError|BadArityError|cannot compile" /tmp/phase149-wave0-exunit-red.log'` | No, Wave 0 creates | complete |
| 149-01-02 | 01 | 0 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | T-149-02..03 | Browser contract asserts route IDs, approval path, diagnostics, and screenshot-after-semantic-proof ordering before implementation | browser contract | `cd examples/phoenix_host && rg "proveAdminPilotApprovalFlow" e2e/route_tour.spec.ts && rg "/_e2e/saas-session" e2e/route_tour.spec.ts && rg "saas-dashboard" e2e/route_tour.spec.ts && rg "saas-approvals" e2e/route_tour.spec.ts && rg "saas-approval" e2e/route_tour.spec.ts && rg "Approve request" e2e/route_tour.spec.ts && rg "adminpilot-diagnostics" e2e/route_tour.spec.ts` | Existing route tour, extend | complete |
| 149-02-01 | 02 | 1 | SAAS-01, SAAS-02 | T-149-05..07 | Fixture records are deterministic, fictional, role-aware, and do not introduce user-controlled account/role paths | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs` | Wave 0 creates | complete |
| 149-02-02 | 02 | 1 | SAAS-01 | T-149-05..07 | Read context and reset digest expose static SaaS breadth without broad table persistence | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs` | Wave 0 creates | complete |
| 149-03-01 | 03 | 1 | SAAS-02, SAAS-03 | T-149-08..10 | Diagnostics route facts derive from compiled router metadata, not user params or prose-only labels | unit | `cd examples/phoenix_host && mix test --only diagnostics_route_rows test/crosswake_example/saas_portal/diagnostics_test.exs` | Wave 0 creates | complete |
| 149-03-02 | 03 | 1 | SAAS-03 | T-149-08..10 | Support labels, rough edges, and guide links stay allowlisted and lane-local without adding an inspector route | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/showcase/catalog_test.exs` | Wave 0 creates | complete |
| 149-04-01 | 04 | 2 | SAAS-04 | T-149-11..14 | Approval/activity schemas persist only mutable proof evidence with changeset validation and safe metadata | unit/migration | `cd examples/phoenix_host && mix ecto.migrate --quiet && mix test --only approval_schema_persistence test/crosswake_example/saas_portal/approvals_test.exs` | Wave 0 creates | complete |
| 149-04-02 | 04 | 2 | SAAS-01, SAAS-04 | T-149-11..14 | Approval authorization uses server-owned current user/account state and reset reseeds persisted evidence idempotently | unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/showcase/reset_test.exs` | Wave 0 creates | complete |
| 149-05-01 | 05 | 3 | SAAS-02, SAAS-03 | T-149-15..18 | Components render route/support truth from diagnostics data without leaking sensitive details or creating dashboard scope | render/unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/diagnostics_test.exs` | Wave 0 creates | complete |
| 149-05-02 | 05 | 3 | SAAS-01, SAAS-02, SAAS-03 | T-149-15..18 | AdminPilot pages render product context, posture, and denial proof while keeping auth/session authority backend-owned | render/unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/page_title_test.exs` | Wave 0 creates plus existing page-title test | complete |
| 149-06-01 | 06 | 4 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | T-149-19..22 | Approval queue renders persisted approvals and support truth without exposing broad CRUD or native authority | liveview | `cd examples/phoenix_host && mix test --only approval_queue_live test/crosswake_example/saas_portal/approvals_live_test.exs` | Wave 0 creates | complete |
| 149-06-02 | 06 | 4 | SAAS-04 | T-149-19..22 | Approval detail mutates only through the server context, persists success, and emits optional haptics after success only | liveview/unit | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs` | Wave 0 creates | complete |
| 149-07-01 | 07 | 5 | SAAS-04 | T-149-23..26 | E2E session helper is compile-time gated, fixture allowlisted, and cannot become production auth/provider MFA | unit | `cd examples/phoenix_host && mix test test/crosswake_example/e2e/saas_session_controller_test.exs test/crosswake_example/router_test.exs` | New controller test | complete |
| 149-07-02 | 07 | 5 | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | T-149-23..26 | Browser proof observes product flow and support truth after full ExUnit passes, preserving semantic assertions before screenshots | unit/browser | `cd examples/phoenix_host && mix test test/crosswake_example/saas_portal/fixtures_test.exs test/crosswake_example/saas_portal/diagnostics_test.exs test/crosswake_example/saas_portal/approvals_test.exs test/crosswake_example/saas_portal/approvals_live_test.exs test/crosswake_example/e2e/saas_session_controller_test.exs`<br>`cd examples/phoenix_host && mix test`<br>`cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` | Wave 0 plus e2e helper | complete |

---

## Wave 0 Requirements

- [x] `examples/phoenix_host/test/crosswake_example/saas_portal/fixtures_test.exs` - covers SAAS-01 fixture density and reset digest components.
- [x] `examples/phoenix_host/test/crosswake_example/saas_portal/diagnostics_test.exs` - covers SAAS-02 and SAAS-03 route metadata drift and support truth.
- [x] `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_test.exs` - covers SAAS-04 context authorization and optional approval/activity persistence.
- [x] `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` - covers SAAS-04 LiveView action states.
- [x] `examples/phoenix_host/e2e/route_tour.spec.ts` - extend existing route tour to click `dashboard -> approvals -> detail -> approve -> diagnostics`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Desktop/mobile visual containment across light, dark, system, reduced motion, and focus states | SAAS-01, SAAS-02, SAAS-03, SAAS-04 | Browser route tour can prove semantic flow, but responsive clipping/focus quality still needs screenshot review unless a visual audit is added | Run the route tour locally, then inspect desktop and mobile screenshots for no horizontal overflow, no clipped badges/actions, visible focus, and readable contrast |

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing test references.
- [x] No watch-mode flags in verification commands.
- [x] Feedback latency remains under the command budget above.
- [x] Set `nyquist_compliant: true` in frontmatter after Wave 0 tests exist and pass.

**Approval: approved**
