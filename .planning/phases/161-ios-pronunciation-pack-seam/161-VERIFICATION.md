---
phase: 161-ios-pronunciation-pack-seam
verified: 2026-08-03T16:47:57Z
status: gaps_found
score: 9/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The reference host can install its declared pronunciation pack through the bundled production construction path."
    status: failed
    reason: "PackStore.bundled discards required byte-count and SHA-256 metadata, passing 0 and an empty digest to the injected provider; the provider correctly rejects the nonempty fixture."
    artifacts:
      - path: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift"
        issue: "Lines 89-93 decode only versions and manufacture invalid integrity declarations."
      - path: "examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift"
        issue: "The host computes a private valid requirement at lines 252-260 but never supplies it to PackStore."
    missing:
      - "Decode and validate a requirement declaration containing positive exact byte count and pinned SHA-256 before constructing PackStore."
      - "Exercise the actual bundled host path in an XCTest."
  - truth: "Every corrupt, interrupted, missing, stale, unconfigured, malformed, and revoked path fails closed."
    status: failed
    reason: "Malformed pack references are dropped by compactMap, allowing an all-malformed required-pack list to reach LiveView; a concurrent reconciliation can also clear a persisted invalidation fence from an old installed record."
    artifacts:
      - path: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift"
        issue: "Lines 96-101 discard malformed references; lines 147-157 clear a revocation when stale reconciliation sees available."
    missing:
      - "Make every malformed, empty, unknown, or incompatible required-pack reference return a blocking closed status."
      - "Add a per-pack operation generation/fence so only the originating successful invalidation plus fresh absence can clear revocation."
      - "Add deterministic malformed-manifest and reconcile-during-failed-invalidation tests."
  - truth: "The generated proof lane deterministically installs verified bytes and performs offline pronunciation playback/readback before pack_audio_prerequisite can pass."
    status: failed
    reason: "The reference adapter accepts any nonempty fixture, stores only a UserDefaults Boolean, and audio exercise returns that Boolean-derived snapshot. The verifier promotes printed XCTest markers, not structured integrity/install/audio evidence."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex"
        issue: "Lines 41-52 contain no size or SHA-256 validation, atomic promotion, persisted artifact readback, networking assertion, or audio/read operation."
      - path: "script/verify_generated_ios_shell.sh"
        issue: "Lines 188-195 turn untrusted marker strings into a passed pack_audio_prerequisite outcome."
    missing:
      - "Keep the generated lane blocked unless a host adapter supplies verified fixture acquisition, atomic promotion, relaunch readback, and deterministic offline audio/read evidence."
      - "Consume structured assertions for those operations rather than print markers."
---

# Phase 161: iOS Pronunciation Pack Seam Verification Report

