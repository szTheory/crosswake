---
phase: 150
slug: field-service-showcase
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-11
---

# Phase 150 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix plus Playwright 1.60.0 for browser proof |
| **Config file** | `examples/phoenix_host/test/test_helper.exs`; `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `cd examples/phoenix_host && mix test test/crosswake_example/field_service test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs` |
| **Full suite command** | `cd examples/phoenix_host && mix test` |
| **Browser proof command** | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` |
| **Estimated runtime** | Focused ExUnit ~30s; full ExUnit + route tour depends on browser startup |

---

## Sampling Rate

- **After every task commit:** Run the focused Fieldserv ExUnit file(s) touched by that task.
- **After reset/catalog/router changes:** Also run `cd examples/phoenix_host && mix test test/crosswake_example/showcase/catalog_test.exs test/crosswake_example/showcase/reset_test.exs`.
- **After every plan wave:** Run `cd examples/phoenix_host && mix test`.
- **Before `/gsd:verify-work`:** Run `cd examples/phoenix_host && mix test` and `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts`.
- **Max feedback latency:** Keep task-level feedback under 60 seconds where possible by using focused ExUnit files before full-suite gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 150-W0-01 | Wave 0 contracts | 0 | FIELD-01 | T-150-01 / T-150-06 | Fieldserv fixture breadth renders jobs, assets, inspections, notes, evidence, and technician state without mobile overflow | unit/render | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/fixtures_test.exs test/crosswake_example/field_service/*_live_test.exs` | no - W0 creates | pending |
| 150-W0-02 | Wave 0 contracts | 0 | FIELD-02 | T-150-02 / T-150-04 | Capture/scanner/permission pressure is labeled as native runtime or future gap; no camera/scanner bridge command is implied | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/field_service/*_live_test.exs` | no - W0 creates | pending |
| 150-W0-03 | Wave 0 contracts | 0 | FIELD-03 | T-150-05 | Offline/degraded posture is cached read-only and contains no shipped local-first, journal, outbox, replay, saved-locally, or queued-for-sync claims | unit/render/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/*_live_test.exs && npx playwright test e2e/route_tour.spec.ts --grep Fieldserv` | no - W0 creates | pending |
| 150-W0-04 | Wave 0 contracts | 0 | FIELD-04 | T-150-01 | Route owner/support labels match compiled router metadata for LiveView, native-screen, and future offline-island pressure | unit/browser | `cd examples/phoenix_host && mix test test/crosswake_example/field_service/diagnostics_test.exs test/crosswake_example/showcase/catalog_test.exs` | no - W0 creates | pending |
| 150-W0-05 | Wave 0 contracts | 0 | FIELD-01, FIELD-02, FIELD-03, FIELD-04 | T-150-03 / T-150-05 | Reset and route-tour proof stay semantic-first and deterministic; screenshots are collateral after assertions pass | unit/browser | `cd examples/phoenix_host && mix test test/crosswake_example/showcase/reset_test.exs && npx playwright test e2e/route_tour.spec.ts --grep Fieldserv` | partial - W0 extends | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/test/crosswake_example/field_service/fixtures_test.exs` - fixture density, stable IDs, realistic jobs/assets/inspection/evidence/technician state, and digest components.
- [ ] `examples/phoenix_host/test/crosswake_example/field_service/jobs_test.exs` - context lookup, state transitions, missing job behavior, and server-owned workflow actions.
- [ ] `examples/phoenix_host/test/crosswake_example/field_service/evidence_test.exs` - evidence status ladder, backend-verification authority, and optional `Ecto.Multi` transaction behavior.
- [ ] `examples/phoenix_host/test/crosswake_example/field_service/diagnostics_test.exs` - compiled route metadata drift, support-label allowlists, native-screen/cached-read-only truth, and future-gap labels.
- [ ] `examples/phoenix_host/test/crosswake_example/field_service/components_test.exs` - scoped CSS selectors, focus rules, reduced-motion CSS, 44px action targets, and prohibited copy.
- [ ] `examples/phoenix_host/test/crosswake_example/field_service/*_live_test.exs` - page rendering, click path, native capture fallback, evidence review, and no-overclaiming copy.
- [ ] `examples/phoenix_host/e2e/route_tour.spec.ts` - Fieldserv happy path, mobile, dark/system theme, reduced motion, focus, overflow, route-owner truth, and screenshots after semantic assertions.
- [ ] `examples/phoenix_host/e2e/support/evidence_manifest.ts` - Fieldserv capability-map evidence for capture, scanner, document scan, permissions, media upload, offline inspection, and native rebuild pressure.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual polish of dense Fieldserv operational UI | FIELD-01, FIELD-04 | Automated tests catch semantics, overflow, and focus, but final visual density still needs maintainer review | Review desktop and mobile route-tour screenshots after semantic assertions pass. Confirm job context, support truth, and capture/offline pressure are visible without marketing-page layout. |

---

## Threat References

| Threat | Risk | Expected Control |
|--------|------|------------------|
| T-150-01 | Route metadata drift makes capture look browser-owned | Diagnostics derive from compiled router metadata and tests assert runtime/offline/security/capability declarations. |
| T-150-02 | Capture/scanner support is implied as shipped bridge or web support | Tests reject camera/scanner bridge-command copy and require native-runtime/future-gap labels. |
| T-150-03 | Evidence appears available before backend verification | Evidence review uses a closed status ladder and backend verification copy before availability. |
| T-150-04 | Permission support is broadened beyond current notifications-only truth | Fieldserv copy keeps camera permission inside native capture/future-gap surfaces. |
| T-150-05 | Cached read-only posture is mistaken for local-first mutation | Tests reject local-first, journal, outbox, replay, saved-locally, and queued-for-sync wording outside explicit future-not-shipped explanations. |
| T-150-06 | Dense operational UI clips support truth on mobile | Playwright checks no horizontal overflow, visible focus, reduced motion, and unclipped action/status areas. |

---

## Validation Sign-Off

- [x] All phase requirements have planned automated verification coverage.
- [x] Wave 0 covers all currently missing Fieldserv test files.
- [x] No watch-mode flags are required.
- [x] Feedback latency target is under 60 seconds for task-level focused ExUnit.
- [x] `nyquist_compliant: true` set in frontmatter.
- [ ] Wave 0 tests have been implemented and are red before production Fieldserv work.

**Approval:** pending Wave 0 implementation
