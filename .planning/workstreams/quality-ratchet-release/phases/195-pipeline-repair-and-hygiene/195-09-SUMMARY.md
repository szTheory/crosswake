---
phase: 195-pipeline-repair-and-hygiene
plan: 09
subsystem: infra
tags: [ci, github-actions, dependabot, weekly-canary, release-gate]
requires:
  - phase: 195-08
    provides: See It Run split and grouped Dependabot on the PR2 branch
provides:
  - "PR2 (#251) merged to main by merge commit 735c3bc after its own one-use allow"
  - "Canary node pin fix-forward (#254) merged at 0b28e6d after its own one-use allow"
  - "Weekly Canary green on main (run 40354096432, 0b28e6d, attempt 1)"
  - "Dependabot security updates enabled with read-back"
affects: [195-10, 195-13]
requirements-completed: [REL-03, REL-04, REL-05]
actuals:
  tokens: 6000
  tasks: 3
  commits: 0
  plan_head_before: 4c07549b0b24a4115de444f621d5a93821428b78
  plan_head_after: 4c07549b0b24a4115de444f621d5a93821428b78
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 09: Ship PR2, observe lanes on main, enable security updates Summary

**PR2 landed, the first Weekly Canary on main was red (missing exact node 22.14.0), a gated fix-forward PR #254 landed, and the canary is now green on main; Dependabot security updates are on.**

This plan makes no repository commits of its own (its code arrived through PR #251 and #254); its output is the four untracked evidence files plus GitHub state. `commits: 0` is measured: the plan wrote evidence only, which plan 10 commits first.

## Approvals

- pr2 approval: allow, bound to PR 251 head 51af1f9. Merged once with a merge commit: 735c3bce826f4e70a50f8636440d3d89c62c58e5.
- pr2 fix approval: allow, bound to PR 254 head 4c07549 (fresh, not transferred). Merged once with `--match-head-commit`: 0b28e6d69767045bbd37c737068bd84c77ba86d4.

## Results

- See It Run on main (run 40327633511, 735c3bc): `web-and-gif` success, `assemble-pr` success, no `native` job. Auto-PR #253 (collateral/auto-refresh) is OPEN at head c8d774f; recorded only, plan 13 dispositions it.
- Weekly Canary, first dispatch on main (run 40327687439, 735c3bc, attempt 1): **failure** at the repository-preflight step of the hermetic root proof. No test ran. The log did not name the tool; the cause was established as the missing exact node 22.14.0 (the canary lacked the setup-node step that the required proof job has). The `asdf install` text was only the remediation hint. It was not re-run.
- Fix-forward PR #254 (`ci: pin node 22.14.0 in the weekly canary root proof`): Crosswake CI run 40328871069, pull_request, success, reporting head 4c07549 (it tested a synthetic merge commit). Pre-merge confirmation: canary dispatched from the branch, run 40333952719, success on 4c07549.
- Weekly Canary on main after the fix: run 40354096432, workflow_dispatch, head 0b28e6d, attempt 1, success (PASS repository-preflight, root-proof, repository-cleanliness). The canary stays advisory; the required check list is still `["Crosswake CI"]`.
- Dependabot security: automated-security-fixes before `{"enabled":false,"paused":false}`, vulnerability-alerts before 404; after `{"enabled":true,"paused":false}` and 204. Live re-read `true`. Only these two settings were written.
- Observed: PR #252, a grouped Dependabot "bump actions/setup-java ... in the actions group", is the first evidence the monthly grouping config is live. Recorded only.
- Remote tags unchanged (94). Remote branches `ci/recurring-lanes-and-secret-masking` and `ci/weekly-canary-node-pin` kept for plan 13.

## Deviations from Plan

**1. [Rule 1 - Bug] README doc-drift fixed before push.** A README statement drifted from the changed workflows and was corrected before the push of PR2.

**2. [Rule 1 - Bug] Red first canary, cause, fix-forward PR #254 with its own gate.** The plan said a non-success canary writes 195-09-BLOCKED.md and stops, never re-run to green. That happened (BLOCKED written, canary not re-run). The fix then went through a new PR with its own CI and its own one-use allow, as the plan's own text directs for a later fix. The re-dispatch after the merge was a fresh dispatch on a new main commit, not a re-run: it is attempt 1 of a different run. 195-09-BLOCKED.md was deleted once that run succeeded.

**3. [Process] Protection contexts recorded just before merge.** `pr2: protection_contexts_before ["Crosswake CI"]` was captured just before the merge, not before Task 1. The value after, and again after the fix, is identical (`["Crosswake CI"]`), so no protection change is evident.

**4. [Evidence format] Red canary lines renamed.** In lanes-main-195.txt the red run's lines were first written with the `canary:` prefix, which the Task 3 verify's awk would also match (two canary runs). They were renamed `canary_red:` so the single `canary: run ... conclusion success` line is the main-green record; a note line in the file says so. The red facts are preserved verbatim.

**5. [Plan-text mismatch] Task 3 step 5 (`git switch main`).** Done per the plan so plan 10 branches from current origin/main.

## Verify results

- Task 1 and Task 2: satisfied before the pause (privacy clean, CI success on head, allow recorded).
- Task 3 verify (file checks): merge commit on origin/main; web-and-gif success; native_job_present no; canary success on attempt 1; canary head 0b28e6d contains 735c3bc; security after read-back enabled; auto_pr line present. All pass.
- Task 3 live checks: web-and-gif success and no native job on run 40327633511; canary 40354096432 live head and conclusion match; attempt 1; security enabled true; open auto-refresh PR #253 recorded. All pass.
- Acceptance: protection contexts `["Crosswake CI"]` equal the before value; tags 94 unchanged.

## Known Stubs

None.

## Self-Check: PASSED

Evidence files exist; PR #251 and #254 merge commits are ancestors of origin/main.
