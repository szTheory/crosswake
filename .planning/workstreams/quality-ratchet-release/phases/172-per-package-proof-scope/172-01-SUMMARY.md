---
phase: 172-per-package-proof-scope
plan: 01
subsystem: release-candidate-proof
tags: [elixir, bash, jq, python, hex-publish, proof-scope, candidate_ref]

# Dependency graph
requires:
  - phase: 171-version-authority-split
    provides: validate_approved_artifacts!/1 with the version-literal weld already removed
provides:
  - "candidate_ref as a per-artifact field on both the producer (Artifact) and the consumer
    (Cleanroom approved/public) schemas"
  - "verify_companion_cleanroom.sh and hex_artifacts.sh both threading a 7-field artifact
    positional (package, version, candidate_ref, tarball, unpacked_root, outer_checksum, source)"
  - "MATRIX_PUBLIC_REF resolved independently from git rev-parse HEAD, never from the approved
    manifest it is compared against"
affects: [172-02-graded-claim-classifier, 172-03-non-vacuity-proof-test]

# Actuals (#2632)
actuals:
  tokens: 4805
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-package field threading through a shell/Elixir CLI boundary: extend the fixed-width
      positional-arg chunk (Artifact.inspect_cli!/1) in lockstep on both the producer wrapper and
      every shell call site, never as an out-of-band scalar"
    - "Independent-derivation guard against comparison-target circularity: the value a proof
      compares against a manifest must be resolved from a source the manifest cannot influence
      (git rev-parse HEAD), never read out of that same manifest"

key-files:
  created: []
  modified:
    - lib/crosswake/release_candidate/artifact.ex
    - lib/crosswake/release_candidate/cleanroom.ex
    - script/verify_companion_cleanroom.sh
    - script/release_candidate/hex_artifacts.sh
    - test/crosswake/release_candidate/artifact_test.exs
    - test/crosswake/release_candidate/cleanroom_test.exs
    - script/collection_assertion_ledger.json

key-decisions:
  - "candidate_ref moved off Artifact's family-level @input_keys onto @artifact_keys (per-artifact); inspect_family!/1 no longer resolves one shared ref, inspect_artifact!/3 became /2"
  - "Cleanroom gained a dedicated 40-hex ref!/1 validator distinct from the 64-hex digest sha!/1 — reusing sha!/1 would reject every valid ref"
  - "The observed ref (MATRIX_PUBLIC_REF) is resolved once from git -C \"$MATRIX_REPO_ROOT\" rev-parse HEAD, never from the approved manifest — this is the T-172-01 mitigation and the load-bearing anti-vacuity guard for 172-02's drift comparison"
  - "validate_public_artifacts!/3 carries candidate_ref through WITHOUT calling ref!/1 on it, preserving reachability of the registry-missing branch for packages absent from the registry"
  - "public_artifact_reason/3 is untouched by this plan (SC#3 rigor floor) — confirmed by re-running the malformed-ref test's falsifiability mutation, not just by diff inspection"

requirements-completed: [XPUB-01]

coverage:
  - id: D1
    description: "Artifact.inspect_family!/1 and inspect_cli!/1 thread candidate_ref per artifact instead of broadcasting one family-level value"
    requirement: "XPUB-01"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/artifact_test.exs#two artifacts in one family carry their own distinct candidate_ref, not a broadcast value"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/artifact_test.exs#rejects package-set, file-list, checksum, path, output, and version mutations (top_level_candidate_ref, malformed_ref cases)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cleanroom.validate_approved_artifacts!/1 resolves and validates each package's own candidate_ref with a 40-hex ref validator; six independent refs validate in one run and two differing refs both succeed"
    requirement: "XPUB-01"
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#approved-artifacts schema accepts six independent candidate_ref values in one run"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#two packages with different candidate_ref values both validate independently in one run"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#approved-artifacts validator rejects a malformed or absent candidate_ref"
        status: pass
    human_judgment: false
  - id: D3
    description: "No jq expression anywhere in the tree collapses the six approved refs to one scalar; the shell scripts pass a per-artifact 7-field positional and resolve the observed ref independently"
    requirement: "XPUB-01"
    verification:
      - kind: other
        ref: "grep -c 'unique' script/verify_companion_cleanroom.sh returns 0; grep -c 'chunk_every(6)' lib/crosswake/release_candidate/artifact.ex returns 0; bash -n on both scripts exits 0"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs#post-publication adapter fetches exact packages and preapproval command cannot count it (extended script-contract assertions)"
        status: pass
    human_judgment: false
  - id: D4
    description: "public_artifact_reason/3's byte-exact digest comparison is textually unchanged by this plan (SC#3 rigor floor)"
    requirement: null
    verification:
      - kind: other
        ref: "git diff 9ba10059..HEAD -- lib/crosswake/release_candidate/cleanroom.ex shows zero changed lines inside public_artifact_reason/3"
        status: pass
    human_judgment: false

# Metrics
duration: 55min
completed: 2026-09-17
status: complete
---