**Phase Goal:** Replace simulated availability with one host-supplied foreground iOS install path that verifies exact real bytes and atomically installs them, while every corrupt/interrupted/missing/stale/unconfigured path fails closed and Crosswake does not claim generic native storage.
**Verified:** 2026-08-03T16:47:57Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Versioned requirement-bound status/install/invalidate provider has closed results. | ✓ VERIFIED | `PackProvider.swift:3-84` defines only the typed v1 contract and closed result/reason types; core tests pass. |
| 2 | Real fixture bytes reach activation only after exact integrity, atomic promotion, persistence, and fresh reconciliation. | ✗ FAILED | Package tracer uses a test fake; the actual bundled host path supplies zero/empty integrity fields (`PackStore.swift:89-93`) and is rejected by its provider. |
| 3 | Cold launch and route reads use current reconciled inventory, never timed or legacy availability. | ✗ FAILED | Checking-first code exists, but malformed required-pack declarations are silently discarded (`PackStore.swift:96-101`) and may let activation continue. |
| 4 | Core/provider ownership is narrow and excludes host transport/storage/playback details. | ✓ VERIFIED | Public protocol has only three requirement/result operations; no URL, path, credentials, codec, archive, or raw Error member was found. |
| 5 | Host installer stages, verifies, atomically promotes, and persists only after commit. | ✗ FAILED | The reference provider hashes an in-memory `Data` value and writes it atomically, but does not stream as required; more importantly its production requirement wiring is unusable. |
| 6 | Install/invalidate are serialized and reconciliation cannot fabricate availability. | ✗ FAILED | `@MainActor` serialization exists, but the invalidation fence can be cleared by an overlapping stale reconciliation (`PackStore.swift:147-157`). |
| 7 | Failed replacement preserves known-good bytes and a newer declaration remains stale/blocked. | ✓ VERIFIED | Provider stages before replace (`PronunciationPackProvider.swift:25-55`); focused host test asserts retained old record, and PackStore maps version mismatch to `.stale`. |
| 8 | Revocation persists and remains blocked until the same successful invalidation/reinstall confirms it. | ✗ FAILED | Any reconciliation that sees an installed record clears the revocation, contrary to this invariant. |
| 9 | Reference host injects a working private exact requirement/provider configuration. | ✗ FAILED | Injection is explicit (`CrosswakeShellApp.swift:206-218`), but the calculated requirement is not passed to PackStore, so foreground installation cannot work. |
| 10 | Reference UI exposes closed state, one foreground recovery action, and stable accessibility semantics. | ✓ VERIFIED | `RequiredPackView` is wired to coordinator callbacks; the four focused UI contract tests are present and were exercised in the phase gate. |
| 11 | Install/Update/Retry/Invalidate-then-Install are foreground-only, with no automatic retry or second runtime owner. | ✓ VERIFIED | Closed action mapping in `RequiredPackView.swift` and coordinator callbacks; no background continuation path found. |
| 12 | Dynamic Type, text-plus-color, system colors, and accessible status/actions are implemented. | ✓ VERIFIED | Reference view and its accessibility contract tests supply this behavior. |
| 13 | Existing generated lane proves missing-provider denial, verified install, relaunch reconciliation, and offline pronunciation use. | ✗ FAILED | Generated adapter uses a Boolean instead of verified installation/readback; its UI test only sees a passed label. |
| 14 | Public provider has no playback/asset API and the separate host proof operation actually exercises installed offline audio. | ✗ FAILED | Public API is narrow, but `exerciseInstalledPronunciationAudioOffline()` is only `observe()` (`ProofLaneDriver.swift.eex:50-52`). |
| 15 | `pack_audio_prerequisite` passes only from real immutable bytes and exact adapter-derived evidence; simulator remains advisory. | ✗ FAILED | The advisory boundary is retained, but the condition for passing is a nonempty fixture plus print markers, not exact evidence. |
| 16 | Retained evidence rejects private/raw proof values and keeps closed outcomes only. | ✓ VERIFIED | Focused ExUnit evidence/template/verifier suite: 40 tests, 0 failures; evidence privacy tests cover the closed rejection path. |
| 17 | A final tree proves the provider, atomic/reconciliation, invalid paths, revocation, UI, and generated audio lane together. | ✗ FAILED | The advertised aggregate gate passes while the production wiring, malformed-manifest denial, invalidation fence, and generated audio proof fail by source inspection. |
| 18 | Validation/evidence retain only approved IDs, closed states, aggregate results, and closed outcomes. | ✓ VERIFIED | Evidence tests pass and validation contains aggregate/closed result claims rather than raw fixture values. |
| 19 | Simulator proof is advisory; Phase 162 alone owns physical-iPhone/adopter promotion and TODO-002 remains blocked. | ✓ VERIFIED | Script’s passing rule is explicitly advisory (`PL-IOS-PACK-AUDIO-ADVISORY`); roadmap/state preserve Phase 162 and `unknown_blocking`. |
| 20 | The in-process protocol is accurately declared as no external API integration. | ✓ VERIFIED | `api-coverage.verify-pre` returned `passed: true`; COVERAGE.md has the required no-external-API declaration. |

