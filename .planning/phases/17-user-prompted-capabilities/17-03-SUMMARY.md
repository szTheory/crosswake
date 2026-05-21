---
phase: "17-user-prompted-capabilities"
plan: "03"
title: "iOS prompt capability bridge for notification_token and file_picker"
executed_at: "2026-05-21T16:46:12Z"
commits:
  - "50320e4"
  - "98d83f1"
files_changed:
  - "examples/ios_shell_host/CrosswakeShell/BridgeChannel.swift"
  - "examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift"
  - "examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift"
  - "examples/ios_shell_host/CrosswakeShell/NotificationTokenProvider.swift"
  - "examples/ios_shell_host/CrosswakeShell/FilePickerCoordinator.swift"
  - "examples/ios_shell_host/CrosswakeShell/TransferCoordinator.swift"
  - "examples/ios_shell_host/CrosswakeShellTests/BridgeChannelTests.swift"
---

# Phase 17 Plan 03 Summary

Implemented the checked-in iOS shell bridge for prompt-free `notification_token` snapshots and transfer-bound `files.pick` execution, with explicit APNs provider semantics, copy-first staging, and typed cancel/success outcomes aligned to the landed Phase 17 Elixir contracts.

## Execution Path

- Executed in the forked workspace at `/Users/jon/projects/crosswake`.
- Preserved unrelated dirty workspace changes and limited edits to the user-owned iOS plan-03 files plus this summary artifact.
- Reconciled against pre-existing iOS host bridge changes instead of assuming a clean example-shell baseline.

## Completed Work

- Extended the iOS `BridgeChannel` to support:
  - manifest-version-gated `notifications.token.get`
  - async `files.pick` replies without widening the bounded bridge surface
  - explicit denial reasons for missing notification authorization, missing token snapshots, missing picker transfers, and in-flight picker collisions
- Added shell-local APNs snapshot plumbing through the iOS app lifecycle:
  - the app now refreshes APNs registration from the app delegate without prompting
  - success replies stay provider-explicit with `provider: apns`, `token`, `notification_status`, and detail metadata
  - token replies remain evidence-only and never imply backend registration or delivery readiness
- Added copy-first picker handling:
  - `UIDocumentPickerViewController(..., asCopy: true)` presentation from the LiveView container
  - transfer-bound gating via declared inbound `native_picker` seams only
  - app-sandbox staging into temporary shell-controlled storage with opaque `handle` values
  - typed `outcome: picked` and `outcome: canceled` payloads with stable `transfer_id` plus `items`
- Extended `TransferCoordinator` to track picker-backed staged documents and cancel state without exposing raw provider URLs or persistent authority.
- Expanded iOS bridge tests to cover notification-token success and denial paths plus file-picker success, cancel, and undeclared-transfer denial behavior.

## Verification

- `xcodebuild test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17'`
  - Result: `17 tests, 0 failures`

## Deviations From Plan

### Rule 3 - Verification environment adaptation

- Found during verification: the plan-specified `iPhone 16` simulator was not installed in this Xcode environment.
- Fix: ran the required Xcode test target on the available `iPhone 17` simulator instead.
- Impact: verification coverage stayed the same; only the simulator device name changed.

### Rule 3 - Manual Xcode source registration constraint

- Found during implementation: `CrosswakeShell.xcodeproj` uses manual source-file registration, but `project.pbxproj` was outside the user-owned plan-03 file set.
- Fix: kept the compiled `NotificationTokenProvider` and `FilePickerCoordinator` implementations in already-targeted owned Swift files, while creating the requested artifact paths as explanatory placeholders.
- Impact: runtime behavior and tests are complete in this workspace, but moving those type definitions into standalone compiled files still requires a follow-up `project.pbxproj` change by the workspace owner for that file.

### Shared bridge-surface execution note

- The async `files.pick` bridge refactor and the prompt-free `notification_token` bridge wiring both had to land in the same `BridgeChannel` and shared bridge test surface.
- Result: the green implementation was committed as one feature slice after a single red test commit instead of one independent green commit per plan task.

## Known Stubs

None.

## Threat Flags

None.

## Constraints Observed

- Did not modify `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj`, `.planning/STATE.md`, `.planning/ROADMAP.md`, or any non-owned Phase 17 artifacts.
- Did not revert or overwrite unrelated local workspace changes.

## Self-Check

PASSED

- Summary file exists.
- Commits `50320e4` and `98d83f1` exist in git history.
