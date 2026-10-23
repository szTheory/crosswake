---
phase: 170-vacuous-assertion-remediation
plan: 01
subsystem: testing
tags: [vacuous-assertions, elixir, ledger, absence-is-not-success, vac-01, static-analysis]

# Dependency graph
requires:
  - phase: 169-diagnostic-legibility
    provides: "release.scanner.roster_exact regenerate-and-diff-exact pattern (D-04), reused one level down for call-site completeness"
provides:
  - "script/inventory_collection_assertions.exs — regenerable tree scanner classifying every assert Enum.all?/any? and refute Enum.any?/all? call site in test/**/*.exs"
  - "script/collection_assertion_ledger.json — committed classification snapshot covering all 220 audited sites"
  - "test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs — ledger-completeness proof, non-vacuity controls, and D-14/D-24 measured-fact guard tests"
  - "VACG-01 sunset step recorded in REQUIREMENTS.md, the script's header comment, and the snapshot's sunset field"
affects: [170-02, 170-03, VACG-01]

actuals:
  tokens: 39000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Content-hash row keys ({enclosing test name, normalized expression, ordinal} → sha256:<16 hex>) instead of file:line, so a moved-but-unchanged assertion produces zero diff noise"
    - "Root-identifier backward scan for guard/pin detection: unwrap one level of a |> pipeline or an Enum/Map/MapSet/Stream call to find the collection's root, then search backward through the enclosing test body (unbounded, not a fixed N-line window) for a same-root non-emptiness guard or cardinality pin"
    - "Scope-in-ledger self-description: the committed snapshot's own 'scope' field is what an unqualified --check/--emit-snapshot regenerates against, so the CLI needs no --scope flag to match what was committed"

key-files:
  created:
    - script/inventory_collection_assertions.exs
    - script/collection_assertion_ledger.json
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  modified:
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md

key-decisions:
  - "Reused JSON (Elixir 1.18+ stdlib) instead of Jason for the script's JSON encode/decode — a standalone elixir script.exs has no Mix dependency path, and JSON is already the idiom test/crosswake/proof/phase169_diagnostic_legibility_test.exs uses for the same reason."
  - "An unqualified --check or --emit-snapshot reads its scope from the ledger file it is checking/regenerating against, falling back to the tree-wide default only when no ledger exists yet — this is what lets Task 1's narrow release-critical snapshot and Task 2's full-tree snapshot both pass `elixir script/inventory_collection_assertions.exs --check` with zero flags."
  - "Cardinality-pinning and non-emptiness-guard detection matches on the flagged expression's ROOT identifier, unbounded backward through the whole enclosing test body — not a fixed 6-line window — because a guard can sit many lines above a SECOND flagged assertion sharing the same already-guarded collection (test/mix/tasks/crosswake_doctor_test.exs:297's `!= []` guard sits 2 lines above one assertion but the pattern generalizes without a hard line cap)."
  - "One site (test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:92) required a manual override: its pinning list is asserted against a differently-named field (assertion_ids) than the flagged expression's own identifier (assertions), a fact only a human reading the surrounding struct can establish. Recorded as an explicit, cited override rather than widening the heuristic to guess at cross-identifier equivalence."

requirements-completed: [VAC-01]

coverage:
  - id: D1
    description: "Regenerable inventory script classifies every assert Enum.all?/any? and refute Enum.any?/all? call site in test/**/*.exs (220 sites) into D-07's five-bucket vocabulary"
    requirement: "VAC-01"
    verification:
      - kind: other
        ref: "elixir script/inventory_collection_assertions.exs --check"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs#Task 2: full-tree audit, measured totals pinned as literals (D-14 / D-24)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Ledger-completeness test proves both directions (unclassified/orphan) and is demonstrated going RED against a mutated snapshot (D-14 non-vacuity)"
    requirement: "VAC-01"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs#Task 1: non-vacuity control (D-14) — a mutated ledger copy must go RED"
        status: pass
    human_judgment: false
  - id: D3
    description: "VAC-01 adjacency/empty/encoding/ordering edge cases all proven via synthetic fixtures"
    requirement: "VAC-01"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs#VAC-01 adjacency edge / empty edge / encoding edge / ordering edge"
        status: pass
    human_judgment: false
  - id: D4
    description: "VACG-01's sunset step (lift detection core, then delete the ledger and its proof test) recorded in REQUIREMENTS.md, the script's header, and the snapshot's sunset field"
    verification:
      - kind: other
        ref: "grep -c inventory_collection_assertions .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-09-16
