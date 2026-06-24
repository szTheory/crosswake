---
phase: 128-collateral-see-it-run-guide
plan: "01"
subsystem: docs
tags: [exdoc, guides, drift-test, elixir, tdd]

requires:
  - phase: 127-see-it-run-banner
    provides: bin/see-it-run.sh hero command that the guide references and test guards

provides:
  - guides/see_it_run.md — reader-empathy orientation guide with gameplan blockquote and 7 JTBD sections
  - test/crosswake/guides/see_it_run_test.exs — source-derived drift test green on delivery
  - mix.exs ExDoc registration — see_it_run.md as item 2 in extras and Start group

affects:
  - 128-02 (QUICK_START update referencing this guide)
  - 128-03 (README See it run section referencing this guide)
  - Future ExDoc / HexDocs consumers of the Start group

tech-stack:
  added: []
  patterns:
    - "Per-file helper mirroring: house idiom copies helpers (source_port!, require_contains,
      require_regex, documented_path_failures, wrong_port_failures) into each test file rather
      than extracting a shared module — prevents fragile shared-module coupling in drift tests"
    - "documented_paths regex extended to bin/ and guides/ prefixes beyond the template's
      examples/ and script/ prefixes — enables link-rot detection across all internal paths"
    - "require_regex used for anchor-link assertions (support_matrix.md#support-truth-label-legend)
      where string contains would be overly broad"

key-files:
  created:
    - guides/see_it_run.md
    - test/crosswake/guides/see_it_run_test.exs
  modified:
    - mix.exs

key-decisions:
  - "Port derived from runtime.exs via System.get_env('PORT') regex — never hardcoded (D-18)"
  - "D-15 honest-label sentence quoted verbatim with support_matrix.md#support-truth-label-legend anchor"
  - "Guide links forward to QUICK_START; zero back-links to README (D-14 non-circular nav)"
  - "Unused @router_path and require_regex warnings resolved by adding @router_path to readability
    assertion and require_regex for legend anchor guard — keeps helper set complete without dead code"
  - "Guide carries 7 ## sections (not 8 literals) — the plan's '8 sections' counted the H1 title
    plus 7 ## headings; all 7 ## sections are present in D-08 order"

patterns-established:
  - "Drift test with three anti-vacuity cases: wrong_port, missing_route, missing_native_label"
  - "Advisory blockquote BEFORE/ADJACENT to native imagery (D-06)"
  - "emulator evidence term with support_matrix legend anchor in both guide and test"

requirements-completed: [DOCS-01, DOCS-03]

duration: 6min
completed: 2026-06-22
status: complete
---

# Phase 128 Plan 01: See It Run Guide Summary

**Source-derived drift test and orientation guide for guides/see_it_run.md — gameplan blockquote, 7 JTBD sections, honest emulator-evidence labels, registered in ExDoc Start group as item 2 after README**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-06-22T20:52:54Z
- **Completed:** 2026-06-22T20:58:29Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Drift test `test/crosswake/guides/see_it_run_test.exs` written test-first (TDD RED, 5 tests), port derived from `runtime.exs` via `System.get_env("PORT")` regex, no binary File.exists? assertions (D-19), no banner literal overlap (D-18)
- `guides/see_it_run.md` authored with gameplan blockquote + hero command `bin/see-it-run.sh`, all 7 D-08 JTBD sections in order, D-15 honest-label sentence verbatim, forward links to QUICK_START, zero back-links to README; drift test turns GREEN (5/5 pass)
- `mix.exs` updated: `guides/see_it_run.md` as item 2 in both `extras:` list and `Start:` group; `mix docs` exits 0 and emits `doc/see_it_run.html`

## Task Commits

1. **Task 1: Source-derived guide drift test (TDD RED)** - `b553034` (test)
2. **Task 2: Author guides/see_it_run.md** - `0de117b` (feat) — also updates test to fix unused-variable warnings
3. **Task 3: Register guide in ExDoc extras + Start group** - `fa08055` (chore)

