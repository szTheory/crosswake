---
phase: 174-clean-room-host-realism-adopter-fidelity
plan: 07
subsystem: testing
tags: [phoenix, clean-room, installer, doctor, matrix, non-vacuity]
requires: []
provides:
  - Matrix clean-room hosts run the real Crosswake installer and recompile before doctor.
  - Captured candidate-local evidence proves ten installer-before-doctor profile/pass pairs.
  - Independent source, evidence, and mutation checks protect ROOM-02.
affects: [clean-room-proof, release-candidate-full-proof, ROOM-02]
actuals:
  tokens: 12500
  tasks: 3
  commits: 0
tech-stack:
  added: []
  patterns: [literal matrix profile/pass evidence roster, scratch-clone candidate proof]
key-files:
  created:
    - test/crosswake/proof/phase174_matrix_install_order_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/evidence/174-matrix-install-local-run.log
  modified:
    - script/verify_companion_cleanroom.sh
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-CLEANROOM-EVIDENCE.md
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-NON-VACUITY.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
key-decisions:
  - "Install against the generated Phoenix router path, then recompile before route assertions and doctor."
  - "Capture candidate-local proof from a temporary clone with a scratch-only commit; keep the main repository uncommitted because its Git metadata is read-only."
patterns-established:
  - "Matrix installer and doctor markers carry source mode, profile, and pass identity only after successful commands."
  - "Independent checks use literal expected profile/pass values and mutation controls against copies."
requirements-completed: [ROOM-02]
coverage:
  - id: D1
    description: "Each matrix clean-room profile/pass runs Crosswake install and doctor in order."
    requirement: ROOM-02
    verification:
      - kind: integration
        ref: "evidence/174-matrix-install-local-run.log#ten-profile-pass-order"
        status: pass
      - kind: other
        ref: "bash -n script/verify_companion_cleanroom.sh"
        status: pass
      - kind: other
        ref: "bash script/assert_manifest_contract_unchanged.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "The independent matrix order check rejects missing, empty, duplicate, and reversed evidence."
    requirement: ROOM-02
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase174_matrix_install_order_test.exs#all (9 tests)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase174_cleanroom_host_realism_test.exs and phase174_cleanroom_lane_parity_test.exs"
        status: pass
    human_judgment: false
---

# Phase 174 Plan 07: Matrix Clean-Room Installer Order Summary

**Matrix Phoenix hosts install Crosswake, recompile, and pass doctor across all ten candidate-local profile/pass runs.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-09-25T17:35:24Z
- **Completed:** 2026-09-25T18:14:55Z
- **Tasks:** 3
- **Files modified or created:** 8

## Accomplishments

- Added `mix crosswake.install --router lib/clean_room_host_web/router.ex` after initial compile in the shared matrix loop, followed by warning-as-error recompilation before downstream checks and doctor.
- Captured a successful hermetic candidate-local matrix run from scratch commit `fc79b3162830568d42a84aca0a6bc6628fbe701a`; all five profiles across both passes reported installer before doctor.
- Added nine independent checks with literal profile/pass expectations and source deletion, unknown-mode, missing marker, reversed order, empty log, generator-only, and missing-file controls.
- Reconciled ROOM-02 evidence in the clean-room evidence, non-vacuity record, requirements traceability, and roadmap.

## Task Commits

No main-repository commits were made because the repository's `.git` metadata is read-only. The evidence run used a temporary scratch-only commit, `fc79b3162830568d42a84aca0a6bc6628fbe701a`, whose sole changed path was the harness script.

## Files Created/Modified

- `script/verify_companion_cleanroom.sh` — runs the adopter installer and recompiles each matrix host before doctor.
- `test/crosswake/proof/phase174_matrix_install_order_test.exs` — checks the loop, evaluator result, ten ordered pairs, and mutation controls.
- `evidence/174-matrix-install-local-run.log` — captured candidate-local proof output and evaluator result.
- `174-CLEANROOM-EVIDENCE.md`, `174-NON-VACUITY.md`, `REQUIREMENTS.md`, and `ROADMAP.md` — record ROOM-02 closure and its evidence.

## Decisions Made

- Followed the CI setup shape in the scratch clone, including isolated root dependency setup before candidate artifact generation.
- Invoked the mode-100644 harness through `bash`, matching the supported CI command.

## Deviations from Plan

**1. [Execution adjustment] Reproduced CI dependency setup in the scratch clone.**
- **Found during:** Task 2
- **Issue:** The first clean clone lacked root Mix dependencies, so candidate artifact generation stopped before matrix execution.
- **Fix:** Ran `mix deps.get` with invocation-owned `MIX_HOME` and `HEX_HOME`, matching the workflow's setup action, then rebuilt artifacts.
- **Verification:** The six-artifact build and full matrix run passed.

**2. [Execution adjustment] Used `bash` to invoke the clean-room script.**
- **Found during:** Task 2
- **Issue:** Direct execution returned 126 because the tracked script mode is `100644`.
- **Fix:** Re-ran using the workflow's supported `bash script/verify_companion_cleanroom.sh` form.
- **Verification:** Harness exited 0 with all ten pairs and expected evaluator fields.

**Total deviations:** 2 execution adjustments. **Impact:** Both reproduced the established CI invocation and did not alter product scope.

## Issues Encountered

- The initial artifact run failed due to missing root dependencies; resolved as described above.
- The first test run exposed use of unavailable `String.index/2`; replaced with `:binary.match/2`. The independent test then passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 174-07 is complete and ROOM-02 evidence is captured. Re-run Phase 174 goal verification before advancing; leave Phase 175 release state untouched.
- Focused Phase 174 Elixir checks passed (9 new + 18 existing), doctor contract guard passed, and `npm test` passed 133 tests.
- No publishing task, credential, or release authority was used.

---
*Phase: 174-clean-room-host-realism-adopter-fidelity*
*Completed: 2026-09-25*
