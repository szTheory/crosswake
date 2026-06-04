---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
plan: "02"
subsystem: manifest/types
tags: [runtime-line, types, struct, tdd, additive]
requirements-completed: [RLINE-02, RLINE-03, RLINE-04, RLINE-05]
dependency-graph:
  requires: []
  provides:
    - Crosswake.Manifest.Types.RuntimeLineRow
    - CapabilitySupportEntry.verification_method
    - PromotionRuleEntry.required_verification_method
    - SupportMatrix.rebuild_matrix
  affects:
    - lib/crosswake/manifest/types.ex
tech-stack:
  added: []
  patterns:
    - ReleaseBoundaryEntry-mirror for RuntimeLineRow struct
    - atom_label/1 for PromotionRuleEntry atom fields; Atom.to_string/1 for CapabilitySupportEntry
    - additive-default back-compat pattern (NOT @enforce_keys)
key-files:
  created:
    - test/crosswake/manifest/types_phase64_test.exs
  modified:
    - lib/crosswake/manifest/types.ex
decisions:
  - Use atom_label/1 for required_verification_method in PromotionRuleEntry.to_map/1 (consistent with existing proof_class/promotes_to serialization in that clause)
  - Use Atom.to_string/1 for verification_method in CapabilitySupportEntry.to_map/1 (consistent with existing owner field serialization in that clause)
  - Place RuntimeLineRow defmodule after ActionClassEntry and before the @manifest_schema_version constant (follows existing inner-module ordering; before module-level attributes)
  - Place new_runtime_line_row/1 immediately before new_promotion_rule_entry/1 (logical grouping with typed row constructors)
  - Place to_map(%RuntimeLineRow{}) between ChangeClassEntry and ActionClassEntry clauses (follows struct definition ordering)
  - verification_method field type defined in CapabilitySupportEntry module; PromotionRuleEntry.@type t references it via the fully-qualified type path
metrics:
  duration: "~10 minutes"
  completed: "2026-06-03"
  tasks-completed: 2
  files-changed: 2
---

# Phase 64 Plan 02: Types Foundation (RuntimeLineRow + Verification Fields) Summary

Additive type-layer foundation in `lib/crosswake/manifest/types.ex`: new `RuntimeLineRow` struct with JSON encoding, `verification_method` field on `CapabilitySupportEntry`, `required_verification_method` field on `PromotionRuleEntry`, and `rebuild_matrix` field on `SupportMatrix` — all defaulted and back-compat, with constructors and `to_map/1` clauses. Compatibility struct and SupportEntry baseline are unchanged.

## What Was Built

### Task 1: RuntimeLineRow struct + verification_method + required_verification_method (TDD)

**New `RuntimeLineRow` struct** (`defmodule RuntimeLineRow` inside `Crosswake.Manifest.Types`):
- `@moduledoc false`, `@derive Jason.Encoder`
- `@enforce_keys [:runtime_line, :capability_surface, :change_class, :ota_safe, :rebuild_required, :evidence_tier]`
- `@type evidence_tier :: :none | :provider_advisory | :jvm_hermetic | :emulator_advisory | :device_verified`
- `new_runtime_line_row/1` constructor (all 6 fields via `Keyword.fetch!`)
- `to_map(%RuntimeLineRow{})` using `Atom.to_string/1` for `evidence_tier`

**`CapabilitySupportEntry` additive field:**
- `verification_method: :none` added to `defstruct` only (NOT `@enforce_keys`)
- `@type verification_method` enum added
- `new_capability_support_entry/1` extended with `verification_method: Keyword.get(attrs, :verification_method, :none)`
- `to_map/1` extended with `"verification_method" => Atom.to_string(support_entry.verification_method)`

**`PromotionRuleEntry` additive field:**
- `required_verification_method: :none` added to `defstruct` only (NOT `@enforce_keys`)
- `new_promotion_rule_entry/1` extended with `required_verification_method: Keyword.get(attrs, :required_verification_method, :none)`
- `to_map/1` extended with `"required_verification_method" => atom_label(entry.required_verification_method)`

**Compatibility struct: NOT touched.** SupportEntry baseline: NOT touched.

### Task 2: SupportMatrix.rebuild_matrix field (TDD - same GREEN commit)

**`SupportMatrix` additive field:**
- `rebuild_matrix: []` added to `defstruct` only (NOT `@enforce_keys`)
- `@type t` updated with `rebuild_matrix: [Crosswake.Manifest.Types.RuntimeLineRow.t()]`
- `new_support_matrix/1` extended with `rebuild_matrix: Keyword.get(attrs, :rebuild_matrix, [])`
- `to_map(%SupportMatrix{})` extended with `"rebuild_matrix" => Enum.map(support_matrix.rebuild_matrix, &to_map/1)`

## Commits

| Task | Phase | Commit | Description |
|------|-------|--------|-------------|
| RED test | TDD | 3f009bc | `test(64-02)`: 20 failing tests for all new types/fields |
| GREEN impl | Tasks 1+2 | 659704a | `feat(64-02)`: full implementation, 20 tests pass |

## Test Results

- **20 new tests** in `test/crosswake/manifest/types_phase64_test.exs` — all pass
- `mix compile --warnings-as-errors` exits 0
- Full suite: 767 tests, 37 pre-existing failures (planning transition, phase56/60 proof tests unrelated to this plan), 0 new failures introduced

## Deviations from Plan

None — plan executed exactly as written. Both tasks were implemented in a single implementation commit because the implementation naturally flows through a single file (`lib/crosswake/manifest/types.ex`) and both tasks' test assertions are validated by the same test run.

## Known Stubs

None — all fields are wired with real constructor support and `to_map/1` serialization. No placeholder values.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary surfaces introduced. This plan is pure typed struct additions with atom defaults; no runtime evaluation of untrusted input.

## Self-Check: PASSED

Files exist:
- `lib/crosswake/manifest/types.ex` — modified (verified via grep and compile)
- `test/crosswake/manifest/types_phase64_test.exs` — created (20 tests pass)

Commits exist:
- `3f009bc` — RED test commit (verified in git log)
- `659704a` — GREEN implementation commit (verified in git log)
