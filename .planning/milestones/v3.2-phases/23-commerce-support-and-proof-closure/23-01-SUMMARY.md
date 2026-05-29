---
phase: 23-commerce-support-and-proof-closure
plan: 01
subsystem: doctor
tags: [elixir, doctor, support-matrix, commerce, proof-class, diagnostics]

# Dependency graph
requires:
  - phase: prior milestone commerce work
    provides: support_matrix.commerce_corridor_entries, doctor pipeline, commerce.contracts
provides:
  - Typed commerce_summary surface in doctor output (corridors, prerequisites, snapshot_freshness, proof_posture, rebuild_requirements)
  - proof_class (:merge_blocking | :advisory) on every commerce corridor entry and every commerce finding
  - Fail-closed stale/unknown entitlement snapshot diagnostic (merge-blocking)
  - native_rebuild_required diagnostic derived from canonical support matrix metadata
  - Human + JSON formatter rendering of commerce_summary and proof_class labels
affects:
  - 23-02-support-matrix-renderer  # consumes proof_class metadata
  - 23-03-reviewer-storefront-guides  # cites commerce_summary contract
  - 23-04-proof-lanes-ci  # gates on proof_class

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Proof-class taxonomy as canonical support-matrix metadata, not per-finding heuristic"
    - "Fail-closed diagnostic emission for stale/unknown entitlement freshness"

key-files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/doctor/formatter.ex
    - lib/crosswake/doctor/json_formatter.ex
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/doctor/formatter_test.exs

key-decisions:
  - "Both purchase_intent and restore_intent corridors are merge_blocking for core contract proof, with a separate advisory_provider_proof flag for StoreKit/Play Billing simulator checks"
  - "Stale or unknown snapshot freshness emits :warning severity but is tagged merge_blocking via proof_class — severity describes operator urgency, proof_class describes CI gate behavior"
  - "Native rebuild requirements are derived from canonical support matrix corridor metadata, not per-route heuristics"
  - "commerce_summary is a top-level key in both human and JSON output, separate from the findings stream — structured for both operator and CI consumption"

patterns-established:
  - "Proof-class metadata flows: support_matrix → doctor commerce_summary + findings → formatter rendering"
  - "Commerce findings carry proof_class in their :details map; formatters detect commerce.* code prefix to surface the label"

requirements-completed:
  - SUPP-04

# Metrics
duration: ~50min (paused mid-Task-3 on session limit, resumed inline)
completed: 2026-05-27
---

# Phase 23 Plan 01: Doctor Commerce Summary Surface — Summary

**Doctor now emits a typed commerce_summary surface with proof-class-labeled findings, derived from canonical support-matrix metadata, and fails closed on stale/unknown entitlement snapshots.**

## Performance

- **Duration:** ~50min (session-limit pause + inline resume)
- **Started:** 2026-05-27T13:34:40Z
- **Completed:** 2026-05-27
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Tagged every commerce corridor entry in `support_matrix.ex` with `proof_class` (`:merge_blocking` or `:advisory`) and exposed `commerce_corridor_proof_classes/0` as the canonical mapping.
- Built `Crosswake.Doctor.commerce_summary/1` returning a structured map of `corridors`, `prerequisites`, `snapshot_freshness`, `proof_posture`, and `rebuild_requirements`, wired into the doctor `run/1` pipeline alongside `findings`.
- Added fail-closed `commerce.entitlement.stale_snapshot` and `commerce.corridor.native_rebuild_required` diagnostics, both carrying `proof_class: :merge_blocking` in `details`.
- Extended both the human formatter (new `Commerce:` section + inline `[merge-blocking]/[advisory]` labels on commerce findings) and the JSON formatter (top-level `commerce_summary` key + `proof_class` field on commerce check objects).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add proof_class metadata to support matrix commerce corridor entries** — `56e07dc` (feat)
2. **Task 2: Build typed commerce summary surface in doctor pipeline** — `8cdf022` (feat)
3. **Task 3: Extend human and JSON formatters for commerce summary and proof_class output** — `5624fcc` (feat)

## Files Created/Modified
- `lib/crosswake/support_matrix/support_matrix.ex` — `proof_class` on commerce corridor entries + `commerce_corridor_proof_classes/0` mapping
- `lib/crosswake/doctor/doctor.ex` — `commerce_summary/1`, `stale_snapshot`, and `native_rebuild_required` diagnostics wired into `run/1`
- `lib/crosswake/doctor/formatter.ex` — `Commerce:` section rendering + inline `proof_class` labels on commerce findings
- `lib/crosswake/doctor/json_formatter.ex` — top-level `commerce_summary` key + `proof_class` field on commerce check objects
- `test/crosswake/support_matrix/support_matrix_test.exs` — proof_class presence + merge_blocking expectations
- `test/crosswake/doctor/doctor_test.exs` — commerce_summary structure + stale freshness merge-blocking assertion
- `test/crosswake/doctor/formatter_test.exs` — Commerce section rendering, inline label assertions

## Verification

- `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/formatter_test.exs test/crosswake/support_matrix/support_matrix_test.exs` → 32 tests, 0 failures
- `rg "commerce_summary|proof_class|stale_snapshot|native_rebuild_required" lib/crosswake/doctor lib/crosswake/support_matrix` → present across doctor.ex (43), formatter.ex (15), json_formatter.ex (9), support_matrix.ex (15), renderer.ex (5)
- `rg "proof_class" test/crosswake/doctor test/crosswake/support_matrix` → covered in doctor_test.exs (6), formatter_test.exs (6), support_matrix_test.exs (18)

## Self-Check: PASSED

All acceptance criteria across Tasks 1–3 met; verification block green.

## Notable Deviations

- Plan execution was paused mid-Task-3 due to an Anthropic session token limit on the original executor agent; the orchestrator resumed inline, validated the agent's draft formatter/JSON/test edits against the plan acceptance criteria, ran the verify command (18 → 32 tests passing), and committed Task 3 as a single atomic commit (`5624fcc`). No design or scope deviation from the plan.
