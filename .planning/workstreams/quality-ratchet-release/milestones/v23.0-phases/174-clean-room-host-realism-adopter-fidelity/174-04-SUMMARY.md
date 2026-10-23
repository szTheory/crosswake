---
phase: 174-clean-room-host-realism-adopter-fidelity
plan: 04
subsystem: release-infra
tags: [github-actions, workflow-dispatch, clean-room, hex, ci, exunit]

requires:
  - phase: 174-01
    provides: LEGACY_STEP_MARKERS (nine-name step= roster) and legacy_step_marker() in
      script/verify_companion_cleanroom.sh, plus the committed local real-run log this plan reads
      for directional (non-scored) context.
provides:
  - .github/workflows/clean-room-proof-rehearsal.yml — an on-demand workflow_dispatch door onto
    the exact clean-room proof invocation the release lane runs, for any published companion
  - Crosswake.Proof.Phase174CleanRoomLaneParityTest — pins the rehearsal's package roster to
    release-please.yml's clean-room-proof-* lane, keyed on the harness invocation itself
  - A real, verbatim-recorded CI dispatch refusal for the not-yet-merged rehearsal workflow, and
    a real captured matrix-path CI log with its step= marker roster measured
affects: [174-05, 174-06]

actuals:
  tokens: 130721
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Omit-the-argument-vs-pass-empty-string distinction for shell positional defaults: a
      workflow_dispatch step that wants to hand the underlying script's own sentinel-default
      behavior through must conditionally OMIT an optional trailing positional argument when its
      input is blank, not pass it through as an empty string — the two are semantically
      different once a script disambiguates \"argument absent\" ($#) from \"argument empty\"."

key-files:
  created:
    - .github/workflows/clean-room-proof-rehearsal.yml
    - test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-CLEANROOM-EVIDENCE.md
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-matrix-ci-run.log
  modified: []

key-decisions:
  - "The rehearsal step builds its argument list conditionally in bash (ARGS=(...); if
    non-empty, append engine args) rather than always passing four positional arguments. Passing
    an explicit empty string as $3 would force script/verify_companion_cleanroom.sh's NO_ENGINE
    override branch regardless of package, which would silently break the rulestead/rindle
    engine-present default profile every time an operator leaves the engine inputs blank. Omitting
    the argument entirely preserves the script's own __crosswake_default__ sentinel path, so the
    two-argument invocation matches clean-room-proof-rulestead/sigra/chimeway/threadline exactly,
    and the four-argument invocation (engine inputs filled) matches clean-room-proof-rindle
    exactly."
  - "Inputs are passed to the run step via env: vars (REHEARSAL_PACKAGE, etc.) rather than
    interpolated directly into a shell conditional, matching the house convention in
    hex-publish.yml — engine_package/engine_module are free-text inputs and belong in env:, not
    inline in an `if [ -n \"${{ ... }}\" ]` shell test."
  - "SC#3 and the CI-log half of SC#4 are recorded PENDING POST-MERGE, per the plan's own Task 3a
    instruction and the objective's documented known_obstacle: GitHub refuses to dispatch a
    workflow_dispatch workflow that is not yet on the default branch. The refusal was actually
    attempted and its verbatim text captured, rather than assumed."
  - "The plan-01 local real-run log (174-legacy-rindle-local-run.log) is cited in the evidence
    file for directional context only and explicitly NOT counted toward SC#4's satisfied verdict
    — SC#4's stated method is grepping two CAPTURED CI LOGS, and that log is a local run, not a
    CI run."

patterns-established: []

requirements-completed: []

coverage:
  - id: D1
    description: "A dispatchable workflow exists that runs the identical clean-room proof
      invocation the release lane runs, for an operator-chosen published companion package and
      version"
    requirement: "ROOM-03"
    verification:
      - kind: other
        ref: "actionlint .github/workflows/clean-room-proof-rehearsal.yml (exit 0); elixir
          script/check_release_workflow_integrity.exs (73/73 roster checks, 0 failed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The rehearsal's package roster is derived from release-please.yml's
      clean-room-proof-* lane (an independent source), and a fixture with one lane job removed
      demonstrably makes the roster-equality check fail and names the removed package"
    requirement: "ROOM-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs — 6 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "The clean-room proof for live crosswake_rindle 0.1.0 has actually executed in
      CI with a run id and job-level conclusion recorded"
    requirement: "ROOM-03"
    verification:
      - kind: other
        ref: "174-CLEANROOM-EVIDENCE.md SC#3 section — verbatim HTTP 404 dispatch refusal
          recorded; verdict explicitly NOT SATISFIED / PENDING POST-MERGE"
        status: fail
    human_judgment: true
    rationale: "The dispatch was genuinely attempted and genuinely refused by GitHub because the
      workflow file is not yet on the default branch (the documented Phase 173 precedent). This
      cannot be resolved without merging this branch — a human decision (or the next phase's
      merge) is required before the real dispatch can be attempted, per the plan's own explicit
      instruction to record PENDING rather than fabricate a run."
  - id: D4
    description: "The step= marker parity between the legacy and matrix clean-room paths is
      measured by grepping two captured CI logs, with both rosters, both counts, and an explicit
      verdict recorded"
    requirement: "ROOM-04"
    verification:
      - kind: other
        ref: "174-CLEANROOM-EVIDENCE.md SC#4 section — matrix roster (6 markers) measured from a
          real crosswake-ci.yml run (35324177344 / job 105533330884); legacy CI-log side recorded
          PENDING for the same root cause as D3"
        status: fail
    human_judgment: true
    rationale: "The legacy path has never executed in CI (confirmed by inspecting the last 60
      release-please.yml runs — every clean-room-proof-* job is skipped in all of them), so there
      is no real CI log of the legacy path to grep yet. This is downstream of D3's pending
      dispatch, not a separate defect, and needs the same post-merge action to close."

