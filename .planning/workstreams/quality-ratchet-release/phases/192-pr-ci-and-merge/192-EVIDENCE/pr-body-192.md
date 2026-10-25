This lands the v25-v27 work from the Phase 191 integration branch onto `main`, as a merge commit, after explicit approval.

## What is in it

114 commits on top of `main`:

- 94 preserved candidate commits (the original v25-v27 candidate line, including its fix commits)
- 10 Phase 191 fix commits: FORMAT, LOCALE, G1, PRIVACY, HOST-G2G6, SWIFT-G4, WR-05, WR-01-06, WR-03, ADOPTION-EXT
- 1 planning resolver commit
- 5 planning carry commits (v23.0 to v27.0)
- 1 example-host fixture commit
- 2 planning sync commits
- 1 review-fix commit (LAND-FIX)

## How it was checked

The full local suite ran at the Phase 191 head; see [191-VERIFICATION.md](https://github.com/szTheory/crosswake/blob/4a6c1af2f2304e7c3a72ca845a2409a7a9e0d682/.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-VERIFICATION.md). The privacy scan of the whole change is clean at this head. This PR's Crosswake CI runs on GitHub's merge preview of `main` plus this head.

## What the checks did and did not cover

The check for the first adopter's private terms was skipped by the user's earlier decision (A-14).
2 personal values in older history were accepted and not rewritten; they are not shown here.
The full local suite ran at the planning sync head. The review-fix commit ran only its affected tests and the scanner self-test. This PR's CI is the full judge.

## Review follow-up

The review-disposition file carried in this PR (191-REVIEW-DISPOSITION.md) was written before the fixes and still lists the warnings as open. This PR fixes WR-01 and WR-02 in the review-fix commit and WR-03 in the planning sync commit, because the scanner lives in the planning folder. IN-01 and IN-02 are deferred to a follow-up after landing, and the updated disposition file lands in Phase 193.

## What it does not do

No version change, no release, no package publish, and no change to other open PRs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
