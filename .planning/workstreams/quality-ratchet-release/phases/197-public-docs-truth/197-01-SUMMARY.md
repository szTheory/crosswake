---
phase: 197-public-docs-truth
plan: 01
subsystem: docs-tooling
tags: [docs-report, leak-counter, link-checker, mix-test-gate, exunit-fixtures]

requires:
  - phase: 196-spec-and-structure-ratchet
    provides: absence-is-not-success guard and the bearings-report script shape this plan copies
provides:
  - script/docs-report, a report-only checker (leak counter and relative link/anchor counter) over the mix.exs extras
  - script/docs_leak_allowlist.json, schema-validated, zero entries
  - script/mix_test_gate.sh, the shared mix test gate every later gate in this phase runs through
  - phase branch docs/197-public-docs-truth cut from current origin/main with the planning commits carried over
affects: [197-02, 197-03, 197-04, 197-05, 197-06, 197-07, 197-08, 197-09, 197-10, 197-11, 197-12, 197-13, 197-14, 197-15]

actuals:
  tokens: 9468
  tasks: 3
  commits: 3
plan_head_before: ebc2db6ed22003339c41b953215777f59a5cb744
plan_head_after: 9066d0ab498dd91ff6b07294fa5a2c4739eb5a1d

tech-stack:
  added: []
  patterns:
    - "UNVERIFIED-never-zero: an unread, empty or under-scanned input prints a fixed reason atom and exits 2"
    - "deps-map seam (read, exists?, run, scan) so fixture tests need no network and can prove a scan floor"
    - "gate on captured output: mix test to a file with no pipe, parse the ExUnit summary, assert nonzero count and zero failures"

key-files:
  created:
    - script/docs-report
    - script/docs_report.exs
    - script/docs_leak_allowlist.json
    - test/crosswake/docs_report_test.exs
    - script/mix_test_gate.sh
    - test/crosswake/mix_test_gate_test.exs
  modified: []

key-decisions:
  - "Leak patterns carry a leading word boundary (\\bPhase, \\bTODO-, \\bD-NN, \\bSEED-) so SEED-12 is one SEED hit and not also a D-12 hit"
  - "Allowlist suppresses by exact file plus normalized line; allowlisted= counts suppressed hits, stale_allowlist= counts entries that matched nothing"
  - "A scan that touches fewer files than the parsed .md extras is UNVERIFIED reason=scan_floor for both the leaks and links lines"

patterns-established:
  - "Mutation controls assert the mutated input differs from its source"
  - "Before refute Enum.any?(lines, ...), assert lines != [] so the repo's collection-assertion ratchet sees a non-vacuous collection"

requirements-completed: [DOCS-03]

coverage:
  - id: D1
    description: "script/docs-report prints docs.leaks and docs.links counters over the mix.exs extras, report-only, exit 0 or 2, never 1"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/crosswake/docs_report_test.exs (28 tests, counters, scan floor, UNVERIFIED reasons)"
        status: pass
      - kind: integration
        ref: "script/docs-report --detail on the repo: leaks files=30, links checked=232 files=30, exit 2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Allowlist schema validation: wrong schema_version, missing entries, malformed entries are UNVERIFIED allowlist_invalid"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/crosswake/docs_report_test.exs describe allowlist schema (6 controls plus 1 positive)"
        status: pass
    human_judgment: false
  - id: D3
    description: "script/mix_test_gate.sh grades mix test runs on captured output, a nonzero ran count and zero failures"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/crosswake/mix_test_gate_test.exs (13 tests, stub mix)"
        status: pass
      - kind: integration
        ref: "real-output positive, below_min and no-match controls run through script/mix_test_gate.sh"
        status: pass
    human_judgment: false

duration: 70min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 01: docs-report and the shared mix test gate Summary

**Report-only `script/docs-report` counts planning leaks and broken relative links over the `mix.exs` extras, treats every unread or under-scanned input as UNVERIFIED (exit 2), and ships with a tested `mix test` gate helper that no longer trusts an exit code alone.**

## Performance

- **Duration:** about 70 min
- **Completed:** 2026-11-05
- **Tasks:** 3 (1 tracer, 2 auto/tdd)
- **Files created:** 6

## Accomplishments

