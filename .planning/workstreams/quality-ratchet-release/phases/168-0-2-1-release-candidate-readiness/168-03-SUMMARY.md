---
phase: 168-0-2-1-release-candidate-readiness
plan: "03"
subsystem: release-candidate-artifacts
tags: [elixir, hex, package-audit, compatibility-floor, release-coordinates, tdd]
requires:
  - phase: 168-02
    provides: Closed candidate identity, receipt state, deterministic projections, and exact command boundary
provides:
  - Exact-ref six-package Hex publish-dry-run, build, official-unpack, and normalized digest pipeline
  - Metadata-first 0.2.1 Hex/iOS/Android linked-coordinate validator
  - Independent companion requirement and below-floor boundary proof
affects: [168-clean-room-proof, 168-mirror-authority, 168-release-workflow, release-candidate-capture]
actuals:
  tokens: 12804
  tasks: 2
  commits: 12
plan_head_before: 9cae78ddd1e9bb0162af6dfc0232525b41fcff54
tech-stack:
  added: []
  patterns: [official-hex-unpack, normalized-artifact-manifest, candidate-seeded-offline-dependency, red-green-task-commits]
key-files:
  created:
    - lib/crosswake/release_candidate/artifact.ex
    - lib/crosswake/release_candidate/coordinate.ex
    - script/release_candidate/hex_artifacts.sh
    - test/crosswake/release_candidate/artifact_test.exs
    - test/crosswake/release_candidate/coordinate_test.exs
  modified:
    - script/verify_hex_publish_dry_run.sh
key-decisions:
  - "Use Hex's official tarball unpacker and accept only exact-ref built tarballs; durable evidence is the normalized metadata/payload digest pair, never a repository tree or ephemeral root."
  - "Seed companion audit dependencies from the candidate core tarball inside exact-ref source snapshots, preserving public Hex requirements without a registry fallback."
  - "Link only Hex, iOS core, and Android core at 0.2.1; companion versions and proposals remain independent approval outsiders."
patterns-established:
  - "Package observations are closed, ordered, content-addressed, and reject path escape, symlink, checksum, source, file-set, and package-family drift."
  - "Companion compatibility proof must accept both the candidate and the declared floor while rejecting an immediately below-floor control."
requirements-completed: []
requirements-addressed: [REL-03, REL-04]
coverage:
  - id: candidate-hex-artifacts
    description: Six exact-ref Hex packages pass package-only publish dry-run, build, official unpack, canonical inspection, and deterministic normalized digest comparison without publication authority.
    requirement: REL-04
    verification:
      - kind: integration
        ref: "mix test test/crosswake/release_candidate/artifact_test.exs && bash script/verify_hex_publish_dry_run.sh"
        status: pass
      - kind: integration
        ref: "two fresh script/release_candidate/hex_artifacts.sh runs compared after removing only unpacked_root"
        status: pass
    human_judgment: false
  - id: linked-coordinate-and-floors
    description: The evaluator links only Hex/iOS/Android at 0.2.1 and proves every independently versioned companion requirement at the floor, candidate, and below-floor boundary.
    requirement: REL-03
    verification:
      - kind: unit
        ref: "test/crosswake/release_candidate/coordinate_test.exs"
        status: pass
      - kind: integration
        ref: "elixir script/check_release_workflow_integrity.exs"
        status: pass
    human_judgment: false
duration: 38m
completed: 2026-09-12
status: complete
---

# Phase 168 Plan 03: Candidate Hex Artifacts and Coordinate Floors Summary

**Six exact-ref Hex packages now produce officially unpacked, content-addressed observations, while a closed validator proves the 0.2.1 core/native tuple and independent companion compatibility floors.**

## Performance

- **Duration:** 38m
- **Started:** 2026-09-13T02:30:44Z
- **Completed:** 2026-09-13T03:08:11Z
- **Tasks:** 2
- **Files modified:** 8
- **Commits:** 12 measured from `9cae78ddd1e9bb0162af6dfc0232525b41fcff54`

## Accomplishments

