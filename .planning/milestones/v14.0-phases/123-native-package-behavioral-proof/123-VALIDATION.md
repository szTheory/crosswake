---
phase: 123
slug: native-package-behavioral-proof
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-20
validated: 2026-06-21
---

# Phase 123 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir), XCTest (Swift, tools 5.9), JUnit 4 `junit:junit:4.13.2` (Kotlin) |
| **Config file** | `test/test_helper.exs` (Elixir, existing); `Package.swift` (Swift, gains `resources:`); `build.gradle.kts` (Kotlin, gains `kotlinx-coroutines-test`) |
| **Quick run command** | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` |
| **Full suite command** | `mix test` && `(cd packages/crosswake-shell-core-ios && swift test)` && `(cd packages/crosswake-shell-core-android && ./gradlew test)` |
| **Estimated runtime** | Elixir ~10s · Kotlin `./gradlew test` ~60s · Swift `swift test` ~60s (macOS only) |

---

## Sampling Rate

- **After every task commit:** Run the suite for the language touched — Elixir `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs`; Swift `swift test` (in `packages/crosswake-shell-core-ios/`); Kotlin `./gradlew test` (in `packages/crosswake-shell-core-android/`)
- **After every plan wave:** Run full `mix test` + `swift test` + `./gradlew test`
- **Before `/gsd-verify-work`:** All three suites green + CI gate aggregator (`merge-blocking-native-behavioral-proof`) green
- **Max feedback latency:** ~60 seconds (slowest single-language suite)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 123-01-* | 01 | 1 | NTEST-01 | — | Expanded vectors authored by gen task only; version bump → stale fixture (GUARD-01/02) | unit | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` | ✅ | ✅ green |
| 123-01-* | 01 | 1 | NTEST-01 | — | Gen emits byte-identical iOS + Android copies (GUARD-02 diffs them) | command | `mix crosswake.contract.gen && git diff --exit-code` | ✅ | ✅ green |
| 123-02-* | 02 | 2 | NTEST-02 | — | iOS 6 behaviors deny/allow with reason loaded from vectors JSON, no sim | unit (XCTest) | `swift test` | ✅ | ✅ green |
| 123-03-* | 03 | 2 | NTEST-03 | — | Android 6 behaviors deny/allow with reason loaded from classpath JSON, no emulator | unit (JUnit 4) | `./gradlew testDebugUnitTest` | ✅ | ✅ green |
| 123-04-* | 04 | 3 | NTEST-04 | — | Android lane merge-blocking; Swift lane advisory; aggregator needs Android only | CI gate | CI push + `script/register-native-gate.sh` (documented PATCH) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*(Task IDs are placeholders pending planner breakdown; the planner assigns final per-task IDs.)*

---

## Wave 0 Requirements

- [x] `test/crosswake/bridge/bridge_behavioral_vector_test.exs` — Elixir behavioral vector test driving `Crosswake.Compatibility.bridge_findings/2` (NTEST-01)
- [x] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/` — directory exists; holds byte-identical gen-emitted copy
- [x] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` — Swift bridge vector tests (NTEST-02)
- [x] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift` — Swift activation tests (NTEST-02)
- [x] Replace corrupted `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/CrosswakeShellCoreTests.swift` (D-12) — replaced; suite compiles + `swift test` green
- [x] `packages/crosswake-shell-core-android/src/test/resources/` — directory exists; holds byte-identical gen-emitted copy
- [x] `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` — Android bridge tests (NTEST-03)
- [x] `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt` — Android activation tests (NTEST-03)
- [~] `kotlinx-coroutines-test:1.7.3` — N/A: no async path tested, so correctly absent (`org.json:json` is the added test dep; no `runBlocking`)
- [x] `.github/workflows/native-behavioral-proof-gate.yml` — CI gate (NTEST-04)
- [x] `script/register-native-gate.sh` — registration script (NTEST-04)

Framework install: NOT needed (ExUnit, XCTest, JUnit 4 already present). Version-field "bump fails Elixir" property is ALREADY owned by Phase 122 GUARD-01 — do not duplicate.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch-protection PATCH (adding `merge-blocking-native-behavioral-proof` as required check) | NTEST-04 | Historically human/harness-gated (v12.0 pattern); green-first guard refuses until aggregator has ≥1 green run on `main`. Script does NOT auto-toggle. | Run `script/register-native-gate.sh` after the gate is green on main; confirm the documented `gh api -X PATCH` is applied out-of-band. |
| iOS `swift test` on `macos-latest` | NTEST-02 / NTEST-04 | Advisory CI lane (macOS Xcode = native toolchain). Not in the aggregator `needs:`; runs but does not merge-block. | Observe the advisory `ios-package-unit` job result in CI; locally runnable on macOS via `swift test`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-21

---

## Validation Audit 2026-06-21

Retroactive Nyquist audit (`/gsd-validate-phase 123`). The draft VALIDATION.md predated execution (all rows ⬜ pending, `nyquist_compliant: false`); the phase shipped 12/12 (see 123-VERIFICATION.md). This audit re-ran every suite against the **current** fixture — note the canonical `bridge_contract_vectors.json` has since grown from 7 → **15 vectors** (`bridge_protocol_version=1.1.0`, expanded by phase 124); all three test-resource copies remain byte-identical, and the data-driven suites exercise all 15 without code changes.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Audit re-run results (this machine, 2026-06-21):**

| Requirement | Command | Result |
|-------------|---------|--------|
| NTEST-01 | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` | ✅ 1 test, 0 failures (anti-vacuous loop over all 15 vectors via real `bridge_findings/2`) |
| NTEST-01 | `diff` iOS + Android copies vs root fixture | ✅ byte-identical (0 diff) |
| NTEST-02 | `swift test` (in `packages/crosswake-shell-core-ios/`) | ✅ 6 tests, 0 failures (no simulator) |
| NTEST-03 | `./gradlew testDebugUnitTest` (`JAVA_HOME=openjdk@17`, in `packages/crosswake-shell-core-android/`) | ✅ 9 tests, 0 failures (no emulator) |
| NTEST-04 | CI gate yaml + register script present, aggregator topology wired (Android-only `needs:`) | ✅ CI-enforced; branch-protection PATCH remains documented manual-only |

No test generation or auditor spawn was required — all requirements already had automated verification running green. The only defect was the stale draft document, now reconciled.
