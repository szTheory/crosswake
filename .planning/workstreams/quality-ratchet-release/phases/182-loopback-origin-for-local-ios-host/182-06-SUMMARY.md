---
phase: 182-loopback-origin-for-local-ios-host
plan: 06
status: complete
requirements: [LOOP-05]
commits: 0
plan_head_before: none (no commits in this plan; the 182 clone stays at its final head)
plan_head_after: da53c54db06e54be5a80fb4be144a70d3fed36a5
---

# Phase 182 Plan 06: Phase 180 candidate move Summary

## What happened

The Phase 180 working copy (/private/tmp/crosswake-phase180-impl) was moved from its old commit 12f84cd onto the verified Phase 182 commit da53c54, which contains the loopback mode. The move was a fetch from the local Phase 182 clone followed by a detached checkout, with no force flags. Nothing was pushed, merged, released or opened as a PR, and the recovery checkout was not touched (nothing staged, HEAD still d0f3e2f1).

## What was checked

- Before the move: the Phase 182 clone was clean at da53c54 and its tree matched the final-head record and the passed Simulator result. The Phase 180 copy was at 12f84cd with exactly 21 uncommitted paths (no renames). None of those paths overlap the 33 files the 182 work changed. The three pinned tests matched their recorded hashes.
- A before-manifest (path, status, sha256, mode for each of the 21 paths), the binary diff, and a tarball backup were written first, outside any Git repository: /private/tmp/crosswake-phase182-move-backup-20261015T003402Z
- After the move: Phase 180 HEAD is da53c54 and its tree equals the 182 tree (d1cbbe30). All 21 paths have identical status, hash and mode. The binary diff hash is identical (e208f105...). The three pinned tests are unchanged. 180-CANDIDATE.json, 180-GATE.json, 180-05-BLOCKED.md and 180-ORIGIN-DECISION.json are byte-unchanged, and consumed_by is still null.
- An independent recomputation from live Git state matched the move record.

## Record

182-CANDIDATE-MOVE.json (result moved). It states: "The 180-01 gate must rerun on new_head before 180-05 reruns from Task 1." and that 180-05 must generate under MIX_ENV dev or test.

## Deviations from Plan

One small repair while building the backup: the first tarball attempt failed because of how tar resolved its file list, so it was rebuilt before any move. The rebuilt tarball lists all 21 paths plus head.diff. No other deviation.

## Unknown

Whether the Phase 180 gate passes on the new head. It has not been run; no mix, swift or xcodebuild ran in the Phase 180 copy.

## Next action

`$gsd-execute-phase 180 --ws quality-ratchet-release` which first reruns the 180-01 gate on the new head (new verdict, the 12f84cd verdict kept as baseline) and only then reruns 180-05 from Task 1 under MIX_ENV dev or test, setting consumed_by in 180-ORIGIN-DECISION.json at that point.

## Self-Check: PASSED
