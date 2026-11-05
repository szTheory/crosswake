---
phase: 198-android-foreign-host-proof
plan: 03
subsystem: android-shell-core-ci
tags: [kotlin, jvm-tests, test-floor, junit-xml, ci, negative-controls]

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 02: Kotlin core JVM suite at 37 tests with BridgeChannelBoundaryTest at 20"
provides:
  - "script/check_kotlin_test_floor.py: forced fresh Gradle run, JUnit-XML-only floor gate"
  - "script/check_kotlin_test_floor_test.py: 13-test fixture selftest, one fixture per reason in the closed set"
  - "Two merge-blocking steps in the android-package-unit CI job"
affects: [198-04]

actuals:
  tokens: 5000
  tasks: 3
  commits: 3
plan_head_before: 2e649bc36844fda078bdb5a41aaef87ea4934a0c
plan_head_after: 67c3ed2e19399a2a4c0cef7122bfc848e43853a8

tech-stack:
  added: []
  patterns: ["pure evaluate() over parsed XML plus CLI wrapper", "derived equality (XML count equals source @Test count) instead of a pinned literal", "fake gradlew in a temp dir to test the gradle_failed path without Gradle"]

key-files:
  created:
    - script/check_kotlin_test_floor.py
    - script/check_kotlin_test_floor_test.py
  modified:
    - .github/workflows/crosswake-ci.yml

key-decisions:
  - "Option A: separate steps after the pinned android-package-proof stage; script/repository_verification_stages.json untouched (C7)"
  - "A missing androidx.webkit dependency line is treated as webkit_comment_untruthful (fail closed: the comment cannot be verified)"
  - "gradle_failed is inserted first in the reason list, but the XML is still evaluated and every reason printed"

requirements-completed: [AND-02]

coverage:
  - id: D1
    description: "Floor checker passes on the real tree after a forced fresh run"
    requirement: AND-02
    verification:
      - kind: integration
        ref: "python3 script/check_kotlin_test_floor.py --run -> kotlin-floor: tests=37 source_tests=37 boundary=20 floor=25 verdict=PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every failure reason has a fixture that turns it red next to a positive control"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "python3 script/check_kotlin_test_floor_test.py (Ran 13 tests, OK); mutation check: disabling count and skip checks turned 3 tests red"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both run in merge-blocking android-package-unit without changing the stage schema"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "check_ci_leaf_manifest.py --self-test pass; phase165/134 mix gate 47/47; repository_verification node suite 41 pass 0 fail"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-11-05
status: complete
---

# Phase 198 Plan 03: Kotlin test-floor gate Summary

**A stdlib checker forces a fresh `testDebugUnitTest` run and fails closed unless fresh JUnit XML shows at least 25 tests, zero failures or skips, XML count equal to the source `@Test` count, 10 or more boundary testcases and every load-bearing named test; a 13-test fixture selftest proves every reason, and both run in the merge-blocking `android-package-unit` job. JVM evidence only; nothing was run on a device.**

## Accomplishments

- Real tree, forced run: `kotlin-floor: tests=37 source_tests=37 boundary=20 floor=25 verdict=PASS` (derived equality held).
- Closed reason set, all eleven with their own fixture: `no_results`, `below_floor`, `failures`, `skipped`, `duplicate_suite`, `count_mismatch`, `boundary_below_min`, `named_test_missing`, `serialization_dependency_present`, `webkit_comment_untruthful`, `gradle_failed`.
- Negative-control strength measured: weakening the checker (count-equality and skip checks disabled in a scratch copy) turned `test_count_mismatch`, `test_duplicate_suite` and `test_skipped` red, so the controls bite. The selftest also passes under `env -i PATH=/usr/bin:/bin` (no Gradle, Java or network).
- CI: steps "Check Kotlin JVM test floor" and "Check Kotlin test floor controls" added after `Run Android JVM tests`; the existing remediation line is byte-identical and one test-floor remediation line was added. `script/repository_verification_stages.json` is untouched.

## Numeric floors (I-5)

| Floor | Planner baseline | Re-measured on branch | Used |
|---|---|---|---|
| Kotlin XML tests (verify regex) | 37 | 37 | 37 |
| Boundary testcases | 10 minimum | 20 | 10 (checker), 10 (regex) |
| Selftest `Ran N` | 13 | 13 | 13 |
| Mix gate (phase165 x2 + phase134) | 47 | 47 | 47 |
| Node repository_verification pass | 41 | 41 | 41 |
| Remediation line count in workflow | 1 | 1 (unchanged) | 1 |

Load-bearing test names matched the XML committed by Plans 01 and 02 exactly; no rename needed.

## Task Commits

1. **Task 1 (tracer): floor checker** - `95d9466d` (test). Tracer gate: the full forced Gradle run passed end-to-end before expansion.
2. **Task 2: fixture selftest** - `0b6ba21e` (test)
3. **Task 3: CI wiring** - `67c3ed2e` (ci)

## Deviations from Plan

None to code. One process note on the Task 2 TDD flow: the checker was written in Task 1 (tracer), so the selftest passed on first run and there was no natural RED. In place of a RED commit, a mutation check against a scratch copy (checks disabled) was run and produced three red tests, which is the evidence that the controls are not vacuous.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. T-198-10 mitigated (forced `cleanTestDebugUnitTest`, derived equality, duplicate-suite and zero-XML failure); T-198-11 mitigated (`build_file_violations`); T-198-12 and T-198-SC accepted. Stdlib only, no installs, no network.

## Requirement closure

AND-02 is marked complete: Kotlin JVM tests 12 to 37 (floor 25) with `BridgeChannel` boundary cases, `androidx.webkit` kept because `BridgeChannel.kt` imports it (decision in `198-DECISIONS.md`), JSON stack decided in writing, and the floor now enforced by a recurring merge-blocking check with negative controls. CI behavior itself is unobserved until a PR runs; local equivalents passed.

## Self-Check: PASSED

- FOUND: script/check_kotlin_test_floor.py, script/check_kotlin_test_floor_test.py, 198-03-SUMMARY.md
- FOUND commits: 95d9466d, 0b6ba21e, 67c3ed2e
- `.planning/config.json` and the Phase 197 `.review-diagnostics/` directory were never staged.
