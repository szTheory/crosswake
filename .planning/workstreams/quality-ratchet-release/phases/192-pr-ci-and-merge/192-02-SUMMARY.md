---
phase: 192-pr-ci-and-merge
plan: 02
subsystem: release-landing
tags: [privacy-scan, fail-closed, wr-03]
requires: [192-01]
provides:
  - "scan-191.sh fails closed on unreadable git notes (WR-03)"
  - "privacy-192.sh plain privacy check with self-test"
affects: [192-06, 192-07, 192-08, 192-09, 192-10]
key-files:
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/scan-191.sh
    - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/selftest-scan-191.sh
  created:
    - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/privacy-192.sh
    - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts/selftest-privacy-192.sh
    - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-EVIDENCE/red-WR03-192.txt
    - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-EVIDENCE/selftest-scan-192.out
    - .planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-EVIDENCE/selftest-privacy-192.out
status: complete
commits: 0
requirements: [LAND-03]
---

# Phase 192 Plan 02: WR-03 fail-closed scanner and privacy check Summary

The privacy scanner now stops, instead of skipping, when a git note cannot be read, and there is a plain privacy check for the public PR text and evidence. Both were proven by running their self-tests.

## What was checked

- New scanner control S33 (`unreadable git note is a scope error`) was run against the unfixed scanner first. It reported `NOT as expected` and the run closed with `selftest-scan: controls 32 of 33 as expected` (saved in `red-WR03-192.txt`).
- After the fix the full scanner self-test exits 0 and ends `selftest-scan: controls 33 of 33 as expected`, including S33 passing (`selftest-scan-192.out`).
- The privacy self-test ends `selftest-privacy: controls 13 of 13 as expected`, with no planted value in any output (`selftest-privacy-192.out`).
- `privacy-192.sh` with no argument prints `privacy: no input` and exits 2. It reports `privacy: clean files 3` for 192-CONTEXT.md, 192-01-PLAN.md and 192-02-PLAN.md, and also for the three evidence files written here.

## What changed

- scan-191.sh: exactly two lines in the notes block. The notes listing now ends `|| fail "notes list failed"` and the note blob read ends `|| fail "cat-file failed"` (both exit 2). The old empty-file fallback and skip-to-next-note fallback are gone.
- selftest-scan-191.sh: new control S33, registered after S32. The fixture adds a note to the head commit and deletes the note blob's loose object.
- privacy-192.sh: eight classes (home_path, user_temp, gh_token, pem, cred_assign, email, account, private_string). Hits print `privacy: hit CLASS file K` with K as the argument index, never a value or path. Zero arguments are `no input` and a missing or unreadable file is `unreadable`, both exit 2. The test hooks T192_ACCOUNT and T192_PRIVATE_STRINGS are refused unless SELFTEST_192=1 and the strings file is under the fixture prefix.
- selftest-privacy-192.sh: controls V01-V13.

## Important for Plan 06 (D-01 deviation)

The scanner fix is a change to a phase script in the recovery checkout. It reaches the PR only through Plan 06's planning sync commit, not through the WR-01/WR-02 code commit. Verification of the PR must look at the sync commit's copy of scan-191.sh.

## Commits

None. Commits were skipped per the recovery-checkout rule; all files are plain, uncommitted files. Nothing was pushed to GitHub. STATE.md and ROADMAP.md were not touched. `commits: 0` is correct here because the work sits as plain files by design, not as an unreported change.

## Deviations from Plan

None. The plan was executed as written. D-02 was followed: only the scanner self-test was run for WR-03, not the full suite.

## Known Stubs

None.

## Threat Flags

None. T-192-04 and T-192-05 are mitigated as planned.

## Self-Check: PASSED

All seven listed files exist; both task verify commands exited 0; no fixture folders were left under the shared temp location.
