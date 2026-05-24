---
phase: "17-user-prompted-capabilities"
plan: "04"
title: "Android notification-token fail-closed seam and copy-first file picker staging"
executed_at: "2026-05-21T16:42:48Z"
commits:
  - "a5f378f"
  - "909faef"
  - "8187d5d"
files_changed:
  - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt"
  - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt"
  - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/MainActivity.kt"
  - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/NotificationTokenProvider.kt"
  - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/FilePickerCoordinator.kt"
  - "examples/android_shell_host/app/src/main/java/dev/crosswake/shell/transfer/TransferCoordinator.kt"
  - "examples/android_shell_host/app/src/test/java/dev/crosswake/shell/BridgeChannelTest.kt"
---

# Phase 17 Plan 04 Summary

Implemented the Android example-host slice for Phase 17 by adding a provider-aware `notification_token` seam that fails closed without provider setup, plus an activity-backed `files.pick` path that uses `ACTION_GET_CONTENT`, copies selected content into app-controlled staging, and returns typed staged handles instead of raw content URIs.

## Execution Path

- Executed in the forked workspace at `/Users/jon/projects/crosswake`.
- Preserved the existing dirty worktree, including unrelated Elixir, iOS, and earlier Android edits already present in this workspace.
- Applied changes only to the user-owned Android plan-04 files and this summary artifact.
- Left shared planning state files such as `.planning/STATE.md` and `.planning/ROADMAP.md` untouched because the execution request limited ownership to Android plan-04 files plus this summary.

## Completed Work

- Added `NotificationTokenProvider` as an explicit Android token seam with typed `Available` and `Denied` outcomes.
- Wired `notifications.token.get` into `BridgeChannel` and aligned Android capability checks with the Phase 17 Elixir contracts:
  - `notification_token` for `notifications.token.get`
  - `file_picker` for `files.pick`
- Kept the default Android token path fail-closed:
  - denies when notification authorization is not granted
  - denies when no provider-backed token source is configured
  - never invents a generic Android push token
- Added `FilePickerCoordinator` with:
  - `ACTION_GET_CONTENT`
  - `CATEGORY_OPENABLE`
  - transfer-bound `transfer_id` validation through `TransferCoordinator`
  - app-sandbox copy staging under cache storage
  - opaque `staged://...` handles and normalized item metadata
  - typed cancel outcome instead of empty-success cancellation
- Routed picker execution through `MainActivity` activity-result handling and `LiveViewFragment` host delegation so the bridge reply can be deferred until picker completion.
- Extended `TransferCoordinator` to validate `native_picker` seams and turn staged picker copies into typed public reply payloads.
- Expanded `BridgeChannelTest` to cover:
  - normalized `permissions.status`
  - provider-tagged `notification_token` success
  - explicit notification-token denials for missing prerequisites
  - transfer-bound `files.pick` success and cancel payload shapes

## Verification

- `java -version && (cd examples/android_shell_host && ./gradlew test --tests dev.crosswake.shell.BridgeChannelTest)`
  - Result: blocked locally because this environment does not have a Java runtime installed.
  - Observed failure: `Unable to locate a Java Runtime.`
- Because Java is unavailable here, Gradle and JVM proof for `BridgeChannelTest` is now expected to close in the dedicated `Phase 18 Proof` GitHub Actions workflow rather than through manual workstation follow-up.

## Deviations From Plan

### Rule 1 - Contract alignment fix

- Found during Task 2 implementation: the Android bridge still treated `files.pick` as capability `files.pick`, while the landed Elixir contract resolves the public family as `file_picker`.
- Fix: updated Android command-to-capability mapping so `files.pick` checks `file_picker`, and `notifications.token.get` checks `notification_token`.
- Files modified: `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt`
- Commit: `8187d5d`

## Known Stubs

- `NotificationTokenProvider` intentionally denies by default after a granted notification-status preflight because no provider-backed Android token source is configured in this example host yet. This is intentional fail-closed behavior, not a fake token implementation.

## Threat Flags

None.

## Self-Check

PASSED

- Summary file exists.
- Commits `a5f378f`, `909faef`, and `8187d5d` exist in git history.
