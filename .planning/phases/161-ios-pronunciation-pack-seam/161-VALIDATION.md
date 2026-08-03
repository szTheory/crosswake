---
phase: 161
slug: ios-pronunciation-pack-seam
status: planned
nyquist_compliant: true
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
| 161-01-01 | 161-01 | 1 | PACK-01, PACK-02, PACK-03, PACK-04 | T-161-01, T-161-02, T-161-03, T-161-04 | Real fixture bytes reach route activation only after exact binding, atomic promotion, persistence, and fresh status; nil/malformed paths block | XCTest tracer + API shape | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests/testVerifiedFixturePromotesThenFreshStatusUnblocksActivation` | ❌ task creates | ⬜ pending |
| 161-01-02 | 161-01 | 1 | PACK-01, PACK-02, PACK-04 | T-161-02, T-161-03, T-161-04 | Optional host injection, checking-first bootstrap, closed failures, and nil provider remain unavailable | XCTest unit + activation contract | `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests` | ❌ task creates | ⬜ pending |
| 161-02-01 | 161-02 | 2 | PACK-02, PACK-03, PACK-04 | T-161-05, T-161-06, T-161-07, T-161-10 | Host provider stages/verifies/promotes/persists in order and preserves known-good under every injected fault | XCTest real-byte fault injection | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests` | ❌ task extends | ⬜ pending |
| 161-02-02 | 161-02 | 2 | PACK-02, PACK-04 | T-161-08, T-161-09, T-161-10 | Revoke-first invalidation survives relaunch and per-pack serialization fences stale/parallel completion | XCTest lifecycle/concurrency | `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests` | ❌ task extends | ⬜ pending |
| 161-03-01 | 161-03 | 3 | PACK-01, PACK-02, PACK-04, PACK-05 | T-161-11, T-161-12, T-161-13, T-161-14 | Reference provider injection and accessible one-action foreground recovery expose only safe semantic facts | Example-host XCTest/build | `xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'generic/platform=iOS Simulator' build-for-testing CODE_SIGNING_ALLOWED=NO` | ❌ task creates | ⬜ pending |
| 161-04-01 | 161-04 | 3 | PACK-01, PACK-03, PACK-04 | T-161-16, T-161-17, T-161-19 | Generated real fixture, host install/relaunch, and separate audio operation stay inside the Phase 159 lane | ExUnit template + generated XCTest contract | `mix test test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs` | ⚠️ task extends | ⬜ pending |
| 161-04-02 | 161-04 | 3 | PACK-03, PACK-04, PACK-05 | T-161-15, T-161-16, T-161-18 | Stable-ID XCUITest and exact verifier markers prove advisory install/relaunch/offline audio without support promotion | ExUnit verifier/template + advisory native command | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | ⚠️ task extends | ⬜ pending |
| 161-05-01 | 161-05 | 4 | PACK-01, PACK-02, PACK-03, PACK-04, PACK-05 | T-161-20, T-161-21, T-161-22, T-161-23, T-161-24 | Exact evidence allowlist, complete current-tree gate, advisory boundary, and no-external-API seal close deterministic phase truth | Swift/Xcode/ExUnit/artifact inspection | `swift test --package-path packages/crosswake-shell-core-ios && mix test test/crosswake/proof_lane test/crosswake/offline/proof_lane_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` | ⚠️ task extends | ⬜ pending |

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
- [x] Every previously missing Wave 0 reference is created before or with the production behavior it verifies by Plans 161-01 through 161-04; Plan 161-05 supplies the final same-tree backstop.
- [ ] No watch-mode flags are used.
- [ ] Feedback latency remains below 180 seconds for the default local loop.
- [ ] `nyquist_compliant: true` is set in frontmatter after all plan task mappings are finalized and executable.

**Approval:** pending
