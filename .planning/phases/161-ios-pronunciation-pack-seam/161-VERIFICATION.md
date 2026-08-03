---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-03T18:34:02Z
status: gaps_found
score: 14/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/20
  gaps_closed:
    - "Bundled declarations now propagate positive exact byte count and pinned SHA-256 through PackStore.bundled."
    - "Malformed required-pack references now block activation, and per-pack generations fence stale reconciliation from revocation."
    - "The generated reference adapter now checks immutable fixture bytes, promotes atomically, rereads on relaunch, and emits exact structured advisory evidence."
  gaps_remaining:
    - "Reference-host reconciliation trusts persisted inventory rather than verifying installed artifact bytes."
    - "Reference-host promotion can replace the live artifact before durable inventory persistence succeeds."
    - "The reference-host XCTest target does not build for an available iPhone simulator."
  regressions:
    - "The post-gap reference-host implementation has two integrity/atomicity defects identified by current-source inspection and an unbuildable XCTest target."
gaps:
  - truth: "A pack is available only when the current installed bytes still exactly satisfy its declared size, SHA-256, and version."
    status: failed
    reason: "PronunciationPackProvider.status returns the persisted PackInstalledRecord without locating or hashing the artifact; PackStore accepts that record as available and ActivationCoordinator then mounts the route. Deleted or changed bytes can therefore activate a route."
    artifacts:
      - path: "examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift"
        issue: "status(for:) at lines 22-25 reads inventory only; it neither checks artifact existence nor recomputes byte count/SHA-256."
      - path: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift"
        issue: "status(for:requirement:) at lines 220-233 accepts provider record flags and byte count as availability authority."
    missing:
      - "On every status/relaunch reconciliation, verify the current artifact against the supplied PackRequirement and return a closed result for absence, read failure, size mismatch, or digest mismatch."
      - "Add executable relaunch tests that delete and corrupt an installed artifact and assert activation remains requiredPack."
  - truth: "A failed replacement preserves the last known-good artifact and cannot leave inventory attesting to different bytes."
    status: failed
    reason: "The provider replaces/moves the live artifact before saveInventory. If inventory persistence fails after promotion, the method reports failure but the prior inventory can attest to the newly replaced bytes."
    artifacts:
      - path: "examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift"
        issue: "Lines 39-56 promote the artifact before durable inventory write and have no rollback path."
    missing:
      - "Make artifact and inventory publication recoverable as one transaction, restoring the former artifact on every post-promotion persistence failure (or withholding visible promotion until durable metadata is committed)."
      - "Add a deterministic injected inventory-write-failure replacement test with a fresh status/relaunch assertion."
  - truth: "The reference host supplies a runnable foreground iOS installation path with executable XCTest evidence."
    status: failed
    reason: "The host XCTest command fails on an available iPhone simulator even with isolated DerivedData: CrosswakeShell is compiled for x86_64 while CrosswakeShellCore is emitted only as arm64 simulator module, so the module cannot be resolved."
    artifacts:
      - path: "examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj"
        issue: "Current simulator build configuration does not produce a CrosswakeShellCore module usable by every architecture Xcode compiles for the target."
    missing:
      - "Correct the target/package architecture configuration and make the focused PronunciationPackProvider XCTest target pass on a clean available iPhone simulator."
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated availability with one host-supplied foreground iOS install path that verifies and atomically installs real bytes.
**Verified:** 2026-08-03T18:34:02Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Versioned requirement-bound status/install/invalidate provider has closed results. | ✓ VERIFIED | `PackProvider.swift:3-84` exposes only v1, requirement-bound closed results. `swift test` passed 27/27. |
| 2 | Real fixture bytes reach activation only after exact integrity, atomic promotion, persistence, and fresh reconciliation. | ✗ FAILED | Fresh reconciliation is not byte-backed: host `status(for:)` returns persisted inventory alone (`PronunciationPackProvider.swift:22-25`). |
| 3 | Cold launch and route reads use current reconciled inventory, never timed or legacy availability. | ✗ FAILED | Route gating is wired, but a deleted or tampered promoted artifact retains a persisted available record and can pass `PackStore` into activation. |
| 4 | Core/provider ownership is narrow and excludes host transport/storage/playback details. | ✓ VERIFIED | Core provider has only `status`, `install`, and `invalidate`; authority scan found no transport, CDN, codec, playback, or storage-budget API. |
| 5 | Host installer stages, verifies, atomically promotes, and persists only after commit. | ✗ FAILED | Lines 39-56 replace the live file before inventory persistence and provide no rollback on persistence failure. |
| 6 | Install/invalidate are serialized and reconciliation cannot fabricate availability. | ✓ VERIFIED | `PackStore.swift:127-216` captures per-pack generations and tests cover stale/overlapping invalidation; package suite passes. |
| 7 | Failed replacement preserves known-good bytes and a newer declaration remains stale/blocked. | ✗ FAILED | A failure after file promotion can destroy the known-good artifact while old inventory remains. |
| 8 | Revocation persists and remains blocked until the same successful invalidation/reinstall confirms it. | ✓ VERIFIED | Current `clearRevocation` is limited to same-generation `.notInstalled` invalidation or `.available` reinstall (`PackStore.swift:183-204`), covered by focused tests. |
| 9 | Reference host injects a working private exact requirement/provider configuration. | ✗ FAILED | Source injection and bundled metadata are present, but the focused host XCTest target fails to compile on an available simulator with a CrosswakeShellCore architecture mismatch. |
| 10 | Reference UI exposes closed state, one foreground recovery action, and stable accessibility semantics. | ✓ VERIFIED | `RequiredPackView` is connected to coordinator callbacks and focused UI-contract tests exist; no blank recovery branch found. |
| 11 | Install/Update/Retry/Invalidate-then-Install are foreground-only, with no automatic retry or second runtime owner. | ✓ VERIFIED | Closed UI action mapping and coordinator callbacks are foreground `async` actions; no background continuation found. |
| 12 | Dynamic Type, text-plus-color, system colors, and accessible status/actions are implemented. | ✓ VERIFIED | Reference view and generated UI contract test use semantic labels and Accessibility XXXL layout assertions. |
| 13 | Existing generated lane proves missing-provider denial, verified install, relaunch reconciliation, and offline pronunciation use. | ✓ VERIFIED | `ProofLaneDriver.swift.eex:60-137` verifies fixture/readback; contract tests invoke install, relaunch, and networking-disabled read. |
| 14 | Public provider has no playback/asset API and separate host proof operation exercises installed offline audio. | ✓ VERIFIED | Core remains narrow; generated host operation requires `CROSSWAKE_PROOF_LANE_NETWORK_DISABLED=1` and reads verified installed bytes. |
| 15 | `pack_audio_prerequisite` passes only from immutable bytes and exact adapter-derived advisory evidence. | ✓ VERIFIED | Script requires exact six-ID JSON schema before emitting `PL-IOS-PACK-AUDIO-ADVISORY`; ExUnit verifier suite passes. |
| 16 | Retained evidence rejects private/raw proof values and keeps closed outcomes only. | ✓ VERIFIED | `evidence_test.exs` exercises private/raw candidate rejection; focused ExUnit suite passes 40/40. |
| 17 | A final tree proves provider, atomic/reconciliation, invalid paths, revocation, UI, and generated audio lane together. | ✗ FAILED | The retained gate is not sufficient evidence: current source has the two host integrity defects and the host XCTest target cannot build. |
| 18 | Validation/evidence retain only approved IDs, closed states, aggregate results, and closed outcomes. | ✓ VERIFIED | Validation/COVERAGE artifacts contain aggregate and closed state values; focused evidence tests pass. |
| 19 | Simulator proof is advisory; Phase 162 alone owns physical-iPhone/adopter promotion and TODO-002 remains blocked. | ✓ VERIFIED | Script emits advisory-only result and ROADMAP assigns physical-iPhone proof to Phase 162. |
| 20 | The in-process protocol is accurately declared as no external API integration. | ✓ VERIFIED | `COVERAGE.md` declares the in-process Swift protocol/local fixture boundary; no external SDK or service was added. |

