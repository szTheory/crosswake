---
phase: 175-rehearsal-and-publish
plan: 36
subsystem: infra/testing
tags: [github-actions, release-pipeline, hex, ios, maven, mutation-testing, rel-17]

# Dependency graph
requires:
  - phase: 175-rehearsal-and-publish
    provides: "Plan 175-35 release evidence contract and candidate-bound policy inputs"
provides:
  - "REL-17 operation-scoped gates at release creation, ordinary, recovery, companion, and final script boundaries"
  - "Exact cross-path integrity roster with independent guard-removal mutations"
  - "Local control closure record; no fresh candidate or publish authorization"
affects: [175-37, 175-38, 175-39, 175-40, 175-41, release-pipeline]

# Actuals (#2632)
actuals:
  tokens: 31929
  tasks: 3
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Re-fetch the shared operation-bound live evidence immediately before each external release side effect."
    - "Keep immutable payload checkouts separate from trusted current-main release tooling."

key-files:
  created:
    - script/release_candidate/load_release_evidence_context.sh
    - test/support/phase175_rel17_fixtures.ex
    - test/crosswake/proof/phase175_rel17_publish_paths_test.exs
    - test/crosswake/proof/phase175_rel17_recovery_paths_test.exs
    - test/crosswake/proof/phase175_rel17_wiring_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-REL17-CLOSURE.md
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - .github/workflows/ios-mirror-backfill.yml
    - script/guarded_hex_publish.sh
    - script/release_candidate/ios_mirror.sh
    - script/release_candidate/android_publication.sh
    - script/check_release_workflow_integrity.exs
    - lib/crosswake/release_candidate/evidence_gate.ex
    - lib/crosswake/release_candidate/evidence_live.ex
    - test/support/release_workflow_fixtures.ex
    - test/crosswake/release_candidate/evidence_gate_test.exs
    - test/crosswake/release_candidate/evidence_live_test.exs

key-decisions:
  - "Linked release stays core-only, companion publication is package-scoped, and recovery permits only the exact six-package Hex family; Maven and iOS recovery stay core-scoped."
  - "The legacy Phase 168 mirror entry uses trusted current-main tooling and requires fresh linked-release evidence before SSH credentials."
  - "REL-17 closure is local control evidence only; fresh candidate-specific evidence and separate exact authorization remain necessary for any future publication."

requirements-completed: [REL-17]

# Coverage metadata
coverage:
  - id: D1
    description: "Release creation and every ordinary, recovery, companion, and final publication side effect use a fresh operation-bound gate."
    requirement: REL-17
    verification:
      - kind: integration
        ref: test/crosswake/proof/phase175_rel17_publish_paths_test.exs
        status: pass
      - kind: integration
        ref: test/crosswake/proof/phase175_rel17_recovery_paths_test.exs
        status: pass
      - kind: integration
        ref: test/crosswake/proof/phase175_rel17_wiring_test.exs
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release-please.yml .github/workflows/hex-publish.yml .github/workflows/ios-mirror-backfill.yml"
        status: pass
    human_judgment: false
  - id: D2
    description: "The strict authorization context loader and pure/live validators enforce operation, package, candidate, merge, and policy scope."
    requirement: REL-17
    verification:
      - kind: unit
        ref: test/crosswake/release_candidate/evidence_gate_test.exs
        status: pass
      - kind: unit
        ref: test/crosswake/release_candidate/evidence_live_test.exs
        status: pass
      - kind: integration
        ref: test/crosswake/proof/phase175_rel17_recovery_paths_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: "The declared REL-17 guard roster and additive closure record make each gate-removal or bypass mutation reviewable."
    requirement: REL-17
    verification:
      - kind: other
        ref: elixir script/check_release_workflow_integrity.exs
        status: pass
      - kind: integration
        ref: test/crosswake/proof/phase175_rel17_wiring_test.exs
        status: pass
      - kind: other
        ref: "git diff --check"
        status: pass
    human_judgment: false

duration: 150min
completed: 2026-09-26
status: complete
---

# Phase 175 Plan 36: REL-17 Publication Controls Summary

