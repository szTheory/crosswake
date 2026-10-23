---
phase: 175-rehearsal-and-publish
plan: 93
subsystem: release-evidence
tags: [elixir, node, evidence, fail-closed]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan91 attempt-bound operation accounting and the D-107 planning trigger
provides:
  - Temporary-root Plan93 candidate read coordinator, CLI, and fake GET/Git proof
  - One fixed pending attempt, closed by a zero-request terminal HOLD
affects: [phase-175, REL-13, REL-17]
actuals:
  tasks: 3
  commits: 2
  plan_head_before: be786849fe55fcf444478d66f16d82667307fd35
  plan_head_after: 720c7b8153d1915854570f13e947debca445cf3e
tech-stack:
  added: []
  patterns:
    - Attempt-bound path set with recursive preservation manifest and symlink rejection
    - Exact-or-UNKNOWN API, Git, and parent-process journals
key-files:
  created:
    - lib/crosswake/release_candidate/plan93_candidate_read.ex
    - lib/mix/tasks/crosswake.release.candidate_read.ex
    - test/crosswake/release_candidate/plan93_candidate_read_test.exs
    - script/release_candidate/plan93_candidate_read.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-path-set.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-480db51798d676a00645f29822d951c9-read-scope.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-480db51798d676a00645f29822d951c9-history-manifest.json
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-480db51798d676a00645f29822d951c9-preflight.lifecycle.jsonl
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-ops-480db51798d676a00645f29822d951c9-a23a336c99fbd4e16e249856a5252b839a6a2128c85fc02db31a33d5471ea754-parent.jsonl
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-ops-480db51798d676a00645f29822d951c9-a23a336c99fbd4e16e249856a5252b839a6a2128c85fc02db31a33d5471ea754-child.jsonl
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-480db51798d676a00645f29822d951c9-hold.json
  modified:
    - script/release_candidate/plan87_mirror_ref.mjs
requirements-completed: []
coverage: []
status: halted
---

# Phase 175 Plan 93: Exact-candidate read path closed at zero-request HOLD

Plan93 implemented a Plan93-only fixed-contract read path for the held `0.2.7` candidate. Its
local fake proof passed, and one fresh attempt was prepared and inspected offline. The user's
reply `allow` omitted the required attempt, path-set, scope, contract, and candidate bindings.
Plan93 defines any inexact reply as `READ_NOT_ALLOWED`; the attempt was therefore closed as a
terminal HOLD. No Plan93 ALLOW or read authorization was created.

## Results

- Task 1 implemented a fixed-locator coordinator and Mix task, extended the shared Plan87 reader
  with closed Plan93 path/scope/authorization validation, and added temporary-root fake HTTP/Git
  tests. Tests cover exact authorization ordering, sanitized output, durable operation accounting,
  missing credentials, incomplete journals, nested prior evidence, and symlink rejection.
- Task 2 reserved fixed locator
  `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan93-path-set.json` for attempt
  `480db51798d676a00645f29822d951c9`. Path-set SHA-256 is
  `1085d9a7ba223eb77d44763f01eb207c8a1f55d069a39fe5563431295acfa12a`; scope SHA-256 is
  `a23a336c99fbd4e16e249856a5252b839a6a2128c85fc02db31a33d5471ea754`; contract SHA-256 is
  `ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2`. The fixed candidate
  tuple is version `0.2.7`, base `e51698528dc667ef89beb951e4eb1ec91da74981`, head
  `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree
  `5279cae1daa1fbff3437b673df8ca231fb07c91f`.
- The history manifest digest is
  `e70d58cf3afa5dc23ea3e2d759230ed77336dbc49e0b0ce4cacbada6b0a432e9`. It records all 145
  pre-existing evidence files, including 65 nested files and four Plan92 artifacts. Offline
  inspection verified the manifest again at terminal closeout.
- The first prepare invocation failed before writing because the existing evidence tree contains
  nested directories. Recursive inventory with symlink rejection was added; fake gates passed
  again, and the subsequent successful prepare created the only fixed locator. No partial Plan93
  files were left by the failed invocation.
- Task 3 sealed terminal HOLD digest
  `42c4ec245ca7e04484b259cacd69a5e21d0d41cc579d0ebaa593942b645d38a9`. Terminal inspection
  confirms `request_count=0`, `read_intent=false`, `read_invocations=0`; both operation journals
  remain empty. No credential lookup, HTTP/provider access, or Git remote operation occurred.

## Checks Performed

- Focused ExUnit: 8 tests, zero failures.
- Plan93 Node suite: 4 tests, zero failures or skips; `node --check` passed.
- Named Elixir format check and scoped `git diff --check` passed.
- Fixed locator pending inspection and terminal held inspection passed.
- The Plan88/Plan92 evidence and approvals were not selected. The prior-evidence manifest remained
  valid; all release requirement statuses and holds are unchanged.

## Commits

- `dadb89b0` — RED tests for attempt-bound read gate.
- `720c7b81` — Plan93 coordinator, CLI, bounded reader integration, and fake tests.

Phase175 remains INCOMPLETE. REL-13/14/15/17 remain OPEN, candidate readiness BLOCKED, merge
policy UNKNOWN, release hold ACTIVE, and Plans45–48 HELD. The phase index has no eligible plan
after this terminal safe stop. Reopen only when new, independently verifiable evidence supports a
materially distinct bounded observation path and a separately scoped plan; do not repeat Plan93,
reuse this attempt, or route back through discussion/planning on the same trigger.

## Self-Check: PASSED

- The fixed locator, exact attempt-derived files, zero-request HOLD, and unchanged history manifest
  passed offline inspection.
- No ALLOW artifact, preflight result, credential lookup, provider request, or Git remote operation
  exists for this attempt.
- The phase index reports no runnable plan.
