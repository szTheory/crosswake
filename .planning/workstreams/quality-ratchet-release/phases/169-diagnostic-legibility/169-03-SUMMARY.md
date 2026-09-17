---
phase: 169-diagnostic-legibility
plan: 03
subsystem: ci-diagnostics
tags: [python, bash, elixir, github-actions, ci-diagnostics, msg-06]

# Dependency graph
requires:
  - phase: 169-01
    provides: the diagnostic-legibility scanner substrate this plan's Python/shell checks sit
      alongside (independent artifacts, no direct code dependency)
provides:
  - A global duplicate-display-name scan in `list_merge_blocking_checks.py` that runs over EVERY
    job producer, not only names containing "merge-blocking"
    (`duplicate-producer/duplicate-display-name`)
  - A version-literal reject over job display names and `actions/upload-artifact` `with.name`
    values (`version-literal-in-display-name`)
  - Six renamed display names/artifact names (three release-please.yml jobs, two
    release-please.yml artifacts, one phase70-proof.yml job) landed atomically with the widened
    scan so `main` was never left red against its own tree
  - An explicit global-uniqueness branch in `check_required_checks_registered.sh` stating the
    same guarantee at the shell entry point, plus an exit-contract header comment
  - Fixture-based non-vacuity proof (11 tests) that each new assertion fires against a violating
    input and stays quiet against a clean one
affects: [170, 171, release-status, ci-diagnostics]

# Actuals (#2632)
actuals:
  tokens: 4500
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Extracted pure predicates (on_trigger_clean?/1, release_prefix_lowercase?/1) from
       assertions against live checked-in files, so a synthetic violating input can prove the
       predicate is capable of going red — not just currently true against a currently-clean
       file"
    - "Shell out to python3 -c with PyYAML (the already-declared parser) for structured workflow
       data in ExUnit tests, decoded via the already-present Jason dependency, rather than
       adding a new Elixir YAML library"

key-files:
  created:
    - test/crosswake/proof/phase169_check_name_uniqueness_test.exs
  modified:
    - script/list_merge_blocking_checks.py
    - script/check_required_checks_registered.sh
    - .github/workflows/release-please.yml
    - .github/workflows/phase70-proof.yml
    - test/crosswake/proof/phase153_1_gate_integrity_test.exs

key-decisions:
  - "Widened the duplicate scan by removing the `\"merge-blocking\" in record[0].lower()` guard
     from the duplicate-grouping path only. The unrelated substring filter in main()'s default
     `--contexts` selection (used by isolated fixture self-tests with no policy file) was left
     untouched per the plan's read_first note — it selects which records to PRINT in that mode,
     not which records get de-duplicated."
  - "Quoted the three renamed release-please.yml job names (`\"release: ...\"`) because the value
     itself contains a colon+space, which YAML would otherwise parse as the start of a new
     mapping key. The phase70-proof.yml rename needed no quoting (no colon in the value)."
  - "Added negative-fixture tests for the two Task 3 structural guards (on:-trigger keys,
     release: prefix casing) by extracting them into pure predicates and feeding each a synthetic
     violating input, rather than flagging them as unproven-by-fixture — the plan explicitly
     permits either honestly flagging or proving; proving was straightforward here."

requirements-completed: [MSG-06]

coverage:
  - id: D1
    description: "list_merge_blocking_checks.py's duplicate scan finds ANY duplicate display
      name, not only ones containing 'merge-blocking' (MSG-06, D-20)."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 2: duplicate reject fires on a collision without the substring 'merge-blocking'"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 2: duplicate reject does not over-fire on distinct names"
        status: pass
    human_judgment: false
  - id: D2
    description: "A version literal in a job display name or upload-artifact name is rejected
      (MSG-06, D-20/D-22)."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 2: version-literal reject fires on a job display name"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 2: version-literal reject fires on an upload-artifact name"
        status: pass
    human_judgment: false
  - id: D3
    description: "An empty workflow inventory never scores as clean; the real tree is proven
      clean under a >100-record floor (MSG-06 empty edge)."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 2: the real tree is clean under both widened assertions"
        status: pass
    human_judgment: false
  - id: D4
    description: "The one real display-name collision and all five version-literal offenders are
      renamed in one commit; required_check_policy.json and phase48-proof.yml are byte-unchanged;
      branch protection is never touched (D-18/D-21)."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "python3 script/list_merge_blocking_checks.py --producers (exit 0, 103 records, no diagnostic)"
        status: pass
      - kind: unit
        ref: "git diff -- script/required_check_policy.json .github/workflows/phase48-proof.yml (empty)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The shell entry point states the global-uniqueness guarantee independently of
      the Python exit code, and the renames-are-free argument (no pull_request trigger, single
      target context, release: prefix casing) is mechanically checked rather than asserted in
      prose (D-19/D-22/D-23)."
    requirement: MSG-06
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 2: the shell entry point's global-uniqueness branch fires independent of gh"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 3: on:-trigger guard fires on a synthetic trigger set with pull_request added"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase169_check_name_uniqueness_test.exs#Task 3: release: prefix rule fires on a synthetic name with uppercase after the prefix"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-09-16
status: complete
---

