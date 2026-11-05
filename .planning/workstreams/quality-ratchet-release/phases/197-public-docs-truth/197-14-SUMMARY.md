---
phase: 197-public-docs-truth
plan: 14
subsystem: release-evidence
tags: [privacy-scan, real-cleanroom, ios-host-deferral, pr-268, ci-record, lock-bump-merge, d-03, d-09]
status: complete

requires:
  - phase: 197-public-docs-truth
    provides: "197-13 suite and docs-report after-counts, 197-01..12 and 197-15 docs and docs leg"
provides:
  - "Real four-leg clean-room PASS against published 0.2.11 with docs read from pushed commit e4a25fb5 (197-EVIDENCE/cleanroom-0.2.11-197.txt)"
  - "197-EVIDENCE/sc1-ios-host-deferral-197.txt: the :ios_host step is a named deferral to Phase 199, never counted as executed"
  - "PR 268 open with Crosswake CI green (38 of 38) on head e49366372c41c2854520dc80985529ffb0a89dae, and a `197 CI record` comment naming that head"
  - "Full suite and docs-report after-counts remeasured on the tree that includes the PR 269 lock bumps"
affects: [197-verification, 199]

actuals:
  tokens: 42000
  tasks: 2
  commits: 9
plan_head_before: 2e4a9b3e0a0b02793d8490b23f0458e5c68279f5
plan_head_after: e49366372c41c2854520dc80985529ffb0a89dae

tech-stack:
  added: []
  patterns:
    - "A measured input (mix.lock) that changes after the after-counts were taken forces a full-suite and docs-report remeasure, with the earlier run kept under a superseded heading"
    - "A blocked plan leaves NN-BLOCKED.md, never NN-SUMMARY.md, so dependents stay locked until the done criterion is met"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/cleanroom-0.2.11-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/sc1-ios-host-deferral-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/privacy-197.txt
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/suite-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/docs-report-after-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/docs-report-after-detail-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-DOCS-REPORT.md

key-decisions:
  - "The dependency advisories were fixed in a separate PR to main (PR 269, merged by the user's own approval), not on this branch; this branch then merged main. The cleaner route, because the failure was not Phase 197's."
  - "The real clean-room run was not repeated: README.md and guides/install.md are byte-identical between the run's ref e4a25fb5 and the final head."
  - "The e2e-proof job needed no rerun: the second CI run passed it on the first attempt, so there is no superseded rerun to explain."

patterns-established:
  - "Say which commit CI ran on: GitHub ran every job on the synthetic merge commit, not the head"

requirements-completed: [DOCS-01, DOCS-02, DOCS-03]

coverage:
  - id: D1
    description: "Real REL-06 run against published 0.2.11 passes all four legs with docs read from a pushed commit"
    requirement: "DOCS-01"
    verification:
      - kind: other
        ref: "197-EVIDENCE/cleanroom-0.2.11-197.txt (result PASS legs hex,maven,ios,docs version 0.2.11, rc 0, docs source commit e4a25fb5)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The :ios_host step is a named deferral to Phase 199 and was not counted as executed"
    requirement: "DOCS-01"
    verification:
      - kind: other
        ref: "197-EVIDENCE/sc1-ios-host-deferral-197.txt; workstream ROADMAP Phase 199 criterion 5 (deferred=none)"
        status: pass
    human_judgment: false
  - id: D3
    description: "PR 268 Crosswake CI is green on its final head"
    requirement: "DOCS-03"
    verification:
      - kind: other
        ref: "plan Task 2 verify 1 (jq gate): ci-gate: PASS checks=38; run 42089200558 attempt 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "Privacy scan clean on every changed file and PR bodies before each push and after the last commit"
    requirement: "DOCS-01"
    verification:
      - kind: other
        ref: "197-EVIDENCE/privacy-197.txt (last line rc 0); post-commit rescan rc 0; CI record comment body scanned rc 0"
        status: pass
    human_judgment: false

duration: "two sessions (first blocked at the CI gate, second after the lock fix; second about 1h 10m, of which about 11 min suite and about 19 min CI)"
completed: 2026-11-05
---

# Phase 197 Plan 14: Real clean-room run, push, and a green PR 268 Summary

**Real four-leg clean-room PASS against published 0.2.11, the `:ios_host` step recorded as a named Phase 199 deferral, and PR 268 green (38 of 38 Crosswake CI checks) after a separately merged lock-bump fix.**

## What was checked and what happened

**Task 1 (tracer), first session.** Privacy scan run 1 over 92 changed files returned rc 1 (two `email` hits).
Both were fixed by exact-path commit `e4a25fb5` (the Maven POM fixture's scp-style SCM user dropped; the
docs-report link test now uses a `mailto:` target without an address; 146 tests pass). Runs 2 and 3
returned rc 0. After the push, the real command ran against published 0.2.11 with no selftest variable:
`cleanroom: leg docs PASS 0.2.11 executed=18 not_applicable=2 deferred=ios_host ...` and
`cleanroom: result PASS legs hex,maven,ios,docs version 0.2.11`, rc 0, first and only run. The deferral
record states that `:ios_host` is deferred to Phase 199 (0.2.12), not counted as executed or passed, no
exemption; ROADMAP Phase 199 criterion 5 (`deferred=none`) carries it.

**Task 2, first session (the block).** PR 268 was opened and Crosswake CI ran on head `22d56f69` (synthetic
merge `6bb3c40c`): 35 of 38 green. `proof-dependency-security` failed on upstream `mix hex.audit`
advisories (phoenix_html 4.3.0 in both locks, ecto 3.13.6 in the example host lock), `e2e-proof` was
cancelled at its 20-minute limit while an apt mirror stalled (no test ran), and the aggregator failed as a
consequence. None was caused by this phase. The plan's fix-forward rule did not allow lock edits, and a
dependency bump is a product decision, so the plan was recorded as `197-14-BLOCKED.md` (not a SUMMARY, so
nothing unlocked) and the work stopped. That file's content is carried here and the file was removed.

