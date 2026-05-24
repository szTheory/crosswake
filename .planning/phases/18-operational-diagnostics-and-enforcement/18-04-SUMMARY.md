---
phase: "18-operational-diagnostics-and-enforcement"
plan: "04"
title: "Layered proof slices and explicit Android JVM gate"
executed_at: "2026-05-21T21:56:46Z"
commits: []
files_changed:
  - "test/crosswake/proof/phase18_bounded_family_lane_test.exs"
  - "test/crosswake/proof/phase18_deep_link_activation_lane_test.exs"
  - "script/verify_phase18_contract.sh"
  - ".github/workflows/phase18-proof.yml"
  - "guides/support_matrix.md"
---

# Phase 18 Plan 04 Summary

Phase 18 now has explicit bounded-family and deep-link activation proof slices, and the iOS shell lane passed locally. The Android JVM proof gate has been shifted into the dedicated `Phase 18 Proof` GitHub Actions workflow because this environment does not have a Java runtime.

## Completed Work

- Added `phase18_bounded_family_lane_test.exs` to prove family-first bounded bridge behavior and the transfer-backed `file_picker` exception.
- Added `phase18_deep_link_activation_lane_test.exs` to keep deep-link activation truth separate from route-local bridge authority.
- Verified the iOS shell test suite locally, including `BridgeChannelTests`.
- Reconfirmed that the Android proof command is still blocked at `java -version` in this environment.
- Added a dedicated `Phase 18 Proof` GitHub Actions workflow so the remaining Android shell proof can run in CI without human UAT.

## Verification

- `mix test test/crosswake/proof/phase18_bounded_family_lane_test.exs test/crosswake/proof/phase18_deep_link_activation_lane_test.exs test/crosswake/shell/activation_test.exs`
  - Result: passed
- `xcodebuild test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17'`
  - Result: passed (`17 tests, 0 failures`) on 2026-05-21
- `java -version && (cd examples/android_shell_host && ./gradlew test --tests dev.crosswake.shell.BridgeChannelTest)`
  - Result: blocked locally because no Java runtime is installed; closure moved to CI via `Phase 18 Proof`
- `.github/workflows/phase18-proof.yml`
  - Result: added as the machine gate that will run the Phase 18 Elixir suite, iOS shell tests, and Android shell verification in CI

## Blocker

- Phase 18 cannot be treated as fully verified until the `Phase 18 Proof` workflow runs green and closes the Android shell lane on CI evidence.

## Self-Check

PENDING