# Phase 169 Plan 03: Diagnostic Legibility — Duplicate/Version-Literal Rename Summary

**Widened `list_merge_blocking_checks.py`'s duplicate scan from a `"merge-blocking"`-substring
filter to a global check that finds any duplicate display name, added a version-literal reject
over job/artifact names, retired all six version-welded release identifiers in one atomic commit,
and proved every new assertion non-vacuous with 11 fixture-backed tests.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-16T13:46:00Z
- **Completed:** 2026-09-16T13:57:27Z
- **Tasks:** 3
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments

- `script/list_merge_blocking_checks.py`'s duplicate-grouping path no longer requires the string
  `"merge-blocking"` to appear in a display name — it groups and flags EVERY producer record,
  catching the one real collision (`advisory provider sandbox/device proof (storekit + play
  billing)`, produced by both `phase48-proof.yml` and `phase70-proof.yml`) that the old
  substring filter structurally could not see post-v22.0.
- The same traversal now rejects any job display name or `actions/upload-artifact` `with.name`
  matching `\d+\.\d+\.\d+` (`version-literal-in-display-name`), catching all three release job
  names and both release artifact names that were welded to `0.2.1`.
- All six renames landed in the SAME commit as the widened scan (D-21 atomicity):
  `release: approved-candidate merge guard`, `release: exact-public artifact proof`,
  `release: linked release rollup`, `exact-public-proof`, `linked-release-status` (all in
  `release-please.yml`), and `advisory provider device proof (play billing)`
  (`phase70-proof.yml`). Job IDs and `needs:` edges were untouched — only display strings moved.
- `script/check_required_checks_registered.sh` gained an explicit global-uniqueness branch over
  the local producer inventory and an `# exit contract: 0 clean / 1 defect found / 3 could not
  verify` header comment, so the guarantee is stated at the shell entry point independently of
  the Python exit code.
- 11 new tests in `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` prove each new
  assertion fires against a violating fixture and stays quiet against a clean one, including two
  extracted-predicate negative-fixture tests for the Task 3 structural guards (see Decisions).

## Task Commits

Each task was committed atomically:

1. **Task 1: Widen the scan and land all six renames in ONE commit** - `ae9b6651` (feat)
2. **Task 2: Prove each new assertion fires — fixture non-vacuity** - `22f0ff24` (test)
3. **Task 3: Confirm the renames changed no authority + non-vacuity ledger** - `ce0575d1` (test)

## Files Created/Modified

- `script/list_merge_blocking_checks.py` - Widened duplicate scan, added version-literal reject
  over job names and upload-artifact names
- `script/check_required_checks_registered.sh` - Global-uniqueness branch, exit-contract header
- `.github/workflows/release-please.yml` - Three job renames, two artifact renames
- `.github/workflows/phase70-proof.yml` - One job rename (disambiguates from phase48's storekit)
- `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` - New: 11 tests across duplicate
  reject, version-literal reject, real-tree cleanliness, shell-level uniqueness, and the two
  Task 3 structural guards
- `test/crosswake/proof/phase153_1_gate_integrity_test.exs` - Updated one pre-existing assertion
  to the renamed diagnostic identifier (see Deviations)

## Decisions Made

- Kept the substring filter in `main()`'s default `--contexts` selection path (used by isolated
  fixture self-tests with no policy file) untouched — it controls which records are PRINTED in
  that mode, an unrelated concern from the duplicate-grouping widened in Task 1.
- Quoted the three renamed release-please.yml job names because their values contain a literal
  colon+space (`release: ...`), which YAML would otherwise parse as a new mapping key.
