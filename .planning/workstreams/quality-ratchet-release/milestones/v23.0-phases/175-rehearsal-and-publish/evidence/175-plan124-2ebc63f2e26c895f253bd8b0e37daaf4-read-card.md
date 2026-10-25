# Phase 175 current-facts read scope

Status: PENDING
Attempt: 2ebc63f2e26c895f253bd8b0e37daaf4
Scope SHA-256: 0c0df8840465d5681ca6d30229620e1bf28916ef22715a3295e670f998161c17
Collector SHA-256: e3e4f3feab95a71a79ffd42a6f0ef0bdc59464fdcf86adb6d90461f2ad414ec1

No decision is recorded. No read has started. No current facts have been fetched.

## Allowed routes

- GET /repos/szTheory/crosswake/pulls/219
- GET /repos/szTheory/crosswake/commits/{head.sha from pull 219}
- GET /repos/szTheory/crosswake-shell-core-ios
- GET /user
- GET /repos/szTheory/crosswake-shell-core-ios/collaborators/{login from /user}/permission
- GET /repos/szTheory/crosswake-shell-core-ios/rulesets?includes_parents=true&per_page=100&page={1..4}
- GET /repos/szTheory/crosswake-shell-core-ios/rulesets/{returned numeric id}

## Allowed Git reads

1. source ls-remote refs/tags/ios-core-v0.2.6 and peeled ref
2. mirror ls-remote refs/heads/main, refs/tags/v0.2.5 and peeled ref, refs/tags/v0.2.6 and peeled ref
3. clone source with fixed validated argv
4. check shallow state
5. fetch fixed source tag
6. resolve fetched tag commit
7. verify fetched tag commit
8. detached checkout of fetched commit
9. inspect repository root tree
10. inspect packages/crosswake-shell-core-ios tree
11. subtree split exact package prefix and commit
12. inspect split commit
13. inspect split tree
14. verify cloned origin URL
15. recheck source tag refs
16. recheck mirror refs

## Limits

- ci_requests: 0
- credential_helper_checks: 1
- dry_run_attempts: 0
- git_operations: 16
- github_requests: 25
- ordinary_process_timeout_ms: 15000
- permission_checks: 2
- process_output_bytes: 8192
- response_bytes: 262144
- ruleset_details: 16
- ruleset_pages: 4
- subtree_split_timeout_ms: 240000
- tag_attempts: 0
- total_process_timeout_ms: 240000

Historical comparison pins only: source tag 998742856a37a97ae7247f6c532f9c154ea20885; split 424ab96ede1b92f2b751b54bce04c6e607f0f3c8; package tree b80f3bf00ef61708120b062bc88738fed88294a9; prior PR #219 tuple retained from earlier inspection. They do not establish current facts.

dry-run, tag-write, CI, merge, registry, publication, and release-authority budgets are zero.
