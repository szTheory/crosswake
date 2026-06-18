---
phase: 113-honest-e2e-rewrite-compile-gate
plan: "01"
subsystem: e2e-test-infrastructure
tags: [compile-gate, playwright, ecto, e2e, fixtures, controller]
status: complete

dependency_graph:
  requires: []
  provides:
    - compile-clean-test-tree (MIX_ENV=test mix compile --warnings-as-errors passes)
    - green-sibling-spec (offline_storage.spec.ts 3/3 passing)
    - scoped-count-endpoint (sync-state controller returns count scoped to client_mutation_id)
  affects:
    - 113-02-PLAN.md (depends on scoped count + green Playwright lane)
    - 113-03-PLAN.md (depends on compile-clean tree)

tech_stack:
  added: []
  patterns:
    - scoped Ecto aggregate with from/2 + Repo.aggregate(:count, :id) scoped to ^id
    - import Ecto.Query, warn: false to avoid --warnings-as-errors trip

key_files:
  created: []
  modified:
    - examples/phoenix_host/test/support/flashcards_fixtures.ex
    - examples/phoenix_host/e2e/offline_storage.spec.ts
    - examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex

decisions:
  - id: D-04b-fix
    summary: "create_progress/1 → upsert_progress/1 rename in flashcards_fixtures.ex line 47; this was the sole warning blocking --warnings-as-errors"
  - id: D-05-fix
    summary: "#btn-pass (dead after Phase 112 rename) → #btn-good; storage-error locator extended to full app string"
  - id: D-02-ext
    summary: "sync_state_controller extended with scoped count (from/2 WHERE client_mutation_id == ^id), @moduledoc, and import Ecto.Query, warn: false"

metrics:
  duration: "~2 minutes"
  completed: "2026-06-18"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 3
  files_created: 0

requirements: [E2E-03, E2E-04]
---

# Phase 113 Plan 01: Green Foundation — Compile Fix, Sibling Spec, Scoped Count Summary

**One-liner:** Three surgical pre-flight fixes — fixture rename unblocks the compile gate, dead button selector unblocks the Playwright lane, scoped Ecto count unblocks Plan 02's duplicate-flush proof.

## Objective

Lay the green foundation that Plans 02 and 03 both depend on: (1) fix the only compile warning blocking `--warnings-as-errors`, (2) fix the dead button selector that reds the Playwright lane, (3) extend the sync-state controller with a scoped `count` field and test-only `@moduledoc`.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Pre-flight compile fix — create_progress → upsert_progress (D-04b) | 3557ef2 | flashcards_fixtures.ex |
| 2 | Sibling-spec hygiene — #btn-pass → #btn-good + tighten storage-error text (D-05) | a5392ab | offline_storage.spec.ts |
| 3 | Extend sync-state controller — scoped count + test-only @moduledoc (D-02) | ba9f78e | sync_state_controller.ex |

## Verification Results

- `MIX_ENV=test mix compile --warnings-as-errors` — PASSED (Tasks 1 + 3)
- `npx playwright test e2e/offline_storage.spec.ts` — 3/3 PASSED (Task 2)
- `grep 'where: r.client_mutation_id == \^id' sync_state_controller.ex` — FOUND (Task 3)

## Decisions Made

**D-04b:** The sole compile warning was `create_progress/1 is undefined` at `flashcards_fixtures.ex:47` — renamed to `upsert_progress/1` (live at `flashcards.ex:82`). Single-identifier rename; pipeline shape and arguments unchanged.

**D-05:** `#btn-pass` was a dead selector after Phase 112's D-01 button rename to `#btn-good`. Tightened storage-error text locator from partial to full string `"Please free up space on your device."` — honesty tightening (was passing by substring match but misrepresenting the assertion).

**D-02:** `sync_state_controller.ex` extended with: `@moduledoc` stating test-only/`:test`+`:e2e` mount (pre-stages Phase 114 GUARD-02); `import Ecto.Query, warn: false` (required for `from/2`; `warn: false` avoids tripping the gate); scoped count via `from(r in ReviewEvent, where: r.client_mutation_id == ^id) |> Repo.aggregate(:count, :id)`. Returns `count: 0` in `nil` branch, `count: count` in record branch. Bare `Repo.aggregate` NOT used (would count entire table, > 1 in multi-test runs).

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

T-113-01 mitigation verified: `sync_state_controller.ex` is mounted only under `Mix.env() in [:test, :e2e]` (router.ex ~line 378). The added `@moduledoc` documents this; Phase 114 GUARD-02 will add the enforced assertion.

T-113-02 mitigation verified: `client_mutation_id` path param flows into `^id` — Ecto parameterization, no string interpolation, no SQL-injection surface.

## Known Stubs

None — all three changes are complete, functional, and wired correctly.

## Self-Check: PASSED

Files exist:
- `/Users/jon/projects/crosswake/examples/phoenix_host/test/support/flashcards_fixtures.ex` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/e2e/offline_storage.spec.ts` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` — FOUND

Commits:
- 3557ef2 — FOUND
- a5392ab — FOUND
- ba9f78e — FOUND
