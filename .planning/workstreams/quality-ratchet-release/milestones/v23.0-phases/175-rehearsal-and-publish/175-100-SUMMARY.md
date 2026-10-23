---
phase: 175-rehearsal-and-publish
plan: 100
subsystem: release-evidence
tags: [ios-mirror, read-scope, release-hold, rehearsal]
requires:
  - phase: 175-99
    provides: "Plan99 checkout-before-subtree-split collector and fixed v2 read contract"
provides:
  - "An isolated Plan100 root with the byte-identical Plan99 collector and v2 contract"
  - "One fresh Plan97-compatible PENDING scope and a sanitized Wave10 approval card"
affects: [REL-13, REL-17, Plan101, Phase175 release hold]
actuals:
  tokens: 20063
  tasks: 2
  commits: 2
  plan_head_before: c58f254dc4e0f9267b209c2329cc9a54df2bd11f
  plan_head_after: 6f974ecd856ccb4590d9334e82047074093f14cf
tech-stack:
  added: []
  patterns:
    - "Isolated fake-adapter proof before fresh exclusive scope reservation"
    - "PENDING scope card binds attempt, path-set, scope, contract, target, routes, and bounds"
key-files:
  created:
    - attempt-roots/plan100/mix.exs
    - attempt-roots/plan100/script/release_candidate/plan87_mirror_ref.mjs
    - attempt-roots/plan100/script/release_candidate/plan87_read_scope_contract.json
    - attempt-roots/plan100/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan97-path-set.json
    - attempt-roots/plan100/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan97-41321f55e8cb60c9a4f6c3ddcc62cd89-read-scope.json
    - attempt-roots/plan100/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan97-41321f55e8cb60c9a4f6c3ddcc62cd89-preflight.lifecycle.jsonl
    - attempt-roots/plan100/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan97-ops-41321f55e8cb60c9a4f6c3ddcc62cd89-1e01ee01a4b5b4c0c3836f9c8a3976d9477dda4d1a9c0021e5bd02da8b17a8c3-parent.jsonl
    - attempt-roots/plan100/.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan97-ops-41321f55e8cb60c9a4f6c3ddcc62cd89-1e01ee01a4b5b4c0c3836f9c8a3976d9477dda4d1a9c0021e5bd02da8b17a8c3-child.jsonl
    - 175-100-SUMMARY.md
  modified: []
key-decisions:
  - "Plan98/99 OIDs remain historical comparison pins; neither terminal evidence nor approval transfers to this new attempt."
  - "Plan101 owns the fresh exact ALLOW/HOLD decision and any one-use read; Plan100 makes no authorization decision."
requirements: [REL-13, REL-17]
requirements-completed: []
coverage:
  - id: D1
    description: "The isolated root contains the exact Plan99 collector and contract, and local fake tests prove checkout-before-split behavior."
    requirement: REL-13
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan94_mirror_read_test.exs --max-cases 1 (11 passed)"
        status: pass
      - kind: unit
        ref: "node --test script/release_candidate/plan87_mirror_ref.test.mjs (21 passed)"
        status: pass
      - kind: other
        ref: "cmp -s against the source collector and v2 contract"
        status: pass
    human_judgment: false
  - id: D2
    description: "A fresh Plan100 scope is PENDING with no read intent or invocation and empty separate operation journals; the exact scope card is recorded for Plan101."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "plan97-inspect --expect pending --json (exit 0)"
        status: pass
      - kind: other
        ref: "Read-only artifact inspection: lifecycle RESERVED; parent and child journals each 0 bytes; scope request_count 0 and read_intent false"
        status: pass
    human_judgment: false
duration: 9 min
completed: 2026-10-07
status: complete
---

# Phase 175 Plan 100: Rehearsal and Publish Summary

**Plan100 isolates Plan99’s checkout-before-split mirror collector and reserves one fresh, zero-operation PENDING scope for a separately authorized review.**

## Performance

- **Duration:** approximately 9 minutes.
- **Started:** approximately 2026-10-07 23:38 UTC (worktree dispatch timestamp).
- **Completed:** 2026-10-07.
- **Tasks:** 2.
- **Files created:** 9, including this summary.

## Accomplishments

- Created the isolated Plan100 root with a byte-identical copy of the Plan99-fixed collector and unchanged v2 read contract. The contract digest is ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2.
- Ran the existing local fake Mix-to-Node boundary and checkout-order suites: 11 ExUnit tests and 21 Node tests passed; both source/copy comparisons passed.
- Reserved and inspected one fresh Plan97-compatible scope. It is PENDING, has read_intent false and request_count 0, and its parent and child operation journals are separate empty files.
- Recorded the complete approval card below. Plan100 made no ALLOW/HOLD decision and performed no provider, credential, Git remote, CI, tag/ref, merge, registry, recovery, or publication operation.
- Preserved the release posture: REL-13/14/15/17 OPEN; candidate readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD; Phase175 INCOMPLETE.

## Wave10 approval card — review only, no decision requested here

