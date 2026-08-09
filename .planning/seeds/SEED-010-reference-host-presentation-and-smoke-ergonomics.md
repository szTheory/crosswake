---
id: SEED-010
status: dormant
planted: 2026-08-08
planted_during: v21.0 / Phase 162 external gate
trigger_when: when improving the checked-in iOS Simulator rehearsal or its automated smoke coverage
scope: medium
---

# SEED-010: Reference-host presentation and smoke-test ergonomics

## Why This Matters

The reference study flow should look intentional and pseudo-realistic when opened in
Simulator, while remaining clearly a reference host rather than product brand work. A clearer
visual hierarchy and compact state layout will make it more pleasant to inspect and let AI or
automated smoke checks reach the important states without excessive scrolling.

## When to Surface

**Trigger:** when improving the checked-in iOS Simulator rehearsal or its automated smoke coverage.

Surface alongside a reference-host/rehearsal improvement, not during physical-device proof
promotion. It must not delay Phase 162's real-host/iPhone gate.

## Scope Estimate

**Medium** — one bounded reference-host presentation pass plus focused accessibility and
viewport-sized smoke assertions.

## Breadcrumbs

- `bin/crosswake-ios-rehearsal` opens the reference study route in Simulator.
- `examples/phoenix_host/lib/crosswake_example_web/controllers/learn_loop_study_html/index.html.heex`
  owns the visible offline-study surface.
- `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` and
  `examples/phoenix_host/e2e/support/offline_route_proof.ts` are the existing behavioral proof.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` and `AGENTS.md` preserve the stop list: no brand/showcase
  polish, generic UI framework, or new product surface.

## Notes

- Improve typography, spacing, hierarchy, status treatment, and the first viewport only where it
  supports comprehension and testability.
- Prefer semantic accessibility identifiers and compact test fixtures over scroll-heavy visual
  automation.
- Preserve truthful learner copy and the existing offline/replay authority boundaries.
- Do not add a generic design system, native rendering breadth, screenshots/video retention, or
  customer-specific styling.
