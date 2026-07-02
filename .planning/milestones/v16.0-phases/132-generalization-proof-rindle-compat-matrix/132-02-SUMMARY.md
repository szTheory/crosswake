---
phase: 132-generalization-proof-rindle-compat-matrix
plan: 02
subsystem: companion-packaging
tags: [compat-matrix, drift-test, docs, companion-versioning, proof, ast-parse]
status: complete
requires:
  - "packages/crosswake_rindle/mix.exs (132-01 — non-vacuity precondition, >= 2 packages)"
  - "packages/crosswake_rulestead/mix.exs (existing companion)"
  - "Crosswake.TestSupport.ProofAssertions.stable_id_message/7"
provides:
  - "guides/companion_compatibility.md (COMPAT-02 single-source-of-truth matrix)"
  - "Crosswake.Proof.Phase132CompatMatrixDriftTest (COMPAT-03 merge-blocking drift test)"
  - "proof.compat_03.{doc_exists,non_vacuity,matrix_drift.<pkg>.*} stable ids"
affects:
  - "future companion packages — adding crosswake_<x> now requires a matching matrix row or the drift test fails"
tech-stack:
  added: []
  patterns:
    - "code-canonical-with-drift-test (companion mix.exs is source of truth; doc is human-readable; test asserts bidirectional parity)"
    - "AST-parse crosswake_dep/0 via Code.string_to_quoted/2 + Macro.prewalk/3 (NOT grep — grep returns both Hex and path branches)"
    - "pinned HTML-comment column contract resolves the requirement column by name, not absolute index (D-12)"
key-files:
  created:
    - guides/companion_compatibility.md
    - test/crosswake/proof/phase132_compat_matrix_drift_test.exs
  modified: []
decisions:
  - "The requirement-cell check resolves the 'Requires crosswake' column index from the pinned HTML-comment contract and exact-matches ONLY that cell — a whole-row String.contains? false-passed because the Engine Dependency cell carries its own ~> 0.1 literal (caught during RED/GREEN drift verification, fixed as a Rule 1 bug)."
  - "extract_hex_req_from_if/1 has a nil fallthrough so a refactored crosswake_dep/0 surfaces as version_mismatch (fail-loud) rather than silently extracting nothing."
metrics:
  duration: ~14m
  completed: 2026-06-26
  tasks: 2
  files: 2
---

# Phase 132 Plan 02: Compat Matrix Doc + COMPAT-03 Drift Test Summary

Shipped `guides/companion_compatibility.md` (COMPAT-02) — the single source of truth for
"what core version + which engine do I need to add a companion?" — and the merge-blocking
`Phase132CompatMatrixDriftTest` (COMPAT-03) that keeps it honest against each companion's
declared `{:crosswake, "~> 0.1"}` requirement, bidirectionally and non-vacuously. With both
`crosswake_rulestead` and `crosswake_rindle` now real packages, the drift test validates
against real state (2 packages), not a vacuous one.

## What Was Built

