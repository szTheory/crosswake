---
phase: 192-pr-ci-and-merge
plan: 05
subsystem: release-verification
tags: [post-merge, baseline, release-please, LAND-04]
requires: [192-03, 192-04]
provides: [postmerge-192.sh baseline|verify, selftest-postmerge-192.sh, a4 guard evidence]
key-files:
  created:
    - scripts/postmerge-192.sh
    - scripts/selftest-postmerge-192.sh
    - 192-EVIDENCE/baselines-tracer-192.txt
    - 192-EVIDENCE/selftest-postmerge-192.out
    - 192-EVIDENCE/a4-guard-192.txt
status: complete
requirements: [LAND-04]
commits: 0
---

# Phase 192 Plan 05: Post-merge verifier Summary

A read-only post-merge verifier now exists. It decides "CI on main is green for the merge commit" from three checkable facts, and it proves no package was released. Commits were skipped in this checkout per the recovery-checkout rule, so `commits: 0` is intended and every file is a plain uncommitted file.

## What was checked

- A live baseline was recorded now (tracer): 48 release names, the latest release, 71 tag names and the Hex latest stable version of all six packages.
- The self-test ran 19 of 19 controls as expected (the plan required at least 14). Scenarios are derived from live captures through the shim, which refuses any invented field.
- Assumption A4 was confirmed by reading only: no version-bearing path differs between main and the integration clone, and the release guard ends at its no-version-change exit before its script uses the policy token.

## What changed

Two new scripts and three evidence files (listed above). Only GET reads were made against GitHub and Hex. Nothing was written to GitHub, and no workflow was rerun or dispatched.

## How verify decides

`postmerge-192.sh verify` prints `postmerge: main green` only when all hold: (a) the recorded pull-request check succeeded for the bound head with the tested synthetic tree; (b) the merge commit has exactly two parents (main first, bound head second), its tree equals the tested synthetic tree, and it is on main; (c) the highest-id Release Please push run on the merge commit succeeded, its guard job succeeded, at least one publish-class job exists and all are skipped, and every other non-advisory push run succeeded. See It Run Collateral is recorded as advisory (success, failure, cancelled, in_progress or absent) and never counted. The release, tag and Hex baselines taken after must equal the ones taken before. Empty results (no runs, no publish-class jobs) fail closed; unparseable output exits 2.

## Assumptions

- A4 (the guard's two-parent path exits at the no-version-change branch): confirmed from the workflow file and the path diff.
- A7 (See It Run Collateral is usually cancelled): treated as advisory fact. It will start on the merge because one of its watched paths changed; it is recorded, not counted.

## Release-merge credential reasoning (accurate, job-level)

This is not a release merge: no version-bearing path changes, and the guard exits at its no-version-change branch before its script references the bound policy token. The orchestrator note applies: the publish jobs bind the token in steps with no step-level `if`. Their gate is the job-level `if` (linked release approved, or a package release created plus a matching rel17 operation). On this merge `linked_release` stays false and no package release is created, so those jobs are skipped; the previous main push run shows every publish-class job skipped. Only the Release Please step has a step-level `rel17_context` gate. The phase's own gate reads use the local CLI credential and are read-only. The a4 evidence records this wording.

## Deviations from Plan

1. [Rule 2 - small additions] Extra labels beyond the plan's list: `postmerge: bad label` (unknown baseline label, exit 2), `postmerge: guard not success`, and `postmerge: release-please conclusion pending` (run still going at the poll limit). Controls Q17 to Q19 cover bad label, missing input, unreadable release read and still-running Release Please.
2. a4-guard-192.txt carries two extra `note` lines and one extra key (`token_bound_jobs_gated`) recording the job-level reasoning above. All seven required lines are present verbatim.
3. The plan's automated verify uses `set -- $T`, which needs bash or sh word splitting; the second verify was run under bash for that reason. Both verifies pass.

## Known Stubs

None.

## Threat Flags

None.

## Task results

- Task 1 (tracer): pass. Syntax checks, tracer baseline, Q01, `baseline bogus` exit 2, seven A4 lines, fresh empty diff of version paths, and the awk token-binding check all pass.
- Task 2: pass. Self-test closes `selftest-postmerge: controls 19 of 19 as expected`; none NOT as expected.

## Self-Check: PASSED

All five artifacts exist; both automated verifies pass; no private path appears in the evidence files; no git write was made in the recovery checkout.
