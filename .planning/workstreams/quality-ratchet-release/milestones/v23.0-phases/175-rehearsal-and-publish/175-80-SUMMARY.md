---
phase: 175-rehearsal-and-publish
plan: 80
subsystem: testing
tags: [release-integrity, exunit, workflow-scanner, broken-windows]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan79's committed receipt helper and recorded passing local scanner/pre-update evidence
provides:
  - D-104 paragraph-bounded matrix prose assertion with exact normalized sentence comparison
  - D-105's evidence-limited PROVEN workflow structure claims for 13 publisher rows
  - Windows entry 36 resolved after the post-update suite and dynamic count gates
affects: [REL-17, Phase175-78-matrix, WINDOWS.md]
actuals:
  tokens: 3412
  tasks: 2
  commits: 2
plan_head_before: 2566a2abcefde8d7d6bf0602d6cb6322ad292abf
plan_head_after: 27e154e76405b5857fbd2e2db390cf7c403cfb80
tech-stack:
  added: []
  patterns: [paragraph-local whitespace normalization with exact sentence equality]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-80-SUMMARY.md]
  modified:
    - test/crosswake/proof/phase175_rel17_condition_paths_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md
    - .planning/WINDOWS.md
key-decisions:
  - "D-104: normalize whitespace only within the bounded explanatory paragraph, then compare the complete expected sentence including punctuation."
  - "D-105: promote only the 13 workflow_presence_order cells supported by passing named scanner checks and matching mutation/order assertions; preserve every unsupported cell and release hold."
requirements-completed: []
coverage:
  - id: D1
    description: "The REL-17 condition-path test enforces exact matrix structure and exact narrative content after paragraph-local whitespace normalization."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_rel17_publish_paths_test.exs test/crosswake/proof/phase175_rel17_recovery_paths_test.exs test/crosswake/proof/phase175_rel17_wiring_test.exs test/crosswake/proof/phase175_rel17_condition_paths_test.exs --max-cases 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Windows entry 36 is fixed only after the suite passes and dynamic pre/post status-count assertions pass."
    requirement: REL-17
    verification:
      - kind: other
        ref: "gsd_run windows status --raw dynamic assertions before and after gsd_run windows fixed 36"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-10-05
status: complete
---

# Phase 175 Plan 80: REL-17 Matrix and Ledger Summary

**REL-17's matrix records 13 locally verified publisher workflow structures, with the exact five-module suite and dynamic ledger gates passing before entry 36 was fixed.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-10-05T14:12:37Z
- **Completed:** 2026-10-05
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Scoped narrative whitespace normalization to the single explanatory paragraph and retained exact sentence wording and punctuation checks.
- Updated all 13 `workflow_presence_order` cells to `PROVEN` only against passing named scanner checks and their matching mutation/order assertions. `final_guard_execution`, response-row evidence, and unsupported cells remain `UNKNOWN`.
- Re-ran the workflow integrity scanner because scanner inputs changed after Plan79; it emitted 98/98 checks with 0 failures.
- Ran the exact post-update five-module Mix suite once: 40 tests, 0 failures.
- Passed the dynamic ledger gate with entry 36 `open` and counts 36 open / 0 fixed / 0 waived / 36 total, then fixed entry 36 and passed the fresh gate with 35 open / 1 fixed / 0 waived / 36 total.
- Preserved REL-13 and REL-17 as OPEN, candidate readiness as BLOCKED, merge policy as UNKNOWN, release hold as ACTIVE, Plans175-45 through 175-48 as HELD, and Phase175 as INCOMPLETE.

## Task Commits

1. **Task 1: Reapply the bounded matrix proof and pass the post-update suite** — `6109d0fb` (`docs`)
2. **Task 2: Resolve only Windows entry 36 after the dynamic count gate** — `27e154e7` (`docs`)

## Files Created/Modified

- `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` — asserts PROVEN only for supported workflow cells and compares the exact expected sentence after whitespace normalization within the bounded paragraph.
- `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md` — records the passing structural and mutation/order evidence without claiming real publisher execution.
- `.planning/WINDOWS.md` — marks entry 36 fixed after both required gates.

## Decisions Made

- D-104 keeps the narrative comparison strict while treating source line wrapping as presentation inside one captured paragraph.
- D-105 permits only supported structural workflow claims and ledger closure after fresh local verification; it grants no release authority.

## Deviations from Plan

None. The scanner rerun was the conditional D-105 response to changed scanner inputs. No provider or remote access, CI rerun, candidate Gate 2, merge, recovery, registry action, tag write, or publication occurred.

## Issues Encountered

- The initial task 1 staging attempt was blocked by repository sandbox permissions on `.git`; the scoped normal commit with hooks succeeded after the authorized write-access retry. No changes were lost.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan80 is complete. Phase174 remains the last completed phase; Phase175 remains incomplete with REL-13/REL-17 OPEN and the release hold active. The phase-level REL-13/14/15 coverage gap recorded by the plan checker remains unresolved. Next: `$gsd-discuss-phase 175 --ws quality-ratchet-release` to scope that gap before any additional plan. No release action is authorized.

## Self-Check: PASSED

- Both task commits exist in the current history and the three changed task files are committed.
- The exact suite, scanner, pre-update gate, and post-update gate results are recorded above.
- The stub scan found no placeholder/stub patterns in the files changed by this plan; no new security-relevant surface was introduced.
- Release holds and incomplete dispositions remain unchanged.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-05*