## Files Created/Modified

- `/Users/jon/projects/crosswake/test/crosswake/guides/see_it_run_test.exs` — 5-test drift guard: readability, no-drift, wrong_port, missing_route, missing_native_label anti-vacuity cases
- `/Users/jon/projects/crosswake/guides/see_it_run.md` — 141-line orientation guide: gameplan blockquote, 7 JTBD sections, raw.githubusercontent.com collateral URLs, emulator evidence labels
- `/Users/jon/projects/crosswake/mix.exs` — 2 insertions: see_it_run.md in extras list (item 2) and Start group (item 2)

## Decisions Made

- Port derived from runtime.exs via `System.get_env("PORT")` regex — never hardcoded (D-18 correct duplication with sibling tests)
- `@router_path` attribute added to readability test assertion; `require_regex` used for `support_matrix.md#support-truth-label-legend` anchor guard — eliminates compiler warnings while keeping the full house helper set
- Guide carries 7 `##` sections — plan's "8 sections" included the H1 title; all D-08 sections present
- D-15 sentence quoted verbatim with legend anchor in both the guide (Wire a Native Runtime section) and the drift test (require_regex assertion)
- `documented_paths/1` extended to match `bin/` and `guides/` prefixes in addition to the template's `examples/` and `script/` prefixes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused compiler warnings from test module**
- **Found during:** Task 2 (running drift test after guide creation)
- **Issue:** `@router_path` attribute was set but never used; `require_regex/5` helper was defined but never called — both produced compiler warnings on `mix test`
- **Fix:** Added `File.exists?(@router_path)` assertion to readability test; added `require_regex` call for `support_matrix.md#support-truth-label-legend` anchor guard in `scan_guide/1`
- **Files modified:** `test/crosswake/guides/see_it_run_test.exs`
- **Verification:** `mix test test/crosswake/guides/see_it_run_test.exs` exits 0 with zero warnings
- **Committed in:** `0de117b` (Task 2 commit, alongside the guide)

---

**Total deviations:** 1 auto-fixed (Rule 1 — unused attribute/function warning)
**Impact on plan:** The fix improves the test module by adding meaningful assertions for the router path and the support-matrix legend anchor. No scope creep; both uses are called for by the plan's action spec.

## Issues Encountered

None — all three tasks executed cleanly. The only friction was compiler warnings from the per-file helper set (unused `@router_path` and `require_regex`) which were resolved inline.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This plan creates documentation files and a test module only. The `mix docs` output is not distributed — it is generated locally. No threat flags.

## Known Stubs

None — the guide references raw.githubusercontent.com image URLs for collateral that will be captured and committed in plan 128-02. The image URLs are intentional forward-references (the guide renders in ExDoc without them — images simply don't load until collateral is captured). This is not a stub that prevents the plan's goal (DOCS-01 guide authorship) from being achieved. The collateral capture is tracked in plan 128-02.

## Self-Check

Files exist:
- `guides/see_it_run.md` — FOUND
- `test/crosswake/guides/see_it_run_test.exs` — FOUND
- `mix.exs` (modified) — FOUND

Commits exist:
- `b553034` — FOUND (test(128-01): add failing drift test)
- `0de117b` — FOUND (feat(128-01): author guides/see_it_run.md)
- `fa08055` — FOUND (chore(128-01): register in ExDoc extras + Start group)

Test result: `mix test test/crosswake/guides/see_it_run_test.exs` — 5 tests, 0 failures

## Self-Check: PASSED

## Next Phase Readiness

- `guides/see_it_run.md` is live in ExDoc Start group, ready for plan 128-02 to add the QUICK_START pointer blockquote and rename Option A
- The drift test guards the guide against port/route/label drift; it will catch any future mutation to the relevant source files
- Plan 128-03 (README section) can reference this guide via `guides/see_it_run.md`

---
*Phase: 128-collateral-see-it-run-guide*
*Completed: 2026-06-22*
