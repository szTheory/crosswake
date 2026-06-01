---
phase: 50
plan: "02"
subsystem: diagnostics
tags: [doctor, mix-task, publish-readiness, json, formatter]
requires:
  - phase: 50
    provides: publish-readiness contract and derivation engine
provides:
  - mix crosswake.doctor --check-publish flag
  - optional publish_readiness doctor report payload
  - human Publish readiness section
  - conditional publish_readiness JSON object
affects: [phase-51, phase-52, doctor, support-truth, release-readiness]
tech-stack:
  added: []
  patterns: [conditional sidecar rendering, findings-first readiness integration]
key-files:
  created: []
  modified:
    - lib/mix/tasks/crosswake.doctor.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/doctor/formatter.ex
    - lib/crosswake/doctor/json_formatter.ex
    - test/mix/tasks/crosswake_doctor_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/doctor/formatter_test.exs
key-decisions:
  - "`--check-publish` is an additive flag on the existing doctor task, not a new command."
  - "JSON carries the machine contract; human output stays a concise sidecar section."
  - "Publish readiness findings merge into doctor only when the flag is enabled."
patterns-established:
  - "Doctor report fields may carry optional sidecar contracts without changing default output."
  - "Readiness checks render blocking items before warnings/advisories in human output."
requirements-completed: [DIAG-01, DIAG-02]
duration: 11min
completed: 2026-05-31
---

# Phase 50 Plan 02 Summary

**`mix crosswake.doctor --check-publish` with conditional human/JSON readiness output and findings integration**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-01T00:21:31Z
- **Completed:** 2026-06-01T00:32:16Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added strict `--check-publish` parsing to the existing `mix crosswake.doctor` task.
- Added optional `publish_readiness` to `Crosswake.Doctor.Report` and merged readiness findings only when the flag is enabled.
- Rendered the readiness contract in human and JSON output without changing unflagged output.
- Kept blocking exit behavior scoped to ordinary errors plus blocking publish-readiness checks under the flag.

## Task Commits

1. **Task 1: Lock the additive doctor contract with CLI, report, and formatter regressions** - `9987d63` (test)
2. **Task 2: Wire `--check-publish` through doctor report, human output, JSON output, and exit behavior** - `94cecb0` (feat)

## Files Created/Modified

- `lib/mix/tasks/crosswake.doctor.ex` - Added strict `--check-publish` option and passed `check_publish?: true` to doctor.
- `lib/crosswake/doctor/doctor.ex` - Added optional report sidecar and conditional readiness finding integration.
- `lib/crosswake/doctor/formatter.ex` - Added concise `Publish readiness` sidecar rendering.
- `lib/crosswake/doctor/json_formatter.ex` - Added conditional nested `publish_readiness` payload.
- `lib/crosswake/doctor/publish_readiness.ex` - Made missing host `CHANGELOG.md` a blocking local-truth check instead of a runtime raise.
- `test/mix/tasks/crosswake_doctor_test.exs` - Covered flag wiring, JSON gating, human output, and blocking readiness behavior.
- `test/crosswake/doctor/doctor_test.exs` - Covered optional report sidecar and findings integration.
- `test/crosswake/doctor/formatter_test.exs` - Covered human readiness rendering.

## Decisions Made

- No `--fail-on` flag was added; the default error threshold remains the only exit threshold in Phase 50.
- Readiness JSON is emitted only when `--check-publish` is enabled.
- The doctor CLI does not duplicate route inventory; provider/auth/notification/shell truth remains summarized as checks and findings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced invalid Mix test flag**
- **Found during:** Task verification
- **Issue:** The planned `mix test ... -x` command is unsupported in this environment.
- **Fix:** Used the equivalent file-scoped test command without `-x`.
- **Files modified:** None.
- **Verification:** `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/mix/tasks/crosswake_doctor_test.exs`
- **Committed in:** Not applicable; command-only deviation.

**2. [Rule 2 - Missing Critical] Avoided publish readiness crash outside repo cwd**
- **Found during:** Task 2 implementation
- **Issue:** Doctor task tests run from a temp host cwd. The readiness engine originally used `File.read!` for `CHANGELOG.md`, which would crash before it could report a blocking local publish-truth check.
- **Fix:** Missing changelog now produces the existing blocking publish parity check.
- **Files modified:** `lib/crosswake/doctor/publish_readiness.ex`
- **Verification:** CLI tests exercise `--check-publish` from a temp host cwd.
- **Committed in:** `94cecb0`

---

**Total deviations:** 2 auto-fixed (one command mismatch, one missing critical runtime guard).
**Impact on plan:** The public contract is unchanged; the CLI now fails as a structured readiness report instead of crashing on missing local publish truth.

## Issues Encountered

`gsd-sdk query verify.key-links` still reports a false negative for the `crosswake\\.doctor` test-link pattern even though `test/mix/tasks/crosswake_doctor_test.exs` contains `crosswake.doctor` in `@task` and test names. The behavioral tests and direct `rg` spot-check both confirm the link.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 51 can expand support-matrix and native rebuild truth knowing doctor now has a publish-readiness sidecar and stable JSON payload to consume.

## Self-Check: PASSED

- `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/mix/tasks/crosswake_doctor_test.exs` passed with 35 tests, 0 failures.
- Key modified files exist on disk.
- Production commits exist for `50-02`.

---
*Phase: 50-doctor-publish-and-readiness-checks*
*Completed: 2026-05-31*
