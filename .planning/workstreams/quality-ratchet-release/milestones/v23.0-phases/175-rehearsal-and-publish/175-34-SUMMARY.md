---
phase: 175-rehearsal-and-publish
plan: 34
subsystem: infra
tags: [elixir, mix, release-evidence, rel-17]
requires:
  - phase: 175
    provides: existing candidate receipts, linked-release workflow, and Hex rehearsal records
provides:
  - Exact-key, source-digest-bound REL-17 evidence validation for pre-merge and post-merge stages
  - A local Mix gate and fail-closed linked-release workflow seam
  - Deterministic companion-specific receipt construction and a local receipt command
affects: [175-35, 175-36, 175-37]
actuals:
  tokens: 18000
  tasks: 3
  commits: 1
tech-stack:
  added: []
  patterns:
    - Pure validators consume explicit evidence and source bytes; adapters own I/O.
    - A passing pre-merge envelope confirms evidence readiness and does not grant publication authority.
key-files:
  created:
    - lib/crosswake/release_candidate/evidence_gate.ex
    - lib/crosswake/release_candidate/companion_receipt.ex
    - lib/mix/tasks/crosswake.release.gate.ex
    - lib/mix/tasks/crosswake.release.receipt.ex
    - script/release_candidate/require_release_evidence.sh
    - test/crosswake/release_candidate/evidence_gate_test.exs
    - test/crosswake/release_candidate/companion_receipt_test.exs
  modified:
    - .github/workflows/release-please.yml
key-decisions:
  - "Keep evidence identity bound to receipt digest, operation, and leg run ID; candidate OIDs remain subject fields."
  - "Require the post-merge envelope to carry the consumed pre-merge authorization and exact merge identity."
  - "Keep companion receipts package-scoped and separate from the six-child core rollup."
patterns-established:
  - "Each accepted REL-17 fact has a bounded relative source path, SHA-256 digest, and bytes checked by the validator."
requirements-completed: [REL-17]
coverage:
  - id: D1
    description: "REL-17 staged gate validates the six seeded conditions, blocks field mutations, and is called before linked release authority is emitted."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "test/crosswake/release_candidate/evidence_gate_test.exs#the shell seam and Mix task accept a complete seeded post-merge envelope"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/evidence_gate_test.exs#each REL-17 condition and binding blocks when its source fact is changed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Companion receipts are canonical, package-specific, and bound to same-head CI plus the exact no-mutation Hex rehearsal row."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/companion_receipt_test.exs#a package-specific same-head CI and Hex rehearsal create a deterministic canonical receipt"
        status: pass
      - kind: integration
        ref: "test/crosswake/release_candidate/companion_receipt_test.exs#the Mix task writes only a local receipt artifact and prints its digest"
        status: pass
    human_judgment: false
duration: 28 min
completed: 2026-09-26
status: complete
---

# Phase 175 Plan 34: REL-17 Evidence Contract Summary

**REL-17 now has a source-backed staged validator and package-specific companion receipts, with linked release held closed until fresh post-merge evidence is supplied.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-09-26T14:08:34Z
- **Completed:** 2026-09-26T14:36:12Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added a pure validator for six exact-key evidence conditions, the `(receipt_digest, operation, leg_run_id)` identity, and distinct pre-merge and post-merge envelopes.
- Added Mix and shell entry points; the linked-release workflow calls the gate before emitting `linked_release=true`, and missing evidence blocks.
- Added deterministic, package-scoped companion receipts with source-byte digests and a local-only Mix command.

## Task Commits

The three task outputs were committed together because they share the new gate contract and test fixture:

1. **Task 1: Gate one linked post-merge path** — `c0908662` (`feat`)
2. **Task 2: Validate staged evidence and mutations** — `c0908662` (`feat`)
3. **Task 3: Build companion-specific receipts** — `c0908662` (`feat`)

## Files Created/Modified

- `lib/crosswake/release_candidate/evidence_gate.ex` — closed staged validator over explicit facts and source bytes.
- `lib/crosswake/release_candidate/companion_receipt.ex` — canonical package-scoped receipt builder.
- `lib/mix/tasks/crosswake.release.gate.ex` and `lib/mix/tasks/crosswake.release.receipt.ex` — local evidence commands with bounded output.
- `script/release_candidate/require_release_evidence.sh` — fail-closed gate seam.
- `.github/workflows/release-please.yml` — invokes the shared seam before linked publication authority.
- `test/crosswake/release_candidate/evidence_gate_test.exs` and `test/crosswake/release_candidate/companion_receipt_test.exs` — seeded positive and mutation coverage.

## Decisions Made

- A pre-merge PASS means the evidence is ready for the separate exact decision; it is not publication permission.
- A post-merge PASS requires the consumed pre-merge authorization, the exact two-parent merge, and all three runbook ancestry checks.
- The linked workflow deliberately stays blocked until Plan 175-35 supplies fresh evidence capture.

## Deviations from Plan

The production changes and all three task test sets were grouped into one scoped plan commit rather than separate task commits. No unrelated dirty files were staged, and the implementation stayed within the plan's file list.

**Total deviations:** 1 execution packaging deviation. **Impact:** no behavior or scope change; all planned checks passed.

## Issues Encountered

The initial RED run confirmed the new validator was missing. Implementation then passed the staged-envelope and receipt tests. A formatting check identified one line in the receipt Mix task; it was corrected before closeout.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 175-35 can add fresh GitHub, Git, and Hex capture at the authorization and side-effect boundaries. REL-17 remains open, and no release or publication authority was created by this plan.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-26*
