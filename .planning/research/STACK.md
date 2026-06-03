# Stack Research

**Domain:** v4.0 Production Shell Runtime Line — hardening checked-in iOS/Android shells into a documented production runtime line
**Researched:** 2026-06-03
**Confidence:** HIGH (Elixir/OTP/CI layers), MEDIUM (iOS/Android SDK version specifics)

---

## Executive Summary

v4.0 needs almost no new Elixir library dependencies. The work lives at four integration points:

1. **Elixir/Mix** — new `Crosswake.RuntimeLine` module + doctor/support-matrix extensions + `mix crosswake.gen.shell` template additions. No new hex deps required.
2. **iOS/Swift** — `MetricKit` (already bundled in Xcode/iOS SDK since iOS 14; no SPM package needed), EEx-generated permission/entitlement template files, and `xcodebuild` integration in CI.
3. **Android/Kotlin** — `ApplicationExitInfo` API (stdlib in API 30+, already above `minSdk 26` which needs a version bump), EEx-generated `AndroidManifest.xml` and permission template fragments, Gradle wrapper version bump, and the advisory emulator lane using `ReactiveCircus/android-emulator-runner@v2`.
4. **CI** — a new proof workflow following the established hermetic/advisory two-lane pattern, plus a device-UAT checklist as a markdown artifact (no CI tooling).

The **no-local-Java constraint** is respected throughout. Android JVM unit tests run in CI via `actions/setup-java` with `temurin:17` — the same pattern already proven in `phase18-proof.yml`. Emulator/device lanes are advisory-only.

---

## Existing Stack That Does NOT Change

The following already ship and need no version bumps for v4.0 features:

| Layer | Technology | Current CI Pin | Status |
|-------|-----------|---------------|--------|
| Elixir | `crosswake` library | `0.1.0` on hex.pm | No new hex deps |
| Elixir | `jason ~> 1.4` | 1.4.x | Template rendering already uses Jason |
| Elixir | `nimble_options ~> 1.1` | 1.1.x | Schema validation already uses NimbleOptions |
| Elixir | `phoenix ~> 1.8` | 1.8.x | Not involved in shell generation |
| Elixir | `phoenix_live_view ~> 1.1` | 1.1.x | Not involved in shell generation |
| Elixir | `telemetry ~> 1.0` | 1.x | Doctor/support telemetry already wired |
| iOS | `WebKit` / `WKWebView` | iOS SDK (bundled) | Already in checked-in shell |
| iOS | `UIKit` / `SwiftUI` | iOS SDK (bundled) | Already in checked-in shell |
| Android | `androidx.webkit:webkit` | `1.15.0` | Already in `app/build.gradle` |
| Android | `androidx.core:core-ktx` | `1.13.1` | Already in `app/build.gradle` |
| Android | `kotlinx-coroutines-android` | `1.8.1` | Already in `app/build.gradle` |
| CI | `erlef/setup-beam@v1` | Elixir 1.19.5 / OTP 27.3 | Established pattern; no version bump needed for v4.0 |
| CI | `actions/setup-java@v5` | temurin:17 | Established Android JVM proof pattern |
| CI | `actions/checkout@v6` | pinned SHA | No change |

---

