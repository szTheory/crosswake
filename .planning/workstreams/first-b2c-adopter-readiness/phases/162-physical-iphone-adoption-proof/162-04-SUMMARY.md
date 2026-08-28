---
phase: 162-physical-iphone-adoption-proof
plan: "04"
subsystem: learner-status-ui
tags: [phoenix, offline-island, indexeddb, playwright, xcuittest, accessibility]
requires:
  - phase: 162-03
    provides: host-owned physical iPhone observation and adapter boundary
provides:
  - closed learner-facing local-save, replay, review, and paused status surface
  - validated host-only recovery entry point with retained work
  - browser and generated XCUITest accessibility/backstop contracts
affects: [162-05, physical-device-evidence, offline-study]
tech-stack:
  added: []
  patterns: [closed status presentation mapping, host-validated recovery destination, focus-preserving status announcement]
key-files:
  created: []
  modified:
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/e2e/offline_sync.spec.ts
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
key-decisions:
  - "Learner status is a closed four-state presentation and never renders replay or account mechanics."
  - "Recovery navigation is created only from a same-origin host-supplied destination; the status row never contains record detail."
  - "The original proof corpus retains an aria-hidden status fixture while learner-visible content uses only the new semantic row."
patterns-established:
  - "Status transitions emit one semantic effect with preserveFocus instead of moving learner focus."
  - "Host-adapter XCUITests own physical backstops and remain unavailable until a real status adapter is supplied."
requirements-completed: [DEVICE-03, DEVICE-04, DEVICE-05]
coverage:
  - id: D1
    description: Closed status mapping retains offline work and exposes recovery only through a validated host destination.
    requirement: DEVICE-03
    verification:
      - kind: e2e
        ref: "examples/phoenix_host: npm run proof:offline-island -- --grep study status|recovery|account switch|feature disablement"
        status: pass
      - kind: unit
        ref: "mix test test/crosswake/offline/status_test.exs --max-failures 1"
        status: pass
    human_judgment: false
  - id: D2
    description: Physical-driver accessibility contract covers XXXL wrapping, recovery hit targets, appearance, motion, and announcement/focus semantics.
    requirement: DEVICE-04
    verification:
      - kind: automated_ui
        ref: "bash script/verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter"
        status: pass
      - kind: unit
        ref: "mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1"
        status: pass
    human_judgment: false
  - id: D3
    description: Existing browser proof remains compatible without exposing its legacy status fixture to learners or assistive technology.
    requirement: DEVICE-05
    verification:
      - kind: e2e
        ref: "examples/phoenix_host: npm run proof:offline-island"
        status: pass
    human_judgment: false
metrics:
  duration: 45min
  completed: 2026-08-04
status: complete
---

# Phase 162 Plan 04: Learner Recovery Surface Summary

**Closed in-flow learner status for locally saved, replaying, retained-review, and safely paused study work, with host-gated recovery and physical-driver accessibility contracts.**

## Performance

- **Duration:** 45 min
- **Completed:** 2026-08-04T21:49:37Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Replaced free-form learner status strings with the D-07 four-state presenter, exact approved copy, semantic identifiers, reduced-motion-safe active indicator, and focus-preserving announcement effect.
- Kept rejected work retained and rendered the visible recovery action only after same-origin host destination validation; no backend reason, retry, deletion, or account detail enters learner UI.
- Added Playwright coverage plus generated XCUITest contracts for Dynamic Type, 44pt recovery reachability, appearance, motion, status semantics, and announcement/focus behavior.

## Task Commits

1. **Task 1: Render the four-state in-flow study status and recovery contract** — `52ece0ac` (`test` RED), `032515b0` (`feat`)
2. **Task 2: Prove accessibility, layout, motion, and focus through the physical driver** — `a4c624d3` (`test`)
3. **Compatibility correction** — `0a975abd` (`fix`)

## Files Created/Modified

- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` — semantic in-flow status row, token-only styling, and hidden proof-fixture mirror.
- `examples/phoenix_host/priv/static/offline_study.js` — closed status mapping, safe destination validation, announcement effect, and retained-work lifecycle behavior.
- `examples/phoenix_host/e2e/offline_sync.spec.ts` — state, retention, CTA, focus, and announcement contract coverage.
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` — host-adapter physical accessibility/backstop assertions.

## Decisions Made

- The four learner states are the only presentation vocabulary; the card position remains outside the status row.
- Verified pack availability remains outside this status surface and is never inferred from replay state.
- Generated physical assertions use fixed UI semantics and do not retain screenshots, accessibility trees, or sensitive output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Preserved the existing host proof status fixture**
- **Found during:** Final browser proof verification
- **Issue:** The established generated browser corpus uses `#status`; removing it broke its host-reusable proof contract.
- **Fix:** Added an `aria-hidden`, `hidden` compatibility mirror for only the existing proof fixture while keeping all learner-visible status content in `#crosswake-study-status`.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex`, `examples/phoenix_host/priv/static/offline_study.js`
- **Verification:** `npm run proof:offline-island` passes; the learner-facing status tests remain green.
- **Committed in:** `0a975abd`

---

**Total deviations:** 1 auto-fixed (1 Rule 2 compatibility correction).
**Impact on plan:** Preserves the required existing browser-proof fixture without adding a learner-visible technical surface.

## Issues Encountered

None unresolved. The generated physical status assertions intentionally execute only when a real host study-status adapter is supplied; absent adapters remain unavailable and non-promoting.

## Known Stubs

None. The absent host study-status adapter is an intentional fail-closed integration seam, not a passing proof result.

## Next Phase Readiness

- Plan 162-05 can consume the closed learner-visible state and host-adapter assertion vocabulary without treating UI state as Phoenix authority.
- A physical-device promotion still requires the separate validated route, signed host, and real adapter prerequisites from Plans 162-01 through 162-03.

## Self-Check: PASSED

- All four declared implementation artifacts exist.
- Commits `52ece0ac`, `032515b0`, `a4c624d3`, and `0a975abd` exist in Git history.

---
*Phase: 162-physical-iphone-adoption-proof*
*Completed: 2026-08-04*
