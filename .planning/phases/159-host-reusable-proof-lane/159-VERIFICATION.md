---
phase: 159-host-reusable-proof-lane
verified: 2026-07-31T21:15:04Z
status: gaps_found
score: 0/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Generation is non-destructive and supports a diff/check mode."
    status: failed
    reason: "Config accepts an arbitrary absolute ios_shell_root; Generator derives its host root by removing two components, allowing output outside the intended host (including filesystem root)."
    artifacts:
      - path: "lib/crosswake/proof_lane/config.ex"
        issue: "safe_absolute_path?/1 accepts /tmp/not-the-native-ios-root."
      - path: "lib/crosswake/proof_lane/generator.ex"
        issue: "host_root/1 uses two Path.dirname calls without proving a native/ios suffix or non-root destination."
    missing:
      - "Validate ios_shell_root as a contained normalized native/ios path and reject derived root /."
  - truth: "Existing browser tests and fixtures remain the primary web/island coverage."
    status: failed
    reason: "The extracted example-host browser proof cannot type-check because it references an undefined capturedId."
    artifacts:
      - path: "examples/phoenix_host/e2e/support/offline_route_proof.ts"
        issue: "Line 244 uses capturedId without a declaration."
    missing:
      - "Retain the mutation ID returned by runOfflineIslandProof or otherwise define it before the history assertion, with a TypeScript regression check."
  - truth: "Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio."
    status: failed
    reason: "The proof-lane verifier returns exit 0 when generated proof targets cannot be built, making an unavailable prerequisite appear as successful verification."
    artifacts:
      - path: "script/verify_generated_ios_shell.sh"
        issue: "Proof-lane branches at lines 124-148 emit advisory text and exit 0 after target enumeration/build failure."
    missing:
      - "Return a distinct non-zero blocked/unavailable result (with machine-readable outcome) whenever the proof target cannot be enumerated or built."
  - truth: "Evidence generation fails when sensitive payload or identity fields appear."
    status: failed
    reason: "The retained evidence schema accepts account-like identifiers in commit_ref and arbitrary caller-supplied evidence_json digests, which can fingerprint sensitive data."
    artifacts:
      - path: "lib/crosswake/proof_lane/evidence.ex"
        issue: "valid_versions/1 accepts alice_123 and valid_hashes/1 accepts any labelled 64-hex digest without binding it to canonical sanitized bytes."
    missing:
      - "Constrain retained revision/assertion identifiers to closed safe forms and compute or verify every retained digest from an allowlisted canonical artifact."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding while preserving existing browser tests and keeping physical-device support non-promoting until later evidence.
**Verified:** 2026-07-31T21:15:04Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports a diff/check mode. | ✗ FAILED | `Config.normalize/1` accepted `/tmp/not-the-native-ios-root`; `Generator.host_root/1` then strips two components, so the effective root is `/`. Generation could target `/e2e`, `/test`, and `/.crosswake`, outside the configured host. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ✗ FAILED | TypeScript compilation reports `TS2304: Cannot find name 'capturedId'` at `offline_route_proof.ts:244`; the primary browser proof module is not runnable. |
| 3 | Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio. | ✗ FAILED | `bash script/verify_generated_ios_shell.sh --proof-lane` printed an advisory that targets were not built and exited `0`. An unavailable proof prerequisite is therefore a green command result. |
| 4 | Evidence generation fails when sensitive payload or identity fields appear. | ✗ FAILED | `Evidence.build/1` accepted `commit_ref: "alice_123"`, `assertion_ids: ["unreviewed_identifier"]`, and a caller-selected 64-hex digest. These are retained in evidence JSON despite not being safe closed values or verified sanitized bytes. |