**Resolution.** The user approved a separate fix, PR 269 (lock bumps for phoenix_html and ecto plus the
phase-164 test pins), merged to main as `6cb51127`. This branch merged main (`35f18f93`, local merge
commit, no conflicts).

**Second session (this one).**
- `mix.lock` is a measured input, so the full suite was rerun through `script/mix_test_gate.sh --min-total
  3114` on the merged tree: 3134 tests, 0 failures, 76 excluded, `verdict=PASS`. The floor is unchanged
  (195 added and 4 removed `test "` lines against the new merge base, which is origin/main, so floor =
  2923 + 195 - 4 = 3114). The previous passing run is kept in `suite-197.txt` as `# superseded run 2`, the
  earlier failing run stays as `# superseded run 1`. `docs-report` was remeasured at `35f18f93`:
  counters and the sorted detail hit lines are identical to the earlier measurement (warnings 197,
  links broken 0 of 234, leaks 95). The `## After (phase 197 head)` rows in `197-DOCS-REPORT.md` now name
  `35f18f93` and the lock-bump commit `e8252b3c`. Local absolute paths in the evidence were redacted to
  `<repo>`, `<home>`, `<tmp>`.
- Privacy scan run 4 (96 changed files plus the live and draft PR bodies, 98 inputs) rc 0, then the
  post-commit rescan rc 0; the `197 CI record` comment body was scanned too (rc 0) before posting.
- Pushed (feature branch, no gate, no force); `git ls-remote` equals `e49366372c41c2854520dc80985529ffb0a89dae`.
- Clean-room evidence stays valid: `git diff --quiet e4a25fb5..HEAD -- README.md guides/install.md` exits 0,
  so the run was not repeated.
- Crosswake CI run 42089200558 (pull_request event, attempt 1) on the new head: all 38 checks
  COMPLETED+SUCCESS, including `release-candidate-full-proof`, `proof-dependency-security`, `e2e-proof`
  and the `Crosswake CI` aggregator. **CI ran on the synthetic merge commit
  `9d0aa1f0bcbf79dae0f0f9dcee342c5a43c35b53` (parents: main `6cb51127` and the head), not on the head.**
  No rerun was needed, so the apt stall did not recur.
- New `197 CI record` PR comment posted naming head `e4936637...` and that merge commit, each check with
  `ran_on`, the superseded red run and the PR 269 fix, `privacy_final: rc 0` and the cost report.
- Cost report (advisory only): 163 billable minutes against a baseline of about 250, wall clock 19 min,
  2 jobs with a full-suite step against about 10; no duplicated full-suite run or uncached job flagged.

## Verifies

- Task 1: all three automated verifies exit 0 (real PASS line, last `privacy: rc 0`, docs leg line plus
  the deferral record).
- Task 2: the jq gate prints `ci-gate: PASS checks=38`; the release-sensitive-path check exits 0 (the diff
  touches README.md, CHANGELOG.md, guides and lib); a `197 CI record` comment names the current `headRefOid`.
- Acceptance: `pr-ci-197.txt` is not a tracked file; no commit since `origin/main` touches
  `.planning/config.json`; the repository's delete-branch-on-merge setting reads `false`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] CI red for causes outside the phase**
- **Found during:** Task 2, step (e)
- **Issue:** upstream dependency advisories plus a stalled apt mirror.
- **Fix:** none on this branch by the executor; the user approved PR 269 separately and this branch merged
  main, then the measured-input after-counts were rerun (Task 1's rule for a changed `mix.lock`).
- **Files modified:** the four after-count files by exact path (commit `9e87d327`); privacy log (`e4936637`).
- **Commit:** `9e87d327`, `e4936637`

### Notes

- Plan-head ledger count: `commits: 9` is `git rev-list --count 2e4a9b3e..e4936637`. It includes two commits
  authored on main (`e8252b3c`, merge `6cb51127`) and the merge `35f18f93`; six are this plan's own
  (`e4a25fb5`, `e7825282`, `22d56f69`, `56f9be87`, `9e87d327`, `e4936637`). The SUMMARY commit follows and is not counted.
- PR body attribution line: the first session's PR body carries the line the harness requested for PR
  descriptions at that time; this session did not edit the PR body.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the public PR comment, scanned before posting (T-197-37).

## What is unknown

- Whether the advisories appeared only after 2026-10-29 (the last green main run I found) was not verified;
  it does not affect this plan's result.
- Whether `e2e-proof`'s apt stall will recur on a future PR: it did not on this run.

## Whether anything changed

Yes, on the remote: the feature branch `docs/197-public-docs-truth` was pushed (`e4936637`, no force), and one PR
comment was added to PR 268. Nothing was merged, tagged, published or deleted, no `--admin` was used.
`.planning/config.json` (the user's uncommitted change) and `.review-diagnostics/` were not touched. This
SUMMARY commit stays local and is not pushed, as the plan states.

## Next gate

The merge of PR 268 to main is a separate irreversible step that needs its own fresh one-use `allow`
shown to the user for the PR head at that time (the local SUMMARY commit is not on the PR, so the PR head
stays `e4936637` until pushed); the auto-delete-on-merge setting was read live as `false` and must be
re-read before asking. After the merge the exact next command is
`/gsd-verify-work 197 --ws quality-ratchet-release`.

## Self-Check: PASSED
