---
phase: 168-0-2-1-release-candidate-readiness
plan: "05"
subsystem: release-candidate-mirror
tags: [elixir, git, swiftpm, mirror, atomic-push, tdd]
requires:
  - phase: 168-04
    provides: Candidate companion clean-room proof and the publication-gated exact-public contract
provides:
  - Credential-free immutable 0.2.0 mirror baseline inspection
  - Exact-SHA 0.2.1 candidate rehearsal with bounded authorization and porcelain evidence
  - Ordinary atomic fast-forward publication isolated from exact-ref recovery
affects: [168-release-workflow, 168-exact-candidate-capture, ios-mirror-recovery]
actuals:
  tokens: 10876
  tasks: 2
  commits: 5
plan_head_before: c236c7238e37db5d7078b84bfc65786ca2c217b2
tech-stack:
  added: []
  patterns: [closed-mirror-modes, bounded-git-observations, atomic-ordinary-publication, exact-ref-recovery]
key-files:
  created:
    - lib/crosswake/release_candidate/mirror.ex
    - script/release_candidate/ios_mirror.sh
    - test/crosswake/release_candidate/mirror_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-05-task1-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-05-task2-red.json
  modified:
    - script/verify_ios_mirror_backfill.sh
key-decisions:
  - "Model baseline, candidate rehearsal, ordinary publication, and recovery as four closed modes with mode-specific input shapes and operations."
  - "Permit normal publication only from immediate fresh refs, ancestor/equal main, immutable candidate tag, proven write authority, and an atomic porcelain rehearsal."
  - "Construct force-with-lease only in recovery after a distinct receipt digest and exact expected old/new refs; readiness cannot reach publication or recovery."
patterns-established:
  - "Mirror decisions are pure Elixir evaluations over bounded observations; the shell adapter gathers Git evidence and executes only an explicitly selected mode."
  - "Read-only modes always report external_state_changed=false, while applied fixture publication must report the freshly fetched resulting refs and changed=true."
requirements-completed: []
requirements-addressed: [REL-02, REL-04]
coverage:
  - id: immutable-mirror-baseline-and-candidate-rehearsal
    description: Public 0.2.0 mirror truth is inspected without credentials, while a 0.2.1 candidate requires exact split, write authority, atomic porcelain success, and unchanged refs.
    requirement: REL-04
    verification:
      - kind: integration
        ref: "script/release_candidate/ios_mirror.sh baseline against the public mirror, followed by credential-free candidate mode"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/mirror_test.exs"
        status: pass
    human_judgment: false
  - id: ordinary-publication-and-recovery-separation
    description: Ordinary publication is immutable, fast-forward/equal, and atomic; only separately approved recovery can form exact-ref force-with-lease arguments.
    requirement: REL-02
    verification:
      - kind: integration
        ref: "local bare-mirror publication fixture in test/crosswake/release_candidate/mirror_test.exs"
        status: pass
      - kind: unit
        ref: "publish/recovery hostile matrix in test/crosswake/release_candidate/mirror_test.exs"
        status: pass
    human_judgment: false
duration: 26m
completed: 2026-09-13
status: complete
---

# Phase 168 Plan 05: iOS Mirror Authority and Recovery Summary

**Four fail-closed mirror modes now prove the public baseline and candidate write authority while keeping atomic ordinary publication structurally separate from exact-ref recovery.**

## Performance

- **Duration:** 26m
- **Started:** 2026-09-13T03:56:40Z
- **Completed:** 2026-09-13T04:21:52Z
- **Tasks:** 2
- **Files modified:** 6
- **Commits:** 5 measured from `c236c7238e37db5d7078b84bfc65786ca2c217b2`

## Accomplishments

- Added a closed mirror evaluator and adapter for credential-free baseline inspection, credentialed candidate rehearsal, ordinary atomic publication, and separately approved recovery.
- Proved the live public `main` and `v0.2.0` baseline both resolve to `658d60253c58b7e0aedb576f16f40766fa677f23` without loading credentials or changing external state.
- Exercised candidate mode without credentials and received the exact fail-closed diagnostic `WRITE AUTHORITY NOT CHECKED`, with the freshly computed subtree split and unchanged public refs.
- Executed ordinary publication only against an invocation-owned local bare mirror: main and `v0.2.1` advanced atomically, `v0.2.0` remained immutable, and the final bounded result reported the observed new refs.
- Kept force-with-lease construction exclusive to recovery with a separate receipt digest and exact old/new bindings; no real mirror ref, package, or tag was published or changed.

## Task Commits

1. **Task 1 RED: immutable baseline and candidate rehearsal contract** — `406fd046`
2. **Task 1 contract correction: retain detected mutation truth** — `d94c414f`
3. **Task 1 GREEN: baseline and candidate authority** — `0f4edc3d`
4. **Task 2 RED: publication and recovery separation contract** — `803f44ea`
5. **Task 2 GREEN: constrained publication and exact-ref recovery** — `7af4387e`

