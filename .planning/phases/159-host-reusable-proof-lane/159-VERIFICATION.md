---
phase: 159-host-reusable-proof-lane
verified: 2026-08-01T01:35:52Z
status: gaps_found
score: 20/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
next_action: "Fix the generator helper's post-create cleanup and manifest-collision staging cleanup, then rerun Phase 159 verification."
next_command: "/gsd-plan-phase 159 --gaps"
re_verification:
  previous_status: passed
  previous_score: 23/23
  gaps_closed: []
  gaps_remaining:
    - "Generation can retain a partial destination file after a write or fsync failure."
    - "A manifest publish collision retains a .staging-* file while reporting reuse."
  regressions:
    - "The previous final-tree proof gate did not exercise post-create write/fsync failure cleanup."
    - "The previous final-tree proof gate did not assert staging-file removal on manifest collision."
gaps:
  - truth: "Generation is non-destructive and supports a diff/check mode."
    status: failed
    reason: "The native helper streams directly into the final host destination. A post-create write or fsync failure leaves a partial file that later generation reports as reused. A manifest collision likewise reports reuse while leaking the helper-owned staging path."
    artifacts:
      - path: "priv/native/crosswake_proof_lane_fs.c"
        issue: "write_file returns after post-create failures without unlinkat(parent, leaf(relative), 0)."
      - path: "priv/native/crosswake_proof_lane_fs.c"
        issue: "publish_file returns EXISTS after linkat collision without unlinkat(stage_parent, leaf(staging), 0)."
    missing:
      - "Remove a newly created destination on every post-create write/read/fsync failure while preserving the original failure result."
      - "Remove the helper-owned staging file on an EEXIST publish collision; make cleanup failure fail closed."
      - "Add deterministic regressions for both cleanup paths and rerun the complete final-tree gate."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding.
**Verified:** 2026-08-01T01:35:52Z
**Status:** gaps_found
**Re-verification:** Yes — a prior `passed` report was independently rechecked after code review findings.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports a diff/check mode. | ✗ FAILED | `write_file` creates the final pathname before copying and never removes it after failed write/read/fsync; forced `ulimit -f 1` run exited 153 and left `partial.txt` at 512 bytes. Manifest collision exited 10 (`EXISTS`) but retained `.crosswake/proof_lane.json.staging-verify`. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ✓ VERIFIED | `bash script/verify_phoenix_host_proof_lane.sh` passed typecheck and all 5 Playwright tests, including the existing IndexedDB/reconnect/backend/idempotency flow. |
| 3 | Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio. | ✓ VERIFIED | Generated shared-scheme verification returned `{"outcome":"passed","rule_id":"PL-IOS-TEST-EXECUTION","scope":"generated-proof-targets"}`. Templates retain unavailable/blocked prerequisites for later replay/auth and pack/audio behavior; no physical-device promotion is present. |
| 4 | Evidence generation fails when sensitive payload or identity fields appear. | ✓ VERIFIED | Focused evidence/config/template/IOS/generator ExUnit gate passed; `Evidence` uses a typed allowlist, source-bound hashes, final-stage scanning, and fail-closed hook normalization. |

**Roadmap score:** 3/4 success criteria verified.

### Detailed Must-Have Score

The prior report's 23 final-tree truths were regression-checked. Twenty remain supported. The following three are failed by the confirmed helper behavior: collision-safe staged generation, rerun byte preservation after an interrupted write, and interrupted/concurrent generation cleanup. The relevant evidence-promotion no-replace tests remain passing; this gap is specifically in proof-lane *generation* and manifest publication.

