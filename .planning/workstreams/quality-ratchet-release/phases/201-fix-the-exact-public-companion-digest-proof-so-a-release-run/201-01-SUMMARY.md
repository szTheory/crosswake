---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 01
subsystem: release-candidate
tags: [hex, build_env, digest, exact-public-proof, regression-test, real-fixtures]

requires:
  - phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
    provides: "200-08-BLOCKED.md: the five companion digest_mismatch findings of run 42639651064"
provides:
  - "Three real Hex tarball fixtures (public crosswake_rulestead 0.1.1, Hex 2.7.0 rebuild of its tag, public crosswake 0.2.13) with SHA256SUMS and a provenance README"
  - "Artifact.inspect_single!/2 (@doc false) single-artifact entry point over inspect_artifact!/2"
  - "19-test regression file written before the fix; 9 fail on the unchanged digest rule exactly as reasoned"
  - "Measured baselines at origin/main: 38 tests (artifact + cleanroom), 196 tests (release_candidate suite + phase172)"
affects: [201-02, 201-03, 201-04, 201-05, 201-07]

actuals:
  tokens: 4000
  tasks: 2
  commits: 4

plan_head_before: "0aa184704009c5baf9c3550cf7cf7fde9228f2b8 (worktree crosswake-201-wt, 2 commits); 10afd5a576f735e069de1a9b68edf3c5109134b4 (main checkout, 2 evidence commits)"
plan_head_after: "58afa0a8ca047f29edca4759b03ac159d9f4a2f4 (worktree); 1f9074083162b8b79f054444a56776b6a229cf46 (main checkout)"
commits: 4

tech-stack:
  added: []
  patterns:
    - "Real-output fixtures with a divergence floor, relation-only assertions and content controls"
    - "Red-before-fix evidence captured through script/mix_test_gate.sh --out"

key-files:
  created:
    - test/crosswake/release_candidate/artifact_real_tarball_test.exs
    - test/fixtures/hex_tarballs/crosswake_rulestead-0.1.1.public.tar
    - test/fixtures/hex_tarballs/crosswake_rulestead-0.1.1.rebuild.tar
    - test/fixtures/hex_tarballs/crosswake-0.2.13.public.tar
    - test/fixtures/hex_tarballs/SHA256SUMS
    - test/fixtures/hex_tarballs/README.md
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/baseline-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/rc-suite-baseline-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/real-tarball-red-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/real-tarball-red-full-201.txt
  modified:
    - lib/crosswake/release_candidate/artifact.ex
    - .gitattributes

key-decisions:
  - "Test names are flat (no describe blocks) so ExUnit failure output reads `test <prefix>: ...` and the plan's awk grading patterns and the 2-space `test \"` count hold"
  - "rewrite_metadata!/2 takes a list-to-list function (not a per-term map) because put_build_env/1 and drop_build_env/0 must drop terms"

requirements-completed: [REL-09]

coverage:
  - id: D1
    description: "A real pre-2.6 public rulestead tarball and a real Hex 2.7.0 rebuild of the same tag give unequal metadata_digest on the unchanged artifact.ex, captured red before any fix"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/artifact_real_tarball_test.exs#equality: public tarball and Hex 2.6+ rebuild of the same tag give equal digests (red by design; .planning/.../201-EVIDENCE/real-tarball-red-201.txt)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The full 19-test regression exists before the fix; the old rule fails exactly the equality, six shape and two companion build_env tests and passes the 10 controls"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "script/mix_test_gate.sh --min 19 on artifact_real_tarball_test.exs -> rc=2 ran=19 failures=9 reason=mix_rc (201-EVIDENCE/real-tarball-red-full-201.txt)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Baselines measured at origin/main before any change"
    requirement: REL-09
    verification:
      - kind: unit
        ref: "201-EVIDENCE/baseline-201.txt (ran=38 failures=0 PASS); 201-EVIDENCE/rc-suite-baseline-201.txt (ran=196 failures=0 PASS)"
        status: pass
    human_judgment: false

duration: 30min
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 01: Real-tarball regression for the build_env digest defect Summary

**Three real Hex tarballs (public rulestead 0.1.1, its Hex 2.7.0 rebuild, public core 0.2.13) plus a 19-test file that reproduces the companion `digest_mismatch` on real data: red on the unchanged digest rule (9 failures, exactly the ones reasoned), fix still to come in Plan 03.**

## Performance

- **Duration:** about 30 min
- **Completed:** 2026-11-09T19:44Z
- **Tasks:** 2
- **Files modified:** 12 (3 tarballs, SHA256SUMS, README, .gitattributes, artifact.ex, the test file, 4 evidence files)

## Accomplishments

