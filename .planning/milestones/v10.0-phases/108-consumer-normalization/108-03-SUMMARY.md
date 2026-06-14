---
phase: 108-consumer-normalization
plan: "03"
subsystem: brand-normalization
tags: [offline-ui, test-contract, tailwind-retirement, semantic-tokens, norm-04]
dependency_graph:
  requires: [108-02]
  provides: [generator-test-semantic-contract, offline-css-no-clobber-test, link-order-test]
  affects: [test/mix/tasks/crosswake.gen.offline_ui_test.exs]
tech_stack:
  added: []
  patterns: [semantic-only-assertions, no-clobber-test-mirror, link-order-binary-match]
key_files:
  created: []
  modified:
    - test/mix/tasks/crosswake.gen.offline_ui_test.exs
decisions:
  - "Asserted --cw-action-focus-ring (not --cw-action-bg) in offline.css content test — offline.css uses focus-ring action token but not action-bg; spirit of NORM-04 satisfied (action tier is referenced)"
  - "Ran tests via MIX_DEPS_PATH pointing at main repo deps (worktree shares git history but not _build/deps)"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-14"
  tasks_completed: 1
  tasks_total: 1
  files_created: 0
  files_modified: 1
---

# Phase 108 Plan 03: Generator Test — Semantic-Token Contract Summary

**One-liner:** Rewrote `crosswake.gen.offline_ui_test.exs` to pin the Plan 02 semantic-token contract: retired 4 stale Tailwind/esbuild assertions, kept neutral assertions, added 4 new tests (semantic class refs + no Tailwind, offline.css semantic content, offline.css no-clobber, link-order). All 9 tests pass.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite the generator test to the semantic-token contract | b014ff7 | test/mix/tasks/crosswake.gen.offline_ui_test.exs |

## What Was Built

### Assertions Removed (retired Tailwind/esbuild block, D-11)

Four assertions that pinned the now-retired stale generator output were removed from the "outputs standard instructions" test:
- `output =~ "cw-wake-700"` — retired Tailwind theme reference
- `output =~ "cw-brass-500"` — retired Tailwind theme reference
- `output =~ "tailwind.config.js"` — retired legacy step
- `output =~ "Configure esbuild to bundle offline.js"` — retired legacy step

Three neutral assertions were kept:
- `"Offline UI components generated successfully!"`
- `"get \"/offline\""`
- `"TestAppWeb.OfflineController"`

### New Tests Added

**Test: generated output contains semantic token references, not Tailwind classes**
- Reads `offline_page.html.heex` + `offline_root.html.heex` from the tmp dir and combines
- Asserts `cw-offline-` is present (semantic class namespace)
- Refutes: `flex`, `bg-white`, `bg-cw-foam-50`, `text-cw-current-950`, `min-h-screen`, `~r/border-cw-/`, `border-gray-`, `--cw-primitive-`

**Test: generated offline.css contains semantic token references and no primitives**
- Reads vendored `priv/static/assets/offline.css` from tmp dir
- Asserts: `var(--cw-surface-default)`, `var(--cw-text-default)`, `--cw-action-focus-ring`
- Refutes: `--cw-primitive-`

**Test: offline.css no-clobber semantics**
- Mirrors the existing `tokens.css` no-clobber test verbatim (D-01)
- Writes custom content, re-runs generator, asserts custom content preserved + output contains "reused"

**Test: offline_root links offline.css after tokens.css and app.css**
- Uses `:binary.match/2` to find byte positions of "tokens.css", "app.css", "offline.css"
- Asserts `tokens_pos < app_pos < offline_pos` (D-02 link order)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Adjusted --cw-action-bg assertion to --cw-action-focus-ring**
- **Found during:** Task 1 verification
- **Issue:** The plan's PATTERNS.md specifies `assert css_content =~ "--cw-action-bg"` but the Plan 02 `offline.css` does not use `--cw-action-bg`; it uses `--cw-action-focus-ring` in the `:focus-visible` rule (the offline page has no action buttons, so action-bg is not applicable)
- **Fix:** Changed the assertion to `--cw-action-focus-ring`, which is the actual action-tier token present in offline.css. The spirit of NORM-04 (action semantic tier is referenced) is satisfied
- **Files modified:** test/mix/tasks/crosswake.gen.offline_ui_test.exs
- **Commit:** b014ff7

## Known Stubs

None. All new tests make real assertions against generator output.

## Threat Flags

None. Test-only change; no new runtime surface, auth paths, or network endpoints introduced.

## Self-Check: PASSED

Files modified:
- test/mix/tasks/crosswake.gen.offline_ui_test.exs — FOUND (178 lines)

Commits:
- b014ff7 test(108-03): rewrite offline_ui_test to pin semantic-token contract (NORM-04) — FOUND

Verification:
- `grep -coE 'cw-wake-700|cw-brass-500|tailwind.config.js|Configure esbuild to bundle offline.js' <file>` == 0 — PASSED
- File contains `cw-offline-`, `var(--cw-surface-default)`, `offline.css`, `refute` — PASSED
- `mix test test/mix/tasks/crosswake.gen.offline_ui_test.exs` exits 0 — PASSED (9 tests, 0 failures)
