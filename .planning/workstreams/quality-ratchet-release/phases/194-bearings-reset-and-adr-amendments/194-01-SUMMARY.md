---
phase: 194-bearings-reset-and-adr-amendments
plan: 01
subsystem: support-matrix
tags: [support-matrix, android, adr-01, golden-fixtures, release-please]
requires:
  - phase: 193
    provides: v27 closeout baseline
provides:
  - D-06 Android note ("proof and parity cover existing contracts only") in support-matrix source, renderers, guides and golden fixtures
  - Recorded D-03 prefix decision and regeneration diff evidence
affects: [194-02, 194-03]
actuals:
  tokens: 0
  tasks: 3
  commits: 2
plan_head_before: d1435bf3
plan_head_after: e60f8330
key-files:
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/capability_map/renderer.ex
    - lib/crosswake/proof_lane/provenance.ex
    - guides/support_matrix.md
    - guides/capability_map.md
    - guides/native_shell.md
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/support_matrix/renderer_test.exs
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json
    - examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json
    - examples/phoenix_host/native/ios/crosswake_shell/.crosswake/ios_host_generation.json
    - test/fixtures/shell/ios/production_generation.sha256.json
  created:
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-EVIDENCE/ (four evidence files)
key-decisions:
  - "D-03: fix(support-matrix) prefix, because release-please links hex/ios-core/android-core so they bump together"
requirements-completed: [ADR-01]
status: complete
---

# Phase 194 Plan 01: Android proof and parity wording Summary

The word "frozen" no longer appears in the Android support-matrix notes; they now state that Android proof and parity cover existing contracts only (JVM hermetic proof and shared vectors), with golden fixtures regenerated through their generators.

## Results

- Merge-blocking lane: `mix test --exclude requires_example_host --exclude advisory_only` gave 2663 tests, 0 failures, 78 excluded (`lane: rc 0`).
- `mix format --check-formatted` passes. Swift `HostCommandSeamTests`: 15 tests, 0 failures. Seam fixture ExUnit test: 2 tests, 0 failures.
- Regeneration diff: `regen: files 3`, `changed_lines 14`, `unexpected 0`.
- Commits: product `3c20a9c0`, evidence `e60f8330`.

## Deviations from Plan

1. **[Rule 3 - Blocking] `mix deps.get` before the baseline.** Dependencies were not fetched in the tree.
2. **Files 2 to 3 override.** `ios_host_generation.json` records the manifest digest, so it necessarily changes (hash-only). `shell.json` was kept at its tracked version. The plan's `regen: files 2` was replaced with the recorded override value `files 3`.
3. **Line-neutral test rewrite.** `support_matrix_test.exs` was rewritten so its assertions do not depend on line positions that the wording change shifts.
4. **Golden digest update.** `test/fixtures/shell/ios/production_generation.sha256.json` was updated to the new generation digest.
5. **Orchestrator fix commit d1435bf3.** Four lane failures came from files outside this plan: PROJECT.md lacked the `### v28.0 Truth and Release Train (active)` heading, and 194-09-PLAN.md used awk `$10`, which matched privacy.commercial_detail. The orchestrator fixed both; the affected tests and test/crosswake/planning then passed (92 tests, 0 failures).
6. The per-plan HEAD ledger file was absent, so `plan_head_before` is recorded as d1435bf3, the HEAD when the final product work began; the SUMMARY and tracking commits are not counted.

## Known Stubs

None.

## Self-Check: PASSED

Both commits are ancestors of HEAD; the evidence files are tracked and clean; `shell.json` is unchanged and no `crosswake_example.db*` is dirty.
