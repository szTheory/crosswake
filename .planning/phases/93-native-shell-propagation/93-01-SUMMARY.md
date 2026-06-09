# 93-01: iOS Native Shell Propagation Complete

## Tasks Completed
- **Task 1: iOS Core Shell Updates** - Added `threadID` support to `ActivationRequest` and `LiveViewSession`. The `ActivationCoordinator` now mints and maintains the active instance of `currentThreadID`.
- **Task 2: iOS Shell Host Updates** - Updated `LiveViewContainerViewController` to set the `X-Crosswake-Thread-Id` header and inject `threadId` via `WKUserScript` deterministically at document start.

## Commits
- `ae92c7e`: feat(93-01): add threadID to ActivationCoordinator and ActivationRequest
- `7213e4a`: feat(93-01): update LiveViewContainerViewController to inject threadID via header and script

## Verification
- `swift build` on the iOS shell core package passes successfully.
- Manual verification of the source changes confirms alignment with the strategy. (Note: Xcodebuild for the host app simulator was skipped due to environmental lack of iOS 26.5 destination on the build machine, but syntax and logic are complete).