---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-01T00:00:00Z
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
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-01T00:00:00Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

The browser proof and generated host-owned scaffold preserve the intended offline-island sequence, and the focused ExUnit review command passes. However, the proof publication boundary has two exploitable integrity failures: a predictable executable cache in the shared temporary directory and a time-of-check/time-of-use gap in retained-evidence validation. The native evidence writer also leaves incomplete artifacts behind after failures, contrary to the phase's atomic evidence requirement.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Shared temporary executable cache permits arbitrary code execution

**File:** `lib/crosswake/proof_lane/generator_fs.ex:160-175`

**Issue:** The helper executable name is deterministically derived from public source bytes under `System.tmp_dir!()`. If a regular file already exists there, lines 162-163 trust it without checking ownership, origin, or even whether it is a symlink to an attacker-controlled executable; `invoke_read/3` and `run_port/4` then execute it. Another process that can write the shared temporary directory can pre-create `crosswake-proof-lane-fs-<known-digest>` and obtain code execution whenever the host runs generation, `--check`, or `--diff`.

**Fix:** Do not reuse a predictable executable in a shared directory. Build into a process-private `0700` directory using an unpredictable name, execute that exact file, and remove it afterwards. If caching is retained, use a private cache directory and reject symlinks/non-owned files with `lstat` plus ownership and mode checks before execution.

### CR-02: Evidence check can approve artifact bytes that were never digest-verified

**File:** `lib/crosswake/proof_lane/evidence.ex:89-94`

**Issue:** `check/1` first calls `scan_stage/1`, which reads and digest-verifies one copy of `proof-lane-evidence.json` (lines 111-118, 358-376), but then `read_evidence/1` reopens the pathname and decodes a second copy (lines 379-386). A concurrent writer can replace the JSON after `scan_stage/1` returns. `check/1` will then validate and return success for the replacement bytes without proving that they match `.complete`; the same gap exists in `check/2`. This defeats the claimed digest-bound retained-evidence integrity boundary.

**Fix:** Read the artifact once and carry those verified bytes through marker verification, scanning, decoding, and source-hash validation. At minimum, make `scan_stage/1` return the verified bytes/evidence and have both `check` variants consume that result; preferably use descriptor-based reads and revalidate file identity to avoid a path replacement race.

## Warnings

### WR-01: Native promotion leaves incomplete evidence at the final destination on write failures

**File:** `priv/native/crosswake_evidence_promote.c:95-118`

**Issue:** The native publisher creates the final destination before writing the artifact and completion marker. Any later failure (write, `fsync`, permission change, marker creation, rename, or directory sync) returns an error without removing the created directory or partial files. That leaves a partially promoted artifact at the advertised destination, violating the phase requirement that failed evidence generation be atomic and leave no retained artifact.

**Fix:** Track ownership after successful `mkdir`, and on every later failure use directory-descriptor-relative cleanup to unlink the incomplete files and remove the directory only if it is still the publisher's directory. Preserve the existing no-clobber collision behavior.

---

_Reviewed: 2026-08-01T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