**Score:** 0/4 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` | iOS generator and action selection | ✓ VERIFIED | Substantive CLI dispatches `generate`, `check`, and `diff`; normalizes config before dispatch. |
| `lib/crosswake/proof_lane/config.ex` | Closed normalization boundary | ✗ FAILED | Exists and is called, but accepts unsafe absolute iOS roots without requiring `native/ios`. |
| `lib/crosswake/proof_lane/generator.ex` | Missing-only host rendering | ✗ FAILED | Exclusive file creation preserves valid-host paths, but unsafe config permits writes outside the intended host. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed safe evidence and promotion | ✗ FAILED | Exact-key schema and final scan exist, but retained identity-like values and arbitrary hashes are accepted; promotion also has a check-then-rename collision window. |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | Primary browser semantic wrapper | ✗ STUB | Substantive source calls `runOfflineIslandProof`, but its undefined `capturedId` makes the wrapper fail compilation/runtime. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | Reusable offline-island sequence | ⚠️ PARTIAL | Rendered sequence is wired, but lacks `try/finally`; a failed offline proof leaves the shared browser context offline. |
| iOS XCTest/XCUITest templates | Proof-owned native target graph | ⚠️ PARTIAL | Templates declare explicit blocked/unavailable prerequisite outcomes and targets, but their verifier fails open when they cannot be built. |
| `script/verify_generated_ios_shell.sh` | Generated-target verification | ✗ FAILED | Proof-lane xcodebuild failure/unavailability exits 0 rather than a blocked/unavailable failure result. |
| `test/mix/tasks/crosswake_gen_proof_lane_test.exs` | Lifecycle regression coverage | ⚠️ PARTIAL | 22 focused tests pass, but none covers an arbitrary accepted shell root or the browser TypeScript compilation boundary. |
| `test/crosswake/proof_lane/evidence_test.exs` | Evidence privacy regression coverage | ⚠️ PARTIAL | Tests pass but only use keyword-based sensitive canaries; they do not reject account-like values without sensitive substrings or unverified supplied digests. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Mix.Tasks.Crosswake.Gen.ProofLane.run/1` | `Config.normalize/1` | config loading | ✓ WIRED | Task calls `Config.normalize(config)` at line 69 before generator operations. |
| `Generator.generate/1` | proof-lane EEx templates | normalized config assigns | ⚠️ HOLLOW | `render/2` supplies config to all templates, but the accepted unsafe root invalidates containment. |
| generated browser wrapper | `runOfflineIslandProof` | adapter delegation | ✗ NOT_WIRED | The call exists, but the wrapper's subsequent undefined identifier prevents its proof from executing. |
| generated iOS target graph | `verify_generated_ios_shell.sh` | enumerate/build-for-testing | ✗ NOT_WIRED | The script finds targets but treats graph/build failure as exit-0 success. |
| `Evidence.build/1` | `Evidence.to_map/1` | explicit serializer | ⚠️ PARTIAL | Connection exists, but pre-serialization validation is too permissive for retained identity/hash data. |
| `Evidence.promote/2` | `Evidence.scan_stage/1` | final-stage scan then rename | ⚠️ PARTIAL | Scan is called, but `absent(destination)` before staging is a TOCTOU check; a concurrent empty destination can be replaced by rename. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generator | rendered `destination` paths | normalized `ios_shell_root` | No safe containment guarantee | ✗ HOLLOW |
| Browser proof | mutation ID/history assertion | `runOfflineIslandProof` adapter result | Undefined local `capturedId` at assertion | ✗ DISCONNECTED |
| Evidence | `commit_ref`, `assertion_ids`, `approved_hashes` | caller map | Caller-controlled retained values; digest is not bound to approved bytes | ✗ HOLLOW |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused proof-lane regressions | `mix test test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` | 22 tests, 0 failures | ✓ PASS (insufficient coverage) |
| Unsafe root is rejected | `mix run -e 'Config.normalize(... ios_shell_root: "/tmp/not-the-native-ios-root")'` | Returned `{:ok, %Config{...}}` | ✗ FAIL |
| Identity-like values and arbitrary hash are rejected | `mix run -e 'Evidence.build(... commit_ref: "alice_123", approved_hashes: [...])'` | Returned `{:ok, %Evidence{...}}` | ✗ FAIL |
| Browser proof type-checks | `examples/phoenix_host/node_modules/.bin/tsc --noEmit ... e2e/support/offline_route_proof.ts` | `TS2304` for `capturedId` (also existing Node/window ambient-type errors) | ✗ FAIL |
| Unavailable generated iOS proof is non-passing | `bash script/verify_generated_ios_shell.sh --proof-lane` | Printed advisory “targets were not built” and exited 0 | ✗ FAIL |

## Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` files were found.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159-01, 159-02, 159-03 | Non-overwriting ExUnit, Playwright, shell, and device scaffold | ✗ BLOCKED | Unsafe accepted root can redirect scaffold output outside the host; collision safety is not established for that boundary. |
| PROOF-02 | 159-01, 159-02 | Exact route/storage/mutation/endpoint/router/shell configuration | ✗ BLOCKED | Nine keys normalize, but `ios_shell_root` is semantically under-validated and violates host confinement. |
| PROOF-03 | 159-01, 159-03 | Preserve existing browser/unit/fixture corpus; add only unavailable boundaries | ✗ BLOCKED | Existing browser support module has an undefined identifier and cannot type-check. |
| PROOF-04 | 159-01, 159-04 | Reject raw payloads, account identifiers, media, tokens, stable device identifiers | ✗ BLOCKED | Retained schema accepts account-like IDs and arbitrary evidence digest fingerprints. |

No orphaned Phase 159 requirements were found: all four roadmap IDs are declared by plan frontmatter.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | 244 | Undefined `capturedId` | 🛑 BLOCKER | Browser proof cannot compile/run. |
| `script/verify_generated_ios_shell.sh` | 124-148 | Advisory plus exit 0 on proof build failure | 🛑 BLOCKER | Unavailable proof is reported as successful command execution. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | 31-42 | No cleanup around `context.setOffline(true)` | ⚠️ WARNING | Failed proof contaminates shared browser state. |
| `lib/crosswake/proof_lane/evidence.ex` | 374-390 | Check-then-rename promotion | 🛑 BLOCKER | Concurrent empty destination can be clobbered after the absence check. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in phase-modified implementation files.

## Gaps Summary

The phase goal is not achieved. All roadmap success criteria fail under executable or direct source evidence. The passing focused ExUnit suite is misleading because it omits the unsafe-root, arbitrary-identifier/hash, browser compilation, and iOS-verifier exit-status cases. These gaps are not deferred: later phases depend on this proof lane and do not own making its generator, primary browser corpus, or retained evidence safe.

_Verified: 2026-07-31T21:15:04Z_
_Verifier: the agent (gsd-verifier)_
