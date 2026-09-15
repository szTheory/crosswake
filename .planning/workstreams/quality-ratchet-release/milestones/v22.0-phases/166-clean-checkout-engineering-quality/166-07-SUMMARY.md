---
phase: 166-clean-checkout-engineering-quality
plan: 07
subsystem: testing
tags: [exact-commit, isolated-checkout, pinned-toolchain, darwin-arm64, repository-evidence]
requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: recurring repository quality contract and bounded ownership remediation
provides:
  - exact-commit isolated repository capture from a dirty source checkout
  - invocation-local pinned Darwin/arm64 BEAM, Node, and Java environment
  - closed evidence projection with temporary private logs and exact owned-root cleanup
affects: [166-clean-checkout-engineering-quality, canonical-evidence, repository-verification]
actuals:
  tokens: 31987
  tasks: 2
  commits: 9
tech-stack:
  added: []
  patterns: [explicit tracked-commit isolation, literal artifact authority and SHA-256 pins, invocation-owned tool roots]
key-files:
  created:
    - script/capture_repository_verification_evidence.sh
    - script/run_repository_evidence_environment.sh
    - script/repository_evidence_toolchain.json
  modified:
    - script/repository_verification_stages.json
    - test/js/repository_verification.test.mjs
key-decisions:
  - "Resolve evidence input only from an explicit tracked commit and never copy source worktree or index state."
  - "Materialize the declared Darwin/arm64 toolchain beneath one invocation-owned root with literal upstream authorities and SHA-256 pins."
  - "Commit the authorized install/doctor correction set separately before binding exact-commit verification to the new supported HEAD."
patterns-established:
  - "Exact-commit proof clones a named reachable commit into an empty isolated checkout and projects only allowlisted evidence fields."
  - "Executable tool artifacts are checksum-verified before extraction, archive entries are containment-checked, and all paths remain invocation-local."
requirements-completed: [ENG-01, ENG-03, ENG-04]
coverage:
  - id: D1
    description: Exact-commit capture excludes dirty source bytes, validates closed results, and removes all invocation-owned temporary state.
    requirement: ENG-03
    verification:
      - kind: integration
        ref: script/capture_repository_verification_evidence.sh --self-test
        status: pass
      - kind: unit
        ref: test/js/repository_verification.test.mjs#capture self-test proves exact-commit isolation
        status: pass
    human_judgment: false
  - id: D2
    description: Darwin/arm64 provisioning materializes the four declared runtimes from immutable authorities and passes production preflight at the tracked HEAD.
    requirement: ENG-01
    verification:
      - kind: integration
        ref: script/run_repository_evidence_environment.sh --self-test
        status: pass
      - kind: integration
        ref: script/run_repository_evidence_environment.sh --prepare-and-preflight --source-repository . --commit d4212d1b4c822b788b06cce8b1e88f56c67d3725
        status: pass
    human_judgment: false
  - id: D3
    description: Capture and environment contracts remain aligned with recurring repository quality and CI stage authority.
    requirement: ENG-04
    verification:
      - kind: integration
        ref: script/check_phase166_clean_checkout_engineering_quality.sh
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-09-09
status: complete
---

# Phase 166 Plan 07: Commit-Addressed Capture and Evidence Environment Summary

**Exact tracked commits can now be verified from dirty source repositories using a checksum-pinned, invocation-local Darwin/arm64 toolchain without leaking worktree bytes, private logs, or global state.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-09-09T20:05:30Z
- **Completed:** 2026-09-09T20:30:24Z
- **Tasks:** 2
- **Files modified:** 24

## Accomplishments

- Added strict commit-addressed capture with reachable-commit validation, empty isolated checkout, complete facade execution, closed evidence projection, and owned-root cleanup on every outcome.
- Added a closed Darwin/arm64 toolchain lock and executable environment for Erlang 27.3, Elixir 1.19.5 on OTP 27, Node 22.14.0, and Temurin 17.0.20.1+1 without credentials or global installation.
- Verified the authorized install/doctor baseline at 1,594 root tests and all six example-host seed/class cells, committed it separately, then passed real production preflight at exact HEAD `d4212d1b`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: exact-commit capture contract** — `4e73e23e` (test)
2. **Task 1 GREEN: exact-commit repository capture** — `5183cee8` (feat)
3. **Task 2 RED: evidence environment contract** — `c7915bfc` (test)
4. **Task 2 GREEN: pinned evidence toolchain** — `3d03fb41` (feat)
5. **Task 2 correction: system Bash cleanup guards** — `2e33e50f` (fix)
6. **Task 2 correction: bounded capture failure status** — `6922500f` (fix)
7. **Task 2 correction: safe failed-stage identities** — `ba95249d` (fix)
8. **Task 2 correction: pinned runtime probes** — `09708896` (fix)
9. **Authorized prerequisite baseline: install and doctor proof corrections** — `d4212d1b` (fix)

## Files Created/Modified

