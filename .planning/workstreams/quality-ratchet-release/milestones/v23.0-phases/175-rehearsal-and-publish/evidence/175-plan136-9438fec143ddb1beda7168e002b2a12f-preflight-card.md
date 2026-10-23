# Crosswake exact-head preflight

Status: PENDING. This card records a local one-use choice. No current facts have been fetched.

Attempt: 9438fec143ddb1beda7168e002b2a12f
Scope SHA-256: 1fda45cec4e0be79f31bfa18c5db6f42997882cca0edf7254cbc647b8cde3aa0
Collector SHA-256: 56b06d59f9708aa54886d7a8a05bcf9cc9d810a5ea7ee3f43b272fa0848aeb7f

## Allowed routes

- GET /repos/szTheory/crosswake/pulls/219
- GET /repos/szTheory/crosswake/commits/696a27a3be1fcd56efe70923dc0ce286a1c41c6d
- GET /repos/szTheory/crosswake-shell-core-ios
- GET /user
- GET /repos/szTheory/crosswake-shell-core-ios/collaborators/{login}/permission
- GET /repos/szTheory/crosswake-shell-core-ios/rulesets?includes_parents=true&per_page=100&page={1..4}
- GET /repos/szTheory/crosswake-shell-core-ios/rulesets/{returned numeric id}
- GET /repos/szTheory/crosswake/contents/.release-please-manifest.json?ref={validated head.sha from pull 219}

## Allowed operations

1. ls-remote source: refs/tags/ios-core-v0.2.6 and peeled tag
2. ls-remote mirror: refs/heads/main, refs/tags/v0.2.5, refs/tags/v0.2.6 and peeled tags
3. full clone source; fetch exact source tag; verify package subtree and split
4. one configured host credential lookup without terminal, askpass, or manager prompts
5. GET /user and fixed mirror collaborator permission lookup using the same credential
6. one --dry-run --porcelain push with the same credential and exact object:refs/tags/v0.2.6 refspec
7. repeat mutable source/mirror refs, PR/candidate and effective tag policy

## Limits

- ci_requests: 0
- credential_helper_checks: 1
- dry_run_attempts: 1
- git_operations: 24
- permission_checks: 3
- process_output_bytes: 8192
- public_requests: 66
- response_bytes: 262144
- ruleset_pages: 4
- rulesets: 16
- tag_attempts: 0
- total_process_ms: 240000

The fixed source object is 424ab96ede1b92f2b751b54bce04c6e607f0f3c8; the sole permitted ref is refs/tags/v0.2.6. The version comes only from the root release manifest fetched by the verified PR head and tree. The PR title is not version evidence.

Reply `allow` to authorize this exact local synthetic attempt or `hold` to stop it. This choice cannot authorize a tag, CI, merge, registry, publication, or release. Tag authority: NONE. Release authority: NONE.