# Phase 172 Plan 01: Per-Package Proof Scope — Schema and Transport Summary

**Loosened the release-candidate proof from one shared `candidate_ref` to six independent per-package refs across the Elixir producer/consumer and both shell transports, with the observed ref resolved from `git rev-parse HEAD` rather than the manifest it is compared against.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-09-17T18:26:00Z (approx, first Read)
- **Completed:** 2026-09-17T19:21:32Z
- **Tasks:** 3 completed
- **Files modified:** 6 plan-scoped files + 1 deviation fix (collection assertion ledger snapshot)

## Accomplishments

- `Artifact.@input_keys` shrank to `output_root`/`artifacts`; `candidate_ref` moved onto
  `@artifact_keys` and is resolved per artifact inside `inspect_artifact!/2` (was `/3`).
  `inspect_cli!/1`'s positional-arg chunk width grew from 6 to 7 fields, with `candidate_ref`
  third (right after package/version).
- `Cleanroom.@approved_artifact_keys` and `@public_artifact_keys` both gained `candidate_ref`. A
  new `ref!/1` (40-hex) validator enforces it on the approved side; the public side carries the
  observed ref unvalidated so the `registry_missing` branch stays reachable for absent packages.
  `public_artifact_reason/3` is untouched — confirmed both by an exact-range diff and by locally
  reverting `ref!/1` to a pass-through and watching the malformed-ref test fail for the right
  reason (recorded below).
- Both shell scripts (`hex_artifacts.sh`, `verify_companion_cleanroom.sh`) append the ref as the
  third element of every 7-field artifact-args group and drop the now-removed leading ref
  positional from their `Artifact.inspect_cli!` invocations.
- The `jq 'map(.candidate_ref) | unique | if length == 1 ...'` collapse in
  `matrix_fetch_public_family` is deleted outright — nothing replaces it at that position. The
  observed ref (`MATRIX_PUBLIC_REF`) is instead resolved once, independently, from
  `git -C "$MATRIX_REPO_ROOT" rev-parse HEAD`, format-guarded and fail-closed through
  `matrix_fail`. It can never be derived from the approved manifest it will later be compared
  against (T-172-01).
- The python observation-assembly heredoc's `approved_artifacts` comprehension now projects 5
  keys (adds `candidate_ref`); `public_artifacts` was rebuilt to read the re-fetch manifest rows
  directly (not the six-key candidate-local projection) and now projects 9 keys including
  `candidate_ref`. A missing `candidate_ref` on either side raises `KeyError` (fail-closed,
  T-172-03) rather than silently defaulting.
- Six independent-ref schema tests added and passing: all six distinct refs accepted in one run,
  two named packages with different refs both land in `succeeded_packages`, and a malformed or
  absent `candidate_ref` raises `ArgumentError`.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end per-package ref — Elixir producer/consumer** - `99dff0ff` (feat)
2. **Task 2: Delete the single-ref collapse in the shell transport** - `f33a81e8` (feat)
3. **Task 3: Fixtures and schema tests** - `cee77590` (test — includes a bundled Rule 3 fix, see Deviations)

**Plan metadata:** commit pending (this SUMMARY + STATE/ROADMAP/REQUIREMENTS update)

_Note: Task 3 is TDD (`tdd="true"`); RED was run against the pre-172-01 tree (17 baseline tests,
7 failing for the expected shape-mismatch reason before fixtures were updated) and GREEN
confirmed after fixtures + new tests were added (21 tests, 0 failures)._

## Files Created/Modified

- `lib/crosswake/release_candidate/artifact.ex` — per-artifact `candidate_ref`, 7-field CLI chunking
- `lib/crosswake/release_candidate/cleanroom.ex` — `ref!/1`, `candidate_ref` on approved/public key lists
- `script/verify_companion_cleanroom.sh` — deleted the unique-refs collapse, added `MATRIX_PUBLIC_REF`, rebuilt python comprehensions
- `script/release_candidate/hex_artifacts.sh` — 7-field `ARTIFACT_ARGS`, dropped leading ref positional
- `test/crosswake/release_candidate/artifact_test.exs` — per-artifact ref fixture + distinct-ref test + 2 new mutation cases
- `test/crosswake/release_candidate/cleanroom_test.exs` — per-package ref fixtures + 3 new schema tests + extended script-contract assertions
- `script/collection_assertion_ledger.json` — regenerated snapshot (line-number-only diff, see Deviations)

## Decisions Made

- `candidate_ref` sits third in the artifact positional/map order (after package, version),
  matching the plan's instruction to keep shell call sites readable.
- The per-package approved-ref jq lookup added to `matrix_fetch_public_family`'s loop is used for
  diagnostic logging only (`echo ... candidate_ref=$approved_ref ...`) — it never feeds the
  observed-ref derivation, preserving the T-172-01 independence guarantee while still giving the
  Task 3d script-contract test a concrete substring to pin.
- Test refs for the six-distinct-refs schema test use `String.duplicate(digit, 40)` for digits
  `0`–`5` rather than reusing the two named module-attribute refs, keeping the "all six distinct"
  assertion independent of the two-ref mutation test's fixture values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated the Phase 170 collection-assertion ledger snapshot**
