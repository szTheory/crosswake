---
phase: 169-diagnostic-legibility
plan: 02
subsystem: infra
tags: [elixir, exunit, ci-diagnostics, release-status, exit-codes]

# Dependency graph
requires:
  - phase: 169-01
    provides: the ROSTER/DONE stdout protocol and release.workflow_integrity owner check this plan classifies crashes on top of
provides:
  - "`:unverifiable` as a first-class status wired through both `Crosswake.ReleaseStatus.aggregate_status/1` and `exit_code/1` in the same change, with the fail-open catch-all `def exit_code(_status), do: 0` closed for this atom (FID-02, D-13)."
  - "Two distinguishable scanner crash-shape classifications — `scanner did not start` (no ROSTER line) vs `scanner terminated early` (ROSTER present, DONE absent or incomplete) — each with a bounded stderr excerpt (T-169-04) and routing every dependent check to `:unverifiable`, never `:ok` (D-03/D-08)."
  - "`mix crosswake.release.status` can reach real OS exit 3 via `exit({:shutdown, 3})`, with a D-17 `[crosswake] FAIL (exit 1)` / `[crosswake] UNVERIFIED (exit 3)` summary block appended to `render/1`'s output."
affects: [169-03, 169-04, release-status, ci-diagnostics]

# Actuals (#2632)
actuals:
  tokens: 9660
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Total precedence order encoded as an ordered cond/case chain (:error > :unverifiable > :warning > :ok), asserted with exact-integer exit codes rather than != 0"
    - "Crash-shape classification driven by a positive completion assertion (DONE line) rather than inferred from absence"
    - "Cascade-pointer messaging: a dependent check that could not evaluate names WHY (cause:) rather than just THAT it could not"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/deferred-items.md
  modified:
    - lib/crosswake/release_status.ex
    - lib/mix/tasks/crosswake.release.status.ex
    - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
    - test/mix/tasks/crosswake_release_status_test.exs
    - test/crosswake/proof/phase168_release_version_weld_test.exs

key-decisions:
  - "Both crash shapes (:unavailable — scanner never started; :unverifiable — scanner terminated early) route the always-emitted release.workflow_integrity owner check AND the five scoped scanner_check/7 results to the SAME check-status :unverifiable, never :error. An :error owner check would outrank :unverifiable in aggregate_status/1's precedence and silently force exit 1 on a crash instead of exit 3 — the opposite of what exit 3 exists to communicate. This is a necessary generalization beyond the plan's literal per-evidence-status wording, required by the plan's own Task 3 behavior (\"the crash fixture terminates the OS process with exit status 3\")."
  - "Updated the two schema_version==\"1.1.0\" assertions in crosswake_release_status_test.exs to 1.2.0 — the plan's own Task 1 <files> list scopes this file for editing, and bumping @schema_version to 1.2.0 is Task 1's own explicit acceptance criterion."
  - "The top-level 'status: <atom>' render/1 line now routes through status_label/1 (not just per-check lines) — the plan's prohibition that ':unverifiable' must never be printed as a word applies repo-wide in rendered output, not only to check lines."

requirements-completed: [FID-02, MSG-02]

coverage:
  - id: D1
    description: "Crosswake.ReleaseStatus.exit_code(:unverifiable) returns exactly 3, textually above the catch-all, wired in the same change as aggregate_status/1's new branch."
    requirement: FID-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#Task 1: :unverifiable is first-class in aggregate_status/1 and exit_code/1 (FID-02, D-13) (9 tests)"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake_release_status_test.exs#exit behavior is non-fatal for ok and warning, fatal for error, and strict for args"
        status: pass
    human_judgment: false
  - id: D2
    description: "A confirmed defect and a could-not-run check both surface with neither masked, and a confirmed defect outranks an unknown (exit 1, not 3)."
    requirement: FID-02
    verification:
      - kind: integration
        ref: "manual verification: RELEASE_PLEASE_CONFIG_PATH pointed at a missing path produced exit 3 with 6 UNVERIFIED checks + 3 OK checks; a drifted manifest produced exit 1 with the FAIL block"
        status: pass
    human_judgment: false
  - id: D3
    description: "aggregate_status([]) returns :unverifiable, never :ok; precedence is total and order-independent."
    requirement: FID-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#aggregate_status([]) returns :unverifiable — nothing verified is not clean"
        status: pass
    human_judgment: false
  - id: D4
    description: "A scanner crash before any ROSTER line reports 'scanner did not start' (:unavailable); a crash after the ROSTER line reports 'scanner terminated early' (:unverifiable); a ROSTER+full-emission run with no DONE line still classifies as :unverifiable, not :ok."
    requirement: MSG-02
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#Task 2: the two crash shapes classify distinctly and cascade loudly (D-03, D-08) (5 tests)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Under either crash shape, the five scoped scanner_check/7 results carry the cascade-pointer message and status :unverifiable, never :ok and never a status mapping to exit 0."
    requirement: MSG-02
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#the crash-before-roster and roster-then-crash fixtures (2 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "mix crosswake.release.status terminates the real OS process with status 1 on a confirmed defect and status 3 on a could-not-verify, observed via a subprocess exit_status."
    requirement: FID-02
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#169-02 Task 3: the Mix task reaches OS exit 3, with D-17 microcopy (6 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "render/1's D-17 summary block prints FAIL (exit 1) / UNVERIFIED (exit 3) microcopy, with 'Do not read exit 3 as a pass.' on the exit-3 path, and no hardcoded check-count literal."
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#the drifted-manifest and crash fixture subprocess tests"
        status: pass
    human_judgment: false

