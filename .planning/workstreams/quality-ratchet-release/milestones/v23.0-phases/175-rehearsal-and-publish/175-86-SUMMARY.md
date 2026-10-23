---
phase: 175-rehearsal-and-publish
plan: 86
subsystem: release-candidate
tags: [elixir, bounded-process, diagnostic-artifact, offline-inspection]
requires:
  - phase: 175-85
    provides: Local bounded collector process contract and Plan84 separation baseline
provides:
  - Closed Plan86 diagnostic records for verified production preflight process failures
  - Exclusive Plan86 artifact/lifecycle writer and repeatable offline inspector
  - Local process, privacy, immutability, and release-hold regressions
affects: [REL-13, REL-17, Phase175]
actuals:
  tokens: 9680
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 11e73a7a73f5de97936b7fef313b3704baedf32f
plan_head_after: a937623e156d4782541b7bd1eb25ecab0030b6bf
tech-stack:
  added: []
  patterns: [closed process-failure projection, exclusive artifact reservation, read-only offline inspection]
key-files:
  created:
    - lib/crosswake/release_candidate/plan86_production_diagnostic.ex
    - test/crosswake/release_candidate/plan86_production_diagnostic_test.exs
  modified:
    - lib/crosswake/release_candidate/ios_mirror_tag_repair.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
key-decisions:
  - "Persist only process stages and envelope facts that were directly observed at the bounded collector boundary."
  - "Keep Plan86 evidence separate and terminal UNKNOWN; retain an exact request count only from a complete validated child failure result."
requirements-completed: []
coverage:
  - id: D1
    description: "Observed production preflight process failures produce closed Plan86 UNKNOWN diagnostics without changing the existing generic error result."
    requirement: REL-13
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan86_production_diagnostic_test.exs --max-cases 1 (14 passed, 0 skipped)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exclusive artifact/lifecycle pair is privacy-safe, digest-validated, repeatably inspectable offline, and preserves release holds."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "Plan86 diagnostic suite: local fault matrix, tamper/reuse, privacy, and read-only inspection regressions (14 passed, 0 skipped)"
        status: pass
      - kind: integration
        ref: "Plan84 regression suite (46 passed, 0 skipped) and Plan85 local twin suite (21 passed, 0 skipped)"
        status: pass
    human_judgment: false
metrics:
  duration: 14min
  completed: 2026-10-06
  status: complete
---

# Phase 175 Plan 86: Production Collector Diagnostic Summary

**The bounded production preflight now preserves verified process-failure classes in an exclusive, privacy-safe Plan86 UNKNOWN artifact with a read-only offline inspector.**

## Performance

- **Duration:** 14 minutes
- **Started:** 2026-10-06T22:14:53Z
- **Completed:** 2026-10-06T22:28:43Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- The existing `preflight` collector preserves its generic `{:error, :collector_unavailable}` result while recording observed Port startup, timeout, nonzero exit, output-limit, envelope, child-process, child-result, and collector-reported failure classes before returning.
- Plan86 writes one fresh-attempt artifact and ordered lifecycle pair on exclusive paths. Its canonical digest covers an exact schema, fixed UNKNOWN status and held posture, bounded process facts, and either a validated bounded request count or `null` with `request_count_unknown=true`.
- The `plan86-inspect` Mix mode accepts only root and JSON output options. It validates the artifact and lifecycle without writing, so repeated inspection leaves both files byte-identical.
- Local regressions cover the unavailable-executable tracer, child and Port process faults, exact and unknown request counts, tampering, duplicate/path reuse, privacy sentinels, Plan84 byte preservation, and release holds.
- No provider request, credential lookup, Plan84 replay, preflight, dry-run, decision, tag, CI, merge, registry, publication, or release mutation ran. No Plan86 workstream evidence pair was created.

## TDD Gate Compliance

- **Task 1 RED:** The TAP report recorded the target tracer failing because no Plan86 artifact existed after the observed `preflight` Port startup failure. `gsd_run check tdd-red-evidence` returned `RED_EVIDENCE_OK`; semantic inspection confirmed the planned artifact-existence assertion failed, with no setup or load failure.
- **Task 1 GREEN:** Commit `bf77266d` added the closed diagnostic projection and exclusive writer. The focused suite passed 3 tests with no skips.
- **Task 2 RED:** The TAP report recorded the child nonzero-exit target failing because the bounded collector returned its envelope without producing the separate diagnostic. The evidence classifier returned `RED_EVIDENCE_OK`; the remaining failures were on the planned class, count, and inspector contracts.
- **Task 2 boundary RED:** A later TAP report showed that the child timeout envelope (`exit_observed=true`, `exit_status=null`, truncated output) was incorrectly categorized as an invalid result. The targeted ExUnit output confirmed this assertion specifically.
- **Task 2 GREEN:** Commit `a937623e` maps that observed timeout boundary to `CHILD_TIMEOUT`; all local matrix and inspection assertions pass. The machine-validated RED records and temporary TAP formatter were removed after the gates completed.

## Task Commits

1. **Task 1 RED: add the production preflight tracer** — `de52a5d5` (`test(175-86): add Plan86 production diagnostic tracer`).
2. **Task 1 GREEN: persist startup diagnostics** — `bf77266d` (`feat(175-86): persist production collector startup diagnostics`).
3. **Task 2 RED: cover classes and inspection** — `8610be04` (`test(175-86): cover diagnostic classes and inspection`).
4. **Task 2 GREEN: classify failures and inspect offline** — `a937623e` (`feat(175-86): inspect closed production diagnostics`).