- Added hostile artifact fixtures and a closed Elixir evaluator for the exact root-plus-five-companion package family, including official metadata parsing, declared/actual file comparison, path and symlink rejection, and independent SHA-256 metadata/payload digests.
- Added an isolated adapter that performs official package-only `mix hex.publish --dry-run`, `mix hex.build`, and Hex unpack semantics from the exact candidate ref without publication credentials, public fetch fallback, or durable raw logs.
- Added a metadata-first coordinate evaluator that binds Hex/iOS/Android to `0.2.1`, preserves five independent companion versions and proposals, and proves every public core requirement against its floor and an immediately below-floor control.
- Confirmed two fresh six-package builds from the same ref have identical normalized observations after removing only invocation-local unpack roots.

## Task Commits

1. **Task 1 RED: exact artifact-family contract** — `4c98dd06`
2. **Task 1 GREEN: artifact evaluator and adapter** — `171df5c7`
3. **Task 1 fixes: hermetic archive and candidate-seeded companion audit** — `699c438e`, `43b459fa`, `96797cda`, `848e4983`, `33c13ff5`, `df6e32da`, `60f33e29`, `e7aff169`
4. **Task 2 RED: coordinate graph and boundary contract** — `1f5e22c7`
5. **Task 2 GREEN: linked coordinate and companion floor authority** — `aa99328e`

## Evidence and Verification

- `mix test test/crosswake/release_candidate/artifact_test.exs` passed 4 tests with zero failures.
- `bash script/verify_hex_publish_dry_run.sh` passed all six package dry-run/build/unpack/normalize steps with `external_state_changed=false`.
- `mix test test/crosswake/release_candidate/coordinate_test.exs` passed 4 tests with zero failures.
- `elixir script/check_release_workflow_integrity.exs` passed every release workflow integrity assertion.
- Two additional fresh artifact builds produced byte-identical normalized JSON after deleting only the invocation-local `unpacked_root` field.
- `mix format --check-formatted`, `mix compile --warnings-as-errors`, and `git diff --check` passed.
- Both RED records passed `tdd-red-evidence` with `RED_EVIDENCE_OK` before their GREEN source edits.

## TDD Gate Compliance

| Task | RED | GREEN | REFACTOR | Status |
|------|-----|-------|----------|--------|
| Six exact candidate Hex payloads | `4c98dd06` | `171df5c7` | follow-up fixes through `e7aff169` | Pass |
| Linked coordinates and companion floors | `1f5e22c7` | `aa99328e` | — | Pass |

The first GREEN exposed integration-only differences between fixture metadata and official Hex archives; each correction remained scoped to the candidate artifact path and was verified against the exact plan command.

## Decisions Made

- Use package-only Hex publish dry-runs. Documentation generation belongs to later REL-04 proof, while this adapter audits the package payload and public dependency metadata without widening authority.
- Supply the not-yet-published candidate core to companion dry-runs from its just-built official tarball. The source snapshot is produced with `git archive` at the exact ref, and its temporary lock/marker are excluded from the distributable allowlist.
- Treat package roots as ephemeral execution data. Only outer checksum, normalized metadata digest, payload digest, files, requirements, version, package, source, and candidate ref are durable observation fields.
- Keep the candidate coordinate fixed at `0.2.1` and keep PRs #115/#146/#147 plus every companion component outside the linked approval unit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Resolved Hex from the pinned runtime archive**
- **Found during:** Task 1 exact dry-run verification
- **Issue:** The generic user Hex archive was compiled for a different Erlang runtime and could hang or fail under the pinned toolchain.
- **Fix:** Resolve the archive through the pinned Mix runtime before copying it into the isolated home.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`
- **Verification:** Isolated `mix hex.config` and the full six-package command passed.
- **Committed in:** `699c438e`

**2. [Rule 2 - Missing Critical] Seeded companions from the candidate core tarball**
- **Found during:** Task 1 companion dry-run
- **Issue:** Public companion metadata requires core, but the 0.2.1 candidate is intentionally not yet published and public registry fallback is prohibited.
- **Fix:** Build exact-ref companion snapshots and seed their Hex-shaped dependency from the officially unpacked candidate core tarball.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`
- **Verification:** All five companion dry-runs and builds passed offline.
- **Committed in:** `43b459fa`

**3. [Rule 1 - Bug] Removed seed-dependent module export assertion**
- **Found during:** Task 1 repeated focused tests
- **Issue:** `function_exported?/3` could run before the artifact module was loaded, producing a random false negative.
- **Fix:** Explicitly ensure the module is loaded before asserting its public API.
- **Files modified:** `test/crosswake/release_candidate/artifact_test.exs`
- **Verification:** Seeds 0 and 1 plus the exact plan command passed.
- **Committed in:** `96797cda`

