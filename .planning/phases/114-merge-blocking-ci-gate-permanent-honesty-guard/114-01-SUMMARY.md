---
phase: 114-merge-blocking-ci-gate-permanent-honesty-guard
plan: "01"
subsystem: ci
tags: [ci, workflow, aggregator, guard, gate, e2e]
dependency_graph:
  requires: []
  provides:
    - ".github/workflows/offline-sync-e2e-gate.yml (four-job aggregator topology)"
    - "guard-01-e2e-honesty job (honesty check surface for plan 114-02)"
    - "guard-02-prod-route-absence job (prod absence surface for GUARD-02)"
    - "e2e-proof job (compile gate + in-suite tests + Playwright)"
    - "merge-blocking-offline-sync-e2e aggregator (sole required-check target for GATE-01)"
  affects:
    - "CI pipeline (all PRs to main)"
    - "Branch protection required-check registration (plan 114-05)"
tech_stack:
  added: ["re-actors/alls-green@release/v1", "actions/cache@v4 (env-scoped keys)"]
  patterns: ["Option-C aggregator topology", "MIX_ENV-isolated runners", "env-scoped cache keys"]
key_files:
  created: []
  modified:
    - ".github/workflows/offline-sync-e2e-gate.yml (renamed from phase90-proof.yml via git mv)"
decisions:
  - "Option-C aggregator topology: three sibling jobs + one re-actors/alls-green aggregator as sole required check"
  - "Env-scoped cache keys (build-test-* / build-prod-*) isolate the two MIX_ENV compiles — never a shared _build cache key"
  - "rm -rf _build/prod forces a clean prod compile so a :test-compiled router beam cannot make GUARD-02 pass vacuously"
  - "Placeholder comment for plan 114-05 registration one-liner placed in workflow header"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-18T06:35:56Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
status: complete
---

# Phase 114 Plan 01: 4-Job Aggregator Gate & Workflow Rename Summary

**One-liner:** Four-job Option-C aggregator topology replacing single-job phase90-proof.yml — guard-01 (AST honesty), guard-02 (prod-route absence), e2e-proof (compile gate + Playwright), merge-blocking aggregator via re-actors/alls-green.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | git mv phase90-proof.yml → offline-sync-e2e-gate.yml with stable name + archaeology | b4bf214 | .github/workflows/offline-sync-e2e-gate.yml |
| 2 | Restructure into four-job Option-C aggregator topology | d544530 | .github/workflows/offline-sync-e2e-gate.yml |

## What Was Built

### Task 1: Workflow Rename (git mv)

Renamed `.github/workflows/phase90-proof.yml` to `.github/workflows/offline-sync-e2e-gate.yml` using `git mv` so history is preserved (`git log --follow` shows pre-rename commits). Set the top-level `name:` to `Offline-Sync E2E Gate` and added the archaeology comment: "Renamed from phase90-proof.yml (2026-06). Permanent merge gate — purpose-named, not phase-scoped." Added `permissions: { contents: read }` (T-114-03 mitigation).

### Task 2: Four-Job Aggregator Topology

Replaced the single `e2e-offline-sync` job with four jobs per Option-C (D-01):

**guard-01-e2e-honesty** (~2s, no Elixir, no browser): checkout + setup-node@v4 (node 20), runs `node script/check-e2e-honesty.mjs`, writes a $GITHUB_STEP_SUMMARY note. This job is the CI surface that plan 114-02 uses for the AST honesty guard.

**guard-02-prod-route-absence** (MIX_ENV=prod, isolated runner): setup-beam pinned to fc68ffb90438ef2936bbb3251622353b3dcb2f93 (v1.24.0), env-scoped cache at `build-prod-*` on `_build/prod`. The assert step: `rm -rf _build/prod` (forces clean prod compile, never inspects a :test-compiled beam), `mix deps.get --only prod`, captures `mix phx.routes CrosswakeExample.Router`, then `grep -qE '/_e2e(/|$)'` to assert ABSENCE — exits 1 if found. Uses `! grep -qE` semantics, never `grep -v`.

**e2e-proof** (MIX_ENV=test, isolated runner): setup-beam (same pin), env-scoped cache at `build-test-*` on `_build/test`. Steps: `mix deps.get`, `mix compile --warnings-as-errors` (compile gate BEFORE Playwright — E2E-04 preserved), `mix test router_test.exs sync_state_controller_test.exs` (in-suite route/controller assertions for plan 114-03), `npm ci`, `npx playwright install --with-deps`, `npx playwright test`.

**merge-blocking-offline-sync-e2e** (aggregator, THE only required check): `if: always()`, `needs: [guard-01-e2e-honesty, guard-02-prod-route-absence, e2e-proof]`, single step `re-actors/alls-green@release/v1` with `jobs: ${{ toJSON(needs) }}`. This is the one immutable string registered in branch protection (GATE-01).

A placeholder comment in the workflow header marks where plan 114-05 will paste the `gh api PATCH` registration one-liner.

## Threat Mitigations Applied

| Threat | Mitigation | Evidence |
|--------|------------|---------|
| T-114-01: aggregator skip bypass | re-actors/alls-green with if: always() | Line: `if: always()` + `uses: re-actors/alls-green@release/v1` |
| T-114-02: shared _build cache contamination | Env-scoped keys build-test-* / build-prod-* on distinct paths; rm -rf _build/prod | Verified by grep checks |
| T-114-03: excess workflow permissions | permissions: { contents: read } | Present in workflow header |

## Deviations from Plan

None — plan executed exactly as written. The `grep -qE` absence assertion pattern, env-scoped cache keys, four-job topology, aggregator `if: always()` + alls-green, and archaeology comment all match the RESEARCH-SYNTHESIS §1 sketch.

## Known Stubs

None. This plan delivers the workflow spine only; the following plans complete the referenced scripts/tests:
- `script/check-e2e-honesty.mjs` — created by plan 114-02
- `examples/phoenix_host/test/crosswake_example/router_test.exs` — created by plan 114-03
- `examples/phoenix_host/test/crosswake_example/e2e/sync_state_controller_test.exs` — created by plan 114-03
- The gh api PATCH registration comment — authored by plan 114-05

The `guard-01-e2e-honesty` and e2e-proof jobs reference these files by name; they will fail on CI until plans 114-02/114-03 land (expected — plan 114-05 registration is gated on all jobs going green together).

## Self-Check: PASSED

- `.github/workflows/offline-sync-e2e-gate.yml` exists: FOUND
- `.github/workflows/phase90-proof.yml` deleted: CONFIRMED
- Commit b4bf214 exists: CONFIRMED (rename + stable name)
- Commit d544530 exists: CONFIRMED (four-job topology)
- All four job keys present: 4/4
- Aggregator `if: always()` + alls-green: PRESENT
- Env-scoped cache keys build-test-* / build-prod-*: PRESENT
- compile before playwright: line 87 < line 99
- `grep -v` NOT present in guard-02: CONFIRMED
