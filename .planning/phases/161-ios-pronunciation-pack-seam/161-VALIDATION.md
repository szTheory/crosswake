---
phase: 161
slug: ios-pronunciation-pack-seam
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| **Full suite command** | `mix test test/crosswake/proof_lane test/crosswake/offline/proof_lane_test.exs test/crosswake/proof_lane/ios_verifier_test.exs && swift test --package-path packages/crosswake-shell-core-ios && xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CrosswakeShellTests/PronunciationPackProviderTests test CODE_SIGNING_ALLOWED=NO && xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CrosswakeShellTests/RequiredPackViewTests test CODE_SIGNING_ALLOWED=NO` |
| **Estimated runtime** | ~180 seconds |

---

## Phase 160 Preservation Gates (T-161-23)

These exact current, non-watch commands are mandatory parts of Plan 161-05's final same-tree gate. They preserve scoped replay, backend authorization, Sigra, privacy/egress, and browser proof while Phase 161 changes pack availability.

| Contract preserved | Exact automated command |
|---|---|
| Scoped offline privacy and egress | `mix test test/crosswake/offline test/crosswake/telemetry_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs` |
| Sigra closed authority projection | `(cd packages/crosswake_sigra && mix deps.get && mix test test/crosswake/companions/sigra/contracts_test.exs)` |
| Phoenix request-bound `local_first` authorization | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first test/crosswake_example/e2e)` |
| Complete offline-island browser proof | `(cd examples/phoenix_host && npm run proof:offline-island)` |

All four must pass in the same Plan 161-05 execution before T-161-23 can be recorded green.

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
| 161-01-01 | 161-01 | 1 | PACK-01, PACK-02, PACK-03, PACK-04 | T-161-01, T-161-02, T-161-03, T-161-04 | Real fixture bytes reach route activation only after exact binding, atomic promotion, persistence, and fresh status; nil/malformed paths block | XCTest tracer + API shape | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests/testVerifiedFixturePromotesThenFreshStatusUnblocksActivation` | ✅ | ✅ green |
| 161-01-02 | 161-01 | 1 | PACK-01, PACK-02, PACK-04 | T-161-02, T-161-03, T-161-04 | Optional host injection, checking-first bootstrap, closed failures, and nil provider remain unavailable | XCTest unit + activation contract | `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests` | ✅ | ✅ green |
| 161-02-01 | 161-02 | 2 | PACK-02, PACK-03, PACK-04 | T-161-05, T-161-06, T-161-07, T-161-10 | Concrete example-host provider stages/verifies/promotes/persists the real fixture in order, survives new-provider relaunch, and preserves known-good under every injected replacement fault | Example-host simulator XCTest + package fault regression | `swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests && xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CrosswakeShellTests/PronunciationPackProviderTests test CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES` | ✅ | ✅ green |
| 161-02-02 | 161-02 | 2 | PACK-02, PACK-04 | T-161-08, T-161-09, T-161-10 | Concrete example-host provider and core enforce revoke-first success/failure across relaunch while serialized install/invalidate races fence stale completion | Example-host simulator XCTest + package lifecycle/concurrency | `swift test --package-path packages/crosswake-shell-core-ios --filter PackStoreTests && swift test --package-path packages/crosswake-shell-core-ios --filter PackProviderFixtureTests && xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CrosswakeShellTests/PronunciationPackProviderTests test CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES` | ✅ | ✅ green |
| 161-03-01 | 161-03 | 3 | PACK-01, PACK-02, PACK-04, PACK-05 | T-161-11, T-161-12, T-161-13, T-161-14 | Reference provider injection and accessible one-action foreground recovery expose only safe semantic facts | Example-host simulator XCTest | `xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:CrosswakeShellTests/RequiredPackViewTests test CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES` | ✅ | ✅ green |
| 161-04-01 | 161-04 | 3 | PACK-01, PACK-03, PACK-04 | T-161-16, T-161-17, T-161-19 | Generated real fixture, host install/relaunch, and separate audio operation stay inside the Phase 159 lane | ExUnit template + generated XCTest contract | `mix test test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs` | ✅ | ✅ green |
| 161-04-02 | 161-04 | 3 | PACK-03, PACK-04, PACK-05 | T-161-15, T-161-16, T-161-18 | Stable-ID XCUITest and exact verifier markers prove advisory install/relaunch/network-disabled audio without support promotion | ExUnit verifier/template + rendered-host simulator XCTest/XCUITest | `env -u CROSSWAKE_IOS_XCODEBUILD_BIN -u CROSSWAKE_IOS_PROJECT_ROOT -u CROSSWAKE_IOS_SHIM_MODE CROSSWAKE_IOS_USE_LOCAL_CORE=1 CROSSWAKE_IOS_LAUNCH_SIMULATOR=1 bash script/verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter` | ✅ | ✅ green (advisory) |
| 161-05-01 | 161-05 | 4 | PACK-01, PACK-02, PACK-03, PACK-04, PACK-05 | T-161-20, T-161-21, T-161-22, T-161-23, T-161-24 | Exact evidence allowlist, concrete host-provider matrix, complete current-tree gate, executed host UI, positive advisory reference-adapter lane, all four Phase 160 preservation gates above, and no-external-API seal close deterministic phase truth | Swift/Xcode/ExUnit/browser/artifact inspection | Run Plan 161-05 Task 1's complete `<verify><automated>` chain, including every command in **Phase 160 Preservation Gates (T-161-23)** above. | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift` — lifecycle, reconciliation, revocation, nil/malformed provider, and activation-denial tests for PACK-01 and PACK-02.
- [ ] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackProviderFixtureTests.swift` plus a non-sensitive immutable fixture resource — real bytes, exact size/digest, atomic promotion, persistence, last-known-good preservation, relaunch, and fault injection for PACK-02 and PACK-03.
- [ ] `examples/ios_shell_host/CrosswakeShellTests/PronunciationPackProviderTests.swift` plus executable `CrosswakeShellTests` source/resource project membership — compile and exercise the actual example-host provider for real fixture integrity, same-volume promotion, inventory/new-provider relaunch, known-good replacement, successful/failed invalidation, and serialized install/invalidate races without retaining private values.
- [ ] The smallest injectable host-private Codable file-backed inventory store — writes only after promotion and supports deterministic persistence-failure and newly constructed provider/store relaunch tests without logging private details.
- [ ] Generated proof-lane adapter, contract-test, and UI-test template coverage — closed `pack_audio_prerequisite`, stable accessibility identifiers, terminate/relaunch, and host-owned offline audio operation.
- [ ] ExUnit source/template/evidence regressions — reject asset paths, URLs, digest values, archive bytes, media, `.xcresult`, screenshots, logs, and raw output from retained evidence.

---

## Manual-Only Verifications

All Phase 161 behaviors have automated verification. Physical-iPhone setup and promotion are explicitly owned by Phase 162, not this validation contract.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Every previously missing Wave 0 reference is created before or with the production behavior it verifies by Plans 161-01 through 161-04; Plan 161-05 supplies the final same-tree backstop.
- [x] No watch-mode flags are used.
- [x] Feedback latency remains below 180 seconds for the default local loop.
- [x] `nyquist_compliant: true` is set in frontmatter after all plan task mappings are finalized and executable.

**Approval:** complete from the fresh 2026-08-03 post-WR-01/CR-01 final-tree gate.

---

## Fresh Post-Crash-Recovery Final-Tree Gate

Retained evidence is the allowlisted machine-readable object below. Dynamic run facts appear only in this object so they can be compared mechanically; raw native output and private values are excluded.

<!-- phase161-final-run-manifest:start -->
{
  "schema": 5,
  "run_id": "30357CD0-2064-4539-ACB5-F2E06E603626",
  "head_revision": "b133fda73583e9435903b526b20982211b1b12bc",
  "subject": {
    "set": "phase161-plans19-20-v5",
    "file_count": 2,
    "tree_sha256": "5fa5ec44ad2082f568e40fab5c035bc53feecbcb1454fdcb1fc67264d0a56e85"
  },
  "suite_counts": {
    "swift_core": 27,
    "host_xctest": 4,
    "proof_lane": 53,
    "privacy": 121,
    "sigra": 15,
    "phoenix": 33,
    "browser": 23
  },
  "restart_outcomes": {
    "retained_old": "passed",
    "promoted_inventory_pending": "passed",
    "inventory_committed": "passed",
    "idempotence": "passed",
    "malformed_schema_phase_denied": "passed",
    "sibling_destination_denied": "passed",
    "record_identity_version_denied": "passed",
    "colliding_leaves_denied": "passed",
    "non_regular_denied": "passed",
    "stale_inventory_absent_artifact": "passed"
  },
  "bootstrap_outcomes": {
    "construction_started": "passed",
    "in_flight_status_awaited_existing": "passed",
    "repeated_status_unchanged": "passed",
    "failure_memoized_no_mutation": "passed"
  },
  "volume_anchor_outcomes": {
    "retained_old_absent_destination": "passed",
    "first_install_absent_destination": "passed",
    "mismatched_existing_leaf_denied": "passed"
  },
  "invalidate_recovery_outcomes": {
    "retained_old_before_revocation": "passed",
    "promoted_inventory_pending_before_revocation": "passed"
  },
  "durability_outcomes": {
    "retention_order": "passed",
    "promotion_order": "passed",
    "inventory_before_committed_cleanup": "passed",
    "committed_cleanup_order": "passed"
  },
  "ui_backstops": {
    "recovery_wrap_reachability": "passed",
    "announcement_focus": "passed",
    "action_wrap_targets": "passed",
    "developer_context": "passed"
  },
  "requirements": {
    "PACK_01": "passed",
    "PACK_02": "passed",
    "PACK_03": "passed",
    "PACK_04": "passed",
    "PACK_05": "passed_non_claim"
  },
  "threats": {
    "T_161_82": "passed",
    "T_161_83": "passed",
    "T_161_84": "passed",
    "T_161_85": "passed",
    "T_161_86": "passed",
    "T_161_87": "passed",
    "T_161_88": "passed",
    "T_161_89": "passed",
    "T_161_90": "passed",
    "T_161_91": "passed",
    "T_161_92": "passed",
    "T_161_93": "passed",
    "T_161_94": "passed",
    "T_161_97": "passed",
    "T_161_98": "passed",
    "T_161_99": "passed"
  },
  "generated": {
    "default": "closed_non_passing",
    "reference": "passed_simulator_advisory"
  },
  "generated_current_run": {
    "reset_initial_blocked": "passed",
    "foreground_install_passed": "passed",
    "relaunch_readback_passed": "passed",
    "offline_audio_passed": "passed"
  },
  "api_coverage": "passed",
  "ui_spec": {
    "covered": 12,
    "backstop": 4,
    "dismissed": 2,
    "unresolved": 0
  },
  "boundaries": {
    "todo_002": "unknown_blocking",
    "adopter_instance": "unknown_blocking",
    "physical_iphone_promotion": "phase_162_only"
  }
}
<!-- phase161-final-run-manifest:end -->

### Boundaries Retained

The object above is simulator-advisory evidence only. Adopter-instance and physical-device promotion remain outside Phase 161, and the foreground iOS stop list remains unchanged.
