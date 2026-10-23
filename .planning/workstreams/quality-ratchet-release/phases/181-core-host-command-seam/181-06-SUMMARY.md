---
phase: 181-core-host-command-seam
plan: 06
status: complete
requirements: [SEAM-04]
candidate: /private/tmp/crosswake-phase181-impl
candidate_head: b9ad8854f2fb9eef4040a917151e2e205c38eac5
commits: 1
---

# Phase 181 Plan 06: offline_island admission Summary

The bounded iOS shell now admits `offline_island` routes as their own presentation (`ShellPresentation.offlineIsland`) that shares the web container and passes the same ordered checks as `live_view`. Any other runtime string is denied with the accurate hint.

## What changed (candidate repo)

- `ActivationCoordinator.swift`: public `WebRuntime` enum (`liveView`, `offlineIsland`); `LiveViewSession.runtime` (last property, after `hostCommandDeniedVersions`); `ShellPresentation.offlineIsland(LiveViewSession)`; resolve uses a closed, exact, case-sensitive switch (`"live_view"`, `"offline_island"`, default denied with `compatibility_mismatch` and the D-14 message/hint). Required-pack label is "Offline island" for islands, "LiveView" otherwise. Check order is unchanged. Navigation authorizes `.offlineIsland` through the existing non-denied path.
- `CrosswakeShellApp.swift`: `.offlineIsland` arm renders the same `LiveViewContainerView` (added after line 444; no hunk at or above line 115).
- `OfflineIslandAdmissionTests.swift`: 15 tests (island/live_view paired for version, inactive, external entry, pack, origin; near-miss runtimes; seam-fixture host command granted and `not_registered`; native_screen unchanged; navigation equals fresh resolve).

Host apps with an exhaustive `switch` over `ShellPresentation` must add the `.offlineIsland` arm. This source break is intended (D-11); the 181-09 guide note covers it.

## Commit

| Task | Commit |
|---|---|
| 1 and 2 (combined) | b9ad8854f2fb9eef4040a917151e2e205c38eac5 `feat(181-06)` |

## Results after the last commit

- Root `mix test`: 2206 tests, 0 failures (78 excluded)
- examples/phoenix_host: 150 tests, 0 failures
- `swift test`: 80 tests, 0 failures
- Example host `xcodebuild build`: BUILD SUCCEEDED
- phase154_catalog_guard + navigation_shell_advisory tests: 38 tests, 0 failures

## Deviations

1. Tasks 1 and 2 were committed together as one commit (the test file was written whole), so there is no separate task-2 commit.
2. Admission tests compare denial reason, message, hint and route id rather than whole denials: the `safeFallback` recovery action depends on a live_view route existing in the manifest, unrelated to the runtime under test.
3. The 181-05 tests that rewrite the seam fixture's `lesson` route to `live_view` (in `SeamWorld.load`) were left as is. Island coverage uses a local `islandWorld()` helper that switches the runtime without editing the fixture file. Switching the shared helper would change those tests' presentation case and was out of scope.
4. `fallbackURL` still picks a `live_view` route only; not changed (no plan requirement).

## Next action

Execute wave 7 (181-07) in the candidate repo. No push or merge is authorized.
