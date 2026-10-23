# Phase 175 Plan 115: One Current-State Read

This card covers one fresh, bounded check. It does not create a tag or start a release.

## What the check will do

If you allow it, the checker will use the GitHub login already saved on this computer to find which account it belongs to and what access that account has to the iOS mirror. It will also check the pinned source tag, mirror refs, pull request #219, and run one dry-run for the `v0.2.6` mirror tag. The dry-run checks whether Git would accept that exact tag; it does not push it.

The login and credential will not be shown or saved. The helper will run without opening a prompt; if it needs you to unlock or sign in, the check will stop safely.

## Current scope

- Attempt ID: `0138d7ab20f5ce20577329a27ab89c35`
- Scope SHA-256: `00d5fbbdc9bff3a23035fd055d8ac810d63f0936590e177e71bdf55f38992fc5`
- Scope file: `evidence/175-plan105-0138d7ab20f5ce20577329a27ab89c35-read-scope.json`
- Created: `2026-10-09T14:49:18.978096Z`
- Collector SHA-256: `c0eacb95396b32b8b5212596b623a6f9e377cff0b19316e0813b844662483387`
- Source: `szTheory/crosswake`, tag `ios-core-v0.2.6` (source object `998742856a37a97ae7247f6c532f9c154ea20885`)
- Mirror: `szTheory/crosswake-shell-core-ios`, checking `main`, prior tag `v0.2.5`, and whether target tag `v0.2.6` exists
- Candidate: pull request #219, version `0.2.7`, open and not draft or merged; base `e51698528dc667ef89beb951e4eb1ec91da74981`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`
- Package comparison pin: `b80f3bf00ef61708120b062bc88738fed88294a9`; expected split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`
- API routes: PR #219; its pinned commit; mirror repository; authenticated account identity (`GET /user`); that account's mirror permission; and effective mirror tag rules.
- Git operations: pinned source and mirror ref reads; source clone/fetch and package split validation; one same-credential dry-run of `object:refs/tags/v0.2.6`; then bounded rechecks of mutable refs and policy.

## Limits and current status

- At most 64 API requests, 24 Git operations, 3 permission checks, 1 credential-helper lookup, and 1 dry-run.
- At most 262,144 response bytes, 8,192 process-output bytes, and 240 seconds total.
- Tag attempts: 0. CI requests: 0. Merge, registry, and publication actions: 0.
- Current state: **PENDING**. The scope has not been authorized; no credential lookup or external request has happened for this attempt.

Only a new, explicit `allow` for this card can authorize the single check. `hold` closes this attempt without checking credentials or contacting GitHub. A successful check still does not authorize a tag push; that would need a separate decision.
