# Phase 192 Plan 08: BLOCKED (ci_red_after_round_2)

The branch is pushed and PR #242 is open, but the required check, Crosswake CI, is still red after the second (user-authorized) fix-forward round. No SUMMARY was written. No further commit or push was made. No merge, rerun, approval or other GitHub write happened beyond the one push of this run.

## What this run did (run 3, CI-FIX-2)
- User decision (2026-10-23): "One more fix round". One commit, one push.
- Commit `24c4ca0c1e5676d06a2aebe0d08d5dd705ca0ed1` in the integration clone (label CI-FIX-2 in heads-191.txt):
  - `.github/workflows/crosswake-ci.yml`: `proof-requires-example-host` `timeout-minutes` 25 to 60. Nothing else in workflows changed.
  - `script/verify_repository.mjs`: when root-proof fails on a hosted runner, print a bounded tail (150 lines, 24 KiB, credential-shaped values masked) of its own test output. Verdict unchanged, silent on success.
  - `test/js/repository_verification.test.mjs`: one test for the tail.
- Local check: `MIX_ENV=test mix verify` on the Mac passed (2659 tests, 0 failures), so the root-proof failure did not reproduce locally. JS repository tests: 40 pass.
- Scan: the first `finalize-191.sh --scan-only` on that commit reported one gitleaks finding, caused by a credential-shaped literal in my own new test string. I amended the not-yet-pushed commit to build those strings at runtime (no triage row added, nothing allow-listed). The rescan was clean (terms 0, gitleaks_findings 0, blocking_final 0, `finalize: head ... scan clean`) and `--check-binding` printed `finalize: binding pass`.
- One push through push-192.sh: delivered. Remote tip read back (`git ls-remote`) equals the clone HEAD `24c4ca0c1e5676d06a2aebe0d08d5dd705ca0ed1`.
- CI run 40029165177 on that head: finished failure after 30m38s.

## CI result (run 40029165177)
- Green: `proof-requires-example-host` (took about 28 minutes, so the 60-minute limit fixes the round-2 cancellation) and every other job except two.
- Red: `phase130-core-hermetic-proof` and `phase41-gating-proof` (and therefore `Crosswake CI`).

## Causes read from the failed-job logs
- `phase41-gating-proof`: one test failed, `test/crosswake/proof_lane/twin_producers_test.exs:323` ("read_rows opens the database only read-only and returns integers"). `TwinProducers.read_rows/2` returned `{:error, :rows_unavailable}` where `{:ok, %{total: 3, ...}}` was expected. The test builds a throwaway SQLite file with the `sqlite3` binary, then reads it through `TwinProducers.capture/5` (a bounded child via `TwinRuntime`). This same job was green on the previous head (run 40021118301) with no relevant change, so this looks like a timing or environment race on the runner rather than a deterministic break. It passes locally on the Mac.
- `phase130-core-hermetic-proof` (root-proof): the new tail now shows `2658 tests, 1 failure (82 excluded)` and `mix cmd` exit 2. The 150-line tail started after the failure report, so the test name was cut off. It is very likely the same test (one failure, same suite, same runner image), but that is an inference, not something the log states. Lesson for diagnostics: the tail should have kept the failure summary section, not only the last lines.

## State at stop
- Remote branch tip: `24c4ca0c1e5676d06a2aebe0d08d5dd705ca0ed1` (equals clone HEAD, scan-bound)
- PR: #242 open, base main, head land/v25-v27 (its pr-192.txt record still shows the older head `ca7d2057`; I did not edit it)
- Clone HEAD: `24c4ca0c1e5676d06a2aebe0d08d5dd705ca0ed1`, clean
- Evidence appended: fixforward-192.txt, ci-history-192.txt, push-192.txt. ci-192.txt not written (no green run).
- Failed-job log copy: /private/tmp/crosswake-phase191-run/p192-failed3.log

## Suggested next step
Decide whether to allow a third round for the single remaining test (`twin_producers_test.exs:323`): find why `capture`/`read_rows` returns `:rows_unavailable` on a Linux runner some of the time (child exit-status or port race, or the `sqlite3` child) and fix or de-flake it honestly, without weakening the assertion. This run did not make that change because the user authorized exactly one round.
