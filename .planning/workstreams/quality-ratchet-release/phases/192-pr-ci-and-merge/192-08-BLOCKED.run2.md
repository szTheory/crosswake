# Phase 192 Plan 08: BLOCKED (ci_red_repeat)

The branch is pushed and the pull request is open, but the required check, Crosswake CI, is still red after one fix-forward round. No SUMMARY was written. No merge, approval, rerun or other GitHub write was made beyond the two pushes and the one PR creation.

## What was done
- Run 2 pushed once, as the user chose ("push once with the fix"). Before it: origin main still equalled MAIN_SHA `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, the remote branch was absent, `finalize: binding pass` held at `4a6c1af2`. The push was delivered (deviation A-08-1: the push gate now passes `-c http.postBuffer=524288000`; run 1's HTTP 400 was git's default 1 MB buffer on the 114-commit first upload).
- PR body written from the recorded scan and suite records, privacy check clean, one `gh pr create`, one open PR: https://github.com/szTheory/crosswake/pull/242 (base main, head land/v25-v27).
- First CI run (run 40014160817, head `4a6c1af2`) was red with 11 failing jobs. Causes read from the failed-job logs and reproduced in a Linux container:
  1. dependency advisories on plug_crypto (root and example host) and bandit (example host);
  2. candidate-artifact inspection rejected the `build_env` key that current Hex writes into package metadata;
  3. four tests that only work on a Mac: the generated-shell build test (needs xcodebuild and a hard-coded macOS temp folder), two iOS migration tests (xcodebuild read), and the twin-journey cleanup test (run root too shallow under a Linux /tmp).
- Fix-forward round 1 (one commit `ca7d20577aad17f228ea8445b6065045781599d5`, label CI-FIX-1 in heads-191.txt): locks updated to the patched releases (and the lock-pin test follows), `build_env` allowed, the Xcode-only tests tagged or guarded, the Hex cache folder follows the temp dir, the cleanup test uses a deeper run root. Affected local tests passed on the Mac (179 tests, 0 failures) and the same files passed in a Linux container; the scan-only rescan was clean (`scan: result clean`, terms 0, blocking_final 0); pushed through push-192.sh (delivered, remote tip read back equal).
- Second CI run (run 40021118301, head `ca7d2057`): 8 of the 11 jobs went green, including release-candidate-full-proof, proof-dependency-security and all hermetic suites. Still red: two jobs.

## What is still red and why it stops here
1. `proof-requires-example-host` was CANCELLED by its own `timeout-minutes: 25` (it started the isolation matrix at 20:42:34 and was cut at 21:06:31). In run 1 the matrix failed fast on a red suite; now that the suite is green it runs all three seeds in both classes (about 10 minutes per seed on the runner), which does not fit in 25 minutes. The fix is to raise that job's limit (or shrink the matrix) in `.github/workflows/crosswake-ci.yml`. That is a CI-workflow change, which this plan's prohibitions list excludes ("no workflow or branch-protection change"), and the isolation script also snapshots that file. It needs a decision, not a silent edit.
2. `phase130-core-hermetic-proof` (root-proof, `mix verify`) failed after about 12 minutes. The repository facade prints only `FAIL root-proof` and withholds the test output, so the cause is not visible in the CI log. In a Linux container with the same seed and concurrency (`mix verify`, git 2.47, as a normal user) the companion suites and the phase 41 run pass and the main run showed only container-specific misses (no sqlite3 binary in my image), so I could not reproduce a real failure. A further change would be a blind guess, so none was made.

The same cause did not recur (round 1's causes are all fixed), but the check is still red, so the round budget is the thing that ends the plan; one of the two remaining items needs a human decision about the workflow file.

## State at stop
- Remote branch tip: `ca7d20577aad17f228ea8445b6065045781599d5` (equals the clone HEAD; scan-bound)
- PR number: 242 (open)
- Clone HEAD: `ca7d20577aad17f228ea8445b6065045781599d5`, clean
- Evidence: 192-EVIDENCE/push-192.txt (delivered x2), pr-body-192.md, checks-summary-192.txt, privacy-08-192.txt, pr-192.txt, ci-history-192.txt, fixforward-192.txt, open-prs-before-192.txt, gh-writes-192.txt (one pr_create). ci-192.txt was not written because no run succeeded.
- Other open PRs were not touched (#210, #211, #236, #238, #239, #240, #241).

## Suggested next step
Decide whether the example-host job may get a longer limit in the PR (a small workflow edit, pushed through push-192.sh with a fresh scan), and either allow one more round for the root-proof job or have its output made visible (for example by letting a re-run write the failing test names). Recovery-checkout commits were skipped per the checkout rule.