duration: 24min
completed: 2026-09-18
status: complete
---

# Phase 174 Plan 4: Clean-Room Host Realism — Rehearsal Lane & Parity Measurement Summary

**A dispatchable clean-room proof rehearsal now exists with a roster pinned to the release lane
from an independent source, but the live-run evidence ROADMAP SC#3 and SC#4 want is recorded as
genuinely PENDING, not fabricated — GitHub refused the actual dispatch attempt because the
workflow isn't on the default branch yet, exactly the documented Phase 173 obstacle.**

## Performance

- **Duration:** 24 min (approx.)
- **Started:** 2026-09-18T13:45:00Z (approx.)
- **Completed:** 2026-09-18T14:09:00Z (approx.)
- **Tasks:** 3/3 completed
- **Files modified:** 4 created (1 workflow, 1 test, 1 evidence doc, 1 captured CI log), 0 modified

## Accomplishments

- Added `.github/workflows/clean-room-proof-rehearsal.yml`: a `workflow_dispatch`-only workflow
  with `contents: read` and no other permission, whose job copies the release lane's action SHA
  pins (`actions/checkout`, `erlef/setup-beam`) verbatim and invokes
  `bash script/verify_companion_cleanroom.sh` with the same two- or four-argument shape the lane
  uses, chosen by whether the operator supplies an engine override.
- `actionlint` and `elixir script/check_release_workflow_integrity.exs` both pass against the new
  file (73 of 73 roster checks, 0 failed); `release-please.yml` is byte-unchanged
  (`git diff --name-only` prints nothing for that path).
- Added `Crosswake.Proof.Phase174CleanRoomLaneParityTest` (6 tests, 0 failures): discovers the
  lane roster from `release-please.yml` by keying on the `bash
  script/verify_companion_cleanroom.sh` invocation itself (never the `clean-room-proof-*`
  job-name prefix, which two non-invoking jobs — `-ios` and `-android` — also share), asserts
  exact five-member cardinality before the equality comparison, and demonstrates the check goes
  RED against a fixture with `clean-room-proof-rindle`'s job block removed, naming
  `crosswake_rindle` as the reported difference.
- Actually attempted the CI dispatch against live `crosswake_rindle 0.1.0` (not simulated):
  `gh workflow run clean-room-proof-rehearsal.yml --ref phase-174-clean-room-host-realism ...`
  returned a verbatim `HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default
  branch` — no run id was ever created. Searched `gh run list --workflow=release-please.yml
  --limit 60` for any pre-existing real run to substitute: every `clean-room-proof-*` job across
  all 60 inspected runs is `skipped`, confirming there is no historical run to fall back to.
  Both facts, plus the exact re-dispatch command for post-merge, are recorded verbatim in
  `174-CLEANROOM-EVIDENCE.md`.
- Captured a real, non-fabricated matrix-path CI log (`crosswake-ci.yml` run `35324177344`, job
  `release-candidate-full-proof`, conclusion `success`) as `evidence/174-matrix-ci-run.log`
  (3124 lines) and measured its distinct `step=` marker roster directly from that file by
  grep: 6 names (`build`, `dry-run`, `generate`, `install-generator`, `normalize`,
  `official-unpack`). The legacy path's equivalent CI log could not be captured for the same
  reason the dispatch was refused, and is recorded as pending the same post-merge step.

## Task Commits

Each task was committed atomically:

1. **Task 1: A dispatchable rehearsal lane that runs the same invocation the release lane runs** — `700b806d` (feat)
2. **Task 2: The rehearsal roster is pinned to the lane roster, from the lane's side** — `b612b59f` (test)
3. **Task 3: Run it against live rindle, capture both logs, and measure the marker parity** — `d77c1e14` (docs)

## Files Created/Modified

- `.github/workflows/clean-room-proof-rehearsal.yml` — new on-demand door onto the clean-room
  proof, copying the lane's runner image, timeout, permissions, action SHA pins, and Hex/Rebar
  step verbatim.
- `test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs` — new roster-parity proof, 6
  tests.
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-CLEANROOM-EVIDENCE.md`
  — new evidence record with explicit satisfied / not-satisfied verdicts for SC#3 and SC#4.
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-matrix-ci-run.log`
  — new captured real CI log (3124 lines) from a genuine `crosswake-ci.yml` run.

## Decisions Made