## Evidence and Verification

- `mix test test/crosswake/release_candidate/mirror_test.exs` passed 9 tests with zero failures.
- `mix test test/crosswake/release_candidate` passed 32 tests with zero failures.
- `mix compile --warnings-as-errors`, both shell syntax checks, formatting, and `git diff --check` passed.
- The credential-free public baseline returned `PASS`, `authorization_checked=false`, `authorization_result=NOT CHECKED`, and `external_state_changed=false` for the recorded 0.2.0 split.
- The credential-free candidate probe returned `BLOCKED`, the exact correction `WRITE AUTHORITY NOT CHECKED`, and `external_state_changed=false`; this is the required honest local outcome, not an authorization success.
- The local bare-mirror fixture exercised the actual ordinary atomic push using only fixture-owned refs. No public mirror or package registry write was attempted.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
|------|-----|-------|----------|--------|
| Immutable baseline and candidate rehearsal | `406fd046` | `0f4edc3d` | contract correction `d94c414f` before GREEN | Pass |
| Ordinary publication and exact-ref recovery | `803f44ea` | `7af4387e` | included in GREEN | Pass |

Both intentional RED records were validated by `gsd_run check tdd-red-evidence` before implementation. The final focused and release-candidate suites pass from the committed implementation.

## Decisions Made

- Baseline is permanently credential-free and pinned to the already-recorded 0.2.0 source tag and split; candidate is a distinct exact-commit dry-run and cannot pass when write authority is unavailable.
- A successful ordinary publication requires a fresh expected-old ref, ancestor/equal main, an absent-or-identical immutable candidate tag, atomic capability, proven authorization, and exact after-state verification.
- Recovery updates only mirror main, preserves tags, and requires its own approval state, receipt digest, and exact old/new refs before forming force-with-lease arguments.
- The Phase 168 readiness Mix task remains unable to invoke either mutation mode.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Preserved observed external mutation state instead of normalizing it away**
- **Found during:** Task 1 RED contract review
- **Issue:** A hostile observation with changed before/after refs could have been reported with `external_state_changed=false`, undermining the fail-closed evidence boundary.
- **Fix:** Derive the emitted flag from both the supplied observation and before/after ref inequality, and added a regression assertion before GREEN implementation.
- **Files modified:** `lib/crosswake/release_candidate/mirror.ex`, `test/crosswake/release_candidate/mirror_test.exs`
- **Verification:** Focused hostile baseline and candidate cases block while retaining `external_state_changed=true`.
- **Committed in:** `d94c414f`, `0f4edc3d`

**Total deviations:** 1 auto-fixed (1 Rule 2 critical correctness fix).
**Impact on plan:** The adjustment strengthens the planned truthfulness boundary without expanding publication, credential, platform, or product scope.

### AGENTS.md-driven adjustments

- `REL-02` and `REL-04` remain pending in `REQUIREMENTS.md`. This plan establishes mirror authority and mutation semantics, but Plan 168-06 still owns workflow/scanner integration and later plans own final exact-candidate evidence.

## Issues Encountered

- Historical Phase 145/153 proof tests and the current workflow-integrity scanner still encode the superseded combined verify/apply/force mirror contract. Their migration is intentionally owned by Plan 168-06 alongside the workflow entry points; this plan's closed evaluator, adapter suite, live read-only probes, and release-candidate suite are green.

## Known Stubs

None. Public publication and recovery are deliberately approval-gated modes, not placeholder success paths.

## Threat Review

- T-168-13 is mitigated by explicit authorization state, bounded porcelain parsing, read-only credential-free baseline behavior, denied/unparseable fixtures, and no credential material in output.
- T-168-14 is mitigated by fresh before/action ref reads, ancestor/equal normal main, immutable tags, atomic ordinary pushes, race rejection, and verified after-state.
- T-168-15 is mitigated by a separate recovery input shape, distinct approval state and digest, exact old/new bindings, and exclusive force-with-lease construction.
- No unplanned network endpoint, authentication route, schema, or application trust boundary was introduced.

## User Setup Required

None. The bounded live verification intentionally used no credentials and made no remote changes.

## Next Phase Readiness

Plan 168-06 can wire the four-mode adapter into the release workflow and migrate the integrity scanner from the historical combined mirror contract. Candidate rehearsal remains fail closed until the trusted workflow supplies the scoped mirror credential.

## Self-Check: PASSED

All six declared implementation/test/evidence artifacts exist, all five measured task commits are reachable, the final release-candidate suite passes, and both required live read-only probes produced the expected fail-closed state without a remote mutation.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-13*
