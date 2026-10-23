---
phase: 175-rehearsal-and-publish
plan: 91
subsystem: release-automation
tags: [elixir, node, operation-accounting, offline-inspection]

requires:
  - phase: 175
    provides: Plan87 bounded coordinator and collector, Plan90 versioned GET-only read scope
provides:
  - Contract-bound, durable API/Git and parent-process operation journals
  - Offline inspection that recomputes exact accounting or retains UNKNOWN
  - Sanitized accounting and fresh-scope next action in Mix output
affects: [175-88, 175-89, release-evidence]

actuals:
  tokens: 16797
  tasks: 3
  commits: 6
commits: 6
plan_head_before: 0b54deb2dcdeb64442a927033ba002ff7f202bff
plan_head_after: f86b278202eb141d9fe64a228a30ce9eaa01e965

tech-stack:
  added: []
  patterns: [bounded fsynced JSONL journals, exact-or-UNKNOWN accounting]
key-files:
  created: []
  modified:
    - script/release_candidate/plan87_read_scope_contract.json
    - lib/crosswake/release_candidate/plan87_mirror_tag.ex
    - lib/crosswake/release_candidate/plan87_mirror_tag_evidence.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/plan87_mirror_ref.mjs
    - test/crosswake/release_candidate/plan87_mirror_tag_test.exs
    - script/release_candidate/plan87_mirror_ref.test.mjs
key-decisions:
  - "Version the read contract and bind both journals to the exact attempt, scope digest, and contract digest; old Plan88 authorization is ineligible."
  - "Derive local counts only from validated invocation events; incomplete process or child sequences keep the upper bound UNKNOWN and remote delivery/receipt UNKNOWN."
  - "Keep all tests fake-driven and temporary-root-only; release readiness and requirement states remain held/open."
patterns-established:
  - "Journal every observed boundary with a closed event shape, ordered sequence, bounded bytes, and fsync."
  - "Offline inspection recomputes journal digests and accounting before accepting sealed evidence."
requirements-completed: []

duration: 13min
completed: 2026-10-07
status: complete
---

# Phase 175 Plan 91: Scoped Operation Accounting Summary

The Plan87 read contract now seals bounded local API, Git, and parent-process accounting that offline inspection independently recomputes while preserving UNKNOWN at every unobserved boundary.

## Performance

- **Duration:** approximately 13 minutes
- **Started:** 2026-10-07T02:31:00Z
- **Completed:** 2026-10-07T02:44:14Z
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- Bound the new accounting schema into the Plan87 read contract and refreshed the Elixir and Node byte-hash pins. The existing Plan88 scope and ALLOW no longer validate under this contract.
- Added exclusive attempt/scope-derived parent and child journals with ordered closed events, byte/event bounds, append-and-fsync records, and distinct API/Git failure classifications.
- Made offline inspection reject missing, malformed, reordered, mismatched, or changed journals and recompute their digests and counts. An interrupted process remains UNKNOWN; local fetch invocation never implies provider receipt.
- Added sanitized text/JSON accounting output and a fixed next action to plan a fresh exclusive scope and authorization.
- Kept all fakes and journals in temporary roots. The evidence directory remained byte-identical across all 138 sampled files, including Plan84 evidence and the old Plan88 scope/lifecycle.

## Task Commits

1. **Task 1: Seal one fake scoped read with durable operation accounting** — 36a17212 (RED), a77db585 (GREEN)
2. **Task 2: Account for every observable API and Git failure boundary** — f7583b98 (RED), 24d2c2d9 (GREEN)
3. **Task 3: Validate accounting during inspection and keep output safe** — 71a80579 (RED), f86b2782 (GREEN)

**Plan metadata:** Not committed; phase_commit_docs.175=false.

## Files Created/Modified

- script/release_candidate/plan87_read_scope_contract.json — versioned accounting contract.
- lib/crosswake/release_candidate/plan87_mirror_tag.ex — journals, boundary handling, strict parsing, recomputation, and inspection.
- lib/crosswake/release_candidate/plan87_mirror_tag_evidence.ex — closed attempt/scope/contract-bound accounting summary.
- lib/mix/tasks/crosswake.release.mirror_tag_026.ex — sanitized accounting and next-action output.
- script/release_candidate/plan87_mirror_ref.mjs — durable child API/Git event recording.
- test/crosswake/release_candidate/plan87_mirror_tag_test.exs — fake coordinator, tamper rejection, and interrupted-operation coverage.
- script/release_candidate/plan87_mirror_ref.test.mjs — fake API/Git success and failure-boundary coverage.

## Decisions Made

- The new shared contract intentionally invalidates Plan88's prior ALLOW. A future read needs a separately planned path set, new attempt, and new exact authorization.
- Empty journals are created for each prepared temporary attempt so an absent journal cannot be mistaken for an exact zero-operation result.
- API/Git failure classes retain only locally observed states. Delivery, provider receipt, release readiness, and merge policy remain UNKNOWN/BLOCKED as specified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical validation] Require both journal files and reject incomplete pending attempts**
- **Found during:** Task 3
- **Issue:** Treating absent journals as empty could manufacture an exact zero count; pending inspection also needed to reject any unexpected operation record.
- **Fix:** Create exclusive empty journals during scope preparation, require regular bounded files, and accept pending inspection only while both remain empty.
- **Files modified:** lib/crosswake/release_candidate/plan87_mirror_tag.ex
- **Commit:** f86b2782

## Verification

- MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1 — 17 passed, 0 skipped.
- node --check script/release_candidate/plan87_mirror_ref.mjs — passed.
- node --test script/release_candidate/plan87_mirror_ref.test.mjs — 17 passed, 0 skipped.
- Plan84–86 regression suite — 81 passed, 0 skipped.
- Named mix format --check-formatted and scoped git diff --check — passed.
- SHA-256 and file-set comparison against the 138-file evidence baseline — identical; Plan84 and Plan88 scope/lifecycle hashes unchanged.
- No provider, credential lookup, remote Git, CI, tag/ref, merge, registry, or release operation was invoked.

## Release Posture and Next Action

Last completed phase remains 174; Phase175 remains incomplete. REL-13/14/15/17 remain OPEN, candidate readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, and Plans45–48 HELD. Plans88 and 89 were not executed. The current phase index still lists stale Plan88 as ready; do not replay it or run Wave 3. The next GSD action is $gsd-plan-phase 175 --ws quality-ratchet-release to plan a fresh exclusive read path and attempt and route the scheduler around the stale Plan88/89 sequence. Any future read still requires a new exact ALLOW after that plan.

## Self-Check: PASSED

- All seven declared implementation paths are present and scoped to Plan91.
- All six task commits are ancestors of f86b2782.
- No Plan84/Plan88 evidence changed, and no generated files were left in the real evidence directory.
- No new stub patterns were found in the seven modified implementation/test paths.
