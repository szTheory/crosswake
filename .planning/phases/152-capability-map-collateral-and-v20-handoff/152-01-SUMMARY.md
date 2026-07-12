---
phase: 152-capability-map-collateral-and-v20-handoff
plan: 01
subsystem: testing
tags: [capability-map, support-truth, evidence-manifest, docs-guardrails, red-contracts]
requires: []
provides:
  - RED capability-map data contracts for typed v19/v20 support truth
  - RED capability-map renderer and guide parity contracts
  - RED public-claim scanner and generalized evidence-manifest schema contracts
affects: [capability-map, route-tour-proof, v20-handoff, support-truth]
tech-stack:
  added: []
  patterns: [typed-support-truth-tests, renderer-parity-tests, forbidden-claim-scanner, evidence-manifest-schema]
key-files:
  created:
    - test/crosswake/capability_map/capability_map_test.exs
    - test/crosswake/capability_map/renderer_test.exs
    - test/crosswake/guides/capability_claims_test.exs
  modified:
    - test/crosswake/guides/evidence_manifest_test.exs
key-decisions:
  - "Wave 0 remains intentionally RED: production capability-map modules, rendered guide, and generalized manifest rows are deferred to dependent plans."
  - "Evidence manifest proof posture, support label, package owner, capability posture, limitations, and retention are separate fields."
patterns-established:
  - "Capability-map tests normalize structs or maps so implementation can use a typed Row struct without changing contract intent."
  - "Public claim scanning accepts explicit non-claim copy while blocking broad native, offline, commerce, plugin, entitlement, and screenshot-proof overclaims."
requirements-completed:
  - CAPMAP-01
  - CAPMAP-02
  - CAPMAP-03
  - CAPMAP-04
  - PROOF-02
  - PROOF-03
  - PROOF-04
duration: 10 min
completed: 2026-07-12
status: complete
---

# Phase 152 Plan 01: Wave 0 Capability Map Contracts Summary

**RED ExUnit contracts now pin typed capability truth, rendered-guide parity, public overclaim scanning, and generalized v19 route-tour evidence before implementation.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-12T15:19:30Z
- **Completed:** 2026-07-12T15:29:21Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added RED `Crosswake.CapabilityMap` contracts for exact vocabularies, canonical row fields, v19 evidence coverage, v20 pressure, and conservative package/proof ownership.
- Added RED `Crosswake.CapabilityMap.Renderer` contracts for deterministic Markdown rendering, write semantics, byte-identical `guides/capability_map.md` parity, UI-SPEC table order, and markdown escaping.
- Added public-claim scanner coverage and expanded evidence-manifest schema expectations so unsupported native/offline/commerce/plugin/screenshot claims and incomplete route evidence fail structurally.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create RED capability-map data contracts** - `e43a0601` (test)
2. **Task 2: Create RED renderer and guide parity contracts** - `3c3f47ea` (test)
3. **Task 3: Create RED claim scanner and generalized manifest schema contracts** - `605dca03` (test)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `test/crosswake/capability_map/capability_map_test.exs` - RED typed capability-map data contract.
- `test/crosswake/capability_map/renderer_test.exs` - RED capability guide renderer and parity contract.
- `test/crosswake/guides/capability_claims_test.exs` - RED public support-truth claim scanner.
- `test/crosswake/guides/evidence_manifest_test.exs` - generalized v19 evidence-manifest schema expectations.

## Decisions Made

- The Wave 0 contract intentionally allows maps or structs for capability rows so Plan 152-02 can choose the local Elixir shape while preserving the field contract.
- Manifest vocabulary now separates proof posture, support label, capability posture, package owner, known limitations, retention, and unavailable reasons.
- Scanner negation handling permits existing "what this is not" and backend-projection authority language while still catching synthetic overclaims.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep; no production modules, docs guide, native control API, provider integration, storage/sync productization, dashboard, or plugin catalog was added.

## Issues Encountered

The initial claim scanner matched a few existing non-claim lines in README/offline/commerce docs. The scanner was tightened before commit so it still catches synthetic broad claims while accepting explicit negated or backend-authoritative copy.

## Verification

- `mix test test/crosswake/capability_map/capability_map_test.exs` — RED passed: fails on missing `Crosswake.CapabilityMap`.
- `mix test test/crosswake/capability_map/renderer_test.exs` — RED passed: fails on missing `Crosswake.CapabilityMap.Renderer`.
- `mix test test/crosswake/guides/capability_claims_test.exs test/crosswake/guides/evidence_manifest_test.exs` — RED passed: fails on missing capability guide/module and old manifest route/label schema.
- Combined plan verification command — RED passed: 23 tests run, failing for missing planned implementation/docs/evidence, not syntax or option errors.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 152-02 can implement `Crosswake.CapabilityMap`, `Crosswake.CapabilityMap.Renderer`, `guides/capability_map.md`, and ExDoc registration against the RED contracts. Plan 152-03 can then generalize route-tour evidence and update the committed evidence manifest.

---
*Phase: 152-capability-map-collateral-and-v20-handoff*
*Completed: 2026-07-12*
