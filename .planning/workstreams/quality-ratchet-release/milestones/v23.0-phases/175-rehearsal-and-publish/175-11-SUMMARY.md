---
phase: 175-rehearsal-and-publish
plan: 11
subsystem: release-integrity
tags: [github-actions, maven-central, receipt-authority, structural-scanner]
requires:
  - phase: 175-07
    provides: existing exact release authority and Maven rehearsal path
provides:
  - isolated manual Maven VALIDATED-to-DROP rehearsal workflow
  - mutation-tested receipt authority and no-bypass scanner guards
affects: [phase-175-release-recovery, release-please, maven-publish]
actuals:
  tokens: 2400
  tasks: 3
  commits: 3
tech-stack:
  added: []
  patterns: [declared workflow fixture overrides, raise-on-no-op seed-red structural proofs]
key-files:
  created:
    - .github/workflows/maven-publish-fire-drill.yml
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-RECOVERY-GUARDS.md
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase175_release_recovery_test.exs
key-decisions:
  - Maven rehearsal is a dedicated manual workflow with read-only repository permissions and no PR-mutating machinery.
  - Canonical receipt cardinality and head/tree/base identity remain fail-closed with no retry or bypass route.
requirements-completed: [REL-11, REL-13]
coverage:
  - id: D1
    description: Maven fire drill is physically isolated from Release Please while retaining disposable VALIDATED-to-DROP semantics.
    requirement: REL-11
    verification:
      - kind: integration
        ref: MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1
        status: pass
      - kind: other
        ref: elixir script/check_release_workflow_integrity.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Exact receipt authority and no-retry/bypass constraints reject seeded regressions.
    requirement: REL-13
    verification:
      - kind: integration
        ref: test/crosswake/proof/phase175_release_recovery_test.exs
        status: pass
      - kind: integration
        ref: test/crosswake/proof/phase173_recovery_proof_convergence_test.exs
        status: pass
    human_judgment: false
status: complete
---

# Phase 175 Plan 11: Release Recovery Isolation Summary

**A dedicated Maven Central Portal fire drill now proves signed disposable upload through VALIDATED then DROP without sharing Release Please or release-PR mutation authority.**

## Accomplishments

- Extracted the Maven rehearsal from the push-driven release workflow into a manual, read-only workflow with the signed local artifact checks and Central Portal VALIDATED-to-DROP sequence intact.
- Added a declared structural scanner surface and raise-on-no-op fixture mutations that reject embedded drills and PR/Release Please machinery.
- Added seed-red proof for exact-one unexpired canonical receipt identity and prohibited dispatch/rerun/individual-registry bypass routes.
- Recorded local guard evidence and the explicit zero-external-mutation boundary in `175-RECOVERY-GUARDS.md`.

## Task Commits

1. **Task 1: Extract one real Maven rehearsal path behind a seed-red isolation contract** — `af04f773` (`feat(175-11): isolate Maven fire drill`)
2. **Task 2: Seed-red the no-retry and exact-receipt authority boundary** — `b60c0bf5` (`test(175-11): prove receipt recovery guards`)
3. **Task 3: Record guard coverage and verify the isolated graph without dispatching it** — pending this metadata commit.

## Verification

- `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1` — passed (11 tests, 0 failures).
- `elixir script/check_release_workflow_integrity.exs` — passed with the declared nonempty roster and zero failures.
- No workflows were dispatched and no remote or registry state was changed.

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

The repository can now create a fresh candidate without reusing the mutating Maven rehearsal surface. Physical workflow evidence remains a later, separately authorized gate.