- Extracted `on_trigger_clean?/1` and `release_prefix_lowercase?/1` as pure predicates so a
  synthetic violating input could prove each Task 3 structural guard is capable of going red,
  rather than flagging them as "unproven by fixture" per the plan's fallback option.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated a pre-existing test asserting the stale pre-widen diagnostic identifier**
- **Found during:** Task 2 (running the plan's required sibling-suite verification)
- **Issue:** `test/crosswake/proof/phase153_1_gate_integrity_test.exs`'s "negative control: the
  uniqueness assertion fails on two jobs sharing a name" test asserted the output contains the
  literal string `"duplicate-merge-blocking-name"`. Task 1's D-20 instruction explicitly renamed
  this diagnostic identifier to `duplicate-producer/duplicate-display-name`; the pre-existing
  test's hardcoded string is exactly the identifier this plan retired, so implementing D-20 as
  specified necessarily broke this assertion. The plan's own acceptance criterion ("pre-existing
  CI-policy and gate-integrity proof tests pass with no edits to those files") did not anticipate
  that this specific assertion hardcodes the exact string this plan renames.
- **Fix:** Updated the assertion to `assert out =~ "duplicate-producer/duplicate-display-name"`
  with a comment noting the Phase 169 rename. No other part of the test (fixture, file names,
  exit-code expectation) changed.
- **Files modified:** test/crosswake/proof/phase153_1_gate_integrity_test.exs
- **Verification:** `mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs` — 0
  failures (9 tests)
- **Committed in:** 22f0ff24 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — pre-existing test hardcoded the diagnostic string
this plan's explicit D-20 instruction renamed).
**Impact on plan:** Necessary to implement Task 1's explicit rename instruction. No scope creep —
the fix is scoped to the exact assertion string in conflict; the fixture, the two colliding
workflow files, and the rest of the test file are unchanged.

## Non-Vacuity Ledger (D-23)

Measured pre-fix findings on `main` before Task 1's edit, post-fix findings after, and the
fixture observed to make each new assertion fire:

| Assertion | Pre-fix findings | Post-fix findings | Fixture that fires it |
|---|---|---|---|
| Global duplicate reject (`duplicate-producer/duplicate-display-name`) | 1 collision (`advisory provider sandbox/device proof (storekit + play billing)`, phase48-proof.yml + phase70-proof.yml) | 0 | "Task 2: duplicate reject fires on a collision without the substring 'merge-blocking'" — two synthetic jobs sharing a non-"merge-blocking" name |
| Version-literal reject, job name (`version-literal-in-display-name`) | 3 offenders (`Guard exact approved 0.2.1 merge`, `Prove exact public 0.2.1 artifacts`, `Linked 0.2.1 release rollup`, all release-please.yml) | 0 | "Task 2: version-literal reject fires on a job display name" — synthetic job named `prove 1.2.3 thing` |
| Version-literal reject, artifact name (`version-literal-in-display-name`) | 2 offenders (`exact-public-proof-0.2.1`, `linked-release-status-0.2.1`, both release-please.yml) | 0 | "Task 2: version-literal reject fires on an upload-artifact name" — synthetic `upload-artifact` step named `proof-artifact-9.9.9` |
| Shell global-uniqueness branch (`check_required_checks_registered.sh`) | N/A — branch did not exist before this plan; would have caught the same 1 collision above once introduced | 0 (real tree, `--local-only`) | "Task 2: the shell entry point's global-uniqueness branch fires independent of gh" — two synthetic jobs sharing a display name, run through the checker with `CROSSWAKE_REQUIRED_CHECKS_JSON` so no `gh` call is made |
| `on:`-trigger guard (release-please.yml has no `pull_request` key) | N/A — assertion did not exist before this plan | 0 (real file: keys are exactly `push`, `workflow_dispatch`) | "Task 3: on:-trigger guard fires on a synthetic trigger set with pull_request added" — synthetic trigger map with `pull_request` added, proving the extracted `on_trigger_clean?/1` predicate can return false |
| `release: ` prefix rule (D-22 casing convention) | N/A — assertion did not exist before this plan | 0 (3 real names examined, all lowercase after the prefix) | "Task 3: release: prefix rule fires on a synthetic name with uppercase after the prefix" — synthetic name `release: Exact-Public Artifact Proof`, proving the extracted `release_prefix_lowercase?/1` predicate can return false |

All six rows have an observed fixture that flips the assertion — none are flagged as
unproven-by-fixture.

## Six-Shape Vacuity Taxonomy Review

Per-shape review of the six new assertions above against
`.planning/research/v23/PITFALLS.md`'s taxonomy:

| Shape | Applies to any new assertion? | Result |
|---|---|---|
| A — bare `Enum.all?`/`Enum.any?` on a possibly-empty collection | Yes, structurally: the "real tree is clean" test and the "release: prefix rule" test both iterate/assert over a collection that COULD be empty | **Mitigated.** The real-tree test asserts `length(lines) > 100` before trusting the absence of diagnostics; the prefix-rule test asserts `length(prefixed_names) > 0` before trusting the per-name loop. Neither can pass on an empty collection. |
| B — a job `needs:` something that silently skipped | No | **N/A.** None of the six new assertions are GitHub Actions jobs with `needs:` dependencies; they are inline checks inside existing unconditional job steps or ExUnit tests. |
| C — `continue-on-error` on a lane feeding a one-way door | No | **N/A.** None of the new assertions run under `continue-on-error`; all three source locations (`list_merge_blocking_checks.py`'s `inventory()`, the shell script's global-uniqueness branch, the ExUnit tests) execute unconditionally and propagate a non-zero/failing result. |
| D — `if:` conditions that silently never match | No | **N/A.** The Python and shell checks are unconditional in their traversal; no `if:` gates any of the six new assertions. |
| E — a matrix expanding to zero entries | No | **N/A.** No `strategy.matrix` is involved in any of the six new assertions. |
| F — missing `set -e` / misused `grep -q` / `jq -e` | No | **N/A / reviewed clean.** The shell global-uniqueness branch uses `awk`/`sort`/`uniq -d` (no `grep -q` or `jq -e`) and inherits the file's existing `set -euo pipefail`. No misuse identified. |

## Issues Encountered

None beyond the deviation above. One unrelated pre-existing test failure was observed and left
untouched: `test/crosswake/proof/phase135_ci_ops_proof_test.exs`'s "deferred core-hermetic
failures are now green: milestone_transition_reset" fails because
`test/crosswake/planning/milestone_transition_reset_test.exs` asserts REQUIREMENTS.md names the
active milestone `"v23.0 Release Pipeline Repair & Proof-Lane Truth"`. Confirmed pre-existing via
`git stash` before any of this plan's edits — out of scope for this plan (no file this plan
touches is involved), logged here rather than fixed per the scope-boundary deviation rule.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `duplicate-producer/duplicate-display-name` and `version-literal-in-display-name` are now
  stable diagnostic identifiers future phases (170, 171) can rely on when auditing or extending
  workflow display-name authority.
