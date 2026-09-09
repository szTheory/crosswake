---
phase: 165-efficient-and-maintainable-ci
plan: 13
subsystem: ci
tags: [github-actions, evidence, source-provenance, branch-protection]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 12
    provides: Compatibility-free graph landed with strict Crosswake CI authority
provides:
  - Exact-SHA final workflow and manifest provenance
  - Privacy-safe final CI observations with closed unavailable metrics
  - Reproducible descriptive comparison without causal overclaim
affects: [phase-165-verification, release-readiness, ci-evidence]
actuals:
  tokens: 9937
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Bind final live evidence to an orchestrator-supplied immutable remote-default SHA
    - Treat unmatched cohorts and unexposed API metrics as closed non-results
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/final-remote-default-source.json
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/after.json
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/comparison.md
  modified:
    - scripts/ci_monitor.cjs
    - test/crosswake/proof/phase165_evidence_test.exs
key-decisions:
  - "Reject final evidence unless the exact supplied SHA remains the remote default tip and both authoritative blobs match locally."
  - "Report the pre/post main-bound cohort as not_measured because its explicit criteria differ, despite retaining each sanitized observation descriptively."
patterns-established:
  - "Final-source boundary: remote tip, exact blob digests, graph structure, and branch protection must all pass before collection."
  - "Evidence honesty: unavailable PR cohorts, cache outcomes, and exact queue timing stay explicitly closed rather than inferred."
requirements-completed: [CIP-02, CIP-06, CIP-07]
coverage:
  - id: D1
    description: Exact landed compatibility-free source is digest-bound and protected by exactly Crosswake CI.
    requirement: CIP-02
    verification:
      - kind: integration
        ref: node scripts/ci_monitor.cjs verify-final-remote-default-source --source evidence/final-remote-default-source.json
        status: pass
      - kind: integration
        ref: script/check_required_checks_registered.sh --policy script/required_check_policy.json --state target --live
        status: pass
    human_judgment: false
  - id: D2
    description: Final evidence is sanitized, canonical, and candid about unavailable comparisons and API fields.
    requirement: CIP-06
    verification:
      - kind: unit
        ref: mix test test/crosswake/proof/phase165_evidence_test.exs
        status: pass
      - kind: integration
        ref: node scripts/ci_monitor.cjs test-evidence
        status: pass
    human_judgment: false
  - id: D3
    description: The complete recurring Phase 165 graph and live target authority remain green after evidence capture.
    requirement: CIP-07
    verification:
      - kind: integration
        ref: script/check_phase165_efficient_ci.sh
        status: pass
    human_judgment: false
duration: 51 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 13: Final Landed Evidence Summary

**Exact landed CI source provenance and privacy-safe observations now close Phase 165 without claiming an unsupported efficiency improvement.**

## Performance

- **Duration:** 51 min
- **Started:** 2026-09-09T01:07:12Z
- **Completed:** 2026-09-09T01:58:40Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Rebound the final record after the credential-boundary fix to remote-default SHA `71732ad4393de60a99cc2fec7316c0651ae6e96b`, with exact matching workflow and manifest digests and no compatibility authority.
- Proved live target protection remains strict and requires exactly `Crosswake CI` before and after collection.
- Proved the pull-request workflow contains no repository secret expressions or named release/recovery credentials while retaining all 44 proof leaves.
- Captured one sanitized main-bound automation observation; exact-SHA documentation-only and executable PR cohorts were unavailable and remain `not_measured`.
- Generated a reproducible comparison containing workflow/job/check counts, runner classes, timing medians/ranges, closed cache outcomes, and explicit `not_exposed` queue timing.

## Task Commits

1. **Task 1 RED: define final source evidence contract** — `742436f5`
2. **Task 1 GREEN: bind final evidence to landed source** — `32da4858`
3. **Task 2 RED: require honest matched comparison** — `6b87e7a8`
4. **Task 2 GREEN: capture honest final CI evidence** — `9dfde452`
5. **Security rebind: recapture final evidence after credential-boundary fix** — `2a7d82d6`

## Files Created/Modified

- `scripts/ci_monitor.cjs` — Verifies final source provenance, captures exact-SHA observations, and renders the closed comparison.
- `test/crosswake/proof/phase165_evidence_test.exs` — Enforces the final source schema and comparison honesty contract.
- `evidence/final-remote-default-source.json` — Stores only the exact SHA, branch, two blob digests, verification time, and source command.
- `evidence/after.json` — Stores allowlisted final observations and closed unavailable cohorts.
- `evidence/comparison.md` — Describes both evidence snapshots without thresholds or causal conclusions.

## Decisions Made

- Required current-tip equality and exact remote/local workflow and manifest digests on every source re-verification.
- Kept the main-bound before/after comparison `not_measured` because its explicit pre/post criteria are not identical; the individual observations remain descriptive.
- Left PR cohorts, cache outcomes, and per-job queue time closed as `not_measured` or `not_exposed` rather than manufacturing substitutes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected named comparison output handling**

- **Found during:** Task 2 verification
- **Issue:** The legacy positional parser treated the literal `--output` flag as the destination filename.
- **Fix:** Added named-option parsing while preserving the existing positional form.
- **Files modified:** `scripts/ci_monitor.cjs`
- **Verification:** The plan's exact `compare-evidence ... --output evidence/comparison.md` command generated the intended file and the full evidence suite passed.
- **Committed in:** `9dfde452`

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The fix was required for the specified reproducible output command and did not expand scope.

## Issues Encountered

- An initial manual digest spot-check used ambiguous zsh `$name:suffix` expansion. Re-running with braced expansion proved both blobs match exactly; the production verifier passes SHA and path as separate process arguments and is unaffected.
- The final exact SHA has no qualifying documentation-only or executable PR runs. Those cohorts remain closed as unavailable.
- Security review required a new landed source after removing repository credentials from pull-request Hex dry-run proof. The evidence was rebound rather than treating the earlier source record as final.

## Known Stubs

None. `not_measured` and `not_exposed` entries are intentional evidence results, not placeholders.

## Threat Flags

None. T-165-15 and T-165-04 pass exact source/graph/protection verification; T-165-07 passes the closed allowlist and forbidden-field fixtures.

## User Setup Required

None.

## Next Phase Readiness

- Phase 165 is ready for aggregate verification and closeout.
- The comparison supports no causal efficiency claim; future matched cohorts may extend evidence only under the same exact-source and privacy boundary.

## Self-Check: PASSED

- All five plan files exist.
- Commits `742436f5`, `32da4858`, `6b87e7a8`, `9dfde452`, and `2a7d82d6` exist.
- Exact-source verification, 34 focused evidence/integrity tests, the recurring Phase 165 gate, credential-free PR workflow scan, and live strict target protection pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
