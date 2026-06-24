---
phase: 125-containerized-shared-backend-port-convention
plan: "03"
subsystem: docs-contract
status: complete
tags: [port-registry, drift-test, quick-start, docs-contract, port-migration]
dependency_graph:
  requires:
    - "125-01: runtime.exs holds PORT default 4700 (test derives from it); .env holds COMPOSE_PROJECT_NAME/PORT"
  provides:
    - "docs/PORT-REGISTRY.md: reusable port-allocation convention, 4700–4799 block, crosswake seed row, COMPOSE_PROJECT_NAME + 10.0.2.2 caveats"
    - "test/crosswake/guides/port_registry_test.exs: source-derived drift guard for PORT-REGISTRY"
    - "examples/QUICK_START.md: fully migrated to 4700, Docker boot path documented"
  affects:
    - "PORT-01: committed port 4700 now documented in QUICK_START and PORT-REGISTRY"
    - "PORT-02: Android 10.0.2.2 note now in PORT-REGISTRY"
    - "PORT-03: reusable registry with allocation rule and crosswake seed row"
tech_stack:
  added: []
  patterns:
    - "Source-derived doc-contract test: derives port from runtime.exs via regex, asserts docs match"
    - "Negative-test scanner: proves scanner rejects stale registries (strips COMPOSE_PROJECT_NAME / 10.0.2.2)"
    - "Docker-first + native-alternative documentation pattern (no overclaim)"
key_files:
  created:
    - docs/PORT-REGISTRY.md
    - test/crosswake/guides/port_registry_test.exs
  modified:
    - examples/QUICK_START.md
decisions:
  - "PORT-REGISTRY documents COMPOSE_PROJECT_NAME caveat honestly: namespaces names not ports; committed PORT= is the real collision guard (D-12)"
  - "Test derives port from runtime.exs via ~r/System.get_env(\"PORT\")\\s*\\|\\|\\s*\"(\\d+)\"/ — no hardcoded 4700 in any assertion"
  - "Docker section placed under a new Option A heading in First Run; native path kept as Option B to avoid overclaim"
metrics:
  duration: "~6 minutes"
  completed: "2026-06-21"
  tasks_completed: 3
  files_changed: 3
---

# Phase 125 Plan 03: Port Registry, Drift Test, and QUICK_START Migration Summary

**One-liner:** PORT-REGISTRY.md documents the 4700–4799 reserved block with COMPOSE_PROJECT_NAME/10.0.2.2 caveats and a crosswake seed row, guarded by a new source-derived drift test; QUICK_START.md fully migrated from 4002 to 4700 with a Docker boot path, turning the existing drift test green.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Write docs/PORT-REGISTRY.md | b279f5d | docs/PORT-REGISTRY.md (new) |
| 2 | New source-derived drift test for PORT-REGISTRY | eff28be | test/crosswake/guides/port_registry_test.exs (new) |
| 3 | Migrate QUICK_START.md to 4700 + add Docker path; run full quick-start drift test green | 4a8aa78 | examples/QUICK_START.md |

## What Was Built

### Task 1: docs/PORT-REGISTRY.md

New doc establishing the reusable port-allocation convention:
- **Reserved block:** ports 4700–4799 for the maintainer's OSS lib demos
- **Exclusion list:** 3000 (React/Next), 4000 (Phoenix default), 4002 (old crosswake default, retired), 5000 (macOS AirPlay), 5173 (Vite), 8080, 49152+ (IANA ephemeral)
- **Allocation rule:** pick next free port in block, one per lib, commit `PORT=` and `COMPOSE_PROJECT_NAME=` in lib's `.env`, add a registry row
- **COMPOSE_PROJECT_NAME caveat:** namespaces container/network/volume names NOT host port bindings — the committed `PORT=` value is the real collision guard
- **Android note:** Android emulator reaches host at `10.0.2.2` (not `localhost`)
- **Registry table seed row:** crosswake | 4700 | crosswake | examples/phoenix_host

### Task 2: test/crosswake/guides/port_registry_test.exs

New source-derived doc-contract test mirroring `quick_start_adoption_drift_test.exs`:
- `committed_port/0` reads `runtime.exs` via regex `~r/System.get_env("PORT")\s*\|\|\s*"(\d+)"/` — derives "4700" without hardcoding it
- Positive test: asserts PORT-REGISTRY contains the derived port, `COMPOSE_PROJECT_NAME`, `10.0.2.2`, and `crosswake` seed row; zero failures
- Negative test 1: strips `COMPOSE_PROJECT_NAME` from synthetic registry → asserts `:missing_caveat` failure is produced
- Negative test 2: strips `10.0.2.2` from synthetic registry → asserts `:missing_android_note` failure is produced
- Helpers `failure/3`, `format_failures/1`, `source_port!/3`, `require_contains/5` copied verbatim from the analog drift test

### Task 3: examples/QUICK_START.md

- Replaced all 9 occurrences of `4002` with `4700` (commands, URLs, troubleshooting)
- Added Docker boot section under "First Run" as Option A: `docker compose up` from `examples/phoenix_host/` serves at `http://localhost:4700`; no local Elixir/Node/SQLite toolchain required
- `PORT=4700 mix phx.server` retained as Option B (native alternative)
- Full `quick_start_adoption_drift_test.exs` — 5 tests, 0 failures

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-125-08: PORT-REGISTRY drift vs source port | `port_registry_test.exs` derives port from runtime.exs and fails build if registry drifts | Mitigated |
| T-125-09: Sensitive info in PORT-REGISTRY / QUICK_START | Only ports, project names, and host paths documented; 10.0.2.2 is a public loopback alias | Mitigated |
| T-125-10: Native overclaim in QUICK_START | Docker path documented without overclaiming native support; Option B native section honest; no simulator/emulator/device claims | Mitigated |

## Known Stubs

None — all content is concrete and source-derived. No placeholder text or unresolved TODOs.

## Threat Flags

None — no new network endpoints or auth paths introduced. Docs-only and test-only changes.

## Verification Results

- `docs/PORT-REGISTRY.md` contains `COMPOSE_PROJECT_NAME`, `10.0.2.2`, `crosswake`, `4700`, `4799`, exclusion list with `4002`
- `mix test test/crosswake/guides/port_registry_test.exs` → 4 tests, 0 failures (source-derived, no hardcoded 4700)
- `grep -rn 4002 examples/QUICK_START.md` → no matches
- `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` → 5 tests, 0 failures

## Self-Check: PASSED

Files exist:
- `/Users/jon/projects/crosswake/docs/PORT-REGISTRY.md` — FOUND
- `/Users/jon/projects/crosswake/test/crosswake/guides/port_registry_test.exs` — FOUND
- `/Users/jon/projects/crosswake/examples/QUICK_START.md` — FOUND (modified)

Commits exist:
- b279f5d: docs(125-03): write PORT-REGISTRY with reserved block, exclusions, allocation rule, and crosswake seed row — FOUND
- eff28be: test(125-03): add source-derived drift test for PORT-REGISTRY — FOUND
- 4a8aa78: docs(125-03): migrate QUICK_START.md to port 4700 and add Docker boot path — FOUND