- **Omit, don't empty-string, the engine positional arguments.** Passing an explicit `""` as `$3`
  to `script/verify_companion_cleanroom.sh` forces `NO_ENGINE=1` regardless of package (see the
  script's `validate_inputs`), which would silently break the rulestead/rindle engine-present
  default profile whenever an operator left the engine inputs blank — the opposite of "let the
  script's own defaults apply." The rehearsal step instead builds its argument array
  conditionally in bash, omitting the trailing two arguments entirely when `engine_package` is
  empty, so the script's `__crosswake_default__` sentinel path is preserved.
- **Env vars, not inline `${{ }}` interpolation, inside the shell conditional.** Matches the
  house convention already established in `hex-publish.yml` for free-text `workflow_dispatch`
  inputs reaching a shell script.
- **Selector keys on the script invocation, never the job-name prefix.** `clean-room-proof-ios`
  and `clean-room-proof-android` share the `clean-room-proof-*` prefix but invoke `mix
  crosswake.gen.shell`, `swift build`, and gradle — never the harness script — so a naive
  prefix-glob roster would have discovered seven members and either failed the
  cardinality-exactly-five assertion for the wrong reason, or (worse, if that assertion were
  itself weakened) been silently trusted with two extra, irrelevant, always-passing members.
- **Genuinely-attempted-and-refused, not simulated.** The Task 3 dispatch, the historical-run
  search, and the matrix-log capture were all real `gh` invocations against the live repository,
  not assumed outcomes. This is the distinction this milestone's non-vacuity rule exists to
  enforce: "could not run, verbatim refusal recorded" is an accepted, honest result; a remembered
  or invented run id would not be.

## Deviations from Plan

None — plan executed as written. Task 3's SC#3/SC#4 pending outcome is not a deviation: it is the
plan's own explicitly anticipated Case-B handling ("If GitHub refuses to dispatch the workflow
from this branch ... record that refusal verbatim ... mark ROOM-03 as PENDING"), triggered exactly
as anticipated.

## Issues Encountered

The dispatch refusal itself (see above) is the expected obstacle named in this plan's execution
context, not an issue requiring resolution within this plan. No `script/verify_companion_cleanroom.sh`
edit was needed — the refusal is a GitHub platform-level restriction on dispatching a
not-yet-merged `workflow_dispatch` workflow, not a harness defect Task 3b's repair path applies to.

## User Setup Required

None — no external service configuration required. `gh auth status` was already authenticated
with `workflow` scope for this session.

## Verification Performed

- `actionlint .github/workflows/clean-room-proof-rehearsal.yml` — exit 0.
- `elixir script/check_release_workflow_integrity.exs` — `DONE: 73 of 73 roster checks emitted; 0 failed`, exit 0.
- `git diff --name-only HEAD -- .github/workflows/release-please.yml` — empty.
- `mix test test/crosswake/proof/phase174_cleanroom_host_realism_test.exs test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs --max-cases 1` — 14 tests, 0 failures (unpiped, exit code read directly).
- `mix format --check-formatted` — exit 0.
- `bash script/assert_manifest_contract_unchanged.sh` — `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`, exit 0; `lib/crosswake/doctor/doctor.ex` untouched by this plan.
- `grep -c 'step=' evidence/174-matrix-ci-run.log` — 30 (non-zero, file exists).
- `gh workflow run clean-room-proof-rehearsal.yml --ref phase-174-clean-room-host-realism ...` — real attempt, verbatim `HTTP 404` refusal captured, no run id created.

## Known Gaps (see 174-CLEANROOM-EVIDENCE.md for full detail)

- `evidence/174-rindle-ci-run.log` does **not** exist yet and was not fabricated. ROOM-03 (SC#3)
  and the legacy-log half of SC#4 (ROOM-04) remain **PENDING POST-MERGE**: once this branch (or
  its equivalent) merges to `main`, re-dispatch `clean-room-proof-rehearsal.yml` per the exact
  command recorded in `174-CLEANROOM-EVIDENCE.md`, capture the resulting log, and update that
  file's SC#3 and SC#4 sections with the real run id, job conclusion, and legacy marker roster.
  **The phase cannot be sealed as fully satisfying ROADMAP SC#3/SC#4 until that post-merge
  observation is taken** — this is the same discipline `173-NON-VACUITY.md` established for the
  hex-publish fire drill.

## Self-Check: PASSED

- FOUND: .github/workflows/clean-room-proof-rehearsal.yml
- FOUND: test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs
- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-CLEANROOM-EVIDENCE.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-matrix-ci-run.log
- FOUND commit: 700b806d
- FOUND commit: b612b59f
- FOUND commit: d77c1e14

## Next Phase Readiness

- Plans 174-05 and 174-06 can proceed; neither depends on the pending post-merge dispatch closing
  first, but this phase's own close-out (or the milestone's) must not read ROOM-03/SC#3 or the
  legacy half of ROOM-04/SC#4 as satisfied until that dispatch is actually taken and this file's
  pending sections are updated with real data.
- `release-please.yml` remains byte-unchanged by this plan; the new rehearsal workflow is
  additive and reversible (deleting it restores the prior state exactly).
