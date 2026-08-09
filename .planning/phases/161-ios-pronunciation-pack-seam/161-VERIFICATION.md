---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-04T14:42:00Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/10
  gaps_closed:
    - "Replacement is restart-recoverable: the exact stale-inventory/no-artifact promotion-pending journal now recovers to not-installed and permits a verified foreground reinstall."
  gaps_remaining: []
  regressions: []
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated availability with one host-supplied foreground iOS install path that verifies and atomically installs real bytes.
**Verified:** 2026-08-04T14:42:00Z
**Status:** passed
**Re-verification:** Yes — after Plans 161-19 and 161-20

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A host can supply one closed v1 provider for requirement-bound status, install, and invalidate; malformed, cancelled, nil, and failed results cannot activate routes. | ✓ VERIFIED | `PackProvider` remains the narrow three-operation seam; `PackStore` reconciles its closed results and `ActivationCoordinator` blocks non-available state. `PackStoreTests` passed 9/9. |
| 2 | Availability derives from verified current bytes, not elapsed time, staged bytes, or install acknowledgement. | ✓ VERIFIED | The provider streams/verifies the staged artifact before promotion and `status` re-attests the destination bytes. `PackProviderFixtureTests` passed 3/3, including fresh-status-before-activation. |
| 3 | Corrupt, interrupted, missing, stale, revoked, or unconfigured states fail closed and preserve a usable foreground recovery path where recovery is safe. | ✓ VERIFIED | The host XCTest suite passed 34/34, covering malformed journals, unsafe leaves, volume mismatch, missing artifacts, invalidation races, retained-old recovery, and the repaired stale-inventory path. |
| 4 | The reachable stale-inventory/no-artifact promotion-pending interruption recovers before public operations and then permits a verified foreground reinstall. | ✓ VERIFIED | `PronunciationPackProvider.swift:147-150` journals a prior record only with an actual prior artifact. `:322-351` recognizes exactly the legacy inventory-only topology, removes stale authority, and retains fail-closed rejection for every other missing-retained-artifact topology. `testConstructionBootstrapRecoversStaleInventoryWithoutArtifactAndPermitsReinstall` passed in the independent 34-test XCTest run. |
| 5 | Genuine retained bytes still restore as a last-known-good record/artifact pair; no optimistic availability or silent fallback was introduced. | ✓ VERIFIED | Recovery preserves the retained-artifact branch after topology validation; retained-old and promoted-inventory-pending XCTest regressions passed. |
| 6 | Crosswake owns declaration, lifecycle, inventory, and activation denial, while source, storage, layout, codecs, transport, and playback remain host-owned. | ✓ VERIFIED | The filesystem-backed installer remains solely in `examples/ios_shell_host`; the diff from the prior gate changes only its private journal invariant and recovery branch. No core provider API changed. |
| 7 | Generated reference-adapter evidence requires a current-run foreground install but remains simulator-advisory. | ✓ VERIFIED | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` passed 19/19. Schema-5 records the required ordered current-run outcomes and `passed_simulator_advisory`. |
| 8 | Required-pack recovery UI remains accessible and route activation, not the proof UI, owns availability. | ✓ VERIFIED | Schema-5 records all four executed UI backstops; provider/activation wiring is unchanged by the recovery repair. |
| 9 | Evidence and diagnostics exclude raw media, credentials, account identifiers, paths, URLs, and transcript output. | ✓ VERIFIED | The retained schema-5 object contains aggregate counts, stable outcomes, an opaque run identifier, and a tree digest only; its scoped privacy-field scan found no sensitive category. |
| 10 | Android, generic storage/distribution, background transfer, delta/eviction, scoring, and capture remain unclaimed. | ✓ VERIFIED | No Android file is in the repaired implementation history. The change is confined to the host-private iOS provider/tests, and the ROADMAP/ADR boundary remains foreground-iOS-only. |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift` | Host-private real-byte, atomic, restart-recoverable installer | ✓ VERIFIED | Substantive actor; startup recovery gates all public operations; exact stale legacy topology is repaired without weakening corrupt-state denial. |
| `examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift` | Executable recovery and reinstallation regression | ✓ VERIFIED | Contains direct crash/relaunch construction, inventory/journal cleanup assertions, fixture install, and fresh relaunch re-attestation. |
| `packages/crosswake-shell-core-ios` PackProvider/PackStore | Closed provider seam and activation lifecycle | ✓ VERIFIED | Imported and used by the host path; 12 focused core tests passed. |
| Generated proof templates/verifier | Current-run advisory contract | ✓ VERIFIED | Template/verifier regression suite passed 19/19; it does not promote device proof. |
| `161-VALIDATION.md` | Privacy-safe final evidence | ✓ VERIFIED | Schema-5 binds the two-file repair subject and records the stale-inventory outcome as passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `hadPriorArtifact` | `ReplacementJournal.priorRecord` | Prior record is emitted only with retained destination bytes | ✓ WIRED | `priorRecord = hadPriorArtifact ? loadInventory()[...] : nil`. |
| `replacement-journal.json` | Startup recovery | Validated phase/file topology before persistent mutation | ✓ WIRED | Recovery checks schema, leaf safety, identities, regular-file/volume properties, and recognized state before inventory mutation. |
| Startup recovery | `status` / `install` / `invalidate` | Shared memoized recovery result gates each provider operation | ✓ WIRED | Exact stale state resolves successfully; malformed/ambiguous states retain the closed memoized failure behavior. |
| Host publication | fresh provider status | Streaming integrity check → atomic destination → inventory → byte re-attestation | ✓ WIRED | Fixture and host XCTest evidence exercise the complete data flow. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Host provider | staged/destination artifact | Host source → bounded stream/count/SHA-256 → atomic destination → inventory | Yes | ✓ FLOWING |
| Startup recovery | journal, inventory, destination/retained/staging leaves | Fsynced host-private state validated before recovery mutation | Yes | ✓ FLOWING |
| `PackStore` | required-pack availability | Fresh provider `PackInstalledRecord` → closed lifecycle state → activation decision | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Exact stale inventory/no-artifact crash recovery and foreground reinstall | `xcodebuild clean test ... -only-testing:CrosswakeShellTests/PronunciationPackProviderTests` | 34 tests, 0 failures; exact regression passed | ✓ PASS |
| Fresh byte verification and closed core lifecycle | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests && ... --filter PackStoreTests` | 3 + 9 tests, 0 failures | ✓ PASS |
| Current-run generated proof contract | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | 19 tests, 0 failures | ✓ PASS |
| Repair formatting | `git diff --check -- examples/ios_shell_host/CrosswakeShell/PronunciationPackProvider.swift examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift` | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
| --- | --- | --- | --- |
| PACK-01 | Host-supplied foreground status/install/invalidate seam | ✓ SATISFIED | Narrow protocol and host injection remain wired; focused core and host tests pass. |
| PACK-02 | Invalid/interrupted states never report available | ✓ SATISFIED | Direct regression proves the one recoverable interruption is not installed; malformed/ambiguous paths remain closed. |
| PACK-03 | Exact size/SHA-256 verification then atomic installation | ✓ SATISFIED | Fixture/core and host tests prove verification, atomic promotion, restart readback, and recovery. |
| PACK-04 | Explicit Crosswake/host ownership boundary | ✓ SATISFIED | Repair is private to the example host; public core seam did not expand. |
| PACK-05 | Adjacent storage/media/platform claims remain unclaimed | ✓ SATISFIED | Schema-5 and source inspection preserve foreground iOS only; simulator proof is advisory and physical-iPhone promotion remains Phase 162-only. |

All Phase 161 plan requirements map exactly to PACK-01 through PACK-05. No orphaned Phase 161 requirement was found.

### Anti-Patterns Found

No blocker anti-patterns or unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the repaired production/test artifacts.

### Disconfirmation Pass

- The generated reference-adapter proof is deliberately insufficient as physical-iPhone evidence. It proves a simulator advisory contract only; schema-5 and the roadmap explicitly retain physical-device promotion for Phase 162. This is a preserved boundary, not a Phase 161 failure.
- The recovery test does not accept arbitrary missing-retained-artifact journals: source and the same XCTest suite distinguish the exact inventory-only `.promotionPending` topology from malformed, colliding, mismatched, non-regular, and ambiguous states, which still fail closed.
- The previous failure mode is now directly tested as an actual reconstructed on-disk journal/inventory/staging state, rather than inferred from the implementation or a summary claim.

### Gaps Summary

None. The previous CR-01 blocker is closed by production code and an independently executed host XCTest regression. TODO-002/adopter-instance completeness remains `unknown_blocking`, and physical-iPhone promotion remains Phase 162-only; neither is a missing deliverable of this bounded Phase 161 seam.

---

_Verified: 2026-08-04T14:42:00Z_
_Verifier: the agent (gsd-verifier)_
