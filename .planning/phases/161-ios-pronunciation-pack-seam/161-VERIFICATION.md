---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-03T21:25:19Z
status: gaps_found
score: 19/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 14/20
  gaps_closed:
    - "Generated advisory evidence now derives from an actual deny-only URLSession operation and installed-byte read."
    - "Thrown staged-to-live move failures restore the prior artifact and inventory."
  gaps_remaining:
    - "Replacement publication is not crash-atomic: termination after retaining the old artifact has no durable journal or startup recovery."
  regressions:
    - "The post-161-14 code review's crash-atomicity finding is confirmed independently."
gaps:
  - truth: "A host-supplied foreground install atomically installs real bytes and preserves the last known-good publication through interruption."
    status: failed
    reason: "The provider separates old-artifact retention, staged-to-live promotion, and inventory persistence without durable transaction state or startup recovery. A crash/kill after the old artifact is moved aside can strand .previous-* with no destination; a crash after promotion before inventory commit can leave an artifact/inventory mismatch."
    artifacts:
      - path: "examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift"
        issue: "install() uses only in-process catch/defer rollback; status() reads only pack-{id} and inventory.json, and no journal/recovery/fsync logic exists."
      - path: "examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift"
        issue: "Covers injected thrown move and inventory-write failures only; it does not seed/recover any interruption state between publication steps."
    missing:
      - "Use an OS-supported crash-atomic replacement plus recoverable inventory commit, or persist and fsync a non-sensitive replacement journal before every move and recover it before status/install."
      - "Add deterministic restart tests for retained-old, promoted-new/inventory-pending, and inventory-commit recovery states."
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated availability with one host-supplied foreground iOS install path that verifies and atomically installs real bytes.

**Verified:** 2026-08-03T21:25:19Z  
**Status:** gaps_found  
**Re-verification:** Yes — after Plan 161-12 through 161-14 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The v1 provider exposes only requirement-bound async status/install/invalidate with closed outcomes; nil, malformed, cancelled, and failed results stay blocked. | ✓ VERIFIED | `PackProvider.swift` defines the three-method protocol and closed result/reason types; fresh `swift test` passed 27/27, including nil-provider, malformed, and fresh-status tests. |
| 2 | A verified immutable fixture can unblock activation only after exact count/digest, promotion attestation, and fresh status. | ✓ VERIFIED | `PackStore.status(for:)` rejects all mismatches before `.available`; fresh `PackProviderFixtureTests` passed 3/3, including acknowledgement-without-fresh-status denial. |
| 3 | Cold start and route resolution consume reconciled inventory rather than timestamps, staging, acknowledgement, or legacy inventory. | ✓ VERIFIED | `PackStore` begins provider-backed declarations at `.checking`; `ActivationCoordinator.bootstrapIfNeeded()` reconciles asynchronously, while `blockingStatus(for:)` gates route resolution. Fresh core suite passed. |
| 4 | Crosswake/host ownership remains narrow. | ✓ VERIFIED | Core public provider values contain no transport, credential, location, archive-layout, codec, retention, UI, playback, or raw-error member; the host-private provider owns acquisition and files. |
| 5 | Host installation is atomic across interruption and preserves a committed known-good publication. | ✗ FAILED | See crash-atomicity gap below. Ordinary thrown-error rollback is covered, but process interruption is not recoverable. |
| 6 | Invalid, stale, revoked, overlapping, and unreconciled media cannot activate a route. | ✓ VERIFIED | Generation fencing/revocation are in `PackStore`; fresh `PackStoreTests` and activation tests passed. |
| 7 | Reference-host and generated proof exercise real local bytes without widening the provider API. | ✓ VERIFIED | The generated driver hashes installed bytes and its audio exercise first observes a deny-only `URLSession` failure; exact schema-v2 transcript assertion is required by the shell verifier. This remains advisory only. |
| 8 | Advisory evidence and diagnostics retain only closed, privacy-safe facts. | ✓ VERIFIED | Fresh focused ExUnit proof/evidence/template/verifier suite passed 41/41; validation records aggregate outcomes only. |
| 9 | Simulator/reference-adapter output cannot promote physical-iPhone or adopter claims. | ✓ VERIFIED | `161-VALIDATION.md`, ROADMAP, and STATE keep the result simulator-advisory, retain TODO-002/adopter-instance `unknown_blocking`, and assign physical-iPhone promotion only to Phase 162. |
| 10 | PACK-05's stop list remains a non-claim. | ✓ VERIFIED | No Phase 161 core/provider surface adds Android storage, background transfer, delta/eviction, generic distribution/storage, scoring, or capture; the validation boundary explicitly preserves this exclusion. |

**Score:** 19/20 must-haves verified (0 present, behavior-unverified)

### Plan Must-Have Audit

