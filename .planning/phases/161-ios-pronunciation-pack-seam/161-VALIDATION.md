---
phase: 161
slug: ios-pronunciation-pack-seam
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-03
---

# Phase 161 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift XCTest for `CrosswakeShellCore`; generated XCTest/XCUITest host proof from Phase 159; ExUnit for proof-lane generation and evidence contracts |
| **Config file** | `packages/crosswake-shell-core-ios/Package.swift` plus the generated iOS Xcode project and scheme |
| **Quick run command** | `swift test --package-path packages/crosswake-shell-core-ios` |
| **Full suite command** | `mix test test/crosswake/proof_lane test/crosswake/offline/proof_lane_test.exs test/crosswake/proof_lane/ios_verifier_test.exs && swift test --package-path packages/crosswake-shell-core-ios` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused Swift XCTest or ExUnit command named by the task, then `swift test --package-path packages/crosswake-shell-core-ios` when Swift core code changed.
- **After every plan wave:** Run `mix test test/crosswake/proof_lane test/crosswake/offline/proof_lane_test.exs test/crosswake/proof_lane/ios_verifier_test.exs && swift test --package-path packages/crosswake-shell-core-ios`.
- **Before `$gsd-verify-work`:** The full suite must be green; generated simulator/XCUITest results remain advisory and non-promoting.
- **Max feedback latency:** 180 seconds for the default local contract loop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 161-W0-01 | TBD | 0 | PACK-01 | T-161-02 | Nil, malformed, cancelled, and failed provider results remain unavailable | XCTest unit + compile contract | `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests/testNilProviderIsUnavailable` | ❌ W0 | ⬜ pending |
| 161-W0-02 | TBD | 0 | PACK-02 | T-161-01, T-161-04, T-161-06 | Every integrity, persistence, invalidation, and concurrency failure remains blocked | XCTest fault injection | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests` | ❌ W0 | ⬜ pending |
| 161-W0-03 | TBD | 0 | PACK-03 | T-161-01, T-161-03 | Real fixture bytes are size/hash verified and atomically promoted before reconciliation grants availability | XCTest integration fixture | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests/testVerifiedFixturePromotesThenReconcilesAvailable` | ❌ W0 | ⬜ pending |
| 161-W0-04 | TBD | 0 | PACK-04 | T-161-02, T-161-05 | Public/core and retained-evidence surfaces exclude URLs, paths, errors, digest values, archive layout, and raw output | XCTest API shape + ExUnit template contract | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | ⚠️ partial | ⬜ pending |
| 161-W0-05 | TBD | 0 | PACK-05 | T-161-05 | The proof lane remains foreground iOS-only and retains only allowlisted closed assertion outcomes | ExUnit source/evidence contract | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs` | ✅ extend | ⬜ pending |
| 161-W0-06 | TBD | 0 | PACK-01, PACK-03 | T-161-02, T-161-03 | Missing-provider denial, install-to-ready, relaunch persistence, and host-owned offline audio are observable without filesystem inspection | Generated XCUITest, simulator advisory | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift` — lifecycle, reconciliation, revocation, nil/malformed provider, and activation-denial tests for PACK-01 and PACK-02.
- [ ] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackProviderFixtureTests.swift` plus a non-sensitive immutable fixture resource — real bytes, exact size/digest, atomic promotion, persistence, last-known-good preservation, relaunch, and fault injection for PACK-02 and PACK-03.
- [ ] A host-private fixture provider/storage abstraction — deterministic transfer, storage, promotion, and persistence failures without logging private details.
- [ ] Generated proof-lane adapter, contract-test, and UI-test template coverage — closed `pack_audio_prerequisite`, stable accessibility identifiers, terminate/relaunch, and host-owned offline audio operation.
- [ ] ExUnit source/template/evidence regressions — reject asset paths, URLs, digest values, archive bytes, media, `.xcresult`, screenshots, logs, and raw output from retained evidence.

---

## Manual-Only Verifications

All Phase 161 behaviors have automated verification. Physical-iPhone setup and promotion are explicitly owned by Phase 162, not this validation contract.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers every missing test reference above.
- [ ] No watch-mode flags are used.
- [ ] Feedback latency remains below 180 seconds for the default local loop.
- [ ] `nyquist_compliant: true` is set in frontmatter after all plan task mappings are finalized and executable.

**Approval:** pending
