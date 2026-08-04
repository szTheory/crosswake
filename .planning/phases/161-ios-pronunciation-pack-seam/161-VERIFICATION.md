---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-04T01:29:20Z
status: gaps_found
score: 19/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
next_action: "Repair generated reference-adapter proof run isolation, then rerun the Phase 161 final gate."
next_command: "$gsd-plan-phase 161 --gaps"
re_verification:
  previous_status: gaps_found
  previous_score: 19/20
  gaps_closed:
    - "Crash-safe replacement publication now has a fsynced host-private journal, startup recovery, and executable retained-old/promoted-new/inventory-committed tests."
  gaps_remaining:
    - "Generated reference-adapter proof can pass using a stale persisted pack and therefore cannot truthfully certify installation during the current run."
  regressions: []
gaps:
  - truth: "Generated reference-adapter proof verifies a current-run foreground install of real bytes before it emits a passed advisory result."
    status: failed
    reason: "The generated UI test launches with a fixed persisted Application Support pack path, taps Install, and accepts any Passed outcome. It neither resets that test-only persistence nor asserts the initial Blocked state. The verifier uses xcodebuild test-without-building without uninstalling/resetting the app, so bytes from a prior run can satisfy install, relaunch, and audio markers even if this run performs no install."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"
        issue: "No reset launch environment and no initial Blocked assertion before Install."
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex"
        issue: "Never consumes a reset environment before constructing the reference adapter."
      - path: "script/verify_generated_ios_shell.sh"
        issue: "Runs test-without-building with the adapter flag only; it does not isolate persisted simulator application data."
    missing:
      - "Add a test-only reference-adapter reset environment, consumed before adapter construction, and set it from the generated XCUITest."
      - "Assert the reset launch starts Blocked, then assert Installed/Passed only after the foreground action; add template/verifier regression tests for that ordering."
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated availability with one host-supplied foreground iOS install path that verifies and atomically installs real bytes.

**Verified:** 2026-08-04T01:29:20Z  
**Status:** gaps_found  
**Re-verification:** Yes — after Plans 161-15 and 161-16

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A host can implement one versioned async provider for exact requirement-bound status, install, and invalidate; nil, malformed, cancelled, and failed results remain blocked. | ✓ VERIFIED | `PackProvider.swift` exposes only the closed three-operation protocol. Fresh `swift test --package-path packages/crosswake-shell-core-ios` passed 27/27, including nil/malformed and acknowledgement-without-fresh-status denial. |
| 2 | Cold start begins checking; activation consumes reconciled inventory, not timestamps, staging bytes, or an acknowledgement. | ✓ VERIFIED | `PackStore` begins checking, reconciles through `status(for:)`, and `ActivationCoordinator` delegates actions through the store. Core conformance tests passed. |
| 3 | The host stages and verifies exact byte count/SHA-256, promotes only verified bytes, persists inventory after commit, and fresh status re-attests the destination. | ✓ VERIFIED | `PronunciationPackProvider.install` stages then verifies before its journaled publication; `status` reads and re-verifies the live artifact. Clean focused example-host XCTest passed 33/33. |
| 4 | Replacement is restart-recoverable: retained-old, promoted-new/inventory-pending, and inventory-committed states resolve safely before public operations report. | ✓ VERIFIED | Provider construction creates one startup recovery barrier; the host XCTest suite passed its construction-recovery, durability-ordering, invalid-journal, and recovery-before-invalidate cases. |
| 5 | Crosswake owns declaration/lifecycle/inventory/activation denial while the host owns source, URL/auth, storage, layout, codecs, retention, UI, and playback details. | ✓ VERIFIED | Core API values contain no transport, credential, path, archive-layout, codec, retention, UI, playback, or raw-error field; the file-backed provider remains under the example host. |
| 6 | Invalid, stale, revoked, malformed, crash-stranded, or unreconciled media cannot activate a route. | ✓ VERIFIED | Strict record binding, generation fencing, revoke-first invalidation, journal validation, and activation tests are wired and pass. |
| 7 | Generated reference-adapter proof verifies a fresh current-run foreground install, relaunch readback, and deny-only offline audio operation before emitting advisory success. | ✗ FAILED | A valid fixture persists at a fixed Application Support path. The UI test never resets it or asserts Blocked before tapping Install; `test-without-building` does not uninstall/reset. A stale pack can produce all accepted Passed markers. |
| 8 | Advisory evidence and diagnostics retain only closed, privacy-safe facts. | ✓ VERIFIED | Fresh focused proof-template/evidence/verifier ExUnit suite passed 43/43. No raw media, credentials, account identifiers, paths, URLs, or digests were found in retained validation facts. |
| 9 | Simulator/reference-adapter output cannot promote physical-iPhone or adopter claims. | ✓ VERIFIED | Validation keeps the result `passed_simulator_advisory`, TODO-002/adopter instance `unknown_blocking`, and physical-iPhone promotion Phase-162-only. |
| 10 | Android, background transfer, delta/eviction, generic storage/distribution, scoring, and capture stay unclaimed. | ✓ VERIFIED | The reviewed Phase 161 surfaces add only the foreground iOS seam and preserve the stop list; no prohibited product/platform surface was found. |

