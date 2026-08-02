---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-01T00:00:00Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.typecheck.d.ts
  - examples/phoenix_host/package.json
  - examples/phoenix_host/tsconfig.offline_route_proof.json
  - lib/crosswake/proof_lane/config.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/crosswake/proof_lane/generator_fs.ex
  - lib/crosswake/proof_lane/native_promotion.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - priv/native/crosswake_evidence_promote.c
  - priv/native/crosswake_proof_lane_fs.c
  - priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - script/verify_generated_ios_shell.sh
  - script/verify_phoenix_host_proof_lane.sh
  - test/crosswake/proof_lane/config_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/ios_verifier_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-01T00:00:00Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found

## Summary

The browser helper, generator provenance checks, configuration validation, and evidence allowlist were reviewed along with their tests. Targeted ExUnit coverage passed (54 tests), but the native promotion helper does not preserve the claimed contained, race-resistant filesystem boundary and does not clean up failed publications.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Evidence promotion can be redirected outside its requested destination

**File:** `priv/native/crosswake_evidence_promote.c:95-118`
**Issue:** The helper creates `argv[1]` and then subsequently opens `argv[1]/proof-lane-evidence.json`, `argv[1]/.complete.pending`, and `argv[1]` again by path. It never holds and uses a directory descriptor for these operations. A concurrent actor able to modify the destination parent can replace the freshly created empty directory with a symlink between line 95 and line 100; all later path-based operations then follow that symlink. `O_NOFOLLOW` only protects the final file component, not an ancestor. This violates the promotion containment/race-resistance boundary and permits unintended writes in the symlink target.

**Fix:** Open the newly created directory once with `open(..., O_DIRECTORY | O_NOFOLLOW)` and perform every file creation, verification, rename, and final `fsync` with `openat`, `renameat`/`renameatx_np`, and `unlinkat` relative to that held descriptor. Re-check the directory inode if any path-based fallback remains. Add a concurrent ancestor-replacement test that asserts no files are written outside the destination.

## Warnings

### WR-01: A mid-publication failure permanently leaves an unusable evidence destination

**File:** `priv/native/crosswake_evidence_promote.c:95-114`
**Issue:** Once `mkdir(argv[1], 0700)` succeeds, every later error returns immediately without removing the partially created artifact, pending marker, or directory. A transient write/fsync/rename error therefore leaves the destination existing but incomplete; future `Evidence.promote/2` calls return `PL-EVIDENCE-COLLISION`, so the normal retry path is blocked. This also conflicts with the intended all-or-nothing evidence publication behavior.

**Fix:** Track which entries were created and, on every failure before completion, remove only those entries via the held directory descriptor, fsync the parent, then remove the directory if it is still the helper-created empty directory. Preserve the existing collision behavior for a directory that existed before this invocation. Add fault-injection tests for artifact-write, marker-write, and rename failures followed by a successful retry.

---

_Reviewed: 2026-08-01T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
