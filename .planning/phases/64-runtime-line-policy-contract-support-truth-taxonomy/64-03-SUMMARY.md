---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
plan: 03
subsystem: runtime-line-policy
tags: [rebuild-policy, ota-safety, capability-axis, system-classes, rline-01]
requirements-completed: [RLINE-01, RLINE-02]

dependency-graph:
  requires:
    - lib/crosswake/manifest/types.ex  # Capability.rebuild, Root.t() types
  provides:
    - lib/crosswake/runtime_line/rebuild_policy.ex  # classify/2, diff/2, rebuild_required?/1
  affects: []

tech-stack:
  added: []
  patterns:
    - contract module with @system_rebuild_classes closed-set attribute
    - capability-axis classification derived from Capability.rebuild field
    - ArgumentError guard for nil capability on capability-axis classes
    - TDD RED/GREEN cycle with :rline_01 tagged proof tests

key-files:
  created:
    - lib/crosswake/runtime_line/rebuild_policy.ex
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs
  modified: []

decisions:
  - Capability-axis change classes derive verdicts from Capability.rebuild, never from change-class label alone
  - System-level classes (sdk_floor_bump, privacy_manifest_entry) map via @system_rebuild_classes closed set
  - classify/2 raises ArgumentError when capability-axis class receives nil capability (label-only classification is forbidden)
  - diff/2 documented as tooling/doctor input, not a release-gate oracle (D-06c)

metrics:
  duration: ~15 minutes
  completed: 2026-06-03
  tasks: 1
  files: 2
---

# Phase 64 Plan 03: Implement RebuildPolicy Contract Module Summary

**One-liner:** Pure-Elixir RebuildPolicy module classifying all 8 change classes via Capability.rebuild derivation and a locked @system_rebuild_classes closed set — no label-only classification, companion never OTA-safe, diff documented as non-oracle.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED  | Failing test for RebuildPolicy classify/2, rebuild_required?/1 | 4453ebe | test/crosswake/proof/phase64_runtime_line_policy_test.exs |
| GREEN | Implement Crosswake.RuntimeLine.RebuildPolicy | f129bc9 | lib/crosswake/runtime_line/rebuild_policy.ex, test update |

## What Was Built

`Crosswake.RuntimeLine.RebuildPolicy` — a narrow, derived, additive public module implementing the RLINE-01 rebuild/OTA policy contract:

- **`classify/2`** — classifies any of the 8 change classes as `:ota_safe` or `{:rebuild_required, :native_shell | :companion_shell}`. For capability-axis classes, derives the verdict from `Capability.rebuild`. For system classes (via `@system_rebuild_classes`), returns `{:rebuild_required, :native_shell}`. Raises `ArgumentError` when a capability-axis class receives `nil` for the capability argument.
- **`diff/2`** — detects change classes between two `Root.t()` manifests and returns `[{change_class(), verdict()}]`. Documented as tooling/doctor input, NOT a release-gate oracle.
- **`rebuild_required?/1`** — public boolean predicate over `Capability.rebuild()`.

The proof test file `phase64_runtime_line_policy_test.exs` covers all 8 change classes with `:rline_01` tag, asserting correct verdicts for all three `Capability.rebuild` values, the nil-capability ArgumentError guard for all 6 capability-axis classes, and the `:companion_required` never-OTA-safe invariant.

## TDD Gate Compliance

- RED gate: `test(64-03)` commit `4453ebe` — 17 failing tests, module not yet defined.
- GREEN gate: `feat(64-03)` commit `f129bc9` — 17 tests passing, `mix compile --warnings-as-errors` clean.

## Verification

- `mix compile --warnings-as-errors` exits 0.
- `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs --only rline_01` — 17 tests, 0 failures.

## Deviations from Plan

None — plan executed exactly as written.

The test for `assert_raise` inside a `for` comprehension (Elixir limitation) was corrected to `Enum.each` during RED phase; this is a test-mechanics fix, not a behavioral deviation.

## Known Stubs

None. The module derives classification from live `Capability.rebuild` data; no hardcoded empty values or placeholder behavior.

## Threat Flags

No new security-relevant surface introduced beyond what the plan's `<threat_model>` already covers:

| Threat ID | Status |
|-----------|--------|
| T-64-08 (classify/2 capability-axis nil guard) | Mitigated — ArgumentError raised |
| T-64-09 (companion never OTA-safe) | Mitigated — test asserts across all 6 capability-axis classes |
| T-64-10 (diff/2 misuse as release gate) | Mitigated — @moduledoc and @doc explicitly state tooling-only posture |

## Self-Check: PASSED

- `lib/crosswake/runtime_line/rebuild_policy.ex` — FOUND
- `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — FOUND
- commit `4453ebe` (RED) — FOUND
- commit `f129bc9` (GREEN) — FOUND