- Reproduced the defect on real tarballs through `Artifact`, the path the release uses. The metadata digests differ (`5e444f8c...` public vs `edff10ce...` rebuild), the payload digests are equal. These prefixes match the values in 201-RESEARCH.md. The digests appear only in captured gate output, not in the test.
- Floors hold on real data: the rebuild and the public core 0.2.13 carry `build_env [{"hex", "2.7.0"}]`; the public rulestead tarball has no `build_env`.
- Baselines measured at origin/main `0aa18470`: `artifact_test.exs` + `cleanroom_test.exs` ran 38, `test/crosswake/release_candidate/` + `phase172_per_package_ref_test.exs` ran 196, both PASS.
- Red-before-fix recorded twice: the four Task 1 tests (`ran=4 failures=1`, the equality test) and the full file (`ran=19 failures=9`). The nine failures are the equality test, six `shape:` tests and two `companion build_env:` tests. The ten passes are the three floors, two `core build_env:` controls, four content controls and the unknown-key test.
- Each failure is for the intended reason: shape tests print `Expected exception ArgumentError but nothing was raised`; companion tests print `Assertion with == failed` on digests. No compile error or crash.
- Added the `@doc false` `Artifact.inspect_single!/2` (adds lines only; `inspect_metadata!/3`, `inspect_family!/1`, `inspect_cli!/1` and the observation shape are untouched).

## Task Commits

Code commits are in worktree `~/projects/crosswake-201-wt` on `fix/exact-public-build-env-provenance` (not pushed):

1. **Task 1: tracer, three real fixtures, equality red** - `55cead25` (test)
2. **Task 2: shape, companion/core build_env, content controls, unknown key** - `58afa0a8` (test)

Evidence commits in the main checkout on `docs/199-release-0-2-12`:

- `e87fb17a` docs(201-01): measured baselines and the red real-tarball equality run
- `1f907408` docs(201-01): red run of the full real-tarball regression before the fix

**Plan metadata:** the SUMMARY commit that follows this file (docs: complete plan).

## Files Created/Modified

- `lib/crosswake/release_candidate/artifact.ex` - `@doc false` `inspect_single!/2` (same three `rescue` clauses as `inspect_family!/1`)
- `test/crosswake/release_candidate/artifact_real_tarball_test.exs` - 19 tests, `async: true`, untagged
- `test/fixtures/hex_tarballs/` - three `.tar` fixtures, `SHA256SUMS` (provenance, not a test pin), `README.md` (fetch and rebuild commands, Hex 2.7.0, tag commit `096371e3`)
- `.gitattributes` - `test/fixtures/hex_tarballs/*.tar binary`
- `201-EVIDENCE/` - four gate-output files, each ending in its `mix-test-gate:` verdict line

## Decisions Made

- Flat test declarations rather than `describe` blocks (see key-decisions), so failure lines read `test shape: ...` as the plan's grading awk expects.
- `rewrite_metadata!/2` takes a list-to-list function so drop-and-append rewrites work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Hex install needed pinned asdf versions in the scratch directory**
- **Found during:** Task 1 (fixture rebuild)
- **Issue:** `mix local.hex --force` run from the scratch directory exited 126 (`No version is set for command mix`) because the scratch directory has no `.tool-versions`.
- **Fix:** exported `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.19.5-otp-27` for all scratch commands (the plan already sets them for `hex.build`). Hex 2.7.0 then installed into the isolated `MIX_HOME`.
- **Files modified:** none (command environment only)
- **Verification:** `mix hex.info` printed `Hex: 2.7.0`, `Elixir: 1.19.5`, `OTP: 27.3`; rebuilt `metadata.config` contains `build_env [{"hex","2.7.0"}]`.
- **Committed in:** n/a

**2. [Rule 1 - Bug] First test draft used `describe` blocks**
- **Found during:** Task 1 (red run)
- **Issue:** `describe` prefixes the test name in failure output (`test equality (the defect ...) equality: ...`) and indents declarations to 4 spaces, which would break the plan's Task 2 awk patterns and the 2-space `test "` count of 19.
- **Fix:** flattened to top-level `test` declarations before the first commit; re-captured the Task 1 red run.
- **Files modified:** `test/crosswake/release_candidate/artifact_real_tarball_test.exs`
- **Verification:** both red runs list names as `test <prefix>: ...`; `awk` count is 19.
- **Committed in:** `55cead25`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug in the draft). **Impact on plan:** none on scope; no expectation was adjusted.

## Issues Encountered

None beyond the two deviations. The evidence-commit lock was free both times (Plan 02 was not committing at the same time). The absence guard `elixir script/check_absence_is_not_success.exs` exits 0 with the new test file in the tree, and the existing 38 artifact and cleanroom tests still pass after the entry point was added.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the `@doc false` entry point, which validates `output_root` through `regular_directory!/1` and uses the same `rescue` mapping as `inspect_family!/1`.

## Not verified here

- The fix itself (Plan 03). The nine red tests have not been observed green.
- The privacy scan was not run; nothing was pushed. Plan 04 scans the three fixtures before any push.
- Fixture payloads were rebuilt on macOS arm64 only; the rebuild's payload digest equals the public tarball's here.

## Next Phase Readiness

Ready for 201-03 (the fix). Its floors are measured: 38 and 196 tests at origin/main, 19 tests in the new file (9 red).
The code branch `fix/exact-public-build-env-provenance` has two local commits above origin/main and is not pushed.

## Self-Check: PASSED

All created files exist; commits `55cead25`, `58afa0a8` (worktree) and `e87fb17a`, `1f907408` (main checkout) are ancestors of their branch heads.

---
*Phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run*
*Completed: 2026-11-09*
