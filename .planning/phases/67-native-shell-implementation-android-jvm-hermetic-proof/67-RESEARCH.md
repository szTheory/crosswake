# Phase 67: Native Shell Implementation & Android JVM Hermetic Proof - Research

**Researched:** 2026-06-04
**Domain:** iOS and Android Native Shells, Diagnostic Export, JVM Hermetic Testing
**Confidence:** HIGH

## Summary

This phase operationalizes the runtime-line and diagnostic export contracts (from Phases 64 and 65) into the native iOS and Android shells. It requires enforcing the `native_runtime_version` rebuild check in the `ActivationCoordinator`, setting up an asynchronous, zero-dependency diagnostic export mechanism via HTTP POST, and bumping Android toolchain floors to meet modern requirements. Finally, a merge-blocking Android JVM test lane must be established using Robolectric to guarantee hermetic verification of these mechanisms without relying on flaky emulators.

**Primary recommendation:** Implement `MXMetricManagerSubscriber` (iOS) and `Application.getHistoricalProcessExitReasons` (Android) as fire-and-forget HTTP POSTs directly to a standard host endpoint (e.g., `/api/diagnostics/export`). Enforce `native_runtime_version` parity between the Activation Request and the Shell Manifest.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** AGP 8.5 + Kotlin 1.9.24 + Gradle 8.7.
- **D-02:** `minSdk 30` (Android 11), `compileSdk 35` / `targetSdk 35`.
- **D-03:** Kotlin 1.9.24 is the most stable LTS before the K2 compiler shift.
- **D-04:** OS-Native Asynchronous Capture (No Eager Handlers). No `NSSetUncaughtExceptionHandler`.
- **D-05:** iOS: Implement `MXMetricManagerSubscriber`. Filter for `MXCrashDiagnostic` and `MXHangDiagnostic`, map to Phase 65 `Envelope`, and fire HTTP POST.
- **D-06:** Android: Query `ActivityManager.getHistoricalProcessExitReasons` on boot. Filter for `REASON_CRASH`, `REASON_ANR`, map to `Envelope`, and fire POST.
- **D-07:** Adheres strictly to Phase 65 redaction allowlist.
- **D-08:** Zero-Dependency Native Transport.
- **D-09:** iOS: `URLSession.shared.dataTask`.
- **D-10:** Android: `java.net.HttpURLConnection`.
- **D-11:** Fire-and-forget HTTP POST.
- **D-12:** Robolectric 4.13+ for Merge-Blocking JVM Lane.
- **D-13:** Satisfies `AVER-01` without emulator flakiness by shadowing `ActivityManager` and `ApplicationExitInfo`.
- **D-14:** Device UAT remains relegated to the advisory lane (Phase 68).

### Claude's Discretion
- Code-level naming and organization within the Android/iOS shells as long as it adheres to the zero-dep rule and the architectural decisions defined here.

### Deferred Ideas (OUT OF SCOPE)
- Advisory emulator lane and capability-parity-locked device-UAT checklist (Phase 68).
- Docs-contract parity gate, actual Android `:supported` promotion, and closeout (Phase 69).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AVER-01 | Android CI provides a merge-blocking hermetic proof lane | Shadow `ActivityManager` in Robolectric to test `ApplicationExitInfo` processing and network export. |
| AVER-02 | Android toolchain floors are updated (minSdk 30, compileSdk 35) | Configure `build.gradle` with AGP 8.5, Kotlin 1.9.24, Gradle 8.7. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Diagnostic Export | Browser / Client | — | Native shells capture crash telemetry and export it securely. |
| Rebuild Policy Enforcement | Browser / Client | API / Backend | Native shell acts as the final gatekeeper refusing incompatible manifest updates. |
| HTTP Transport | Browser / Client | — | Shells execute fire-and-forget HTTP POST via OS-level APIs (no external SDK). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Android Gradle Plugin | 8.5.0 | Android Build System | Required by constraint D-01 |
| Kotlin | 1.9.24 | Language Compiler | Pre-K2 LTS stability (D-03) |
| Gradle | 8.7 | Build System | Required by constraint D-01 |
| Robolectric | 4.13+ | JVM Android Testing | Hermetic tests without emulator flakiness (D-12) |
| iOS SDK | Xcode 26 | iOS Toolkit | Standard required update for new Phase contracts |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Robolectric | Android JVM Tests | ✓ | 4.13 | — |
| Xcode | iOS Builds | ✓ | Xcode 26 | — |
| Android SDK | Android Builds | ✓ | API 35 | — |

## Architecture Patterns

