---
phase: 175-rehearsal-and-publish
plan: 113
subsystem: release-evidence
tags: [bounded-reader, authenticated-permission, privacy]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan112's fail-closed handling for anonymous repository permission metadata
provides:
  - A fake-proven authenticated account and mirror-role check using one in-memory credential
  - A fresh Plan105 read scope that remains pending until a separate exact decision
affects: [REL-13, REL-17, plan114, plan106-eligibility, Phase175 release hold]
actuals:
  tokens: 14500
  tasks: 3
  commits: 1
tech-stack:
  added: []
  patterns: [same-credential identity check and dry-run, closed role projection, versioned scope compatibility]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-113-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan105-043375a9084a4e0d4d5a4031dcbb7942-read-scope.json
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/.continue-here.md
key-decisions:
  - "Plan111 stays terminal UNKNOWN; its discarded response cannot be reconstructed."
  - "Only admin, write, or maintain plus a matching authenticated identity can prove push permission; read, triage, and none are denied."
  - "The new exact scope is pending and unapproved; a separate decision is required before checking a credential or contacting GitHub."
patterns-established:
  - "Scope v2 adds the authenticated-user and collaborator-permission routes while preserving v1 evidence inspection."
  - "Credentials stay in memory and are passed to the dry-run through the process environment, never argv or evidence."
requirements-completed: []
coverage:
  - id: D1
    description: "The collector and coordinator accept only a matching identity, a write-capable role, the same dry-run credential, and complete operation counts."
    requirement: REL-17
    verification:
      - kind: unit
        ref: script/release_candidate/plan105_mirror_tag_collector.test.mjs#authenticated permission and dry run use the same in-memory credential
        status: pass
      - kind: unit
        ref: test/crosswake/release_candidate/plan105_mirror_tag_test.exs#authenticated write role and identity are required in the ready receipt
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact authenticated-route scope is pending with zero read intent and zero operations."
    requirement: REL-13
    verification:
      - kind: other
        ref: "mix crosswake.release.mirror_tag_026 --mode plan105-inspect --attempt-id 043375a9084a4e0d4d5a4031dcbb7942 --expect pending"
        status: pass
    human_judgment: false
duration: 25m
completed: 2026-10-09
status: complete
---

# Phase 175 Plan 113: Authenticated Permission Scope Summary

**Plan113 adds a fake-verified way to check the current account's mirror role and prepares one fresh scope for a later, separately approved read.**

## Performance

- **Duration:** About 25 minutes
- **Started:** Approximately 2026-10-09T13:17:20Z
- **Completed:** 2026-10-09T13:46:00Z
- **Tasks:** 3
- **Files modified:** 13, including handoff corrections and scope evidence

## Accomplishments

- Added a version 2 scope that lists `GET /user` and a collaborator-permission route template with no account name. Version 1 scopes and Plan111 evidence remain inspectable.
- Added a bounded fake path that compares the `/user` identity with the permission response, maps documented roles, and uses the same in-memory credential for the Git dry-run. Only normalized role and identity-match values can enter the receipt.
- Verified admin/write/maintain as write-capable, read/triage/none as denied, and unknown or mismatched identity, malformed response, missing credential, and interrupted dry-run as not ready.
- Prepared attempt `043375a9084a4e0d4d5a4031dcbb7942` with scope SHA-256 `92d9124322274a9d2ae3dcc772e2bf86dccde3bd77c1498bc9f8c8f26c05bc03` and collector SHA-256 `c0eacb95396b32b8b5212596b623a6f9e377cff0b19316e0813b844662483387`. Independent offline inspection reports `PENDING`, zero read intent, zero API/Git/credential/permission/dry-run/tag operations, and no authorization.
- Re-inspected Plan111 attempt `10ed7062676ab17b00df4266b5a694f4` using the existing offline inspector. It remains terminal `UNKNOWN / OBSERVATION_UNAVAILABLE` at `MIRROR_REPOSITORY / SHAPE / INVALID_SHAPE`; no old evidence changed.

