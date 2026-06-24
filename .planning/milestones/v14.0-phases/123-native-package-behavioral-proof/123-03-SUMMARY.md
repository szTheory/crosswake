---
phase: 123-native-package-behavioral-proof
plan: "03"
subsystem: android-native-tests
tags: [android, junit4, bridge-conformance, activation-conformance, ntest-03, behavioral-test, vectors]
dependency_graph:
  requires: [123-01]
  provides: [android_bridge_conformance_test, android_activation_conformance_test, org_json_test_dep]
  affects: [123-04]
tech_stack:
  added: [org.json:json:20231013 (testImplementation)]
  patterns: [data-driven-junit4, session-request-decoupled-caps, classpath-getResourceAsStream, inMemory-packstore-seeded]
key_files:
  created:
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt
  modified:
    - packages/crosswake-shell-core-android/build.gradle.kts
decisions:
  - "org.json:json:20231013 added as testImplementation — Android android.jar stubs org.json.JSONObject as not-mocked; production BridgeChannel.kt uses JSONObject for reply-building, so tests require the real implementation"
  - "Session/request capabilities decoupled: request baseline uses fixed 1.0.0 capability version so vec-007 session-side 2.0.0 triggers unavailable_capability correctly"
  - "PackStore.inMemory() seeded with a FAILED-state inventory record to keep blockingStatus() in the memoryStatuses path; avoids the SharedPreferences Android context dependency that fires when pack is absent from memoryStatuses"
  - "kotlinx-coroutines-test NOT added — all bridge and activation paths are synchronous; no async test exercised"
metrics:
  duration: "8m 4s"
  completed: "2026-06-20"
  tasks: 2
  files: 3
status: complete
---

# Phase 123 Plan 03: Android Behavioral Conformance Suites Summary

Added two JUnit 4 behavioral conformance suites to `crosswake-shell-core-android` — `BridgeConformanceTest.kt` (7-vector data-driven bridge suite) and `ActivationConformanceTest.kt` (activation success + denial paths) — plus the `org.json:json:20231013` test dependency required to run production code that uses Android's `org.json.JSONObject` in the JVM unit test environment (NTEST-03 / SC-3).

## What Was Built

### Task 1: BridgeConformanceTest + build.gradle.kts

**`packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt`**

- `@Before loadVectors()` loads `bridge_contract_vectors.json` via `javaClass.getResourceAsStream("/bridge_contract_vectors.json")!!` (leading slash = classpath root, per Pitfall 4)
- `bridgeVersion` is read from `vectorsJson.getString("bridge_protocol_version")` — no literal (D-10)
- `makeSession()` / `makeRequest()` helpers start permissive; `applySessionOverride()` applies `capabilities`, `installed_packs`, and `route_required_packs` overrides from each vector
- Session/request capabilities are decoupled: the request baseline uses `"app.info.get" → "1.0.0"` independent of the session override, so vec-007 (`session.capabilities["app.info.get"] = "2.0.0"`) fires `unavailable_capability` correctly
- Data-driven `@Test` iterates all 7 vectors, calls `BridgeChannel.evaluateForTesting(request)` (synchronous), parses reply with `JSONObject`, and asserts `status` + `denial.denial.reason` per vector — vector id in every failure message
- `appInfoDelegate` stub wired in config so vec-003 canonical-version-ok succeeds (without delegate, `app.info.get` returns `unavailable_capability` even after all other checks pass)
- Two delegate escape-hatch tests: `appInfoDelegate` present → `ok`; absent → `deny` (`unavailable_capability`)

**`packages/crosswake-shell-core-android/build.gradle.kts`**

- Added `testImplementation("org.json:json:20231013")` — the real JSON.org library overrides the Android stub (`org.json.JSONObject` is stubbed as "not mocked" in JVM unit tests but the production `BridgeChannel` uses it for JSON reply construction)
- `kotlinx-coroutines-test` was NOT added — all bridge paths through `evaluateForTesting` are synchronous

### Task 2: ActivationConformanceTest

**`packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt`**