### System Architecture Diagram
```text
[Crash Event] --> (OS Watchdog) 
                      |
                      v
[App Startup] --> (iOS MetricKit / Android getHistoricalProcessExitReasons)
                      |
                      v
              (Sanitize & Map to Envelope)
                      |
                      v
           (URLSession / HttpURLConnection)
                      |
                      v
[Host HTTP Seam (POST /api/diagnostics/export)]
```

### Pattern 1: iOS MetricKit Subscriber
**What:** Use `MXMetricManagerSubscriber` to capture crash/hang reports.
**When to use:** On application launch in `AppDelegate` or a dedicated manager class.
**Example:**
```swift
import MetricKit

final class DiagnosticExportManager: NSObject, MXMetricManagerSubscriber {
    static let shared = DiagnosticExportManager()
    
    func start() {
        MXMetricManager.shared.add(self)
    }
    
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let crashDiagnostics = payload.crashDiagnostics {
                // Map to Envelope and POST
            }
        }
    }
}
```

### Pattern 2: Android ApplicationExitInfo Query
**What:** Query historical process exit reasons during `Application.onCreate`.
**When to use:** Android boot sequence for reliable crash telemetry delivery.
**Example:**
```kotlin
val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
val exitReasons = am.getHistoricalProcessExitReasons(context.packageName, 0, 10)
for (info in exitReasons) {
    if (info.reason == ApplicationExitInfo.REASON_CRASH) {
        // Map to Envelope and POST
    }
}
```

### Pattern 3: Shell Runtime-Line Validation
**What:** The `ActivationCoordinator` must parse `compatibility.native_runtime_version` from the `ShellManifest` and assert parity against the incoming `ActivationRequest`.
**When to use:** During `resolve()` step of `ActivationCoordinator`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP Networking | Sentry, Bugsnag, OkHttp, Alamofire | `URLSession` / `HttpURLConnection` | Meets the strict zero-dependency and host-owned endpoint requirements. |
| Uncaught Exception Handlers | `Thread.setDefaultUncaughtExceptionHandler`, `NSSetUncaughtExceptionHandler` | `ApplicationExitInfo` / `MetricKit` | Eager capture conflicts with standard OS telemetry tools and requires synchronous file I/O during a crash. |

## Common Pitfalls

### Pitfall 1: Over-capturing Diagnostics Data
**What goes wrong:** Adding the exception message or stack trace to the diagnostic envelope.
**Why it happens:** Attempting to build a full crash reporting tool.
**How to avoid:** Map strictly to the Phase 65 envelope using closed enum `exit_reason` codes (`:crash`, `:anr`, `:hang`, etc). Discard text.

### Pitfall 2: Flaky CI due to Emulators
**What goes wrong:** Android tests fail sporadically on GitHub Actions.
**Why it happens:** Testing `ActivityManager` on real emulators is slow and unstable.
**How to avoid:** Use Robolectric's `@Config(shadows = [...])` to shadow `ActivityManager` and simulate fake `ApplicationExitInfo` records.

## Code Examples

### Android Robolectric Shadow for ApplicationExitInfo
```kotlin
@RunWith(RobolectricTestRunner::class)
class DiagnosticExportTest {
    @Test
    fun testCrashExport() {
        val activityManager = ApplicationProvider.getApplicationContext<Context>()
            .getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val shadowAm = shadowOf(activityManager)
        
        // Setup fake exit info
        val exitInfo = ApplicationExitInfo()
        // (Use reflection or shadow to set reason = REASON_CRASH)
        
        // Assert network POST is triggered with correct Envelope shape
    }
}
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (iOS) / Robolectric (Android) |
| Config file | gradle (Android) / Xcode (iOS) |
| Quick run command | `./gradlew testDebugUnitTest` |
| Full suite command | `./gradlew test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AVER-01 | Test ApplicationExitInfo POST | unit | `./gradlew :app:testDebugUnitTest` | ❌ Wave 0 |
| AVER-02 | Verify Toolchain floors | static | `grep -q "compileSdk 35" build.gradle` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `app/src/test/java/dev/crosswake/shell/DiagnosticExportTest.kt` — covers AVER-01
- [ ] `app/src/test/java/dev/crosswake/shell/ActivationCoordinatorRebuildTest.kt` — covers Rebuild policy check
- [ ] iOS unit tests for `DiagnosticExportManager` and `ActivationCoordinator` rebuild check.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Sanitize envelope and allowlist fields only |
| V6 Cryptography | yes | TLS (HTTPS) enforced for export |

### Known Threat Patterns for Native Diagnostic Export

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII / Token Leakage | Information Disclosure | Strictly adhere to the Phase 65 `sanitize/1` fail-closed allowlist constraints. Discard all exception messages and raw stack frames. |
