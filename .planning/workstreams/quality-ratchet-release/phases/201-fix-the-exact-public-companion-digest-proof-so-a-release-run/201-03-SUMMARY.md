---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 03
subsystem: release-candidate
tags: [hex, build_env, digest, exact-public-proof, companions-only, provenance-log, mutation-proof]

requires:
  - phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
    provides: "201-01 real Hex tarballs and the 19-test regression, 9 red on the unchanged digest rule"
provides:
  - "Companions-only fix in Artifact: build_env shape-validated for every package, excluded from the metadata digest only for the five companions (literal list), core keeps it"
  - "Artifact.provenance_line/1 (@doc false) and one artifact-provenance stderr line per package from inspect_cli!/1"
  - "README ## Decision section recording the user's 2026-11-09 companions-only decision and its consequence for the core"
  - "Evidence: green, six mutations, final, release_candidate suite, hermetic suite, guards"
affects: [201-04, 201-05, 201-07]

actuals:
  tokens: 1500
  tasks: 3
  commits: 5

plan_head_before: "58afa0a8ca047f29edca4759b03ac159d9f4a2f4 (worktree crosswake-201-wt, 2 commits); af8a2e442cd3100c0f55b6a6fc2c7e394cecfe61 (main checkout, 3 evidence commits)"
plan_head_after: "be335acc4580a7191fdd3fa5733331482b437f0c (worktree); 5bb569539121c9d39965f3b2174deb171edcfe15 (main checkout, before this SUMMARY commit)"
commits: 5

tech-stack:
  added: []
  patterns:
    - "Fail-closed shape validation before a digest exclusion, one normalizer for candidate and public sides"
    - "Per-control mutation proof: every control goes red on its own mutation, then the file is restored with an empty diff"
    - "Floors measured, not assumed: base at origin/main plus new tests"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/real-tarball-green-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/real-tarball-mutation-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/real-tarball-final-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/release-candidate-suite-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/hermetic-suite-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/guards-201.txt
  modified:
    - lib/crosswake/release_candidate/artifact.ex
    - test/crosswake/release_candidate/artifact_real_tarball_test.exs
    - test/fixtures/hex_tarballs/README.md

key-decisions:
  - "Companions only (user decision 2026-11-09, PD-01): build_env is dropped from the metadata digest exactly when the package is in the literal five-name list; the core crosswake keeps it, so its digest stays Hex-version-sensitive"
  - "build_env!/1 runs before the exclusion for every package: nil or exactly [{hex, semver}] passes, anything else raises ArgumentError"
  - "The provenance line is rendered from the already validated hex_metadata.config, carrying only package, version, Hex version and a yes/no"

requirements-completed: [REL-09]

coverage:
  - id: D1
    description: "The real public rulestead tarball and its Hex 2.7.0 rebuild give equal metadata and payload digests after the fix; all 19 regression tests (9 red before) pass"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "script/mix_test_gate.sh --min 19 on artifact_real_tarball_test.exs -> rc=0 ran=19 failures=0 PASS (201-EVIDENCE/real-tarball-green-201.txt)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The companion exclusion cannot hide changed content, the core keeps build_env, and every control bites: six mutations each turn their own controls red"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "201-EVIDENCE/real-tarball-mutation-201.txt: description 1, requirement 1, links 1, payload-byte 1, no-validation 6 (shape:), core-excluded 2 (core build_env:) failing tests, restored diff_rc=0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Provenance lines name each artifact's builder Hex version, pinned by three tests on real fixtures (file now 22 tests)"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "201-EVIDENCE/real-tarball-final-201.txt -> rc=0 ran=22 failures=0 PASS"
        status: pass
    human_judgment: false
  - id: D4
    description: "release_candidate suite at the measured floor, hermetic suite and three guards pass, and no script, workflow, cleanroom, ledger or policy file changed"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "201-EVIDENCE/release-candidate-suite-201.txt (218 ran, floor 218 = 196 + 22, 0 failures); hermetic-suite-201.txt (total 3274, ran 3198, 0 failures); guards-201.txt (absence, ownership, phase170-ledger rc 0)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The emission of the provenance line from inspect_cli!/1 (the Enum.each to stderr) runs in a real release; the line content is tested, the emission site is not unit-tested"
    requirement: REL-09
    human_judgment: true
    rationale: "inspect_cli!/1 needs a six-package family and is exercised only by hex_artifacts.sh and verify_companion_cleanroom.sh in CI; the first release run after merge shows whether the lines appear in the logs"

