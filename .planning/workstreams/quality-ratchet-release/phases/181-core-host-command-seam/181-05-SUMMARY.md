---
phase: 181-core-host-command-seam
plan: 05
subsystem: ios-shell-core
tags: [host-commands, seam, swift, bridge]
requirements: [SEAM-03, SEAM-05]
status: complete
commits: 3
plan_head_before: fead90724b6ee2cd7ca7a96725dcfc31e98a21ba
plan_head_after: bcf0977
key-files:
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift
    - test/crosswake/shell/host_command_seam_swift_constant_test.exs
  created:
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandSeamTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandNavigationTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/HostCommandWireTests.swift
---

# Phase 181 Plan 05: Per-route host command grant (iOS shell) Summary

The iOS shell now gives each route only the host commands that route declared, that the app registered, and whose declared version is 1.x.y. It re-checks on every navigation, deep link and back step. Every refusal names the route and command.

## What changed (plain language)

- A route gets a host command only if the manifest declares it, the app registered it, the declared version is 1.x.y (versions such as 2.0.0, 0.9.0, 1.0 or x are refused), and the manifest's seam version is not newer than the shell's 1.0.0.
- Navigation requests no longer copy one route's host commands into another route. A command registered for route A and invoked on route B is refused.
- A malformed `host_commands` field (a list, a string, a bad name, a non-string version) blocks boot with "Shell boot blocked". The field being absent, null or `{}` grants nothing new.
- Refused commands are recorded privately (route id, command, issue name only) in `LiveViewSession.hostCommandDenials` and `ActivationCoordinator.hostCommandDiagnostics`, sorted by command. Issue names: not_registered, version_unsupported, seam_unsupported, manifest_unavailable, request_unavailable.
- Bridge denials keep the reason `undeclared_capability`. Only the message and hint changed, with four texts: undeclared, not registered, seam unsupported, version unsupported.

## D-28 resolution in plain language

This changes D-15's "absent host_commands decodes to empty" wording and one D-17 row. A manifest from before schema 1.2.0 has no `host_commands` field. It decodes as "absent" (nil), and the route keeps today's behavior exactly. An activation that already carries a registered command keeps working, for the entry route only. A present field, including `{}` and null, is the only authority.

## Commits (candidate /private/tmp/crosswake-phase181-impl, branch phase181-impl)

| Task | Commit | Content |
|------|--------|---------|
| 1 (tracer) | ab9d245 | HostCommandSeam range and grammar helpers, Route.hostCommands decoding, grantHostCommands, per-route session capabilities, navigation fix, diagnostics, fixture-based tests, Elixir drift test for supportedCommandMajor |
| 2 | ff95d74 | HostCommandNavigationTests and HostCommandWireTests |
| 3 | bcf0977 | BridgeChannel denial messages (hunks start at line 414, above the pinned lines 128/133/286/292 untouched) plus four message tests |

Final candidate HEAD: bcf09770 (short bcf0977). Tree clean.

## Verification (each captured to a file, exit code checked)

- Root `MIX_ENV=test mix test`: 2206 tests, 0 failures (78 excluded). It was 2205 before, plus the new drift test.
- examples/phoenix_host: 150 tests, 0 failures.
- `swift test`: 65 tests, 0 failures. It was 39 before. Added: Seam 15, Navigation 7, Wire 4.
- Example host `xcodebuild build` (generic iOS Simulator, CODE_SIGNING_ALLOWED=NO): BUILD SUCCEEDED.
- Catalog guard plus contract tests: 42 tests, 0 failures. NavigationCoordinator.swift is unchanged from base.
- The grant table test exercises 63 rows (3 routes x 3 registered sets x 7 versions).

## Deviations from Plan

1. **[Rule 3 - fixture runtime]** The generated fixture's `lesson` route has runtime `offline_island`, which the shell does not resolve before 181-06. Tests load the fixture and rewrite routes to `live_view`, entry `external`, and opaque topology ids (`route-aaaa...`) via the memberwise initializers. The fixture file is untouched.
2. **[Rule 2 - legacy entry route on navigation]** The plan said to strip every host.* key in the navigation request. The legacy (D-28) path needs the entry route's own baseline entries, or navigating back to the entry route would lose today's behavior. The closure strips host.* for every route except the entry route. The legacy branch also requires the resolved route id to equal the entry route id, so nothing leaks to other routes. The non-legacy path ignores request host.* in all cases.
3. **[Additive field]** The version_unsupported message needs the declared version, so `LiveViewSession.hostCommandDeniedVersions: [String: String]` was added right after `hostCommandDenials`, with a default. It holds manifest versions of denied commands only. 181-06 should add its runtime field after it.
4. **[Order choice]** When a command is both unregistered and out of range, `not_registered` is recorded. The seam check comes first and takes precedence over both.
5. **[Dedupe]** `hostCommandDiagnostics` skips identical records, so repeated `resolve` calls do not grow it without bound.
6. **[Test determinism]** Session equality in the navigation matrix is compared against a fresh `resolve` on the same coordinator, because each coordinator draws a random thread id.
7. Task commits were split after the fact. Task 1 and 3 production code was written together, then the BridgeChannel change and the message tests were held back so each commit builds and passes on its own.

No threat flags beyond the plan's threat model. No stubs. No new dependencies. Android and the pinned guards were not touched.

## Next action

Execute 181-06 (offline_island admission and the runtime field on LiveViewSession) on the same candidate branch, starting from bcf0977.

## Self-Check: PASSED

Commits ab9d245, ff95d74 and bcf0977 are ancestors of candidate HEAD. The three new test files and this SUMMARY exist. The suites above were green after the last commit.
