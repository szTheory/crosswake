---
phase: 125-containerized-shared-backend-port-convention
plan: "02"
subsystem: docker-artifacts
status: complete
tags: [docker, dockerfile, docker-compose, entrypoint, dockerignore, live-reload, sqlite-volume]
dependency_graph:
  requires:
    - "125-01: runtime.exs BIND_ALL gate, PORT default 4700, DATABASE_PATH, committed .env"
  provides:
    - "examples/phoenix_host/Dockerfile: multi-stage glibc Elixir image with layer-ordered deps cache"
    - "examples/phoenix_host/entrypoint.sh: idempotent ecto.create/migrate/seed then phx.server"
    - "examples/phoenix_host/.dockerignore: lean build context excluding DB artifacts, secrets, and host binaries"
    - "examples/phoenix_host/docker-compose.yml: bind-mount source + named volumes (deps/build/sqlite) + 4700 mapping"
  affects:
    - "examples/phoenix_host/Dockerfile"
    - "examples/phoenix_host/entrypoint.sh"
    - "examples/phoenix_host/.dockerignore"
    - "examples/phoenix_host/docker-compose.yml"
tech_stack:
  added: []
  patterns:
    - "Multi-stage Dockerfile: deps layer keyed on mix.exs/mix.lock (DOCKER-02)"
    - "hexpm/elixir Debian bookworm-slim base (glibc required for ecto_sqlite3 NIF)"
    - "Idempotent container entrypoint: ecto.create --quiet / migrate --quiet / seeds / exec phx.server"
    - "Named volumes for deps/_build/SQLite; source bind-mount for polling live-reload"
    - "BIND_ALL=true + DATABASE_PATH compose env feeding runtime.exs contract (DOCKER-03/04)"
key_files:
  created:
    - examples/phoenix_host/Dockerfile
    - examples/phoenix_host/entrypoint.sh
    - examples/phoenix_host/.dockerignore
    - examples/phoenix_host/docker-compose.yml
  modified: []
decisions:
  - "hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim for both stages (glibc required for ecto_sqlite3 NIF; Alpine/musl unsafe)"
  - "Plain unconditional re-seed in entrypoint (seeds.exs is delete_all + insert — inherently idempotent; no count==0 guard needed)"
  - "docker-compose.yml collocated in examples/phoenix_host/ so build: . context and .:/app bind-mount paths align with .dockerignore"
  - "No version: key in docker-compose.yml (obsolete in modern compose)"
  - "priv/static excluded from .dockerignore does not conflict: dev live_reload watches it via bind-mount at runtime; image context just stays lean"
metrics:
  duration: "~4 minutes"
  completed: "2026-06-21"
  tasks_completed: 2
  files_changed: 4
---

# Phase 125 Plan 02: Docker Artifacts Summary

**One-liner:** Multi-stage glibc Dockerfile + idempotent entrypoint + lean .dockerignore + docker-compose binding source and SQLite to named volumes with 4700 port mapping — one-command boot of the demo backend.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Multi-stage Dockerfile + idempotent entrypoint | b92b09d | Dockerfile (new), entrypoint.sh (new) |
| 2 | Lean .dockerignore + docker-compose with named volumes and 4700 mapping | 4b217d1 | .dockerignore (new), docker-compose.yml (new) |

## What Was Built

### Task 1: Multi-stage Dockerfile + Idempotent Entrypoint

`examples/phoenix_host/Dockerfile` — two-stage build using `hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim` for both stages:

- Stage `build`: `COPY mix.exs mix.lock ./` + `RUN mix deps.get` BEFORE any source `COPY` — ensures the deps layer is cached independently of app/style code changes (DOCKER-02)
- Source then follows: `COPY config/`, `COPY lib/`, `COPY priv/` → `RUN mix deps.compile`
- Stage runtime: same base image (NIF binary compatibility), `COPY --from=build /app /app`, `COPY --from=build /root/.mix /root/.mix`, copies and `chmod +x entrypoint.sh`, `EXPOSE 4700`, `CMD ["./entrypoint.sh"]`

