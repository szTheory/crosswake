---
phase: 165-efficient-and-maintainable-ci
plan: 10
subsystem: ci
tags: [github-actions, live-probes, cancellation, branch-protection, required-checks]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 03
    provides: Trusted requested-event strict-lower cancellation controller
  - phase: 165-efficient-and-maintainable-ci
    plan: 09
    provides: Complete Crosswake CI graph with forty-four proof leaves and one checkout-free umbrella
provides:
  - Source-bound live documentation, full-proof, emitted-name, and monotonic cancellation evidence
  - Strict dual required-check authority with Crosswake CI added beside all twenty-seven legacy contexts
  - Exact drift-bound and unapplied legacy-context retirement proposal
affects: [165-11, 165-12, 165-13, branch-protection, release-readiness]
actuals:
  tokens: 15082
  tasks: 3
  commits: 13
tech-stack:
  added: []
  patterns:
    - Immutable remote-default workflow binding before any live probe mutation
    - Green-first additive required-check migration with exact post-write audit
    - Same-PR candidate scoping before strict fail-closed cancellation selection
key-files:
  created:
    - script/required_check_policy.json
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/remote-default-source.json
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/live-observation.json
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/required-context-retirement.json
  modified:
    - scripts/ci_monitor.cjs
    - .github/workflows/cancel-obsolete-crosswake-ci.yml
    - script/select_obsolete_ci_runs.py
    - script/register_required_checks.sh
    - script/check_required_checks_registered.sh
    - test/crosswake/proof/phase165_evidence_test.exs
    - test/crosswake/proof/phase165_ci_integrity_test.exs
key-decisions:
  - "Bind every live probe to the exact orchestrator-landed remote-default SHA and exact local/remote workflow digests before creating a branch."
  - "Scope cancellation candidates to the current PR before applying strict fail-closed candidate validation, because GitHub removes PR associations from historical runs after probe cleanup."
  - "Keep strict dual authority live and leave the exact legacy retirement proposal unapplied for Plan 165-11."
patterns-established:
  - "Live proof: normalize only allowlisted source, topology, timing, cancellation, and cleanup fields; never retain actors, logs, URLs, credentials, or raw API payloads."
  - "Protection migration: validate the frozen source snapshot, unique local producers, and green observed umbrella before a one-context additive patch, then re-read exact state."
requirements-completed: [CIP-02, CIP-04, CIP-05, CIP-07]
coverage:
  - id: D1
    description: Live source-bound probes prove exact documentation-only and full-proof schedules plus the emitted Crosswake CI context
    requirement: CIP-05
    verification:
      - kind: e2e
        ref: node scripts/ci_monitor.cjs validate-evidence .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/live-observation.json
        status: pass
    human_judgment: false
  - id: D2
    description: Requested-event cancellation live proof cancels only the strict lower same-PR run and preserves the newer authority
    requirement: CIP-02
    verification:
      - kind: e2e
        ref: live-observation.json cancellation record plus python3 script/select_obsolete_ci_runs.py --self-test
        status: pass
    human_judgment: false
  - id: D3
    description: Crosswake CI is additively required under strict protection while every legacy context remains required and uniquely produced
    requirement: CIP-07
    verification:
      - kind: integration
        ref: script/check_required_checks_registered.sh --policy script/required_check_policy.json --state dual --live
        status: pass
    human_judgment: false
  - id: D4
    description: Exact legacy retirement is captured as a dry-run proposal and has not been applied
    requirement: CIP-07
    verification:
      - kind: integration
        ref: script/register_required_checks.sh --policy script/required_check_policy.json --mode retire --dry-run --output evidence/required-context-retirement.json
        status: pass
    human_judgment: false
duration: 3h 30m
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 10: Live CI Authority Migration Summary

**Exact-SHA live probes proved the complete Crosswake CI topology and monotonic cancellation, then added one strict umbrella context beside all twenty-seven legacy authorities while leaving retirement unapplied.**

## Performance

- **Duration:** 3h 30m
- **Completed:** 2026-09-08T21:58:06Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Bound live work to remote-default SHA `9107cef628fdb1952dddb22243d91a4003b6bff4` and exact Plan 09/03 workflow digests before every probe branch.
- Observed one documentation proof leaf, all forty-four full-proof leaves, the exact `Crosswake CI` umbrella display name, strict-lower cancellation, newer-run survival, and complete probe cleanup.
- Added `Crosswake CI` to strict branch protection without removing any legacy context, then generated an exact retirement proposal without applying it.

