---
phase: 43-rulestead-hermetic-advisory-proof-and-guide
plan: "02"
subsystem: companion-docs
tags: [docs, docs-contract, rulestead, companions]
requirements-completed: []

dependency_graph:
  requires:
    - guides/commerce.md (guide voice and docs-contract pattern)
    - lib/crosswake/companions/rulestead.ex
    - lib/crosswake/companions/rulestead/mock_flag_source.ex
    - lib/crosswake/support_matrix/support_matrix.ex
  provides:
    - guides/companions.md (companion-pattern intro + rulestead section)
    - test/crosswake/guides/companions_test.exs (anchor and live-code guard)
    - mix.exs docs extras registration for guides/companions.md
  affects:
    - ExDoc guide surface
    - hermetic test suite docs-contract coverage

tech_stack:
  added: []
  patterns:
    - static guide anchor assertions via File.read!
    - live-code docs guards via Code.ensure_loaded! + function_exported?/3

key_files:
  created:
    - guides/companions.md
    - test/crosswake/guides/companions_test.exs
  modified:
    - mix.exs

decisions:
  - Scope stayed to the Phase 43 rulestead slice only; no rindle or sigra placeholder sections were added.
  - PROOF-02 remains globally pending because Phase 47 owns the full rulestead/rindle/sigra companion guide contract.
  - Code.ensure_loaded!/1 is used before function_exported?/3 to make export checks reliable under lazy module loading.

metrics:
  completed_date: "2026-05-31"
  tasks_completed: 2
  files_modified: 3
---

# Phase 43 Plan 02: Rulestead Companion Guide Summary

Plan 43-02 is complete. `guides/companions.md` now contains the companion-pattern intro and a complete rulestead section covering `gated_by`, `on_unavailable`, gate-state semantics, `kill_switch`, fail-closed behavior, `MockFlagSource`, doctor diagnostics, configuration, and advisory-lane promotion criteria. The guide is registered in `mix.exs` ExDoc extras.

`test/crosswake/guides/companions_test.exs` locks the guide to live code with anchor assertions and export guards for:

- `Crosswake.Companions.Rulestead.validate_dependency/0`
- `Crosswake.Companions.Rulestead.MockFlagSource.set_flag/2`
- `Crosswake.SupportMatrix.gating_truth/0`

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Write `guides/companions.md` and register it in ExDoc extras | a83b817 |
| 2 | Add docs-contract test for guide anchors and live-code exports | ada90f0 |

## Verification Results

- `mix test test/crosswake/guides/companions_test.exs` = **9 tests, 0 failures**
- Anchor/no-scope check = **GUIDE_OK**
- `guides/companions.md` contains `gated_by`, `on_unavailable`, `kill_switch`, `MockFlagSource`, and `fail-closed`.
- `guides/companions.md` contains no `rindle` or `sigra` content.
- `mix.exs` contains `guides/companions.md` in docs extras and still contains the `MIX_INCLUDE_RULESTEAD` conditional dep.

## Deviations from Plan

None for the delivered artifacts. The prior executor completed this plan's files while closing 43-01, then crashed before creating this summary and updating phase bookkeeping.

## Requirements Satisfied

- Phase 43's rulestead slice of PROOF-02 is satisfied.
- The broader PROOF-02 requirement remains pending for Phase 47 because it also requires the full rulestead/rindle/sigra guide surface and deferred non-goals.

## Known Stubs

None in this slice. The production `Rulestead.Snapshot` adapter remains explicitly deferred by the guide's promotion path.

## Self-Check: PASSED

All declared files exist on disk and the plan-level verification passed.
