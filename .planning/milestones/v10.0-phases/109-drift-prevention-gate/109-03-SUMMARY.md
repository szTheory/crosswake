---
phase: 109-drift-prevention-gate
plan: "03"
subsystem: ci
tags: [ci, drift-gate, brand-structural, workflow, on-paths]
dependency_graph:
  requires: [109-01]
  provides: [PROOF-01-SC3, D-01a-on-paths-broadening]
  affects: [.github/workflows/brandbook-verify.yml]
tech_stack:
  added: []
  patterns: [github-actions-path-trigger, plain-node-ci-step]
key_files:
  created: []
  modified:
    - .github/workflows/brandbook-verify.yml
decisions:
  - "Inserted drift step between WCAG contrast matrix and Install brand e2e dependencies to fail fast before Playwright install"
  - "Added 4 consumer globs to both pull_request and push triggers; priv/static/crosswake/** gives D-04 byte-parity free win"
  - "No new job, no new required-status-check name — step lives inside existing brand-structural lane (D-01)"
metrics:
  duration: "2m"
  completed: "2026-06-14"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 1
---

# Phase 109 Plan 03: CI Drift-Gate Wiring Summary

CI drift gate wired into `brand-structural` required job via one new plain-node step running `node check-consumer-drift.mjs`, positioned after WCAG contrast matrix and before Playwright install for fast failure; `on.paths` broadened to fire on all 4 consumer file locations and `priv/static/crosswake/**` (D-04 byte-parity free win).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Broaden on.paths with 4 consumer globs (pull_request + push) | 87a5120 | .github/workflows/brandbook-verify.yml |
| 2 | Add drift-gate step inside brand-structural before Playwright install | 820c311 | .github/workflows/brandbook-verify.yml |

## What Was Built

**Task 1 — on.paths broadening (D-01a):** Added 4 consumer globs to both `pull_request.paths` and `push.paths` in `.github/workflows/brandbook-verify.yml`, keeping `brandbook/**` first:
- `examples/phoenix_host/priv/static/css/app.css`
- `priv/static/crosswake/**` (D-04 free win: fires `compile-tokens.test.mjs:222` byte-parity test on direct `tokens.css` edits — zero new code)
- `priv/templates/crosswake/offline_ui/**`
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/**`

**Task 2 — drift-gate CI step:** Inserted a new step inside the existing `brand-structural` job after `WCAG contrast matrix` and before `Install brand e2e dependencies`:
```
name: Consumer drift gate (no hex / no primitives / semantic coverage)
working-directory: brandbook/tools
run: node check-consumer-drift.mjs
```
The `working-directory: brandbook/tools` matches the established plain-node step shape. The script's internal `ROOT = resolve(__dirname, '../..')` ensures manifest path resolution to repo root regardless of cwd.

## Verification Results

- Task 1 grep gate: PASS (all 4 consumer globs appear exactly twice — once under pull_request.paths, once under push.paths)
- Task 2 ordering gate: PASS (`node check-consumer-drift.mjs` textually after `WCAG contrast matrix` and before `Install brand e2e dependencies`)
- `brand-visual` job unchanged: `continue-on-error: true` confirmed present; no new job introduced
- Required check name unchanged: step added inside existing `brand-structural` lane (D-01)

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The new CI step is read-only (reads committed files via `check-consumer-drift.mjs`), references no secrets, and runs within the existing `brand-structural` job scope. No threat flags.

## Self-Check: PASSED

- `.github/workflows/brandbook-verify.yml` exists and is modified: FOUND
- Task 1 commit 87a5120 exists: FOUND
- Task 2 commit 820c311 exists: FOUND
- Ordering gate: PASS
- Glob count gate: PASS