## Task Commits

1. **Task 1 RED/GREEN: live source and topology contract** — `1b0c6fe8`, `153dfb18`
2. **Task 1 live controller repairs** — `804412a6`, `037cccfc`, `9ea051df`, `8b71df43`, `e1677355`, `374e3bb0`
3. **Task 1 evidence** — `4f4544df`
4. **Task 2 RED/GREEN: additive required-check policy** — `c86dcff9`, `1e1bafa4`
5. **Task 3: unapplied retirement proposal** — `4a12d191`
6. **Overall verification repair** — `2785a795`

## Files Created/Modified

- `scripts/ci_monitor.cjs` — Verifies immutable source blobs and orchestrates bounded live probes with sanitized evidence and cleanup.
- `.github/workflows/cancel-obsolete-crosswake-ci.yml` — Uses the hosted event path and scopes candidates to the current PR.
- `script/select_obsolete_ci_runs.py` — Accepts observed pending peers as known but non-cancellable state.
- `script/required_check_policy.json` — Freezes exact legacy, dual, and target context sets.
- `script/register_required_checks.sh` — Applies exact green-first additive authority and produces dry-run retirement diffs.
- `script/check_required_checks_registered.sh` — Audits exact live dual or target state and one producer per required context.
- Phase evidence JSON — Retains only allowlisted source, probe, cancellation, protection, and cleanup truth.

## Decisions Made

- The emitted `Crosswake CI` display name is the sole new stable umbrella authority.
- Historical runs without a surviving PR association are outside the current PR candidate universe; malformed same-PR candidates still fail closed.
- Retirement remains an explicit later decision. The live state after this plan is strict dual authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced the empty projected event path with GitHub's hosted event path**
- **Found during:** Task 1 live cancellation probe
- **Issue:** `github.event_path` projected an empty value, so the controller closed as `invalid_workflow_identity`.
- **Fix:** Consume the built-in `GITHUB_EVENT_PATH` inside the trusted controller.
- **Verification:** PR #133 passed all checks; subsequent controller selection reached candidate validation.
- **Committed in:** `037cccfc`

**2. [Rule 1 - Bug] Accepted pending peers as known non-cancellable API state**
- **Found during:** Task 1 live cancellation probe
- **Issue:** GitHub returned `pending` for the newer workflow run, causing fail-closed `invalid_candidate` before inversion.
- **Fix:** Add `pending`, `requested`, and `waiting` to known states while keeping only queued/in-progress cancellable.
- **Verification:** Selector self-tests and landed PR #136 passed.
- **Committed in:** `8b71df43`

**3. [Rule 1 - Bug] Scoped candidate history to the current PR before strict validation**
- **Found during:** Task 1 live cancellation probe
- **Issue:** Closed probe PR runs lost their PR association in GitHub's API and poisoned all later controller selections.
- **Fix:** Validate complete pagination, then pass only exact current-PR runs into the fail-closed selector.
- **Verification:** Landed PR #139 passed; final live inversion cancelled the lower run and preserved the newer run.
- **Committed in:** `374e3bb0`

**4. [Rule 1 - Bug] Made exact additive registration idempotent after successful apply**
- **Found during:** Overall verification
- **Issue:** Re-running the prescribed add dry-run/apply sequence rejected the already-verified dual state.
- **Fix:** Add mode accepts only the exact frozen legacy or exact dual set and retains exact post-write equality.
- **Verification:** Prescribed Task 2 sequence passes against live dual protection.
- **Committed in:** `2785a795`

---

**Total deviations:** 4 auto-fixed Rule 1 bugs.
**Impact on plan:** Each repair was required to obtain honest live cancellation or repeatable exact-state verification; no authority or product scope expanded.

## Known Stubs

None.

## Threat Flags

None. The only new network and branch-protection surfaces were explicitly covered by T-165-02, T-165-07, and T-165-08 and passed their planned mitigations.

## User Setup Required

None. Existing authenticated repository authority was sufficient; all bounded probes and cleanup were automated.

## Next Phase Readiness

Plan 165-11 can evaluate the exact retirement proposal while live branch protection remains strict with both Crosswake CI and all legacy contexts required.

## Self-Check: PASSED

- All eleven plan files exist in their expected final state.
- All thirteen task and deviation commits exist.
- Live strict dual authority, canonical live evidence, and the unapplied retirement proposal validate after final writes.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