This card describes the single scope Plan101 may present for a fresh explicit decision. Historical comparison OIDs are planning pins only; they do not establish current remote state or carry forward any earlier approval.

- **Attempt:** 41321f55e8cb60c9a4f6c3ddcc62cd89
- **Path-set SHA-256:** cfc70d268b2865286b671d718855810d9fcfa40df214ae05de4a52dcae5de54e
- **Scope SHA-256:** 1e01ee01a4b5b4c0c3836f9c8a3976d9477dda4d1a9c0021e5bd02da8b17a8c3
- **Contract SHA-256:** ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2
- **Source:** szTheory/crosswake, tag ios-core-v0.2.6, ref refs/tags/ios-core-v0.2.6.
- **Mirror:** szTheory/crosswake-shell-core-ios; main ref refs/heads/main; prior tag refs/tags/v0.2.5; target tag refs/tags/v0.2.6.
- **Fixed target:** refs/tags/v0.2.6.
- **Candidate comparison pin:** PR #219, version 0.2.7, base e51698528dc667ef89beb951e4eb1ec91da74981, head 696a27a3be1fcd56efe70923dc0ce286a1c41c6d, tree 5279cae1daa1fbff3437b673df8ca231fb07c91f. This tuple is historical planning input observed 2026-10-06, not a live observation.
- **API origin and method:** https://api.github.com; GET only, limited to these eight paths:
  1. /repos/szTheory/crosswake/git/ref/tags/ios-core-v0.2.6
  2. /repos/szTheory/crosswake/pulls/219
  3. /repos/szTheory/crosswake/git/commits/{oid40}
  4. /repos/szTheory/crosswake/git/tags/{oid40}
  5. /repos/szTheory/crosswake-shell-core-ios/git/ref/heads/main
  6. /repos/szTheory/crosswake-shell-core-ios/git/ref/tags/v0.2.5
  7. /repos/szTheory/crosswake-shell-core-ios/git/ref/tags/v0.2.6
  8. /repos/szTheory/crosswake-shell-core-ios/git/commits/{oid40}
- **Git observation boundary:** at most nine Git spawns against the fixed source remote https://github.com/szTheory/crosswake.git: clone the source, fetch only the fixed source tag, resolve its tag object and peeled commit, check out that commit detached before resolving the source and package-prefix trees, split the fixed prefix packages/crosswake-shell-core-ios, then resolve the split tree. The fixed route must retain Plan99’s checkout-before-split order.
- **Bounds:** 32 API requests maximum; 10-second HTTP timeout; 32,768-byte response and port-output caps; 240-second port timeout; Git clone/fetch/split/other timeouts of 180/60/120/20 seconds; 8,192-byte Git buffer and 4,096-byte stdout cap; ruleset pagination metadata is limited to four pages of 100 with no added query.
- **Excluded API routes:** no user identity, collaborator-permission, or ruleset endpoint is in the eight-path allowlist; a permission route template in the contract is not authorization to call it.
- **Reservation state:** PENDING / RESERVED; read_intent false; request_count 0; no read invocation. Parent and child operation journals are each 0 bytes.
- **Decision boundary:** only a new, separate exact ALLOW can authorize at most one anonymous read sequence under this attempt and scope. HOLD means zero requests. Neither choice authorizes a tag write, merge, recovery, registry operation, CI action, or publication. Plan101 owns this decision and the terminal exact-or-UNKNOWN accounting.

## Task Commits

1. **Task 1: Prove corrected read path locally and create isolated root** — 4dbb0c85.
2. **Task 2: Reserve and inspect fresh exact scope** — 6f974ecd.
3. **Plan metadata:** this summary is committed separately; its commit is reported in the execution result.

## Files Created

The eight task artifacts are listed in frontmatter. No source files or shared orchestrator artifacts were modified by this plan.

## Decisions Made

- Retained Plan98/99 facts solely as historical comparison pins; the new attempt has independent identity and requires its own decision.
- Left authorization for Plan101. Plan100 ends PENDING and does not infer ALLOW or HOLD.

## Deviations from Plan

None — both tasks followed the plan. The Git metadata write required an approved sandbox escalation; commits used normal hooks and did not bypass verification.

## Issues Encountered

- The sandbox initially denied local Git metadata writes. The authorized escalation allowed ordinary local commits; hooks ran normally.
- The ExUnit command printed pre-existing undefined-module warnings for unrelated Plan83 references. All 11 tests passed; unrelated files were not changed.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan100 is complete and its PENDING scope is ready for Plan101’s fresh exact ALLOW/HOLD gate. The gate must occur before any read intent or public request. Phase175 remains incomplete; all release holds and open requirements remain as recorded above. STATE.md and ROADMAP.md are intentionally left for the orchestrator to reconcile after this wave.

## Self-Check: PASSED

- The eight Task1/Task2 artifacts and both task commits were verified before summary assembly.
- After committing this summary, the summary file and metadata commit were checked alongside both task commits.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-07*