All 14 PLAN frontmatters were inspected. Their declared requirement IDs are exactly PACK-01 through PACK-05. The core/provider, reference-host/UI, generated-proof/evidence, and final-gate must-haves are substantively implemented and wired, except the shared Plan 161-02/12/14 atomic-publication truth: current code is rollback-safe only while the process survives. This one failed truth also invalidates Plan 161-14's claimed complete same-tree closure.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `PackProvider.swift` | Closed v1 provider seam | ✓ VERIFIED | Exists, substantive, consumed by `PackStore` and host provider. |
| `PackStore.swift` | Checking-first reconciled inventory and activation-facing denial | ✓ VERIFIED | Exists, substantive, wired to `ActivationCoordinator`; fresh package tests pass. |
| `PronunciationPackProvider.swift` | Host-private verified atomic installer | ✗ FAILED | Real-byte staging/verification and caught-error rollback exist, but no crash-safe transaction/recovery exists. |
| `PronunciationPackProviderTests.swift` | Host installation and restart regression coverage | ⚠️ PARTIAL | Tests prove caught move/persistence failures and relaunch, but no crash/interruption recovery state. |
| `ProofLaneDriver.swift.eex` / contract tests / verifier | Honest advisory local-byte proof | ✓ VERIFIED | Denied transport is actually observed before the installed-byte read; evidence is operation-derived and schema-v2-gated. |
| `161-VALIDATION.md` / `COVERAGE.md` | Privacy-safe final seal and no-external-API declaration | ✓ VERIFIED | Aggregate-only facts; advisory/non-promotion boundaries remain explicit. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PackRequirement` | `PackProvider.status(for:)` | Exact v1 ID/version/count/digest binding | ✓ WIRED | `PackStore` validates returned record fields before available. |
| `PackProvider.install(_:)` | fresh `PackStore.reconcile` | Install acknowledgement is followed by status | ✓ WIRED | `installRequiredPack` only clears through reconciliation. |
| `PackStore.statuses` | `ActivationCoordinator.resolve` | `blockingStatus(for:)` gate | ✓ WIRED | Fresh activation tests show missing/invalid references cannot reach LiveView. |
| host staging | provider status | Re-attestation of destination bytes | ✓ WIRED | `status(for:)` re-reads and verifies the destination. |
| generated audio operation | denied transport | deny-only URLSession then installed-byte read | ✓ WIRED | Driver waits for `.denied`; negative contract test rejects unexpected success. |
| observed evidence | advisory result | Exact ordered schema-v2 transcript comparison | ✓ WIRED | `verify_generated_ios_shell.sh` rejects generic test/build success. |
| retained artifact/inventory | relaunch status | Crash-safe replacement recovery | ✗ NOT WIRED | No durable state is written or inspected on startup. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PackStore` | `RequiredPackStatus` | Provider's re-attested installed record | Yes | ✓ FLOWING |
| Host provider | destination bytes | Host-private source → staged file → SHA-256/count verifier | Yes | ✓ FLOWING |
| Replacement publication | destination plus inventory | Separate old-retain, new-promote, inventory-write operations | No durable interrupted-state recovery | ✗ HOLLOW TRANSACTION |
| Generated advisory proof | ordered assertion IDs | Actual denied request plus verified installed bytes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core provider, activation, invalid-reference, revocation, and real-fixture contract | `swift test --package-path packages/crosswake-shell-core-ios` | 27 tests, 0 failures | ✓ PASS |
| Evidence allowlist, generated iOS schema, and template contracts | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/template_contract_test.exs` | 41 tests, 0 failures | ✓ PASS |
| Replacement survives process termination between moves/commit | No named recovery test exists; source has no durable journal or recovery branch | Not exercised and structurally absent | ✗ FAIL |

Simulator/XCTest proof is deliberately advisory and non-promoting; it was not used to certify physical-iPhone behavior.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PACK-01 | 01, 03–06, 08–11, 13–14 | Host-supplied foreground status/install/invalidate seam | ✓ SATISFIED | Narrow v1 protocol, explicit optional injection, and fresh core tests. |
| PACK-02 | 01–07, 09–12, 14 | Invalid/unconfigured/interrupted paths never report available | ✓ SATISFIED | Closed mapping, checking-first inventory, generation fencing, and fresh core tests. |
| PACK-03 | 01–02, 04–06, 08–14 | Exact size/SHA-256 verification followed by atomic installation | ✗ BLOCKED | Verification exists, but replacement publication is not crash-atomic. |
| PACK-04 | 01–14 | Explicit Crosswake/host ownership boundary | ✓ SATISFIED | Core contract is narrow; host retains acquisition, storage, and media mechanics. |
| PACK-05 | 03–06, 08–09, 11, 13–14 | Adjacent platform/product claims remain unclaimed | ✓ SATISFIED | Explicit no-promotion/stop-list boundaries; no prohibited surface found. |

No orphaned Phase 161 requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `PronunciationPackProvider.swift` | 65–127, 151–175 | `catch`/`defer` rollback only; no persistent replacement journal or startup recovery | 🛑 BLOCKER | A kill/crash can lose the prior reachable artifact or leave artifact/inventory inconsistent. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the Phase 161 implementation paths.

### Review-Finding Disposition

**CR-01 — confirmed BLOCKER.** The review's crash-atomicity finding is supported by current source: after `moveItem(destination, retainedArtifact)` succeeds, a process termination bypasses the in-process `catch` and `defer`. `status(for:)` only reads `inventory.json` and `pack-{id}`; it never finds `.previous-*`, a transaction journal, or any pending replacement state. This is an observable failure of the phase's atomic-install/known-good-preservation promise, not a Phase 162 device-proof concern.

The earlier WR-01 and evidence-honesty failures are closed in current code: thrown second-move errors enter `rollbackPublication`, while generated evidence comes from the deny-only network operation and verified installed bytes. Neither closure addresses termination between those calls.

### Gaps Summary

Phase 161 has a genuine host-supplied foreground byte-verification path, and its core fail-closed and advisory-proof boundaries are wired and freshly tested. It does not yet atomically replace a committed pack across a normal app/OS termination. Because this is a host installation correctness defect within PACK-03—not physical-iPhone evidence—it cannot be deferred to Phase 162.

**Next action:** revision/escalation gate — plan the crash-safe publication/recovery repair and re-verify Phase 161.  
**Next command:** `$gsd-plan-phase 161 --gaps`

_Verified: 2026-08-03T21:25:19Z_  
_Verifier: the agent (gsd-verifier)_
