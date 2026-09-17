---
phase: 171-version-authority-split
plan: 02
subsystem: domain
tags: [elixir, release-candidate, version-authority, clean-room]

requires:
  - phase: 171-version-authority-split
    plan: "171-01"
    provides: "approved-release-guard.outputs.approved_version, single-producer version derived from the release manifest"
provides:
  - "Crosswake.ReleaseCandidate.Workflow.rollup!/1 derives publishable coordinates from an input :version instead of a frozen @coordinates literal (WELD-04)"
  - "Crosswake.ReleaseCandidate.Workflow.evaluate_cli!/0 threads APPROVED_VERSION from the single producer into rollup!/1"
  - "linked-release-status.json schema widened to schema_version 1.1.0 with a version key (D-171-B)"
  - "Crosswake.ReleaseCandidate.Cleanroom.validate_approved_artifacts!/1 scoped to structural completeness only, no longer asserting a specific candidate version (WELD-05)"
affects: [172-per-package-refs, 173-lib-module-generalization, 175-rehearsal-and-publish]

actuals:
  tokens: 3353
  tasks: 2
  commits: 2
  plan_head_before: b041bf680735bb43939005e9987e28c23677be49

tech-stack:
  added: []
  patterns:
    - "Version-parametric derivation: a module attribute frozen at a specific candidate version becomes a private function of an input version, mirroring the D-171-A single-producer idiom from 171-01 one layer down in the domain model."
    - "Version identity assertion lives at exactly one layer (approved-release-guard's approved_version); downstream validators check structural completeness only, never re-assert a specific version value."

key-files:
  created: []
  modified:
    - lib/crosswake/release_candidate/workflow.ex
    - lib/crosswake/release_candidate/cleanroom.ex
    - .github/workflows/release-please.yml
    - test/crosswake/release_candidate/workflow_test.exs
    - test/crosswake/release_candidate/cleanroom_test.exs

key-decisions:
  - "D-171-B (from PLAN.md, applied as written): linked-release-status.json gains a version key, schema_version moves 1.0.0 -> 1.1.0, rollup!/1 and validate!/1 both thread :version through their exact-key contracts."
  - "WELD-05 fix is a pure conjunct deletion, not a parameterization — the three remaining structural conjuncts in validate_approved_artifacts!/1 already establish package-set completeness; the per-artifact version!/1 format normalizer is untouched (confirmed via an explicit-range git diff against merge-base main, per the plan's own acceptance criterion)."

patterns-established:
  - "Anchored exact-match version guard: version!/1 in Workflow uses ~r/\\A\\d+\\.\\d+\\.\\d+\\z/ — no prefix/substring match, no pre-release or build-metadata suffix accepted, mirroring exact_hex!/2's anchoring style already in the same module."

requirements-completed: [WELD-04, WELD-05]

coverage:
  - id: D1
    description: "rollup!/1's coordinate derivation is a function of an input version; two different versions in, two different coordinate lists out, with identical pass/fail topology"
    requirement: "WELD-04"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/workflow_test.exs#coordinate derivation is a function of the input version, not a frozen literal"
        status: pass
    human_judgment: false
  - id: D2
    description: "rollup!/1 requires :version and rejects non-semver strings; validate!/1 round-trips a non-candidate version and rejects a version/coordinate mismatch"
    requirement: "WELD-04"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/workflow_test.exs#rollup! requires a version key and rejects non-semver version strings"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/workflow_test.exs#validate! round-trips a non-candidate version and rejects a version/coordinate mismatch"
        status: pass
    human_judgment: false
  - id: D3
    description: "evaluate_cli!/0 receives the approved version from APPROVED_VERSION (single producer: approved-release-guard.outputs.approved_version) via the linked-release-rollup job's env block"
    requirement: "WELD-04"
    verification:
      - kind: structural
        ref: ".github/workflows/release-please.yml linked-release-rollup 'Preserve exact linked child states' step env block"
        status: pass
    human_judgment: false
  - id: D4
    description: "validate_approved_artifacts!/1 accepts a well-formed six-package list at any semver version while rejecting missing/duplicate/unexpected packages and malformed per-artifact versions"
    requirement: "WELD-05"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#approved-artifacts validator accepts any well-formed semver, not just the current candidate"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#approved-artifacts validator rejects missing, duplicate, and unexpected packages"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#approved-artifacts validator still rejects a malformed version"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#the deleted crosswake-version identity comparison cannot come back"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-09-17
status: complete
---

# Phase 171 Plan 02: Version/Authority Split — Workflow & Clean-Room Generalization Summary

