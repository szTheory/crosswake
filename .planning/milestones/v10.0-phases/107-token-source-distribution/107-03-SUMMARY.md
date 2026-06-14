---
phase: 107-token-source-distribution
plan: "03"
subsystem: documentation
tags: [tokens, distribution, exdoc, guides, norm-03]
requirements: [NORM-03]
dependency_graph:
  requires: []
  provides: [guides/tokens.md, mix.exs extras registration]
  affects: [ExDoc output, Hex package docs]
tech_stack:
  added: []
  patterns: [ExDoc extras registration, guides/ placement convention]
key_files:
  created:
    - guides/tokens.md
  modified:
    - mix.exs
decisions:
  - "guides/tokens.md placed after guides/offline.md in extras: — natural grouping since tokens.md documents the distribution that supports offline UI"
  - "No change to groups_for_extras: — existing Guides: ~r/guides\\// catch-all already covers it"
  - "No change to files: whitelist — guides and priv already included"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-13"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 1
---

# Phase 107 Plan 03: Token Distribution Guide Summary

## One-liner

`guides/tokens.md` documents the NORM-03 single distribution mechanism end-to-end (source JSON → one-command regeneration → byte-identical outputs → two consumer paths → no-hand-edit contract) and is registered in ExDoc extras.

## What Was Built

**Task 1: Write guides/tokens.md and register it in mix.exs extras** (commit `87b1e0e`)

Created `guides/tokens.md` (102 lines) covering:
- **Source:** `crosswake.tokens.json` (DTCG 2025.10, frozen v9.0 contract)
- **Generate:** `node brandbook/tools/compile-tokens.js` — single command, no other toolchain
- **Two outputs:** `brandbook/tokens/tokens.css` (brand book copy) and `priv/static/crosswake/tokens.css` (distributable)
- **Parity verification:** `diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css`
- **What ships:** `priv/` is in Hex `files:` whitelist; `brandbook/` is excluded
- **Consumer path 1:** `mix crosswake.gen.offline_ui` (no-clobber copy + link before app.css)
- **Consumer path 2:** Direct Phoenix host (copy from deps + `<link>` before app.css, load-order rationale stated)
- **Contract:** never hand-edit tokens.css; both copies byte-identical; Phase 109 adds CI diff gate

Added `"guides/tokens.md"` to `mix.exs` `extras:` list after `"guides/offline.md"`. The existing `Guides: ~r/guides\//` catch-all in `groups_for_extras:` auto-groups it — no further changes needed.

## Verification

All acceptance criteria passed:
- `guides/tokens.md` exists with 102 lines (minimum was 30)
- Contains `node brandbook/tools/compile-tokens.js`
- Contains `priv/static/crosswake/tokens.css`
- Contains no-hand-edit contract statement
- Contains byte-identical/diff parity statement
- `mix.exs` extras includes `"guides/tokens.md"`
- Both consumer paths documented with load-order note
- File is in `guides/` (not `brandbook/`), ships in Hex package, appears in ExDoc
- `mix compile --warnings-as-errors` clean (verified against main repo with deps)

## Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | guides/tokens.md created + mix.exs extras registration | `87b1e0e` |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. Documentation + ExDoc config change only. No new code paths, network endpoints, auth paths, file access patterns, or schema changes. Consistent with the plan's threat model (T-107-05 accepted, T-107-SC accepted).

## Self-Check: PASSED

- `guides/tokens.md` exists: FOUND
- `mix.exs` contains `guides/tokens.md`: FOUND
- Commit `87b1e0e` exists: FOUND
