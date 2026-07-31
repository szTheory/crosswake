---
phase: 156
slug: native-menu-action-button-control
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Full suite command** | `mix verify && node --test test/js/ && swift test --package-path packages/crosswake-shell-core-ios && ./gradlew -p packages/crosswake-shell-core-android test` |
| **Estimated runtime** | ~15 minutes, subject to macOS and Android runner availability |

---

## Sampling Rate

- **After every task commit:** Run the targeted command for the tier changed by that task.
- **After every plan wave:** Run `mix verify`, `node --test test/js/`, SwiftPM tests, and Android JVM tests when Java is available.
- **Before `$gsd-verify-work`:** The full suite, browser fallback proof, and both native vector harnesses must be green.
- **Max feedback latency:** 15 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 156-01-01 | 01 | 1 | MENU-01 | T-156-01 | Route policy is the only action allowlist and cross-field mismatches fail closed. | unit | `mix test test/crosswake/policy/route_test.exs test/crosswake/manifest/builder_test.exs -x` | ✅ extend | ⬜ pending |
| 156-02-01 | 02 | 1 | MENU-01, MENU-02 | T-156-01, T-156-04 | Runtime projections and anchor facts reject unauthorized, stale, or unbounded inputs before native dispatch. | unit + JS | `mix test test/crosswake/bridge/action_menu_test.exs -x && node --test test/js/` | ❌ W0 | ⬜ pending |
| 156-03-01 | 03 | 2 | MENU-02, MENU-03 | T-156-03 | iOS returns exactly one selected or dismissed reply and rejects unknown/disabled ids. | native contract | `swift test --package-path packages/crosswake-shell-core-ios` | ✅ extend | ⬜ pending |
| 156-04-01 | 04 | 2 | MENU-02, MENU-03 | T-156-03 | Android returns exactly one selected or dismissed reply and rejects unknown/disabled ids. | native contract | `./gradlew -p packages/crosswake-shell-core-android test` | ✅ extend | ⬜ pending |
| 156-05-01 | 05 | 3 | PROOF-03 | T-156-02, T-156-03 | One committed vector corpus proves dispatch, denial, selection, and dismissal on both native harnesses without simulator/emulator claims. | vector + drift | `mix test test/crosswake/contract/contract_drift_test.exs -x && swift test --package-path packages/crosswake-shell-core-ios && ./gradlew -p packages/crosswake-shell-core-android test` | ✅ extend | ⬜ pending |
| 156-06-01 | 06 | 3 | MENU-01, MENU-03 | — | The host fallback remains usable and accessible when native presentation is unavailable or denied. | browser + source | `mix test && npm --prefix examples/phoenix_host run test:e2e` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add `test/crosswake/bridge/action_menu_test.exs` for runtime projection validation, anchor option enforcement, typed selected/dismissed replies, and fallback/native race cancellation.
- [ ] Extend policy and manifest tests for the `action_menu` schema, route serialization, and capability/contract cross-field errors.
- [ ] Extend `test/js/crosswake_esm_test.mjs` for explicit-anchor measurement, invalid-anchor denial facts, stale-binary capability preflight, and cancellation.
- [ ] Extend the Swift and Kotlin vector harnesses with fake action-menu presenters.
- [ ] Provide Java runtime setup before local Android Gradle proof; CI remains the fallback lane until local Java is available.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| VoiceOver/TalkBack speech, focus order, dynamic type/font scaling, final platform chrome, and physical tap-outside/Back behavior | MENU-03 | Hostless XCTest/JVM vectors prove semantic adapter wiring but cannot honestly prove assistive-technology speech or final device interaction. | On one supported iOS device/simulator and Android device/emulator, open the Actions trigger; inspect spoken labels, disabled explanations, focus, scaling, destructive treatment, selection, tap-outside/Back dismissal, and focus return. Record this as advisory evidence rather than a merge-blocking requirement. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is below 15 minutes.
- [ ] `nyquist_compliant: true` is set in frontmatter.

**Approval:** pending