# Metrics
duration: 95min
completed: 2026-09-16
status: complete
---

# Phase 169 Plan 02: Exit-Code Vocabulary and Crash-Shape Legibility Summary

**`mix crosswake.release.status` now answers "I could not verify this" as a distinct, exit-3 outcome — wired through `aggregate_status/1` and `exit_code/1` in one change, with the scanner's two crash shapes classified and cascaded so no check that couldn't run is ever mistaken for a pass.**

## Performance

- **Duration:** 95 min
- **Started:** 2026-09-16T14:05:00Z
- **Completed:** 2026-09-16T15:40:00Z
- **Tasks:** 3
- **Files modified:** 5 (1 created, 5 modified — one via a scoped deviation fix)

## Accomplishments

- `:unverifiable` is a first-class status: `aggregate_status/1` gained a new branch
  (precedence `:error > :unverifiable > :warning > :ok`) and returns `:unverifiable` for an empty
  check list; `exit_code/1` gained `exit_code(:unverifiable) -> 3` textually above the fail-open
  catch-all `def exit_code(_status), do: 0`, in the same commit. `status_label/1` keeps the
  internal atom off every rendered surface — the human word is `UNVERIFIED`. `@schema_version`
  bumped `1.1.0` -> `1.2.0`.
- The scanner's two crash shapes are now distinguished by 169-01's ROSTER/DONE lines: no ROSTER at
  all is `scanner did not start: no roster line emitted (exit <n>)` (`:unavailable`); a ROSTER
  observed with DONE absent or fewer OK/FAIL lines than the roster declares is
  `scanner terminated early: <emitted> of <roster> roster checks ran (exit <n>)` (`:unverifiable`)
  — DONE's absence is treated as non-completion even when every emitted line looks clean. Both
  crash messages embed a stderr excerpt bounded to 500 characters with a `…(truncated)…` marker
  (T-169-04). Under either shape, the always-emitted `release.workflow_integrity` owner check and
  all five scoped `scanner_check/7` results carry status `:unverifiable` with the literal cascade
  pointer `not evaluated — the scanner stopped before these gates ran (cause: <cause>). This is not
  a pass.` — never `:ok`, and never a status mapping to exit 0. A required ID genuinely absent from
  the ROSTER still routes to `:error` (unchanged, latent-bug hardening from 169-01).
- `Mix.Tasks.Crosswake.Release.Status` replaced its binary `!= 0` check with a three-way
  `case` reaching real `exit({:shutdown, 3})` for the could-not-verify path (never
  `System.halt/1`). `render/1` gained a D-17 summary block appended after every existing section:
  a `[crosswake] FAIL (exit 1): ...` paragraph naming each blocking issue, an
  `[crosswake] UNVERIFIED (exit 3): ...` paragraph naming each check that could not run plus
  `Do not read exit 3 as a pass.`, and both blocks together — nothing masked — when a defect and an
  unknown are both present. Verified live: a real drifted-manifest run exits exactly 1, a real
  crash fixture exits exactly 3, and a clean run exits exactly 0.

## Task Commits

Each task was committed atomically:

1. **Task 1: `:unverifiable` first-class in BOTH `aggregate_status/1` and `exit_code/1`** - `562b21ea` (feat)
2. **Task 2: Classify the two crash shapes and make dependent checks loudly non-passing** - `f2b3824e` (feat)
3. **Task 3: Make the Mix task able to reach OS exit 3, with D-17 microcopy** - `b6899fc8` (feat, includes the deviation fix below)

## Files Created/Modified

- `lib/crosswake/release_status.ex` - `:unverifiable` in aggregate_status/1 + exit_code/1, `status_label/1`, crash classification (`classify_workflow_integrity_output/2`, `bounded_stderr_excerpt/1`, `done_line_present?/1`), cascade-pointer plumbing (`scanner_ids_result/2`, `workflow_integrity_owner_check/1`, `unverifiable_cause/1`), `render/1`'s D-17 `summary_block/1`, `@schema_version` bump
- `lib/mix/tasks/crosswake.release.status.ex` - three-way exit-code `case`, `exit({:shutdown, 3})`, exit-contract header comment and `@moduledoc` pointer
- `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` - 20 new tests across Task 1 (exit-code/aggregate wiring), Task 2 (crash-shape classification via real subprocess + mutated-script cwd mirroring), Task 3 (subprocess OS exit-status proof for clean/drifted/crash fixtures)
- `test/mix/tasks/crosswake_release_status_test.exs` - schema_version assertions bumped to `1.2.0`, `exit_code(:unverifiable) == 3` added alongside the existing exact-integer assertions
- `test/crosswake/proof/phase168_release_version_weld_test.exs` - deviation fix (see below)
- `.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/deferred-items.md` - new, logs 2 unrelated pre-existing failures found by this plan's full-suite verification step

