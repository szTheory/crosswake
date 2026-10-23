---
phase: 175-rehearsal-and-publish
plan: 96
subsystem: release-evidence
tags: [node, git, diagnostic-classification, privacy]
requires:
  - phase: 175-95
    provides: "Attempt-bound terminal Plan95 journal and local collector seam"
provides:
  - "Closed stage and process-reason diagnostics for injected source-split failures"
  - "Private provenance checks that reject callback-forged failure classifications"
affects: [REL-13, REL-17, Phase175]
actuals:
  tokens: 4636
  tasks: 2
  commits: 4
  plan_head_before: ea01e94b91c653dc28733e50c5efc4032ba43411
  plan_head_after: 2805b5946f5df859404bb05aa48b90efefedb272
tech-stack:
  added: []
  patterns:
    - "Private WeakMap provenance for closed Git diagnostic values"
    - "Fixed call-site stage names and allowlisted process reasons"
key-files:
  created: []
  modified:
    - script/release_candidate/plan87_mirror_ref.mjs
    - script/release_candidate/plan87_mirror_ref.test.mjs
    - script/release_candidate/plan94_mirror_read.test.mjs
key-decisions:
  - "Only Git process failures created by the internal classifier may contribute a reason; arbitrary callback error properties map to UNKNOWN."
  - "A local fixture diagnosis does not change release readiness or satisfy REL-13/REL-17."
patterns-established:
  - "Safe Git diagnostics contain only fixed stage and reason enum values."
requirements-completed: []
coverage:
  - id: D1
    description: "Plan95-shaped injected failures report their fixed Git stage and closed process reason without leaking raw values."
    verification:
      - kind: unit
        ref: "script/release_candidate/plan94_mirror_read.test.mjs#Plan95 reports the seventh injected Git failure as a closed subtree split diagnostic"
        status: pass
      - kind: unit
        ref: "script/release_candidate/plan87_mirror_ref.test.mjs#Git failure projection admits only internally classified reasons and keeps raw data out"
        status: pass
    human_judgment: false
  - id: D2
    description: "The sealed Plan95 result remains BLOCKED with unknown historical cause and unchanged release holds."
    verification:
      - kind: other
        ref: "mix crosswake.release.mirror_tag_026 --mode plan95-inspect --path-set .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan95-path-set.json --expect terminal --json"
        status: pass
    human_judgment: false
decisions:
  - "Keep Plan95's historical seventh-call cause UNKNOWN; Plan96 proves only how a future injected failure is classified."
metrics:
  duration: "16 min"
  completed: 2026-10-07
  commits: 4
status: complete
---

# Phase 175 Plan 96: Closed Git Failure Diagnostics Summary

**Injected Git failures now expose only a fixed source-split stage and allowlisted process reason, with callback-forged classifications rejected.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-10-07T20:50:26Z
- **Completed:** 2026-10-07T21:06:28Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Bound each of the nine existing source-split Git calls to its own fixed stage enum without changing call order, request bounds, cleanup, or operation-journal schema.
- Classified spawn failure, timeout, interruption, nonzero exit, and invalid output with closed reason values. Arbitrary callback errors and forged stage/reason properties become `UNKNOWN`.
- Added a Plan95-shaped fake showing six successful Git callbacks followed by a seventh `SUBTREE_SPLIT/NONZERO_EXIT` failure, with no eighth or ninth callback and no private sentinel in the diagnostic or journal.
- Preserved the terminal Plan95 result and all release holds; no new live evidence or release authority was created.

## Execution and Verification

