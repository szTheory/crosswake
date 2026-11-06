---
phase: 198-android-foreign-host-proof
plan: 11
subsystem: android-foreign-host-proof
tags: [ci, advisory-job, manifest-checker, integrity-test, foreign-host]
status: complete

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 09 script/verify_android_foreign_host.sh (--evidence, --head-sha) and Plan 10 promotion script that matches job android-foreign-host and artifact android-foreign-host-evidence"
provides:
  - "Advisory CI job android-foreign-host (ubuntu-latest, full_proof only, 25 min, needs classify-change) running the published-artifact proof and uploading android-foreign-host-evidence in every outcome"
  - "Foreign-host failure-handling and promotion-counting selftests as steps of the merge-blocking android-generated-shell-unit job"
  - "check_ci_leaf_manifest.py ADVISORY_JOBS loop applying the four advisory checks to every advisory id, with four negative controls for the new job"
  - "phase165 sibling test: android foreign-host proof stays visibly red and outside required authority"
affects: [198-12]

actuals:
  tokens: 2500
  tasks: 2
  commits: 3
plan_head_before: 1abe5f4f7023992ba615f196b4b8a424db12dc29
plan_head_after: 392ffa6a44b4a7e87ec731df40168f006161a9a5

tech-stack:
  added: []
  patterns: ["advisory job ids looped through one set of authority checks so adding an id cannot silently exempt it", "membership checks over derived id lists proven non-empty first, instead of refute Enum.any? on a possibly empty list"]

key-files:
  created: []
  modified:
    - .github/workflows/crosswake-ci.yml
    - script/check_ci_leaf_manifest.py
    - test/crosswake/proof/phase165_ci_integrity_test.exs

key-decisions:
  - "The Gradle distribution cache key carries runner.os and runner.arch before the wrapper-properties hash: the Phase 153.1 cache integrity test requires it, and it differs from the plan's literal key"
  - "The sibling test uses membership checks (refute id in ids) over lists proven non-empty, not refute Enum.any?, so the absence-is-not-success baseline and the Phase 170 ledger stay unchanged (290 sites, no new baseline entries)"
  - "The retired compatibility list is empty by design; the new test names the job against it but the checker's retired_compatibility_context control is what keeps it empty"

requirements-completed: []

coverage:
  - id: D1
    description: "android-foreign-host exists on Linux CI as advisory evidence outside required authority, with an evidence artifact"
    requirement: AND-03
    verification:
      - kind: integration
        ref: "workflow job shape check printed job_ok True (name, needs, runs-on, timeout 25, no continue-on-error or || true, not in umbrella needs, proof and artifact names, no MAVEN_LOCAL or secrets, setup-android-jvm with working-directory)"
        status: pass
      - kind: unit
        ref: "python3 script/check_ci_leaf_manifest.py --self-test: 8 ran including test_every_advisory_job_stays_outside_authority ok, 'ci leaf manifest self-test: pass'"
        status: pass
      - kind: unit
        ref: "script/mix_test_gate.sh --min 48 phase165_ci_integrity, phase165_ci_policy, phase134_native_gate_blocking_proof: ran=48 failures=0 verdict=PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "The job has not yet run on Linux CI, so AND-03 is not satisfied"
    requirement: AND-03
    verification:
      - kind: manual
        ref: "Plan 12 owns the pushed CI run, the evidence artifact and the CI-minute comparison; nothing was pushed here"
        status: unverified
    human_judgment: false
---

# Phase 198 Plan 11: Advisory Foreign-Host CI Leg Summary

The published-artifact foreign-host proof is wired onto Linux CI as a visibly red advisory job `android-foreign-host` with an `android-foreign-host-evidence` artifact; it sits outside the umbrella needs, the leaf manifest and every compatibility projection, and the checker plus an ExUnit test enforce that mechanically.

## What was done

