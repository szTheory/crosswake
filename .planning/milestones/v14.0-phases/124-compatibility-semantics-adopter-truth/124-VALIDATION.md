---
phase: 124
slug: compatibility-semantics-adopter-truth
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-21
validated: 2026-06-21
---

# Phase 124 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir), XCTest (Swift, tools 5.9, no simulator), JUnit 4 `junit:junit:4.13.2` (Kotlin, no emulator) |
| **Config file** | `test/test_helper.exs` (Elixir, existing); `Package.swift` (Swift, `resources:` byte-identical vector copy); `build.gradle.kts` (Kotlin, classpath vector copy) |
| **Quick run command** | `mix test test/crosswake/guides/compatibility_test.exs` |
| **Full suite command** | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs test/crosswake/proof/phase52_operator_truth_test.exs test/crosswake/guides/compatibility_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/guides/release_boundaries_test.exs` && `(cd packages/crosswake-shell-core-ios && swift test)` && `(cd packages/crosswake-shell-core-android && JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew testDebugUnitTest)` |
| **Estimated runtime** | Elixir ~1s · Swift `swift test` ~1s (macOS only) · Kotlin `./gradlew testDebugUnitTest` ~5s |

---

## Sampling Rate

- **After every task commit:** Run the suite for the language touched — Elixir `mix test <touched test file>`; Swift `swift test` (in `packages/crosswake-shell-core-ios/`); Kotlin `JAVA_HOME=openjdk@17 ./gradlew testDebugUnitTest` (in `packages/crosswake-shell-core-android/`)
- **After every plan wave:** Run all five Elixir COMPAT files + both native suites
- **Before `/gsd-verify-work`:** All Elixir COMPAT files + `swift test` + `./gradlew testDebugUnitTest` green; contract-drift-gate + native-behavioral-proof-gate aggregators green
- **Max feedback latency:** ~5 seconds (slowest single suite — Android `./gradlew testDebugUnitTest`)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 124-01-* | 01 | 1 | COMPAT-01 | T-124-01/02/03 | Native bridge/runtime/pack axes floor via `SemVer.compatible` (`>=`), fail-closed on parse error; protocol NAME stays exact `==` | unit (ExUnit) | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` | ✅ | ✅ green (1/1) |
| 124-06-* | 06 | 1 | COMPAT-01 | T-124-06-01/02/03 | Capability axis floors (provides=request, demands=session); iOS `ActivationCoordinator.resolve()` native-runtime floor gate; discriminating vec-014 (1.1.0 > 1.0.0 → allow under `>=`, deny under old `==`) | unit (XCTest) | `swift test` (in `packages/crosswake-shell-core-ios/`) | ✅ | ✅ green (6/6) |
| 124-06-* | 06 | 1 | COMPAT-01 | T-124-06-01/02/03 | Same six behaviors + capability floor on Android; vec-014 discriminating; phantom vec-012/013 removed | unit (JUnit 4) | `JAVA_HOME=openjdk@17 ./gradlew testDebugUnitTest` (in `packages/crosswake-shell-core-android/`) | ✅ | ✅ green (9/9) |
| 124-02-* | 02 | 1 | COMPAT-02 | T-124-SC | `rebuild_decision_table/0` (11 rows, D-09) rendered into `support_matrix.md`; byte-parity + section-presence guard merge-blocking | unit (ExUnit) | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` | ✅ | ✅ green (6/6) |
| 124-03-* | 03 | 1 | COMPAT-03 | — | `compatibility.md` leads with decision table before prose; renderer-mirror anti-drift; table appears exactly once | unit (ExUnit) | `mix test test/crosswake/guides/compatibility_test.exs` | ✅ | ✅ green (6/6) |
| 124-04-* | 04 | 1 | COMPAT-04 | T-124-09/10/11 | Advisory `compatibility_rebuild_guidance` check — never `:error`, never blocking; 4-step action sequence; denial vocabulary; shared parity detector (cannot disagree) | unit (ExUnit) | `mix test test/crosswake/doctor/publish_readiness_test.exs` | ✅ | ✅ green (19/19) |
| 124-05-* | 05 | 1 | COMPAT-05 | T-124-12/13/14 | Every `## [x.y.z]` release carries exactly one `### Upgrade Impact` block; labels from locked 4-string set; legend parity with `support_matrix.md` | unit (ExUnit) | `mix test test/crosswake/guides/release_boundaries_test.exs` | ✅ | ✅ green (8/8) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*(Task IDs reflect the per-plan breakdown; COMPAT-01 was completed across plans 124-01 (bridge/runtime/pack axes) and 124-06 (capability axis + iOS activation gate — the gap-closure plan).)*

---

## Wave 0 Requirements

