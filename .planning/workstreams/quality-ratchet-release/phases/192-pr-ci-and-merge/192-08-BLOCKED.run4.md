# Phase 192 Plan 08: BLOCKED (ci_red_after_round_3, infrastructure cause)

PR #242 is open and its branch is pushed. The CI-FIX-3 change fixed the real test failure: `phase41-gating-proof` and `phase130-core-hermetic-proof` are now green. One job, `phase43-rulestead-proof`, is red for a reason outside this PR (hex.pm timed out while the job fetched dependencies), so the required check `Crosswake CI` is red on the head. No SUMMARY was written. No further commit, push, rerun, merge or other GitHub write was made.

## What this run did (run 4, CI-FIX-3)
- User decision (2026-10-23): "Diagnose, then one fix". One commit, one push.
- Root cause found and reproduced on Linux (see below).
- Commit `9f33c071aa9569879bd643a2fc1aa33ead2614de` (label CI-FIX-3 in heads-191.txt):
  - `lib/crosswake/proof_lane/twin_runtime.ex`: `start_child/3` no longer fails when the child has already exited before its pid is read; `alive?(nil)` is false.
  - `lib/crosswake/proof_lane/twin_producers.ex`: `read_rows/2` keeps its real reason, `{:error, {:rows_unavailable, reason}}` (exit status and a 200-byte printable head of sqlite3's own text; no row contents).
  - `test/crosswake/proof_lane/twin_producers_test.exs`: absent-database assertion matches the new shape; new regression test captures 1,200 immediately-exiting children concurrently.
  - `script/verify_repository.mjs` plus one JS test: root-proof failure output now also prints the ExUnit failure details section (bounded 120 lines / 16 KiB, credential-masked) before the tail.
  - No workflow file changed.
- Local checks: `mix test test/crosswake/proof_lane` 317 tests, 0 failures; compile with warnings-as-errors clean; format clean; `node --test test/js/repository_verification.test.mjs` 41 pass.
- Scan: first `finalize-191.sh --scan-only` was clean (terms 0, no findings); no amendment, no triage row. `--check-binding` printed `finalize: binding pass`.
- One push through push-192.sh: delivered. Remote tip read back equals the clone HEAD `9f33c071...`.

## Root cause of the original failure
`TwinRuntime.start_child/3` read the child's pid with a strict match, `{:os_pid, pid} = Port.info(port, :os_pid)`. A short-lived child such as `sqlite3` can finish before that call on a loaded runner. The port is then already closed, `Port.info/2` returns `nil`, the match raises, and the surrounding `rescue` reports `prerequisite_missing` (as if the executable were missing). `read_rows/2` then collapsed every failure into `{:error, :rows_unavailable}`. The child's output and exit status are still delivered to the process, so nothing was actually wrong with the database or sqlite3.

Evidence (Debian container, Elixir 1.19.5 / OTP 27, 16 concurrent callers):
- With the diagnostic change, 1 of 3,200 `read_rows` calls failed with `{:rows_unavailable, {:start_failed, :prerequisite_missing}}`.
- A bare `Port.open` plus `Port.info` of the perl-wrapped sqlite3 returned `nil` in 1 of 14,400 spawns, and a probe showed `Port.info` is `nil` after a fast exit while the `{:data, ...}` and `{:exit_status, 0}` messages still arrive.
- After the fix: 5 x 6,400 calls under the same load, 0 failures.
- Ruled out: sqlite3 3.45.1 (Ubuntu 24.04) `-readonly`, piped stdin, the perl `setpgrp` wrapper, output ordering, missing-database behavior (all correct).
- The same strict match also sat in the `lsof`/`ps` ownership check path (`TwinFaultBoundary.run_readonly`), so the fix covers that path too.

## CI result (run 40035430432, head 9f33c071aa9569879bd643a2fc1aa33ead2614de)
- 47 jobs success, 2 failure: `phase43-rulestead-proof` and `Crosswake CI` (the aggregator).
- Green now: `phase41-gating-proof`, `phase130-core-hermetic-proof`, `proof-requires-example-host`, and every other job.
- Red: `phase43-rulestead-proof` failed in the shared "setup-elixir-cache" step, `mix deps.get`, three attempts, each `Failed to fetch record for <package> from registry :timeout`, then `mix deps.get failed 3 times`. No test ran in that job. This is a hex.pm/runner network timeout, not code in this PR.
- That job was green in earlier runs of this PR (run 40029165177 had it passing), and the PR changes nothing it depends on.

## State at stop
- Remote branch tip: `9f33c071aa9569879bd643a2fc1aa33ead2614de` (equals clone HEAD, scan-bound)
- PR #242 open, base main, head land/v25-v27. `pr-192.txt` still shows the older head `ca7d2057` (not edited, per instruction: only edited on a green run).
- Evidence appended: fixforward-192.txt, ci-history-192.txt, push-192.txt. `ci-192.txt` not written (no green run).
- Failed-job log copy: /private/tmp/crosswake-phase191-run/p192-failed4.log

## Suggested next step
Re-run only the failed job (`gh run rerun 40035430432 --failed`). That is an infrastructure-cause rerun, which the plan (R-FF) allows once with the run id and cause recorded; this round's rules prohibited CI reruns, so it was not done. If `phase43-rulestead-proof` and the aggregator go green on the same head, write `ci-192.txt` and `192-08-SUMMARY.md` from that run with no new commit. A new commit is not needed.
