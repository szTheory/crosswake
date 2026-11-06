---
phase: 198-android-foreign-host-proof
plan: 04
subsystem: android-shell-core-contract
tags: [kotlin, contract-gen, vector-set-hash, sha256, gitattributes, artifact-policy]
status: complete

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 03: Kotlin test floor checker (floor script used for the 39-test floor)"
provides:
  - "mix crosswake.contract.gen writes VectorSetHash.kt: the sha256 of the exact corpus bytes written to the three copies"
  - "VectorCorpus.loadVerifiedBytes(): the single Kotlin corpus loader, CW-VECTOR-MISSING first then CW-VECTOR-HASH"
  - "VectorCorpusTest: positive control plus flipped-byte mismatch test"
  - "Narrow .gitattributes LF pins; Kotlin constant declared as generated output with the phase166 pin"
affects: [198-05, 198-07]

actuals:
  tokens: 9000
  tasks: 3
  commits: 3
plan_head_before: 586def5ec614b6d424274feec1aa991f3024e8c7
plan_head_after: 7cbeec41746285a2159f8821d3041fddeec03b71

tech-stack:
  added: []
  patterns: ["one encoded binary hashed and written (hash of bytes on disk, not of a re-encoded structure)", "single verified loader; callers decode with toString(UTF_8) from the hashed bytes"]

key-files:
  created:
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/VectorSetHash.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/VectorCorpus.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/VectorCorpusTest.kt
    - .gitattributes
  modified:
    - lib/mix/tasks/crosswake.contract.gen.ex
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeReplyLegTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeFixtures.kt
    - script/repository_artifact_policy.json
    - test/crosswake/proof/phase166_repository_quality_test.exs

key-decisions:
  - "The constant is `3b64c8d8...64c0`, the sha256 of the 15-vector corpus as committed; regenerating is a no-op and the three corpus copies and docs snippet did not change"
  - ".gitattributes lists the Swift constant path (VectorSetHash.swift) now even though Plan 05 creates it, as the plan specified; a pattern for an absent file is inert"

requirements-completed: []

coverage:
  - id: D1
    description: "Generator emits the Kotlin hash from the bytes it wrote; second run prints unchanged"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "mix crosswake.contract.gen: corpus copies and docs snippet git diff clean; constant matches sha256 of raw corpus (python check, 1 anchored match)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every Kotlin corpus load verifies against the constant; mismatch fails with CW-VECTOR-HASH"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "Gradle cleanTestDebugUnitTest testDebugUnitTest green; floor checker kotlin-floor: tests=39 source_tests=39 boundary=20 verdict=PASS; only VectorCorpus.kt names the corpus resource; mutating the constant to 00... turned the suite red (gradle exit 1) and regenerating restored it"
        status: pass
    human_judgment: false
  - id: D3
    description: "LF pins and declared generated output"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "git ls-files --eol shows i/lf attr/text eol=lf; output_paths sorted/unique (9); mix_test_gate phase166+contract_drift 21/21 PASS; node repository_verification 41 pass 0 fail"
        status: pass
    human_judgment: false
---

# Phase 198 Plan 04: Kotlin vector-set hash Summary

The generator now hashes the one corpus binary it writes and emits `VectorSetHash.kt`; every Kotlin corpus load goes through `VectorCorpus.loadVerifiedBytes()`, which refuses any other bytes.

## What was checked and what happened

- Baselines re-measured on the branch before the first edit (I-5): Kotlin floor `tests=37 source_tests=37 boundary=20`; `phase166 + contract_drift` mix gate `ran=21`. The plan's floors (39 Kotlin tests, 21 mix tests) equal measured baseline plus the added count (37 + 2; 21 + 0), so no floor was changed.
- Task 1 (tracer, `bb2d2345`): generator extended; `VectorCorpus`, `VectorCorpusTest` added; `BridgeConformanceTest` routed through the verified loader with `CW-VECTOR-LOADED expected 15`/`14` and the 3-test count and test name untouched. Gradle forced run green, floor `tests=39` PASS. Tracer gate: the same `<verify>` was re-run end to end and passed before expanding.
- Task 2 (`16eee8d6`): `BridgeReplyLegTest`, `ActivationConformanceTest` and `BridgeFixtures` (two reads) routed through the loader. Only `VectorCorpus.kt` names `bridge_contract_vectors.json` now.
- Task 3 (`7cbeec41`): six-pattern `.gitattributes`; `VectorSetHash.kt` added to `generated_contracts[0].output_paths` (byte-sorted, 9 paths) and the phase166 pin; docs-sync record untouched (Plan 07 owns it).
- Extra check beyond the plan: temporarily changed the constant to a wrong hash and confirmed the Kotlin suite fails (Gradle exit 1), then regenerated to restore it. The working tree shows no diff on the constant.

Claim ceiling: JVM evidence only. Nothing was run on a device. CI itself is unobserved until a PR runs; this plan did not push.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Compiler warning from clause grouping**
- **Found during:** Task 1
- **Issue:** First placement of `kotlin_vector_set_hash/1` fell between two `convert_value/1` clauses, producing a "clauses should be grouped" warning (would fail `mix compile --warnings-as-errors`).
- **Fix:** Moved the function to sit before `docs_snippet/1`; compile with `--warnings-as-errors --force` and format check both exit 0.
- **Files modified:** lib/mix/tasks/crosswake.contract.gen.ex
- **Commit:** bb2d2345

Otherwise none: plan executed as written. AND-01 is deliberately not marked complete: this is the Kotlin half only; the Swift half is Plan 05 and the equality ledger test is Plan 07.

## Known Stubs

None.

## Threat Flags

None. The threat register's T-198-13, T-198-14 and T-198-15 mitigations are all in place (verified loader plus flipped-byte test; hash computed from the written binary and declared output; LF pins).

## Self-Check: PASSED

- Files present: VectorSetHash.kt, VectorCorpus.kt, VectorCorpusTest.kt, .gitattributes (all found).
- Commits bb2d2345, 16eee8d6, 7cbeec41 are ancestors of HEAD; `git rev-list --count 586def5e..HEAD` was 3 before this SUMMARY commit.
