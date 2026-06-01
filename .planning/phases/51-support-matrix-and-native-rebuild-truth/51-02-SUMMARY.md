---
phase: 51-support-matrix-and-native-rebuild-truth
plan: "02"
subsystem: docs
tags: [support-matrix, rebuild-guidance, promotion-rules, release-boundaries]
requires:
  - phase: 51-support-matrix-and-native-rebuild-truth
    provides: typed action classes and promotion rules
provides:
  - generated support-matrix action-class section
  - generated support-matrix promotion-rule section
  - public non-claim guidance for deferred v3.6 surfaces
affects: [support_matrix, install-guide, native-shell-guide, compatibility-guide]
tech-stack:
  added: []
  patterns: [generated docs from canonical support truth, guide release-boundary locks]
key-files:
  created: []
  modified:
    - lib/crosswake/support_matrix/renderer.ex
    - guides/support_matrix.md
    - guides/install.md
    - guides/native_shell.md
    - guides/compatibility.md
    - test/crosswake/support_matrix/renderer_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
key-decisions:
  - "Public docs name deferred StoreKit, Play Billing, Sigra, notification delivery, and shell package claims explicitly."
  - "Rebuild guidance links to canonical action classes and promotion rules instead of repeating an independent taxonomy."
patterns-established:
  - "Renderer-owned support guide sections consume Crosswake.SupportMatrix accessors directly."
  - "Guide tests lock deferred-scope wording and support-matrix byte identity."
requirements-completed: [SUPP-02]
duration: 12min
completed: 2026-06-01
---

# Phase 51-02: Support Guide Rendering Summary

**Public support docs now render canonical action classes, promotion rules, rebuild guidance, and explicit v3.6 non-claims.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-06-01T15:47:46Z
- **Completed:** 2026-06-01T15:50:17Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Extended `Crosswake.SupportMatrix.Renderer` with deterministic Action Classes, Promotion Rules, and Public Non-Claims sections.
- Regenerated `guides/support_matrix.md` from the canonical renderer.
- Updated install, native shell, and compatibility guides with direct rebuild answers, promotion-rule links, and deferred-scope language.

## Task Commits

1. **Task 1: Add failing docs-contract tests** - `49767d4` (test)
2. **Task 2: Render canonical rebuild and promotion truth** - `3b3e11b` (feat)

## Files Created/Modified

- `lib/crosswake/support_matrix/renderer.ex` - Renders action classes, promotion rules, and public non-claims.
- `guides/support_matrix.md` - Generated support truth output.
- `guides/install.md` - Adds rebuild and promotion links plus deferred non-claims.
- `guides/native_shell.md` - Adds rebuild and promotion links plus deferred non-claims.
- `guides/compatibility.md` - Adds rebuild and promotion links plus compatibility-window distinction.
- `test/crosswake/support_matrix/renderer_test.exs` - Locks generated sections and byte identity.
- `test/crosswake/guides/release_boundaries_test.exs` - Locks guide cross-links and non-claim wording.

## Decisions Made

- Updated older “do not mention StoreKit/Play Billing” expectations to require explicit “not shipped in v3.6” wording.
- Kept docs narrow: provider adapter proof remains advisory and notification-token readiness is provider-snapshot only.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

One source test needed case-exact wording for `compatibility-window narrowing`; guide copy was adjusted to match the locked phrase.

## Verification

- `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/guides/release_boundaries_test.exs` - 13 tests, 0 failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 51-03 can now surface the same action-class and promotion-rule identifiers in operator inspection and publish-readiness diagnostics.

---
*Phase: 51-support-matrix-and-native-rebuild-truth*
*Completed: 2026-06-01*