- Phase branch `docs/197-public-docs-truth` cut from current `origin/main` (ancestry check exits 0, non-`.planning` diff against `origin/main` empty). The 14 `.planning/`-only phase-197 commits were cherry-picked oldest first; all 15 PLAN files and the rest of the phase directory arrived byte-identical. The user's uncommitted `.planning/config.json` change is still an uncommitted working-tree change and was never staged, stashed or committed.
- `script/docs-report` runs end to end on the real repo. Tracer result (before any doc edit, branch tip at plan start): `docs.leaks hits=95 allowlisted=0 stale_allowlist=0 files=30`, `docs.links broken=0 checked=232 files=30`, `docs.warnings UNVERIFIED reason=not_measured` (filled by 197-02), exit 2. These are scratch observations from this plan, not the D-19 baseline record, which 197-02 takes.
- Scope is parsed from `mix.exs` `extras:` (AST walk inside `docs/0`, no evaluation); the 31 extras give 30 scanned `.md` files (LICENSE counted but not scanned).
- Absence rule enforced by fixtures: empty extras or missing `mix.exs` (`no_extras`), an unreadable listed extra (`unreadable_extra`), a `scan` seam that drops a file (`scan_floor`, with a default-scan positive pair), a missing allowlist (`allowlist_unreadable`), and six malformed-allowlist controls plus a positive control (`allowlist_invalid`) all print an UNVERIFIED line, no `hits=` line, and exit 2.
- `script/mix_test_gate.sh` (bash, sed, grep, rm only): captured output with no pipe, last real ExUnit summary parsed, PASS only on mix rc 0, a summary found, zero failures and invalid, and ran/total at their floors. Real-output controls: PASS on the 19-test docs report file, `reason=below_min` at `--min 9999`, `reason=mix_rc` for a path that matches no test file.

## Task Commits

1. **Task 1: tracer, docs-report with leak counter** - `71f51d94` (feat)
2. **Task 2: shared mix test gate helper** - `b7eb6333` (chore)
3. **Task 3: relative link and anchor counter** - `9066d0ab` (feat)

The branch and cherry-pick step of Task 1 produced no commit of its own beyond the 14 carried planning commits.

## Verification Run

- `test/crosswake/docs_report_test.exs`: 28 tests, 0 failures (floor 23). `test/crosswake/mix_test_gate_test.exs`: 13 tests, 0 failures (floor 13). Combined run through the gate: 41 tests, verdict PASS.
- `test/crosswake/proof/absence_is_not_success_test.exs` through the gate: 59 tests, PASS (no new absence-guard finding after the fix below).
- `mix format --check-formatted` clean on all changed Elixir files. `grep -rl "docs-report\|docs_report\|mix_test_gate" .github/workflows` prints nothing.
- Real-repo output has exactly one `reason=not_measured` line (warnings) and one `docs.links` line matching the required shape with `files=30`.

## Decisions Made

- Leak regexes gained a leading `\b`; see Deviations.
- `--detail` lines carry the line text of the shipped public docs, never line numbers (BEARINGS line-number tripwire).
- `render([])` of an empty report is UNVERIFIED, so an empty result can never read as clean.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Collection-assertion ratchet flagged the new test file**
- **Found during:** Task 1 verify (`absence_is_not_success_test.exs` reported 2 failures)
- **Issue:** `refute Enum.any?(lines, ...)` on a collection never proven non-empty is an `unsafe_collection` finding, which moved the reviewed multiset (delta above 0).
- **Fix:** `assert lines != []` immediately before each such refute.
- **Files modified:** `test/crosswake/docs_report_test.exs`
- **Verification:** absence test re-run through the gate: 59 tests, 0 failures
- **Committed in:** `71f51d94` (fixed before the Task 1 commit)

**2. [Rule 1 - Bug] Leak patterns double counted `SEED-NN`**
- **Found during:** Task 1 design check of the plan's literal patterns
- **Issue:** the plan's `D-[0-9]{2}` also matches inside `SEED-12`, so one SEED label would count as two hits.
- **Fix:** a leading `\b` on the `Phase`, `TODO-`, `D-NN` and `SEED-` patterns. The milestone pattern already had one. Counts for every plan-listed fixture line are unchanged.
- **Files modified:** `script/docs_report.exs`
- **Committed in:** `71f51d94`

**Total deviations:** 2 auto-fixed (both Rule 1). **Impact:** none on scope; the first keeps the repo's own ratchet green, the second keeps the counter exact.

## Process Notes (not deviations)

- The first cherry-pick attempt passed all commit hashes as one argument (zsh does not word-split an unquoted variable) and picked nothing; the branch was still at `origin/main`, so the loop was simply re-run commit by commit. No state was lost.
- The new branch inherited `origin/main` as its upstream; the upstream was unset so a bare push cannot target `main`.
- The new test file triggers two compile warnings (`Crosswake.DocsReport` undefined at test compile time), the same library-mode load pattern `bearings_report_test.exs` uses; they do not affect results.

## Known Stubs

None. The `docs.warnings UNVERIFIED reason=not_measured` line is an intentional, honest state of an unmeasured counter that 197-02 fills; it is not a hidden zero.

## Threat Flags

None. No new network endpoint, auth path or file-access surface; the report reads only repo files and prints counts, fixed reason atoms and (with `--detail`) lines from shipped public docs.

## Self-Check: PASSED

- FOUND: script/docs-report, script/docs_report.exs, script/docs_leak_allowlist.json, script/mix_test_gate.sh, test/crosswake/docs_report_test.exs, test/crosswake/mix_test_gate_test.exs
- FOUND commits: 71f51d94, b7eb6333, 9066d0ab (all ancestors of HEAD)
- `.planning/config.json` still shows an uncommitted modification and is absent from every commit on the branch.
