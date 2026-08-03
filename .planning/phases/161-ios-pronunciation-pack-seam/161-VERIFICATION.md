---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-03T20:07:04Z
status: gaps_found
score: 14/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 14/20
  gaps_closed:
    - "Current provider status now attests installed bytes on every reconciliation and the clean simulator XCTest target builds."
    - "Post-promotion inventory-write failure rolls back the staged replacement or removes an uncommitted first install."
  gaps_remaining:
    - "Generated proof can assert networking_disabled without enforcing or observing network denial."
    - "A staged-to-live promotion move failure deletes the retained known-good artifact."
  regressions:
    - "Fresh code review CR-01 and WR-01 invalidate the generated proof and atomic-replacement claims despite passing focused tests."
gaps:
  - truth: "The generated host-owned pronunciation operation requires an explicit networking-disabled condition and performs a deterministic installed-artifact read; network-dependent operation remains blocked."
    status: failed
    reason: "The generated reference adapter never reads or enforces CROSSWAKE_PROOF_LANE_NETWORK_DISABLED. The UI test only sets the environment variable, while the contract test unconditionally emits networking_disabled and the shell verifier accepts that marker."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex"
        issue: "ProofLanePackEvidence.networkingDisabled is unused; installed audio reads local bytes without a failing transport or observed network-denial mechanism."
      - path: "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex"
        issue: "emitStructuredEvidence unconditionally includes networking_disabled."
    missing:
      - "Either prove offline behavior with an injectable transport that is available for install and deterministically fails after relaunch, or remove networking_disabled from this advisory evidence and narrow the claim."
      - "Add a regression that fails if installed-audio proof invokes the transport after network denial."
  - truth: "A failed replacement preserves last-known-good bytes and atomic publication never destroys a committed winner."
    status: failed
    reason: "During replacement, install moves the live artifact to retainedArtifact and then moves staging to destination. If the second move throws, the outer catch returns atomicInstallFailed and defer deletes retainedArtifact; no rollback occurs."
    artifacts:
      - path: "examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift"
        issue: "Lines 76-80 perform the two promotion moves, but lines 106-108 return from the outer catch without rollback; line 63 deletes the retained artifact."
    missing:
      - "Make all publication moves plus inventory persistence one rollback-protected transaction, including staged-to-destination move failure."
      - "Add deterministic move-failure XCTest coverage that asserts prior bytes and inventory survive immediate and relaunched status checks."
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated pronunciation-pack availability with one narrow host-supplied foreground iOS adapter that verifies exact size/SHA-256, installs atomically, preserves explicit ownership/fail-closed outcomes, and does not widen into generic storage or physical-device claims.

