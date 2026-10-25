# Phase 175 Plan 121: Bounded Read Decision Card

**Status: CONSUMED — exact ALLOW recorded; one read made; terminal result UNKNOWN.**

Attempt ID: 62d2ab7ce54ebe587ac21d4151b5ed0f

## Exact scope

- Scope SHA-256: `9ae0e20c158126d7218381b407f7ef297a9218a9ce190d52aa53a271617ed6ee`
- Collector SHA-256: `69712958adacc61117f5c43452b8eb582efd74dfe8cac2da05cc1da42be19865`
- Scope schema: `crosswake-plan105-read-scope/v2`
- Source: `https://github.com/szTheory/crosswake.git`, ref `refs/tags/ios-core-v0.2.6`
- Mirror: `https://github.com/szTheory/crosswake-shell-core-ios.git`, target `refs/tags/v0.2.6`
- Historical comparison pins only: source object `998742856a37a97ae7247f6c532f9c154ea20885`; mirror split object `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`; package tree `b80f3bf00ef61708120b062bc88738fed88294a9`.
- Candidate comparison pins only: PR #219, version `0.2.7`, state `OPEN`, not draft or merged; base `e51698528dc667ef89beb951e4eb1ec91da74981`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`.
- Tag authority: `NONE`. Release authority: `NONE`.

These OIDs and candidate fields are fixed comparison inputs from the scope, not current observations.

## Fixed public GET routes

- `GET /repos/szTheory/crosswake/pulls/219`
- `GET /repos/szTheory/crosswake/commits/696a27a3be1fcd56efe70923dc0ce286a1c41c6d`
- `GET /repos/szTheory/crosswake-shell-core-ios`
- `GET /user`
- `GET /repos/szTheory/crosswake-shell-core-ios/collaborators/{login}/permission`
- `GET /repos/szTheory/crosswake-shell-core-ios/rulesets?includes_parents=true&per_page=100&page={1..4}`
- `GET /repos/szTheory/crosswake-shell-core-ios/rulesets/{returned numeric id}`

## Fixed Git operations

- Read the source tag `refs/tags/ios-core-v0.2.6` and peeled tag.
- Read mirror `refs/heads/main`, `refs/tags/v0.2.5`, `refs/tags/v0.2.6`, and peeled tags.
- Full-clone the source, fetch the exact source tag, and verify the package subtree and split.
- Check one configured host credential without prompting; the credential value is not returned.
- Use that same credential for `GET /user`, the fixed mirror collaborator-permission lookup, and at most one dry-run push of the exact object to `refs/tags/v0.2.6`.
- Re-read mutable source/mirror refs, PR/candidate facts, and effective tag policy.

## Caps

- Public requests: 64; Git operations: 24.
- Ruleset pages: 4; rulesets: 16; permission checks: 3.
- Response body: 262,144 bytes; process output: 8,192 bytes.
- Total process deadline: 240,000 ms. Only the `SUBTREE_SPLIT` child may use a per-process cap up to 240,000 ms, clipped to the remaining total deadline; every other child remains capped at 15,000 ms.
- Each API request has its own 8,000 ms timeout. The 240,000 ms process deadline does not cap HTTP waits.
- Credential-helper checks: 1; dry-run attempts: 1; CI requests: 0; tag attempts: 0.

The approved attempt used 7 public requests, 12 Git operations, 1 credential-helper check, and 2 permission checks. It made no dry-run, CI request, or tag attempt. No credential value, raw provider response, or process stream was retained or printed.

## Decision and terminal inspection

The exact ALLOW was recorded for this attempt and scope digest only. Authorization SHA-256: `174a13d1a2fd4bfe3abe9965f0bfeaf0f42b48c8be30085c666afeaae0a89e3f`. The exact attempt was independently inspected offline. Its terminal status is `UNKNOWN / OBSERVATION_UNAVAILABLE`, with diagnostic `SUBTREE_SPLIT / PROCESS / PROCESS_STDERR_NONEMPTY`. Counts are 7 public requests, 12 Git operations, 1 credential-helper check, 2 permission checks, 0 dry runs, and 0 tag attempts. The scope digest and collector digest match the values above.

The diagnostic does not provide the stderr contents or explain the failure. This receipt establishes no current candidate, permission, or policy facts. The attempt and its ALLOW are consumed; neither may be reused. No further acquisition or planning command is eligible until distinct evidence identifies the stderr cause and supports a genuinely different repair.

This ALLOW authorized only the single bounded Plan105 v2 observation. It did not authorize a tag write, CI, Gate 2, merge, recovery, registry action, or publication. Tag authority and release authority remain `NONE`.