## New and Changed Stack Items

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir `~> 1.19` / OTP `27.3` | existing pin | Runtime-line policy module, doctor extensions, EEx template generation | Already pinned in all existing proof lanes; OTP 28 is stable as of May 2025 but upgrading is optional and carries no v4.0 benefit |
| `MetricKit` (Apple system framework) | iOS 14+ / bundled | Crash/diagnostic export seam in iOS shell | No SPM package needed — `import MetricKit` is available on all devices iOS 14+; `MXCrashDiagnostic` and `MXDiagnosticPayload` provide JSON-serialisable call-stack trees; delivers immediately on next launch after crash (iOS 15+) |
| `ApplicationExitInfo` (Android API) | API 30 (`minSdk` must move from 26 to 30) | Crash/diagnostic export seam in Android shell | Stdlib, no extra dependency; `ActivityManager.getHistoricalProcessExitReasons()` returns typed exit records with crash trace input streams; available since Android 11 which is the correct floor for production apps submitting to Google Play in 2025 |
| Android Gradle Plugin | `8.5.1` (current checked-in: `8.4.1`) | Compile pipeline for Android shell | AGP 8.5.x targets `compileSdk 35` / `targetSdk 35` needed for Google Play compliance; `8.4.1` only supported up to `compileSdk 34`; bump is a one-line change in `settings.gradle` |
| `compileSdk` / `targetSdk` | `35` (current: `34`) | Google Play API target compliance | Google Play required `targetSdk 35` for new apps and updates starting 2025; `compileSdk 35` is needed to use the API 35 symbols |
| Kotlin | `2.0.21` (current: `1.9.24`) | Kotlin compiler for Android shell | Kotlin 2.0 is the stable branch as of mid-2025 and pairs correctly with AGP 8.5+; `1.9.x` still builds against AGP 8.5 but support is narrowing; K2 compiler is default in 2.0 |
| Gradle Wrapper | `8.11.1` (current: bundled with AGP 8.4.1 range) | Build wrapper for Android shell | AGP 8.5+ requires Gradle 8.7+; `8.11.1` is the latest stable as of mid-2025 |
| `ReactiveCircus/android-emulator-runner@v2` | `v2.36.0` | Advisory emulator lane for Android CI | The canonical GHA action for hardware-accelerated Android emulator on macOS; supports `api-level: 35`, `aosp-atd` system image; advisory-only per the established hermetic/advisory split |
| EEx templates (Elixir stdlib) | stdlib | Permission/entitlement template generation | Already used by `mix crosswake.gen.shell` for all native shell files; no new dep needed; new templates for `Info.plist`, `.entitlements`, and `AndroidManifest.xml` fragments are pure EEx additions |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None | — | — | v4.0 requires no new Elixir hex dependencies. All Elixir work is new modules within the existing `crosswake` library using stdlib, `jason`, `nimble_options`, and the existing doctor/support-matrix surfaces. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `xcodebuild` (Xcode 16.4) | iOS shell build + test in CI | Already used in `verify_generated_ios_shell.sh`; `macos-15` runner default will move to Xcode 16.4 in August 2025; workflows already use `runs-on: macos-15` which is the right base |
| `xcrun simctl` | iOS simulator management in CI | Already used; no change |
| `sdkmanager` / Android command-line tools | Android SDK package management in CI | Already used in `verify_generated_android_shell.sh`; bump package set to include `platforms;android-35` and `build-tools;35.0.0` |
| `adb` / Android platform-tools | Android device/emulator communication | Already provisioned by the verify script; advisory lane uses this for emulator boot + test execution |
| `avdmanager` | Android virtual device creation | Already in verify script; advisory emulator lane creates an `api-35` AVD with `aosp_atd` system image |
| `PlistBuddy` (macOS stdlib) | Info.plist read/write in CI proof | Already used in `verify_generated_ios_shell.sh` to extract bundle ID; extended use for permission key presence checks |

---

## Integration Points with Existing Surfaces

### 1. Elixir — `Crosswake.RuntimeLine` (new module)

The rebuild-policy contract and compatibility-window logic belongs in a new `Crosswake.RuntimeLine` module (parallel to `Crosswake.Compatibility`). It should:

- Define `rebuild_required?/2` — given a change class atom (`:manifest_schema`, `:bridge_protocol`, `:native_runtime`, `:capability_family`, `:ota_safe`) and the current/required version pair, return a typed verdict struct.
- Expose `compatibility_window/1` — given platform and shell version, return the supported manifest-schema / bridge-protocol / native-runtime range.
- Feed into `Crosswake.Doctor` via a new `phase_v40_runtime_line_findings/1` clause, following the existing `phase_NN_findings` pattern.
- Surface to `Crosswake.SupportMatrix` via a new `runtime_line_truth/0` function, parallel to `auth_contract_truth/0` and `notification_support_truth/0`.

### 2. EEx Templates — permission/entitlement artifacts

`mix crosswake.gen.shell` already generates all shell files via `@ios_templates` and `@android_templates` template lists. v4.0 adds:

