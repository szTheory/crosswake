# Phase 67: Native Shell Implementation & Android JVM Hermetic Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 67-Native Shell Implementation & Android JVM Hermetic Proof
**Areas discussed:** Android Toolchain Floor, Diagnostic Export Capture, HTTP Transport Implementation, JVM Hermetic Proof Scope

---

## Android Toolchain Floor

| Option | Description | Selected |
|--------|-------------|----------|
| AGP 8.3 / Kotlin 1.9 | Stable LTS | |
| AGP 8.4+ / Kotlin 2.0 (K2) | Modern, fast, breaks older plugins | |
| AGP 8.5 + Kotlin 1.9.24 + Gradle 8.7 | Stable, rock-solid, covers API 35 requirements without K2 risk | ✓ |

**User's choice:** AGP 8.5 + Kotlin 1.9.24 + Gradle 8.7
**Notes:** Chosen to keep the shell a solid copy-able artifact without imposing K2 on older adopter plugins.

---

## Diagnostic Export Capture

| Option | Description | Selected |
|--------|-------------|----------|
| Real-time capture (Eager) | Uses `NSSetUncaughtExceptionHandler`, brittle, drops data | |
| OS-Native Asynchronous Capture | MetricKit on iOS, `ApplicationExitInfo` on Android | ✓ |

**User's choice:** OS-Native Asynchronous Capture (No Eager Handlers)
**Notes:** Embraces the host OS lifecycle and guarantees payload conforms strictly to Phase 65 redaction allowlist.

---

## HTTP Transport Implementation

| Option | Description | Selected |
|--------|-------------|----------|
| Third-party client libs | Alamofire / OkHttp | |
| Zero-Dependency Native Transport | URLSession / HttpURLConnection | ✓ |

**User's choice:** Zero-Dependency Native Transport
**Notes:** Crosswake shells are checked-in proof artifacts. Native dependencies keep footprint small and auditable.

---

## JVM Hermetic Proof Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Pure JUnit + MockK | Heavy mocking | |
| Emulators | Flaky on CI | |
| Robolectric 4.13+ | Natively shadows Android framework on JVM | ✓ |

**User's choice:** Robolectric 4.13+ for Merge-Blocking JVM Lane
**Notes:** Satisfies AVER-01 hermetic proof requirement with zero flakiness.

---

## Claude's Discretion

Code-level naming and organization within the Android/iOS shells as long as it adheres to the zero-dep rule and architectural decisions.

## Deferred Ideas

None — discussion stayed within phase scope.