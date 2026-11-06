---
phase: 198-android-foreign-host-proof
plan: 10
subsystem: android-foreign-host-proof
tags: [promotion-readiness, derived-status, ci-history, bearings-report, selftest, advisory]
status: complete

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 09 evidence JSON (tests, control_reason, script_blob, result) written by script/verify_android_foreign_host.sh"
provides:
  - "script/android_foreign_promotion.sh: derives clean_runs=N/2 from Crosswake CI run history and the android-foreign-host-evidence artifacts; report only, never edits authority"
  - "script/android_foreign_promotion_test.py: 13-case fake-gh selftest, every counting rule and every UNVERIFIED reason"
  - "script/bearings_report.exs: one android_foreign line through the deps.run seam, with a positive fixture case and an UNVERIFIED control"
affects: [198-11, 198-12]

actuals:
  tokens: 6000
  tasks: 3
  commits: 3
plan_head_before: b4140b19b110a3b429218111ddca90c7084ad7aa
plan_head_after: 39a0cb353681a2c6ed378c3f36318c1511cb1f4f

tech-stack:
  added: []
  patterns: ["gh read written to a file with one repeat attempt; fixed-reason UNVERIFIED instead of stderr passthrough", "fake gh keyed by argv substring with zipfile-built artifact fixtures"]

key-files:
  created:
    - script/android_foreign_promotion.sh
    - script/android_foreign_promotion_test.py
  modified:
    - script/bearings_report.exs
    - test/crosswake/bearings_report_test.exs

key-decisions:
  - "A gh read is attempted twice before it is UNVERIFIED: GitHub answered HTTP 502 on a readable run in two consecutive real runs, so a 50-run scan would report UNVERIFIED by chance. A read that fails twice is still UNVERIFIED, never zero"
  - "The script is invoked by the bearings report as bash script/android_foreign_promotion.sh; the report's seam drops the output of a non-zero exit, so a real exit 2 shows a generic fixed reason there, and the script's own reason is visible when it is run directly"
  - "A success whose evidence artifact is missing or expired stops the count (conservative: it cannot be shown clean)"

requirements-completed: []

coverage:
  - id: D1
    description: "Promotion readiness is derived from CI history and evidence content, with read failures UNVERIFIED and never zero"
    requirement: AND-03
    verification:
      - kind: integration
        ref: "real local run: android_foreign: clean_runs=0/2 eligible=no head=none ci_ran_on=synthetic_merge (50 runs read, exit 0)"
        status: pass
      - kind: unit
        ref: "python3 script/android_foreign_promotion_test.py: 13 ran, OK, also under env -i PATH=/usr/bin:/bin"
        status: pass
    human_judgment: false
  - id: D2
    description: "The bearings report shows the derived line and turns UNVERIFIED when the script does"
    requirement: AND-03
    verification:
      - kind: unit
        ref: "script/mix_test_gate.sh --min 74 test/crosswake/bearings_report_test.exs: ran=74 failures=0 verdict=PASS"
        status: pass
    human_judgment: false
---

# Phase 198 Plan 10: Derived foreign-host promotion readiness Summary

**`bash script/android_foreign_promotion.sh` counts clean foreign-host CI runs from run history and evidence artifacts (`clean_runs=N/2`), and the bearings report prints that line, so "required only after two clean runs" is measured and never stamped.**

## What was checked and what happened

Task 1 (tracer): the script was run for real with the local authenticated `gh` against the live Crosswake CI history.
It read all 50 most recent pull-request runs of `crosswake-ci.yml`; none has the `android-foreign-host` job yet
(Plan 11 adds it), so every run was neither clean nor a reset. Final line, exit 0, 154 s wall:

```
android_foreign: clean_runs=0/2 eligible=no head=none ci_ran_on=synthetic_merge
```

Task 2: the selftest runs 13 cases in about 6 s with no network. Task 3: the real `elixir script/bearings_report.exs`
(128 s wall, exit 1 because of unrelated ATTENTION lines already on this branch) carries:

```
android_foreign: clean_runs=0/2 eligible=no head=none ci_ran_on=synthetic_merge
```

## Numeric floors (I-5)

| Gate | Planner baseline | Re-measured baseline (2026-11-05, branch) | Added | Floor used | Result |
|---|---|---|---|---|---|
| `test/crosswake/bearings_report_test.exs` (`ran=`) | 72 | 72 | 2 | 74 | ran=74, 0 failures |
| selftest `Ran N tests` | 13 enumerated | n/a (new file) | 13 | 13 | Ran 13, OK |

## Accomplishments