**Score:** 19/20 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `PackProvider.swift` | Narrow closed v1 provider seam | ✓ VERIFIED | Substantive 85-line API, consumed by `PackStore` and host provider. |
| `PackStore.swift` / `ActivationCoordinator.swift` | Checking-first reconciliation and route denial | ✓ VERIFIED | Imported/wired state → activation path; core tests execute it. |
| `PronunciationPackProvider.swift` | Host-private verified, durable, restart-recoverable installer | ✓ VERIFIED | Journal, fsync ordering, startup recovery, status re-attestation, and 33 host XCTest cases pass. |
| `PronunciationPackProviderTests.swift` | Concrete host integrity/recovery backstops | ✓ VERIFIED | Executes retained-old, promoted-new, committed, malformed topology, invalidation, and ordering coverage. |
| `ProofLaneDriver.swift.eex` | Real fixture installation/readback and observed denied network operation | ⚠️ PARTIAL | The adapter itself verifies bytes and observes denial, but its fixed persisted location is not reset for the UI proof run. |
| `ProofLaneApp.swift.eex` / `ProofLaneUITests.swift.eex` / verifier script | Run-isolated advisory proof | ✗ FAILED | Wired to pass markers, but missing reset + initial-blocked proof makes current-run installation evidence hollow. |
| `161-VALIDATION.md` / `COVERAGE.md` | Aggregate-only, non-promoting evidence boundary | ✓ VERIFIED | Privacy and stop-list projections are retained; the generated-install claim must be regenerated after repair. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PackRequirement` | `PackProvider.status(for:)` | exact ID/version/count/digest binding | ✓ WIRED | Provider result is strictly checked by `PackStore` before availability. |
| `PackProvider.install(_:)` | `PackStore.reconcile` | mandatory fresh status after acknowledgement | ✓ WIRED | `installRequiredPack` calls `reconcile` only after `.installed`. |
| Host publication | provider status | startup recovery then destination byte re-attestation | ✓ WIRED | `awaitStartupRecovery` precedes status; status opens/verifies the artifact. |
| Journal/inventory transitions | filesystem operations | sync-before-move and recover-before-operation | ✓ WIRED | `persistJournal`, synchronization calls, and focused recovery tests prove ordering. |
| Generated reference install action | passed advisory evidence | reset → blocked → install → passed current-run chain | ✗ NOT WIRED | The required reset and blocked-state link is absent; existing Passed assertion accepts stale state. |
| Generated observed network operation | advisory verifier | exact schema-v2 transcript markers | ✓ WIRED | Script accepts the six required ordered assertion IDs only after test execution. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PackStore` | `RequiredPackStatus` | provider re-attested record | Yes | ✓ FLOWING |
| Host provider | staged/destination bytes | host source → streamed SHA-256/count → live artifact → inventory | Yes | ✓ FLOWING |
| Crash recovery | journal/inventory/live artifact | fsynced private journal → startup reconciliation | Yes | ✓ FLOWING |
| Generated proof | UI Passed marker | fixed persisted Application Support artifact may predate test run | No current-run provenance | ✗ HOLLOW |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core provider, route denial, fresh reconciliation | `swift test --package-path packages/crosswake-shell-core-ios` | 27 tests, 0 failures | ✓ PASS |
| Host integrity, durability, and restart recovery | `xcodebuild clean test … -only-testing:CrosswakeShellTests/PronunciationPackProviderTests` | 33 tests, 0 failures | ✓ PASS |
| Proof templates, evidence allowlist, generated verifier contracts | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs` | 43 tests, 0 failures | ✓ PASS |
| Current-run generated installation evidence | Static trace of UI test/app/script | Reset and initial Blocked assertion absent; stale persistence remains reachable | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PACK-01 | 01, 03–06, 08–11, 13–14, 16 | Host-supplied foreground status/install/invalidate seam | ✓ SATISFIED | Closed v1 protocol and host injection are implemented and tested. |
| PACK-02 | 01–07, 09–12, 14–16 | Failure/unconfigured/interrupted states never available | ✓ SATISFIED | Strict mappings, revocation, recovery validation, and route-denial tests pass. |
| PACK-03 | 01–02, 04–06, 08–16 | Exact size/SHA-256 verification then atomic installation | ✗ BLOCKED | The real host installer and crash recovery pass, but the required generated advisory proof can falsely certify this run's installation from stale bytes. |
| PACK-04 | 01–16 | Explicit Crosswake/host ownership boundary | ✓ SATISFIED | API boundary remains narrow; acquisition/storage/media mechanics remain host-owned. |
| PACK-05 | 03–06, 08–09, 11, 13–14, 16 | Adjacent claims remain unclaimed | ✓ SATISFIED | No Android/background/generic-storage/product expansion; simulator evidence remains non-promoting. |

All plan-declared requirement IDs are PACK-01 through PACK-05. No orphaned Phase 161 requirement was found in `REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `ProofLaneUITests.swift.eex` | 15–30 | Tests only for `Passed`, not reset/initial blocked state | 🛑 BLOCKER | Stale persisted bytes can masquerade as a successful current-run install. |
| `ProofLaneApp.swift.eex` | 4–9 | Test-only reset function is never wired before adapter construction | 🛑 BLOCKER | The proof cannot create the required clean starting condition. |
| `verify_generated_ios_shell.sh` | 184 | `test-without-building` receives adapter flag but no reset/isolation contract | 🛑 BLOCKER | The verifier promotes stale simulator container state into advisory evidence. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker was found in the reviewed Phase 161 implementation paths. The `return {}` UI mapping is the intentional no-effect case for an unavailable optional action, not a stub.

