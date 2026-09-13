---
phase: 168-0-2-1-release-candidate-readiness
plan: "04"
subsystem: release-candidate-cleanroom
tags: [elixir, phoenix, hex, clean-room, companion-matrix, tdd]
requires:
  - phase: 168-03
    provides: Six officially unpacked candidate payloads with normalized metadata and payload digests
provides:
  - Five non-vacuous companion profiles exercised twice in independently isolated generated Phoenix hosts
  - Candidate-local proof restricted to the six built payload roots with no repository or public fallback
  - Fixture-backed exact-public package, registry-source, digest, lock-source, profile, and live-status verification
affects: [168-mirror-authority, 168-release-workflow, 168-exact-candidate-capture]
actuals:
  tokens: 15437
  tasks: 2
  commits: 6
plan_head_before: 79928fc7f1074e4b3e6d4e865c0e602f2216c44c
tech-stack:
  added: []
  patterns: [pinned-real-phoenix-generator, twice-isolated-consumer-proof, closed-five-profile-matrix, fail-closed-doctor]
key-files:
  created:
    - lib/crosswake/release_candidate/cleanroom.ex
    - test/crosswake/release_candidate/cleanroom_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-04-task1-red.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/168-04-task2-red.json
  modified:
    - script/verify_companion_cleanroom.sh
key-decisions:
  - "Generate map-shaped companion settings and one explicit managed route so the real Doctor path evaluates the intended host contract."
  - "Treat every install, compile, smoke, registration, and Doctor command as a fail-closed proof child before recording profile success."
  - "Keep exact-public verification fixture-backed and dormant until 0.2.1 publication and an approved receipt make its live precondition true."
patterns-established:
  - "Candidate clean-room proof uses exactly six unpacked built payloads, phx_new 1.8.13, five fixed profiles, and two distinct installs per profile."
  - "Public proof accepts only exact registry sources with zero path locks, approved normalized digests, the same complete profile matrix, and passing live release status."
requirements-completed: []
requirements-addressed: [REL-01, REL-04]
coverage:
  - id: candidate-local-companion-matrix
    description: Six built payloads pass five non-vacuous companion profiles across two isolated installs in real generated Phoenix hosts.
    requirement: REL-01
    verification:
      - kind: integration
        ref: "Two independent current-HEAD hex_artifacts.sh builds followed by verify_companion_cleanroom.sh candidate-local; normalized artifacts and results compared equal"
        status: pass
      - kind: unit
        ref: "test/crosswake/release_candidate/cleanroom_test.exs"
        status: pass
    human_judgment: false
  - id: exact-public-proof-contract
    description: The dormant post-publication path rejects non-registry sources, path locks, digest drift, partial availability, and ambiguous live status.
    requirement: REL-04
    verification:
      - kind: integration
        ref: "mix test test/crosswake/release_candidate/cleanroom_test.exs --only post_publication"
        status: pass
    human_judgment: false
duration: 34m
completed: 2026-09-12
status: complete
---

# Phase 168 Plan 04: Candidate Companion Clean-Room Proof Summary

**Six built package payloads now pass a real `phx_new 1.8.13` five-profile companion matrix twice from isolated state, while exact-public proof remains fail-closed and publication-gated.**

## Performance

- **Duration:** 34m
- **Started:** 2026-09-13T03:17:15Z
- **Completed:** 2026-09-13T03:50:51Z
- **Tasks:** 2
- **Files modified:** 5
- **Commits:** 6 measured from `79928fc7f1074e4b3e6d4e865c0e602f2216c44c`

## Accomplishments

- Added a closed Elixir evaluator for exactly six payloads, five ordered profiles, ten distinct install observations, non-vacuous checks, and per-profile negative controls.
- Rebuilt all six artifacts twice from exact current HEAD and completed two full real generated-host matrices. Both runs reported `package_count=6`, `profile_count=5`, `install_count=2`, `path_lock_count=0`, and PASS for every profile and negative control.
- Compared the independent builds after removing only invocation-local unpack roots; normalized artifact manifests and complete clean-room result documents were identical.
- Added the distinct exact-public mode and fixtures for exact versions, registry-backed source, approved digest equality, zero path locks, partial publication, full profile reuse, and fail-closed live release status.

## Task Commits

1. **Task 1 RED: candidate clean-room contract** — `507af4d5`
2. **Task 1 GREEN: candidate companion matrix** — `6186f66d`
3. **Task 2 RED: exact-public clean-room contract** — `98271d09`
4. **Task 2 GREEN: exact-public companion proof** — `78f0346b`
5. **Rule 1 correction: map-shaped companion settings** — `2263e4f7`
6. **Rule 1 correction: fail-closed generated-host Doctor** — `9a4f8fdd`

## Evidence and Verification

