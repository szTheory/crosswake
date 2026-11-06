---
phase: 198-android-foreign-host-proof
plan: 06
subsystem: support-truth
tags: [android, evidence-ceiling, capability-map, support-matrix, docs-sync]
status: complete

requires:
  - phase: 198-android-foreign-host-proof
    provides: "Plans 01-05: JVM floor, vector-set hash on both platforms"
provides:
  - "Crosswake.SupportMatrix typed Android evidence ceiling (levels, ceiling :jvm_hermetic, labels, validate_android_evidence!/1 raising, android_boundary/0)"
  - "CapabilityMap.Row.android_evidence (default :not_claimed, validated when built) and the Android evidence column in guides/capability_map.md"
  - "One source for the Android boundary sentence in lib and tests"
affects: [198-07, 198-08]

actuals:
  tokens: 9000
  tasks: 3
  commits: 3
plan_head_before: e455f818a593a434f5bb734dc9591bad58b95d06
plan_head_after: 7b02bcb7b69890447f193b2f6da5467afe6414b4

tech-stack:
  added: []
  patterns: ["typed claim ceiling that raises with rule names only", "generated guide column rendered from a typed field"]

key-files:
  created:
    - test/crosswake/support_matrix/android_evidence_test.exs
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/capability_map.ex
    - lib/crosswake/capability_map/renderer.ex
    - guides/capability_map.md
    - test/crosswake/capability_map/renderer_test.exs
    - test/crosswake/capability_map/capability_map_test.exs
    - test/crosswake/support_matrix/renderer_test.exs

key-decisions:
  - "Only bounded-bridge-app-info carries :jvm_hermetic: it is the only wire command (app.info.get) that a non-elixir_only request vector exercises (vec-003, vec-004 to vec-011, vec-014 to vec-017 in the corpus; vec-001 is elixir_only)"
  - "guides/native_shell.md is a documented hand-written exemption, held equal to android_boundary/0 by a whitespace-normalized pin test"
  - "Ceiling stays at :jvm_hermetic; raising it needs an ADR A1 amendment"

requirements-completed: []

coverage:
  - id: D1
    description: "Typed Android evidence ceiling with raise controls"
    requirement: AND-01
    verification:
      - kind: unit
        ref: "test/crosswake/support_matrix/android_evidence_test.exs (9 tests); mutation control: ceiling set to :device turns 3 tests red, restored"
        status: pass
    human_judgment: false
  - id: D2
    description: "Android evidence column rendered per capability row, outside the Declared iOS Host Setup section"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "mix crosswake.docs.sync --check clean; header pin; rendered JVM hermetic proof cell count equals typed count (1); 0 occurrences inside the Declared iOS Host Setup section"
        status: pass
    human_judgment: false
  - id: D3
    description: "Boundary sentence single-sourced"
    requirement: AND-01
    verification:
      - kind: integration
        ref: "lib literal count 1 (baseline 3); guide copies capability_map 1, support_matrix 3, native_shell 1 (exempt, pinned)"
        status: pass
    human_judgment: false
---

# Phase 198 Plan 06: Android evidence ceiling Summary

The Android claim ceiling is now typed (`:not_claimed < :jvm_hermetic < :emulator < :device`, ceiling `:jvm_hermetic`), validated whenever a capability row is built, shown as an `Android evidence` column after `Proof posture`, and the boundary sentence renders from one function.

## What was checked and what happened

- Task 1 (tracer, `bf1ff181`): added the five SupportMatrix functions and `Row.android_evidence`; `row/1` validates through `validate_android_evidence!/1`, so a canonical row at `:device` cannot be built. The guide gained the 11th column. Header pin updated in the same commit.
- Task 2 (`fdddce2e`): the two support-matrix notes strings, the support-matrix renderer's `Android (existing contracts)` row and the capability-map renderer's adoption paragraph now interpolate `android_boundary/0`. The two verbatim pins in `support_matrix/renderer_test.exs` compare against the function. Only `guides/capability_map.md` changed on regeneration (the paragraph now carries the canonical sentence followed by `Native-control breadth stays frozen.`); `guides/support_matrix.md` was already byte-identical.
- Task 3 (`7b02bcb7`): 9 API tests plus 1 capability-map test.

## Row choices (D-22)

| Row | android_evidence | Justification |
|---|---|---|
| bounded-bridge-app-info | :jvm_hermetic | `app.info.get` is the `command` of non-elixir_only request vectors vec-003, vec-004 to vec-011, vec-014 to vec-017 (Kotlin BridgeConformanceTest executes them) |
| bounded-bridge-haptics | :not_claimed | `haptics.impact` appears only in reply-leg vectors, not in a request vector |
| bounded-bridge-share | :not_claimed | `share.invoke` has no request vector |
| permissions-status | :not_claimed | `permissions.status` has no request vector |
| notification-token | :not_claimed | `notifications.token.get` has no request vector |
| all others | :not_claimed | default |

C10 check: the single rendered `JVM hermetic proof` line has no `support` after the cell. No row had to be reset.

## Exemption record

`guides/native_shell.md` (about line 33) holds a hard-wrapped hand-written copy of the boundary sentence. It is not a docs.sync projection, so it cannot render from a function and was not edited. Test 9 in `android_evidence_test.exs` asserts its whitespace-normalized text contains the normalized `android_boundary/0` value exactly once.

## Test floors

- Baseline measured before Task 1: 100 (capability_map plus support_matrix, `ran=100`), matching the planner's number, so the 110 floor stands. After: `ran=110`, `failures=0`.
- Documentation-contracts set (Task 2): total 288, excluded 5, `ran=283`, floor 248, `verdict=PASS`.
- `mix crosswake.docs.sync --check`, `mix compile --warnings-as-errors` and `mix format --check-formatted` on every changed Elixir file exit 0.

## TDD record (Task 3)

The tests were written after the implementation already existed (Task 1 owned the API), so there was no natural failing run. As the RED substitute, a mutation control set `@android_evidence_ceiling :device`: 24 tests ran (the two files), 3 failed (ceiling test, above-ceiling raise test, capability-map ceiling test). The source was restored from a byte copy and the tests then passed.

## Deviations from Plan

None. During Task 1 I briefly applied the Task 2 notes interpolation and reverted it before committing, so each commit holds only its own task's change.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust-boundary file access.

## AND-01 status

Not marked complete. AND-01 also needs the generated parity ledger and the test that Swift and Kotlin reference the same hash (Plan 07). This plan supplies the typed Android cell API that the ledger will use.

## Self-Check: PASSED

- FOUND: test/crosswake/support_matrix/android_evidence_test.exs
- FOUND commits: bf1ff181, fdddce2e, 7b02bcb7 (ancestors of HEAD)
- `.planning/config.json` and the phase 197 `.review-diagnostics/` left untouched and unstaged
