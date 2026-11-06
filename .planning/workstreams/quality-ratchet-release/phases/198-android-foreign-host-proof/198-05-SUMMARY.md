---
phase: 198-android-foreign-host-proof
plan: 05
subsystem: ios-shell-core-contract
tags: [swift, contract-gen, vector-set-hash, sha256, cryptokit, byte-flip-evidence]
status: complete

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 04: Kotlin constant, the single `hex` binding in contract.gen, LF pins"
provides:
  - "mix crosswake.contract.gen writes VectorSetHash.swift (Tests root, not Resources/) from the same hex as the Kotlin constant"
  - "VectorCorpus (Swift): verifiedData(contentsOf:), verify(_:expected:), sha256Hex(_:); CW-VECTOR-HASH on mismatch, no canImport skip"
  - "VectorCorpusTests: positive control plus flipped-byte mismatch test"
  - "All five Swift bridge-corpus suites verify the bytes before decoding"
  - "One-time byte-flip evidence on both platforms (D-06)"
affects: [198-06, 198-07]

actuals:
  tokens: 6000
  tasks: 3
  commits: 3
plan_head_before: 0380484b74cbc44ea8e2cd9e22b92039581ce4a3
plan_head_after: a0671f456bdf1304e67dd4e00b9ca958a6f439bc

tech-stack:
  added: []
  patterns: ["one hex binding feeds both platform constants", "generated constant kept outside the bundle-copied Resources/ directory"]

key-files:
  created:
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/VectorSetHash.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/VectorCorpus.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/VectorCorpusTests.swift
  modified:
    - lib/mix/tasks/crosswake.contract.gen.ex
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/OfflineIslandAdmissionTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift
    - script/repository_artifact_policy.json
    - test/crosswake/proof/phase166_repository_quality_test.exs

key-decisions:
  - "The Swift constant equals the Kotlin constant `3b64c8d8...64c0` and the raw-bytes sha256 of test/fixtures/bridge_contract_vectors.json; regenerating changed no corpus copy"
  - "AND-01 is not marked complete: the requirement also needs the generated parity ledger and the test that Swift and Kotlin reference the same hash (Plans 06 and 07)"

requirements-completed: []

coverage:
  - id: D1
    description: "Swift constant generated from the same bytes as the Kotlin constant"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "python check: swift 1 anchored match, kotlin 1 anchored match, both equal raw-bytes sha256; corpus and Kotlin constant git diff clean after generation"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every Swift corpus loader verifies bytes; mismatch fails with CW-VECTOR-HASH"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "swift test 91 executed, 2 skipped, 0 failures (baseline 89); reader scan: 6 files name the bridge resource, 0 unverified; byte-flip run below"
        status: pass
    human_judgment: false
  - id: D3
    description: "Swift constant declared as generated output"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "output_paths sorted/unique with both constants; mix_test_gate phase166+contract_drift ran=21 PASS; node repository_verification pass 41 fail 0"
        status: pass
    human_judgment: false
---

# Phase 198 Plan 05: Swift vector-set hash Summary

The generator now also writes `VectorSetHash.swift` from the same hex as the Kotlin constant, and all five Swift suites that load the bridge corpus refuse any other bytes with `CW-VECTOR-HASH`.

## What was checked and what happened

- Baselines re-measured on the branch before the first edit (I-5): Swift `Executed 89 tests, with 2 tests skipped and 0 failures`; mix gate for phase166 plus contract_drift `ran=21`; node `repository_verification` 41 pass. The plan's floors (91 Swift, 21 mix) equal measured baseline plus the added count (89 + 2; 21 + 0), so no floor changed.
- Task 1 (tracer, `bc3b2984`): generator extension, `VectorCorpus.swift`, `VectorCorpusTests.swift`, `BridgeConformanceTests` loader swap. The `<verify>` was run end to end: constants equal each other and the raw sha256; Swift 91 executed, 0 failures; format and `--warnings-as-errors` compile exit 0; the Swift file is not under `Resources/`; zero `canImport` in the helper. Verified end to end before expanding.
- Task 2 (`2e1f9c32`): `BridgeReplyLegTests`, `ActivationConformanceTests`, `OfflineIslandAdmissionTests` and `Phase180TwinFeasibilityTests` load through `VectorCorpus.verifiedData`. Reader scan: 6 files name the bridge resource, none unverified. Each file still has one `CW-VECTOR-MISSING` unwrap. Navigation corpora were not touched (C4). Swift again 91 executed, 0 failures.
- Task 3 (`a0671f45`): `VectorSetHash.swift` added to `generated_contracts[0].output_paths` (byte-sorted, 10 paths, both constants) and to the phase166 pin. Gate `ran=21 PASS`; node 41 pass 0 fail.

## Byte-flip evidence

One-time phase evidence (D-06), not committed and not CI. Offset 256 in each copy: the last `0` of the first `"bridge_protocol_version": "1.1.0"` was changed to `7`, so the JSON stays parseable.

| Platform | Mutated path | Exit | First CW-VECTOR-HASH line | Restored run |
|---|---|---|---|---|
| Kotlin | `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` | 1 (Gradle: 39 tests completed, 31 failed) | `CW-VECTOR-HASH expected 3b64c8d81e1ca086494a1910aa5fb2d05d7a2d263b3d72f229f319d22e0064c0 got 79b891ed32a8d8b53ce9215e37c8ed8c8385b57c08b5f7f13dddacec185f470b` (from the Gradle XML report; the console shows only the test name) | `testDebugUnitTest` exit 0; floor checker `tests=39 source_tests=39 boundary=20 verdict=PASS` |
| Swift | `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json` | 1 (`Executed 91 tests, with 36 tests skipped and 38 failures`) | the same expected/got pair as above, printed by `swift test` | `swift test` exit 0, `Executed 91 tests, with 2 tests skipped and 0 failures` |

After each restore `git diff --exit-code` on the resource path passed, and `git status --porcelain` on both resource directories printed nothing at the end.

Notes: the Kotlin mutation turned the suite red in every corpus consumer and in `VectorCorpusTest` itself (its positive control and its flipped-byte test both load verified bytes first), which is the intended behavior. The Swift run skipped 36 tests because the setUp failures abort dependent tests; the failure count is what matters.

Claim ceiling: JVM and host-Swift evidence only. Nothing was run on a device. CI is unobserved until a PR runs; this plan did not push.

## Deviations from Plan

None - plan executed exactly as written. One observation, not a deviation: `python3 script/check_kotlin_test_floor.py --run` reports `gradle_failed` without `JAVA_HOME` set; with `JAVA_HOME=/opt/homebrew/opt/openjdk@17` it passes. Environment only.

AND-01 deliberately not marked complete: the requirement text also needs the parity ledger generated from `priv/contract_vectors/*.json` with an Android column and the test asserting both platforms reference the same hash (Plans 06 and 07). This plan completes the native half.

## Known Stubs

None.

## Threat Flags

None. T-198-16 (verified loaders, flipped-byte test, one-time byte-flip run) and T-198-17 (one `hex` binding, equality check against raw sha256) are mitigated.

## Self-Check: PASSED

- Files present: VectorSetHash.swift, VectorCorpus.swift, VectorCorpusTests.swift (found); not present under `Resources/`.
- Commits bc3b2984, 2e1f9c32, a0671f45 are ancestors of HEAD; `git rev-list --count 0380484b..HEAD` was 3 before this SUMMARY commit.
