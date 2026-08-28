---
phase: 158-adoption-reset-and-route-map
plan: "08"
subsystem: protected privacy CI
tags: [github-actions, elixir, mix-task, privacy, trust-boundary, tdd]
dependency_graph:
  requires: [158-07, filesystem-privacy-gate]
  provides: [trusted-pr-private-term-enforcement, fail-closed-fork-protection]
  affects: [phase-158-validation, protected-promotion]
tech_stack:
  added: []
  patterns: [event-provenance-gate, secret-free-fork-failure, non-echoing-remediation]
key_files:
  created: []
  modified:
    - .github/workflows/hex-page-proof.yml
    - test/mix/tasks/crosswake_adoption_context_scan_test.exs
decisions:
  - Protected private-term scans run only for trusted same-repository PRs, main pushes, and manual dispatches; fork PRs fail closed without secret exposure.
metrics:
  duration: 5m
  completed_date: 2026-07-31
  tasks_completed: 1
  files_changed: 2
status: complete
---

# Phase 158 Plan 08: Trusted PR Privacy Gate Summary

The protected private-term scan now enforces privacy before merge for trusted same-repository pull requests, while fork-originated pull requests remain secret-free and explicitly fail closed.

## Accomplishments

- Added a same-repository provenance condition so protected scans run for trusted PRs as well as main pushes and manual dispatches.
- Added a fork-only blocking step with stable maintainer-controlled remediation, without inspecting or injecting protected input.
- Added focused workflow regressions for provenance expressions, secret placement, fork blocking, and absence of `pull_request_target`.

## Verification

- Passed: `mix test test/mix/tasks/crosswake_adoption_context_scan_test.exs` (5 tests, 0 failures).
- Passed: `mix crosswake.adoption_context.scan`.
- Passed: `mix format --check-formatted test/mix/tasks/crosswake_adoption_context_scan_test.exs`.
- Passed: `git diff --check`.

## Task Commits

1. **Task 1: Enforce one protected PR path end to end without crossing the fork boundary**
   - `943fae49` — failing structural workflow regressions for trusted provenance and fork blocking.
   - `9c5d10b1` — provenance-gated protected scan and secret-free fork failure path.

## Decisions Made

- Repository identity comparison is the trust boundary: only a pull request whose head repository equals `github.repository` may receive the protected private-term environment value.
- A fork cannot satisfy the protected check through untrusted workflow execution; it must use a trusted maintainer-controlled branch or merge-queue check.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Formatting] Formatted the new structural regression before GREEN verification**
- **Found during:** Task 1 verification.
- **Issue:** `mix format --check-formatted` reported the newly added assertion layout.
- **Fix:** Applied the repository formatter and reran all task verification commands.
- **Files modified:** `test/mix/tasks/crosswake_adoption_context_scan_test.exs`
- **Commit:** `9c5d10b1`

## Known Stubs

None.

## Self-Check: PASSED

- Both modified task files exist.
- Both TDD gate commits exist in git history.
- No workflow step gives fork-originated pull-request code the protected repository secret.
