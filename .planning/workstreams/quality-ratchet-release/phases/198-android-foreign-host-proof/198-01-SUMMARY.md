---
phase: 198-android-foreign-host-proof
plan: 01
subsystem: android-shell-core
tags: [kotlin, jvm-tests, org-json, semver, bridge-envelope, fail-closed]

requires:
  - phase: 196-vector-evidence
    provides: shared bridge contract vectors and the 12-test Kotlin baseline
provides:
  - Kotlin core JVM tests run on the AOSP-derived android-json artifact (device-like coercion)
  - Dead kotlinx-serialization dependency and plugin removed from the core build
  - BridgeRequestEnvelope(JSONObject) rejects non-string required fields
  - BridgeChannel.parseBody and listenerAllows internal and JVM-testable
  - SemVer.parse digit-only hardening
  - 198-DECISIONS.md written record with debt rows
affects: [198-02, 198-03, 198-08, 198-12]

actuals:
  tokens: 11000
  tasks: 3
  commits: 3
plan_head_before: a988f5464d0ccbb96c23d8717724b16a29c21422
plan_head_after: a9124676d26a527222ff707c9942bafabce29c52

tech-stack:
  added: ["com.vaadin.external.google:android-json:0.0.20131108.vaadin1 (test scope only)"]
  patterns: ["internal extraction of a listener boundary so it is testable without a WebView", "JSON-typed fail-closed field accessor (requireString)"]

key-files:
  created:
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeFixtures.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeChannelBoundaryTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/SemVerBoundaryTest.kt
    - .planning/workstreams/quality-ratchet-release/phases/198-android-foreign-host-proof/198-DECISIONS.md
  modified:
    - packages/crosswake-shell-core-android/build.gradle.kts
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt
    - packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/SemVer.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt

key-decisions:
  - "JVM tests use the AOSP-derived android-json test artifact; production keeps platform org.json (D-09)"
  - "Request envelope requires JSON strings for nine required fields; malformed envelope is dropped silently on purpose (D-11)"
  - "SemVer is digit-only on Android; divergence from iOS Int(_:) recorded as debt row (e)"
  - "Branch override: ran on orchestrator-provided test/198-android-foreign-host-proof, not feat/..."

requirements-completed: [AND-02]

coverage:
  - id: D1
    description: "JVM tests run on android-json and the dead serialization dependency is gone"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "gradlew cleanTestDebugUnitTest testDebugUnitTest (21 tests, 0 failures/errors/skips)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Envelope rejects JSON null and numbers for all nine required fields (18 cases)"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "BridgeChannelBoundaryTest#envelope rejects non string required fields on the JVM"
        status: pass
    human_judgment: false
  - id: D3
    description: "Listener gate and parseBody boundary, SemVer fails closed on signed components"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "BridgeChannelBoundaryTest, SemVerBoundaryTest"
        status: pass
    human_judgment: false
  - id: D4
    description: "JSON-stack choice and related decisions recorded in writing"
    requirement: AND-02
    verification:
      - kind: other
        ref: "198-DECISIONS.md section and keyword greps"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-11-05
status: complete
---

# Phase 198 Plan 01: JVM test JSON stack, fail-closed envelope, SemVer hardening Summary

**Kotlin core JVM tests now run on the AOSP-derived android-json artifact, the request envelope rejects non-string required fields, SemVer fails closed on signed components, and the choices are recorded in 198-DECISIONS.md. JVM evidence only; nothing was run on a device.**

## Performance

- **Duration:** about 25 min
- **Completed:** 2026-11-05T22:27Z
- **Tasks:** 3
- **Files modified:** 8 (plus 1 created decisions record)

## Accomplishments

- Core JVM test count rose from 12 to 21 (forced `cleanTestDebugUnitTest testDebugUnitTest`, 0 failures, errors or skips).
- Removed the dead Kotlin serialization plugin and runtime dependency; kept `androidx.webkit` with a comment naming `addWebMessageListener`.
- `BridgeRequestEnvelope(JSONObject)` uses `requireString` for the nine required fields; an 18-case test (JSON null and a number per field) proves rejection.
- `parseBody` and `listenerAllows` extracted as internal functions; `attach` uses both and the deny reply is unchanged. Trailing-slash origin near miss is covered.
- `SemVer.parse` accepts digit-only components, `compare` uses `compareTo`.

## Task Commits

1. **Task 1 (tracer): JSON-stack swap, fail-closed envelope, first boundary test** - `84c3b53f` (test)
2. **Task 2: listener extraction and SemVer hardening** - `8cb0dff7` (feat)
3. **Task 3: 198-DECISIONS.md** - `a9124676` (docs)

TDD RED evidence for Task 2: before the hardening, `SemVerBoundaryTest > negative plus signed and overflowing components fail closed` failed with `java.lang.AssertionError at SemVerBoundaryTest.kt:38` (the `-1.0.0` demand case, which was satisfied by `0.0.0`). After the hardening all five SemVer tests passed.

## Decisions Made

See `198-DECISIONS.md`. Summary: JVM test JSON stack, intentional silent drop of malformed envelopes, SemVer digit-only rule and its iOS divergence (debt row e), explicit D-13 pin override (debt row d), D-14 debt row (a).

## Deviations from Plan

### Branch handling (recorded override I-3 in 198-DECISIONS.md)

The plan's Task 1 says to create `feat/198-android-foreign-host-proof` from origin/main and cherry-pick the Phase 198 planning commits. The dispatching orchestrator had already created `test/198-android-foreign-host-proof` from current origin/main (origin/main is an ancestor) and instructed no branch switch. No cherry-pick was performed. Consequences:

- The plan's fourth Task 1 verify gate (branch name `feat/...` and no Phase 197 commits) was adapted: branch is `test/198-android-foreign-host-proof`, origin/main is an ancestor, and no Plan 01 commit touches the Phase 197 directory.
- The branch already carries the four Phase 197 closeout commits under new hashes (67241beb, 0932e36c, 6580fd94, f8500948; originals d81c110a, 78805a06, 01eecba2, 31a782dd). The "Open items for the user" section of 198-DECISIONS.md was rewritten to say so truthfully and leaves the split-or-keep decision to the user.
- No planning-commit hashes were cherry-picked. Planning commits on the branch at start: bb1dc31f (context), cd2e06b0 (research and validation), 0ede5640, c8afc811, a988f546 (plans and checker records).

**Total deviations:** 1 (orchestrator-directed; no code impact).

## Issues Encountered

None. Removing the `WebMessageCompat` import in `BridgeChannel.kt` was a small cleanup consequence of replacing `parseRequest`.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path or trust-boundary surface; changes tighten existing boundaries (T-198-01 through T-198-04 mitigated).

## Self-Check: PASSED

- FOUND: BridgeFixtures.kt, BridgeChannelBoundaryTest.kt, SemVerBoundaryTest.kt, 198-DECISIONS.md
- FOUND commits: 84c3b53f, 8cb0dff7, a9124676
- `.planning/config.json` and the Phase 197 `.review-diagnostics/` directory were never staged.
