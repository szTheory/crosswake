---
phase: 126
slug: additive-native-dev-wiring
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-22
---

# Phase 126 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) — the proof-posture/drift guards are the primary automated coverage; native build verification is manual (Xcode/Gradle toolchains) |
| **Config file** | `mix.exs` / `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/guides/native_dev_wiring_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30–90 seconds (Elixir suite) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/guides/native_dev_wiring_test.exs` (once the guard exists)
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 126-01-01 | 01 | 1 | NDEV-01/02/03 | — | — | compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 126-01-02 | 01 | 1 | NDEV-01/02/03 | T-126-01 | dev fixtures diverge only in url/origin/correlation_id; default run writes no prod surface | behavior | `mix crosswake.contract.gen --dev && git diff --quiet -- <prod surfaces> && test -f <dev fixtures>` | ✅ | ⬜ pending |
| 126-01-03 | 01 | 1 | NDEV-01/02/03 | — | separate `@dev_generated_json_paths`; prod drift list untouched | unit | `mix test test/crosswake/contract/contract_drift_test.exs` | ✅ | ⬜ pending |
| 126-02-01 | 02 | 2 | NDEV-01 | T-126-01 | `Info-Dev.plist` localhost-pinned ATS, no `NSAllowsArbitraryLoads`; prod `Info.plist` byte-untouched | lint+diff | `plutil -lint Info-Dev.plist && git diff --quiet -- Info.plist` | ❌ W2 | ⬜ pending |
| 126-02-02 | 02 | 2 | NDEV-01 | — | `Debug-Dev` config + `CONFIGURATION`-guarded Run Script copy phase | lint | `plutil -lint project.pbxproj && xcodebuild -list \| grep Debug-Dev` | ❌ W2 | ⬜ pending |
| 126-02-03 | 02 | 2 | NDEV-01 | — | `Dev.xcscheme` points Launch/Test at `Debug-Dev` | xml-lint | `parse Dev.xcscheme && grep buildConfiguration = "Debug-Dev"` | ❌ W2 | ⬜ pending |
| 126-03-01 | 03 | 2 | NDEV-02 | — | `prod`+`dev` flavors; `versionName "0.1.2"` preserved (drift-safe) | grep | `grep flavorDimensions/applicationIdSuffix/versionName build.gradle` | ❌ W2 | ⬜ pending |
| 126-03-02 | 03 | 2 | NDEV-02 | T-126-01 | `10.0.2.2`-pinned cleartext via `tools:replace`; prod manifest byte-untouched; default-off base-config | xml+diff | `parse dev manifest+nsc && grep 10.0.2.2 && git diff --quiet -- src/main/AndroidManifest.xml` | ❌ W2 | ⬜ pending |
| 126-03-03 | 03 | 2 | NDEV-02 | — | D-10 lockstep: example-host Gradle invocations migrated to Prod-flavored names | grep | `grep ProdDebug script/... && grep installProdDebug QUICK_START && ! grep 'gradlew installDebug'` | ❌ W2 | ⬜ pending |
| 126-04-01 | 04 | 3 | NDEV-03 | T-126-01 | D-14 proof-posture guard: source-derived port, Jason.decode! key lookup, anti-vacuity cases | unit | `mix test test/crosswake/guides/native_dev_wiring_test.exs` | ❌ W3 | ⬜ pending |
| 126-04-02 | 04 | 3 | NDEV-03 | — | QUICK_START additive section keeps adoption-drift guard green (labels + source-derived port) | unit | `grep section labels QUICK_START && mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` | ❌ W3 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/guides/native_dev_wiring_test.exs` — D-14 proof-posture guard (source-derived, anti-vacuity regression cases)
- [ ] `test/crosswake/contract/contract_drift_test.exs` — extend with `@dev_generated_json_paths` (D-13)

*Existing ExUnit infrastructure covers all Elixir-side phase requirements; native build verification is manual.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| iOS `Dev` scheme builds + simulator reaches `http://localhost:4700` | NDEV-01 | Requires Xcode toolchain + iOS simulator (not in CI) | `xcodebuild -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme Dev -configuration Debug-Dev -destination 'platform=iOS Simulator,name=iPhone 16' build`, then run against a live backend on 4700 |
| Android `devDebug` builds + emulator reaches `http://10.0.2.2:4700` | NDEV-02 | Requires Android SDK + emulator + JDK 17 (not in CI for example host) | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug`, `adb shell am start -n dev.crosswake.shell.dev/.MainActivity` |

*The proof-posture guard (D-14) and drift tests automate the "proof untouched + dev correct + honestly tagged" invariants; physical native runs are advisory-native evidence only (D-16).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
