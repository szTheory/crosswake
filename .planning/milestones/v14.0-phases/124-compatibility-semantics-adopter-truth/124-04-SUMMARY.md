---
phase: 124-compatibility-semantics-adopter-truth
plan: "04"
subsystem: doctor
tags: [doctor, publish-readiness, advisory-check, compatibility, compat-04]
dependency_graph:
  requires: [124-02]
  provides: [compatibility_rebuild_guidance_check, action_sequence_for, contract_version_parity_errors]
  affects: [lib/crosswake/doctor/publish_readiness.ex, test/crosswake/doctor/publish_readiness_test.exs]
tech_stack:
  added: []
  patterns:
    - advisory_check/1 builder (never result_check/1) for non-blocking checks
    - Shared detector extraction (contract_version_parity_errors/1) for anti-disagreement guarantee
    - Two-tier severity (advisory baseline / warning on detected drift)
    - Honest microcopy ("cannot observe a live denial — guidance, not a detected failure")
key_files:
  created: []
  modified:
    - lib/crosswake/doctor/publish_readiness.ex
    - test/crosswake/doctor/publish_readiness_test.exs
decisions:
  - "advisory_check/1 used exclusively — result_check/1 always emits :error on fail, which this check prohibits"
  - "action_sequence_for/1 expands native-rebuild into 4 discrete ordered steps"
  - "per_class_guidance_map/0 builds from SupportMatrix.change_classes/1 then overrides native-rebuild entry with 4 steps"
  - "baseline active_action_sequence defaults to native-rebuild 4 steps (worst-case shown even when no drift)"
  - "denial_vocabulary in details sourced from Denial.reasons/0 cast to strings"
  - "contract_version_parity_errors/1 extracted so parity check and advisory check share one detector and can never disagree"
metrics:
  duration: "3m 14s"
  completed: "2026-06-20"
  tasks_completed: 2
  files_modified: 2
status: complete
---

# Phase 124 Plan 04: Doctor Advisory Rebuild Guidance Summary

**One-liner:** Advisory `compatibility_rebuild_guidance` doctor check with 4-step native-rebuild sequence, shared parity detector, denial vocabulary, and honest microcopy — never `:error`, never blocking.

## What Was Built

### Task 1: Extract `contract_version_parity_errors/1` as the shared detector

Extracted the error-collection logic inlined in `contract_version_parity_check/1` into a new private function `contract_version_parity_errors(cwd) :: [String.t()]`. The parity check now delegates to it. Observable output (id/code/message/severity/blocking/details) is byte-for-byte unchanged. All 11 existing tests still pass after the extraction.

**Refactor commit:** `6d2c336`

### Task 2: Add `compatibility_rebuild_guidance_check/1` + `action_sequence_for/1` + `per_class_guidance_map/0`

Added:
- `alias Crosswake.Shell.Denial` (denial vocabulary source)
- `compatibility_rebuild_guidance_check/1` — built via `advisory_check/1` (never `result_check/1`)
- `action_sequence_for/1` — derives per-class action list from `SupportMatrix.change_classes/1`; expands `"native or companion rebuild required"` into 4 discrete ordered steps
- `per_class_guidance_map/0` — builds the full 4-class guidance map with expanded native steps
- Check appended last in `build_checks/0`

**New check shape:**

| Field | Baseline (no drift) | Drift detected |
|-------|---------------------|----------------|
| `code` | `diag.compat.rebuild_guidance_baseline` | `diag.compat.rebuild_guidance_drift_detected` |
| `severity` | `:advisory` | `:warning` |
| `result` | `:pass` | `:fail` |
| `blocking` | `false` | `false` |
| `category` | `:compatibility_rebuild_guidance` | `:compatibility_rebuild_guidance` |

**`details` keys:**
- `active_action_sequence` — ordered list of steps (4 steps for native-rebuild)
- `change_class_guidance` — map of all 4 change-class strings to their action sequences
- `docs_reference` — `"guides/compatibility.md"`
- `denial_vocabulary` — list of all `Denial.reasons/0` atoms as strings
- `detected_drift_errors` — list of drift error strings (empty at baseline)

**4-step native-rebuild sequence (exact order):**
1. Regenerate shell via mix crosswake.gen.shell
2. Rebuild native app
3. Resubmit to App Store / Play Store
4. Coordinated deploy with updated Hex package

**Feature commit:** `cfaa94a`

## Verification

```
mix test test/crosswake/doctor/publish_readiness_test.exs
19 tests, 0 failures
```

- 11 existing tests still pass (parity extraction preserves behavior)
- 8 new tests cover: baseline advisory, never-:error in both states, :warning-on-drift, 4 ordered steps, denial vocabulary, message/hint microcopy disclaimer, guide link

## Deviations from Plan

### Auto-decisions (within plan discretion)

**1. Baseline active_action_sequence uses the 4-step native-rebuild sequence**

The plan grants "Claude's discretion" for exact details keys, and specifies the baseline should carry "the FULL static baseline" including "the ordered action sequence." I chose to default `active_action_sequence` to the native-rebuild 4 steps (worst-case guidance) even at baseline — matching the microcopy intent that doctor should "tell them exactly what to do, in order" even before drift is confirmed. The `change_class_guidance` map provides per-class sequences for all four classes.

**2. `denial_vocabulary` added as explicit details key**

The plan requires the denial vocabulary to appear in the advisory. Rather than only embedding it in the prose `hint`, I added it as `details.denial_vocabulary: [String.t()]` so it is machine-accessible alongside `active_action_sequence`. This supports the "machine arrays for machines" intent from D-15.

None of the above violate D-12..D-15.

## Threat Coverage (T-124-09, T-124-10, T-124-11)

| Threat | Mitigation applied |
|--------|--------------------|
| T-124-09 (severity spoofing) | `advisory_check/1` used exclusively; test asserts `severity != :error` and `blocking == false` in both states |
| T-124-10 (false detection claim) | Microcopy in both `message` and `hint`: "cannot observe a live shell's denial — this is guidance, not a detected failure" |
| T-124-11 (detector divergence) | Both `contract_version_parity_check/1` and `compatibility_rebuild_guidance_check/1` call the extracted `contract_version_parity_errors/1` — disagreement impossible by construction |

## Self-Check: PASSED