- Counting exactly as D-20: newest first; not-completed, absent or skipped job is neither clean nor reset; a head SHA already counted is skipped; a job that ran and did not succeed stops the count; a success counts only with evidence `tests >= 1`, `control_reason == could_not_find`, `script_blob` equal to the current `git hash-object` of `script/verify_android_foreign_host.sh`, `result == PASS`; reading stops at 2.
- Six fixed UNVERIFIED reasons with exit 2 (`tool_unavailable`, `repo_unreadable`, `runs_unreadable`, `jobs_unreadable`, `artifact_unreadable`, `evidence_unparseable`); gh stderr is never printed (the selftest plants a token-shaped string in fake stderr and asserts it never appears).
- The tool check runs before any other command, proven with a PATH holding only fake `gh` and `git`.
- The script never names or edits the final proof leaf list or the umbrella needs (`grep -c FINAL_PROOF_LEAVES` is 0).

## Selftest mutation evidence

The selftest passed on its first run, so no RED fixture failed against the script. To show the cases can fail, six
one-line mutations of a scratch copy were run; each turned exactly the matching case red and no other: dropping the
blob check (case 4), the head-SHA dedup (case 5), treating skipped as a reset (case 3), the control-reason check
(case 6), a jobs read failure counted as zero (case 11), and the stop-at-two break (case 1).

## Task Commits

1. Task 1 (tracer): `a12110d2` feat(198-10): derive foreign-host promotion readiness from CI history and evidence artifacts
2. Task 2: `0a925ce7` test(198-10): fake-gh selftest proving every foreign-host promotion counting rule and UNVERIFIED reason
3. Task 3: `39a0cb35` feat(198-10): show derived foreign-host promotion readiness in the bearings report

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Transient GitHub HTTP 502 made the tracer report UNVERIFIED by chance**
- **Found during:** Task 1 real run
- **Issue:** with no job present yet the script reads 50 runs; two consecutive real runs each stopped with `jobs_unreadable` on a different, readable run (`gh: Server Error (HTTP 502)`, reproduced once in a separate probe; the same calls succeeded when repeated).
- **Fix:** every gh read goes through `gh_get`, which writes to a file and attempts the read once more after one second. A read that fails twice is still UNVERIFIED. Plan text says any read failure is UNVERIFIED; this narrows "failure" to "failed twice" and is documented in the script header.
- **Files modified:** `script/android_foreign_promotion.sh`
- **Commit:** `a12110d2`

**2. [Rule 1 - Bug] Script header named the authority list the plan forbids the script to mention**
- **Found during:** Task 1 acceptance check (`grep -q FINAL_PROOF_LEAVES` must exit 1, it exited 0 because of a header comment)
- **Fix:** reworded to "the final proof leaf list"; landed in the Task 2 commit because that task also lists the script.
- **Files modified:** `script/android_foreign_promotion.sh`
- **Commit:** `0a925ce7`

## Issues and concerns

- **Slow until the job exists.** Every `elixir script/bearings_report.exs` now adds about two minutes (50 sequential jobs reads at roughly 2 to 3 s each) while no run has the `android-foreign-host` job. Once Plan 11's job has produced two clean runs the scan stops after two. If the delay is unwelcome, bounded parallel reads are the fix; not done because the plan fixes the sequential counting rules.
- **The report loses the script's own reason on exit 2.** `system_run` discards output on a non-zero exit by design, so the report shows `UNVERIFIED android_foreign: promotion script exited non-zero (run it for the reason)`. A fixture where the runner returns the script's UNVERIFIED line as output (the tested control) maps to the specific reason.
- **The job name is an assumption.** The script matches the job display name `android-foreign-host` and the artifact `android-foreign-host-evidence` (the names in this plan). Plan 11 must create the job and artifact with exactly these names, with the evidence JSON at the top level of the artifact zip.
- Pre-existing failures in `test/crosswake/proof` are unchanged and recorded in `deferred-items.md`: `phase52_operator_truth` (and its `Phase135CiOpsProofTest` wrapper) and the two `Phase175LinkedAuthorizationTest` tests. Run result: 963 tests, 4 failures, all four in that list. The collection-assertion ledger needed no regeneration (diff empty after the last test edit).

## Known Stubs

None.

## Threat Flags

None beyond the plan's register: the script is read-only against the GitHub API, writes only to a temp directory it removes, and prints a derived line or a fixed reason (T-198-33 to T-198-36 mitigated as planned; T-198-SC accepted, no packages added).

## Claim ceiling

This plan adds a readiness measurement only. It does not promote the job, edit the final proof leaf list or the umbrella needs, and makes no device or emulator claim. AND-03 stays open until the Linux CI job produces evidence (Plans 11 and 12); the current derived value is 0/2.

## Self-Check: PASSED

Files present, three commits are ancestors of HEAD (`a12110d2`, `0a925ce7`, `39a0cb35`), selftest 13 tests OK (also under `env -i`), bearings report test ran=74, real script run exit 0.
