---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
plan: "01"
subsystem: proof-lane
tags: [proof, hermetic, tdd, wave-0, rline]
requirements-completed: [RLINE-01, RLINE-02, RLINE-03, RLINE-04, RLINE-05]

dependency_graph:
  requires: []
  provides:
    - "Wave-0 hermetic proof lane: test/crosswake/proof/phase64_runtime_line_policy_test.exs"
    - "Green-up target for plans 02-05"
  affects:
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs

tech_stack:
  added: []
  patterns:
    - ExUnit hermetic proof lane (no @moduletag :requires_example_host)
    - CaptureIO over Mix.Task.run for doctor integration assertions
    - ProofAssertions.stable_id_message/7 for drift reporting
    - struct!(Types.Capability, ...) with required :id/:version keys

key_files:
  created:
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs
  modified: []

decisions:
  - Used %Types.Capability{id: "test.*", version: "1.0", rebuild: ...} pattern because Capability has @enforce_keys [:id, :version] — test structs must satisfy all enforce_keys

metrics:
  duration: "~4 minutes"
  completed: "2026-06-04"
  tasks_completed: 1
  files_created: 1
---

# Phase 64 Plan 01: Wave-0 Hermetic Proof Lane Summary

Wave-0 hermetic ExUnit proof scaffold covering all RLINE-01..05 assertions across RebuildPolicy classification, Compatibility struct integrity, rebuild matrix surface, evidence taxonomy, and Android promotion criteria.

## What Was Built

Created `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — the canonical Wave-0 green-up target for the entire Phase 64. The file defines `Crosswake.Proof.Phase64RuntimeLinePolicyTest` with 11 tests tagged across 5 requirement groups:

**RLINE-01 (3 tests):** Assert `RebuildPolicy.rebuild_required?/1` returns false for `:none` and true for `:native_required`/`:companion_required`. Assert `classify/2` returns `{:rebuild_required, :native_shell}` for `:native_required` capabilities across all 6 capability-axis change classes, `{:rebuild_required, :companion_shell}` for `:companion_required`, `:ota_safe` for `:none`, and `{:rebuild_required, :native_shell}` for system-level classes `:sdk_floor_bump`/`:privacy_manifest_entry` with nil capability.

**RLINE-02 (3 tests):** Assert `Compatibility` struct has EXACTLY the 5 locked fields. Assert canonical `manifest.compatibility.manifest_schema_version == "1.0.0"`. Assert co-truth parity: `classify/2` agrees with `action_classes()` `rebuild_required` boolean for every action class.

**RLINE-03 (4 tests):** Assert `SupportMatrix.rebuild_matrix/1` returns a non-empty `[%Types.RuntimeLineRow{}]` including a `"1.x"` row. Assert doctor human output contains `"rebuild & compatibility matrix:"`. Assert doctor JSON output has a `"rebuild_matrix"` key holding a list. Assert structural parity: every `runtime_line` in JSON is also present in human output.

**RLINE-04 (4 tests):** Assert entries with `:device_verified` exist and doctor output contains `"device-verified"`. Assert entries with `:jvm_hermetic` exist and doctor output contains `"jvm-hermetic (CI only)"`. Assert `SupportMatrix.validate/1` returns a non-empty error list when a CI-only entry claims `:device_verified`. Assert doctor `"evidence posture:"` line contains `ios=device-verified` and `android=jvm-hermetic (CI only)`.

**RLINE-05 (3 tests):** Assert `promotion_rules()` contains `"shell.android.jvm_hermetic"` with `minimum_consecutive_passes: 3` and `required_verification_method: :jvm_hermetic`. Assert `"shell.android.device_verified"` row exists with `required_verification_method: :device_verified` and `demotion_trigger` mentioning Phase 67/68 and the jvm_hermetic gating note. Assert canonical Android `SupportEntry.status == :verification_required` (D-20 guardrail).

**Hermetic lane guard (1 test):** Asserts no `@moduletag`, no example-host module references, no `MIX_INCLUDE_*` flags.

## Wave-0 RED State Confirmed

Running `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs` RED-fails with a compile error:

```
error: Crosswake.Manifest.Types.RuntimeLineRow.__struct__/1 is undefined
```

This is the intended Wave-0 state — `RuntimeLineRow` (plan 02), `RebuildPolicy` (plan 03), `rebuild_matrix/1` (plan 04), and the doctor rendering (plan 05) are not yet implemented. The proof lane is the single green-up target for the phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Capability struct requires :id and :version enforce_keys**
- **Found during:** Task 1 — first test run attempt
- **Issue:** `%Types.Capability{rebuild: :native_required}` raised `ArgumentError: the following keys must also be given when building struct Crosswake.Manifest.Types.Capability: [:id, :version]` because `@enforce_keys [:id, :version]` is set on the struct
- **Fix:** Added `id: "test.native", version: "1.0"` (and equivalent for companion/ota variants) to all Capability struct literals in the tests
- **Files modified:** `test/crosswake/proof/phase64_runtime_line_policy_test.exs`
- **Commit:** ed01a3a (included in task commit)

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This plan creates a test-only file with no production module changes.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `test/crosswake/proof/phase64_runtime_line_policy_test.exs` | FOUND |
| Commit `ed01a3a` | FOUND |
| `64-01-SUMMARY.md` | FOUND |
