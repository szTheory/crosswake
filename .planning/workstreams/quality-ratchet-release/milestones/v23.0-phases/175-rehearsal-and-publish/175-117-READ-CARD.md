# Phase 175 Plan 117: One Fresh Current-State Read

This card covers one bounded read of current source, mirror, candidate, permission, and tag-policy facts. It does not create a tag or start a release.

If you allow it, the checker will use the GitHub login already saved on this computer to check which account it represents and that account's access to the iOS mirror. It will then check the exact source tag, mirror refs, pull request #219, applicable tag policy, and one-ref Git dry run within the limits below. No login setup, token, or secret is requested or saved. If the saved helper requires a prompt or unlock, the check stops safely.

This is one read only. Plan115's earlier ALLOW was spent on its terminal UNKNOWN result and does not apply here. Even a complete successful read would not authorize a tag, CI rerun, merge, registry change, or publication; those require separate authority.

## Current scope

Attempt ID: 17f1791ecb4c181146e35250a2e5bc93
Scope SHA-256: 1b7394710d00a176fc6780fe45b004102da2ad428a760cc0afeff90eff89267d

- Scope file: `evidence/175-plan105-17f1791ecb4c181146e35250a2e5bc93-read-scope.json`
- Created: `2026-10-09T18:06:46.268715Z`
- Collector: `script/release_candidate/plan105_mirror_tag_collector.mjs`
- Collector SHA-256: `9218ef655f6b0537a0b31ea35706f62d43b424bddb0b6f3f6fada08d93a6c5a7`
- Source: `szTheory/crosswake`, tag `ios-core-v0.2.6`, pinned source object `998742856a37a97ae7247f6c532f9c154ea20885`
- Mirror: `szTheory/crosswake-shell-core-ios`; refs checked include `main`, prior tag `v0.2.5`, and target tag `v0.2.6`
- Source ref: `refs/tags/ios-core-v0.2.6`
- Target ref: `refs/tags/v0.2.6`
- Candidate comparison: PR #219, version `0.2.7`, state OPEN, draft false, merged false; base `e51698528dc667ef89beb951e4eb1ec91da74981`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`
- Package tree pin: `b80f3bf00ef61708120b062bc88738fed88294a9`; expected split: `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`

## Allowed routes and operations

API access is limited to GET requests for:

- PR #219: `GET /repos/szTheory/crosswake/pulls/219`
- Its pinned commit: `GET /repos/szTheory/crosswake/commits/696a27a3be1fcd56efe70923dc0ce286a1c41c6d`
- The mirror repository: `GET /repos/szTheory/crosswake-shell-core-ios`
- Authenticated account identity: `GET /user`
- That account's mirror permission: `GET /repos/szTheory/crosswake-shell-core-ios/collaborators/{login}/permission`
- Effective tag rules: `GET /repos/szTheory/crosswake-shell-core-ios/rulesets?includes_parents=true&per_page=100&page={1..4}` and `GET /repos/szTheory/crosswake-shell-core-ios/rulesets/{returned numeric id}`

Git work is limited to reading the pinned source and mirror refs, cloning/fetching the source to verify the package subtree and split, one dry-run of the exact `object:refs/tags/v0.2.6` refspec using the same credential, and bounded rechecks of mutable refs, the candidate, and policy. The dry-run does not push.

## Limits and current status

- At most 64 public requests, 24 Git operations, 3 permission checks, 1 credential-helper lookup, and 1 dry-run.
- At most 262,144 response bytes, 8,192 process-output bytes, and 240 seconds total.
- CI requests: 0. Tag attempts: 0. Merge, registry, and publication actions: 0.
- Current status: **PENDING**. Inspection confirms zero credential checks, public requests, Git operations, dry runs, permission checks, and tag attempts. No read intent has been recorded for this attempt.

Only a new, explicit `allow` for this displayed card can authorize this single check. `hold` closes this attempt without checking credentials or contacting GitHub.