**Verified:** 2026-08-03T20:07:04Z
**Status:** gaps_found
**Re-verification:** Yes — final-tree check after Plan 161-10/11

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Versioned requirement-bound status/install/invalidate provider has closed results. | ✓ VERIFIED | `PackProvider.swift` exposes only the v1 requirement/result protocol; `swift test` passed 27/27. |
| 2 | Real bytes reach activation only after exact integrity, atomic promotion, persistence, and fresh reconciliation. | ✗ FAILED | Exact size/digest and fresh status work, but replacement publication is not atomic on the second move failure. |
| 3 | Cold launch and route reads consume only current reconciled inventory. | ✓ VERIFIED | `status(for:)` reopens and hashes the destination; deletion/corruption/relaunch tests pass in focused XCTest. |
| 4 | Core/provider ownership is narrow and excludes host transport/storage/playback details. | ✓ VERIFIED | Core exposes only status/install/invalidate; no pack URL, credential, archive layout, codec, playback, or storage-budget API exists. |
| 5 | Host installer stages, verifies, atomically promotes, and persists safely. | ✗ FAILED | `install` has rollback for inventory-write failure, but not for the staged-to-destination promotion failure. |
| 6 | Install/invalidate are serialized and reconciliation cannot fabricate availability. | ✓ VERIFIED | `PackStore` per-pack generations and focused package tests cover stale/overlapping paths. |
| 7 | Failed replacement preserves known-good bytes and newer declarations stay blocked. | ✗ FAILED | WR-01 is directly reproducible by control flow: outer catch skips rollback and deferred cleanup deletes the saved artifact. |
| 8 | Revocation persists and remains blocked until confirmed invalidation or verified reinstall. | ✓ VERIFIED | `PackStore` revocation tests pass. |
| 9 | Reference host injects a working private exact provider configuration. | ✓ VERIFIED | Clean iPhone 17 simulator XCTest passed 11 concrete-provider tests with no architecture override. |
| 10 | Reference UI exposes closed state and one foreground recovery action with stable accessibility semantics. | ✓ VERIFIED | Clean focused `RequiredPackViewTests` passed 5/5. |
| 11 | Recovery remains foreground-only with no automatic retry or second runtime owner. | ✓ VERIFIED | Closed action mapping and coordinator callbacks are explicit; no pack background continuation was found. |
| 12 | Dynamic Type and accessible status/actions are implemented. | ✓ VERIFIED | View tests and source establish semantic labels, 44pt controls, system colors, and no animation-based transition. |
| 13 | Generated lane proves missing-provider denial, verified install/relaunch, and offline pronunciation use. | ✗ FAILED | CR-01: the claimed networking-disabled portion is fabricated by test output, not adapter behavior. |
| 14 | Public provider has no playback/asset API; host proof reads installed audio. | ✓ VERIFIED | The core contract remains narrow and the proof operation reads a verified installed artifact. |
| 15 | `pack_audio_prerequisite` passes only from immutable bytes and exact adapter-derived advisory evidence. | ✗ FAILED | The verifier accepts a six-ID document whose `networking_disabled` ID is printed unconditionally. |
| 16 | Retained evidence rejects private/raw proof values and preserves closed outcomes. | ✓ VERIFIED | Focused ExUnit evidence/template/verifier suite passed 40/40. |
| 17 | A final tree proves provider, atomic/reconciliation, invalid paths, revocation, UI, and generated audio lane together. | ✗ FAILED | CR-01 and WR-01 contradict this final-tree assertion. |
| 18 | Validation/evidence retain only approved IDs, aggregate results, and closed outcomes. | ✓ VERIFIED | `161-VALIDATION.md` and evidence tests retain aggregate/closed values only. |
| 19 | Simulator proof is advisory; Phase 162 alone owns physical-iPhone/adopter promotion. | ✓ VERIFIED | ROADMAP/VALIDATION retain advisory wording, TODO-002 unknown_blocking, and Phase 162 ownership. |
| 20 | The in-process protocol is accurately declared as no external API integration. | ✓ VERIFIED | `COVERAGE.md` retains the in-process Swift/local-fixture declaration; no external service was added. |

