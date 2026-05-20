---
phase: 08-selective-native-flow-exemplar
plan: 03
subsystem: proof-fixtures
requirements-completed: [NATIVE-01, NATIVE-02]
completed: 2026-05-18
---

# Phase 8 - Plan 03 Summary

## Objective Completed
Extended the checked-in proof posture and shell fixtures so the selective-native lane becomes a public supported artifact instead of a Phoenix-only code path.

## Tasks Completed
1. **Added lane-specific proof for manifest truth and staged-state honesty**: Created assertions in `test/crosswake/proof/phase8_selective_native_lane_test.exs` to ensure exactly one Phase 8 route is `:native_screen`, and the surrounding routes remain `:live_view`. This proof also verifies capability, pack, and transfer assignments stay locked to the capture route only, and that local capture vs upload vs submission are distinct states.
2. **Aligned checked-in iOS and Android shell fixtures to the Phase 8 lane**: Updated `route_activation.json` for both platforms to use the `selective-native-claim-capture` route. Updated the `crosswake_manifest.json` on both platforms. Modified `ActivationCoordinatorTests.swift` and `LiveViewBootInstrumentedTest.kt` to exercise the pack-ready capture paths successfully. Added the new Phase 8 test file into `script/verify_phase5_example_hosts.sh` to keep all lane assertions running through the base checked-in proof entrypoint.

## Output
- `test/crosswake/proof/phase8_selective_native_lane_test.exs` is included in the unified test runner.
- Generated new canonical manifests into `examples/ios_shell_host/Fixtures/crosswake_manifest.json` and `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json`.
- Both `route_activation.json` fixtures now target `selective-native-claim-capture`.
- Full platform-aligned proof covers both pack-ready and pack-blocked paths.