### Review-Finding Disposition

**CR-01 — confirmed BLOCKER.** The source independently reproduces the reviewer’s causal chain: `ProofLaneReferencePackAdapter.installedURL()` is a deterministic Application Support location; its `resetReferencePersistenceForTests()` helper is only called by unit-contract tests; `ProofLaneApp` does not read a reset environment; the XCUITest launches with only the reference-adapter flag and accepts any `Passed:` label; and the script does not uninstall/reset before `test-without-building`. Therefore simulator proof remains advisory and non-promoting, but its narrower claim of a current-run install is also false.

### Gaps Summary

Phase 161 now has a real host-supplied foreground installer, exact byte verification, fresh status reconciliation, and crash/restart-safe publication. Its generated advisory proof lane is not run-isolated, so it cannot truthfully certify that the current invocation installed those bytes. This is not deferrable to Phase 162: physical-device promotion is separate, while truthful simulator advisory evidence is a Phase 161 final-gate contract.

**Next action:** Escalation/revision gate — repair the generated reference-adapter reset and current-run assertion chain, execute the fresh same-tree gate, and re-verify.  
**Next command:** `$gsd-plan-phase 161 --gaps`

_Verified: 2026-08-04T01:29:20Z_  
_Verifier: the agent (gsd-verifier)_