The measured plan range is 4 commits from `11e73a7a73f5de97936b7fef313b3704baedf32f` through `a937623e156d4782541b7bd1eb25ecab0030b6bf`. Phase 175 configuration disables planning-artifact commits, so this summary and the corresponding workstream handoff remain local.

## Files Created/Modified

- `lib/crosswake/release_candidate/plan86_production_diagnostic.ex` — closed failure projection, exact schema, exclusive artifact/lifecycle writer, canonical digest, and offline validator.
- `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex` — captures safe Port and child process facts before the existing fail-closed return.
- `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` — adds the offline-only `plan86-inspect` mode.
- `test/crosswake/release_candidate/plan86_production_diagnostic_test.exs` — 14 local tests for process classes, count confidence, privacy, tampering, reuse, inspection, and release posture.

## Decisions Made

- The diagnostic stores only allowlisted process booleans, bounded integers, closed classes, and the fixed release posture. Exception text, child bytes, stderr, argv, environment, paths, and credentials are discarded.
- The legacy Plan84 safe-failure shape remains UNKNOWN with unknown count. Exact counts are accepted only from a complete, exact-key child failure shape whose bounded count is explicitly confirmed.
- Plan86 diagnostics never reuse Plan84 attempt IDs, digests, receipt paths, or lifecycle state.
- REL-13 and REL-17 remain open because this local diagnostic closes neither fresh candidate evidence nor the shared live-release validator and mutation proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Distinguish the bounded child timeout envelope**
- **Found during:** Task 2 (failure-matrix acceptance review).
- **Issue:** A child timeout can be reported after termination with `exit_observed=true`, a null exit status, and `stdout_truncated=true`; the first classifier draft treated this observed timeout as an invalid result.
- **Fix:** Recognize that exact bounded envelope combination as `CHILD_TIMEOUT` before result validation. The request count remains unknown.
- **Files modified:** `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex`, `test/crosswake/release_candidate/plan86_production_diagnostic_test.exs`.
- **Verification:** The targeted timeout regression failed on `CHILD_RESULT_INVALID` before the correction; the final Plan86 suite passes 14 tests with no skips.
- **Committed in:** `a937623e`.

**Total deviations:** 1 auto-fixed (Rule 1). The correction is required to preserve the observed process class and count uncertainty.

## Issues Encountered

- The default ExUnit report is not a supported GSD RED-evidence format. A temporary ExUnit TAP formatter produced the actual target-test reports accepted by `gsd_run check tdd-red-evidence`; the formatter and report files were removed afterward.
- The first timeout-classification regression exposed the envelope distinction recorded above; the final focused suite passed after the correction.

## Validation Results

- `MIX_ENV=test mix test test/crosswake/release_candidate/plan86_production_diagnostic_test.exs --max-cases 1` — 14 passed, 0 failures, 0 skipped.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs --max-cases 1` — 46 passed, 0 failures, 0 skipped.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan85_local_twin_test.exs --max-cases 1` — 21 passed, 0 failures, 0 skipped.
- `mix format --check-formatted lib/crosswake/release_candidate/ios_mirror_tag_repair.ex lib/crosswake/release_candidate/plan86_production_diagnostic.ex lib/mix/tasks/crosswake.release.mirror_tag_026.ex test/crosswake/release_candidate/plan86_production_diagnostic_test.exs` — passed.
- `git diff --check` on the four plan files — passed.
- Plan84 receipt and lifecycle SHA-256 values remain `44e6980b3c84ccf8bef95129a8ac95e29e0400410569965e90c6642eb8149471` and `6a256c8cac0662bd134a67f243b7dac2c444930010d42bae81d56c0ddee7a04d`. Its status remains UNKNOWN, with one request intent, zero confirmed requests, unknown actual count, and zero dry-run, decision, tag, or CI attempts.

## Unchanged Release Posture

REL-13/14/15/17 remain OPEN; candidate readiness remains BLOCKED; merge policy remains UNKNOWN; release hold remains ACTIVE; Plans45–48 remain HELD; Phase175 remains INCOMPLETE. Plan84 remains terminal UNKNOWN/OBSERVATION_UNAVAILABLE. Plan86 creates only local diagnostic capability and grants no live or release authority.

## Next Phase Readiness

Plan86 is complete. No Phase175 plan is currently eligible: Plans45–48 remain held, and Plan86 does not supply their live candidate, authorization, or release prerequisites. Keep the phase incomplete. Reopen work only when independently verifiable current candidate facts or evidence for a materially distinct bounded observation path support a separately scoped plan and its required authorization. Do not retry consumed attempts or use generic phase advancement to bypass the workstream gate.

## Self-Check: PASSED

- The two Plan86 implementation files and the Plan86 regression test exist at their listed paths.
- All four task commits are ancestors of HEAD; none deleted tracked files.
- `gsd_run check evaluation-scope --plan "175-86" --commits-only --raw` resolved the four Plan86 commits with no unreachable or missing files.
- The final Plan86, Plan84, and Plan85 suites and named formatting check passed with zero skipped tests.
- Plan84 receipt and lifecycle fingerprints match the prior recorded values; the release posture remains held.

---
*Phase: 175-rehearsal-and-publish*
*Plan: 86*
*Completed: 2026-10-06*