- The `release: <subsystem-noun> <role>` naming convention is now both documented (via the
  version-literal reject's fix sentence) and mechanically checked (the `release: ` prefix
  casing test) for `release-please.yml`.
- No blockers. Branch protection, `script/required_check_policy.json`, and
  `.github/workflows/phase48-proof.yml` were never touched, per D-18.

## Self-Check: PASSED

- FOUND: script/list_merge_blocking_checks.py
- FOUND: script/check_required_checks_registered.sh
- FOUND: .github/workflows/release-please.yml
- FOUND: .github/workflows/phase70-proof.yml
- FOUND: test/crosswake/proof/phase169_check_name_uniqueness_test.exs
- FOUND: test/crosswake/proof/phase153_1_gate_integrity_test.exs
- FOUND commit: ae9b6651 (Task 1)
- FOUND commit: 22f0ff24 (Task 2)
- FOUND commit: ce0575d1 (Task 3)
- Re-ran all `<acceptance_criteria>` across all three tasks: all pass.
- Re-ran the plan-level `<verification>`: `python3 script/list_merge_blocking_checks.py
  --producers` exits 0 with 103 records, no diagnostic on stderr; `bash
  script/check_required_checks_registered.sh --local-only` exits 0; `mix test
  test/crosswake/proof/phase169_check_name_uniqueness_test.exs` — 11 tests, 0 failures; `mix test
  test/crosswake/proof/phase153_1_gate_integrity_test.exs test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs test/crosswake/proof/phase165_ci_policy_test.exs`
  — 0 failures; `git diff -- script/required_check_policy.json .github/workflows/phase48-proof.yml`
  is empty.

---
*Phase: 169-diagnostic-legibility*
*Completed: 2026-09-16*