- **iOS**: `CrosswakeShell/CrosswakeShell.entitlements.eex` — a host-owned, comment-annotated `.entitlements` plist template with documented capability sections (Push Notifications, Associated Domains, App Groups, etc.), each section gated by a `<%= if @entitlement.push_notifications %>` guard so the generator only emits what the host has declared.
- **iOS**: Augmented `Info.plist.eex` — explicit permission strings (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSLocationWhenInUseUsageDescription`, etc.) with placeholder text that doctor can verify is not left as placeholder in production.
- **Android**: `AndroidManifest.xml.eex` augmentation — `<uses-permission>` template fragments for each declared capability class, gated by the same capability-class guards used by the manifest/policy compiler.
- Both platform templates emit a `# HOST OWNED — review before shipping` header comment that doctor checks for presence, per the maintainer house style.

### 3. `Crosswake.Doctor` — runtime-line findings category

New `phase_v40_runtime_line_findings/1` slice added to `Doctor.run/1`, parallel to `phase_62_notification_findings`. Checks:

- Whether `native_runtime_version` declared in the manifest compatibility block falls within the documented compatibility window for the current crosswake library version.
- Whether any declared capability family has a documented OTA-safe vs. rebuild-required classification and flags unclassified capability families.
- Whether generated permission/entitlement templates have been reviewed (placeholder text detection).
- Android: whether `minSdk` in the checked-in shell is at or above the minimum for claimed API surface (30 for `ApplicationExitInfo`).

### 4. CI — new proof workflow following established pattern

A new `phase-v40-proof.yml` follows the exact hermetic/advisory split from `phase58-proof.yml`:

**Hermetic job** (`runs-on: macos-15`, merge-blocking):
- `erlef/setup-beam` + `actions/setup-java temurin:17` (existing pattern)
- Elixir: runtime-line policy tests, doctor extension tests, permission template generation and content-check tests, rebuild-policy contract tests
- iOS shell: `xcodebuild build-for-testing` with `CROSSWAKE_IOS_BUILD_FOR_TESTING=0` (compile-only, no simulator launch needed for contract proof)
- Android JVM: `./gradlew testDebugUnitTest` with `CROSSWAKE_ANDROID_CONNECTED_TESTS=0` (existing proven pattern)

**Advisory emulator/device job** (`runs-on: macos-15`, `continue-on-error: true`, schedule-only):
- `ReactiveCircus/android-emulator-runner@v2` with `api-level: 35`, `arch: x86_64`, `target: aosp_atd`
- Runs `connectedDebugAndroidTest` for instrumented verification
- This is the advisory lane for Android verification closure, not a merge-blocking requirement

---

## What NOT to Add

| Avoid | Why | What to Do Instead |
|-------|-----|-------------------|
| **Firebase Crashlytics / BugSnag / Sentry SDK** | These are broad native SDKs that the maintainer house style explicitly forbids; they introduce transitive deps, require registration, and would claim crash delivery outside Crosswake's authority boundary | Use `MetricKit` (iOS) + `ApplicationExitInfo` (Android) — both are stdlib, deliver JSON-serialisable diagnostics, and are host-export-only; the shell emits diagnostic payloads to a host-owned endpoint, never to a third-party collector |
| **Capacitor / Expo / React Native bridge adaptors** | Directly contradicts the project thesis — no JS-framework-first abstraction | Keep bridge contracts semantic, typed, versioned |
| **Standalone shell packages** (`crosswake_ios_shell`, `crosswake_android_shell`) | Not ready until release choreography is solved; checked-in `examples/` remain the proof artifact class | Shells stay in `examples/` as host-owned artifacts |
| **SPM (Swift Package Manager) dependencies in the shell** | The iOS shell intentionally has no SPM dependencies; adding any would create transitive dep surface and complicate adopter customisation | Keep shell as pure Xcode project; MetricKit is Apple-bundled |
| **KVM-based Linux emulator in merge-blocking CI** | `ubuntu-24.04` does not have `/dev/kvm` available on standard GitHub-hosted runners; emulator tests on Linux are unreliable | Keep emulator lane on `macos-15` and mark it advisory with `continue-on-error: true` |
| **AGP 9.x / Kotlin 2.1+** | AGP 9.x is early-access as of mid-2025; Kotlin 2.1.x unstable branches introduce K2-related API churn not worth absorbing yet | Pin AGP `8.5.1` and Kotlin `2.0.21` which are both stable GA |
| **`compileSdk 36` / API 36** | API 36 is still in preview as of mid-2025; `compileSdk 35` is the correct production floor | Stay at `compileSdk 35` / `targetSdk 35` |
| **OTP 28 for CI** | OTP 28.0 landed May 2025; the project pins `27.3` which is LTS and fully sufficient; upgrading has no v4.0 benefit and risks runner image availability gaps | Stay at OTP `27.3`; revisit for v4.1 or later |
| **Gradle Managed Devices (`crosswakeApi34`)** for advisory proof | The existing `managedDevices` block in `app/build.gradle` uses `aosp-atd` system images that require `cmdline-tools`; `ReactiveCircus/android-emulator-runner@v2` is more reliable in GitHub Actions advisory lanes | Use `ReactiveCircus/android-emulator-runner@v2` for the advisory emulator lane; keep `managedDevices` for local developer use only |
| **`androidTestImplementation` additions for advisory proof** | Broad instrumented test libraries widen the advisory lane surface; the advisory lane should exercise existing `connectedDebugAndroidTest` targets, not add new instrumented test frameworks | Reuse the existing `androidx.test.ext:junit:1.2.1` / `androidx.test:runner:1.6.1` already in `app/build.gradle` |

---

## Version Compatibility Matrix

| Component | Current Pin | v4.0 Target | Compatibility Notes |
|-----------|-------------|-------------|---------------------|
| Elixir | `~> 1.19` (1.19.5) | No change | 1.19.5 is latest stable in the 1.19 branch; 1.20-rc.x exists but is not yet GA |
| OTP | `27.3` | No change | OTP 28.2 is stable but upgrade is optional and low-value for v4.0 |
| Phoenix | `~> 1.8` | No change | Not involved in shell generation |
| iOS SDK / Xcode | Xcode 16 / iOS 18 SDK | Xcode 16.4 (default on `macos-15` from Aug 2025) | MetricKit available iOS 14+; no min deployment target change needed |
| Swift | 5.9 (implicit in Xcode 16) | No change | Shell uses Swift 5.9 idioms; Swift 6 strict concurrency not required |
| Android `minSdk` | `26` | **`30`** | `ApplicationExitInfo` requires API 30 (Android 11); Google Play's minimum effective floor is already 28+ for new apps; moving to 30 is safe and correct |
| Android `compileSdk` / `targetSdk` | `34` | **`35`** | Google Play required `targetSdk 35` for updates in 2025 |
| AGP | `8.4.1` | **`8.5.1`** | Required for `compileSdk 35` support; one-line change in `settings.gradle` |
| Kotlin | `1.9.24` | **`2.0.21`** | Kotlin 2.0 stable; pairs with AGP 8.5+; K2 compiler default |
| Gradle Wrapper | (AGP 8.4.1 default ~8.6) | **`8.11.1`** | AGP 8.5+ requires Gradle 8.7+; `8.11.1` is stable as of mid-2025 |
| `ReactiveCircus/android-emulator-runner` | not yet used | **`v2.36.0`** | Advisory emulator lane only; supports API 35 + `aosp_atd` |
| `api-level` for advisory AVD | `34` (existing managed device) | **`35`** | Must match `compileSdk 35` / `targetSdk 35` for instrumented tests |

---

## Stack Patterns by Variant

**Crash/diagnostic export (iOS):**
- Implement `MXMetricManagerSubscriber` in the shell's `CrosswakeShellApp.swift`
- On `didReceive(_: [MXDiagnosticPayload])`, serialize `crashDiagnostics` via `.jsonRepresentation()` and POST to a host-owned diagnostic endpoint (host-provided base URL from `CrosswakeManifest`)
- No third-party SDK; no registration; no data leaves the host's own infrastructure
- Doctor checks: verify the diagnostic endpoint URL is declared and non-placeholder

**Crash/diagnostic export (Android):**
- On app start, call `ActivityManager.getHistoricalProcessExitReasons(null, 0, 5)`
- Filter for `REASON_CRASH` / `REASON_ANR` / `REASON_CRASH_NATIVE`
- Serialize exit records (reason, description, timestamp, PSS, RSS) plus trace input stream content to JSON
- POST to the same host-owned diagnostic endpoint pattern as iOS
- No third-party SDK; `ApplicationExitInfo` is Android API 30+ stdlib

**Permission/entitlement template generation:**
- `mix crosswake.gen.shell ios` gains `--permissions` and `--entitlements` option flags that gate template sections
- Generated files carry `# HOST OWNED` header; doctor checks for placeholder text (`NSCameraUsageDescription: "TODO: Replace this"`)
- Entitlements `.entitlements` file is generated but intentionally empty except for comments until host operator opts in to each entitlement class

**Android rebuild vs. OTA-safe classification:**
- `RuntimeLine.rebuild_required?/2` checks against a static classification table in `Crosswake.SupportMatrix.runtime_line_truth/0`
- `:ota_safe` changes: manifest JSON updates, backend route policy changes, bridge capability version bumps within a declared range
- `:rebuild_required` changes: new native capability families, `native_runtime_version` major bump, new permission/entitlement requirement, `minSdk` / `targetSdk` changes, new `<activity>` / `<service>` declarations in `AndroidManifest.xml`
- Doctor surfaces rebuild requirement prominently if the current `native_runtime_version` in the compatibility block is newer than what the last proven binary shipped

---

## Installation Notes

No new Elixir hex deps to install.

Android `app/build.gradle` changes:
```groovy
// Bump these three values
android {
  compileSdk 35
  defaultConfig {
    minSdk 30        // was 26; required for ApplicationExitInfo (API 30)
    targetSdk 35     // was 34; required for Google Play compliance
  }
}
```

`settings.gradle` changes:
```groovy
id 'com.android.application' version '8.5.1' apply false   // was 8.4.1
id 'org.jetbrains.kotlin.android' version '2.0.21' apply false  // was 1.9.24
```

`gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-bin.zip
```

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Elixir/OTP/Mix layer | HIGH | All existing, verified against live CI and codebase |
| iOS MetricKit integration | HIGH | Apple stdlib since iOS 14; `MXCrashDiagnostic` JSON serialization is documented and stable; no SPM dependency |
| Android `ApplicationExitInfo` | HIGH | Android API 30 stdlib; documented stable API; `minSdk 30` is the correct and safe floor |
| AGP / Kotlin / Gradle bump | MEDIUM-HIGH | AGP 8.5.1 + Kotlin 2.0.21 + Gradle 8.11.1 are all GA stable; version compatibility verified via official release notes; minor risk is build cache invalidation on first upgrade |
| `ReactiveCircus/android-emulator-runner` for advisory lane | MEDIUM | v2.36.0 is widely used; advisory-only means CI failures do not block merge; API 35 + `aosp_atd` support confirmed via search |
| EEx template generation for permissions/entitlements | HIGH | Crosswake already uses this exact pattern for all shell files; adding template sections is low-risk |
| Device-UAT checklist | HIGH | Pure markdown artifact; no tooling dependency; follows the advisory promotion criteria pattern established in v3.2+ |

---

## Sources

- `examples/android_shell_host/app/build.gradle` — confirmed current AGP `8.4.1`, Kotlin `1.9.24`, `minSdk 26`, `compileSdk 34`
- `examples/ios_shell_host/CrosswakeShell/Info.plist` — confirmed current permission and WKAppBoundDomains shape
- `.github/workflows/phase18-proof.yml` — confirmed hermetic Android JVM proof pattern (`setup-java temurin:17`, `CROSSWAKE_ANDROID_CONNECTED_TESTS=0`)
- `.github/workflows/phase58-proof.yml` — confirmed hermetic/advisory two-lane pattern and pinned SHA action versions
- `script/verify_generated_android_shell.sh` — confirmed existing SDK provisioning logic, AVD creation, emulator boot pattern
- `script/verify_generated_ios_shell.sh` — confirmed `xcodebuild build-for-testing`, `xcrun simctl`, `PlistBuddy` pattern
- `lib/crosswake/doctor/doctor.ex` — confirmed `phase_NN_findings` extension pattern and support-matrix integration
- `lib/mix/tasks/crosswake.gen.shell.ex` — confirmed EEx template generation pattern for new permission/entitlement template additions
- [AGP 8.5.0 release notes](https://developer.android.com/build/releases/agp-8-5-0-release-notes) — compileSdk 35 support (MEDIUM confidence: official Android Developers docs)
- [AGP 8.11.0 release notes](https://developer.android.com/build/releases/agp-8-11-0-release-notes) — current stable 8.x branch confirmation (MEDIUM)
- [Erlang OTP 28.2 release](https://github.com/erlang/otp/releases/tag/OTP-28.2) — OTP 28 stable history; OTP 27.3 pin still valid
- [Elixir v1.19 changelog](https://hexdocs.pm/elixir/changelog.html) — 1.19.5 confirmed current stable
- [Apple MetricKit documentation](https://developer.apple.com/documentation/MetricKit) — official; iOS 14+ availability, `MXCrashDiagnostic` JSON export confirmed
- [Android ApplicationExitInfo reference](https://developer.android.com/reference/kotlin/android/app/ApplicationExitInfo) — official; API 30 minimum confirmed
- [ReactiveCircus/android-emulator-runner](https://github.com/ReactiveCircus/android-emulator-runner) — v2.36.0 with API 35 + aosp_atd support confirmed
- [Google Play targetSdk requirements](https://developer.android.com/google/play/requirements/target-sdk) — targetSdk 35 requirement for 2025 confirmed

---

*Stack research for: v4.0 Production Shell Runtime Line*
*Researched: 2026-06-03*