- `mix test test/crosswake/release_candidate/cleanroom_test.exs` passed 9 tests with zero failures.
- `mix test test/crosswake/release_candidate/cleanroom_test.exs --only post_publication` passed all 4 tagged tests with zero failures.
- `mix test test/crosswake/release_candidate` passed 23 tests with zero failures.
- `mix compile --warnings-as-errors`, `bash -n script/verify_companion_cleanroom.sh`, `mix format --check-formatted`, and `git diff --check` passed.
- Two independent artifact builds and complete candidate-local matrices passed from `9a4f8fdd9020a43699500ca5ffb187d5af552d3e`. Each matrix generated ten fresh Phoenix hosts, ran compile/smoke/registration/negative-control/Doctor checks, and retained no path lock.
- Independent-root, normalized-artifact-manifest, and normalized-clean-room-result equality checks all reported PASS.
- Exact-public live execution was not invoked because 0.2.1 is not published and no approved post-publication receipt exists; the fixture seam proves the path while preserving the precondition.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
|------|-----|-------|----------|--------|
| Candidate-local generated-host matrix | `507af4d5` | `6186f66d` | follow-up fixes `2263e4f7`, `9a4f8fdd` | Pass |
| Exact-public comparison mode | `98271d09` | `78f0346b` | — | Pass |

Both planned RED records preceded implementation. The later corrections were discovered by executing the real generated-host proof and remained scoped to the same clean-room contract.

## Decisions Made

- Generated profile configuration uses `%{enabled: true}` because Doctor passes the configured value directly to each companion's `enabled?/1` map contract.
- The minimal generated host declares one managed LiveView-owned route through Phoenix route metadata. This makes Doctor's manifest validation substantive without expanding product or route scope.
- Critical child commands carry explicit failure propagation before an install can be recorded as PASS; outer shell control-flow cannot mask a nonzero Doctor or smoke result.
- The exact-public path remains available only after publication. Candidate readiness cannot count fixture output, published-current packages, or path/cache fallback as public 0.2.1 proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected companion configuration from keyword lists to maps**
- **Found during:** Task 1 real generated-host proof at the continuation checkpoint
- **Issue:** Generated `enabled: true` keyword settings reached companion `enabled?/1` functions that require maps, raising `BadMapError` in Doctor.
- **Fix:** Emit `%{enabled: true}` in the five-profile matrix and both retained profile-specific single-package templates, with structural regression assertions.
- **Files modified:** `script/verify_companion_cleanroom.sh`, `test/crosswake/release_candidate/cleanroom_test.exs`
- **Verification:** Focused 9-test suite passed, then all ten generated hosts completed Doctor successfully in each of two independent builds.
- **Committed in:** `2263e4f7`

**2. [Rule 1 - Bug] Prevented generated-host Doctor failures from becoming false profile passes**
- **Found during:** Task 1 first real proof rerun
- **Issue:** The generated Phoenix host had no managed Crosswake route, so Doctor correctly rejected an empty manifest; the outer shell `||` context also allowed the loop to continue after that nonzero result.
- **Fix:** Add one explicit managed route to every generated router and require explicit success from deps, compile, router, smoke, and Doctor commands before recording an install.
- **Files modified:** `script/verify_companion_cleanroom.sh`, `test/crosswake/release_candidate/cleanroom_test.exs`
- **Verification:** The invalid run was aborted; both subsequent independent six-package/five-profile/twice-install matrices passed with zero path locks and equivalent normalized results.
- **Committed in:** `9a4f8fdd`

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs).
**Impact on plan:** Both corrections were required to make the planned Doctor evidence real and fail closed. No package publication, tag/ref mutation, Android breadth, companion breadth, or parked-adopter work was added.

### AGENTS.md-driven adjustments

- `REL-01` and `REL-04` remain pending in `REQUIREMENTS.md`. This plan proves candidate-local consumption and the exact-public fixture contract, but the live public 0.2.1 run and final exact-candidate dossier remain owned by later Phase 168 plans.

## Issues Encountered

- Dependency and evaluated-lock warnings appeared in invocation-local logs, but the required application compilation ran with warnings as errors and passed. They did not alter the closed proof result.
- The first post-checkpoint run was intentionally discarded after it exposed the empty-manifest and failure-propagation defect; all retained completion evidence comes from fresh builds after the final correction.

## Known Stubs

None. Exact-public live execution is an intentional post-publication gate, not an unwired success path; missing or partial publication remains non-complete.

## Threat Review

- T-168-10 is mitigated by invocation-unique owned roots, distinct per-profile/per-pass scratch roots, bounded cleanup, and source/repository containment checks.
- T-168-11 is mitigated by explicit candidate-local versus exact-public modes, exactly six source observations, registry/path-lock discrimination, exact versions, and digest equality.
- T-168-12 is mitigated by five closed profile results, two installs, required public behavior, Doctor success, and one deliberate negative control in every lane.
- No unplanned network endpoint, authentication path, database schema, or application trust boundary was introduced.

## User Setup Required

None.

## Next Phase Readiness

Plan 168-05 can consume a fail-closed, real generated-host companion proof and continue with mirror baseline/candidate authority. The exact-public path is ready for its separately gated use after publication; immutable publication and tag mutation remain untouched.

## Self-Check: PASSED

All five declared implementation/test/evidence artifacts exist, all six measured commits are reachable, both independent real matrices passed, and the exact-public fixture suite remains green.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-12*
