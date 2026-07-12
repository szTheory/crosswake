---
phase: 152-capability-map-collateral-and-v20-handoff
plan: 02
subsystem: docs
tags: [capability-map, renderer, exdoc, support-truth, v20-handoff]
requires:
  - phase: 152-capability-map-collateral-and-v20-handoff
    provides: 152-01 RED capability-map and renderer contracts
provides:
  - Typed Crosswake.CapabilityMap source of truth
  - Deterministic Crosswake.CapabilityMap.Renderer output
  - Generated guides/capability_map.md adopter guide
  - ExDoc registration under Truth extras
affects: [capability-map, exdoc, support-truth, v20-handoff]
tech-stack:
  added: []
  patterns: [typed-support-truth, deterministic-markdown-renderer, exdoc-truth-extra]
key-files:
  created:
    - lib/crosswake/capability_map.ex
    - lib/crosswake/capability_map/renderer.ex
    - guides/capability_map.md
  modified:
    - mix.exs
key-decisions:
  - "Capability truth lives in a typed Elixir module and renders to Markdown; the checked-in guide is generated, not hand-authored."
  - "Capability rows separate category, display label, route runtime owner, package owner, proof posture, fallback behavior, and v20 implication."
patterns-established:
  - "CapabilityMap.Row mirrors the support-matrix truth pattern while staying phase-scoped and narrow."
  - "Renderer.write/1 and write/2 preserve created/reused/updated semantics for regeneration checks."
requirements-completed:
  - CAPMAP-01
  - CAPMAP-02
  - CAPMAP-03
  - CAPMAP-04
  - PROOF-03
  - PROOF-04
duration: 5 min
completed: 2026-07-12
status: complete
---

# Phase 152 Plan 02: Typed Capability Map Summary

**Typed capability-map truth with deterministic generated guide and ExDoc Truth registration.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-12T15:29:30Z
- **Completed:** 2026-07-12T15:34:20Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `Crosswake.CapabilityMap` with exact vocabularies and stable canonical rows for shipped support, proof-backed examples, demo pressure, future gaps, deferred work, and v20 next-pack candidates.
- Added `Crosswake.CapabilityMap.Renderer` plus generated `guides/capability_map.md`, including reader-first sections and detailed support-truth rows.
- Registered the generated guide in ExDoc extras and the `Truth` group without adding dependencies or broad native-control implementation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement typed capability-map canonical data** - `d6ce8610` (feat)
2. **Task 2: Implement renderer and render the capability guide** - `963ef37b` (feat)
3. **Task 3: Register the guide in ExDoc and run focused capability tests** - `70a6f011` (docs)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `lib/crosswake/capability_map.ex` - typed capability-map vocabularies and canonical rows.
- `lib/crosswake/capability_map/renderer.ex` - deterministic Markdown renderer and write helpers.
- `guides/capability_map.md` - generated adopter-facing capability map.
- `mix.exs` - ExDoc extras and Truth group registration.

## Decisions Made

- `deep-link-activation` is represented as `:native_shell` ownership because activation is shell-owned but still governed by Crosswake route policy.
- `permissions.status` and `notification-token` remain read-only/evidence surfaces; provider delivery and permission-request sprawl are not claimed.
- LearnLoop offline proof is `example/docs-only` and proof-backed, but native storage/sync productization remains deferred.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** The plan stayed within docs/support-truth scope; no native-control APIs, commerce providers, storage/sync productization, dashboard, schema, or plugin catalog were introduced.

## Issues Encountered

One capability row initially used the banned phrase `subscriber truth` in a negated fallback sentence. The row was corrected to say device/storefront evidence never grants access, satisfying the RED support-truth contract.

## Verification

- `mix test test/crosswake/capability_map/capability_map_test.exs` — passed.
- `mix test test/crosswake/capability_map/renderer_test.exs` — passed.
- `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/capability_map/renderer_test.exs` — passed, 10 tests.
- `mix format --check-formatted lib/crosswake/capability_map.ex lib/crosswake/capability_map/renderer.ex mix.exs` — passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 152-03 can generalize the route-tour evidence manifest and update proof/collateral metadata against the typed map and generated guide.

---
*Phase: 152-capability-map-collateral-and-v20-handoff*
*Completed: 2026-07-12*
