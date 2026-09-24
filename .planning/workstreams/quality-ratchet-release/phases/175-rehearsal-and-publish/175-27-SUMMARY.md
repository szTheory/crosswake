---
phase: 175-rehearsal-and-publish
plan: 27
subsystem: release-infrastructure
tags: [maven-central, github-actions, candidate-receipt, release-guard]
requires:
  - phase: 175-26
    provides: ordinary iOS runtime repair and plan-scoped workflow proof
provides:
  - Ordinary Maven publication requires the exact guard-selected READY receipt and matching merge identity before Gradle.
  - Historical Phase 168 identity pins remain recovery-only.
  - Scanner and local synthetic merge tests guard receipt selection, digest, identity, and authority separation.
affects: [175-28, 175-29, release-workflow]
actuals:
  tokens: 5197
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [receipt digest and exact merge identity validated before registry tooling]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-27-SUMMARY.md]
  modified: [.github/workflows/release-please.yml, script/release_candidate/android_publication.sh, script/check_release_workflow_integrity.exs, test/crosswake/proof/phase175_release_recovery_test.exs]
key-decisions:
  - "The approved guard exports its exact first-parent base OID for downstream receipt validation."
  - "The Android publish job independently requires one unexpired artifact with the head-bound name, exact two-file roster, and approved digest before credentials are exposed."
  - "The shell adapter applies Phase 168 identity pins only in recovery mode; ordinary observe and execute validate the supplied receipt and exact two-parent merge."
patterns-established:
  - "Ordinary native release lanes validate receipt provenance and merge identity before invoking publication tooling."
requirements-completed: [REL-13]
coverage:
  - id: D1
    description: Ordinary Maven observe and execute accept only the exact approved receipt and two-parent merge identity.
    requirement: REL-13
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase175_release_recovery_test.exs#ordinary Android observe accepts a synthetic exact merge and receipt"
        status: pass
      - kind: integration
        ref: "test/crosswake/proof/phase175_release_recovery_test.exs#ordinary Android observe rejects wrong bindings before publication"
        status: pass
      - kind: integration
        ref: "elixir script/check_release_workflow_integrity.exs"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release-please.yml"
        status: pass
    human_judgment: false
  - id: D2
    description: Phase 168 recovery pins and the ordinary receipt chain fail closed under seeded mutations.
    requirement: REL-13
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase175_release_recovery_test.exs#Android receipt workflow and recovery identity assertions reject seeded gaps"
        status: pass
      - kind: other
        ref: "bash -n script/release_candidate/android_publication.sh"
        status: pass
    human_judgment: false
duration: Not recorded
completed: 2026-09-24
status: complete
---

# Phase 175 Plan 27 Summary

**Ordinary Maven publishing now validates the canonical candidate receipt and exact merge before Gradle, with Phase 168 pins limited to recovery.**

## Performance

- **Duration:** Not recorded in this resumed session
- **Started:** Not recorded
- **Completed:** 2026-09-24
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added a guard output for the merge's first-parent base and a receipt download step scoped to `publish-android-core`.
- Required exactly one unexpired head-named artifact, exact downloaded file roster, approved SHA-256, READY state, bound/observed equality, exact version/base/head/tree, and no publication mutation before Maven credentials.
- Updated `android_publication.sh` so ordinary observe/execute requires the receipt file and validates the checked-out two-parent merge; the four historical pins now apply only to recovery.
- Added local synthetic merge tests, wrong-binding cases including wrong base, execute-path stub coverage, and scanner mutations for missing download, wrong cardinality, digest, artifact name, receipt argument, and recovery pin scope.

## Task Commits

1. **Task 1: Accept an exact successor in observe mode through the ordinary Maven boundary** — `1a2c0daf` (`fix`)
2. **Task 2: Guard the ordinary and recovery authority split structurally** — included in `1a2c0daf` (`fix`)

## Decisions Made

- Kept canonical receipt provenance checks in the guarded publish job before the step that receives Maven secrets.
- Used a stub `gradlew` only in the local fixture to prove that an exact ordinary `--execute` identity reaches the runner without network or registry activity.

## Deviations from Plan

- None. All publication checks used local fixture repositories; no Release Please workflow, Maven coordinate, or registry was dispatched.

## Verification

- `elixir script/check_release_workflow_integrity.exs` — 79/79 checks passed.
- `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1` — 12 tests, 0 failures.
- `actionlint .github/workflows/release-please.yml` — passed.
- `bash -n script/release_candidate/android_publication.sh` — passed.
- Plan-scoped `git diff --check` — passed.

## Next Phase Readiness

- Plan 175-27 is complete. Plan 175-28 is the next wave and requires live candidate, CI, registry-absence, three-rehearsal, and receipt evidence. Stop before 175-29's blocking-human Gate 2 task unless a new exact authorization is obtained after its fresh evidence is prepared.
- The prior 0.2.4 authorization remains consumed. This plan grants no publication authority.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-24*
