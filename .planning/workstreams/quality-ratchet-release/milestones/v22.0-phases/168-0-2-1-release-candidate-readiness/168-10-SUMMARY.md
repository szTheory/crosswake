---
phase: 168-0-2-1-release-candidate-readiness
plan: "10"
subsystem: release-readiness
gap_closure: true
tags: [release-truth, regression-guard, tdd, ci, runbook]
requires:
  - phase: 168-09
    provides: Restored 0.2.1 manifest truth to author the guard against
provides:
  - Deterministic manifest-versus-published-tag guard with OK/FAIL/BLOCKED tri-state
  - Fixture-backed proof that the gap-3 defect class is detected independently of current repository state
  - Release-sensitive CI enforcement and runbook documentation of both failing states
affects: [release-please-next-candidate, companion-publish-runbook]
actuals:
  tasks: 2
  commits: 3
plan_head_before: 75cb0dfad8e6c5c2d5e9a1f3b7c4e2d0a9f8b6c1
tech-stack:
  added: []
  patterns: [tri-state-release-guard, blocked-never-collapsed-to-ok, semantic-newest-selection]
key-files:
  created:
    - script/check_release_version_truth.exs
    - test/crosswake/proof/phase168_version_truth_test.exs
  modified:
    - .github/workflows/crosswake-ci.yml
    - docs/COMPANION-PUBLISH-RUNBOOK.md
key-decisions:
  - "Treat AHEAD of the newest tag as OK, not a warning — being ahead is the normal pre-release state, and flagging it would make the guard noisy enough to be ignored on exactly the runs that matter."
  - "Keep BLOCKED as its own exit code (2) rather than folding it into OK or FAIL. A tagless shallow checkout must say 'unknown', because a guard that answers 'clean' when it cannot see published truth is worse than no guard."
  - "Use the built-in `JSON` module rather than `Jason`. The script runs under bare `elixir` with no deps loaded, matching check_release_workflow_integrity.exs; `Jason` is undefined in that context."
  - "Host the step in the existing release-candidate-full-proof job rather than adding a job — it is already release-sensitive and already checks out with fetch-depth: 0, and adding a job would require a CI leaf manifest change and a new required check (D-13)."
patterns-established:
  - "A release-integrity guard proves itself against the historical defect commit, not only against current repository state — the negative control here is c7edcd78's own manifest."
  - "Newest published version is selected with `Version.compare/2`, never lexicographic sort, so 0.10.0 correctly beats 0.9.0."
requirements-completed: []
requirements-addressed: [REL-03, REL-04]
---

# Plan 168-10 Summary — Regression guard for manifest-behind-published-truth

## Accomplishments

Closed gap 3's regression-guard half: the class of defect behind gap 3 is now detected deterministically, so a rollback-after-publish cannot silently re-arm a duplicate release.

**Task 1 — guard built under TDD.** `script/check_release_version_truth.exs` compares each linked core component's declared manifest version against the newest matching published tag. Tri-state: `OK` (0) at or ahead, `FAIL` (1) behind, `BLOCKED` (2) when published truth cannot be established.

**Task 2 — enforced and documented.** One step added to the existing release-sensitive `release-candidate-full-proof` job; runbook section distinguishing `FAIL` from `BLOCKED`.

## Task Commits

| Task | Commit |
|---|---|
| 1 (RED) | `95c72792` test(168-10): prove manifest version truth against published tags |
| 1 (GREEN) | `f5e7c750` fix(168-10): add release version truth guard |
| 2 | `e2f49b55` fix(168-10): run version truth guard in release-sensitive CI and document it |

## Evidence and Verification

**The decisive check — the guard catches the real incident:**

- Against `c7edcd78`'s own manifest (the commit that caused gap 3), with real repository tags: **exit 1**, all three components reported `declared 0.2.0 is BEHIND newest published 0.2.1`.
- Against the manifest as restored by 168-09: **exit 0**, all three `OK`.

So the guard is proven against the historical defect, not merely consistent with today's state.

- `mix test test/crosswake/proof/phase168_version_truth_test.exs` → 12 tests, 0 failures (RED first: 12 tests, 11 failures)
- `actionlint .github/workflows/crosswake-ci.yml` → clean
- `python3 script/check_ci_leaf_manifest.py --self-test` → pass, no leaf change needed
- `elixir script/check_release_workflow_integrity.exs` → 66 OK, 0 FAIL
- `mix crosswake.release.status` → no lockstep failure
- `mix test …phase168_version_truth_test.exs test/crosswake/release_candidate/` → 56 tests, 0 failures
- Guard command appears exactly once in the workflow
- Guard performs no network access and leaves `.release-please-manifest.json` unmodified (asserted)

## TDD Gate Compliance

RED committed before GREEN: `95c72792` (11 failing) precedes `f5e7c750`. Every behavior bullet has at least one fixture-backed assertion.

## Decisions Made

See `key-decisions` frontmatter.

## Deviations from Plan

### Auto-fixed

- **Issue:** First implementation used `Jason.decode/1`. Under bare `elixir` with no deps loaded, `Jason` is undefined — 9 of 12 tests failed with `UndefinedFunctionError`.
- **Fix:** Switched to the built-in `JSON` module, matching `check_release_workflow_integrity.exs`, which reads the same manifest the same way. The test file's own `Jason.encode!` is unaffected because it runs under `mix test`, where deps load.
- **Impact:** None on behavior or scope; the failure was environmental and caught by the plan's own RED-then-GREEN sequence.

**Total deviations:** 1 auto-fixed (environmental).

## Issues Encountered

None beyond the above.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Gap 3 is now fully closed on the code side; only its `CHANGELOG.md` public-facing half remains, owned by plan 168-11.
- The guard is release-sensitive, so it will run on the next release-candidate change without further wiring.
- Gaps 1 (CR-01) and 2 (canonical receipt) remain, owned by 168-12 and 168-13.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-15*
