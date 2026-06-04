# Phase 67: Native Shell Implementation & Android JVM Hermetic Proof - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

iOS and Android shells mirror the contracts/templates defined in Phase 64, 65, and 66. For Android, build against updated toolchain floors (minSdk 30, compileSdk/targetSdk 35) and set up merge-blocking JVM hermetic proof. For iOS, apply Xcode 26 SDK and mirror contracts. Android remains `:verification_required`.

</domain>

<decisions>
## Implementation Decisions

### Android Toolchain Floor
- **D-01:** **AGP 8.5 + Kotlin 1.9.24 + Gradle 8.7.** 
- **D-02:** `minSdk 30` (Android 11, covers 90%+ devices, modern crypto/TLS/background limits). `compileSdk 35` / `targetSdk 35` (meets 2026 Google Play requirements).
- **D-03:** Kotlin 1.9.24 is the most stable LTS before the K2 compiler shift. Ensures the shell remains a rock-solid, copy-able artifact without imposing K2 on older adopter plugins.

### Diagnostic Export Capture
- **D-04:** **OS-Native Asynchronous Capture (No Eager Handlers).** Do not use `NSSetUncaughtExceptionHandler` or similar brittle, eager approaches that conflict with APM tools.
- **D-05:** **iOS:** Implement `MXMetricManagerSubscriber`. Filter for `MXCrashDiagnostic` and `MXHangDiagnostic`, map to Phase 65 `Envelope`, and fire HTTP POST.
- **D-06:** **Android:** On `Application.onCreate` (or boot), query `ActivityManager.getHistoricalProcessExitReasons`. Filter for `REASON_CRASH`, `REASON_ANR`, etc., map to `Envelope`, and fire POST.
- **D-07:** Adheres strictly to Phase 65 redaction allowlist by relying on OS structures.

### HTTP Transport Implementation
- **D-08:** **Zero-Dependency Native Transport.**
- **D-09:** **iOS:** `URLSession.shared.dataTask(with: request)`.
- **D-10:** **Android:** `java.net.HttpURLConnection`.
- **D-11:** The Phase 65 contract strictly expects a fire-and-forget HTTP POST. Zero third-party dependencies keep the shell lightweight, auditable, and truly "hermetic" without bloat or supply-chain risk.

### JVM Hermetic Proof Scope
- **D-12:** **Robolectric 4.13+ for Merge-Blocking JVM Lane.**
- **D-13:** Satisfies `AVER-01` without emulator flakiness. Natively shadows `ActivityManager` and `Application`, allowing fake `ApplicationExitInfo` records injection to assert that the shell correctly maps to Phase 65 `Envelope` and calls the network.
- **D-14:** Device UAT remains fully relegated to the advisory lane (AVER-03 in Phase 68).

### Claude's Discretion
- Code-level naming and organization within the Android/iOS shells as long as it adheres to the zero-dep rule and the architectural decisions defined here.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — v4.0 "Production Shell Runtime Line" goal. Android stays `:verification_required` (advisory-until-promotion).
- `.planning/REQUIREMENTS.md` — AVER-01, AVER-02 for Android, Xcode 26 SDK for iOS.
- `.planning/ROADMAP.md` — Phase 67 boundary.
- `.planning/phases/65-diagnostic-export-seam-elixir/65-CONTEXT.md` — Phase 65 Envelope struct, payload mapping, redaction allowlist constraints, and HTTP POST semantic details.
- `.planning/phases/64-runtime-line-policy-contract-support-truth-taxonomy/64-CONTEXT.md` — The `native_runtime_version` and evidence taxonomy this phase's shells must adopt.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/ios_shell_host/CrosswakeShell/` — iOS shell codebase. Needs updating to Xcode 26 and `URLSession` POST integration.
- `examples/android_shell_host/app/build.gradle` — Android gradle config to bump to `compileSdk 35` and `minSdk 30`.
- Phase 65 `Crosswake.Shell.DiagnosticExport` struct fields (reference for mapping).

### Established Patterns
- OSS Maintainer DNA: No bloat, no third-party HTTP libraries on the shell if native suffices (URLSession, HttpURLConnection).
- Hermetic Proof: Robolectric over emulators to avoid flaky CI lanes.
- Fire-and-forget HTTP POST: the app does not await a response, the data is pushed out as-is mapped to the Envelope.

### Integration Points
- Android Application class: Query `getHistoricalProcessExitReasons` here.
- iOS AppDelegate/SceneDelegate: Register `MXMetricManagerSubscriber` here.
- iOS `.github/workflows/phase67-proof.yml` (or similar, needs to use Xcode 26).
- Android `.github/workflows/phase67-proof.yml` (or similar, Robolectric tests JVM lane).

</code_context>

<specifics>
## Specific Ideas

- Robolectric shadowing of `ActivityManager` and `ApplicationExitInfo` for the Android JVM tests.
- OS-native MetricKit / ApplicationExitInfo batching rather than eager capture logic.

</specifics>

<deferred>
## Deferred Ideas

- Advisory emulator lane and capability-parity-locked device-UAT checklist (Phase 68).
- Docs-contract parity gate, actual Android `:supported` promotion, and closeout (Phase 69).

</deferred>

---

*Phase: 67-Native Shell Implementation & Android JVM Hermetic Proof*
*Context gathered: 2026-06-04*