**Shared live evidence now gates release creation and every ordinary, recovery, companion, and final publication boundary, with mutations proving the guards are required.**

## Performance

- **Duration:** approximately 150 min
- **Started:** 2026-09-26T14:40:22Z (phase execution start recorded in workstream state)
- **Completed:** 2026-09-26T17:10:10Z
- **Tasks:** 3
- **Files modified:** 18

## Accomplishments

- Added strict, private authorization-context loading and operation/package-scoped live evidence checks across the existing release and recovery routes.
- Added an exact REL-17 scanner roster and independent mutations for release creation, publisher jobs, recovery entries, companion jobs, final side-effect checks, and token handoff.
- Recorded local control closure and exact verification evidence while preserving the requirement for fresh candidate-specific evidence and separate authorization.

## Task Commits

1. **Task 1: Guard ordinary Release Please and core publishers** - `bd7815ed` (linked release and ordinary publisher gates)
2. **Task 2: Guard exact-ref recovery entries with a distinct operation** - `2cf9a15a` (recovery operation scoping and validator coverage)
3. **Task 3: Guard companion jobs and lock paths into existing CI** - `79147bae` (declared guard roster, mutation tests, and closure record)

**Plan metadata:** recorded with the completion commit.

## Files Created/Modified

- `.github/workflows/release-please.yml`, `.github/workflows/hex-publish.yml`, `.github/workflows/ios-mirror-backfill.yml` - Gate release creation, ordinary publishers, recovery entries, the retained legacy iOS mirror route, and companion jobs.
- `script/release_candidate/load_release_evidence_context.sh` - Validate the exact authorization tuple and write private runner context.
- `script/guarded_hex_publish.sh`, `script/release_candidate/ios_mirror.sh`, `script/release_candidate/android_publication.sh` - Re-fetch live evidence at final Hex, iOS, and Maven mutation boundaries.
- `lib/crosswake/release_candidate/evidence_gate.ex`, `evidence_live.ex` - Enforce the shared operation/package scope in pure and live validation.
- `script/check_release_workflow_integrity.exs` - Declare the exact REL-17 cross-path roster in the existing integrity lane.
- `test/support/phase175_rel17_fixtures.ex` and `test/crosswake/proof/phase175_rel17_{publish_paths,recovery_paths,wiring}_test.exs` - Seed authorized envelopes and prove independent path mutations fail closed.
- `test/support/release_workflow_fixtures.ex`, `test/crosswake/release_candidate/evidence_{gate,live}_test.exs` - Cover exact package recovery scope in fixtures and validators.
- `175-REL17-CLOSURE.md` - Record local control closure and verification outputs.

## Decisions Made

- Operation and package identity stay explicit end to end. Recovery supports only the six exact Hex packages; Maven and iOS recovery remain core-scoped.
- The retained legacy iOS mirror entry uses trusted current-main tooling and a separate immutable payload checkout, with a fresh gate before credentials.
- This plan closes implementation controls only. It does not prepare a fresh candidate or authorize publication.

## Deviations from Plan

### Auto-fixed Issues

**1. Unsupported workflow permission rejected by actionlint**
- **Found during:** Task 3 verification
- **Issue:** The workflow declared an unsupported `administration: read` permission.
- **Fix:** Removed the unsupported permission while retaining the supported least-privilege permissions.
- **Files modified:** `.github/workflows/release-please.yml`, `.github/workflows/hex-publish.yml`, `.github/workflows/ios-mirror-backfill.yml`
- **Verification:** `actionlint` passed on all three workflows.
- **Committed in:** `79147bae` (workflow changes were included in the scoped implementation commits)

**Total deviations:** 1 auto-fixed (workflow validity)
**Impact on plan:** Required for valid GitHub workflow configuration; no release scope was added.

## Issues Encountered

- A mutation test exposed a scanner position check that treated `nil` as greater than an integer under Elixir term ordering. The check was corrected to require integer positions; the affected mutation suites then passed.
- No workflows were dispatched, no merge or registry/mirror mutation occurred, and no human UAT was needed for these executable control assertions.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 175-36 is complete and ready for Plan 175-37. No fresh candidate, recovery, or publication is authorized by this plan.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-26*
