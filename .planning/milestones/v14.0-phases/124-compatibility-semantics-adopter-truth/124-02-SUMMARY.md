---
phase: 124-compatibility-semantics-adopter-truth
plan: "02"
subsystem: docs
tags: [support-matrix, rebuild-decision-table, renderer, byte-parity, change-class]

requires:
  - phase: 124-01
    provides: floor semantics for version axes; native SemVer helpers
  - phase: 122-drift-guards
    provides: phase52 byte-parity guard pattern (assert_file_exact)

provides:
  - Crosswake.SupportMatrix.rebuild_decision_table/0 — canonical axis→change-kind→rebuild-class table (11 rows, D-09 mapping)
  - Crosswake.Manifest.Types.RebuildDecisionEntry struct and new_rebuild_decision_entry/1 constructor
  - rebuild_decision_table_section/1 and rebuild_decision_table_row/1 in renderer.ex
  - guides/support_matrix.md with new "## Rebuild Decision Table" section right after "## Change Classes"
  - Phase52 assert_contains_exact guard for section presence (merge-blocking)

affects:
  - 124-03 (compatibility.md guide JTBD table consumes rebuild_decision_table/0)
  - 124-04 (doctor action-sequence check derives from change_class_entries/adopter_action)
  - 124-05 (changelog label vocabulary references the 4 verbatim strings)

tech-stack:
  added: []
  patterns:
    - RebuildDecisionEntry follows ChangeClassEntry pattern (struct + Types constructor + public SupportMatrix accessor)
    - rebuild_decision_table/0 is a public function (not defp) called directly by renderer (like action_classes())
    - Section inserted into render/1 list immediately after change_class_section; auto-covered by existing byte-parity guard
    - Rebuild-class strings reused verbatim from change_class_entries/0 taxonomy — no minted synonyms

key-files:
  created: []
  modified:
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/support_matrix/renderer.ex
    - guides/support_matrix.md
    - test/crosswake/proof/phase52_operator_truth_test.exs

key-decisions:
  - "rebuild_decision_table/0 is a public def (not defp) so the renderer can call it directly — mirrors action_classes() pattern, not the struct-field pattern"
  - "native_runtime_version additive row maps to native or companion rebuild required (no compat-bump-only row) — D-09 asymmetry: native lives in the binary, floor semantics do not help"
  - "manifest_schema_version and bridge_protocol_version additive rows map to compatibility-bump only — enabled by D-01/D-02 floor semantics making older shells still compatible"
  - "RebuildDecisionEntry added to types.ex after ChangeClassEntry; constructor follows new_change_class_entry/1 pattern"
  - "Phase52 section-presence assert added (assert_contains_exact) — byte-parity guard already covers drift; section assert makes the invariant explicit"

patterns-established:
  - "Renderer calls rebuild_decision_table/0 directly (not via SupportMatrix struct field) — preserves struct backward compat"
  - "Regen idempotent: running mix run -e File.write!(guides/support_matrix.md ...) twice leaves file unchanged"

requirements-completed: [COMPAT-02]

duration: 4min
completed: 2026-06-20
status: complete
---

# Phase 124 Plan 02: Rebuild Decision Table Summary

**Canonical axis-to-rebuild-class decision table in rebuild_decision_table/0 (11 rows, D-09 mapping), rendered into guides/support_matrix.md and locked by the existing phase52 byte-parity merge-blocking guard**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-06-20T22:35:37Z
- **Completed:** 2026-06-20T22:39:33Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `RebuildDecisionEntry` module to `Crosswake.Manifest.Types` with `axis`, `change_kind`, `rebuild_class`, `adopter_action`, `denial_signal`, `guide_anchor` fields plus `new_rebuild_decision_entry/1` constructor
- Added public `rebuild_decision_table/0` to `Crosswake.SupportMatrix` encoding the full D-09 axis mapping (11 rows) with all 4 verbatim rebuild-class strings — native_runtime_version additive asymmetry encoded and documented
- Added `rebuild_decision_table_section/1` and `rebuild_decision_table_row/1` to renderer.ex; inserted section in `render/1` immediately after `change_class_section` so the guide section appears right after `## Change Classes`
- Regenerated `guides/support_matrix.md` with the new `## Rebuild Decision Table` section; regen confirmed idempotent
- Extended phase52 with `assert_contains_exact` for `## Rebuild Decision Table` presence; all 6 phase52 tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Add canonical rebuild_decision_table/0 + RebuildDecisionEntry** - `eddca30` (feat)
2. **Task 2: Render rebuild decision table section + lock with phase52** - `59c0b53` (feat)

## Files Created/Modified

- `lib/crosswake/manifest/types.ex` — Added RebuildDecisionEntry struct + new_rebuild_decision_entry/1 constructor
- `lib/crosswake/support_matrix/support_matrix.ex` — Added RebuildDecisionEntry alias + rebuild_decision_table/0 public function (11 rows, D-09 mapping)
- `lib/crosswake/support_matrix/renderer.ex` — Added RebuildDecisionEntry alias, rebuild_decision_table_section/1, rebuild_decision_table_row/1, and section call in render/1
- `guides/support_matrix.md` — Regenerated with new ## Rebuild Decision Table section after ## Change Classes
- `test/crosswake/proof/phase52_operator_truth_test.exs` — Added assert_contains_exact for ## Rebuild Decision Table presence

## Decisions Made

- `rebuild_decision_table/0` is `def` not `defp` — the renderer needs to call it from outside the module; follows the `action_classes()` pattern (direct call) not the `change_classes()` pattern (struct field access). This preserves the `SupportMatrix.t()` struct's backward compatibility.
- The `RebuildDecisionEntry` is added to `types.ex` immediately after `ChangeClassEntry` since it is the analog struct.
- The phase52 section-presence assert uses `assert_contains_exact` with `proof.docs.support_matrix.rebuild_decision_table_section` as the ID. The byte-parity guard already covers drift, but the explicit assert makes the invariant self-documenting.
- native_runtime_version has exactly one additive row mapping to `"native or companion rebuild required"` — the D-09 asymmetry. The adopter_action text explicitly explains this asymmetry.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `rebuild_decision_table/0` is the single canonical source COMPAT-03, COMPAT-04, and COMPAT-05 all consume
- Plan 03 (compatibility.md JTBD guide) can now derive its decision table from `Crosswake.SupportMatrix.rebuild_decision_table/0`
- Plan 04 (doctor action-sequence) can derive from `change_class_entries/0` adopter_action fields
- Plan 05 (changelog upgrade-impact label) can reference the 4 verbatim strings locked in this plan

## Self-Check

- `lib/crosswake/manifest/types.ex` exists: YES
- `lib/crosswake/support_matrix/support_matrix.ex` contains `rebuild_decision_table`: YES
- `lib/crosswake/support_matrix/renderer.ex` contains `## Rebuild Decision Table`: YES
- `guides/support_matrix.md` contains `## Rebuild Decision Table`: YES
- Commits `eddca30` and `59c0b53` exist: YES
- Phase52 tests: 6/6 pass

---
*Phase: 124-compatibility-semantics-adopter-truth*
*Completed: 2026-06-20*