## Decisions Made

- Routed BOTH crash-evidence statuses (`:unavailable` and `:unverifiable`) to the SAME check-level
  `:unverifiable` outcome for the owner check and all five scoped checks — see key-decisions in
  frontmatter for the full reasoning (an `:error` owner check would outrank `:unverifiable` in
  `aggregate_status/1`'s precedence and silently force exit 1 on a crash).
- Bumped the two `schema_version == "1.1.0"` assertions in `crosswake_release_status_test.exs` to
  `1.2.0` rather than treating them as locked — the file is explicitly in Task 1's `<files>` list
  and the schema bump is Task 1's own acceptance criterion.
- Routed the top-level `render/1` status line through `status_label/1` as well as per-check lines,
  since the plan's prohibition on printing the bare `:unverifiable` atom is repo-wide, not
  check-line-scoped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed `line_for/2`'s substring match colliding with 169-01's new ROSTER line**
- **Found during:** this plan's own `mix test` (full suite) verification step
- **Issue:** `test/crosswake/proof/phase168_release_version_weld_test.exs`'s `line_for/2` helper
  located a check's result line via `String.contains?(line, id)`. 169-01 added an additive
  `[crosswake] ROSTER: <count> <comma-joined ids>` line that lists every declared check ID,
  including `release.version_weld.gates_match_declared_version` — since the ROSTER line prints
  before any OK/FAIL line and also contains that ID as a substring, `Enum.find/2` now returned the
  ROSTER line instead of the actual result line, failing 5 of 6 tests in the file. Confirmed
  pre-existing (present on `main` before this plan's own changes, introduced by 169-01) via
  `git stash` against the committed baseline.
- **Fix:** Match the real `[crosswake] (OK|FAIL): <id> - ` line shape instead of a bare ID
  substring — the same consumer contract `release_status.ex`'s own parser depends on.
- **Files modified:** test/crosswake/proof/phase168_release_version_weld_test.exs
- **Verification:** `mix test test/crosswake/proof/phase168_release_version_weld_test.exs` — 0
  failures (6 tests, was 5 failures before the fix)
- **Committed in:** b6899fc8 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — pre-existing regression from a sibling plan, surfaced
by this plan's own full-suite verification gate).
**Impact on plan:** Necessary for this plan's own explicit `<verification>` requirement
("`mix test` (full suite) green before the wave closes"). No scope creep — the fix is scoped to the
exact substring-match bug in the one file it broke.

## Issues Encountered

Two unrelated, pre-existing full-suite failures remain and are OUT OF SCOPE for this plan (logged
to `deferred-items.md`):
- `test/crosswake/planning/milestone_transition_reset_test.exs` — `REQUIREMENTS.md`'s header does
  not name the active v23.0 milestone.
- `test/crosswake/proof/phase135_ci_ops_proof_test.exs` — its dependent
  `milestone_transition_reset` deferred-proof assertion, which reruns the above test as a
  subprocess.

Both are confirmed pre-existing via `git stash` against the committed baseline before any 169-02
change, and are unrelated to `lib/crosswake/release_status.ex`, the Mix task, or the scanner's
ROSTER/DONE protocol this plan touches. `mix test` (full suite) therefore reports 2 failures, not
0 — both attributable to project-state bookkeeping (`REQUIREMENTS.md`'s milestone header) outside
this plan's task list, not to any 169-02 change.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `:unverifiable`/exit-3 vocabulary, `status_label/1`, and the D-17 summary-block pattern in
  `render/1` are stable for 169-03/169-04 (and any future status atom) to build on.
- The two crash-shape classifications and the `cause:` cascade-pointer field are available to any
  future check that depends on scanner evidence.
- Deferred: the REQUIREMENTS.md milestone-header failures above are not blocking for this plan but
  should be addressed before milestone completion (see `deferred-items.md`).

## Self-Check: PASSED

- FOUND: lib/crosswake/release_status.ex
- FOUND: lib/mix/tasks/crosswake.release.status.ex
- FOUND: test/crosswake/proof/phase169_diagnostic_legibility_test.exs
- FOUND: test/mix/tasks/crosswake_release_status_test.exs
- FOUND: test/crosswake/proof/phase168_release_version_weld_test.exs
- FOUND: .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/deferred-items.md
- FOUND commit: 562b21ea (Task 1)
- FOUND commit: f2b3824e (Task 2)
- FOUND commit: b6899fc8 (Task 3)
- Re-ran all `<acceptance_criteria>` across all three tasks: all pass. `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` — 35 tests, 0 failures.
- Re-ran the plan-level `<verification>`: `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` — 138 tests, 0 failures. `mix test` (full suite) — 1751 tests, 2 failures (both pre-existing/unrelated, see Issues Encountered). `release.live_registry_unverifiable` confirmed still `:error`/exit 1 via the locked assertions at `test/mix/tasks/crosswake_release_status_test.exs:241-243` (unchanged, still passing).

---
*Phase: 169-diagnostic-legibility*
*Completed: 2026-09-16*
