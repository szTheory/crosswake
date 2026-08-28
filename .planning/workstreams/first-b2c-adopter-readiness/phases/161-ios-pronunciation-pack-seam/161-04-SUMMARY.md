---
phase: 161-ios-pronunciation-pack-seam
plan: "04"
subsystem: generated-ios-proof-lane
tags: [ios, proof-lane, pronunciation-pack, xctest, xcuittest, privacy]
requires:
  - phase: 159-host-reusable-proof-lane
    provides: Host-owned generated iOS proof scaffold and closed evidence schema
  - phase: 161-ios-pronunciation-pack-seam
    provides: Foreground PackProvider lifecycle vocabulary
provides:
  - Missing-only generated real-byte pronunciation fixture
  - Closed foreground install and offline-audio proof callbacks
  - Advisory-only reference-adapter simulator proof for pack_audio_prerequisite
affects: [phase-161-final-gate, phase-162-physical-iphone-proof]
tech-stack:
  added: []
  patterns: [host-owned-fixture, closed-proof-outcomes, stable-accessibility-ids, exact-marker-verification]
key-files:
  created:
    - priv/templates/crosswake/proof_lane/ios/Resources/pronunciation-pack-fixture.bin.eex
  modified:
    - lib/crosswake/proof_lane/generator.ex
    - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
    - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
    - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
    - script/verify_generated_ios_shell.sh
    - test/crosswake/proof_lane/template_contract_test.exs
    - test/crosswake/proof_lane/ios_verifier_test.exs
decisions:
  - Default generated proof stays non-passing; only explicit reference-pack-adapter mode can emit the closed advisory pack_audio_prerequisite pass.
  - Exact XCTest/XCUITest markers, rather than generic xcodebuild success, are required for advisory pack/audio proof.
metrics:
  duration: 16m
  completed_date: 2026-08-03
  tasks: 2
  files: 10
status: complete
---

# Phase 161 Plan 04: Generated iOS Pronunciation Pack Proof Summary

The existing Phase 159 generated proof lane now exercises a host-owned immutable fixture through foreground installation, persisted relaunch reconciliation, and offline pronunciation audio while retaining only closed advisory evidence.

## Completed Tasks

1. Added a version-3 missing-only fixture resource, Xcode membership, closed generated adapter callbacks, and deterministic XCTest pack lifecycle coverage.
2. Added accessibility-only install/audio UI flow, exact reference-adapter verifier markers, and advisory-only `pack_audio_prerequisite` output.

## Verification

- `mix test test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — 23 tests passed.
- `mix test test/crosswake/proof_lane/evidence_test.exs` — 22 tests passed.
- Full planned verifier command passed: default `--proof-lane` emitted a non-passing closed outcome; explicit `--reference-pack-adapter` emitted only `{"outcome":"passed","rule_id":"PL-IOS-PACK-AUDIO-ADVISORY","scope":"pack_audio_prerequisite"}`.
- `bash -n script/verify_generated_ios_shell.sh` and `git diff --check` passed.

## Decisions Made

- The generated reference adapter is selected only by the explicit verifier mode and is never the ordinary host factory default.
- The simulator result is advisory and creates no physical-device, support, Android, background-transfer, or generic-storage claim.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the generated fixture and all declared templates/verifier tests exist.
- Confirmed task commits `8626563c`, `1a90c2f5`, `e2ce3180`, and `209c8210` exist.