**Task 1 — COMPAT-03 drift test (RED, commit acc2a9d)**
`test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — `use ExUnit.Case, async: true`,
untagged, `alias Crosswake.TestSupport.ProofAssertions`. Four tests:

1. `doc_exists` — distinct failure when `guides/companion_compatibility.md` is absent.
2. `non_vacuity` — `length(Path.wildcard("packages/crosswake_*/mix.exs")) >= 2` before any
   per-package loop (Pitfall 3, D-13).
3. forward parity — for each `packages/crosswake_*/mix.exs`, AST-extract the `crosswake_dep/0`
   `do:`-branch requirement via `Code.string_to_quoted/2` + `Macro.prewalk/3` (NOT grep, which
   returns both the Hex and `path: "../.."` strings — Pitfall 1), then assert the doc has the
   package row (`missing_from_doc`) and the exact requirement literal in the **Requires crosswake**
   cell (`version_mismatch`).
4. reverse parity — every `crosswake_*` doc row maps to a real `packages/<pkg>/mix.exs`
   (`phantom_doc_row`).

Committed RED: 3/4 failing because the doc did not yet exist (doc_exists fired distinctly;
non-vacuity already passed at 2 packages).

**Task 2 — compat matrix doc + drift-cell fix (GREEN, commit ac03e63)**
`guides/companion_compatibility.md` — pinned `compat-03 contract` HTML comment above the table
(names col1 = Hex Package, the requirement cell = "Requires `crosswake`", warns not to reorder
without updating the test), a six-column matrix (Hex Package, Companion ID, Current Version,
Requires `crosswake`, Engine Dependency, hexdocs) with one row each for `crosswake_rulestead`
and `crosswake_rindle`, verbatim `~> 0.1` requirement cells, and the five prose sections in
brand voice: opening orientation (links to `companions.md` for setup + `compatibility.md` for
the forward-looking contract, does not merge them), Independent Versioning, Reading the
Requirement Syntax (`~> 0.1` = `>= 0.1.0 and < 1.0.0`), Engine Dependencies (optional engines
not pulled transitively; honest friction that `rulestead 1.0.0` and `rindle 0.3.0` are both
outside `~> 0.1` so adopters must pin the `0.1.x` line — D-19), and Verifying Companion Health
(`mix crosswake.doctor` CTA closing the registered-but-no-engine loop).

## Verification

- `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` → **4 tests, 0 failures**.
- Drift proof (the non-vacuity guarantee): corrupting the rulestead **Requires crosswake** cell
  to `~> 9.9` turns `crosswake_rulestead.version_mismatch` **RED**; reverting returns GREEN.
- Phantom proof: appending a `crosswake_phantom` row turns `crosswake_phantom.phantom_doc_row`
  **RED**; removing it returns GREEN.
- Doc-content checks: `compat-03 contract` HTML comment present, both companion names present,
  no banned `just` / `fully compatible` / `ecosystem`.
- `MIX_ENV=test mix compile --warnings-as-errors` → clean (test file compiles, no unused).
- `Path.wildcard("packages/crosswake_*/mix.exs")` → 2 (rulestead + rindle).

## Deviations from Plan

**1. [Rule 1 — Bug] Requirement check matched the whole row line, masking real drift.**
- **Found during:** Task 2 RED/GREEN drift verification (the plan's mandated "corrupt the version,
  confirm `version_mismatch` goes red" check).
- **Issue:** The first implementation asserted `String.contains?(row_line, req)`. Because the
  Engine Dependency cell on the same row is `{:rulestead, "~> 0.1", optional: true}`, it carries
  its own `~> 0.1` literal — so corrupting the dedicated **Requires crosswake** cell to `~> 9.9`
  still left `~> 0.1` elsewhere on the line and the test false-passed. The drift was undetectable,
  defeating COMPAT-03's whole point.
- **Fix:** `doc_row_has_requirement?/3` now resolves the **Requires crosswake** column index from
  the pinned HTML-comment header contract (D-12 — the reason the column is pinned), splits the
  package's row into cells, and exact-matches the requirement against that one cell only
  (backtick-stripped; reject substring/semver-equivalence, D-13). Added `requires_crosswake_column_index/1`
  and `row_cells/1`.
- **Files:** `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`.
- **Commit:** ac03e63 (folded into the GREEN commit — the doc and the working assertion are one
  feature; the RED commit acc2a9d intentionally preceded both).

This is exactly the failure mode the pinned column contract exists to prevent; the first cut
read the contract comment as documentation but still keyed the assertion on the whole line. The
fix makes the assertion actually honor the pinned column.

## Known Stubs

None. Both artifacts are fully wired: the doc has real data for both real packages, and the test
asserts against live `mix.exs` source and the live doc.

## Threat Surface

No new threat surface beyond the plan's `<threat_model>`.
- **T-132-04 (vacuous-pass via empty/single glob):** mitigated — the `non_vacuity` test asserts
  `>= 2` packages before the per-package loop; with rindle real (132-01/132-03) this is satisfied
  by genuine packages, not a stub.
- **T-132-03 / T-132-SC:** unchanged — the test reads only controlled in-tree files
  (`packages/crosswake_*/mix.exs`, the doc); no external/untrusted input; no package-manager installs.

## Self-Check: PASSED

Both created artifacts present on disk (`guides/companion_compatibility.md`,
`test/crosswake/proof/phase132_compat_matrix_drift_test.exs`); both task commits (acc2a9d,
ac03e63) present in git history.