**Score:** 9/20 truths verified (0 present, behavior-unverified)

### Roadmap Success-Criteria Verdict

| Success criterion | Status | Evidence |
| --- | --- | --- |
| Simulated timed transitions can no longer imply availability. | ✗ FAILED | Malformed required-pack declarations can bypass the gate; generated proof substitutes Boolean success for installation. |
| All corrupt, interrupted, missing, stale, or unconfigured paths fail closed. | ✗ FAILED | Malformed-manifest bypass and invalidation/reconciliation race are observable fail-open paths. |
| Host and Crosswake ownership is explicit and tested. | ✗ FAILED | Ownership types are explicit, but the real host construction path is disconnected from its integrity requirement. |
| Generic native content-pack storage remains a non-claim. | ✓ VERIFIED | The core protocol remains narrow; host-only example storage is not surfaced as core generic storage. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- |
| `PackProvider.swift` | Versioned closed provider contract | ✓ VERIFIED | Exists, substantive, and imported by PackStore/host. |
| `PackStore.swift` | Current reconciled fail-closed inventory | ✗ FAILED | Wired into activation, but bundled integrity propagation, malformed reference handling, and invalidation fence are defective. |
| `PronunciationPackProvider.swift` | Host atomic verified installer | ⚠️ PARTIAL | Direct test path exists, but production requirement wiring rejects installation and implementation is non-streaming. |
| `CrosswakeShellApp.swift` | Reference-host composition injection | ✗ FAILED | Provider is injected, but its private exact requirement is unused by PackStore. |
| `ProofLaneDriver.swift.eex` | Verified install/relaunch/offline-audio adapter | ✗ HOLLOW | Uses nonempty resource + UserDefaults Boolean; no integrity/promotion/readback/audio behavior. |
| `ProofLaneContractTests.swift.eex` / `ProofLaneUITests.swift.eex` | Deterministic contract/UI proof | ✗ HOLLOW | Tests assert adapter outcomes and labels, not the required underlying byte or audio operations. |
| `verify_generated_ios_shell.sh` | Exact proof evidence gate | ✗ FAILED | Promotes printed markers to passed evidence. |
| `evidence_test.exs` / `COVERAGE.md` / `161-VALIDATION.md` | Privacy and no-external-API seal | ✓ VERIFIED | Files are substantive; focused ExUnit and API-coverage checks pass. |

### Key Link Verification

