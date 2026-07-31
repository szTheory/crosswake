---
phase: 158-adoption-reset-and-route-map
plan: 02
subsystem: capability-map
tags: [elixir, capability-map, markdown, compatibility, first-b2c-adopter]
dependency_graph:
  requires: [158-01-SUMMARY.md, 158-CONTEXT.md]
  provides: [canonical-adoption-implication, fail-closed-legacy-alias, regenerated-capability-guide]
  affects: [phase-159-host-proof, phase-162-physical-iphone-proof]
tech_stack:
  added: []
  patterns: [single-compatibility-normalizer, deterministic-generated-guide, public-phrase-guard]
key_files:
  created: []
  modified:
    - lib/crosswake/capability_map.ex
    - lib/crosswake/capability_map/renderer.ex
    - test/crosswake/capability_map/capability_map_test.exs
    - test/crosswake/capability_map/renderer_test.exs
    - guides/capability_map.md
decisions:
  - Canonical capability rows use adoption_implication; v20_implication remains a renderer input alias for one documented compatibility window.
  - Conflicting canonical and legacy implication values fail closed without echoing supplied row content.
requirements-completed: [RESET-01, RESET-04]
coverage:
  - id: D1
    description: Canonical capability rows expose adoption implication while legacy map inputs remain compatible and conflict-safe.
    requirement: RESET-01
    verification:
      - kind: unit
        ref: test/crosswake/capability_map/renderer_test.exs#D-11/D-12 normalizes canonical and legacy implication inputs through one compatibility window
        status: pass
    human_judgment: false
  - id: D2
    description: Generated public capability guide is byte-identical, deterministically ordered, and uses first-adopter framing.
    requirement: RESET-04
    verification:
      - kind: unit
        ref: test/crosswake/capability_map/renderer_test.exs#D-06/D-20/D-21 guides/capability_map.md is byte-identical to renderer output
        status: pass
      - kind: unit
        ref: test/crosswake/capability_map/renderer_test.exs#D-11/D-13 public guide uses first-adopter framing without active native-control breadth
        status: pass
    human_judgment: false
metrics:
  duration: 10m
  completed_date: 2026-07-31
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 158 Plan 02: First-Adopter Capability Truth Summary

Canonical capability rows now use `adoption_implication`, with one fail-closed legacy input alias and a regenerated public guide focused on the first adopter.

## What Changed

- Replaced the canonical row field and every canonical row's v20 implication with `adoption_implication`.
- Added the renderer's sole implication normalizer: atom and string-key map input works, equal aliases normalize once, and conflicting aliases raise a stable `ArgumentError` without exposing input text.
- Kept rendered row order stable, including equal implication values, and regenerated the capability guide through `Renderer.write/0`.
- Reworded current implications around route ownership, host-reusable proof, scoped replay, one foreground iOS adapter, and physical-iPhone proof; active native-control breadth is no longer recommended.

## Verification

- Passed: `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/capability_map/renderer_test.exs` (17 tests, 0 failures).
- Attempted phase quick command: `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/capability_map test/crosswake/support_matrix`.
  Capability-map and support-matrix suites passed; the planning-context assertion remains blocked by the pre-existing executor-start `STATE.md` transition described in `deferred-items.md`.

## TDD Gate Compliance

- RED: `b859a7e7` — failing canonical-field, compatibility, and conflict tests.
- GREEN: `0b3921a6` — canonical field migration and renderer normalization.

## Task Commits

1. Task 1 — `b859a7e7`, `0b3921a6`
2. Task 2 — `2c5e4e5a`

## Decisions Made

- The compatibility alias is intentionally confined to renderer input normalization and must be removed only through a documented breaking compatibility change.
- Public capability prose uses `first adopter`; it does not position Native Controls Pack 1 as active work.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Required implementation, focused tests, and generated guide exist.
- Task commits `b859a7e7`, `0b3921a6`, and `2c5e4e5a` exist in git history.
