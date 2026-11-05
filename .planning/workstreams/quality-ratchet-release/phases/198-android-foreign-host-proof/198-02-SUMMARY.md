---
phase: 198-android-foreign-host-proof
plan: 02
subsystem: android-shell-core
tags: [kotlin, jvm-tests, bridge-channel, boundary-tests, fail-closed]

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plan 01: android-json test artifact, BridgeFixtures, BridgeChannelBoundaryTest (4 tests), evaluate seam"
provides:
  - "16 new BridgeChannel boundary testcases (20 in BridgeChannelBoundaryTest), counted near-miss groups with positive controls"
  - "BridgeFixtures.status, denialReason and vectorCommands helpers"
  - "Kotlin core JVM suite at 37 tests, 0 failures, 0 errors, 0 skips"
affects: [198-03]

actuals:
  tokens: 9000
  tasks: 3
  commits: 3
plan_head_before: 45335b9ea3e019c23640b2874d7e29f9be30a0a7
plan_head_after: 6cf7a51000dde71df9d3ba6ea372e6d0b39a664b

tech-stack:
  added: []
  patterns: ["each near-miss group asserts a ran-count after a positive-control baseline", "deny helper asserts status and nested denial.denial.reason together"]

key-files:
  created: []
  modified:
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeChannelBoundaryTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeFixtures.kt

key-decisions:
  - "No production, shared-vector, Swift or Elixir change; every case behaved fail-closed, so no finding was recorded"
  - "server.event.push and server.state.update ungated behavior pinned as characterization only, pointing at debt row (a) in 198-DECISIONS.md"

requirements-completed: []  # AND-02 floor of 25 JVM tests is met (37) but the requirement also spans later Phase 198 plans; the orchestrator or Plan 03 closes it

coverage:
  - id: D1
    description: "Compatibility, route, origin and deny-shape boundaries fail closed"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "BridgeChannelBoundaryTest (wrong protocol, malformed version, route id, origin near misses, deny shape)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Command, capability, pack-authority, side-effect and precedence boundaries"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "BridgeChannelBoundaryTest (command near misses, aliases, request claimed packs, capability gating, side effects, precedence)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Transfer, files.pick, permissions alias, command-set parity, D-14 characterization"
    requirement: AND-02
    verification:
      - kind: unit
        ref: "BridgeChannelBoundaryTest (transfer null coordinator, deferred picker, permissions alias, command wire parity, server characterization)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-11-05
status: complete
---

# Phase 198 Plan 02: BridgeChannel boundary tests Summary

**BridgeChannelBoundaryTest now covers every D-12 boundary group with counted near-miss loops and positive controls; the Kotlin core JVM suite is at 37 tests with no failures or skips. JVM evidence only; nothing was run on a device.**

## Accomplishments

- Forced `cleanTestDebugUnitTest testDebugUnitTest`: 37 tests, 0 failures, 0 errors, 0 skips; `BridgeChannelBoundaryTest` reports 20 tests (4 from Plan 01 plus 16).
- Every near-miss loop asserts its ran-count, so an empty case list cannot pass.
- No fail-open case: every near miss the plan lists returned `deny` with the expected reason. No finding to report.
- No production, shared-vector, Swift or Elixir file changed (verified with `git diff --name-only` against the Plan 01 summary commit for `src/main`, `test/fixtures` and `packages/crosswake-shell-core-ios`; empty).

## Cases and observed reasons

Task 1 (tracer):

| Test | Cases | Observed |
|---|---|---|
| wrong protocol | `crosswake.bridge2`, empty, `Crosswake.Bridge` (3) | `compatibility_mismatch` |
| malformed request version | deny: empty, `abc`, `1.0.0-beta`, `1.0.0.0`, `99999999999.0.0` (5); accept: `1`, `1.0` (2) | denials `compatibility_mismatch`; accepts `ok` |
| route id mismatch | `route_id` differs, `active_route_id` differs (2) | `inactive_route` |
| origin near misses | trailing slash, `http://`, `:8443` port, uppercase host, `@evil.test` userinfo, `null`, empty (7) | `origin_denied` |
| deny reply shape and privacy | sentinel `CW-SENTINEL-SECRET-198` in `payload` and `capabilities` on an `origin_denied` deny | top-level `payload` empty; `denial.denial` has reason, code, message, route_id, hint; sentinel absent; sentinel in `correlation_id` is present (echo control) |

Task 2:

| Test | Cases | Observed |
|---|---|---|
| command near misses | `App.Info.Get`, `app.info.get ` (trailing space), empty, `app.info.get.x` (4) | `undeclared_capability` |
| capability mismatch and aliases | `files.pick`/`files.pick`; `app.info.get`/`haptics.impact` | `undeclared_capability`; alias pairs `files.pick`/`file_picker` and `notifications.token.get`/`notification_token` (2) pass that gate and deny `unavailable_capability` (session declares neither) |
| request-claimed packs | request claims `test-pack` 2.0.0 with none in session; empty demand `test-pack@`; two requirements with one missing | `pack_incompatible`; positive control (session pack installed) and unversioned requirement return `ok` |
| capability gating | session capabilities empty; session `2.0.0` over request `1.0.0` | `unavailable_capability` |
| side effects | haptics counter | origin-denied: 0; correct origin: `ok` and 1 |
| precedence | protocol+route+origin; route+origin; origin+command; unknown command with missing pack | `compatibility_mismatch`; `inactive_route`; `origin_denied`; `undeclared_capability` |

Task 3:

| Test | Cases | Observed |
|---|---|---|
| transfer null coordinator | `transfer.import`, `.export`, `.download`, `.upload.prepare` (4) | `undeclared_capability` |
| deferred files.pick, no sink | `FilesPickResult.Deferred` | `unavailable_capability`; the picker starter was never invoked |
| permissions.status alias | missing alias, `camera`; control `notifications` | `unavailable_capability`; control `ok` |
| command-set parity | Kotlin `BridgeCommand` wire values vs corpus `commands` (10) | corpus is a subset; difference is exactly `{server.event.push, server.state.update}` |
| D-14 characterization | `server.event.push` with `name`, session capabilities empty; without `name`; `server.state.update` `bogus` and control `connected` | `ok` (ungated); `invalid_payload`; `ok` with `MutableStateFlow` unchanged; `connected` moves the flow (control) |

## Task Commits

1. **Task 1 (tracer): compatibility, scope, origin and deny-shape** - `521b9b41` (test)
2. **Task 2: command, capability, pack, side-effect, precedence** - `98a74838` (test)
3. **Task 3: transfer, files.pick, permissions alias, parity, D-14** - `6cf7a510` (test)

The tracer gate passed end-to-end (full forced Gradle run, 26 tests green) before expansion.

## Deviations from Plan

None. The plan executed as written. The branch is `test/198-android-foreign-host-proof` per recorded override I-3.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. Test-only change; no new network endpoint, auth path or trust-boundary surface. T-198-05 through T-198-08 mitigated by the tests above; T-198-09 accepted and characterized with the debt row.

## Self-Check: PASSED

- FOUND: BridgeChannelBoundaryTest.kt, BridgeFixtures.kt, 198-02-SUMMARY.md
- FOUND commits: 521b9b41, 98a74838, 6cf7a510
- `.planning/config.json` and the Phase 197 `.review-diagnostics/` directory were never staged.