- `@Before loadVectors()` reads both `bridge_protocol_version` and `native_runtime_version` from the classpath vectors file (D-01 version-anchoring — a version bump flows through automatically)
- `makeManifest()` / `makeRequest()` / `makeCoordinator()` helpers use injected loaders — no Context, no assets, no emulator
- **Activation success:** `live_view` route + permissive config → `ShellPresentation.LiveView`; `session.bridgeProtocolVersion` asserted against `bridgeProtocolVersion` loaded from file
- **Activation inactive-route denial:** unknown `routeId` → `Denied(reason=INACTIVE_ROUTE)`
- **Activation required-pack denial:** route with `test-pack@1.0.0` + `PackStore.inMemory()` seeded with a FAILED-state record → `ShellPresentation.RequiredPack`

**Full suite result:** 9/9 tests pass — `BridgeConformanceTest` (3), `ActivationConformanceTest` (3), `CrosswakeShellConfigTest` (3).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Android JVM unit tests stub org.json.JSONObject as not-mocked**
- **Found during:** Task 1 first run
- **Issue:** `org.json.JSONObject.getString()` and `.put()` throw `RuntimeException: Method ... not mocked` in JVM unit tests. Android's `android.jar` (used by the AGP test runner) stubs all Android framework classes. `org.json` lives in `android.jar` on Android but has no real JVM implementation there.
- **Fix:** Added `testImplementation("org.json:json:20231013")` to `build.gradle.kts`. The real JSON.org library takes priority on the test classpath over the Android stub, making both the production `BridgeChannel.kt` reply-building and the test-side reply-parsing work.
- **Files modified:** `packages/crosswake-shell-core-android/build.gradle.kts`
- **Commit:** eb700f8

**2. [Rule 1 - Bug] PackStore.inMemory() falls through to SharedPreferences when pack absent from memoryStatuses**
- **Found during:** Task 2 activation required-pack test
- **Issue:** `PackStore.persistedStatus()` checks `memoryStatuses[packId]` first, but if the pack is not seeded, falls through to `prefs().getString()`, which calls `prefs()`, which throws `error("PackStore requires an Android context for persisted storage")` when context is null. `PackStore.inMemory()` with an empty inventory leaves memoryStatuses empty.
- **Fix:** Seeded `PackStore.inMemory()` with a `PackInventoryRecord` that has `integrityStatus = "unverified"` and `verifiedAt = null`, which causes `buildStatus()` to compute `PackState.FAILED`. The FAILED record lands in `memoryStatuses`, so `persistedStatus` returns it without touching `prefs()`. FAILED state is `!= AVAILABLE`, so `blockingStatus` returns it as a blocking pack → `RequiredPack` presentation.
- **Files modified:** `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt`
- **Commit:** 3b6ce72

## Known Stubs

None. Both test suites assert on observable outcome values (reply JSON status + denial reason, ShellPresentation type + session fields).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. Test files read only the classpath resource (hermetic). `build.gradle.kts` adds one test dependency.

**T-123-07 mitigated (D-10):** No `BridgeChannel.PROTOCOL_VERSION` constant added. Bridge version loaded from `vectorsJson.getString("bridge_protocol_version")` at runtime.
**T-123-08 mitigated (D-14):** Assertions are on reply JSON `status` and `denial.denial.reason` strings, not on internal guards.
**T-123-09 mitigated (D-13):** No `runBlocking` anywhere; no async path exercised; `kotlinx-coroutines-test` not added.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` | FOUND |
| `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt` | FOUND |
| `packages/crosswake-shell-core-android/build.gradle.kts` (org.json dep) | FOUND |
| commit eb700f8 (Task 1 — BridgeConformanceTest + build.gradle.kts) | FOUND |
| commit 3b6ce72 (Task 2 — ActivationConformanceTest) | FOUND |
| `./gradlew testDebugUnitTest` — 9/9 tests pass | PASSED |
| No bridge_protocol_version literal in test files | CONFIRMED |
| No runBlocking in test files | CONFIRMED |
