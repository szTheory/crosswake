---
phase: 124-compatibility-semantics-adopter-truth
plan: "03"
subsystem: compatibility-guide
tags: [docs-contract, compatibility, decision-table, compat-03]
status: complete

dependency_graph:
  requires: [124-02]
  provides: [guides/compatibility.md#decision-table-first, test/crosswake/guides/compatibility_test.exs]
  affects: [guides/compatibility.md, test/crosswake/guides/compatibility_test.exs]

tech_stack:
  added: []
  patterns:
    - decision-table-first guide structure (JTBD table leads, prose demoted)
    - docs-contract ExUnit test with :binary.match ordering assertion
    - renderer-mirror anti-drift assertion coupling guide to canonical source
    - count_occurrences/2 idiom from adopter_profiles_test analog

key_files:
  created:
    - test/crosswake/guides/compatibility_test.exs
  modified:
    - guides/compatibility.md

decisions:
  - prose_sentinel: "'Crosswake keeps runtime ownership' (line 22) — used as the ordering sentinel in the compatibility_test.exs :binary.match assertion"
  - table_column_wording: "Change type | Axis touched | Rebuild class | Adopter action | Denial signal if you skip it | Guide anchor"
  - table_position: "Table header at byte 200, prose sentinel at byte 3854 — ordering holds with large margin"
  - native_asymmetry_stated: "Explicit paragraph immediately after table: '`native_runtime_version` has **no** additive-without-rebuild row'"
  - legacy_prose_retained: "Old '## Do I need to rebuild?' prose moved to '## Do I need to rebuild? (legacy prose)' to preserve existing cross-references"
  - 6_tests_added: "6 ExUnit tests: ordering, renderer-mirror, axes, asymmetry, no-second-support-matrix, table-count-once"

metrics:
  duration: "8 minutes"
  completed: "2026-06-20"
  tasks_completed: 2
  files_changed: 2

requirements:
  - COMPAT-03
---

# Phase 124 Plan 03: Compatibility Guide Decision-Table-First Summary

Decision-table-first `guides/compatibility.md` with Denial signal column, machine-tested by `compatibility_test.exs` with table-before-prose ordering and renderer-mirror anti-drift teeth.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Restructure compatibility.md decision-table-first with Denial signal column | 184fcd6 | guides/compatibility.md |
| 2 | Add compatibility_test.exs docs-contract test (ordering + renderer-mirror) | e3ee7ec | test/crosswake/guides/compatibility_test.exs |

## What Was Built

### Task 1: guides/compatibility.md restructured

Added `## Do I need to rebuild? (start here)` as the new lead section (byte 200) containing a JTBD decision table with columns:

```
| Change type | Axis touched | Rebuild class | Adopter action | Denial signal if you skip it | Guide anchor |
```

The table:
- Mirrors the canonical `rebuild_decision_table/0` rebuild classes verbatim (all 4 strings)
- Includes `compatibility_mismatch`, `undeclared_capability`, and `pack_incompatible` denial signals
- Covers all 3 version axes (`manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`)
- Has `native_runtime_version` with a single "any change" row mapping to `native or companion rebuild required` (no additive-without-rebuild row — the asymmetry)

Adjacent prose immediately after the table explicitly states the `native_runtime_version` asymmetry: additive `manifest_schema`/`bridge_protocol` bumps are `compatibility-bump only` because the native floor is `>=`, while `native_runtime_version` has NO such additive-without-rebuild row.

The original lead prose (`Crosswake keeps runtime ownership...`) was demoted to below the table at line 22 (byte 3854). All existing sections preserved: `## Compatibility Axes`, `## Companion Compatibility Contract`, `## Release Choreography`, Runtime Line Rules. No `Target | Version | Status` support-status table introduced.

### Task 2: test/crosswake/guides/compatibility_test.exs

New module `Crosswake.Guides.CompatibilityTest` with 6 tests:

1. **Table-before-prose ordering** (load-bearing tooth): asserts `:binary.match(guide, table_header) < :binary.match(guide, "Crosswake keeps runtime ownership")`. Would fail silently if prose crept above the table.

2. **Mirror-agrees-with-renderer** (anti-drift tooth): for each of the 4 verbatim rebuild-class strings, asserts it appears in BOTH `Renderer.render(canonical())` and `guides/compatibility.md`. A rename in support_matrix breaks this test.

3. **All three axes present**: asserts `manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version` all present.

4. **native_runtime_version asymmetry locked**: asserts native_runtime asymmetry stated; refutes any additive-no-rebuild row for native_runtime (3 negative assertions covering compat-bump-only, docs-only, core-only variants).

5. **No second support-status table**: `refute guide =~ "| Target | Version | Status |"`.

6. **Decision table appears exactly once**: `count_occurrences(guide, table_header) == 1`.

`count_occurrences/2` private helper copied verbatim from `adopter_profiles_test.exs` analog.

## Verification Results

```
mix test test/crosswake/guides/compatibility_test.exs
6 tests, 0 failures
```

Byte-position ordering: table header at 200, prose sentinel at 3854 — large margin, ordering assertion is real.

## Decisions Made

- **Prose sentinel chosen**: `"Crosswake keeps runtime ownership"` — the first prose sentence in the file (original line 3, now line 22). Matches the D-11 specification exactly.
- **Table column wording**: `Change type | Axis touched | Rebuild class | Adopter action | Denial signal if you skip it | Guide anchor` — exact column set satisfying D-10 requirements.
- **Legacy prose heading**: Renamed old `## Do I need to rebuild?` to `## Do I need to rebuild? (legacy prose)` to preserve existing cross-references while making it subordinate to the new lead section.
- **6 tests instead of 5**: Added a 6th test (`count_occurrences == 1`) to prevent table duplication in future edits.
- **Asymmetry assertion approach**: Used a multi-clause `or` assertion plus 3 negative refute assertions to cover both the explicit wording in the prose paragraph and the table structure.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

- [x] `guides/compatibility.md` exists and leads with `## Do I need to rebuild? (start here)`
- [x] `test/crosswake/guides/compatibility_test.exs` exists with 6 tests
- [x] Task 1 commit: 184fcd6 (feat(124-03): restructure compatibility.md decision-table-first with Denial signal column)
- [x] Task 2 commit: e3ee7ec (test(124-03): add compatibility_test.exs docs-contract test (ordering + renderer-mirror))
- [x] All 6 tests pass: `mix test test/crosswake/guides/compatibility_test.exs` — 6 tests, 0 failures
- [x] Preserved sections: `## Compatibility Axes`, `## Companion Compatibility Contract`, `## Release Choreography` (grep -c returns 3)
- [x] No Target/Version/Status table present (grep returns nothing)
- [x] All 4 verbatim rebuild-class strings present in guide and renderer output

## Self-Check: PASSED
