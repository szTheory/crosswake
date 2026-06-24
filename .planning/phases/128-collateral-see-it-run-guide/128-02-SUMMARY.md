---
phase: 128-collateral-see-it-run-guide
plan: "02"
subsystem: docs
tags: [readme, quick-start, routing, collateral, docs-02]
status: complete

dependency_graph:
  requires: ["128-01"]
  provides: ["DOCS-02"]
  affects: ["README.md", "examples/QUICK_START.md"]

tech_stack:
  added: []
  patterns:
    - "forward-only link graph: README → see_it_run → QUICK_START"
    - "emulator-evidence advisory blockquote pattern"
    - "hero-command-first Option A restructure"

key_files:
  modified:
    - README.md
    - examples/QUICK_START.md

decisions:
  - "Embedded three-runtime-montage.png in README via raw.githubusercontent.com (D-13, recommended option — visual present without separate guide link)"
  - "Advisory blockquote in README uses inline emulator evidence term and links legend anchor; mirrors see_it_run.md advisory pattern"
  - "QUICK_START Option A retains docker compose up as inline fallback note on single line (drift test scans for it; framed as fallback not primary)"

metrics:
  duration: "~2m"
  completed: "2026-06-22"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 128 Plan 02: README + QUICK_START Routing Summary

README and QUICK_START now route readers to guides/see_it_run.md and the one-command path (bin/see-it-run.sh) with honest emulator-evidence labels throughout.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add `## See it run` section to README | 0d4c689 | README.md |
| 2 | Add QUICK_START top pointer + rename Option A | 20287b2 | examples/QUICK_START.md |

## What Was Built

### Task 1 — README `## See it run` section

Inserted a new `## See it run` section in README.md between `## What this is not` (line 34) and `## Choose your path` (now at line 74). The section:

- Fronts `bin/see-it-run.sh` as the single hero command in a fenced code block, with a one-line Docker caveat (port 4700, auto-opens browser)
- Embeds `three-runtime-montage.png` via `raw.githubusercontent.com` absolute URL with the canonical montage alt text carrying `emulator evidence` labels for native frames
- Names the three route owners: `/` (Phoenix LiveView), `/offline` (offline island), `/bridge-proof` (bounded bridge) at `http://localhost:4700`
- Carries an advisory-native blockquote with the canonical `emulator evidence` term and link to `guides/support_matrix.md#support-truth-label-legend`
- Forward-links to `guides/see_it_run.md` (guided tour) and `examples/QUICK_START.md` (command reference)
- No native overclaim; no "works on device", "cross-platform", or unqualified "supported" near native references

### Task 2 — QUICK_START top pointer + Option A rename

In `examples/QUICK_START.md`:

- Added `> **New here?** Start with [guides/see_it_run.md](../guides/see_it_run.md) to see the three runtimes in action. Come back here for the full proof command reference.` before the existing intro paragraph
- Renamed `### Option A: Docker (no local Elixir/Node/SQLite toolchain required)` → `### Option A: One Command (Docker)`
- Option A now leads with `bin/see-it-run.sh` (run from repo root), with clear description of what it does
- Raw `docker compose up` demoted to inline fallback note: `To run the Docker backend directly: \`cd examples/phoenix_host && docker compose up\`` (command retained for drift test scanner)
- All existing honest labels preserved: `## What This Does Not Prove`, native-step proof labels, advisory language
- Option B and dev-wiring command literals unchanged

## Verification Results

```
mix test test/crosswake/guides/quick_start_adoption_drift_test.exs
5 tests, 0 failures
```

### README Acceptance Criteria

| Check | Result |
|-------|--------|
| `grep -c '^## See it run' README.md` | 1 |
| Section between `## What this is not` (34) and `## Choose your path` (74) | PASS (line 45) |
| `grep -c 'bin/see-it-run.sh' README.md` | 1 |
| `grep -c 'guides/see_it_run.md' README.md` | 1 |
| `grep -c 'examples/QUICK_START.md' README.md` | 1 |
| `grep -c 'emulator evidence' README.md` | 3 |
| `grep -c 'support_matrix.md#support-truth-label-legend' README.md` | 2 |
| No native overclaim | PASS |

### QUICK_START Acceptance Criteria

| Check | Result |
|-------|--------|
| `grep -c 'New here?' examples/QUICK_START.md` | 1 |
| `grep -c '../guides/see_it_run.md' examples/QUICK_START.md` | 1 |
| `grep -c '### Option A: One Command (Docker)' examples/QUICK_START.md` | 1 |
| Old heading gone | PASS (0) |
| `grep -c 'bin/see-it-run.sh' examples/QUICK_START.md` | 1 |
| `grep -c 'docker compose up' examples/QUICK_START.md` | 2 (fallback + dev-wiring section) |
| `grep -c '## What This Does Not Prove' examples/QUICK_START.md` | 1 |
| Drift test | 5 tests, 0 failures |

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|-----------|
| T-128-04 | Advisory blockquote in README and intact QUICK_START honest labels prevent native overclaim |
| T-128-05 | `docker compose up` retained in QUICK_START; `## What This Does Not Prove` unchanged; drift test passes 5/5 |

## Known Stubs

None — both files carry real content; no placeholder text introduced.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced. Docs-only changes.

## Self-Check: PASSED

- README.md modified and committed: 0d4c689 — FOUND
- examples/QUICK_START.md modified and committed: 20287b2 — FOUND
- `## See it run` section present at line 45 (between lines 34 and 74) — FOUND
- `> **New here?**` pointer present at top of QUICK_START — FOUND
- `### Option A: One Command (Docker)` present — FOUND
- `mix test quick_start_adoption_drift_test.exs` — 5 tests, 0 failures