**Score:** 20/23 must-haves verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/proof_lane/config.ex` | Closed nine-value Phoenix configuration | ✓ VERIFIED | Validated by focused config tests; only normalized non-root `native/ios` layouts derive a host root. |
| `lib/crosswake/proof_lane/generator.ex` + `generator_fs.ex` | Missing-only generator with diff/check and safe write lifecycle | ✗ FAILED | Wired to the C helper, but the helper violates the required cleanup behavior on post-create failure and manifest collision. |
| `priv/native/crosswake_proof_lane_fs.c` | Descriptor-relative, no-follow confined filesystem boundary | ✗ FAILED | Substantive and wired, but `write_file` and `publish_file` retain unsafe host-tree artifacts on observed failure/collision paths. |
| Browser proof helpers and Phoenix-host script | Primary browser/island proof | ✓ VERIFIED | Typecheck plus all five Playwright tests passed in the real Phoenix host. |
| iOS templates, shared scheme, and verifier script | Bounded executable XCTest/XCUITest proof scaffold | ✓ VERIFIED | `bash script/verify_generated_ios_shell.sh --proof-lane` returned closed `passed`. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed, privacy-safe retained evidence | ✓ VERIFIED | Focused evidence tests passed; no review finding invalidated evidence promotion. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Generator.generate/1` | `GeneratorFS.write/4` | Missing-only file creation | ✗ NOT SAFE | Wired, but failed writes become retained final destination files rather than being cleaned up. |
| `Generator.promote_manifest/4` | `GeneratorFS.publish/3` | Staged manifest no-replace publication | ✗ NOT SAFE | Collision is mapped to `{:ok, :reused}` although the staging source remains. |
| `script/verify_phoenix_host_proof_lane.sh` | Existing Phoenix Playwright corpus | Typecheck then existing and regression specs | ✓ WIRED | All five tests passed. |
| `script/verify_generated_ios_shell.sh --proof-lane` | Shared XCTest/XCUITest scheme | Build-for-testing and test-without-building | ✓ WIRED | Closed passed outcome returned only after test execution. |
| `Evidence.promote/3` | Final scan and native no-replace promotion | Closed hook boundary | ✓ WIRED | Focused evidence tests passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Phoenix Playwright offline proof | Opaque mutation ID and IndexedDB outbox state | Real UI mutation, browser IndexedDB, Phoenix reconnect, and Ecto assertion | Yes | ✓ FLOWING |
| Generated iOS scaffold | Closed adapter outcome/reconnect state | Host-supplied adapter contract | Yes for scaffold contract; later replay/auth and pack/audio stay unavailable | ✓ BOUNDED |
| Retained evidence | Typed sanitized fields and canonical bytes | Explicit allowlist and approved source bytes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Post-create failure does not retain a partial destination | Compiled helper with `ulimit -f 1` and a source larger than the file limit | Exit 153; `partial.txt` remained at 512 bytes | ✗ FAIL |
| Publish collision cleans its staging input | Compiled helper: existing manifest plus staged source, then `publish` | Exit 10; staging source still present | ✗ FAIL |
| Existing browser corpus remains primary | `bash script/verify_phoenix_host_proof_lane.sh` | TypeScript typecheck and 5 Playwright tests passed | ✓ PASS |
| Generated native scaffold executes tests | `bash script/verify_generated_ios_shell.sh --proof-lane` | `PL-IOS-TEST-EXECUTION` outcome `passed` | ✓ PASS |
| Focused proof-lane regression suite | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | Exit 0; its tests do not cover either failed cleanup path | ✓ PASS (coverage gap) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159-01, 02, 03, 05, 06, 08, 09, 12 | Configurable host-owned scaffold without overwriting host files | ✗ BLOCKED | Direct write-to-final behavior can leave a partial host file that future runs preserve as `:reused`; manifest collisions leave extra host-tree staging files. |
| PROOF-02 | 159-01, 02, 05, 08, 10, 12 | Route/storage/mutation/endpoint/router/shell-root configuration | ✓ SATISFIED | Closed config artifact and focused config tests pass. |
| PROOF-03 | 159-01, 03, 06, 09, 10, 12 | Preserve browser/unit/fixture corpus and add only bounded shell/island coverage | ✓ SATISFIED | Live Phoenix browser gate passes; iOS shared scheme executes bounded scaffold tests. |
| PROOF-04 | 159-01, 04, 07, 10, 11, 12 | Reject raw payloads and identity/device sensitive data from generated evidence | ✓ SATISFIED | Evidence tests pass with typed allowlist, final-byte scan, canonical hashing, and fail-closed hooks. |

All requirement IDs declared by Phase 159 plans are present in `REQUIREMENTS.md`; no orphaned Phase 159 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `priv/native/crosswake_proof_lane_fs.c` | 120-129 | Direct final-path write with no post-create unlink on failure | 🛑 BLOCKER | A partial generated host artifact persists and is subsequently treated as user-owned/reused. |
| `priv/native/crosswake_proof_lane_fs.c` | 165-168 | `EEXIST` publish return without staged-source unlink | 🛑 BLOCKER | Concurrent manifest generation silently leaves `.staging-*` artifacts in the host tree. |

No untracked debt-marker blocker was found in the Phase 159 implementation files. The pre-existing `.planning/config.json` modification remains untouched.

### Gaps Summary

Phase 159’s goal is not achieved. The two independently reviewed and directly reproduced native-helper paths violate the core host-ownership contract: interruption can leave a partial final scaffold file, and concurrent manifest publication can leave an internal staging file while reporting success. Both problems are within the current phase’s explicit cross-cutting collision/interruption constraints, not deferred Phase 160–162 work. No later roadmap phase specifically schedules generator-write cleanup, so neither gap is deferred.

The remediation is bounded: clean up a newly created final file on every post-create failure, remove the helper-owned staging file on `EEXIST`, fail closed if cleanup itself fails, add deterministic regressions, then rerun the same focused ExUnit, Phoenix browser, and generated iOS checks from one final tree.

---

_Verified: 2026-08-01T01:35:52Z_
_Verifier: the agent (gsd-verifier)_
