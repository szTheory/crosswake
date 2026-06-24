---
phase: 125-containerized-shared-backend-port-convention
plan: "01"
subsystem: phoenix-config
status: complete
tags: [config-split, port-migration, live-reload, docker-prep]
dependency_graph:
  requires: []
  provides:
    - "runtime.exs: BIND_ALL-gated ip, PORT default 4700, DATABASE_PATH-driven Repo"
    - "dev.exs: polling live_reload interval 1500, code_reloader, check_origin:false"
    - "committed .env: COMPOSE_PROJECT_NAME=crosswake, PORT=4700"
    - "endpoint.ex: LiveReloader + CodeReloader plugs under code_reloading?"
  affects:
    - "examples/phoenix_host/config/config.exs"
    - "examples/phoenix_host/playwright.config.ts"
    - "test/crosswake/guides/quick_start_adoption_drift_test.exs"
tech_stack:
  added:
    - "{:phoenix_live_reload, \"~> 1.5\", only: :dev}"
  patterns:
    - "Phoenix conventional config split: config.exs/dev.exs/runtime.exs"
    - "BIND_ALL env-var gate for container-vs-native ip binding"
    - "Source-derived port extraction: phoenix_host_port/0 reads runtime.exs"
key_files:
  created:
    - examples/phoenix_host/config/dev.exs
    - examples/phoenix_host/config/runtime.exs
    - examples/phoenix_host/.env
  modified:
    - examples/phoenix_host/config/config.exs
    - examples/phoenix_host/mix.exs
    - examples/phoenix_host/lib/crosswake_example/endpoint.ex
    - examples/phoenix_host/playwright.config.ts
    - test/crosswake/guides/quick_start_adoption_drift_test.exs
decisions:
  - "BIND_ALL=true gates {0,0,0,0} bind in runtime.exs; :test env stays on 127.0.0.1 (D-05)"
  - "Port default 4700 lives in runtime.exs, not config.exs — single source of truth (D-01)"
  - "import_config added at end of config.exs so dev.exs auto-loads under :dev"
  - ".env committed with no secrets: only COMPOSE_PROJECT_NAME and PORT (T-125-01 mitigated)"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-21"
  tasks_completed: 3
  files_changed: 8
---

# Phase 125 Plan 01: Config Split + Port Migration Summary

**One-liner:** Phoenix config split into base/dev/runtime with canonical port migrated from 4002 to 4700 via BIND_ALL-gated runtime.exs and committed secret-free .env.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Split config — prune config.exs, add dev.exs and runtime.exs, migrate port 4002→4700 | ebeddec | config.exs, dev.exs (new), runtime.exs (new) |
| 2 | Add live_reload dep + endpoint plugs; migrate playwright + commit .env | 67896bd | mix.exs, endpoint.ex, playwright.config.ts, .env (new) |
| 3 | Redirect drift test to runtime.exs; prove port migration | 064e459 | quick_start_adoption_drift_test.exs |

## What Was Built

### Task 1: Config Split

`config/config.exs` was pruned — removed `http:` and `database:` keys, added `import_config "#{config_env()}.exs"` at the end.

`config/dev.exs` was created with:
- `code_reloader: true`, `check_origin: false`
- `live_reload: [patterns: [...], interval: 1500]` (polling for macOS Docker bind-mounts)
- `show_sensitive_data_on_connection_error: true` for Repo

`config/runtime.exs` was created with:
- `BIND_ALL=true` gates `{0, 0, 0, 0}` binding; default/test stays `{127, 0, 0, 1}`
- `PORT` env var with default `"4700"` — the new canonical port
- `DATABASE_PATH` env var driving Repo database, with local `.db` fallback

### Task 2: Live Reload + .env

`mix.exs` received `{:phoenix_live_reload, "~> 1.5", only: :dev}` and the stale "committed .db file" test alias comment was corrected.

`endpoint.ex` received an `if code_reloading?` block mounting `Phoenix.LiveReloader.Socket`, `Phoenix.LiveReloader`, and `Phoenix.CodeReloader` before `Plug.Static`.

`playwright.config.ts` — both `baseURL` and `webServer.port` updated from `4002` to `4700`.

`examples/phoenix_host/.env` — new committed file with `COMPOSE_PROJECT_NAME=crosswake` and `PORT=4700` (no secrets).

### Task 3: Drift Test Redirect

`quick_start_adoption_drift_test.exs` — `@phoenix_config_path` changed from `config/config.exs` to `config/runtime.exs`. The `phoenix_host_port/0` helper's existing regex `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` now matches runtime.exs and extracts `4700`.

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat | Mitigation | Status |
|--------|-----------|--------|
| T-125-01: .env committed with secrets | Only COMPOSE_PROJECT_NAME and PORT in .env; no secret_key_base/keys/tokens | Mitigated |
| T-125-02: runtime.exs 0.0.0.0 leak into :test | BIND_ALL=true gate; test runner never sets BIND_ALL → stays 127.0.0.1 | Mitigated |
| T-125-03: check_origin:false spoofing | dev.exs only; applies under :dev, not :prod or :test | Accepted (documented) |
| T-125-04: secret_key_base placeholder in config.exs | Intentional demo value String.duplicate("a", 64); no real sessions | Accepted |

## Known Stubs

None — all changes are concrete configuration with real values (port 4700, BIND_ALL gate, DATABASE_PATH).

## Threat Flags

None — no new network endpoints or auth paths introduced. runtime.exs reduces exposure (loopback default vs previously hardcoded loopback in config.exs — same net effect, cleaner gating).

## Verification Results

- `grep -rn 4002 examples/phoenix_host/config examples/phoenix_host/playwright.config.ts` → no matches
- `runtime.exs` contains PORT default 4700, BIND_ALL gate, DATABASE_PATH read
- Drift test `@phoenix_config_path` → `examples/phoenix_host/config/runtime.exs`
- `mix.lock` will be updated on next `mix deps.get` (phoenix_live_reload newly added; expected)

## Self-Check: PASSED

Files exist:
- `/Users/jon/projects/crosswake/examples/phoenix_host/config/dev.exs` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/config/runtime.exs` — FOUND
- `/Users/jon/projects/crosswake/examples/phoenix_host/.env` — FOUND (confirmed via git status)

Commits exist:
- ebeddec: feat(125-01): split Phoenix config into base/dev/runtime — FOUND
- 67896bd: feat(125-01): add live_reload dep + endpoint plugs — FOUND
- 064e459: feat(125-01): redirect drift test port source from config.exs to runtime.exs — FOUND
