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
| TBD — planner fills from RESEARCH.md `## Validation Architecture` and the D-14 guard assertions | — | — | NDEV-01/02/03 | T-126-01 (dev cleartext exposure) | dev-only cleartext scoped to localhost / 10.0.2.2; prod posture default-off | unit | `mix test test/crosswake/guides/native_dev_wiring_test.exs` | ❌ W0 | ⬜ pending |

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