`examples/phoenix_host/entrypoint.sh` — idempotent container startup:
```sh
#!/bin/sh
set -e
mix ecto.create --quiet
mix ecto.migrate --quiet
mix run priv/repo/seeds.exs
exec mix phx.server
```
No `count==0` re-seed guard — `seeds.exs` is already idempotent (`delete_all` then insert 1 deck + 3 cards). `DATABASE_PATH` set by compose routes `ecto.create` to `/data/crosswake_example.db` inside the named volume.

### Task 2: Lean .dockerignore + docker-compose

`examples/phoenix_host/.dockerignore` — full DOCKER-05 exclusion list:
- Compiled artifacts: `_build/`, `deps/`, `node_modules/`
- Built static assets: `priv/static/`
- VCS + planning: `.git/`, `.github/`, `.planning/`, `.claude/`
- Tests: `test/`
- Evidence artifacts: `evidence/`, `artifacts/`
- Runtime secrets: `.env`
- SQLite runtime artifacts: `*.db`, `*.db-shm`, `*.db-wal`, `crosswake_example.db*` (explicit — prevents host artifact from shadowing the named volume, T-125-06)

`examples/phoenix_host/docker-compose.yml` — one service `phoenix`:
- `build: .` + `env_file: .env` (COMPOSE_PROJECT_NAME + PORT from committed .env)
- `environment: BIND_ALL=true, DATABASE_PATH=/data/crosswake_example.db`
- `ports: ["4700:4700"]`
- `volumes`: `.:/app` (source bind-mount), `deps_cache:/app/deps`, `build_cache:/app/_build`, `sqlite_data:/data`
- Top-level `volumes:` declares `deps_cache`, `build_cache`, `sqlite_data`
- No `version:` key (obsolete in modern compose)
- Validated: `docker compose config` parses cleanly

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat | Mitigation | Status |
|--------|-----------|--------|
| T-125-05: Info disclosure via build context | .dockerignore excludes .git, .planning, .claude, .env, evidence, artifacts, and all *.db* | Mitigated |
| T-125-06: crosswake_example.db* baked into image | Explicit `crosswake_example.db*` + `*.db*` exclusions ensure named volume is single DB source | Mitigated |
| T-125-07: 0.0.0.0 bind via BIND_ALL=true | Accepted — container-scoped local dev only; not a prod path | Accepted |
| T-125-SC: mix deps.get hex packages | Deps pinned by committed mix.lock; no new package-manager installs in this plan | Mitigated |

## Known Stubs

None — all files contain concrete configuration with real values (4700, named volume paths, actual Elixir version pin, real seed sequence).

## Threat Flags

None — no new network endpoints or auth paths introduced beyond what was already planned (BIND_ALL gate was in T-125-07 scope, documented as accepted for local-dev use).

## Verification Results

- Layer ordering: `COPY mix.exs mix.lock` + `RUN mix deps.get` confirmed before `COPY lib/` (awk check passed)
- Base image: `hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim` in both stages (glibc)
- entrypoint.sh: `set -e`, all four commands in correct order, no count==0 guard
- .dockerignore: all 8 DOCKER-05 exclusions present including `crosswake_example.db*`
- docker-compose.yml: `4700:4700`, `BIND_ALL=true`, `DATABASE_PATH=/data/crosswake_example.db`, `env_file`, `sqlite_data:/data`
- `docker compose -f examples/phoenix_host/docker-compose.yml config` — PASSED (no errors)

## Self-Check: PASSED

Files exist:
- `/Users/jon/projects/crosswake/examples/phoenix_host/Dockerfile` — FOUND (b92b09d)
- `/Users/jon/projects/crosswake/examples/phoenix_host/entrypoint.sh` — FOUND (b92b09d)
- `/Users/jon/projects/crosswake/examples/phoenix_host/.dockerignore` — FOUND (4b217d1)
- `/Users/jon/projects/crosswake/examples/phoenix_host/docker-compose.yml` — FOUND (4b217d1)

Commits exist:
- b92b09d: feat(125-02): add multi-stage Dockerfile and idempotent entrypoint — FOUND
- 4b217d1: feat(125-02): add lean .dockerignore and docker-compose with named volumes — FOUND