- [x] `test/crosswake/bridge/bridge_behavioral_vector_test.exs` — Elixir behavioral vector test over `Crosswake.Compatibility.bridge_findings/2` (COMPAT-01; skips `native_only` vectors)
- [x] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` — iOS data-driven vector suite; decodes per-vector `request_override.capabilities`; skips `elixir_only` (COMPAT-01)
- [x] `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift` — iOS activation suite; `ShellManifest.compatibility` now decoded for the native-runtime floor gate (COMPAT-01)
- [x] `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` — Android data-driven vector suite; `applyRequestOverride` capabilities; skips `elixir_only` (COMPAT-01)
- [x] `test/crosswake/proof/phase52_operator_truth_test.exs` — `## Rebuild Decision Table` byte-parity + section-presence guard (COMPAT-02)
- [x] `test/crosswake/guides/compatibility_test.exs` — decision-table-first ordering + renderer-mirror anti-drift, 6 tests (COMPAT-03)
- [x] `test/crosswake/doctor/publish_readiness_test.exs` — advisory rebuild-guidance check, 19 tests (COMPAT-04)
- [x] `test/crosswake/guides/release_boundaries_test.exs` — `### Upgrade Impact` structural + vocabulary/legend parity, 8 tests (COMPAT-05)

Framework install: NOT needed (ExUnit, XCTest, JUnit 4 already present). The "version bump fails the Elixir suite" tripwire property is owned by Phase 122 GUARD-01 / GUARD-02 — not duplicated here.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| iOS `swift test` on `macos-latest` | COMPAT-01 | Advisory CI lane (macOS Xcode = native toolchain); runs in `native-behavioral-proof-gate.yml` but is not in the aggregator `needs:`, so it does not merge-block. | Observe the advisory `ios-package-unit` job in CI; locally runnable on macOS via `swift test`. |

---

## Known Caveat — WR-01 (test-coverage gap, no production impact)

The discriminating capability-floor proof for **vec-014** (request `1.1.0` > session `1.0.0` → allow under `>=`, deny under old `==`) runs **native-only** (iOS + Android), not in the Elixir suite. `bridge_behavioral_vector_test.exs` → `make_permissive_request/1` (line ~236) hardcodes `capabilities: %{"app_info" => "1.0.0"}` and ignores `vec-014.request_override.capabilities`, so the Elixir harness evaluates `1.0.0 >= 1.0.0` (passes vacuously under both `==` and `>=`).

- **Not a code defect:** Elixir `compatible_version?/2` (`compatibility.ex:585`) is correct floor semantics and was never broken. COMPAT-01's deliverable was eliminating the *native* exact-equality footgun, which is proven discriminatingly on iOS + Android (both green above).
- **Disposition:** Carried as documented tech debt in `124-VERIFICATION.md` (WR-01) and the v14.0 milestone audit. Fix options: tag vec-014 `native_only: true`, or teach `make_permissive_request/1` to honor `request_override["capabilities"]`. Non-blocking.

---

## Validation Sign-Off

- [x] All requirements have `<automated>` verify (no Wave 0 stubs needed — all tests pre-existed execution)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all references (none MISSING)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-21

---

## Validation Audit 2026-06-21

Retroactive Nyquist audit (`/gsd-validate-phase 124`), run during `/gsd-complete-milestone v14.0` pre-flight. Phase 124 shipped (5/5, see `124-VERIFICATION.md`) but had no VALIDATION.md — this audit reconstructs the validation contract from the 6 plan SUMMARYs and re-runs every suite against the **current** post-124-06 code.

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Audit re-run results (this machine, 2026-06-21):**

| Requirement | Command | Result |
|-------------|---------|--------|
| COMPAT-01 | `mix test test/crosswake/bridge/bridge_behavioral_vector_test.exs` | ✅ 1 test, 0 failures |
| COMPAT-01 | `swift test` (in `packages/crosswake-shell-core-ios/`) | ✅ 6 tests, 0 failures (no simulator) |
| COMPAT-01 | `JAVA_HOME=openjdk@17 ./gradlew testDebugUnitTest --rerun-tasks` (in `packages/crosswake-shell-core-android/`) | ✅ 9 tests, 0 failures (no emulator) |
| COMPAT-02 | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` | ✅ 6 tests, 0 failures |
| COMPAT-03 | `mix test test/crosswake/guides/compatibility_test.exs` | ✅ 6 tests, 0 failures |
| COMPAT-04 | `mix test test/crosswake/doctor/publish_readiness_test.exs` | ✅ 19 tests, 0 failures |
| COMPAT-05 | `mix test test/crosswake/guides/release_boundaries_test.exs` | ✅ 8 tests, 0 failures |

No test generation or auditor spawn was required — all five requirements already had automated verification running green. The only defect was the missing VALIDATION.md, now reconciled. One documented test-coverage caveat (WR-01) is recorded above; it does not leave any requirement uncovered (COMPAT-01's discriminating proof is native-green).
