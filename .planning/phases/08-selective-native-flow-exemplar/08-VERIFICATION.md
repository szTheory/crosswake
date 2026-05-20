# Phase 8 Verification: Selective Native Flow Exemplar

## Goal Backward Analysis

Phase 8 needed to prove one narrow device-heavy route could move into explicit native ownership while surrounding routes remained Phoenix-owned and contract-bounded.

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| NATIVE-01 | One selective-native exemplar flow moves a single route into explicit native ownership | PASSED | `test/crosswake/proof/phase8_selective_native_lane_test.exs`, checked-in shell manifests, `08-selective-native-flow-exemplar-02-SUMMARY.md`, `08-selective-native-flow-exemplar-03-SUMMARY.md` |
| NATIVE-02 | The exemplar uses declared pack, transfer, and capability seams instead of ad hoc container behavior | PASSED | `test/crosswake/proof/phase8_selective_native_lane_test.exs`, `script/verify_selective_native.sh`, `guides/packs.md`, `guides/bridge.md`, `08-selective-native-flow-exemplar-04-SUMMARY.md` |

## Verification Evidence

- `bash script/verify_selective_native.sh`
- `mix test test/crosswake/proof/phase8_selective_native_lane_test.exs`
- `bash script/verify_phase5_example_hosts.sh`

## Overall Phase Outcome

`passed`
