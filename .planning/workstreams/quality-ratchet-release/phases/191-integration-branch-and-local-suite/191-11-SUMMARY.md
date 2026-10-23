---
phase: 191-integration-branch-and-local-suite
plan: 11
subsystem: testing
tags: [land-02, full-local-suite, verify-repository, exclusions, ci-parity]
requires:
  - phase: 191-10
    provides: CARRY-v27.0 head 0dff1f22
provides:
  - LAND-02 gate record at the FIXTURE head 7075a441 (nine stages, seven lanes, host, Swift export)
  - FIXTURE commit (A-15) fixing two example-host-only doctor router tests
affects: [191-12]
key-files:
  created:
    - 191-EVIDENCE/suite-ALL.txt
    - 191-EVIDENCE/suite-HOST-FINAL.txt
    - 191-EVIDENCE/suite-SWIFT-EXPORT-FINAL.txt
    - 191-EVIDENCE/suite-FIXTURE.txt
    - 191-EVIDENCE/fixture-191.txt
    - 191-EVIDENCE/exclusions-191.md
    - 191-EVIDENCE/ci-parity-191.txt
    - 191-EVIDENCE/testfile-pin-191.txt
    - 191-EVIDENCE/land02-dispositions-191.md
    - 191-EVIDENCE/playwright-browser-191.txt
  modified:
    - scripts/suite-gate-191.sh
    - scripts/selftest-suite-191.sh
    - 191-EVIDENCE/env-shims-191.txt
    - 191-EVIDENCE/heads-191.txt
status: complete
requirements-completed: [LAND-02]
plan_head_before: 0dff1f22f35479e59f452511685d8b14f0c82cf8
plan_head_after: 7075a441b4ed05a9497491cd01f686a2644a506a
commits: 1
---

# Phase 191 Plan 11: LAND-02 full local suite Summary

**The full local suite passes at the FIXTURE head 7075a441: all nine verify_repository stages with status 0, seven clean lanes at or above their separately measured floors, the example host, the Swift export run and the nine CI-parity commands.**

## In plain words

Run 1 stopped because two example-host-only tests failed. Their fixture manifest had no routes object, so the tightened doctor check (correctly) rejected it. This run added one commit labelled FIXTURE on top of the v27.0 carry commit that adds an empty routes object to that fixture and nothing else. Red before (4 tests, 2 failures), green after (4 tests, 0 failures); format, warnings-as-errors and the collection-assertion ledger check pass. After that every check below passes. Nothing was pushed, and nothing in the recovery checkout was committed.

## Results at 7075a441

| Stage | Status |
|---|---|
| repository-preflight, root-proof, example-host-proof, browser-proof, ios-package-proof, android-package-proof, format-proof, warnings-proof, repository-cleanliness | all 0 |

| Lane | Tests | Floor | Failures / invalid / skipped | Excluded |
|---|---|---|---|---|
| rulestead | 11 | 11 | 0 / 0 / 0 | 1 |
| rindle | 55 | 55 | 0 / 0 / 0 | 7 |
| sigra | 139 | 139 | 0 / 0 / 0 | 0 |
| chimeway | 53 | 53 | 0 / 0 / 0 | 0 |
| threadline | 98 | 98 | 0 / 0 / 0 | 0 |
| phase41 | 3 | 3 | 0 / 0 / 0 | 2735 |
| main | 2657 | 2657 | 0 / 0 / 0 | 81 (equals main_excluded) |
| example host (separate gate) | 167 | 167 | 0 / 0 / 0 | 0 |
| Swift (ios-package-proof) | 89 | 89 | 0 failures, 2 named G3 skips | n/a |
| Swift export run | 89 | 89 | 0 failures, 0 skips | n/a |

Assumption A11 was disproved (inputs T=2660, X=78, P=3, Q=2735; floors and excluded total in floors-191.txt and excl-191.txt, measured at the carry head; the FIXTURE commit changes one test-fixture line and no test count). A Playwright browser was not installed this run (it was already in the local cache; lock and CLI version 1.60.0, Chromium revision 1223).

## CI parity (all exit 0)

adoption_context scan, docs sync check, closeout verify, e2e honesty, JS tests (135 of 135), release workflow integrity, collection-assertion ledger check, forced warnings-as-errors compile, first-adopter context test (34 tests, 0 failures). The first-adopter test ran as CI runs it, without private terms; threat T-191-43 is waived by the user's decision of 2026-10-22 (A-14). Test-file pin: git count 253, find count 253, pin 253, guard exit 0.

## Exclusions

exclusions-191.md lists advisory_only, collateral_binaries, engine_present, requires_example_host, phase41_nested_process and the two named Swift G3 skips, each with its reason and where it runs instead. Root skip tags: 0.

## Deviations from Plan

1. **[Rule 1 - Bug] suite-gate-191.sh mode all.** Preflight is judged from the orchestrator's own `PASS repository-preflight` output line (the orchestrator writes no preflight log), eight stage logs are expected, and the named floors-191.txt and three-line excl-191.txt are accepted as well as the old formats. Run 1's run-folder-name fix is kept. selftest-suite-191.sh now has 32 controls (two new: preflight failure, named floor files), 32 of 32 as expected.
2. **[Rule 3 - Blocking] First `--all` attempt of this run failed with a one-hour timeout in example-host-proof** (isolation matrix finished seed 17 only; log in the run folder). A complete suite run of the same stage's work took 496 s alone, so the cause was environmental, most likely the machine sleeping during the long wait. The re-run was wrapped in `caffeinate` (process-scoped, no setting changed) and passed in about 25 minutes. Only the passing record is in suite-ALL.txt.
3. **Subset gate note.** The FIXTURE subset gate cannot run the router test file alone (it is excluded by default through requires_example_host and gives 0 tests), so it ran with the doctor test file too (10 tests, 0 failures); the tagged run is the real proof and example-host-proof re-ran it.
4. Verifies that name the CARRY-v27.0 head were evaluated at the FIXTURE head, as A-15 requires. The Android SDK and npm/node path-order shims from run 1 were reused per run only (env-shims-191.txt, placeholders only).
5. The FIXTURE commit carries the plan's Co-Authored-By trailer as used by earlier Phase 191 commits.

## Known Stubs

None.

## Self-Check: PASSED

Adapted plan verifies for Tasks 1 to 3 all passed; clone clean at 7075a441; no home path in the new evidence.
