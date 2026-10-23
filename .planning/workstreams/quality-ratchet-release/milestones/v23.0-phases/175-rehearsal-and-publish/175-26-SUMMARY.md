---
phase: 175-rehearsal-and-publish
plan: 26
subsystem: release-infrastructure
tags: [github-actions, ios-mirror, mix, integrity-scanner]
requires: []
provides:
  - Ordinary iOS publishing jobs install the pinned Beam runtime and locked Mix dependencies before mirror evaluation.
  - Job-scoped scanner and seeded regressions guard setup presence and order.
affects: [175-27, 175-28, release-workflow]
actuals:
  tokens: 1579
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [job-scoped workflow contract with seeded missing and late-setup mutations]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-26-SUMMARY.md]
  modified: [.github/workflows/release-please.yml, script/check_release_workflow_integrity.exs, test/crosswake/proof/phase175_release_recovery_test.exs]
key-decisions:
  - "Use the existing pinned setup-beam action and strict .tool-versions pattern from the ordinary workflow's linked-release rollup."
  - "The candidate adapter regression uses a local bare remote and no SSH agent, deploy key, or execute flag; it asserts a closed no-authority outcome."
patterns-established:
  - "Ordinary publish job runtime setup is checked inside that exact job so rehearsal setup cannot satisfy the contract."
requirements-completed: [REL-13]
coverage:
  - id: D1
    description: Ordinary iOS publish installs strict pinned Beam and checks locked Mix dependencies before mirror publication.
    requirement: REL-13
    verification:
      - kind: integration
        ref: "elixir script/check_release_workflow_integrity.exs"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase175_release_recovery_test.exs#ordinary iOS job requires its own pinned Beam setup before mirror publish"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release-please.yml"
        status: pass
    human_judgment: false
  - id: D2
    description: The iOS candidate adapter reports no write authority without deploy credentials or the execute flag.
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase175_release_recovery_test.exs#iOS candidate adapter refuses without deploy credentials or execute authority"
        status: pass
    human_judgment: false
completed: 2026-09-24
status: complete
---

# Phase 175 Plan 26 Summary

**The ordinary iOS mirror job now prepares its pinned Mix runtime before evaluating the approved mirror write.**

## Performance

- **Duration:** Not recorded in this resumed session
- **Started:** Not recorded
- **Completed:** 2026-09-24
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added strict `setup-beam` and `mix deps.get --check-locked` to `publish-ios-core` after exact release-tag checkout and before the mirror command.
- Added `release.ios.ordinary_mix_setup` to the scanner's declared roster and checks.
- Added seed-red tests for missing and late setup plus a nonpublishing candidate-adapter check without write credentials.

## Task Commits

1. **Task 1: Carry pinned Mix from ordinary checkout to mirror policy** — `b413827c` (`fix`)
2. **Task 2: Check workflow syntax and nonpublishing evaluator path** — included in `b413827c` (`fix`)

## Decisions Made

- Reused the existing exact setup-beam pin and strict `.tool-versions` contract.
- Used a local bare Git remote for the candidate adapter fixture; the command returned its expected blocked/no-authority outcome with `external_state_changed=false`.

## Deviations from Plan

- The initial candidate invocation attempted `git subtree split`, which could not write its cache under the sandbox's read-only `.git`; the committed regression supplies the split SHA and local read-only remote instead, preserving the no-publication assertion.

## Issues Encountered

- A workspace-wide `git diff --check` reported trailing whitespace in the already-dirty `175-PATTERNS.md`. The plan-scoped whitespace check passed; that unrelated file was left untouched.
- `mix format --check-formatted` also reported pre-existing formatting drift elsewhere in `script/check_release_workflow_integrity.exs`; this plan's additions are formatted, and unrelated lines were not rewritten.

## Next Phase Readiness

- Plan 175-26 is complete. Continue with 175-27 (ordinary Maven identity and receipt binding).
- This plan performed no release workflow, registry, mirror publication, or recovery action and grants no publication authority.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-24*
