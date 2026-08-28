---
phase: 159-host-reusable-proof-lane
plan: "08"
subsystem: generator filesystem safety
tags: [elixir, c, filesystem, openat, nofollow, proof-lane]
requires:
  - phase: 159-05
    provides: validated normalized non-root host root
provides:
  - Descriptor-relative no-follow host filesystem boundary
  - Exclusive generated-file creation and no-replace manifest publication
  - Symlink and ancestor-swap regression coverage
affects: [proof-lane, host-reusable-generation, PROOF-01, PROOF-02]
tech-stack:
  added: [repository-owned C filesystem helper]
  patterns: [canonical-root descriptor traversal, relative-only generator operations]
key-files:
  created:
    - lib/crosswake/proof_lane/generator_fs.ex
    - priv/native/crosswake_proof_lane_fs.c
  modified:
    - lib/crosswake/proof_lane/generator.ex
    - test/mix/tasks/crosswake_gen_proof_lane_test.exs
key-decisions:
  - "Generator filesystem authority is confined to GeneratorFS using root-relative paths only."
  - "Unsafe topology and native-helper failures fail closed with stable relative-path rules."
patterns-established:
  - "Use descriptor-pinned no-follow traversal for host-owned generator operations."
metrics:
  duration: 22m
  completed: 2026-07-31
  tasks_completed: 2
  files_changed: 4
status: complete
---

# Phase 159 Plan 08: Host-Root Descriptor Safety Summary

Proof-lane generation now confines every host filesystem action to a descriptor-pinned, no-follow traversal rooted at the normalized host root.

## Completed Work

- Added `Crosswake.ProofLane.GeneratorFS`, a closed boundary that accepts only a validated root and manifest-relative paths.
- Added a repository-owned Linux/Darwin C helper that canonicalizes and reopens the root component by component, uses `openat`/`mkdirat` with no-follow flags, exclusively creates files, safely reads regular files, and publishes manifests through no-replace links.
- Routed generator `generate`, `check`, `diff`, and manifest lifecycle operations through the boundary; Elixir retains rendering only.
- Added regressions for symlinked generated ancestors, a controlled final-create ancestor swap, generated namespace safety, manifest-parent safety, and read-only inspection.

## Task Commits

1. Task 1 RED — `e6452fca` test(159-08): add descriptor traversal regressions
2. Task 1 GREEN — `31dd6047` feat(159-08): pin proof writes to host descriptors
3. Task 2 RED — `23222ffd` test(159-08): cover generator namespace symlinks
4. Task 2 GREEN — `e1585506` feat(159-08): route generator actions through safe filesystem boundary

## Verification

- `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed (9 tests).
- `mix format --check-formatted lib/crosswake/proof_lane/generator.ex lib/crosswake/proof_lane/generator_fs.ex test/mix/tasks/crosswake_gen_proof_lane_test.exs` — passed.
- `test -s priv/native/crosswake_proof_lane_fs.c` — passed.
- Generator authority inspection found no direct host `File.read`, `File.open`, `File.mkdir_p`, `File.ln`, or lexical `within?` use in `generator.ex`.

## Decisions Made

- Canonical root reopening and child traversal happen in the native boundary; caller-supplied absolute destinations are not accepted.
- Topology changes, symlinks, non-directories, unsupported helpers, and compiler failures return stable safe errors without exposing host paths or using a fallback open path.
- Manifest publication retains missing-only no-clobber semantics through an exclusive staging file and no-replace publication.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All four implementation and regression artifacts exist.
- All four TDD gate commits exist in git history.
- The focused generator suite and formatter pass from the final tree.
