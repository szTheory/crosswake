---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-04T02:47:59Z
status: gaps_found
score: 9/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
next_action: "Repair stale-inventory/no-artifact recovery, add a direct crash-recovery regression, run the fresh same-tree gate, then re-verify."
next_command: "$gsd-plan-phase 161 --gaps"
re_verification:
  previous_status: gaps_found
  previous_score: 19/20
  gaps_closed:
    - "Generated reference-adapter proof now resets test-only persistence before adapter construction and proves Blocked → foreground install → Passed → relaunch → offline audio in order."
  gaps_remaining:
    - "Crash recovery cannot handle a journal whose prior inventory record exists but whose prior artifact was absent, permanently blocking all provider operations."
  regressions: []
gaps:
  - truth: "Replacement is restart-recoverable: interrupted publication restores a safe usable state before public provider operations report."
    status: failed
    reason: "install records priorRecord from inventory even when no destination artifact exists. If interrupted after the promotion-pending journal is fsynced, recovery requires a retained file that was never created, throws, and memoizes startup recovery failure."
    artifacts:
      - path: "examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift"
        issue: "Lines 147-171 create the inconsistent journal; lines 320-329 reject it instead of removing stale inventory. awaitStartupRecovery then turns every status/install/invalidate into a permanent closed failure."
      - path: "examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift"
        issue: "No test covers inventory present + destination absent + interruption after journal persistence."
    missing:
      - "Journal a prior record only when its verified artifact is actually retained, or make promotion-pending recovery remove stale inventory when the prior artifact is absent."
      - "Add a direct regression that constructs the reachable stale-inventory/no-artifact journal state and proves a newly constructed provider can recover and install."
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated availability with one host-supplied foreground iOS install path that verifies and atomically installs real bytes.
**Verified:** 2026-08-04T02:47:59Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 161-17 and 161-18

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A host can supply one closed v1 provider for requirement-bound status, install, and invalidate; malformed, cancelled, nil, and failed results do not activate routes. | ✓ VERIFIED | `PackProvider.swift:81-85` exposes only the three operations. `PackStore.swift:121-195` reconciles results into closed states and `ActivationCoordinator.swift:395-404` blocks any non-available pack. |
| 2 | Availability comes from verified current bytes, not simulated time, staging bytes, or install acknowledgement. | ✓ VERIFIED | `PronunciationPackProvider.install` stages and hashes before move (`:137-202`); `status` re-verifies destination bytes (`:104-121`); `PackStore.installRequiredPack` fresh-reconciles after `.installed` (`:127-146`). Focused `PackProviderFixtureTests/testVerifiedFixturePromotesThenFreshStatusUnblocksActivation` passed. |
| 3 | Corrupt, missing, stale, revoked, unconfigured, and ordinary interrupted paths fail closed rather than activate a route. | ✓ VERIFIED | Missing provider/bytes and verification failures map to non-available results; revocation is persisted before invalidation (`PackStore.swift:149-195`), and `blockingStatus` refuses every state other than `.available`. |
| 4 | Interrupted replacement publication is restart-recoverable and leaves the foreground installer usable. | ✗ FAILED | A persisted inventory record with no prior destination is reachable; the next install journals it as `priorRecord` (`PronunciationPackProvider.swift:147-171`). Recovery of `.promotionPending` requires the non-existent retained file (`:320-329`), throws, and its memoized `startupRecovery` makes all public operations fail (`:104-105`, `:124-125`, `:226-227`). |
| 5 | Crosswake owns declaration/lifecycle/inventory/activation denial, while host source, storage, layout, codecs, and playback remain host-owned. | ✓ VERIFIED | Core contract carries only requirement-bound records/results; the filesystem-backed provider is confined to `examples/ios_shell_host`, while `ProofLaneDriver.swift.eex` labels its adapter host scaffold. |
| 6 | The generated reference-adapter proof now proves a current-run foreground install before advisory success. | ✓ VERIFIED | `ProofLaneApp.swift.eex:7-15` consumes both exact test keys before factory construction. XCUITest asserts `Blocked: packAudio` before `install.tap()`, then `Passed`, removes reset before relaunch, and emits four ordered markers. The verifier requires each marker exactly once and in order (`verify_generated_ios_shell.sh:216-235`). Fresh template/verifier suites passed 19/19. |
| 7 | Retained proof evidence remains aggregate-only and simulator output cannot promote physical-iPhone or adopter-instance claims. | ✓ VERIFIED | `161-VALIDATION.md` schema-4 manifest retains `passed_simulator_advisory`, `todo_002: unknown_blocking`, `adopter_instance: unknown_blocking`, and `physical_iphone_promotion: phase_162_only`; no product/template diff exists after its recorded subject revision. |
| 8 | Android, background transfer, delta/eviction, generic storage/distribution, scoring, and capture remain unclaimed. | ✓ VERIFIED | The reviewed Phase 161 product/template paths contain no implementation of these surfaces; ROADMAP/ADR scope remains iOS foreground only. |
| 9 | The approved foreground recovery UI remains accessible and route activation—not the proof view—owns availability. | ✓ VERIFIED | `RequiredPackView` and its host/UI test targets remain wired in the Xcode project; the phase’s retained schema-4 evidence records the four existing UI backstops. No product/UI source changed after that gate. |
| 10 | Evidence and diagnostics retain no raw media, credentials, account identifiers, paths, URLs, or transcript output. | ✓ VERIFIED | The schema-4 retained manifest contains closed aggregate fields only; the generated verifier emits only closed JSON outcome/rule/scope fields. |

