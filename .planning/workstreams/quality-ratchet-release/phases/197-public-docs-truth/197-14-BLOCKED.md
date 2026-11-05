---
phase: 197-public-docs-truth
plan: 14
status: blocked
blocked_at: 2026-11-05
tasks_complete: "1 of 2 (Task 2 stopped at step (e): Crosswake CI is red for causes outside this phase)"
plan_head_before: 2e4a9b3e0a0b02793d8490b23f0458e5c68279f5
plan_head_after: 22d56f695bb7330aa637e0e703e6231cf99c1594
commits: 3
requirements_marked_complete: none
---

# Phase 197 Plan 14: BLOCKED

This file is `BLOCKED`, not `SUMMARY`, on purpose: the plan's done criterion (Crosswake CI green on
the PR head) is not met, so nothing here may unlock dependents or mark DOCS-01, DOCS-02 or DOCS-03
complete.

## What was checked and what happened

**Task 1 (tracer) is done and verified.**

- Privacy scan run 1 over the 92 changed files returned rc 1 (two `email` hits). Both were fixed by
  exact-path commit `e4a25fb5`: the Maven POM fixture's scp-style SCM user was dropped (the fixture is
  only read for project coordinates; the two test files that use it pass, 146 tests, 0 failures), and
  the docs-report link test now uses a `mailto:` target without an address. Run 2 returned rc 0 on 92
  files; run 3 rc 0 on 96 files (including the PR body).
- Pushed `e4a25fb5` (feature branch, no gate) and ran the real command against published 0.2.11 with no
  selftest variable: `cleanroom: leg docs PASS 0.2.11 executed=18 not_applicable=2 deferred=ios_host
  clone=4 shown=4 source=commit:e4a25fb5... phx_new=1.8.13`, then `cleanroom: result PASS legs
  hex,maven,ios,docs version 0.2.11`, rc 0, first and only run, so no superseded run. README.md and
  guides/install.md are byte-identical between that ref and the PR head.
- `sc1-ios-host-deferral-197.txt` records the `:ios_host` step as a deferral to Phase 199 (0.2.12), not
  counted as executed or passed, no exemption; the ROADMAP Phase 199 criterion 5 (`deferred=none`) carries it.
- Three verifies for Task 1 exit 0.

**Task 2 reached the CI gate and stopped.**

- PR 268 is open (`docs(197): public docs truth`, base main, head `22d56f695bb7330aa637e0e703e6231cf99c1594`).
  The `197 CI record` PR comment was posted naming that head, the synthetic merge commit
  `6bb3c40ca1d9d79d80855c2d54508364f88e9e0c`, every check, and the cost report. CI ran on the synthetic
  merge commit, not on the head.
- Crosswake CI run 42077104246: 35 of 38 checks SUCCESS, `release-candidate-full-proof` included
  (the workflow did run the full matrix, as the plan expected). Three are not green:
  1. `proof-dependency-security` FAILURE. `mix hex.audit` now reports upstream advisories
     EEF-CVE-2026-117645 (phoenix_html 4.3.0, MEDIUM, in both `mix.lock` and
     `examples/phoenix_host/mix.lock`) and EEF-CVE-2026-118391 (ecto 3.13.6, HIGH, in the example host
     lock). I reproduced both locally. This branch changes neither lock file, so main's locks fail the
     same audit; the last green Crosswake CI run I found is 2026-10-29, so the advisories most likely appeared after it (not verified).
  2. `e2e-proof` CANCELLED at its 20-minute limit while `apt` installed Playwright system packages (the
     Ubuntu mirror stalled on one package; no test ran). A rerun is needed, not a code fix.
  3. `Crosswake CI` aggregator FAILURE as a consequence.
- Cost report (advisory): 193 billable minutes against a baseline of about 250, 20.7 min wall clock,
  2 jobs with a full-suite step against about 10; no duplicated full-suite run or uncached job flagged.
  The run is red, so the figures are partial.

## Why this stops here

- The fix for (1) is `mix deps.update phoenix_html` and `mix deps.update ecto`, which edits `mix.lock`
  and `examples/phoenix_host/mix.lock`. The plan's fix-forward rule allows only README.md, CHANGELOG.md,
  guides/, lib/, script/, test/ and the 197-13 after-count files, and says a fix needing any other path
  stops the task and is reported. `mix.lock` is also a measured input (it would force the full-suite and
  docs-report after-counts to be rerun) and a release-sensitive path, and a dependency bump that
  changes what the library resolves is a product decision, not a docs-phase edit.
- Retrying `e2e-proof` alone cannot make the PR green while (1) stands, and a CI rerun would spend more
  macOS/Linux minutes for no verdict change.

## What reopens work

A decision on the two advisories, then in order:

1. Land the lock bumps (this PR, or a separate `fix/` PR to main that this branch then merges; the
   cleaner option, because the failure is not Phase 197's and any other PR on these locks should hit it too, not verified). If
   they land on this branch, rerun 197-13 Task 1's full suite and after-count commands (mix.lock is a
   measured input), refresh the after-count files, rescan, push.
2. Rerun the failed `e2e-proof` job on the new head.
3. Re-read CI on the final head, post a new `197 CI record` comment naming the new head and merge
   commit, and run the plan's three Task 2 verifies. Their first verify must exit 0.
4. Then write `197-14-SUMMARY.md`, mark DOCS-01, DOCS-02, DOCS-03 complete, and advance state.

If the lock bumps land in a different PR and main moves, the clean-room evidence stays valid: it
depends on README.md and guides/install.md, which do not change.

## State left behind

- Local branch `docs/197-public-docs-truth` equals `origin/docs/197-public-docs-truth` at `22d56f69`
  before this file's commit; this BLOCKED file's commit is local and is not pushed.
- No merge, tag, publish or remote-branch deletion was done. The auto-delete-on-merge repository
  setting was read live: `false`.
- `.planning/config.json` is unstaged and untouched; `.review-diagnostics/` untouched.
- Temporary files (PR body, CI record, scan outputs) are in the session scratchpad only.

## Next gate once CI is green

Merging PR 268 to main needs a fresh one-use `allow` from the user for that PR's head at that time.
After the merge the exact next command is `/gsd-verify-work 197 --ws quality-ratchet-release`.