- **Task 1 RED:** `node --test script/release_candidate/plan94_mirror_read.test.mjs` — the named regression ran and failed because stage/reason were absent; 6 passed, 1 failed. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`; semantic inspection confirmed an assertion failure on the planned diagnostic.
- **Task 1 GREEN:** the same focused Node suite passed: 7 tests, 0 failures, 0 skipped. `node --check script/release_candidate/plan87_mirror_ref.mjs` passed.
- **Task 2 RED:** `node --test script/release_candidate/plan87_mirror_ref.test.mjs script/release_candidate/plan94_mirror_read.test.mjs` — 25 passed and 2 failed on the planned callback-forgery assertions. The classifier returned `RED_EVIDENCE_OK`; the intended target assertion failed, with no setup or collection errors.
- **Task 2 GREEN:** the combined Node suite passed: 27 tests, 0 failures, 0 skipped. Node syntax check passed.
- **Plan95 terminal inspection:** `mix crosswake.release.mirror_tag_026 --mode plan95-inspect --path-set .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan95-path-set.json --expect terminal --json` passed. The sealed result digest remains `12f777396c0a87b3c25779b063985b9dbec3ac47a15bde1420ca7cd1c82cf91d`, with 6 API fetch invocations and 7 Git attempts. Status remains `BLOCKED/OBSERVATION_UNAVAILABLE`; the saved record identifies the final stage by call order only, and its cause remains UNKNOWN.
- The exact Plan95 digest/count/hold assertion passed. `git diff --check` passed for all three Plan96 source/test files.
- **Tracer feedback gate:** re-ran the Task 1 Node suite and syntax check against the final implementation; 7 tests passed, 0 failures or skips, and syntax passed.

## Task Commits

1. **Task 1 RED test** — `42ef5119` (`test(175-96): add failing subtree split diagnostic regression`)
2. **Task 1 GREEN implementation** — `8ce5508e` (`feat(175-96): classify Git split stage and process reason`)
3. **Task 2 RED tests** — `9e43a32f` (`test(175-96): add closed Git failure classification regressions`)
4. **Task 2 GREEN implementation** — `2805b594` (`fix(175-96): reject forged Git failure classifications`)

Phase 175 configuration sets `phase_commit_docs.175=false`; the summary and state/roadmap handoff updates therefore remain uncommitted. No unrelated dirty or untracked files were staged.

## Files Modified

- `script/release_candidate/plan87_mirror_ref.mjs` — closed Git reason classification, per-call stage attribution, and private metadata validation for safe projections.
- `script/release_candidate/plan87_mirror_ref.test.mjs` — process-outcome classification and redaction regressions.
- `script/release_candidate/plan94_mirror_read.test.mjs` — Plan95-shaped seventh-call attribution and forged-callback rejection coverage.

## Decisions Made

- A callback's public `stage` or `reason` fields are not evidence. Only internally branded process outcomes can contribute to a diagnostic reason.
- Local failure classification does not promote candidate facts or readiness and does not close REL-13 or REL-17.

## Deviations from Plan

None. The forged-reason check directly enforces the plan's spoofing mitigation.

## Issues Encountered

- The sandbox initially denied `.git` writes. The explicitly authorized, file-scoped staging and task commits succeeded through the elevated Git path. The measured plan base was preserved in `/private/tmp` because `.git` is read-only in the workspace permission profile.
- `state.advance-plan` could not parse the pre-existing STATE.md plan position because it lacks canonical labeled position lines. I updated `current_plan`, the current handoff, metric, decision, and session through the GSD state handlers; the roadmap handler confirmed 77/81 summaries and Phase175 remains in progress. The state progress handler also reported that its body `Progress:` line is absent, while its frontmatter already reflects 107/111 completed plans.

## User Setup Required

None.

## Next Phase Readiness

Last completed phase: 174. Phase 175 remains incomplete. Plan95's one-time check stopped during the local Git step that splits source history for the mirror, and the reason was not recorded. Plan96 improves local error reporting only; it did not check remote tags or PR status and did not run CI. Do not retry Plan95. No next command is eligible until we have new current facts about the source tag, mirror tag, and PR, or approval for a new, limited read-only check to gather them. If that happens, start with `$gsd-discuss-phase 175 --ws quality-ratchet-release`, then plan the check. No CI run or release action is authorized. REL-13/14/15/17 remain OPEN; readiness remains BLOCKED; merge policy remains UNKNOWN; release hold remains ACTIVE; Plans45–48 remain HELD.

## Self-Check: PASSED

- Summary file exists at the workstream phase path.
- All four Plan96 task commits are ancestors of `HEAD`.
- The three Plan96 source/test files have no stub placeholders and pass `git diff --check`.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-07*