**Score:** 9/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `PackProvider.swift` | Narrow host-supplied v1 seam | ✓ VERIFIED | Substantive protocol and closed values; used by `PackStore`. |
| `PackStore.swift` / `ActivationCoordinator.swift` | Checking-first reconciliation and route denial | ✓ VERIFIED | Provider result → status → `blockingStatus` → activation is wired. |
| `PronunciationPackProvider.swift` | Host-private real-byte, atomic, restart-recoverable installer | ✗ FAILED | Installation/status are substantive and wired, but the reachable recovery topology above permanently bricks public operations. |
| `PronunciationPackProviderTests.swift` | Concrete integrity and recovery backstops | ⚠️ PARTIAL | Covers several journal topologies but misses stale inventory with absent artifact before journal persistence. |
| Generated proof app/UI/verifier templates | Run-isolated current-run advisory proof | ✓ VERIFIED | Reset, exact UI ordering, relaunch key removal, and transcript gate are all connected. |
| `161-VALIDATION.md` | Privacy-safe advisory evidence | ✓ VERIFIED | Schema-4 aggregate boundary preserves Phase 162-only promotion. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PackRequirement` | `PackProvider.status(for:)` | exact ID/version/count/digest binding | ✓ WIRED | Contract and reconciliation code consume the exact requirement. |
| `PackProvider.install(_:)` | `PackStore.reconcile` | mandatory fresh status after acknowledgement | ✓ WIRED | `installRequiredPack` recurses to reconciliation only after `.installed`. |
| Host publication | provider `status` | live destination byte re-attestation | ✓ WIRED | `status` opens and hashes the destination artifact. |
| Journal/inventory transitions | filesystem recovery | recovery before provider operations | ✗ NOT WIRED SAFELY | The journal permits `priorRecord` without retained bytes; recovery cannot resolve that valid state. |
| Generated install action | advisory evidence | reset → blocked → install → passed → relaunch → audio markers | ✓ WIRED | Source ordering and 19 passing template/verifier tests confirm the repair. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PackStore` | `RequiredPackStatus` | provider’s re-attested `PackInstalledRecord` | Yes | ✓ FLOWING |
| Host provider | staged/destination bytes | host source → streamed count/SHA-256 → atomic destination → inventory | Yes on ordinary path | ✓ FLOWING |
| Startup recovery | journal + inventory + retained artifact | fsynced journal and host-private files | No for stale-inventory/no-artifact state | ✗ HOLLOW FAILURE PATH |
| Generated proof | current-run UI outcome | test-only reset → foreground operation → persisted readback | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Ordered generated-proof contract rejects missing/reordered provenance | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | 19 tests, 0 failures | ✓ PASS |
| Verified bytes require fresh status before activation | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests/testVerifiedFixturePromotesThenFreshStatusUnblocksActivation` | 1 test, 0 failures | ✓ PASS |
| Stale inventory + absent artifact + journal interruption recovery | Static state-machine trace | No regression exists; source deterministically throws at recovery guard | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PACK-01 | 01, 03–06, 08–11, 13–14, 16, 18 | Host foreground status/install/invalidate seam | ✓ SATISFIED | Closed three-operation protocol is implemented and used. |
| PACK-02 | 01–07, 09–12, 14–18 | Invalid/interrupted states never report available | ✗ BLOCKED | It fails closed but a reachable interrupted state permanently disables all foreground recovery, so the required usable foreground path is not achieved. |
| PACK-03 | 01–02, 04–06, 08–18 | Exact size/SHA-256 verification then atomic installation | ✗ BLOCKED | Normal installation verifies and promotes, but the restart-safe atomic publication contract fails for the reachable interrupted topology. |
| PACK-04 | 01–16, 18 | Explicit Crosswake/host ownership boundary | ✓ SATISFIED | Transport/storage/playback remain host-owned. |
| PACK-05 | 03–06, 08–09, 11, 13–14, 16–18 | Adjacent claims remain unclaimed | ✓ SATISFIED | Simulator remains advisory; Phase 162 alone owns physical-iPhone promotion. |

All plan-declared requirement IDs are PACK-01 through PACK-05, which exactly match Phase 161’s IDs in `REQUIREMENTS.md`. No orphaned Phase 161 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `PronunciationPackProvider.swift` | 147–171, 320–329 | Recovery journal records inventory-only prior state but recovery assumes retained prior bytes | 🛑 BLOCKER | One interrupted installation state memoizes failure and permanently blocks status/install/invalidate. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the reviewed Phase 161 implementation paths.

### Review-Finding Disposition

**CR-01 — confirmed BLOCKER.** This is independently established by the code, not the review narrative: `hadPriorArtifact` is calculated separately from `priorRecord`; `priorRecord` is nevertheless journaled when only inventory exists; `.promotionPending` requires `retained` whenever that field is non-nil. A crash after `persistJournal` and before promotion therefore makes the construction-time recovery task throw. Because that task is shared and memoized, each public operation returns its closed failure indefinitely. Existing tests cover retained-old, promoted-new, committed, malformed, volume, and invalidation states, but no test covers this topology.

### Gaps Summary

The prior proof-isolation gap is closed: the generated simulator reference path now establishes current-run provenance, and remains advisory only. Phase 161 is still not achieved because its advertised host-supplied foreground installer cannot recover from one reachable crash state. This is not deferred to Phase 162: physical-iPhone promotion is separate, while safe restart recovery is part of Phase 161’s atomic installation path.

**Escalation gate:** repair the journal/recovery invariant and add the missing executable regression before the phase can proceed.

_Verified: 2026-08-04T02:47:59Z_
_Verifier: the agent (gsd-verifier)_
