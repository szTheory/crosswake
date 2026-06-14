---
phase: 111-generator-rewire-clean-room-proof-release
plan: 02
subsystem: doctor
tags: [publish-readiness, generator, parity, proof, tests]
requires:
  - phase: 111-generator-rewire-clean-room-proof-release
    provides: 111-01 published iOS and Android generator coordinates
  - phase: 111-generator-rewire-clean-room-proof-release
    provides: 111-03 publish-readiness docs parity whitelist
provides:
  - generator_coordinate_parity ReadinessCheck in publish readiness
  - merge-blocking static guard for non-local generator template coordinates
  - mirrored generator template render assertions in mix test
  - Phase 52 publish-readiness fixture updated with the parity check
affects: [doctor, publish-readiness, generator-tests, proof-fixtures]
tech-stack:
  added: []
  patterns:
    - EEx template rendering as deterministic static publish-readiness proof
    - Relative template paths in readiness details for portable fixtures
key-files:
  created:
    - .planning/phases/111-generator-rewire-clean-room-proof-release/111-02-SUMMARY.md
  modified:
    - lib/crosswake/doctor/publish_readiness.ex
    - test/crosswake/doctor/publish_readiness_test.exs
    - test/mix/tasks/crosswake_gen_shell_test.exs
    - test/fixtures/proof/phase52_publish_readiness.json
key-decisions:
  - "Use cwd for template rendering, but report stable relative template paths in readiness details to avoid local absolute-path fixture churn."
  - "Reject the old Android dependency GAV `dev.crosswake:shell-core-android` rather than every `dev.crosswake` string because the generated host app namespace remains `dev.crosswake.shell`."
patterns-established:
  - "Publish readiness can statically render generator templates with [local: false, version:, capabilities: []] to guard release-coordinate truth."
  - "Permanent generator coordinate checks should be mirrored in both doctor readiness and plain mix test."
requirements-completed: [PROOF-02]
duration: 6 min
completed: 2026-06-14
---

# Phase 111 Plan 02: Published-Dep Parity Guard Summary

**Publish readiness now has a merge-blocking generator coordinate parity check, and plain `mix test` mirrors the same non-local template assertions.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-14T22:17:00Z
- **Completed:** 2026-06-14T22:22:55Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `generator_coordinate_parity_check/1` to `Crosswake.Doctor.PublishReadiness` and wired it into `build_checks/4`.
- Rendered both non-local shell templates with `EEx.eval_file/2` using `[local: false, version:, capabilities: []]`.
- Made the check `proof_class: :merge_blocking`; failures become blocking readiness errors through `result_check/1`.
- Checked iOS for the szTheory SwiftPM coordinate, `upToNextMajorVersion`, live Crosswake version, and no local/old-org leakage.
- Checked Android for the io.github.sztheory Maven coordinate, live Crosswake version, and no old GAV/local project leakage.
- Added a publish-readiness negative test that proves stale/local coordinates become a blocking `:generator_coordinate_parity` failure.
- Added a generator-template render test so plain `mix test` catches coordinate drift independently of the doctor CLI.
- Refreshed the Phase 52 publish-readiness fixture with the new passing generator parity sidecar check.

## Task Commits

Each task was committed atomically:

1. **Task 1 + Task 2: Add generator_coordinate_parity check and mirrored tests** - `de6552b` (`feat(111-02): add generator coordinate parity guard`)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `lib/crosswake/doctor/publish_readiness.ex` - Adds and wires the `generator_coordinate_parity` readiness check.
- `test/crosswake/doctor/publish_readiness_test.exs` - Adds category/code coverage and negative blocking-path coverage for stale/local coordinates.
- `test/mix/tasks/crosswake_gen_shell_test.exs` - Adds direct non-local template render assertions for published coordinates and absent local/old-coordinate leakage.
- `test/fixtures/proof/phase52_publish_readiness.json` - Updates the normalized publish-readiness fixture with the new passing generator parity check.

## Decisions Made

- Kept `cwd` rendering per the plan, but recorded relative template paths in check details so fixtures are portable across checkouts.
- Narrowed the Android stale-coordinate rejection to `dev.crosswake:shell-core-android`; `dev.crosswake.shell` remains valid generated host app metadata.

## Deviations from Plan

- `mix crosswake.doctor --check-publish` without a router exits before publish-readiness evaluation in this repo. Verification used the managed test router and direct `Crosswake.Doctor.PublishReadiness.run/1` sidecar path.

## Issues Encountered

- The full doctor CLI still exits nonzero because the broader doctor report has native shell verification blockers. The publish-readiness sidecar itself reports `status: ready` and includes `diag.generator.coordinate_parity_ok`.

## Verification

- `mix test test/crosswake/doctor/publish_readiness_test.exs test/mix/tasks/crosswake_gen_shell_test.exs test/crosswake/proof/phase52_operator_truth_test.exs` passed: 19 tests, 0 failures.
- `MIX_ENV=test mix run -e 'report = Crosswake.Doctor.PublishReadiness.run(cwd: File.cwd!()); ...'` printed `status=ready` and `diag.generator.coordinate_parity_ok blocking=false result=pass proof=merge_blocking`.
- `MIX_ENV=test mix crosswake.doctor --router Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter --check-publish` printed `Publish readiness status: ready` with `diag.generator.coordinate_parity_ok`; process exit remained 1 because of pre-existing broader native shell doctor blockers.
- `mix test --exclude requires_example_host` ran after the final code change and reported 1009 tests with 2 failures, both in `Crosswake.Planning.MilestoneArcCloseoutParityTest` for missing `MILESTONE-ARC.md` Active strategic sections; those failures were present before Plan 111-02.
- `grep -n "generator_coordinate_parity_check(cwd)" lib/crosswake/doctor/publish_readiness.ex` matched the `build_checks/4` wiring.
- `grep -n "parity\|szTheory" test/mix/tasks/crosswake_gen_shell_test.exs` matched the mirrored template assertions.

## Self-Check: PASSED

- All tasks in `111-02-PLAN.md` are complete.
- Key files named in frontmatter exist and contain the expected parity guard, tests, and fixture updates.
- Requirement ID `PROOF-02` is represented in `requirements-completed`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 111-04 can now add the clean-room CI lane with a permanent doctor-side parity guard already protecting the generated dependency coordinates between release-time proof runs.

---
*Phase: 111-generator-rewire-clean-room-proof-release*
*Completed: 2026-06-14*
