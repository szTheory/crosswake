---
phase: 166-clean-checkout-engineering-quality
plan: 03
subsystem: testing
tags: [artifact-policy, generated-contracts, git-index, privacy-safe-diagnostics]
requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: dependency-aware repository runner with NUL-preserving Git snapshots
provides:
  - closed three-class repository artifact policy with one narrow safe fixture
  - exact eight-output generated-contract registry
  - non-staging byte drift detection with focused-mode restoration
  - escaped artifact diagnostics and byte-identical Git index proof
affects: [166-clean-checkout-engineering-quality, repository-quality, contract-drift]
actuals:
  tokens: 9907
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [closed JSON artifact policy, explicit generated-output registry, snapshot-owned byte restoration]
key-files:
  created:
    - script/repository_artifact_policy.json
    - test/crosswake/proof/phase166_repository_quality_test.exs
    - test/fixtures/repository_quality/artifact-cases.json
  modified:
    - script/repository_verification_stages.json
    - script/verify_repository.mjs
    - test/js/repository_verification.test.mjs
key-decisions:
  - "Treat generated contracts as a registry within the intentionally tracked class while keeping the three artifact intents closed."
  - "Restore only registered output snapshots after every generator outcome and disable optional Git index refresh during inspection."
  - "Render suspicious paths as escaped data and never interpolate them into remediation command text."
requirements-completed: [ENG-03, ENG-04]
coverage:
  - id: D1
    description: A closed three-class artifact policy reconciles transient families, tracked source, forbidden tracked families, and the sole safe example-host env fixture.
    requirement: ENG-03
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/phase166_repository_quality_test.exs --only artifact_policy
        status: pass
    human_judgment: false
  - id: D2
    description: The repository-cleanliness stage regenerates all eight contract outputs without staging, restores exact bytes, and preserves index records on success and failure.
    requirement: ENG-03
    verification:
      - kind: integration
        ref: test/js/repository_verification.test.mjs#generated-contract production runner preserves index and restores bytes
        status: pass
      - kind: integration
        ref: script/verify_repository.sh --stage repository-cleanliness
        status: pass
    human_judgment: false
  - id: D3
    description: Artifact and drift failures expose only a stable category, escaped repository-relative path, and one non-secret correction.
    requirement: ENG-04
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/phase166_repository_quality_test.exs
        status: pass
      - kind: integration
        ref: node --test test/js/repository_verification.test.mjs
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-09-09
status: complete
---

# Phase 166 Plan 03: Artifact Intent and Generated-Contract Drift Summary

**A closed artifact policy now classifies repository intent and regenerates eight tracked contracts byte-for-byte without staging, leaking suspicious contents, or disturbing pre-existing state.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-09T17:06:13Z
- **Completed:** 2026-09-09T17:21:05Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a closed, ordered artifact policy for ignored transient, intentionally tracked, and forbidden tracked intent, with `examples/phoenix_host/.env` as the sole exact safe fixture.
- Registered the canonical generator, fixed default/dev argv, all eight generated outputs, and one correction command.
- Integrated artifact and generated-contract validation into `repository-cleanliness`, restoring exact registered bytes after success, drift, or generator failure.
- Proved index bytes and staged records remain identical and diagnostics escape hostile paths without printing contents.

## Task Commits

1. **Task 1 RED: artifact-policy contracts** — `b8b1ea91` (test)
2. **Task 1 GREEN: closed artifact intent policy** — `aa7a1213` (feat)
3. **Task 2 RED: generated drift and index proof** — `ebd7a83a` (test)
4. **Task 2 GREEN: non-staging generated-contract runner** — `17a95489` (feat)
5. **Task 2 security fix: escaped hostile diagnostics** — `16a59080` (fix)

## Files Created/Modified

- `script/repository_artifact_policy.json` — Closed artifact classes, narrow safe fixture, and exact generated registry.
- `script/repository_verification_stages.json` — Purpose-named repository-cleanliness remediation while preserving the existing CI owner identity.
- `script/verify_repository.mjs` — Policy validation, forbidden tracked-path inspection, explicit generator execution, restoration, and narrow diagnostics.
- `test/js/repository_verification.test.mjs` — Production-runner proof for drift, generator failure, byte restoration, and index preservation.
- `test/crosswake/proof/phase166_repository_quality_test.exs` — Structural policy and eight-output registry proof.
- `test/fixtures/repository_quality/artifact-cases.json` — Safe, forbidden, concealed, ambiguous, unknown, and hostile-path cases.

## Decisions Made

- Generated contracts are represented separately from ordinary tracked source but remain part of the intentionally tracked artifact intent.
- Git inspection sets `GIT_OPTIONAL_LOCKS=0` so read-only verification cannot refresh index bytes.
- Suspicious repository paths are JSON-escaped in diagnostics and remain data, never command text.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Security] Kept hostile artifact paths out of remediation commands**
- **Found during:** Final Task 2 threat-model review
- **Issue:** A forbidden tracked filename was initially interpolated into correction text, which could let control characters shape terminal output.
- **Fix:** Paths are now JSON-escaped diagnostic fields, remediation stays fixed, and a newline-bearing forbidden-path fixture protects the boundary.
- **Files modified:** `script/verify_repository.mjs`, `test/fixtures/repository_quality/artifact-cases.json`, `test/crosswake/proof/phase166_repository_quality_test.exs`
- **Verification:** Full Node and Phase 166 ExUnit suites pass.
- **Commit:** `16a59080`

---

**Total deviations:** 1 auto-fixed (1 Rule 2 security correction)
**Impact on plan:** The correction strengthens T-166-09 and T-166-11 without changing artifact classes, generated outputs, or public stage identity.

## Issues Encountered

- The checked-in Elixir/Erlang versions are not installed on this host. Focused ExUnit and real generator verification ran with the already-installed Elixir 1.19.5 / Erlang 28.4.1 pair; no global tool installation or repository contract change was made.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Plan 04 can build engineering-quality ownership evidence over the closed artifact and generated-contract policy.
- `guard-02-generate-and-diff` remains unchanged for its later atomic CI migration.

## Self-Check: PASSED

- All six created/modified plan files and this summary exist.
- All five TDD and security-fix commits exist in Git history.
- Artifact-policy, generated-registry, full Node, full focused ExUnit, and real repository-cleanliness checks passed after the final change.
- No production `git add` or `git clean` behavior exists in the repository verification runner.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-09*
