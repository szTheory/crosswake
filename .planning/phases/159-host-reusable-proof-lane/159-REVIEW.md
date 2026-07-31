---
phase: 159-host-reusable-proof-lane
reviewed: 2026-07-31T21:12:37Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - lib/crosswake/proof_lane/config.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - script/verify_generated_ios_shell.sh
  - test/crosswake/proof_lane/config_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 5
  warning: 2
  info: 0
  total: 7
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-07-31T21:12:37Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The proof-lane unit tests pass, but the implementation is not safe to ship under the phase's containment, privacy, and fail-closed requirements. The browser proof currently has a TypeScript name error; an accepted shell root can redirect generator writes to filesystem-root-level paths; evidence accepts stable identifiers and arbitrary hashes; and both evidence promotion and the iOS proof verifier can report a non-failing outcome when their prerequisite has not been established.

## Critical Issues

### CR-01: Route-tour helper references an undefined mutation ID

**Classification:** BLOCKER

**File:** `examples/phoenix_host/e2e/support/offline_route_proof.ts:244`

**Issue:** `capturedId` is never declared in `proveLearnLoopRoute`. TypeScript reports `TS2304: Cannot find name 'capturedId'`, so every route-tour spec importing this support file cannot type-check. If transpilation is used without type checking, it instead fails at runtime immediately before the history assertion.

**Fix:** Retain the ID returned by `runOfflineIslandProof` (or capture it in an outer variable in `readQueuedRecord`) and use that defined value at the history assertion. Add a type-check/lint gate that includes this support module.

### CR-02: Accepted `ios_shell_root` can make the generator write outside the intended host

**Classification:** BLOCKER

**File:** `lib/crosswake/proof_lane/config.ex:136`

**Issue:** `safe_absolute_path?/1` accepts any absolute path. `Generator.host_root/1` then removes two path components, so an otherwise accepted value such as `/tmp/not-the-native-ios-root` produces `/` as the host root. The subsequent destinations include `/e2e/...`, `/test/...`, and `/.crosswake/...`. This violates the iOS-shell ownership boundary and can create files in an unintended host (or at filesystem root) rather than fail closed.

**Fix:** Require `ios_shell_root` to be a normalized path ending exactly in `native/ios` (and reject roots whose derived host root is `/`). Prefer storing an explicit host root plus a fixed, validated `native/ios` suffix; validate real paths component-by-component without following untrusted symlinks before any `mkdir_p` or write.

### CR-03: Evidence validation permits retained account-like identifiers and unverified sensitive-data fingerprints

**Classification:** BLOCKER

**File:** `lib/crosswake/proof_lane/evidence.ex:188-201`

**Issue:** The sensitive-term substring filter is not an allowlist for the fields it protects. `commit_ref` accepts arbitrary strings such as `alice_123`, and `approved_hashes` accepts any 64-character digest labelled `evidence_json` without verifying it was calculated from the canonical artifact. Both values are retained in the promoted JSON. Thus a caller can store a stable account/person identifier or a fingerprint of sensitive answer/media/device material while satisfying `build/1` and the final scanner. This contradicts the requirement that account, payload, media, and stable device data never enter retained proof artifacts.

**Fix:** Make `commit_ref` a real revision format (for example, a bounded lower-case Git SHA) and make assertion IDs a closed registry. Do not accept caller-provided hashes, or recompute and verify each approved digest against an explicitly allowlisted, sanitized artifact before serializing it. Add canary tests for identifiers that do not contain the current sensitive keywords and for arbitrary labelled digests.

### CR-04: Evidence promotion has a collision time-of-check/time-of-use clobber window

**Classification:** BLOCKER

**File:** `lib/crosswake/proof_lane/evidence.ex:373-386`

**Issue:** `absent/1` checks the destination before staging, then `File.rename(stage, destination)` promotes later. A second writer can create an empty destination directory in that interval; directory rename may replace that empty directory, losing the other writer's host-owned contents. The two-promoter test only exercises the losing case after the winner has populated the directory, so it does not cover this empty-directory race.

**Fix:** Reserve the destination atomically first with an exclusive directory/lock creation, write only inside that owned directory, and remove it on failure only when ownership is proven. Treat every pre-existing destination, including a newly created empty directory, as `PL-EVIDENCE-COLLISION`.

### CR-05: Proof-lane verification succeeds when the required iOS proof is unavailable

**Classification:** BLOCKER

**File:** `script/verify_generated_ios_shell.sh:20-23`

**Issue:** In `--proof-lane` mode, a missing `xcodebuild` prints an advisory and exits 0. The same fail-open behavior occurs if the generated project graph cannot be enumerated or `build-for-testing` fails (`124-148`). A caller/CI therefore receives a successful verification result even though no generated XCTest/XCUITest target was built. That is neither an explicit blocked/unavailable result consumable by the proof lane nor a failing verification gate.

**Fix:** Return a distinct non-zero blocked/unavailable exit status (and a machine-readable status artifact) for each unavailable prerequisite. Reserve exit 0 for a successfully enumerated and built proof target; do not let a caller treat advisories as completed verification.

## Warnings

### WR-01: Offline state is not restored if a proof assertion fails

**Classification:** WARNING

**File:** `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex:33-41`

**Issue:** Once the browser context is put offline, any failure in mutation, record extraction, reconnect, or an assertion skips `context.setOffline(false)`. This contaminates the shared Playwright context and turns later failures into misleading network errors.

**Fix:** Wrap the proof sequence in `try/finally` and call `await context.setOffline(false)` in the `finally` block. Apply the same cleanup pattern to the example-host helper.

### WR-02: IndexedDB reset races the next navigation

**Classification:** WARNING

**File:** `examples/phoenix_host/e2e/support/offline_route_proof.ts:259-265`

**Issue:** The init script starts `indexedDB.deleteDatabase` but neither waits for its success nor handles a blocked deletion. Navigation can therefore initialize the offline island against the old database, producing stale queued rows and nondeterministic replay assertions.

**Fix:** Perform deletion in a page context before navigation and await `onsuccess`/`onblocked`/`onerror` through a Promise; fail the proof on blocked or failed deletion.

---

_Reviewed: 2026-07-31T21:12:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
