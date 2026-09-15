---
phase: 166-clean-checkout-engineering-quality
plan: 08
subsystem: repository-verification
tags: [clean-checkout, exact-commit, evidence, elixir, playwright, gradle]
requires:
  - phase: 166-07
    provides: exact-commit capture tooling and a pinned Darwin/arm64 evidence environment
provides:
  - canonical privacy-safe clean-checkout evidence for the supported-code commit
  - final ownership-ledger closure and Nyquist-complete validation
  - deterministic invocation-local dependency, formatting, and host bootstrap contracts
affects: [167-documentation-and-pull-request-reconciliation, 168-release-preparation]
actuals:
  tokens: 25004
  tasks: 2
  commits: 22
tech-stack:
  added: [pinned invocation-local PyYAML, root Elixir formatter contract]
  patterns: [supported-code SHA precedes evidence-only records, invocation-owned proof roots, byte-immutable Git snapshots]
key-files:
  created:
    - .formatter.exs
    - .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json
    - .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.md
  modified:
    - script/run_repository_evidence_environment.sh
    - script/capture_repository_verification_evidence.sh
    - script/verify_repository.mjs
    - script/check_phase166_ownership_ledger.py
    - .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md
    - .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-VALIDATION.md
key-decisions:
  - "Supported-code identity is 1ddf3357973d1cfdff4f2b6140115bdb2f424fd2; later evidence and planning commits do not redefine it."
  - "Isolated proof owns pinned tools, dependency warm-up, private logs, temporary roots, and cleanup within one invocation."
  - "All five flagged assumptions and both bespoke prohibitions remain unresolved rather than being promoted by local evidence."
patterns-established:
  - "Evidence identity: commit all supported behavior first, record its SHA, then write planning-only evidence."
  - "Clean proof: inspect repository state without refreshing or mutating the caller's index."
requirements-completed: [ENG-01, ENG-02, ENG-03, ENG-04]
coverage:
  - id: D1
    description: Exact supported-code commit passes all nine isolated repository verification stages.
    requirement: ENG-01
    verification:
      - kind: integration
        ref: script/capture_repository_verification_evidence.sh --verify clean-checkout-run.json
        status: pass
    human_judgment: false
  - id: D2
    description: Ownership scope is mechanically closed and uncertainty remains retained.
    requirement: ENG-02
    verification:
      - kind: integration
        ref: script/check_phase166_ownership_ledger.py --ledger 166-ownership-ledger.md --evidence clean-checkout-run.json
        status: pass
    human_judgment: false
  - id: D3
    description: Initial and final NUL-safe Git state are empty and identical with an unchanged index and passing cleanup.
    requirement: ENG-03
    verification:
      - kind: integration
        ref: clean-checkout-run.json repository_state and cleanup
        status: pass
    human_judgment: false
  - id: D4
    description: Canonical JSON and Markdown retain only bounded privacy-safe diagnostics.
    requirement: ENG-04
    verification:
      - kind: integration
        ref: script/capture_repository_verification_evidence.sh --verify clean-checkout-run.json
        status: pass
    human_judgment: false
duration: 7h 10m
completed: 2026-09-10
status: complete
---

# Phase 166 Plan 08: Canonical Clean-Checkout Evidence Summary

**Exact-commit proof now records nine passing repository stages, byte-identical clean Git state, unchanged index state, and privacy-safe bounded evidence for supported code SHA `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2`.**

## Performance

- **Duration:** 7h 10m
- **Started:** 2026-09-09T17:03:42-04:00
- **Completed:** 2026-09-10T00:13:28-04:00
- **Tasks:** 2
- **Files modified:** 24

## Accomplishments

- Established `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2` as the immutable supported-code identity before any final evidence-only write.
- Captured and verified deterministic JSON/Markdown evidence with all nine supported stages PASS, empty and identical initial/final NUL snapshots, an unchanged index, and owned cleanup PASS.
- Reconciled the final ownership cone and Nyquist validation while preserving all five flagged assumptions and both bespoke prohibitions.

## Task Commits

Task 1 required a sequence of atomic corrections and evidence captures:

- `e580912f` — pin isolated PyYAML evidence dependency
- `897d2bde` — bootstrap example-host matrix dependencies
- `a9082974` — define bounded root formatter contract
- `1f17432a` — canonicalize dependency fixture paths
- `b9b66a8c` — warm isolated Gradle proof
- `0b7fe9c3` — seal companion verification locks
- `4465ccad` — provide symlink fixture temp directory
- `de22002d` — provision frozen Android SDK locally
- `97f7cf40` — retain capture-owned private stage logs
- `55abf04a` — serialize offline scope activation
- `30ab60d0` — keep capture index byte-immutable
- `bee6bb8c` — snapshot Git state without index refresh
- `09d2d6b0` — capture intermediate canonical clean-checkout evidence
- `f955e5e9` — bind ownership proof to canonical evidence
- `616a06f1` — prefetch companion proof dependencies
- `33aa4bb3` — skip empty activation replay
- `778ccf47` — warm both example-host environments
- `50439933` — scope example-host temp evidence
- `1ddf3357` — serialize rejected replay setup; final supported-code commit
- `bbbf6da5` — finalize canonical clean-checkout evidence

