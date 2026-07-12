---
phase: 151
slug: subscription-learning-showcase
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-11
---

# Phase 151 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Closeout Refresh

This closeout refresh file was refreshed during Phase 152.1 on 2026-07-12 to reflect the current verified closeout state from `151-VERIFICATION.md`. The refresh updates stale planning-time Wave 0 and approval metadata after the phase had already passed verification; it does not claim this metadata was historically accurate during every execution step.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix.LiveViewTest, Playwright |
| **Config file** | `examples/phoenix_host/test/test_helper.exs`, `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs test/crosswake_example/flashcards_test.exs` |
| **Full suite command** | `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts e2e/offline_sync.spec.ts` |
| **Estimated runtime** | ~120 seconds quick, ~8-12 minutes full including browser proof |

---

## Sampling Rate

- **After every task commit:** Run the task-local ExUnit file or Playwright spec named in the PLAN.md `<verify>` block.
- **After every plan wave:** Run `cd examples/phoenix_host && mix test`.
- **Before `/gsd:verify-work`:** Run `cd examples/phoenix_host && mix test && npx playwright test e2e/route_tour.spec.ts e2e/offline_sync.spec.ts`.
- **Max feedback latency:** 12 minutes for the browser-backed full proof; under 3 minutes for ExUnit-only tasks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 151-W0-01 | 01 | 0 | LEARN-01 | T-151-01 | Product routes expose realistic learner/course/pack/progress data without broad LMS persistence | ExUnit/LiveViewTest | `cd examples/phoenix_host && mix test test/crosswake_example/learn_loop_test.exs test/crosswake_example/learn_loop/*_test.exs` | yes | complete |
| 151-W0-02 | 01 | 0 | LEARN-02 | T-151-02 | Socketless study island queues browser-owned review events and syncs through idempotent replay | Playwright + ExUnit | `cd examples/phoenix_host && npx playwright test e2e/learnloop_route_tour.spec.ts --grep @learnloop-offline` | yes | complete |
| 151-W0-03 | 01 | 0 | LEARN-03 | T-151-03 | Entitlement/paywall copy remains backend-owned or mocked and fail-closed | ExUnit/LiveViewTest | `cd examples/phoenix_host && mix test test/crosswake_example/learn_loop/entitlement_test.exs test/crosswake_example/learn_loop/subscription_live_test.exs` | yes | complete |
| 151-W0-04 | 01 | 0 | LEARN-04 | T-151-04 | Route tour connects hub, LiveView shell, offline island, reconnect sync, history, and support truth before screenshots | Playwright | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts --grep @learnloop` | yes | complete |

*Status: complete after closeout refresh; historical row status was pre-execution planning state.*

---

## Wave 0 Requirements

- [x] `examples/phoenix_host/test/crosswake_example/learn_loop_test.exs` — fixture density, route posture, reset digest, and support-label contracts for LEARN-01.
- [x] `examples/phoenix_host/test/crosswake_example/learn_loop/entitlement_test.exs` — backend-owned mocked entitlement projection and no live storefront-copy contracts for LEARN-03.
- [x] `examples/phoenix_host/test/crosswake_example/learn_loop/*_live_test.exs` — LiveView-owned dashboard/course/pack/subscription/history shell contracts for LEARN-01 and LEARN-04.
- [x] `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` or tagged additions to `examples/phoenix_host/e2e/route_tour.spec.ts` — semantic-first LearnLoop route-tour proof for LEARN-02 and LEARN-04.
- [x] Existing `examples/phoenix_host/e2e/offline_sync.spec.ts` helpers remain reusable and must not be weakened.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | LEARN-01..04 | Phase 151 can be covered by ExUnit, LiveViewTest, and Playwright route-tour proof | All phase behaviors have automated verification. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 12 minutes
- [x] `nyquist_compliant: true` set in frontmatter

**Approval: approved**