**`Crosswake.ReleaseCandidate.Workflow`'s coordinate derivation is now a function of an input version threaded from the single-producer `approved_version`, and `Cleanroom.validate_approved_artifacts!/1` no longer re-asserts a specific candidate version, leaving version identity assertion in exactly one place.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-09-17T15:05:00Z (approx.)
- **Completed:** 2026-09-17T15:45:00Z
- **Tasks:** 2
- **Commits:** 2 (measured: `git rev-list --count b041bf68..HEAD`)
- **Files modified:** 5

## Accomplishments
- Deleted `Workflow`'s frozen `@coordinates` module attribute and replaced it with a private `coordinates(version)` function; `rollup!/1` now requires `:version` in its input map (`exact_map?` guard extended), validates it with a new anchored `version!/1` (`\A\d+\.\d+\.\d+\z`), and computes `coordinates(version)` once before the coordinate lookup.
- `rollup!/1`'s output map and `validate!/1`'s exact-key round-trip both gained `version`; `schema_version` moved from `"1.0.0"` to `"1.1.0"` per D-171-B.
- `evaluate_cli!/0` now calls `System.fetch_env!("APPROVED_VERSION")` and threads it into `rollup!/1`'s input; `.github/workflows/release-please.yml`'s `linked-release-rollup` job's "Preserve exact linked child states" step gained `APPROVED_VERSION: ${{ needs.approved-release-guard.outputs.approved_version }}` in its `env:` block. `linked-release-rollup` already listed `approved-release-guard` in `needs:` (no change required there).
- New test proves two different versions (`"0.2.2"` and `"9.9.9"`) produce two different `successful_coordinates` lists (all three entries differ) with identical `state`; a required-key/non-semver rejection test; and a `validate!/1` round-trip + version/coordinate-mismatch rejection test.
- `Cleanroom.validate_approved_artifacts!/1`'s fourth `unless` conjunct (`Map.fetch!(by_package, "crosswake").version == "0.2.1"`) deleted outright — not parameterized. The three remaining structural conjuncts (exact count, no duplicates, exact package-set match) fully establish completeness; version identity assertion stays exclusively in `approved-release-guard`'s `approved_version` (D-171-A).
- New tests: a positive case proving a non-candidate semver (`"9.9.9"`) now validates successfully through `evaluate_public!/1`; three negative cases (missing/duplicate/unexpected package); a malformed-version rejection case proving the untouched per-artifact `version!/1` format normalizer still fires; and a source-level regression assertion (`refute Regex.match?(~r/version == "[0-9]+\.[0-9]+\.[0-9]+"/, cleaned_source)`) that the deleted literal comparison cannot silently come back.
- All verification green: `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` (57 tests, 0 failures); `elixir script/check_release_workflow_integrity.exs` (69/69 OK, 0 FAIL); `grep -v '^\s*#' lib/.../workflow.ex | grep -cE "@[0-9]+\.[0-9]+\.[0-9]+"` returns `0`; `mix test test/crosswake/proof --max-cases 1` (677 tests, 0 failures, full regression check beyond the plan's own scope).

## Task Commits

1. **Task 1: Make the linked-release rollup derive coordinates from an input version** - `1bcce993` (feat)
2. **Task 2: Scope the clean-room approved-artifacts validator to structural completeness only** - `3b707fd5` (feat)

_Both tasks are marked `tdd="true"` in the plan; in practice this landed as behavior + test together in a single commit per task, matching 171-01's precedent — the plan's `<behavior>` blocks were used as the test specification written alongside the implementation, not as a separately-committed RED phase, since the change is a pure refactor of existing, already-tested functions rather than net-new behavior._

## Files Created/Modified
- `lib/crosswake/release_candidate/workflow.ex` — `@coordinates` deleted; `coordinates/1` and `version!/1` added; `rollup!/1`, `validate!/1`, `evaluate_cli!/0` all thread `:version`; `schema_version` bumped to `"1.1.0"`
- `test/crosswake/release_candidate/workflow_test.exs` — three new tests (two-version comparison, required-key/non-semver rejection, validate! round-trip/mismatch); `rollup_input/2` gained a `version \\ "0.2.1"` default param; one pre-existing assertion updated (see Deviations)
- `lib/crosswake/release_candidate/cleanroom.ex` — fourth conjunct of `validate_approved_artifacts!/1`'s guard deleted
- `test/crosswake/release_candidate/cleanroom_test.exs` — four new tests (non-candidate-version acceptance, structural rejections, malformed-version rejection, source-level regression assertion); `update_approved_artifact/3` helper added
- `.github/workflows/release-please.yml` — `APPROVED_VERSION` added to `linked-release-rollup`'s "Preserve exact linked child states" step `env:` block

## Decisions Made
- **D-171-B applied as written:** `version` added to `rollup!/1`'s output and `validate!/1`'s exact-key list; `schema_version` bumped additively, no key removed or retyped.
- **WELD-05 is a deletion, not a parameterization**, per the plan's explicit instruction — confirmed by an explicit-range `git diff $(git merge-base main HEAD)..HEAD -- lib/crosswake/release_candidate/cleanroom.ex` showing only the conjunct removal, with the per-artifact `version!/1` call inside `Enum.map` unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Auto-fix bugs] Pre-existing test assertion broken by 171-01, not this plan's own change**
- **Found during:** Task 1 verification (`mix test test/crosswake/release_candidate/workflow_test.exs`)
- **Issue:** `"linked publication is gated by approved merge parent and identical tree"` asserted `block =~ "0.2.1"` against the `publish-hex`/`publish-ios-core`/`publish-android-core` job blocks in `release-please.yml`. 171-01's WELD-03 fix (already committed, `b3ec6d4c`) rewrote those jobs' `if:` clauses to compare `needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version`, removing the bare `'0.2.1'` literal these job blocks previously contained anywhere — this plan's own `<verify>` for Task 1 requires the file to pass with `0 failures`, so the pre-existing break had to be resolved to satisfy this plan's stated verification, even though the root cause was 171-01's change, not this plan's edit to the same file (I only added an `APPROVED_VERSION` env line elsewhere in the job).
- **Fix:** Updated the assertion to `assert block =~ "needs.approved-release-guard.outputs.approved_version"`, matching the post-WELD-03 comparison shape.
- **Files modified:** `test/crosswake/release_candidate/workflow_test.exs`
- **Verification:** `mix test test/crosswake/release_candidate/workflow_test.exs` — 15 tests, 0 failures.
- **Committed in:** `1bcce993` (Task 1 commit)

**2. [Rule 1 - Auto-fix bugs] Plan's own `<behavior>` claim for Task 1 was internally inconsistent with the implementation**
- **Found during:** Task 1 implementation, writing the two-version comparison test
- **Issue:** Task 1's `<behavior>` states "`receipt_external_state` values are byte-identical between those two calls" for two different versions. This is impossible by construction: `receipt_external_state/3` embeds `successful_coordinates` (the version-bearing coordinate list) directly into its returned map for `"COMPLETE"`/`"PARTIAL"` states, so two different versions necessarily produce two different `receipt_external_state` maps whenever any coordinate succeeds. The acceptance criteria for the same task repeats the same claim ("... while `state` and `receipt_external_state` are equal").
- **Fix:** Adapted the test to assert what is actually version-independent — the pass/fail topology subset of `receipt_external_state` (`publication`, `failed_step`, `changed`, `all_linked_proven`) is identical across versions, while `receipt_external_state.successful_coordinates` is asserted equal to the top-level `successful_coordinates` for each version separately (i.e., it correctly varies with version, exactly like the top-level field). No code change to `lib/` was needed — only the test's assertion shape, since the plan's literal claim about `receipt_external_state` byte-identity cannot hold given the existing, correct implementation of `receipt_external_state/3` (unchanged by this plan).
- **Files modified:** `test/crosswake/release_candidate/workflow_test.exs`
- **Verification:** `mix test test/crosswake/release_candidate/workflow_test.exs` — 15 tests, 0 failures.
- **Committed in:** `1bcce993` (Task 1 commit)

---

**Total deviations:** 2 (both Rule 1, both test-only, both required to satisfy this plan's own stated `<verify>`/acceptance criteria)
**Impact on plan:** No scope creep. Deviation 1 is a direct fallout of 171-01's already-authorized change reaching a test fixture in a file this plan also touches. Deviation 2 corrects an internally inconsistent claim in the plan's own `<behavior>` text against the unchanged, correct implementation — the plan's underlying intent ("changing the version must not change the pass/fail topology") is fully preserved and tested; only the literal "byte-identical `receipt_external_state`" wording could not be satisfied as written.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Plan 171-03/171-04 (remaining WELD occurrences per `171-RESEARCH.md`) can proceed: `Workflow`'s `@coordinates` weld and `Cleanroom`'s version-identity weld are both fully resolved in source, with regression tests pinning both fixes.
- Phase 172 (per-package proof scope) depends on `cleanroom.ex`'s current shape: `validate_approved_artifacts!/1` now has exactly three structural conjuncts (down from four) and its output map shape (`@approved_artifact_keys`, per-package `version!/1` normalization) is otherwise unchanged — left in the state Phase 172's own plan expects to build on, per this plan's own read-first warning.
- **Per the plan's `<atomicity_constraint>`:** no PR was opened, no branch was pushed. This plan's two commits sit on `gsd/phase-171-version-authority-split` alongside 171-01 and 171-03 through 171-05, all landing together in one PR at 171-05 Task 3 (human-gated).

---
*Phase: 171-version-authority-split*
*Completed: 2026-09-17*

## Self-Check: PASSED

All 5 modified files confirmed present on disk; both task commit hashes (`1bcce993`, `3b707fd5`) confirmed in `git log`.