Task 2:

- `8b51616d` — reconcile final ownership evidence and validation

## Files Created/Modified

- `.formatter.exs` — minimal deterministic root formatter scope.
- `script/repository_evidence_toolchain.json` — pinned invocation-local PyYAML and evidence tools.
- `script/run_repository_evidence_environment.sh` — self-contained tool, dependency, Android, and example-host preparation.
- `script/capture_repository_verification_evidence.sh` — exact-commit capture, private-log ownership, and evidence validation.
- `script/verify_repository.mjs` — byte-immutable NUL-safe Git state and index proof.
- `script/check_phase166_ownership_ledger.py` — supported-SHA and exact evidence-only-delta enforcement.
- `evidence/clean-checkout-run.json` and `evidence/clean-checkout-run.md` — canonical machine and bounded human evidence.
- `166-ownership-ledger.md` and `166-VALIDATION.md` — final ownership and Nyquist reconciliation.

## Decisions Made

- The canonical supported-code identity stops at `1ddf3357`; evidence and planning records intentionally follow it and do not require recursive recapture.
- Dependency provisioning is pinned and invocation-local, including dev/test example-host dependencies and existing frozen Android tooling.
- Git proof uses read-only state inspection and exact owned temporary roots so it never stages, refreshes, or globally cleans caller state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Closed isolated tool and formatter prerequisites**
- **Found during:** Task 1 canonical capture
- **Issue:** Root proof depended on mutable system PyYAML, the example matrix lacked compiled dev dependencies, and no root formatter contract existed.
- **Fix:** Added a pinned invocation-local PyYAML policy, self-contained dependency bootstrap, and minimal `.formatter.exs`.
- **Committed in:** `e580912f`, `897d2bde`, `a9082974`

**2. [Rule 1 - Bug] Made clean-checkout dependencies and platform proof deterministic**
- **Found during:** Task 1 repeated isolated runs
- **Issue:** Fixture paths, Gradle/Android preparation, companion locks, and symlink fixtures were not fully isolated or prewarmed.
- **Fix:** Canonicalized paths, provisioned only the frozen Android SDK posture, sealed locks, and scoped fixture temporary storage.
- **Committed in:** `1f17432a`, `b9b66a8c`, `0b7fe9c3`, `4465ccad`, `de22002d`, `616a06f1`, `778ccf47`

**3. [Rule 1 - Bug] Preserved exact capture ownership and Git state**
- **Found during:** Task 1 capture verification
- **Issue:** Private logs could be removed before capture, state snapshots refreshed the index, and shared temporary-directory scanning was race-prone.
- **Fix:** Retained capture-owned private logs until their owner consumed them, made state inspection read-only, and assigned a canonical invocation-owned temporary root.
- **Committed in:** `97f7cf40`, `30ab60d0`, `bee6bb8c`, `50439933`

**4. [Rule 1 - Bug] Removed scoped browser replay races**
- **Found during:** Task 1 browser stage
- **Issue:** Empty activation replay and rejected replay setup could race asynchronous queue restoration.
- **Fix:** Skipped empty replay, observed queue creation, and installed the rejection mock before reconnecting.
- **Committed in:** `55abf04a`, `33aa4bb3`, `1ddf3357`

**5. [Rule 2 - Missing Critical] Bound ledger claims to canonical evidence**
- **Found during:** Task 1 evidence reconciliation
- **Issue:** The production ownership validator did not require the plan's exact evidence-only delta or supported-code SHA binding.
- **Fix:** Added closed four-path delta validation and canonical SHA/clean-gate checks.
- **Committed in:** `f955e5e9`

**Total deviations:** 5 grouped auto-fixed issues (four Rule 1/3 blocking or correctness groups, one Rule 2 evidence-integrity group).
**Impact on plan:** All changes remained reversible and Phase-166-scoped; public support boundaries, privacy rules, and the frozen Android feature posture were preserved.

## Issues Encountered

The recurring gate initially inherited no asdf selection in one shell. Rerunning it with the repository-declared Erlang 28.4.1 and Elixir 1.19.5-otp-28 environment passed; no source change was needed.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

Phase 166 is fully evidenced and ready for Phase 167 documentation and pull-request reconciliation. The parked First B2C Adopter lane remains unchanged and no release publication authority was exercised.

## Self-Check: PASSED

The summary and canonical evidence files exist, all 21 recorded plan commits resolve, and the evidence-supported SHA exactly matches `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2`.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-10*