- **Task 1 (tracer), 8766f74c:** added the `android-foreign-host` job after `android-generated-shell-unit` (checkout, setup-beam 1.19.5/27.3, setup-android-jvm with `working-directory`, Gradle distribution cache, Hex and rebar, proof step with the head SHA passed through `env:`, artifact upload and summary both `if: always()` at step level). Added the two selftest steps to `android-generated-shell-unit`. Replaced the single brand-visual block in `check_ci_leaf_manifest.py` with a loop over `ADVISORY_JOBS = ("android-foreign-host", "brand-visual")`. Tracer gate: manifest self-test pass and job shape `job_ok True` before any expansion.
- **Cache key fix, 82b92a1a:** see deviation 1.
- **Task 2, 392ffa6a:** added `test_every_advisory_job_stays_outside_authority` (job popped, `continue-on-error`, `|| true`, umbrella membership each raise the matching problem) and the phase165 sibling test.

## Floors (I-5)

Baselines re-measured on the branch before the first edit, all matching the plan: phase165 integrity, policy and phase134 suites 47 tests (floor 48 = 47 plus 1 added test; measured 48 after); manifest self-test 7 tests before, 8 after.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cache key lacked runner.os and runner.arch**
- **Found during:** Task 2 full `test/crosswake/proof` run
- **Issue:** `Phase153_1CacheIntegrityTest` ("every cache key carries runner.os and runner.arch") failed on the plan's literal key `crosswake-gradle-dist-${{ hashFiles(...) }}`
- **Fix:** key is now `crosswake-gradle-dist-${{ runner.os }}-${{ runner.arch }}-${{ hashFiles(...) }}`; the cached item is still only the Gradle distribution
- **Files modified:** .github/workflows/crosswake-ci.yml
- **Commit:** 82b92a1a

**2. [Rule 1 - Bug] First draft of the sibling test added three baseline-new unsafe collections**
- **Found during:** Task 2 full proof run (`AbsenceIsNotSuccessTest` enforce mode reported `new_or_increased unsafe_collection ... baseline=0`, and the Phase 170 ledger gained 4 rows, one `needs-fix`)
- **Fix:** rewrote the test before committing to use non-empty guards plus `refute id in ids` and a `for` loop, so no `refute Enum.any?` site was added; the regenerated Phase 170 ledger is byte-identical to the committed one (290 sites) and `--check` is OK. The pinned counts in the Phase 170 test were reverted to their original values and were never committed changed.
- **Files modified:** test/crosswake/proof/phase165_ci_integrity_test.exs

## Verification

- `python3 script/check_ci_leaf_manifest.py --self-test`: pass, includes the new control method
- `script/mix_test_gate.sh --min 48 ...`: ran=48, 0 failures, PASS
- `mix test test/crosswake/proof`: 964 tests, 4 failures, all four are the known pre-existing reds in deferred-items.md (phase52_operator_truth and its phase135 wrapper, two phase175 tests); the three extra failures seen before the fixes (cache key, two absence-multiset tests) are gone
- `elixir script/inventory_collection_assertions.exs --check`: OK, 290 sites, re-checked after the last test edit
- `mix format --check-formatted` on the edited test: clean
- `python3 script/verify_android_foreign_host_test.py` and `python3 script/android_foreign_promotion_test.py`: OK locally (these now also run in CI)
- `actionlint` reports one shellcheck SC2129 style note at the pre-existing `android-package-unit` summary step; nothing in the new job

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-198-37: the head SHA reaches the shell only through `env: HEAD_SHA`, quoted. T-198-38: loop plus four controls plus sibling test. T-198-39: no secrets, no `MAVEN_LOCAL`, `contents: read` inherited. T-198-SC: reused the file's existing pinned `checkout`, `setup-beam`, `cache` and `upload-artifact` SHAs; no new action.

## Open items for Plan 12

- AND-03 stays open: the job has never run. It needs a pushed PR run on Linux, the `android-foreign-host-evidence` artifact, and the promotion script reading it. Nothing was pushed from this plan.
- Plan 12 records the job's actual billable minutes against the 250-minute baseline (T-198-40 accepted, unmeasured).
- The job proves the published version, not the head version; the step summary says so.

## Self-Check: PASSED

- 8766f74c, 82b92a1a, 392ffa6a are ancestors of HEAD
- `.github/workflows/crosswake-ci.yml`, `script/check_ci_leaf_manifest.py`, `test/crosswake/proof/phase165_ci_integrity_test.exs` exist and carry the changes
