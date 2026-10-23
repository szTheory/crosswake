# Phase 175 Plan 119: One Fresh Read of the Held Tag Candidate

This card requests approval for one bounded check of current source, mirror, pull request, tag-policy, and account-permission information. It does not create or push a tag and does not start a release.

If approved, the check will use the Git Credential Manager login already configured on this computer to identify the account and check its mirror permission. It will not display, save, or copy the credential. It will also make one non-pushing dry-run for the exact tag ref below. If the credential helper prompts, stalls, or cannot finish within the limit, the attempt stops; there is no retry.

## Exact scope

- **Attempt ID:** `fc62e4d8f56df220feb75ba0b79b0baa`
- **Scope SHA-256:** `a551795c7ae39f1993c884ab2853b263ea063a50deb09d5071a8466306d402dc`
- **Collector SHA-256:** `9c71b68eb28bbc7666c5f394fc068dfcaaf14a43de3d95766cace7493a86fd95`
- **Scope file:** `evidence/175-plan105-fc62e4d8f56df220feb75ba0b79b0baa-read-scope.json`
- **Source:** `szTheory/crosswake`, ref `refs/tags/ios-core-v0.2.6`, comparison object `998742856a37a97ae7247f6c532f9c154ea20885`
- **Mirror:** `szTheory/crosswake-shell-core-ios`
- **Candidate comparison:** PR #219, version `0.2.7`; pinned base `e51698528dc667ef89beb951e4eb1ec91da74981`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`
- **Tag being checked:** `refs/tags/v0.2.6`; expected source package tree `b80f3bf00ef61708120b062bc88738fed88294a9`, comparison split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`

These hashes are comparison pins for the check; they are not claims that the current remote still matches.

## What the check may do

GitHub GET requests are limited to:

- `GET /repos/szTheory/crosswake/pulls/219`
- `GET /repos/szTheory/crosswake/commits/696a27a3be1fcd56efe70923dc0ce286a1c41c6d`
- `GET /repos/szTheory/crosswake-shell-core-ios`
- `GET /user`
- `GET /repos/szTheory/crosswake-shell-core-ios/collaborators/{login}/permission`
- `GET /repos/szTheory/crosswake-shell-core-ios/rulesets?includes_parents=true&per_page=100&page={1..4}`
- `GET /repos/szTheory/crosswake-shell-core-ios/rulesets/{returned numeric id}`

Git commands may read the pinned source and mirror refs, clone/fetch the source and verify its package split, check the configured credential helper without printing its value, and run one dry-run of the exact `424ab96ede1b92f2b751b54bce04c6e607f0f3c8:refs/tags/v0.2.6` refspec. The check may repeat mutable source/mirror refs, PR details, and tag policy before it finishes.

## Hard limits and exclusions

- At most **64** public requests, **24** Git operations, **3** permission checks, **1** credential-helper check, and **1** dry-run.
- At most **262,144** response bytes, **8,192** process-output bytes, and **240 seconds** total.
- **Zero** tag pushes, CI requests, merges, registry changes, and publications.
- Credential values, raw response bodies, process output, and account identifiers are not retained.
- This read approval would grant **no** tag or release authority. Any tag write requires a separate decision for its own exact scope.

## Terminal result

**UNKNOWN — the one approved check was used and is finished.** It made 7 public requests, checked the saved credential helper once, and made 2 permission checks. The full source split timed out; the total Git operation count is UNKNOWN. No dry-run or tag attempt occurred. The receipt established no current candidate, permission, or policy facts. Do not retry this attempt or reuse its approval.

The approval covered only this one check. It grants no tag or release authority.
