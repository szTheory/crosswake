---
phase: 177-maintenance-and-queue-reconciliation
plan: 05
subsystem: release-maintenance
tags: [documentation, release-guidance, source-qualification]
requires:
  - phase: 177-maintenance-and-queue-reconciliation
    provides: Current generic task proof, source dispositions, and qualified source binding from Plans 02, 03, and 08
provides:
  - README release links that route pre-release and incident work to their owners
  - Runbook command syntax aligned with the current candidate task's source-bound selectors
  - Incident guidance that preserves unknown historical mirror outcomes without treating an absent launcher as authority
affects: [177-06, 178-clean-source-verification]
actuals:
  tokens: 2911
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [focused README-to-task documentation contract]
key-files:
  created: []
  modified:
    - README.md
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - docs/RELEASE-INCIDENT-RESPONSE.md
    - test/crosswake/guides/release_boundaries_test.exs
key-decisions:
  - "Keep the four supported generic release task owners discoverable and describe candidate evaluation as a local receipt write, not a publication action."
  - "Keep absent candidate-read and mirror-tag modes historical; the retained Phase175 mirror receipts remain UNKNOWN and do not authorize recovery."
  - "Defer committed-source ancestry and matching full CI to Phase178; this recovery overlay is not a committed-source proof."
patterns-established:
  - "The README points maintainers to separate pre-release and post-failure owners, while the executable test checks the supported status and candidate command surface."
requirements-completed: []
coverage:
  - id: D1
    description: README links and runbook instructions reach supported status and source-bound candidate task owners.
    requirement: MAINT-06
    verification:
      - kind: unit
        ref: test/crosswake/guides/release_boundaries_test.exs#README release path reaches supported status and source-bound candidate tasks
        status: pass
      - kind: integration
        ref: mix crosswake.docs.sync --check
        status: pass
    human_judgment: false
  - id: D2
    description: Incident guidance retains historical uncertainty and does not treat an absent mirror-tag launcher as recovery authority.
    requirement: MAINT-03
    verification:
      - kind: unit
        ref: test/crosswake/proof/phase175_runbook_ancestry_test.exs
        status: pass
      - kind: integration
        ref: script/check_release_runbook_ancestry.sh with last committed runbook change, pinned source HEAD, and runbook path
        status: pass
    human_judgment: false
duration: not reliably measured
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 05: Release Guidance Summary

**The README now separates pre-release and incident routes, and the runbook uses the current source-bound candidate interface while retaining historical outcomes as unknown.**

## Performance

- **Duration:** Not reliably measured.
- **Completed:** 2026-10-12.
- **Tasks:** 2.
- **Files modified:** 4 owned files in the qualified source clone; two inherited Plan 02 test edits remain in that clone.

## Accomplishments

- Routed README readers to the companion pre-release runbook and the incident-response owner. Clarified that status is read-only, `--live` adds best-effort registry probes, and status does not create candidate evidence or authorize publication.
- Corrected the candidate command to include the evidence directory and all four required run selectors. Documented its local receipt output, fail-closed malformed or stale selectors, and one correction at the evidence owner.
- Kept historical candidate-read and mirror-tag modes out of active guidance. Incident recovery now preserves the Phase175 `UNKNOWN` mirror receipts and directs maintainers to stop until a separately reviewed, supported operation exists.
- Added a focused README/runbook-to-task assertion. No executable capability owner or generated guide changed, so no guide regeneration was needed.

## Task Commits

None. The protected recovery checkout prohibits commits. The 177-05 cumulative source bundle was recorded and replayed successfully against a fresh clone, including the two inherited Plan 02 test files.

## Files Created/Modified

- `README.md` — distinct pre-release and incident links plus the read-only status boundary.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — accurate status behavior and current source-bound candidate command.
- `docs/RELEASE-INCIDENT-RESPONSE.md` — preserves historical uncertainty and removes absent mirror-tag mode as active recovery authority.
- `test/crosswake/guides/release_boundaries_test.exs` — focused public route and command-owner contract.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json` — owner/status/count binding updated by the private cumulative source-bundle recorder.

## Decisions Made

- `MAINT-03` and `MAINT-06` remain pending parent acceptance. The documentation and ancestry checks do not prove archived reader equivalence or Phase178 committed-source CI.
- The exact source remains pinned at `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. The uncommitted overlay ancestry is explicitly deferred to Phase178.
- Phase175's 8/9 result, REL-10 breach, and parked adopter truth were not edited or softened.

## Deviations from Plan

None. The command assertion was updated alongside the documentation because its former example omitted required candidate selectors.

## Verification

```sh
mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/proof/phase175_runbook_ancestry_test.exs
```

21 tests passed.

- `mix crosswake.docs.sync --check` — passed.
```sh
elixir script/check_release_workflow_integrity.exs
```

98 of 98 checks passed.

```sh
script/check_release_runbook_ancestry.sh "$(git log -1 --format=%H -- docs/RELEASE-INCIDENT-RESPONSE.md)" "$(git rev-parse HEAD)" docs/RELEASE-INCIDENT-RESPONSE.md
```

passed against the actual last committed runbook change and pinned source HEAD.

- `git diff --check` — passed.
- `qualify_source.mjs record-patch --owner 177-05` — six cumulative changed paths, zero untracked source files, exact fresh-clone replay passed.

## Issues Encountered

The pre-existing guide test required a candidate example that omitted the current task's evidence directory and CI/Hex/iOS/Maven run IDs. The focused contract was aligned with the task parser and the final prescribed suite passed.

## User Setup Required

None.

## Next Phase Readiness

The docs overlay is bound to the pinned source tree. Phase178 must qualify this exact content in its committed source and matching full CI run. Historical reader equivalence remains unproven, so no retirement claim or MAINT-03 completion is made here.

## Self-Check: PASSED

The canonical summary file exists; all four owned source files are present in the owner bundle; the 177-05 private patch replay matched the clone's changed paths and bytes; all listed checks passed.

---
*Phase: 177-maintenance-and-queue-reconciliation*
*Completed: 2026-10-12*
