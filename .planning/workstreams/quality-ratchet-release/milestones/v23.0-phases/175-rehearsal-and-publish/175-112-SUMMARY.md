---
phase: 175-rehearsal-and-publish
plan: 112
subsystem: release-evidence
tags: [anonymous-read, mirror-permission, fail-closed]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan111's sanitized terminal UNKNOWN receipt and the repaired bounded reader
provides:
  - A closed projection for anonymous mirror repository permission metadata
  - Coordinator checks that reject UNKNOWN permission and forged readiness
  - A held Phase175 handoff that preserves Plan111 as immutable history
affects: [REL-13, REL-17, plan106-eligibility, Phase175 release hold]
actuals:
  tokens: 4858
  tasks: 3
  commits: 2
tech-stack:
  added: []
  patterns: [anonymous permission remains UNKNOWN, readiness reclassified from stored evidence]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-112-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - lib/crosswake/release_candidate/plan105_mirror_tag.ex
    - test/crosswake/release_candidate/plan105_mirror_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/STATE.md
key-decisions:
  - "Missing or anonymous true push metadata remains UNKNOWN; explicit false remains a denial."
  - "A saved PREFLIGHT_READY receipt is valid only when its facts, dry-run result, and counts still classify as ready."
  - "Plan111's discarded provider response cannot be reconstructed; this repair proves future local behavior, not the historical cause."
requirements-completed: []
coverage:
  - id: D1
    description: Anonymous repository metadata is projected without exposing raw provider fields or treating true as caller write proof.
    requirement: REL-13
    verification:
      - kind: unit
        ref: script/release_candidate/plan105_mirror_tag_collector.test.mjs#anonymous repository metadata never proves caller write permission
        status: pass
      - kind: unit
        ref: script/release_candidate/plan105_mirror_tag_collector.test.mjs#missing anonymous permission reaches only the next fake route and stays UNKNOWN
        status: pass
    human_judgment: false
  - id: D2
    description: UNKNOWN permission, incomplete permission counts, and a forged ready receipt cannot produce readiness or tag authorization.
    requirement: REL-17
    verification:
      - kind: unit
        ref: test/crosswake/release_candidate/plan105_mirror_tag_test.exs#UNKNOWN push permission remains blocked through receipt inspection and tag authorization
        status: pass
      - kind: unit
        ref: test/crosswake/release_candidate/plan105_mirror_tag_test.exs#one completed permission check cannot pass the ready count gate
        status: pass
      - kind: unit
        ref: test/crosswake/release_candidate/plan105_mirror_tag_test.exs#offline inspector rejects a forged ready receipt with UNKNOWN permission
        status: pass
    human_judgment: false
  - id: D3
    description: The terminal Plan111 summary and its four evidence files remain byte-for-byte unchanged.
    verification:
      - kind: other
        ref: sha256sum of Plan111 scope, read authorization, preflight receipt, lifecycle, and summary before and after local checks
        status: pass
    human_judgment: false
duration: 29min
completed: 2026-10-09
status: complete
---

# Phase 175 Plan 112: Anonymous Mirror Permission Summary

**Anonymous mirror metadata now stays UNKNOWN unless caller write access is independently proven, and the Elixir inspector rejects forged ready receipts.**

## Performance

- **Duration:** About 29 minutes
- **Started:** Approximately 2026-10-09T12:17:00Z
- **Completed:** 2026-10-09T12:46:07Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added a pure repository projection that keeps the fixed mirror name and clone URL checks, maps absent or anonymous `permissions.push: true` to `UNKNOWN`, maps explicit `false` to `FALSE`, and rejects malformed present metadata.
- Counts each completed repository permission projection where it occurs. The fake stops after the first projection at the next fixed ruleset route, so it records one completed check and never reaches Git, credential helpers, dry-run, or tag code.
- Added Elixir checks that keep UNKNOWN permission and incomplete counts blocked. The offline inspector and tag coordinator reject a rehashed `PREFLIGHT_READY` receipt whose permission was changed to UNKNOWN.
- Preserved Plan111's scope, authorization, receipt, lifecycle, and summary bytes. The five SHA-256 values measured before and after local verification were identical.

## Task Commits

1. **Task 1: Carry missing anonymous permission through the local reader and coordinator** — `a46dc65b` (`fix(175-112)`)
2. **Task 2: Prove malformed metadata, accounting, and historical immutability** — `9ae96c25` (`fix(175-112)`)

**Task 3:** Summary and current workstream handoff only. Planning-document commits are disabled by `phase_commit_docs.175=false`.

## Files Created/Modified

- `script/release_candidate/plan105_mirror_tag_collector.mjs` — validates the fixed repository identity and returns a closed endpoint/permission projection.
- `script/release_candidate/plan105_mirror_tag_collector.test.mjs` — covers absent, true, false, malformed, and wrong-identity metadata using fake responses.
- `lib/crosswake/release_candidate/plan105_mirror_tag.ex` — rechecks classification when inspecting or authorizing from stored preflight evidence.
- `test/crosswake/release_candidate/plan105_mirror_tag_test.exs` — proves UNKNOWN, incomplete counts, and a forged ready receipt stay blocked in a temporary root.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — updated current Phase175 status and safe-stop condition.
- `175-112-SUMMARY.md` — records local results and limits.

## Decisions Made

- Anonymous repository `permissions.push: true` does not prove that the caller can write. Missing and true remain UNKNOWN; false remains an explicit denial.
- The Elixir side independently recalculates readiness before accepting a stored ready receipt, so recomputing a digest cannot promote UNKNOWN permission.
- The Plan111 response body was not retained. The local fixture makes a missing permission field a plausible explanation for the route failure, but it does not establish that this was the historical cause.

## Deviations from Plan

None. The fake stopped before every production Git, credential, dry-run, and tag operation. No provider request, remote Git operation, current candidate observation, or release action occurred.

## Issues Encountered

- The first Elixir assertion compared the raw persisted receipt with the enriched return value from `run_preflight`; it was corrected to compare the persisted status, permission, and digest. No product-code scope changed.

## User Setup Required

None.

## Next Phase Readiness

Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE. Plan111 attempt `10ed7062676ab17b00df4266b5a694f4` remains terminal `UNKNOWN / OBSERVATION_UNAVAILABLE` at `MIRROR_REPOSITORY / SHAPE / INVALID_SHAPE`; its exact ALLOW is spent and its raw response cannot be reconstructed. This repair proves how future local code treats anonymous permission metadata; it does not establish what Plan111 received or prove current write permission.

There is no eligible GSD acquisition or execution command from this local repair. Reopen live-observation planning only when a materially distinct, independently supported way to prove mirror write permission exists, and it has its own scoped review and authorization. Plan106 remains held until a fresh, complete `PREFLIGHT_READY` receipt is independently inspected; it also requires its own exact tag ALLOW.

REL-13/14/15/17 remain OPEN; readiness is BLOCKED; write permission is UNKNOWN; tag authority is NONE; merge policy is UNKNOWN; release hold is ACTIVE; Plans45–48 and 89 remain HELD. No CI, tag, merge, registry, or publication operation occurred.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-10-09*