- **Found during:** Task 3 (after adding new tests to `cleanroom_test.exs`)
- **Issue:** The new tests inserted before line 34 of `cleanroom_test.exs` shifted three
  Phase-170-pinned collection-assertion rows (`test/crosswake/release_candidate/cleanroom_test.exs:35/36/37`
  → `:37/38/39`). `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` diffs a
  committed snapshot against a live regeneration and failed with "3 row(s) whose content has
  drifted from the live tree" — a direct, mechanical consequence of this task's own file edit,
  not a pre-existing or out-of-scope failure.
- **Fix:** Ran `elixir script/inventory_collection_assertions.exs --emit-snapshot`, redirected to
  a temp file (the script reads its own committed ledger as an input scope, so writing directly
  over it truncates the input before the run), then copied the regenerated snapshot over
  `script/collection_assertion_ledger.json`.
- **Files modified:** `script/collection_assertion_ledger.json`
- **Verification:** `git diff` on the ledger shows exactly 3 rows changed, each only in `display`
  line number and the embedded line-number in `rationale` text — no `bucket` or `key`
  (sha256-of-content) changed. `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs --max-cases 1` — 19 tests, 0 failures (was 2 failures before the fix).
- **Committed in:** `cee77590` (bundled into the Task 3 commit, since it's a direct consequence of that task's test edits)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary to keep an unrelated but line-number-sensitive governance test
green; no scope creep — only the pinned display/rationale line numbers changed, not any
classification.

## Falsifiability Check (Task 3 acceptance criterion)

Per the plan's Task 3 acceptance criteria, `ref!/1`'s call inside `validate_approved_artifacts!/1`
was deleted locally (replaced with a raw pass-through: `candidate_ref: artifact.candidate_ref`),
and the malformed-ref test was re-run:

```
mix compile --warnings-as-errors
     warning: function ref!/1 is unused
     └─ lib/crosswake/release_candidate/cleanroom.ex:421:8

mix test test/crosswake/release_candidate/cleanroom_test.exs --only post_publication --max-cases 1
  1) test approved-artifacts validator rejects a malformed or absent candidate_ref (Crosswake.ReleaseCandidate.CleanroomTest)
     test/crosswake/release_candidate/cleanroom_test.exs:270
     Expected exception ArgumentError but nothing was raised
     code: for {name, mutation} <- [malformed: malformed, absent: absent] do
     ...
10 tests, 1 failure (6 excluded)
```

The mutation was then reverted (file restored from a pre-mutation copy) and `mix compile
--warnings-as-errors` confirmed 0 warnings, 0 diff against the committed state. This confirms the
malformed-ref test is non-vacuous: it fails for the right reason (missing ref validation) when the
validation it claims to test is removed.

Test count: **17 baseline (phase-base commit `9ba10059`) → 21 after this task** (4 new tests: one
per-package-ref test in `artifact_test.exs`, three schema tests in `cleanroom_test.exs`;
`update_approved_artifact`/`update_public_artifact` mutation helpers and the extended
script-contract test reused existing infrastructure without adding new test cases).

## Issues Encountered

None beyond the ledger-snapshot deviation documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The per-package `candidate_ref` field now flows end-to-end: producer (`Artifact`) → both shell
  transports → consumer (`Cleanroom` approved/public schemas). This is 172-02's prerequisite: the
  graded-claim classifier (`public_artifact_reason/3`'s new `reachable_and_compatible`/`unproven`
  branches) can now read a real per-package `candidate_ref` on both sides of the comparison
  instead of a broadcast value.
- `public_artifact_reason/3` itself is untouched — 172-02 is the plan that edits it.
- Per `<atomicity_constraint>`: this plan is NOT separately mergeable. No PR was opened. 172-02 and
  172-03 land in the same PR against `main`.
- The `jq -c` result-summary projection in `verify_companion_cleanroom.sh` already includes
  `attested_packages` and `package_claims` keys (currently `null`, since `Cleanroom` doesn't
  produce them yet) so 172-02 does not need to touch that projection line.

---
*Phase: 172-per-package-proof-scope*
*Plan: 01*
*Completed: 2026-09-17*

## Self-Check: PASSED

- All 6 plan-scoped files + `script/collection_assertion_ledger.json` + this SUMMARY.md confirmed present on disk via `[ -f ]`.
- All 3 task commit hashes (`99dff0ff`, `f33a81e8`, `cee77590`) confirmed present via `git log --oneline --all`.
- All plan-level `<verification>` commands re-run and passing: `mix format --check-formatted` (0), `mix compile --warnings-as-errors` (0 warnings), `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` (71 tests, 0 failures), `bash -n` on both shell scripts (0), `grep -c 'unique'` (0), `grep -c 'chunk_every(6)'` (0).
- Full project suite `mix test --exclude requires_example_host` re-run after the ledger-snapshot fix: 1831 tests, 0 failures.
