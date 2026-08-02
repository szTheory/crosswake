---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-02T00:02:26Z
depth: standard
files_reviewed: 33
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-02T00:02:26Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

The generated Phoenix proof is executable and its browser adapter is fail-closed, but the two final filesystem publication boundaries do not verify that their staged source is still a regular owned artifact. A staging-path swap can therefore make either operation return success while publishing a symbolic link. This violates the proof lane's no-follow, provenance, and privacy-safe retention guarantees.

## Critical Issues

### CR-01: Evidence promotion can successfully retain a substituted symlink

**File:** `/Users/jon/projects/crosswake/priv/native/crosswake_evidence_promote.c:20-24`
**Issue:** The helper uses `stat(argv[1])`, which follows symlinks, before `renameat2(..., RENAME_NOREPLACE)` / `renameatx_np(..., RENAME_EXCL)`. The stage directory is writable through the lifecycle seam until this call. If it is replaced with a symlink after `scan_stage/1` and before promotion, `stat` accepts the linked directory and rename moves the symlink itself to the destination. `Evidence.promote/3` then returns `:ok`, leaving the retained evidence destination as a symlink outside the reviewed stage. This was reproduced with a `before_promote` hook: promotion returned `:ok` and `File.lstat(destination).type` was `:symlink`.
**Fix:** Open or inspect the source with no-follow semantics immediately before publication and reject any non-directory source. At minimum, replace `stat` with `lstat` and reject `S_ISLNK`; preferably use descriptor-relative no-follow operations and validate both source and destination parents so the check and publication share an anchored filesystem authority.

### CR-02: Manifest publication accepts a swapped staging symlink as generated output

**File:** `/Users/jon/projects/crosswake/priv/native/crosswake_proof_lane_fs.c:192-206`
**Issue:** `publish_file` hard-links the staging leaf without opening or `fstat`-checking it first. `linkat(..., 0)` will hard-link a symlink itself, so a staging-file swap between `GeneratorFS.write/4` and `GeneratorFS.publish/3` makes the manifest destination a symlink while the function returns success. That bypasses the claimed generated-file provenance boundary; a subsequent `check` may reject it, but generation has already reported a created manifest and left an unsafe host artifact. Reproduction with a symlink at `.crosswake/proof_lane.json.staging-race` returned `{:ok, :created}` and produced a symlinked `.crosswake/proof_lane.json`.
**Fix:** Before linking, open the staging leaf with `openat(stage_parent, leaf, O_RDONLY | O_NOFOLLOW)`, require `fstat` to report a regular file, and publish only that verified source (or use a descriptor-anchored regular-file copy with exclusive destination creation). Reject and clean up staging when the source is a symlink or otherwise not regular.

---

_Reviewed: 2026-08-02T00:02:26Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
