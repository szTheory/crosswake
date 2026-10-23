---
phase: 175-rehearsal-and-publish
plan: 90
subsystem: release-evidence
tags: [elixir, node, github-rest, read-scope, authorization]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan87's fixed-origin mirror-tag repair coordinator and transport.
provides:
  - One pinned read contract shared by Plan87 Elixir validation and the Node collector.
  - Exact-path pending scope, full-scope digest, reservation binding, and GET-only authorization.
affects: [175-88, 175-89]
actuals:
  tokens: 22165
  tasks: 2
  commits: 2
commits: 2
plan_head_before: ba2b48357b17afc2dda1800997225db72323bb97
plan_head_after: 0b54deb2dcdeb64442a927033ba002ff7f202bff
tech-stack:
  added: []
  patterns: [shared pinned JSON contract, full canonical scope digest, temporary-root fake authorization tests]
key-files:
  created:
    - script/release_candidate/plan87_read_scope_contract.json
  modified:
    - lib/crosswake/release_candidate/plan87_mirror_tag.ex
    - script/release_candidate/plan87_mirror_ref.mjs
    - test/crosswake/release_candidate/plan87_mirror_tag_test.exs
    - script/release_candidate/plan87_mirror_ref.test.mjs
key-decisions:
  - "The dated PR tuple is a historical equality pin only; the next live preflight must freshly confirm it."
  - "A read scope carries no write authority; the Plan89 CREATE_REF decision remains separate."
patterns-established:
  - "Both runtimes require the exact manifest bytes and compiled endpoint/cap ceiling before a read can proceed."
  - "The persisted lifecycle reservation binds the attempt and complete scope digest before any credential callback."
requirements-completed: []
coverage:
  - id: D1
    description: "Temporary-root prepare, pending inspection, and a fake authorized preflight share one exact GET-only scope contract."
    requirement: REL-13
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Scope drift and write escalation are rejected before callbacks, while the fake login sentinel remains absent from saved artifacts and output."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "node --test script/release_candidate/plan87_mirror_ref.test.mjs"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-10-07
status: complete
---

# Phase 175 Plan 90: Read-Scope Contract Repair Summary

**Plan87 now binds pending preparation, inspection, authorization, and its Node GET collector to one exact, full-digest read scope.**

## Performance

- **Duration:** 13 minutes.
- **Started:** 2026-10-06T20:17:00-04:00.
- **Completed:** 2026-10-06T20:30:06-04:00.
- **Tasks:** 2.
- **Files modified:** 5.

## Accomplishments

- Added one versioned JSON contract with a pinned byte digest, exact GET route roster, candidate comparison pin, and finite API/Git/Port bounds. Elixir and Node validate it against closed compiled limits.
- Changed prepare and pending inspection to use Plan88's exact `175-plan87-tag-026-read-scope.json` artifact, with a fresh 32-hex attempt, zero request intent, full canonical SHA-256, and a reservation lifecycle bound to that digest.
- Validated the full scope, lifecycle, attempt, contract digest, and exact one-use READ authorization before credential availability. The Node collector revalidates the scope before each request and rejects POST under READ authority.
- Kept `/user` identity transient. The persisted and returned facts retain only reduced effective permission; fake sentinel scans cover temporary artifacts and captured output.
- Preserved release posture: REL-13/14/15/17 remain OPEN, readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, Plans45–48 HELD, and Phase175 INCOMPLETE. No real Plan88/87 evidence was created or modified.

## Task Commits

1. **Task 1: Make one exact read scope survive prepare, inspection, and fake preflight** — `4900143e` (`feat`).
2. **Task 2: Prove drift and write-separation failures close before access** — `0b54deb2` (`test`).

**Plan metadata:** Documentation commits are disabled for Phase175; no metadata commit was made.

## Verification

- `MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1` — 14 tests, 0 failures.
- `node --check script/release_candidate/plan87_mirror_ref.mjs` — passed.
- `node --test script/release_candidate/plan87_mirror_ref.test.mjs` — 13 tests, 0 failures.
- `mix format --check-formatted lib/crosswake/release_candidate/plan87_mirror_tag.ex test/crosswake/release_candidate/plan87_mirror_tag_test.exs` — passed.
- `git diff --check` on the five Plan90 files — passed.
- The temporary-root scope suite checked path, purpose, attempt, routes/methods, permission template, API/Git caps, query bounds, source remote, subtree, request intent, and dated tuple drift with both stale and recomputed authorizations. Invalid cases called neither credential nor collector callbacks.
- The fake actor sentinel was absent from the temporary artifact tree and captured Mix output. No credential values, remote requests, or Git remote operations were accessed.

## Decisions Made

- The 2026-10-06 PR base/head/tree is a stale equality pin only; Plan88 must observe and compare the current tuple again.
- Plan88 may receive only a bounded GET/Git decision. Plan89 retains a distinct digest/ref/OID write decision.

## Deviations from Plan

- Task-level `tdd=true` was not completed as a committed RED/GREEN cycle. Implementation edits began before the canonical TDD reference was loaded; no classifier-confirmed RED evidence is claimed. The focused fake suites were subsequently expanded and passed, and project execution configuration reported `tdd_mode=false`.
- The Plan90 implementation was grouped into a feature commit followed by a test-matrix commit; both task scopes are committed and verified.

## User Setup Required

None. Plan90 used only fakes and temporary roots.

## Next GSD Action

Phase174 is the last completed phase. Phase175 remains incomplete. Plan90 Wave2 is complete. The exact next command is `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 3`, which runs Plan88 only. Plan88 may prepare its exact scope locally, then must stop at its explicit ALLOW/HOLD decision before any provider or credential access. Plan89 remains ineligible until Plan88 produces a complete `PREFLIGHT_READY` result and its separate write decision is given. The release hold and all open requirement states remain unchanged.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-07*

## Self-Check: PASSED

- Summary and all five Plan90 source/test files exist.
- Task commits `4900143e` and `0b54deb2` are ancestors of HEAD.
- All four Plan88 evidence paths remain absent; Plan90 used temporary roots only.
- `STATE.md` and `ROADMAP.md` name Plan88 Wave3 as the next exact action; planning docs remain uncommitted.
