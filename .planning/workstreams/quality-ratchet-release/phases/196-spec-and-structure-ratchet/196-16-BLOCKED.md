# Phase 196 Plan 16: Blocked at exact-head CI

Status: halted at a designed stop. Task 1 is done. Task 2 did not reach a ready PR, and no summary was written.

## What was checked and what happened

- Task 1 done: PR 260 (`fix(196): make spec and structure ratchets fail on empty evidence`) is open against `main` from `fix/spec-structure-ratchet`. `gate --stage pr-open` exited 0 on head `3b5f77e6a73cd5db6ba3bb4ff0b3858c2e45c7ca`. Before it, the same gate exited 1 with `delivery_missing` as the red control.
- Task 2 blocked: Crosswake CI on the first PR head `979bec852c4b96815e6cebd66194d3d45291cba9` finished red (run 40729998724). The run for the current head `3b5f77e6` was still queued behind it and was not observed. The two heads differ only in `delivery.json`, a planning file, so the supported source is byte-identical.
- The ready poll was stopped by the executor after 18 of 90 polls, so the bound did not expire and no success is claimed.

## Commits and identities

| Item | Value |
|---|---|
| base (main tip, contained in head) | `b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97` |
| PR head (current, remote read-back equal) | `3b5f77e6a73cd5db6ba3bb4ff0b3858c2e45c7ca` |
| first PR head, CI observed | `979bec852c4b96815e6cebd66194d3d45291cba9` |
| GitHub synthetic merge commit (reported separately, not head proof) | `9eb1cbe4e7a53a7f197957791a5d2297d0d3bbe7` |
| candidate identity | unchanged and equal to `candidate.json` |

The CI run on `979bec85` has its own check-run head, which equals that PR head; the synthetic merge commit is a different SHA and was not used as head proof.

## Observed causes on head 979bec85

1. Two ratchet tests fail whenever the checkout has no history for actual main. `test/crosswake/proof/rescue_boundary_ratchet_test.exs` (line 44 to 46) and `test/crosswake/proof/runtime_dependency_ratchet_test.exs` (line 60 to 62) run `git show <main_sha>:<path>`, which exits 128 with empty output in the proof jobs' shallow checkout. Four failing core proof jobs show exactly these two failures in their logs (phase130, phase132, phase41, phase45). Phase34 and phase43 failed too but their logs were not read in detail, and the example-host proof exited 2 from the same full core suite per seed without a detailed read. Locally the object exists, so the 40-child candidate run could not see it.
2. `proof-dependency-security` fails on the example host lock: an advisory for `bandit` (`corrective-command=mix deps.update bandit`). Neither lock file differs from `main`, so this is not caused by the branch. It still keeps `Crosswake CI` red and needs its own decision.

## Why this plan stops here

- The fix for cause 1 edits supported test source, which changes the candidate identity. The plan requires a fresh 196-15 candidate run, internal review and re-measured guards for that; this plan may not edit the gate tools and may not re-stamp the candidate.
- Cause 2 is outside Phase 196 scope (example host dependency update).
- No force push, admin merge, main merge, publish, tag or remote deletion was attempted.

## State left behind

- PR 260 stays open on `3b5f77e6`. The run on that head is queued and will likely show the same causes.
- This file is committed locally on the feature branch and not pushed, so the PR head is still `3b5f77e6`.
- `196-EVIDENCE/delivery.json` records the PR number and the unchanged SPEC-04 move to v29.0; it records no CI success.

## Reopening condition

Reopen plan 16 task 2 after: (a) the two tests read main's objects only when present, or the proof jobs fetch that history, with a negative control; (b) a fresh 196-15 candidate run and review on the new identity; (c) a decision on the example host `bandit` advisory; then push, wait for CI on the new head, and run `gate --stage ready` on that head.
