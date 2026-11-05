---
phase: "198"
slug: "android-foreign-host-proof"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-05"
---

# Phase 198 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `198-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir), JUnit 4.13.2 via Gradle (Kotlin), XCTest (Swift), Python `unittest` (scripts) |
| **Config file** | `packages/crosswake-shell-core-android/build.gradle.kts`; `Package.swift`; none for Python |
| **Quick run command** | `mix test test/crosswake/parity_ledger_test.exs test/crosswake/guides/android_claim_ceiling_test.exs` (Elixir); `cd packages/crosswake-shell-core-android && JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew --no-daemon cleanTestDebugUnitTest testDebugUnitTest` (Kotlin, ~20 s) |
| **Full suite command** | `mix test` plus `swift test` in `packages/crosswake-shell-core-ios` plus the Gradle command above |
| **Estimated runtime** | ~20 s quick (Kotlin), full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick command for the area touched (Kotlin, Elixir or scripts)
- **After every plan wave:** All three quick runs plus `mix crosswake.docs.sync --check`
- **Before `/gsd-verify-work`:** Full `mix test`, `swift test`, Gradle run, floor checker, and a measured advisory-job run (`script/ci_cost_report.sh`) must be green
- **Max feedback latency:** 60 seconds for task-level checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD by planner | — | — | AND-01 | — | Corpus copies byte-equal; Swift and Kotlin hash constants equal the corpus sha256; mismatch fails | unit | `mix test test/crosswake/parity_ledger_test.exs` | ❌ W0 | ⬜ pending |
| TBD by planner | — | — | AND-01 | — | Regenerating `guides/parity_ledger.md` yields no diff | integration | `mix crosswake.docs.sync --check` | ✅ extend | ⬜ pending |
| TBD by planner | — | — | AND-02 | — | Kotlin tests ≥ 25, 0 skipped, boundary class ≥ 10 | script | `python3 script/check_kotlin_test_floor.py --run` | ❌ W0 | ⬜ pending |
| TBD by planner | — | — | AND-02 | — | `BridgeChannel` boundary cases pass | unit (JVM) | Gradle quick run | ❌ W0 | ⬜ pending |
| TBD by planner | — | — | AND-03 | — | Foreign-host selftest incl. wrong-coordinate control fails for the right reason | script | `python3 script/verify_android_foreign_host_test.py` | ❌ W0 | ⬜ pending |
| TBD by planner | — | — | AND-03 | — | Advisory job cannot affect required authority | structural | `python3 script/check_ci_leaf_manifest.py` | ✅ extend | ⬜ pending |
| TBD by planner | — | — | AND-03 (SC4) | — | No Android evidence cell above `JVM hermetic proof` | unit | `mix test test/crosswake/guides/android_claim_ceiling_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Task IDs are filled in once plans exist.*

---

## Wave 0 Requirements

- [ ] `test/crosswake/parity_ledger_test.exs` — AND-01
- [ ] `test/crosswake/guides/android_claim_ceiling_test.exs` — SC4
- [ ] `script/check_kotlin_test_floor_test.py` and `script/verify_android_foreign_host_test.py` — AND-02, AND-03
- [ ] `BridgeChannelBoundaryTest.kt`, `SemVerBoundaryTest.kt`, `BridgeFixtures.kt`, `VectorCorpus.kt`, `VectorCorpus.swift` — AND-01, AND-02

Every new check records a non-empty floor and the mutation that turns it red (BEARINGS tripwire).

---

## Manual-Only Verifications

All phase behaviors have automated verification. The one-time native-loader mutation check (flip one byte per resource copy) is agent-run phase evidence, not CI.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