status: complete
---

# Phase 170 Plan 01: Vacuous Assertion Ledger and Classifier Summary

**Regenerable, content-hash-keyed inventory of all 220 collection-assertion sites (`assert Enum.all?/any?`, `refute Enum.any?/all?`) in `test/**/*.exs`, classified into D-07's five-bucket vocabulary with a mandatory site-specific rationale on every non-trivial row, and proven non-vacuous by a real subprocess mutation control.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-09-16T12:50:00Z
- **Completed:** 2026-09-16T13:45:00Z
- **Tasks:** 3
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- Built `script/inventory_collection_assertions.exs`, a standalone `#!/usr/bin/env elixir` scanner (module `Crosswake.CollectionAssertionInventory`) following `script/check_absence_is_not_success.exs`'s narrative-header + heredoc-stripped-source-regex idiom, with `run/2`, `rows/2`, `normalize_expression/1`, `row_key/3`, and `render_snapshot/2` as its public surface and `--root`/`--scope`/`--ledger`/`--emit-snapshot`/`--check` CLI flags.
- Committed the full-tree snapshot (`script/collection_assertion_ledger.json`) covering all 220 audited sites: 42 `assert_all`, 131 `assert_any`, 47 `refute_any`, 0 `refute_all` — matching the `170-CONTEXT.md` verified ground truth exactly. Bucket composition: 131 `safe-by-construction`, 4 `safe-compile-time-literal`, 17 `safe-cardinality-pinned`, 8 `safe-guarded`, 60 `needs-fix`.
- Implemented D-07's full five-bucket classifier in precedence order, keyed on the flagged expression's root identifier (unwrapping one level of a `|>` pipeline or an `Enum`/`Map`/`MapSet`/`Stream` call) searched backward through the whole enclosing test body — not a fixed line window — for a same-root cardinality pin or non-emptiness guard.
- Proved the ledger via `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` (18 tests): a clean `--check` run, byte-identical `--emit-snapshot` regeneration, both-directions completeness (mirroring Phase 169's `roster_exact`), two real-subprocess non-vacuity controls (a removed row and an added orphan, both proven to turn `--check` RED and name the affected site), all four VAC-01 edge cases (adjacency, empty tree, encoding stability, total ordering), and the D-14/D-24 measured-fact guard tests (`@audited_site_count`, `@shape_counts`, `@bucket_counts` pinned as literals).
- Recorded VACG-01's sunset step (lift the detection core into the future merge-blocking guard, then delete the script, the snapshot, the future remediation manifest, and this proof test) in three places: `REQUIREMENTS.md`'s VACG-01 bullet, the script's own header comment, and the committed snapshot's `sunset` field.

## Task Commits

1. **Task 1: End-to-end "one real subset classified, committed, and provably diffed"** - `d62d539e` (feat)
2. **Task 2: Widen the scan to the full audited population and classify every row** - `50663659` (feat)
3. **Task 3: Record the ledger's sunset trigger and the non-expansion dispositions** - `8b03d32b` (docs)

**Plan metadata:** (this commit)

## Files Created/Modified

- `script/inventory_collection_assertions.exs` - Regenerable classifier; five-bucket D-07 logic, root-identifier backward scan, CLI, JSON snapshot renderer
- `script/collection_assertion_ledger.json` - Committed snapshot, 220 rows, `scope: "test/**/*.exs"`
- `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` - 18 tests: completeness, non-vacuity, edge cases, measured-fact guards
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` - VACG-01's sunset step

## Decisions Made

- Used the Elixir 1.18+ stdlib `JSON` module instead of `Jason` for the script's own encode/decode, since a standalone `elixir script.exs` invocation has no Mix dependency path and this repo's own `phase169_diagnostic_legibility_test.exs` already establishes `JSON.decode!` as the idiom for this exact situation.
- Made `--check` and `--emit-snapshot` read their scope from the ledger file's own `"scope"` field when `--scope` is omitted, falling back to the tree-wide default only when no ledger exists yet. This is what lets Task 1's narrow release-critical snapshot and Task 2's full-tree snapshot both satisfy the plan's literal `elixir script/inventory_collection_assertions.exs --check` verify command with no flags, at either scope.
- Guard/pin detection scans backward through the WHOLE enclosing test body for a same-root match, not a fixed 6-line window as CONTEXT.md's heuristic description suggested — a multi-line list-literal pin (e.g. `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:44`) can begin many lines above the assertion it guards, and a guard shared by two consecutive assertions on the same collection (`test/crosswake/doctor/doctor_test.exs:1451-1452`) must be found for both, not just the first.
- Added one explicit, cited manual override (`test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:92`) for a site whose cardinality pin asserts a differently-named field (`assertion_ids`) than the flagged expression's own identifier (`assertions`) — the same underlying collection surfaced under two field names on one struct, a fact no text-only scanner can infer. This follows D-07's "classification is mechanically bucketed first; humans write rationale only for the residual" instruction literally: the override's rationale explains WHY the heuristic can't reach it, not just what the answer is.

## Deviations from Plan

None - plan executed as written, with the scope-inheritance behavior and unbounded-backward-scan design decided under "Claude's Discretion" per the plan's explicit grant (concrete normalization, serialization, and detection-window choices).

## Reconciliation Against the Grep Total (Task 2 requirement)

- **Committed ledger:** 220 rows, `scope: "test/**/*.exs"` (exactly `170-CONTEXT.md`'s verified ground truth: 42 `assert_all` + 131 `assert_any` + 47 `refute_any` + 0 `refute_all`).
- **Raw grep on this tree today:** `grep -rnE 'assert Enum\.(all\?|any\?)' test --include='*.exs' | wc -l` → **179**; `grep -rnE 'refute Enum\.any\?' test --include='*.exs' | wc -l` → **47**. Raw total: **226**.
- **Delta: 226 − 220 = 6, all six excluded, all in one file.** `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` (created by this plan's own Task 1) contains six `assert Enum.all?(...)` occurrences inside its own fixture heredoc strings (lines 166, 167, 226, 238, 272, 284 as of this commit — the adjacency/encoding-edge test fixtures). Raw grep has no notion of a heredoc fixture and counts them as real source; the scanner's `strip_heredocs/1` correctly excludes them, since they are DATA describing a call site inside a synthetic test fixture, not a real call site in this repository's own test suite. This is proven by a dedicated test (`test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs#Task 2 ... reconciliation`) that re-derives the raw grep count at test time and asserts the delta names exactly these six lines — the delta is measured and named, never absorbed silently.
- No other delta exists: the audited population (220) matches `170-CONTEXT.md`'s pre-Task-1 verified ground truth exactly, before this plan's own new test file existed.

## Issues Encountered

None. One subtlety worth recording for the next reader: two `Regex.run/2` calls against patterns with a capturing group returned `[full_match, group]` rather than `[full_match]`, which raised `CaseClauseError` in `extract_root/1` on first execution against the full tree (visible immediately on real data, since the narrow Task 1 scope happened not to exercise either capturing branch). Fixed inline as a Rule 1 bug (pattern `[matched | _groups] -> matched` instead of `[matched] -> matched`) before Task 2's commit — not a deviation from the plan, a normal implementation bug caught by running the script against real data before committing.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 170-02 (VAC-02 rewrites) can read this plan's committed `needs-fix` rows directly from `script/collection_assertion_ledger.json` as its fixed population — per the plan's own instruction, do not hand-type a second copy of that list.
- Plan 170-03 (VAC-03 taxonomy checklist mechanism) is independent of this plan's artifacts and can proceed in parallel.
- No merge-blocking guard and no required-check registration was added — `script/inventory_collection_assertions.exs` is deliberately absent from `script/check_absence_is_not_success.exs` and any required-check registry (D-13), confirmed by the empty `git diff --stat` over those files plus `.github/workflows/` and `lib/`.

## Self-Check: PASSED

- All key files confirmed present on disk (`script/inventory_collection_assertions.exs`, `script/collection_assertion_ledger.json`, `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`, this SUMMARY).
- All three task commits (`d62d539e`, `50663659`, `8b03d32b`) confirmed present in `git log`.
- Re-ran all acceptance criteria across all three tasks: PASS.
- Re-ran the plan-level `<verification>` block: `elixir script/inventory_collection_assertions.exs --check` → exit 0, `[crosswake] OK: 220 classified collection-assertion site(s)`; `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` → 18 tests, 0 failures; `git diff --stat 817102b0744080d12338c26d9c488e90f6cc3dc2..HEAD -- script/check_absence_is_not_success.exs script/required_check_policy.json .github lib` → empty, exit 0.

---
*Phase: 170-vacuous-assertion-remediation*
*Plan: 01*
*Completed: 2026-09-16*
