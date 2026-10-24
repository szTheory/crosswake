---
phase: 192-pr-ci-and-merge
plan: 08
subsystem: release-landing
tags: [pull-request, ci, fix-forward, github]
requires:
  - phase: 192-07
    provides: scan-bound LAND-FIX head 4a6c1af2
provides:
  - branch land/v25-v27 on GitHub at 9f33c071
  - PR #242 to main with Crosswake CI green on its head
affects: [192-09 merge gate, 192-10 post-merge]
actuals:
  tokens: 0
  tasks: 2
  commits: 3
plan_head_before: 4a6c1af2f2304e7c3a72ca845a2409a7a9e0d682
plan_head_after: 9f33c071aa9569879bd643a2fc1aa33ead2614de
key-files:
  created:
    - 192-EVIDENCE/ci-192.txt
    - 192-EVIDENCE/pr-192.txt
  modified:
    - 192-EVIDENCE/ci-history-192.txt
    - 192-EVIDENCE/fixforward-192.txt
    - 192-EVIDENCE/gh-writes-192.txt
    - 192-EVIDENCE/push-192.txt
key-decisions:
  - "A-08-1: push gate passes http.postBuffer=524288000 (run 1 HTTP 400 on first 114-commit upload)"
  - "One rerun of failed jobs for a recorded hex.pm timeout, by user decision 2026-10-23"
requirements-completed: [LAND-03]
status: complete
---

# Phase 192 Plan 08: Push, PR and green CI Summary

The branch `land/v25-v27` is on GitHub at `9f33c071aa9569879bd643a2fc1aa33ead2614de`. PR #242 (https://github.com/szTheory/crosswake/pull/242) is open to `main`. The required check, Crosswake CI, passed on that exact head. It ran on GitHub's merge preview of main (`d0dbdf7b...`) plus this head. Nothing else on GitHub was changed. The recovery checkout got no commit (phase rule); the fix commits live in the integration clone.

## How it got there (runs 1 to 5)

- Run 1: the first push failed with an HTTP 400 on the 114-commit upload. Nothing was delivered, and the remote branch was re-read as absent. Repair A-08-1: the push gate now passes a larger `http.postBuffer`; nothing else in the gate changed. The user chose one fresh push.
- Run 2: push delivered, PR #242 opened (one `pr create`, listed before and after). The first CI run (40014160817) had 11 failing jobs. Causes were patched dependency advisories, a package-metadata key, and four tests that only work on a Mac. Fix-forward CI-FIX-1 (`ca7d2057`) addressed them.
- Run 3: after CI-FIX-1, run 40021118301 failed because `proof-requires-example-host` hit its 25-minute limit. The user approved CI-FIX-2 (`24c4ca0c`): the timeout went to 60 minutes (the only workflow change), plus bounded, credential-masked failure output from the root proof. The first scan flagged a credential-shaped literal in my own new test. I built it at runtime in the unpushed commit, with no triage row, and the rescan was clean.
- Run 4: after CI-FIX-2, run 40029165177 failed in `phase41-gating-proof`. I reproduced a rare race in Linux containers. `TwinRuntime.start_child/3` read the child pid with a strict match, and a fast-exiting `sqlite3` child could close its port first. CI-FIX-3 (`9f33c071`) fixes that, keeps the real reason in `read_rows`, and adds a regression test. Run 40035430432 on that head then had 47 jobs succeed. `phase43-rulestead-proof` failed only in `mix deps.get`: hex.pm registry timeout, three attempts, no test ran.
- Run 5 (this run): the user decided "Rerun failed jobs once". I re-read the live state first. The remote tip, the clone HEAD and the PR #242 head all equaled `9f33c071`, and main was still `d0dbdf7b`. I recorded the infrastructure cause with run id 40035430432 in `fixforward-192.txt` and logged the rerun in `gh-writes-192.txt`. I ran `gh run rerun 40035430432 --failed` exactly once (attempt 2), then polled with `ci-poll-192.sh wait 242 9f33c071... 120`, which printed `ci-poll: success`.

## Result of the failed-job rerun (run 40035430432, attempt 2)

- 49 jobs, 0 non-success.
- `phase43-rulestead-proof`: success.
- `Crosswake CI`: success (check run 120707263106, app 15368).
- Live required set: `ok`, exactly the one check. A fresh `check` read gave `completed success`. `finalize-191.sh --check-binding` printed `binding pass`.
- `ci-192.txt`: synthetic merge `cdf8af98...` with parents `d0dbdf7b... 9f33c071...`, `ran_on synthetic_merge`, and head-sourced job `release-candidate-full-proof`.

## Deviations from Plan

- [Rule 3 - Blocking] A-08-1: `http.postBuffer` in `push-192.sh` (run 1).
- Fix-forward rounds 1 to 3 (CI-FIX-1/2/3) were each user-authorized after the plan's own round limit. Round 4 was the one infrastructure rerun.
- `pr-192.txt` carried a stale head (`ca7d2057`). It was updated to `9f33c071`.
- Not measured: the plan commit ledger (`gsd-plan-head-before-192-08`) was not available to this run. `commits: 3` is the count of CI-FIX commits recorded in heads-191.txt after LAND-FIX `4a6c1af2`. The clone holds 117 commits over main.

## Known Stubs

None.

## Threat Flags

None. The only workflow change was the `proof-requires-example-host` timeout. No tag, force push, admin bypass, merge, PR edit or other PR change occurred.

## Self-Check: PASSED

- `ci-192.txt`: head `9f33c071`, `conclusion success`, `required_set ok`, `ran_on synthetic_merge`, parents `MAIN_SHA` then head: FOUND.
- `pr-192.txt`: pr 242, head `9f33c071`, `result open`: FOUND. The live PR is OPEN with `headRefOid` equal to the clone HEAD and the remote tip.
- `fixforward-192.txt` ends `result green`: FOUND.
- Commits `ca7d2057`, `24c4ca0c` and `9f33c071` are in the clone and the remote tip equals `9f33c071`: FOUND.