**Score:** 14/20 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `PackProvider.swift` | Closed versioned core contract | ✓ VERIFIED | Exists, substantive, and wired into `PackStore`. |
| `PackStore.swift` | Validated required-pack gate and generation fence | ✓ VERIFIED | Bundled exact metadata, total reference resolution, and fencing are wired and tested. |
| `PronunciationPackProvider.swift` | Host verified atomic installer/reconciler | ✗ FAILED | Installer streams and hashes staged bytes, but reconciliation does not verify installed bytes and promotion precedes durable inventory. |
| `CrosswakeShellApp.swift` | Reference-host composition | ⚠️ PARTIAL | Provider injection is present, but the executable host XCTest target fails to build. |
| `ProofLaneDriver.swift.eex` | Fixture-backed advisory install/readback/audio operation | ✓ VERIFIED | Artifact-backed exact checks and networking-disabled installed-byte read are implemented. |
| `verify_generated_ios_shell.sh` | Structured advisory evidence gate | ✓ VERIFIED | Requires the exact allowlisted schema before advisory pass. |
| `evidence_test.exs`, `COVERAGE.md`, `161-VALIDATION.md` | Privacy/no-external-API seal | ✓ VERIFIED | Substantive and exercised by the focused ExUnit suite. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| bundled declaration | `PackStore.bundled` | validated exact requirement decoding | ✓ WIRED | `validatedRequirement()` requires positive byte count and 64-character lowercase digest. |
| `PackStore` mutation | provider completion | captured generation before state writes | ✓ WIRED | `beginMutation`/`isCurrent` guard every awaited result path. |
| provider status | route activation | reconciled `RequiredPackStatus` → `blockingStatus` → coordinator | ✗ FAILED | Persisted record can describe absent/tampered bytes; coordinator then accepts `.available`. |
| provider promotion | durable inventory | promoted artifact plus inventory record | ✗ FAILED | Artifact changes before `saveInventory`, without transaction/rollback. |
| generated adapter | advisory verifier outcome | exact structured evidence document | ✓ WIRED | Test creates the exact schema only after adapter operations; script accepts no marker-only substitute. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PackStore` | `PackRequirement` | bundled JSON → validated requirement → provider | Yes | ✓ FLOWING |
| host provider install | staged file / installed record | fixture source → stage/hash → destination/inventory | Partially | ⚠️ The staging bytes are real and verified, but a persistence failure can split file and record. |
| host provider status | installed record | inventory JSON only | No current-byte attestation | ✗ DISCONNECTED |
| generated proof adapter | installed artifact | immutable fixture → stage/promote → relaunch readback | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core provider/gate/revocation contracts | `swift test --package-path packages/crosswake-shell-core-ios` | 27 tests, 0 failures | ✓ PASS |
| Evidence/template/generated-verifier contracts | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | 40 tests, 0 failures | ✓ PASS |
| Reference host provider XCTest | `xcodebuild test ... -only-testing:CrosswakeShellTests/PronunciationPackProviderTests` | failed in both normal and isolated DerivedData: `CrosswakeShellCore` module architecture incompatible/unresolved | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — this phase declares no `scripts/*/tests/probe-*.sh` probe. The generated-iOS verifier is covered by its focused ExUnit contract suite above.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PACK-01 | 01, 03-06, 08-09 | Host-supplied foreground status/install/invalidate seam | ✗ BLOCKED | Seam is source-wired, but its reference host XCTest target does not build in a clean simulator target. |
| PACK-02 | 01-03, 05-07, 09 | Invalid/unconfigured paths never report available | ✗ BLOCKED | Persisted record can report available after file deletion/tampering. |
| PACK-03 | 01-02, 04-06, 08-09 | Immutable archive only after exact size/SHA-256 and atomic installation | ✗ BLOCKED | Pre-persistence artifact promotion can leave inventory attesting to replaced bytes; status does not reverify bytes. |
| PACK-04 | 01-09 | Explicit Crosswake/host ownership boundary | ✓ SATISFIED | Core protocol remains requirement/result-only; host owns source and local storage. |
| PACK-05 | 03-06, 08-09 | Stop-list remains explicitly unclaimed | ✓ SATISFIED | No Android/background/delta/generic-storage claim or implementation; simulator outcome is advisory and Phase 162 retains device promotion. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `PronunciationPackProvider.swift` | 22-25 | Inventory-only availability attestation | 🛑 BLOCKER | Missing or modified promoted bytes can silently activate a route. |
| `PronunciationPackProvider.swift` | 39-56 | Promotion before durable inventory commit | 🛑 BLOCKER | Failed replacement can destroy known-good bytes and leave stale metadata. |
| `CrosswakeShell.xcodeproj/project.pbxproj` | simulator target configuration | Cross-architecture core module mismatch | 🛑 BLOCKER | Reference-host executable proof cannot build. |

### Gaps Summary

Phase 161 is still blocked. The gap-closure work correctly repaired the earlier bundled-metadata, malformed-reference, revocation-fence, and marker-only proof defects. However, the current reference host still treats inventory metadata as an attestation of immutable installed bytes, and it makes bytes visible before its matching record is durably persisted. Those paths contradict the phase goal's verified/atomic availability contract. The available simulator also cannot build the focused host XCTest target, so the reference implementation has no executable evidence in its intended host context.

Phase 162 is limited to physical-iPhone adoption proof; its stated success criteria do not cover correcting these implementation defects. No gaps are deferred.

_Verified: 2026-08-03T18:34:02Z_
_Verifier: the agent (gsd-verifier)_
