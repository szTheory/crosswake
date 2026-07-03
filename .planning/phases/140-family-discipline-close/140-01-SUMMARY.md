---
phase: 140-family-discipline-close
plan: 01
subsystem: docs + proof-tests
tags: [compat-matrix, drift-test, FAMILY-01, governance]
requires:
  - Phase 132 compat-matrix drift test (existing forward/reverse parity + non-vacuity)
provides:
  - "Disciplined compat matrix: one-liner Threadline cells + `## Threadline wiring` prose + 5 `unpublished` version cells + anti-hand-edit HTML comment"
  - "proof.compat_03.no_inter_companion_columns — O(N) header-column guard (D-07)"
  - "proof.compat_03.version_cell_format — Current Version cell format guard (D-08)"
affects:
  - guides/companion_compatibility.md
  - test/crosswake/proof/phase132_compat_matrix_drift_test.exs
tech-stack:
  added: []
  patterns:
    - "Header-keyed column resolution (header_row_cells/1) so column reorders can't silently pass"
    - "FORMAT-only version assertion (unpublished | bare semver) — hex.pm stays the version authority"
key-files:
  created: []
  modified:
    - guides/companion_compatibility.md
    - test/crosswake/proof/phase132_compat_matrix_drift_test.exs
decisions:
  - "D-05: Threadline row cells collapsed to one-liners; wiring explanation moved to `## Threadline wiring` prose below the table"
  - "D-06: all five Current Version cells set to `unpublished`; no pipeline write-back automation"
  - "D-07: O(N) structural guard added — no header column beyond col 1 may name a companion package"
  - "D-08: version-cell FORMAT guard added (unpublished | backticked semver), no specific version asserted"
  - "D-09: parser TODO for the eventual core-1.0 compound `~> 0.1 or ~> 1.0` constraint; NO Companion ID drift test, NO new column"
metrics:
  duration: ~3m
  completed: 2026-07-03
  tasks: 2
  files: 2
status: complete
---

# Phase 140 Plan 01: Compat-Matrix Discipline & O(N) Guard Summary

Disciplined the adopter-facing compat matrix (`guides/companion_compatibility.md`) — one-liner Threadline cells, wiring prose moved below the table, five honest `unpublished` pre-publish version cells, anti-hand-edit HTML comment — and locked the matrix shape + version-cell honesty with two new merge-blocking drift-test assertions (O(N) header-column guard + version-cell format guard), plus a core-1.0 compound-constraint parser TODO. FAMILY-01 satisfied.

## What Was Built

### Task 1 — Matrix cell discipline + honest version cells (commit `e39b30db`)
- **D-05:** Threadline data row's ~300-char prose-in-cell collapsed. `Companion ID` cell → `N/A (observer — not a :companions registrant)`; `Engine Dependency` cell → `none (optional :plug + :phoenix_live_view for surface modules)`. The `Crosswake.Plug.Threadline` / `on_mount: Crosswake.Live.Threadline` wiring explanation moved to a new `## Threadline wiring` prose section below the table. Other four rows' Companion ID cells left as their short backticked atoms.
- **D-06:** all five `Current Version` cells set to the backtick-wrapped `unpublished` token. Standalone anti-hand-edit HTML comment added on its own line above the table; the pre-existing `compat-03 contract` HTML comment (which the drift test keys on) preserved. Updated the "records the last published line" prose to describe the `unpublished` pre-publish state (worded with quotes, not the backticked token, so it doesn't inflate the 5-cell `grep -c` count).

### Task 2 — O(N) column guard + version-cell format guard (commit `bda44e46`)
- **D-07 (`proof.compat_03.no_inter_companion_columns`):** parses the header row via a new `header_row_cells/1` helper (sharing the existing `^\|.*Hex Package.*\|` idiom), drops col 0 (`Hex Package`), and refutes any remaining header cell matching `~r/crosswake_\w+/`. A future `Requires crosswake_sigra` column fails CI — keeps the matrix O(N).
- **D-08 (`proof.compat_03.version_cell_format`):** locates the `Current Version` column via a new `current_version_column_index/1` helper, then for every `crosswake_*` data row (same non-vacuous `@row_regex`/`doc_package_rows/1` set) asserts the trimmed cell is `` `unpublished` `` OR a backticked bare semver `~r/^`\d+\.\d+\.\d+`$/`. FORMAT only — no specific version asserted.
- **D-09:** added a `# TODO(core-1.0, D-09)` comment near `extract_hex_req_from_if/1` explaining that a companion may later declare a compound `~> 0.1 or ~> 1.0` requirement (an `{:or, _, [...]}` AST node) that must be accepted rather than surfacing as a cryptic drift failure. Comment only — no `or`-parsing added, no new column, no Companion ID drift test.
- Refactored `requires_crosswake_column_index/1` to reuse the shared `header_row_cells/1` helper (behavior preserved). No existing assertion weakened, deleted, or renamed.

## Verification

- `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — **6 tests, 0 failures** (was 4; +2 new). Also green under `--warnings-as-errors`.
- `grep -c '`unpublished`' guides/companion_compatibility.md` == **5** (one per data row; prose reworded to quoted "unpublished" to avoid a 6th match).
- Header row contains the six original column names and **no** `crosswake_` token.
- `grep -c 'proof.compat_03'` == **15** (well above the ≥7 floor: original 5 stable ids + 2 new).
- **Negative check (D-07):** proved inline (scratch `/tmp` Elixir, then removed — no shipped-test dependency) that the O(N) guard's filter returns `[]` on the good header and `["Requires crosswake_sigra"]` on a mutated header. Guard actually fails on an inter-companion column.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes, no architectural decisions, no auth gates.

Minor implementation note (within plan discretion): the D-06 prose sentence was worded with quoted `"unpublished"` rather than the backticked token so that `grep -c '`unpublished`'` returns exactly 5 (the five data cells) as the acceptance criterion requires, rather than 6.

## Known Stubs

None. No hardcoded empty values, placeholders, or unwired data introduced. The `unpublished` version cells are the intended honest pre-publish state per D-06 (the human writes real semver back post-publish); the anti-hand-edit HTML comment and the D-08 format guard document and enforce this. Not a stub — it is the deliberate pre-publish contract for FAMILY-01, resolved by the human-gated Wave 4 batched publish.

## Self-Check: PASSED

- FOUND: guides/companion_compatibility.md
- FOUND: test/crosswake/proof/phase132_compat_matrix_drift_test.exs
- FOUND commit e39b30db (Task 1)
- FOUND commit bda44e46 (Task 2)
