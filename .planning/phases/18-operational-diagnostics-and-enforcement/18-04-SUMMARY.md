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

Phase 18 now has explicit bounded-family and deep-link activation proof slices, and the dedicated `Phase 18 Proof` GitHub Actions workflow passed the Elixir, checked-in iOS shell, and Android JVM proof lanes.

## Completed Work

- Added `phase18_bounded_family_lane_test.exs` to prove family-first bounded bridge behavior and the transfer-backed `file_picker` exception.
- Added `phase18_deep_link_activation_lane_test.exs` to keep deep-link activation truth separate from route-local bridge authority.
- Verified the iOS shell test suite locally, including `BridgeChannelTests`.
- Reconfirmed that Android proof remains unavailable on this workstation because `java -version` fails locally.
- Added and iterated a dedicated `Phase 18 Proof` GitHub Actions workflow so Android shell proof closes on CI machine evidence instead of local workstation state.

## Verification

- `mix test test/crosswake/proof/phase18_bounded_family_lane_test.exs test/crosswake/proof/phase18_deep_link_activation_lane_test.exs test/crosswake/shell/activation_test.exs`
  - Result: passed
- `xcodebuild test -project examples/ios_shell_host/CrosswakeShell.xcodeproj -scheme CrosswakeShell -destination 'platform=iOS Simulator,name=iPhone 17'`
  - Result: passed (`17 tests, 0 failures`) on 2026-05-21
- `java -version && (cd examples/android_shell_host && ./gradlew test --tests dev.crosswake.shell.BridgeChannelTest)`
  - Result: blocked locally because no Java runtime is installed; closure moved to CI via `Phase 18 Proof`
- `.github/workflows/phase18-proof.yml`
  - Result: passed on GitHub Actions run `26498172516` on 2026-05-27. The final workflow completed in 6m34s after splitting Android JVM proof from emulator-backed connected tests.

## Blocker

- Local Android verification remains unavailable on this workstation without a Java runtime, but Phase 18 repository proof is closed by CI evidence.

## Self-Check

PASSED

- Local Phase 18 contract proof passed.
- Full local Elixir suite passed before CI proof push.
- GitHub Actions `Phase 18 Proof` run `26498172516` passed.