| From | To | Status | Details |
| --- | --- | --- | --- |
| `PackRequirement` | `PackProvider.status/install/invalidate` | ✗ PARTIAL | Methods are wired, but bundled construction destroys required integrity metadata. |
| `PackStore.statuses` | `ActivationCoordinator.resolve` | ✗ FAILED | Activation calls the gate, but malformed references are dropped before a blocking status is produced. |
| `PackStore.invalidatePack` | persistent revocation ledger | ✗ FAILED | Revocation is persisted first, but an overlapping reconciliation may clear it without confirmed invalidation. |
| Host provider | reference host composition root | ✗ PARTIAL | Injection exists; exact requirement configuration is disconnected. |
| Generated fixture | generated host install adapter | ✗ FAILED | Only nonempty-byte presence is checked. |
| Installed pack | offline audio operation | ✗ FAILED | Operation only returns current Boolean-derived status. |
| XCTest/XCUITest results | generated shell verifier | ✗ FAILED | Marker text, rather than structured behavioral evidence, creates a pass. |
| closed proof result | retained Evidence | ✓ VERIFIED | Existing closed assertion/outcome pathway is exercised by ExUnit tests. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PackStore` | `requirements` / `statuses` | bundled JSON → provider → reconciled inventory | No for the reference host: byte count/digest become `0`/`""` | ✗ DISCONNECTED |
| Host provider | installed record | fixture source → staging/destination → inventory | Yes in direct test construction, but not in injected bundled route | ⚠️ PARTIAL |
| Generated proof adapter | installed Boolean | any nonempty bundled fixture → UserDefaults | No verified installed artifact or audio result | ✗ HOLLOW |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core package contract suite | `swift test --package-path packages/crosswake-shell-core-ios` | 21 tests, 0 failures | ✓ PASS — insufficient coverage for listed gaps |
| Evidence/template/verifier suite | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | 40 tests, 0 failures | ✓ PASS — does not exercise actual generated adapter semantics |
| Reference generated simulator proof | `... verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter` | exit 0 | ✗ FAIL as goal evidence — source shows Boolean/marker-only success |
| API declaration seal | `gsd-tools check api-coverage.verify-pre ...` | `passed: true` | ✓ PASS |

### Requirements Coverage

| Requirement | Source plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- |
| PACK-01 | 01, 03, 04, 05 | Host-supplied foreground status/install/invalidate seam | ✗ BLOCKED | Seam exists, but the actual reference-host requirement is not propagated to the store/provider path. |
| PACK-02 | 01, 02, 03, 05 | Invalid/unconfigured paths never report available | ✗ BLOCKED | Malformed required-pack bypass and invalidation/reconciliation race violate fail-closed behavior. |
| PACK-03 | 01, 02, 04, 05 | Immutable archive only after exact size/SHA-256 and atomic install | ✗ BLOCKED | Direct provider test is positive, but production host cannot use exact metadata and generated lane lacks verification/promotion. |
| PACK-04 | 01-05 | Explicit core/host ownership boundary | ✓ SATISFIED | Core protocol does not expose host transport/storage/layout/playback authority. |
| PACK-05 | 03-05 | Stop-list remains unclaimed | ✓ SATISFIED | Simulator output remains advisory; no Android/background/generic-storage/device promotion found. |

### Prohibition Checks

| Prohibition | Status | Evidence |
| --- | --- | --- |
| No unreconciled/malformed/revoked media may silently activate a route. | ✗ FAILED | Malformed declarations are compact-mapped away; revocation can be cleared by stale reconciliation. |
| No Crosswake-owned distribution, generic storage, asset lookup, or playback authority. | ✓ VERIFIED | Contract remains requirement/result-only; host example owns source/storage. |
| No local/simulator/generated result may be presented as device/adopter/Android/generic-storage proof. | ✓ VERIFIED | `PL-IOS-PACK-AUDIO-ADVISORY`, roadmap, and state preserve the Phase 162 physical-device boundary. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `PackStore.swift` | 89-93 | Hardcoded empty integrity declaration | 🛑 Blocker | Makes injected reference provider reject the declared pack. |
| `PackStore.swift` | 96-101 | `compactMap` drops malformed activation requirements | 🛑 Blocker | Required pack gate can disappear. |
| `PackStore.swift` | 147-157 | Unfenced concurrent revocation reconciliation | 🛑 Blocker | Failed invalidation can later reactivate old bytes. |
| `ProofLaneDriver.swift.eex` | 41-52 | Boolean-only installation/audio implementation | 🛑 Blocker | Advisory proof is a false positive for verified offline media. |
| `ActivationCoordinator.swift` | 458-471 | Authorized origin is not bound to loaded URL | ⚠️ Warning | Review finding WR-01; security issue in phase-modified code, outside the PACK goal but requires follow-up. |

## Gaps Summary

Phase 161 does not meet its goal. The source contains four concrete blockers: disconnected integrity metadata in the actual host path, a malformed-required-pack activation bypass, revocation/reconciliation race, and a generated proof lane that reports success without installation or audio behavior. Passing Swift, ExUnit, and simulator commands are not sufficient evidence because their tests either use fakes or assert the Boolean/marker implementation itself.

Phase 162 only owns physical-iPhone promotion; it does not explicitly cover these implementation defects. They are not deferred.

---

_Verified: 2026-08-03T16:47:57Z_
_Verifier: the agent (gsd-verifier)_
