---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-01T01:30:03Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
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
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
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
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-01T01:30:03Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

Reviewed all supplied Phoenix-host, generator, evidence, native-helper, template, shell-script, and test files. The reviewed checks pass, including the targeted ExUnit suite and the Phoenix-host typecheck/browser gate. However, the generator's native filesystem helper violates the phase's missing-only, non-destructive host-ownership guarantee in two failure/concurrency paths.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Failed writes leave a partial file at the generated host destination

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/priv/native/crosswake_proof_lane_fs.c:120-129`

**Issue:** `write_file` creates the final host-owned pathname with `O_CREAT | O_EXCL` and streams the input directly into it. If `read`, `write`, or `fsync` fails, every failure return closes descriptors but never unlinks that new destination. A short write, full filesystem, I/O error, or failed sync therefore leaves a partial generated file in the host tree. On the next run, `O_EXCL` returns `EXISTS`, which the Elixir layer reports as `:reused`; the generator will preserve the corrupted partial file indefinitely. This breaks the explicit collision-safe/no-partial-write proof-lane contract and can leave an apparently generated but unusable iOS or browser scaffold.

**Fix:** Track successful completion and, on every post-create failure path, call `unlinkat(parent, leaf(relative), 0)` before closing `parent`. Preserve the original failure code even if cleanup fails. Add a deterministic native-helper seam/test that forces a post-create write or `fsync` failure and asserts the final relative path does not exist and a rerun can create it.

### CR-02: Manifest collision leaks a staging artifact into the host-owned tree

**Classification:** BLOCKER

**File:** `/Users/jon/projects/crosswake/priv/native/crosswake_proof_lane_fs.c:165-168`

**Issue:** On a destination collision, `publish_file` returns `EXISTS` immediately after `linkat` fails and does not remove its staging file. `GeneratorFS.publish/3` translates that status to `{:ok, :reused}` ([`generator_fs.ex`](/Users/jon/projects/crosswake/lib/crosswake/proof_lane/generator_fs.ex:59)), and `Generator.promote_manifest/4` treats it as a successful run ([`generator.ex`](/Users/jon/projects/crosswake/lib/crosswake/proof_lane/generator.ex:110)). Thus concurrent generators leave `.crosswake/proof_lane.json.staging-*` files in the host project despite reporting success. I reproduced this directly: after a winner manifest existed, `publish` returned `{:ok, :reused}` while the staging path still existed. This violates the promise that generation creates only missing scaffold and leaves host-owned files untouched; it also accumulates untracked files on every manifest race.

**Fix:** When `linkat` fails with `EEXIST`, remove only the helper's own staged source via the already-open `stage_parent` descriptor, then return `EXISTS`; handle cleanup failure as a fail-closed error rather than reporting reuse. Add a concurrent/collision regression assertion that no `proof_lane.json.staging-*` paths remain after either successful or reused manifest promotion.

---

_Reviewed: 2026-08-01T01:30:03Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