**4. [Rule 2 - Security] Bounded dependency atom conversion**
- **Found during:** Task 1 candidate dependency seeding
- **Issue:** Candidate metadata could not safely be converted with unbounded dynamic atom creation.
- **Fix:** Map the closed known core dependency set and fail when it changes.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`
- **Verification:** The exact adapter command passed without atom creation errors.
- **Committed in:** `848e4983`

**5. [Rule 1 - Bug] Wrote the temporary lock without a loaded Mix project**
- **Found during:** Task 1 candidate dependency seeding
- **Issue:** `Mix.Dep.Lock.write/2` triggers a recompilation marker and cannot run outside a loaded project.
- **Fix:** Serialize the validated invocation-local lock map directly.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`
- **Verification:** All companion dependency checks and dry-runs passed.
- **Committed in:** `33c13ff5`

**6. [Rule 3 - Blocking] Pinned tools inside exact-ref snapshots**
- **Found during:** Task 1 snapshot execution
- **Issue:** Temporary candidate snapshots intentionally lack `.tool-versions`, so asdf could not resolve Elixir while reading versions.
- **Fix:** Pass the repository's pinned Erlang and Elixir versions to snapshot-local commands.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`
- **Verification:** All five snapshot-local dry-runs and builds passed.
- **Committed in:** `df6e32da`

**7. [Rule 1 - Bug] Normalized official tuple-shaped link metadata**
- **Found during:** Task 1 official archive normalization
- **Issue:** Hex emits link metadata as key/value tuples, unlike the initial map-only hostile fixture.
- **Fix:** Normalize bounded binary-key tuples, cover the official shape in fixtures, and avoid duplicating an already cached candidate core dependency.
- **Files modified:** `lib/crosswake/release_candidate/artifact.ex`, `script/release_candidate/hex_artifacts.sh`, `test/crosswake/release_candidate/artifact_test.exs`
- **Verification:** Fixture tests and official normalization passed.
- **Committed in:** `60f33e29`

**8. [Rule 1 - Bug] Canonicalized manifest paths across macOS temp aliases**
- **Found during:** Task 1 manifest emission
- **Issue:** `/var` and `/private/var` aliases made a valid caller path appear outside the canonical output root.
- **Fix:** Canonicalize the manifest parent before the containment check.
- **Files modified:** `script/release_candidate/hex_artifacts.sh`
- **Verification:** The full wrapper and repeated-build comparison passed.
- **Committed in:** `e7aff169`

**Total deviations:** 8 auto-fixed (5 Rule 1, 2 Rule 2, 1 Rule 3).
**Impact on plan:** All changes are confined to correctness, security, and hermetic execution of the planned package proof; no publication, registry, tag, Android behavior, or unrelated release scope was added.

### AGENTS.md-driven adjustments

- `REL-03` and `REL-04` remain pending in `REQUIREMENTS.md`. This plan supplies their coordinate/floor and package-artifact portions, while later Phase 168 plans still own exact-candidate tests, documentation, clean-room installation, release-status verification, and the full approval packet. Marking either complete here would overclaim readiness.

## Known Stubs

None. Empty approval children and shell argument initializers are closed-state/control-flow values, not unwired output data.

## Threat Review

- T-168-07 is mitigated by official Hex unpack semantics, exclusive output roots, path/symlink/special-file rejection, exact declared-file comparison, and canonical SHA-256 manifests.
- T-168-08 is mitigated by exact-ref clean-tree validation, `git archive` snapshots, built-tarball-only observations, isolated offline Hex/Mix homes, and no repository/public-registry artifact fallback.
- T-168-09 is mitigated by exact cross-format linked components, fixed 0.2.1 source/manifest assertions, companion exclusion, and boundary-version mutation tests.
- No unplanned network endpoint, authentication path, file-access trust boundary, or schema change was introduced.

## User Setup Required

None.

## Next Phase Readiness

Plan 168-04 can consume the six invocation-local unpacked roots and their durable digest observations to run clean-room consumer proof without changing package-source or coordinate authority. Immutable publication and tag creation remain prohibited and untouched.

## Self-Check: PASSED

All six declared implementation/test artifacts, both RED evidence records, and this summary exist; all twelve measured plan commits are reachable from the current phase branch.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-12*
