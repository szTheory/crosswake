---
phase: 156
slug: native-menu-action-button-control
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-30
---

# Phase 156 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Node built-in test runner, SwiftPM/XCTest, Android Gradle/JUnit, Playwright |
| **Config file** | `mix.exs`, `packages/crosswake-shell-core-ios/Package.swift`, `packages/crosswake-shell-core-android/build.gradle.kts`, `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `mix test test/crosswake/bridge/push_test.exs test/crosswake/bridge/registry_test.exs test/crosswake/policy/route_test.exs -x` |
| **Full suite command** | `mix verify && node --test test/js/ && swift test --package-path packages/crosswake-shell-core-ios && (brew list openjdk@17 >/dev/null 2>&1 || brew install openjdk@17) && export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home" && export PATH="$JAVA_HOME/bin:$PATH" && "$JAVA_HOME/bin/java" -version && ./gradlew -p packages/crosswake-shell-core-android test` |
| **Estimated runtime** | ~15 minutes after the one-time bottled OpenJDK 17 setup |

---

## Sampling Rate

- **After every task commit:** Run the targeted command for the tier changed by that task.
- **After every plan wave:** Run `mix verify`, `node --test test/js/`, SwiftPM tests, and the Android JVM suite through the explicit Homebrew OpenJDK 17 bootstrap/export used by Plans 04 and 07.
- **Before `$gsd-verify-work`:** The full suite, browser fallback proof, and both native vector harnesses must be green.
- **Max feedback latency:** 15 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 156-01-01 | 01 | 1 | MENU-01 | T-156-01 | The D-09/D-26/D-31 one-way publication gate resolves before implementation. | context gate | `rg -n 'D-09:|D-26:|D-31:' .planning/phases/156-native-menu-action-button-control/156-CONTEXT.md` | ✅ exists | ⬜ pending |
| 156-02-01 | 02 | 2 | MENU-01 | T-156-01, T-156-04 | Route policy is the only allowlist and the shared projection enforces all bounds. | unit | `mix test test/crosswake/policy/route_test.exs test/crosswake/manifest/builder_test.exs test/crosswake/bridge/action_menu_test.exs -x` | ❌ created by task | ⬜ pending |
| 156-02-02 | 02 | 2 | MENU-02 | T-156-01, T-156-03 | Contract 1.2.0 returns typed selected/dismissed replies and preserves truthful failure layers. | unit | `mix test test/crosswake/bridge/action_menu_test.exs test/crosswake/bridge/push_test.exs test/crosswake/bridge/registry_test.exs -x` | ❌ created by task | ⬜ pending |
| 156-02-03 | 02 | 2 | MENU-01, MENU-02 | T-156-02 | Explicit anchors and stale-shell facts fail before native posting. | JS + unit | `node --test test/js/crosswake_esm_test.mjs && mix test test/crosswake/bridge/action_menu_test.exs -x` | ✅ extend | ⬜ pending |
| 156-03-01 | 03 | 3 | MENU-02, MENU-03 | T-156-I1, T-156-I3 | Swift fake presenter records semantics and completes exactly once. | native contract | `swift test --package-path packages/crosswake-shell-core-ios --filter 'ActionMenuPresenterTests|BridgeConformanceTests'` | ❌ created by task | ⬜ pending |
| 156-03-02 | 03 | 3 | MENU-02, MENU-03 | T-156-I2 | UIKit action sheet is real and iPad anchoring fails closed. | native source + unit | `swift test --package-path packages/crosswake-shell-core-ios` | ❌ created by task | ⬜ pending |
| 156-04-01 | 04 | 3 | MENU-02, MENU-03 | T-156-A1, T-156-A3 | Kotlin fake presenter records semantics and completes exactly once. | native contract | `(brew list openjdk@17 >/dev/null 2>&1 || brew install openjdk@17) && export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home" && "$JAVA_HOME/bin/java" -version && ./gradlew -p packages/crosswake-shell-core-android test --tests '*ActionMenuPresenterTest' --tests '*BridgeConformanceTest'` | ❌ created by task | ⬜ pending |
| 156-04-02 | 04 | 3 | MENU-02, MENU-03 | T-156-A2 | Android PopupMenu uses a bounded anchor and fails closed. | JVM + source | `export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home" && "$JAVA_HOME/bin/java" -version && ./gradlew -p packages/crosswake-shell-core-android test` | ❌ created by task | ⬜ pending |
| 156-05-01 | 05 | 3 | MENU-02, MENU-03 | T-156-R1, T-156-R2 | Fallback/native races resolve once and cancel stale chrome. | unit + JS | `mix test test/crosswake/bridge/action_menu_test.exs test/crosswake/bridge/push_test.exs -x && node --test test/js/crosswake_esm_test.mjs` | ❌ created by plan 02 | ⬜ pending |
| 156-05-02 | 05 | 3 | MENU-02 | T-156-R3 | Lifecycle telemetry is complete and excludes sensitive/high-cardinality values. | unit | `mix test test/crosswake/bridge/action_menu_test.exs test/crosswake/telemetry_test.exs test/crosswake/proof/phase133_telemetry_contract_test.exs -x` | ✅ extend | ⬜ pending |
| 156-06-01 | 06 | 4 | MENU-01, MENU-02, MENU-03 | T-156-U1, T-156-U2 | Phoenix trigger/fallback/native outcome path reauthorizes before mutation. | LiveView | `mix test examples/phoenix_host/test/crosswake_example/saas_portal/approval_live_test.exs -x` | ✅ extend | ⬜ pending |
| 156-06-02 | 06 | 4 | MENU-01, MENU-03 | T-156-U3 | All UI states plus 320px wrap/reachability backstop stay usable. | browser | `npm --prefix examples/phoenix_host run test:e2e -- --grep 'native controls|action menu'` | ✅ extend | ⬜ pending |
| 156-07-01 | 07 | 4 | MENU-02, MENU-03, PROOF-03 | T-156-P1, T-156-P2 | One corpus drives both real evaluators/fake presenters and a negative control proves non-vacuity. | vector + drift | `mix test test/crosswake/contract/contract_drift_test.exs test/crosswake/proof/phase156_action_menu_proof_test.exs -x && swift test --package-path packages/crosswake-shell-core-ios && export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home" && "$JAVA_HOME/bin/java" -version && ./gradlew -p packages/crosswake-shell-core-android test` | ❌ proof file created by task | ⬜ pending |
| 156-08-01 | 08 | 5 | MENU-01, MENU-03, PROOF-03 | T-156-S1, T-156-S2 | Support/rebuild truth and accessibility non-claims are structurally guarded after native proof is green. | unit + source | `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/proof/phase156_action_menu_proof_test.exs -x` | ❌ proof file created by Plan 07 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Plan 156-02 creates `test/crosswake/bridge/action_menu_test.exs` before production behavior and extends policy/manifest/hook tests.
- [x] Plans 156-03 and 156-04 create fake-presenter tests before real presenter adapters.
- [x] Plan 156-07 creates the Phase 156 proof guard and fail-first negative control before claiming PROOF-03.
- [x] Every later task depends on the plan that creates its missing test file.
- [x] Android proof bootstraps bottled Homebrew `openjdk@17`, exports its keg-only `JAVA_HOME`, verifies the runtime, and then runs the exact Gradle gate; the existing `android-package-unit` CI lane remains the independent merge-blocking proof.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| VoiceOver/TalkBack speech, focus order, dynamic type/font scaling, final platform chrome, and physical tap-outside/Back behavior | MENU-03 | Hostless XCTest/JVM vectors prove semantic adapter wiring but cannot honestly prove assistive-technology speech or final device interaction. | On one supported iOS device/simulator and Android device/emulator, open the Actions trigger; inspect spoken labels, disabled explanations, focus, scaling, destructive treatment, selection, tap-outside/Back dismissal, and focus return. Record this as advisory evidence rather than a merge-blocking requirement. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is below 15 minutes.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** approved for the eight-plan decomposition