duration: about 35 min (hermetic suite about 16 min of that)
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 03: Companions-only build_env fix, provenance line and mutation proof Summary

**`Artifact` now validates `build_env` fail-closed for every package and leaves it out of the metadata digest only for the five companions, so the real public rulestead 0.1.1 tarball and its Hex 2.7.0 rebuild give equal digests while the core still digests its own Hex version. One `artifact-provenance` stderr line per package names the builder Hex version, and six mutations show every control goes red when its coverage is removed.**

## Performance

- **Duration:** about 35 min (the hermetic suite took about 16 min)
- **Completed:** 2026-11-09T21:00Z
- **Tasks:** 3 (one tracer, two auto)
- **Files:** 3 changed on the fix branch (`artifact.ex`, the test file, the fixtures README); 6 evidence files in the main checkout

## Accomplishments

- **Tracer green.** `mix-test-gate: rc=0 total=19 ... ran=19 failures=0 ... verdict=PASS` on the real-tarball file, where Plan 01 recorded `ran=19 failures=9`. The nine that turned green are the equality test, the six `shape:` tests and the two `companion build_env:` tests. The 38 baseline tests (`artifact_test.exs` + `cleanroom_test.exs`) still pass with their measured count.
- **The fix is small and in one place.** `@build_env_excluded_packages` is the literal five-name list placed after `@required_metadata_keys`. `inspect_metadata!/3` calls `build_env!(metadata["build_env"])` for every package, after the `build_tools` check and before the path normalization. `drop_build_env(package)` is the first step of the normalization pipeline, so the exclusion happens before `normalize_term/1`. `@metadata_keys` and `@required_metadata_keys` are byte-identical to origin/main. The file holds exactly one `Map.delete(`.
- **Provenance line.** Three tests first (red on `UndefinedFunctionError`, 3 failures of 22), then `provenance_line/1`. Public rulestead prints `build_env_hex=none build_env_digested=no`; the rebuild prints its own Hex version with `digested=no`; the public core prints its own with `digested=yes`. No Hex version literal appears in the tests.
- **Six mutations, each red on its own controls** (all `rc=2 ... ran=22 ... reason=mix_rc`, every run compiled, no compile-failure counted): description 1 failing `control description:`, requirement 1 `control requirement:`, links 1 `control links:`, payload-byte 1 `control payload byte:`, no-validation 6 `shape:`, core-excluded 2 `core build_env:`. After all six, `git diff --quiet` in the worktree exits 0 (`mutation: restored diff_rc=0`).
- **Suites at measured floors.** release_candidate + phase172: floor 218 = 196 (origin/main, Plan 01) + 22 (new), `ran=218 failures=0`, including the cleanroom `digest_mismatch` anchors unchanged. Hermetic suite: `total=3274 excluded=76 ran=3198 failures=0` (floor 3000 was a sanity bound; Phase 200 measured 3176 on main). Guards: absence rc 0 (`collections mode=enforce files=334 findings=84 delta=0`), ownership rc 0, phase170 ledger rc 0 (21 tests).
- **README `## Decision`** states companions only, the user's decision of 2026-11-09, the core's Hex-version sensitivity (a Hex release between the core's candidate build and its publish fails the proof closed with `digest_mismatch`; the release plan re-reads the newest Hex before the core merge and publish), and the alternative not chosen (all six).

## Task Commits

Code commits on `fix/exact-public-build-env-provenance` in `~/projects/crosswake-201-wt` (not pushed):

1. **Task 1 (tracer): the fix and the README Decision** - `5b7e572c` (fix)
2. **Task 2: provenance line and its three tests** - `be335acc` (fix)

Evidence commits in the main checkout on `docs/199-release-0-2-12` (not pushed):

- `d2a8da43` docs(201-03): real-tarball regression green after the companions-only fix
- `3604f69e` docs(201-03): six negative-control mutations and the final real-tarball run
- `5bb56953` docs(201-03): suites with measured floors and guards on the fix branch

The branch now has four commits above origin/main (two `test(release-candidate):` from Plan 01, two `fix(release-candidate):` here), none `feat`. `git diff --name-only origin/main...HEAD` lists only `.gitattributes`, `artifact.ex`, the test file and the five files under `test/fixtures/hex_tarballs/`.

## Files Created/Modified

- `lib/crosswake/release_candidate/artifact.ex` - `@build_env_excluded_packages`, `build_env!/1` (three clauses with the provenance comment), `drop_build_env/2` (two clauses), `provenance_line/1`, one `IO.puts(:stderr, ...)` in `inspect_cli!/1`
- `test/crosswake/release_candidate/artifact_real_tarball_test.exs` - three `provenance:` tests, now 22
- `test/fixtures/hex_tarballs/README.md` - `## Decision`
- `201-EVIDENCE/` - six gate-output and mutation files

## Decisions Made

- Followed PD-01 exactly as the user settled it on 2026-11-09; no checkpoint was needed or raised.
- The provenance line reads the unpacked `hex_metadata.config` with `:file.consult/1` and `List.keyfind/3` after validation, rather than widening the observation (the receipt shape and `@artifact_keys` stay unchanged).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The hermetic suite exceeded the foreground command limit and was moved to the background by the harness; it was left to finish alone (no second copy started) and its verdict line was read from the evidence file.
- `Monitor` was not available, so waits used bounded until-loops.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the stderr provenance line, which carries package, version, Hex version and a yes/no (T-201-29), plus the planned T-201-39, T-201-40, T-201-41 and T-201-28 mitigations, each shown by a test and a mutation above.

## Threat model status

- T-201-39: `build_env!/1` runs before the exclusion for every package; six `shape:` tests; the `no-validation` mutation turns exactly those six red.
- T-201-40: description, requirement, links and payload-byte controls each go red on their own mutation; `@metadata_keys` and the payload digest are unchanged.
- T-201-41: the allow-list is untouched; the unknown-key test still raises (it is among the passing 22).
- T-201-28: the list is checked by exact-line grep, the core is absent, an unlisted package keeps `build_env`; the `core-excluded` mutation turns the two core controls red.

## Not verified here

- The emission of the provenance lines from `inspect_cli!/1` in a real run. The content is tested; the `Enum.each` to stderr is not (no unit test builds the six-package family). The first CI run of `hex_artifacts.sh` or `verify_companion_cleanroom.sh` after merge will show the lines in the logs.
- The fix on a live exact-public proof run. That is Plan 07's job via the 0.2.14 release PR.
- The privacy scan: nothing was pushed here. Plan 04 scans before any push.
- A Hex release newer than 2.7.0 was not available to test; the core's sensitivity to it is the recorded consequence, not a measured one.

## Next Phase Readiness

Ready for 201-04 (push of the fix branch and its PR, privacy scan first). The fix branch holds four local commits above origin/main and is not pushed; no PR, merge, tag or publish was done in this plan.

## Self-Check: PASSED

All six evidence files exist; worktree commits `5b7e572c` and `be335acc` and main-checkout commits `d2a8da43`, `3604f69e` and `5bb56953` are ancestors of their branch heads; the worktree is clean (`git status --porcelain` prints nothing); all task acceptance criteria and plan verify commands were re-run and passed.

---
*Phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run*
*Completed: 2026-11-09*
