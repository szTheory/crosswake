# Phase 175 successor candidate status

Plan 175-44 verified the normal protected merge of repair PR #218 and the matching no-publication Release Please run. That run produced fresh candidate PR #219 for `crosswake` 0.2.7.

Candidate #219 is exact at base `e51698528dc667ef89beb951e4eb1ec91da74981`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, and tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`. It is not draft and is mergeable, but is blocked on required Crosswake CI. Hex 0.2.7, iOS mirror tag `v0.2.7`, and the Maven 0.2.7 POM are absent.

## Current blocker

Crosswake CI run [36438452825](https://github.com/szTheory/crosswake/actions/runs/36438452825) has a failed `ios-mirror-parity-proof` job. Its exact failure is that the SwiftPM mirror is missing `refs/tags/v0.2.6`. The source repository does have `ios-core-v0.2.6`, pointing at `998742856a37a97ae7247f6c532f9c154ea20885`; the mirror currently has `v0.2.5` but not `v0.2.6`. The required aggregate check is still running another job, so the recorded CI conclusion remains pending; this candidate is already ineligible because a required proof leaf has failed.

This is the earlier partial 0.2.6 iOS gap. Its Gate 2 token is consumed. Plan 175-44 does not authorize a mirror tag push, recovery, or token reuse. Plan 175-44 Task 3 and Plan 175-45 Gate 2 are not ready.

## Evidence

See `evidence/175-rel17-repair-gate.json` and `evidence/175-rel17-successor-candidate.json`. The latter preserves exact PR, CI, current branch policy, runbook ancestry, target absence, and the failing parity evidence. No publication authority was created.