- `script/capture_repository_verification_evidence.sh` — Resolves a tracked commit, runs complete verification in an isolated checkout, and projects bounded evidence.
- `script/run_repository_evidence_environment.sh` — Provisions the locked runtime set beneath one owned temporary root and delegates exact-commit verification.
- `script/repository_evidence_toolchain.json` — Closed immutable Darwin/arm64 artifact authorities, archive layouts, probes, and SHA-256 pins.
- `script/repository_verification_stages.json` — Exact root runtime probes aligned with the supported OTP 27 toolchain.
- `test/js/repository_verification.test.mjs` — Hostile capture and provisioning controls for commit, path, archive, checksum, identity, cleanup, and evidence boundaries.
- Doctor/install source, guides, and tests — Authorized pre-existing corrections that make clean root and example-host verification pass at the supported commit.

## Decisions Made

- A dirty development checkout is acceptable only as an object database; capture reads the explicit tracked commit and copies none of the source checkout's working-tree or index state.
- Full child logs remain private to the invocation root. Retained output uses a closed schema and cannot contain payloads, credentials, tokens, identifiers, or arbitrary child keys.
- Tool materialization is limited to the four literal records in the lock, and Apple tooling is validated in place rather than installed.
- The authorized pre-existing install/doctor edits were reviewed, verified, and committed as an explicit prerequisite baseline instead of being folded into a capture-tool commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected system Bash cleanup and failure propagation**
- **Found during:** Task 2 production verification
- **Issue:** Cleanup ownership and child failure projection had shell/runtime edge cases that could mask a failure or reject the host Bash.
- **Fix:** Made cleanup guards compatible with system Bash, retained bounded child status, and projected failed stage identities safely.
- **Files modified:** `script/capture_repository_verification_evidence.sh`, `script/run_repository_evidence_environment.sh`, `test/js/repository_verification.test.mjs`
- **Verification:** Both self-test suites and all 22 repository runner tests pass.
- **Committed in:** `2e33e50f`, `6922500f`, `ba95249d`

**2. [Rule 1 - Bug] Corrected pinned runtime probes**
- **Found during:** Task 2 real Darwin/arm64 preparation
- **Issue:** Initial probe handling did not reliably bind each declared executable to its exact expected runtime output.
- **Fix:** Corrected the literal probes and composition checks for the pinned environment.
- **Files modified:** `script/run_repository_evidence_environment.sh`, `script/repository_evidence_toolchain.json`
- **Verification:** Real artifact preparation and production repository preflight pass at exact HEAD `d4212d1b`.
- **Committed in:** `09708896`

**3. [Rule 3 - Blocking] Committed the authorized install/doctor baseline before exact-HEAD verification**
- **Found during:** Task 2 exact-commit verification
- **Issue:** The prior committed baseline failed 8 root tests and 19 example-host tests with 22 invalid cases; the user's pre-existing unstaged edits contained the matching corrections.
- **Fix:** With explicit user authorization, reviewed and verified the 19-file correction set, excluded workstream-local state, and committed it separately before rerunning exact-commit preflight.
- **Files modified:** 19 install, doctor, public-guide, and regression-fixture files recorded in commit `d4212d1b`.
- **Verification:** Focused suite 81/81, root suite 1,594/1,594, and the full example-host matrix across seeds 17, 101, and 1009 in tagged and complete classes pass.
- **Committed in:** `d4212d1b`

---

**Total deviations:** 3 auto-fixed (2 Rule 1 correctness corrections, 1 Rule 3 blocking baseline correction)
**Impact on plan:** The corrections make the planned exact-commit path executable and bind it to a passing tracked baseline without widening evidence scope or creating canonical artifacts.

## Issues Encountered

- The first seed-1009 complete example-host matrix attempt reported one unidentified failure; an immediate exact-cell rerun passed 1,658/1,658 and a complete six-cell matrix rerun passed. No reproducible defect remained.
- The developer checkout lacks the repository-pinned OTP 27 asdf pairing. All focused baseline checks used the available Elixir 1.19.5/OTP 28 installation, while the production evidence route independently materialized and verified the exact required OTP 27 pair.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Plan 08 can select the supported-code commit and produce canonical isolated verification evidence using the already-committed capture path.
- No canonical Phase 166 evidence files were created by this plan.
- The three workstream-local runtime files remain untracked and excluded from product commits.

## Self-Check: PASSED

- All five planned capture/environment files exist and commits `4e73e23e`, `5183cee8`, `c7915bfc`, `3d03fb41`, `2e33e50f`, `6922500f`, `ba95249d`, `09708896`, and `d4212d1b` exist in history.
- Capture self-tests pass 8/8, environment self-tests pass 9/9, repository runner tests pass 22/22, and the recurring Phase 166 quality gate passes.
- Real pinned-tool preparation and production preflight pass for exact commit `d4212d1b4c822b788b06cce8b1e88f56c67d3725`.
- No canonical evidence artifact exists in the repository.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-09*