The red tests failed before implementation as expected: the Node fake never called its credential provider, and the Elixir coordinator rejected role/identity facts. After implementation, the focused Node suite passed 45 tests and the Plan105 ExUnit suite passed 19 tests. Elixir formatting, Node syntax, and scoped diff checks passed.

No credential helper was inspected or invoked. No GitHub request, Git remote command, tag operation, CI run, merge, or release action occurred. The real configured credential path is intentionally noninteractive; `osxkeychain` is declined because it may open a system prompt when locked.

Attempt ID: 043375a9084a4e0d4d5a4031dcbb7942
Scope SHA-256: 92d9124322274a9d2ae3dcc772e2bf86dccde3bd77c1498bc9f8c8f26c05bc03
Collector SHA-256: c0eacb95396b32b8b5212596b623a6f9e377cff0b19316e0813b844662483387

## Task Commits

1. **Tasks 1–2: authenticated permission path and fake coverage** — `6790a63e` (`feat`). The shared code/test contract was kept in one scoped commit.

Planning-document commits are disabled by the Phase175 workstream configuration, so the Plan113 summary and handoff updates remain in the working tree.

## Files Created/Modified

- `script/release_candidate/plan105_mirror_tag_collector.mjs` — bounded authenticated user and role lookup, safe projection, and same-credential dry-run setup.
- `script/release_candidate/plan105_mirror_tag_collector.test.mjs` — fake role, identity, privacy, count, and no-ready cases.
- `lib/crosswake/release_candidate/plan105_mirror_tag.ex` — version 2 scope/readiness validation with version 1 compatibility.
- `test/crosswake/release_candidate/plan105_mirror_tag_test.exs` — coordinator readiness and identity checks.
- `evidence/175-plan105-043375a9084a4e0d4d5a4031dcbb7942-read-scope.json` and its lifecycle — pending scope only.
- `STATE.md`, `ROADMAP.md`, and `.continue-here.md` — one active handoff to Wave20.

## Decisions Made

- Plan111's exact provider response is unavailable. This new authenticated method is supported by GitHub's documented endpoints, but no current permission fact is known until Plan114 receives its own exact decision and runs.
- `admin`, `write`, and `maintain` can prove write permission only when the authenticated identity matches. `read`, `triage`, and `none` are explicit denials; unrecognized or incomplete information remains unknown.
- A helper that may prompt or unlock is not used by the unattended path. In particular, the macOS Keychain helper is declined before any provider request.
- Plan106 remains held until a fresh complete `PREFLIGHT_READY` receipt is independently inspected; its tag action still needs a separate exact ALLOW.

## Deviations from Plan

1. Fresh GSD initialization found Plan113 and Plan112 both assigned threat ID `T-175-176`. Plan113's row was changed to the next free ID, `T-175-183`; a fresh initialization then reported no duplicate threat IDs.
2. The plan's final handoff check said to leave Plan113/Wave19 as the next command. Once Plan113 completed, that would repeat completed work. The completed-plan handoff now names Plan114/Wave20 and its fresh exact-decision checkpoint.
3. The pre-existing `.continue-here.md` still described Plan107 and a stale full-suite failure. Its current section was replaced with the Plan113 result; older sections remain as history.

**Total deviations:** 3 small corrections to prevent stale or conflicting handoffs.

## Issues Encountered

The normal scoped commit first failed because the sandbox could not write `.git/index.lock`. The exact four source/test files were then committed with the required narrow Git write access. No unrelated dirty file was staged.

## User Setup Required

None for this local plan. Plan114 must stop safely if the existing credential helper is unavailable or would prompt.

## Next Phase Readiness

Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE. Plan113 is complete in Wave19. The exact pending scope for Plan114 is attempt `043375a9084a4e0d4d5a4031dcbb7942`, digest `92d9124322274a9d2ae3dcc772e2bf86dccde3bd77c1498bc9f8c8f26c05bc03`. It has not been approved or run. The next command is `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 20 --interactive`; its first task asks for a new decision bound to this exact attempt and digest. Do not reuse the ALLOW from Plan111. Plan106 remains held. REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 and 89 remain held.

*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-09*