**Score:** 14/20 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `PackProvider.swift` / `PackStore.swift` | Closed core contract and route gate | ✓ VERIFIED | Substantive, wired, and package suite passes. |
| `PronunciationPackProvider.swift` | Byte-attesting atomic host installer | ✗ FAILED | Reconciliation is byte-backed and inventory-write rollback works, but move-failure rollback is absent. |
| `CrosswakeShellApp.swift` / `RequiredPackView.swift` | Host composition and foreground UI | ✓ VERIFIED | Concrete simulator/provider and UI tests pass. |
| `ProofLaneDriver.swift.eex` | Advisory real-byte/audio proof | ✗ FAILED | It exposes a proof claim its implementation does not observe. |
| `verify_generated_ios_shell.sh` | Exact advisory evidence verifier | ✗ FAILED | Its exact schema permits the false `networking_disabled` assertion. |
| `161-VALIDATION.md` / `COVERAGE.md` | Privacy-safe evidence/no-external-API seal | ✓ VERIFIED | Aggregate-only validation and exact coverage declaration remain intact. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Pack requirement | provider status | current-artifact size/digest attestation | ✓ WIRED | `status(for:)` verifies the destination against supplied requirement. |
| provider status | route activation | `PackStore` reconciled status → blocking gate | ✓ WIRED | Deleted and corrupt artifact XCTest paths remain route-blocking. |
| provider promotion | durable inventory | stage → promote → inventory/rollback | ✗ FAILED | Move failure bypasses `rollbackPublication`. |
| generated adapter | `networking_disabled` evidence | observed denied-network audio operation | ✗ NOT WIRED | Environment variable is not consumed by the driver; test emits the ID directly. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PackStore` | `PackRequirement` | bundled declaration → provider | Yes | ✓ FLOWING |
| host provider status | installed destination bytes | private artifact → streamed verifier | Yes | ✓ FLOWING |
| host provider replacement | staged/live artifact plus inventory | staging → two moves → persistence | No on second move failure | ✗ HOLLOW TRANSACTION |
| generated audio evidence | `networking_disabled` assertion | unconditional XCTest JSON | No observed condition | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core pack contract/gate/revocation | `swift test --package-path packages/crosswake-shell-core-ios` | 27 tests, 0 failures | ✓ PASS |
| Evidence/template/generated-verifier contracts | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | 40 tests, 0 failures | ✓ PASS — insufficient for CR-01 |
| Concrete host provider | clean iPhone 17 `xcodebuild ... -only-testing:CrosswakeShellTests/PronunciationPackProviderTests` | 11 tests, 0 failures | ✓ PASS — lacks move-failure test |
| Required-pack UI contract | clean iPhone 17 `xcodebuild ... -only-testing:CrosswakeShellTests/RequiredPackViewTests` | 5 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PACK-01 | 01–11 | Host foreground status/install/invalidate seam | ✓ SATISFIED | Closed v1 seam, concrete injection, and clean focused XCTest pass. |
| PACK-02 | 01–11 | Invalid/unconfigured paths never report available | ✓ SATISFIED | Nil/malformed/current-byte/revocation paths remain closed under focused tests. |
| PACK-03 | 01–11 | Immutable archive is available only after exact verification and atomic installation | ✗ BLOCKED | Replacement can destroy the committed prior artifact when second promotion move fails. |
| PACK-04 | 01–11 | Explicit Crosswake/host ownership | ✓ SATISFIED | Core interface is narrow; host owns local acquisition and mechanics. |
| PACK-05 | 03–11 | Stop-list remains explicitly unclaimed | ✓ SATISFIED | No Android/background/delta/eviction/generic-storage expansion; simulator output remains advisory and Phase 162 owns device promotion. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `ProofLaneDriver.swift.eex` | 40–43, 92–98 | Unused networkingDisabled and local-only “offline” read | 🛑 BLOCKER | CR-01: generated evidence dishonestly certifies network denial. |
| `ProofLaneContractTests.swift.eex` | 44–57 | Unconditional `networking_disabled` evidence ID | 🛑 BLOCKER | Verifier can pass without the asserted condition. |
| `PronunciationPackProvider.swift` | 76–80, 106–108 | Promotion failure bypasses rollback; defer deletes retained artifact | 🛑 BLOCKER | WR-01 breaks atomic replacement/known-good preservation. |

### Review-Finding Disposition

- **CR-01 — BLOCKER.** Confirmed by final-source trace: neither the driver nor the adapter consumes `CROSSWAKE_PROOF_LANE_NETWORK_DISABLED`, while contract-test JSON always asserts it. This violates Plan 161-04/08/09/11 evidence-honesty must-haves. Advisory status does not excuse a false advisory assertion.
- **WR-01 — BLOCKER.** Confirmed by final-source trace: the existing inventory-write rollback does not cover a throw from `moveItem(staging, destination)`. This violates the phase’s atomic-replacement and last-known-good guarantees.

### Gaps Summary

The final tree repaired the previous current-byte attestation, inventory-write rollback, and simulator architecture gaps, and the associated focused tests now pass. It still misses the phase goal in two observable paths: replacement is not rollback-safe for every publication failure, and the generated lane records a network-disabled assertion that it never proves. These are implementation/evidence defects, not Phase 162 physical-device work; they must not be deferred to Phase 162.

**Next action:** revision/escalation gate — create targeted gap-closure plans, then re-run Phase 161 verification.
**Next command:** `$gsd-plan-phase 161 --gaps`

_Verified: 2026-08-03T20:07:04Z_
_Verifier: the agent (gsd-verifier)_
