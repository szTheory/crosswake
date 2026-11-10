---
id: TODO-013
title: The exact-public record-ledger job drops its verdict line and reports success when another ledger PR is already open
status: open
created: 2026-11-09
severity: medium
surfaced_by: release run 42713010358 (0.2.14) and the Phase 201 Nyquist audit
relates_to: REL-09, Phase 201, TODO-012
---

# record-ledger loses a verdict silently

## Outcome

A release run never loses its ledger line. When a ledger PR is already open, the job either stacks a
second PR or fails visibly and names the lost line in the job summary.

## What happens today

In `.github/workflows/exact-public-proof.yml` (job `record-ledger`, around line 342) the duplicate
branch logs "Ledger pull request #N is already open - not opening a duplicate. Merge #N, then re-run
this job." and exits 0. The line stays in the runner workspace, and the job and its summary report
success. Release run 42713010358 (0.2.14) hit this because PR 285, the 0.2.13 failure line, was open.
Phase 201 appended the 0.2.14 line by hand with `script/append_release_ledger.sh` in PR 289, so no
verdict is missing from main. A future release would lose its line the same way.

## Fix direction

Make the duplicate branch fail or stack a ledger PR, report the lost line in the job summary, and add
a check to `script/check_release_workflow_integrity.exs` modeled on `cleanup_pr_deduped`; the existing
`release.cleanup.deduped` check covers only `release-as-cleanup`. Also consider that bot PRs opened with
the workflow token get no CI checks, so they cannot meet the standing merge rule (CI green on the exact
head) without a manual path.

## Reopen when

A release is about to run, or the next ledger PR is opened while another is open.
