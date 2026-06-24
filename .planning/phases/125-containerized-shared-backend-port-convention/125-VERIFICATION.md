---
phase: 125-containerized-shared-backend-port-convention
verified: 2026-06-21T20:00:00Z
status: passed
score: 5/5
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 125: Containerized Shared Backend + Port Convention — Verification Report

**Phase Goal:** A developer can boot the shared Crosswake demo backend with one command and reach it reliably from all three runtimes, with no port collisions and fast iteration loops.
**Verified:** 2026-06-21T20:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `docker compose up` from a clean checkout boots the demo backend and serves the app at http://localhost:4700 | VERIFIED | `docker-compose.yml` exists with `ports: ["4700:4700"]`, `build: .`, `env_file: .env`, `BIND_ALL=true`; `entrypoint.sh` runs `ecto.create/migrate/seed` then `exec mix phx.server`; `Dockerfile` builds from `hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim`; static verification only per phase notes |
| 2 | Editing app/style code triggers live-reload without re-downloading/re-compiling deps; only mix.exs/mix.lock changes trigger dep rebuild | VERIFIED | Dockerfile layer ordering confirmed: `COPY mix.exs mix.lock` + `RUN mix deps.get` appears before any `COPY lib/`/`COPY config/`/`COPY priv/`; compose bind-mounts source at `.:/app`; `deps_cache:/app/deps` and `build_cache:/app/_build` are named volumes; `dev.exs` has polling `live_reload: [interval: 1500]` |
| 3 | SQLite persists across container restarts in a named volume (not a macOS bind-mount) and is auto-seeded on first boot; `mix phx.server` on port 4700 works as documented native alternative | VERIFIED | `sqlite_data:/data` named volume in `docker-compose.yml`; `DATABASE_PATH=/data/crosswake_example.db` in compose environment; `entrypoint.sh` runs `mix ecto.create --quiet && mix ecto.migrate --quiet && mix run priv/repo/seeds.exs`; `QUICK_START.md` documents `PORT=4700 mix phx.server` as Option B |
| 4 | `.dockerignore` is lean: excludes `_build`, `deps`, `node_modules`, `priv/static`, `.git`, `.planning`, `.claude`, and evidence artifacts | VERIFIED | All 8 required exclusions confirmed present: `_build/`, `deps/`, `node_modules/`, `priv/static/`, `.git/`, `.planning/`, `.claude/`, `crosswake_example.db*`; also excludes `.env`, `test/`, `evidence/`, `artifacts/`, `*.db`, `*.db-shm`, `*.db-wal` |
| 5 | Committed `examples/phoenix_host/.env` has `COMPOSE_PROJECT_NAME=crosswake` and `PORT=4700`; `docs/PORT-REGISTRY.md` documents the convention; Android emulator can reach backend at `10.0.2.2:4700` | VERIFIED | `.env` confirmed via `git show HEAD:examples/phoenix_host/.env` — contains exactly `COMPOSE_PROJECT_NAME=crosswake` and `PORT=4700` with no secrets; `docs/PORT-REGISTRY.md` contains `COMPOSE_PROJECT_NAME`, `10.0.2.2`, `crosswake`, `4700`, `4799`; Android note explicitly states emulator reaches host at `10.0.2.2` |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

---

## Required Artifacts

### Plan 125-01 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/phoenix_host/config/runtime.exs` | PORT default 4700, BIND_ALL gate, DATABASE_PATH | VERIFIED | Contains `System.get_env("PORT") \|\| "4700"`, `BIND_ALL == "true"` gate for `{0,0,0,0}`, `DATABASE_PATH` with local `.db` fallback |
| `examples/phoenix_host/config/dev.exs` | code_reloader, check_origin:false, interval 1500 | VERIFIED | Contains all three; no `_build`/`deps` watcher patterns present |
| `examples/phoenix_host/.env` | COMPOSE_PROJECT_NAME=crosswake, PORT=4700, no secrets | VERIFIED | Confirmed via git; only two lines present; no secret-like keys |
| `examples/phoenix_host/lib/crosswake_example/endpoint.ex` | LiveReloader + CodeReloader under code_reloading? | VERIFIED | `if code_reloading?` block mounts `Phoenix.LiveReloader.Socket`, `plug(Phoenix.LiveReloader)`, `plug(Phoenix.CodeReloader)` before `Plug.Static` |
| `examples/phoenix_host/config/config.exs` | No `http:` or `database:` keys; has import_config | VERIFIED | No `http:` or `database:` keys; ends with `import_config "#{config_env()}.exs"` at line 42 |
| `examples/phoenix_host/mix.exs` | `{:phoenix_live_reload, "~> 1.5", only: :dev}`; corrected comment | VERIFIED | Dep present at line 41; comment reads "Provisions the SQLite DB and applies all migrations before running tests" (stale reference removed) |
| `examples/phoenix_host/playwright.config.ts` | 4700 everywhere, no 4002 | VERIFIED | `baseURL: 'http://localhost:4700'` and `port: 4700`; no 4002 present |
| `test/crosswake/guides/quick_start_adoption_drift_test.exs` | @phoenix_config_path → runtime.exs | VERIFIED | Line 6: `@phoenix_config_path "examples/phoenix_host/config/runtime.exs"` |

### Plan 125-02 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/phoenix_host/Dockerfile` | Multi-stage, hexpm glibc base, deps-first layer ordering, EXPOSE 4700 | VERIFIED | Both stages use `hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim`; `COPY mix.exs mix.lock` + `RUN mix deps.get` before `COPY lib/` (awk check passed); `EXPOSE 4700`; `CMD ["./entrypoint.sh"]` |
| `examples/phoenix_host/.dockerignore` | Full DOCKER-05 exclusion list + `crosswake_example.db*` | VERIFIED | All required exclusions present; also includes `*.db`, `*.db-shm`, `*.db-wal`, `.github/`, `.env`, `test/`, `evidence/`, `artifacts/` |
| `examples/phoenix_host/entrypoint.sh` | `set -e`, ecto.create/migrate/seed, exec phx.server | VERIFIED | `#!/bin/sh`, `set -e`, `mix ecto.create --quiet`, `mix ecto.migrate --quiet`, `mix run priv/repo/seeds.exs`, `exec mix phx.server` in correct order |
| `examples/phoenix_host/docker-compose.yml` | 4700:4700, BIND_ALL=true, DATABASE_PATH, named volumes, env_file | VERIFIED | All five elements confirmed; no `version:` key; `sqlite_data:/data` (no host bind-mount for DB) |

### Plan 125-03 Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `docs/PORT-REGISTRY.md` | Reserved 4700-4799 block, exclusions, allocation rule, crosswake seed row, COMPOSE_PROJECT_NAME and 10.0.2.2 caveats | VERIFIED | All required content confirmed; `4002` documented as excluded (old crosswake default) |
| `test/crosswake/guides/port_registry_test.exs` | Source-derived (no hardcoded 4700), negative tests for COMPOSE_PROJECT_NAME and 10.0.2.2 | VERIFIED | `committed_port/0` derives port from `runtime.exs` via regex; no `4700` literal in any assertion; two negative tests strip COMPOSE_PROJECT_NAME and 10.0.2.2 respectively |
| `examples/QUICK_START.md` | No 4002, uses 4700 everywhere, `docker compose up` section present, `PORT=4700 mix phx.server` as native alternative | VERIFIED | Zero 4002 references; Docker Option A section added; 8+ occurrences of 4700 in URLs/commands; Option B native path retained |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `docker-compose.yml` | `config/runtime.exs` | Sets `BIND_ALL=true` and `DATABASE_PATH=/data/crosswake_example.db` consumed by runtime.exs | VERIFIED | Both env vars confirmed in compose `environment:` block; runtime.exs reads both |
| `docker-compose.yml` | `examples/phoenix_host/.env` | `env_file: .env` supplies COMPOSE_PROJECT_NAME + PORT | VERIFIED | `env_file: .env` present; `.env` confirmed in git with correct values |
| `entrypoint.sh` | `priv/repo/seeds.exs` | Runs `mix run priv/repo/seeds.exs` idempotently | VERIFIED | `mix run priv/repo/seeds.exs` present in entrypoint.sh |
| `test/crosswake/guides/quick_start_adoption_drift_test.exs` | `config/runtime.exs` | `phoenix_host_port/0` derives port via regex from runtime.exs | VERIFIED | `@phoenix_config_path "examples/phoenix_host/config/runtime.exs"` at line 6 |
| `test/crosswake/guides/port_registry_test.exs` | `config/runtime.exs` | `committed_port/0` derives PORT via same regex pattern | VERIFIED | `@runtime_config_path "examples/phoenix_host/config/runtime.exs"` at line 6; regex `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` |
| `docs/PORT-REGISTRY.md` | `examples/phoenix_host/.env` | Registry seed row records same committed PORT/COMPOSE_PROJECT_NAME | VERIFIED | Registry table row: `crosswake | 4700 | crosswake | examples/phoenix_host` |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Port 4700 extractable from runtime.exs via test regex | `grep -oP 'System\.get_env\("PORT"\)\s*\|\|\s*"\K\d+'` | `4700` | PASS |
| No stale 4002 in config or playwright | `grep -rn 4002 examples/phoenix_host/config/ examples/phoenix_host/playwright.config.ts` | no matches | PASS |
| No stale 4002 in QUICK_START.md | `grep -rn 4002 examples/QUICK_START.md` | no matches | PASS |
| Dockerfile layer ordering (deps before source) | awk check on COPY line numbers | deps (line 12) before lib (line 16) | PASS |
| .dockerignore has all 8 required exclusions | grep check for each | all 8 present | PASS |
| PORT-REGISTRY has all 5 required strings | grep check for each | all 5 present | PASS |
| Drift test reads runtime.exs (not config.exs) | grep `@phoenix_config_path` | line 6: `runtime.exs` | PASS |
| port_registry_test.exs has no hardcoded 4700 | grep `4700` in test file | no matches | PASS |
| .env committed with no secrets | git show HEAD + grep for secret-like keys | no secrets found | PASS |
| mix.lock contains phoenix_live_reload (regression fix) | grep in mix.lock | 1 entry | PASS |
| All 9 phase commits exist in git | git log search | All commits verified | PASS |

Note: `docker compose up` runtime boot is not verified in this environment (Docker not running); artifact and configuration correctness is verified statically per phase instructions.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|---------|
| DOCKER-01 | 125-02 | One-command `docker compose up` boots backend | SATISFIED | `docker-compose.yml` with `build: .`, `env_file`, `entrypoint.sh` wires ecto+seed+phx.server |
| DOCKER-02 | 125-02 | Multi-stage Dockerfile; deps layer keyed on mix.exs/mix.lock | SATISFIED | Layer ordering verified: `COPY mix.exs mix.lock` → `RUN mix deps.get` before all source COPY |
| DOCKER-03 | 125-02 | Source bind-mounted; deps/_build in named volumes; polling live-reload | SATISFIED | `.:/app` bind-mount; `deps_cache:/app/deps`; `build_cache:/app/_build`; `dev.exs` interval 1500 |
| DOCKER-04 | 125-02 | SQLite in named volume, auto-seeded; native `mix phx.server` documented | SATISFIED | `sqlite_data:/data`; `DATABASE_PATH=/data/crosswake_example.db`; entrypoint seeds; QUICK_START documents native path |
| DOCKER-05 | 125-02 | `.dockerignore` excludes `_build`, `deps`, `node_modules`, `priv/static`, `.git`, `.planning`, `.claude`, evidence | SATISFIED | All required exclusions verified; also excludes `*.db*` runtime artifacts |
| PORT-01 | 125-01, 125-03 | Committed port 4700 via `.env`; COMPOSE_PROJECT_NAME prevents name collisions | SATISFIED | `.env` confirmed with `PORT=4700`; `COMPOSE_PROJECT_NAME=crosswake` |
| PORT-02 | 125-01, 125-03 | Port reachable from web (localhost:4700), iOS (localhost:4700), Android (10.0.2.2:4700) | SATISFIED | `runtime.exs` BIND_ALL gate enables `0.0.0.0` in container; `10.0.2.2` documented in PORT-REGISTRY |
| PORT-03 | 125-03 | Reusable PORT-REGISTRY document | SATISFIED | `docs/PORT-REGISTRY.md` exists with reserved block, exclusions, allocation rule, crosswake seed row; guarded by `port_registry_test.exs` |

**Note on REQUIREMENTS.md tracking:** The PORT-03 checkbox and traceability table in `REQUIREMENTS.md` still show `[ ]` / "Pending" — but the implementation (`docs/PORT-REGISTRY.md` + `test/crosswake/guides/port_registry_test.exs`) is complete and verified. This is a documentation bookkeeping gap in REQUIREMENTS.md only; it does not reflect implementation status.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

Scanned: `config/runtime.exs`, `config/dev.exs`, `config/config.exs`, `Dockerfile`, `.dockerignore`, `entrypoint.sh`, `docker-compose.yml`, `docs/PORT-REGISTRY.md` — zero TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER markers found.

---

## Human Verification Required

None. All artifacts are statically verifiable configuration and code. Runtime behavior (actual Docker boot, live-reload round-trip, SQLite persistence across restart) is noted as advisory-only per the phase instructions ("Docker is not expected to be actually booted in this environment").

---

## Gaps Summary

No gaps. All 5 success criteria are met, all 8 required artifact files exist with substantive content, all 6 key links are wired, and all 8 requirement IDs (DOCKER-01 through DOCKER-05, PORT-01 through PORT-03) have implementation evidence.

The REQUIREMENTS.md PORT-03 checkbox (`[ ]` → `[x]`) and traceability row ("Pending" → "Complete") were not updated by the phase executor. This is a bookkeeping inconsistency, not a functional gap — the deliverable exists and passes its drift test.

---

---

## Post-Review Remediation & Empirical Boot Verification

The initial verification above passed on **static** grounds (per the "Docker not booted in this environment" note). The subsequent `execute:post` code-review gate, followed by an **actual `docker compose build` + `docker compose up`**, found that the headline one-command-boot goal (Truth 1) and live-reload (Truth 2) were in fact **non-functional** as originally shipped. Four build/boot defects and two live-reload defects were fixed in commit `4112d13`:

1. **Invalid base image** — `hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim` does not exist on Docker Hub (build failed at `FROM`). Pinned to the valid `1.19.5-erlang-27.3.4-debian-bookworm-20260610-slim`.
2. **Path dep outside build context** — `{:crosswake, path: "../.."}` was outside the example-dir build context, so `mix deps.compile` could not find the lib. Build context is now the repo root, mirroring the repo layout in-container; a root `.dockerignore` keeps it lean.
3. **Missing C toolchain** — `exqlite`/`ecto_sqlite3` compile a C NIF; added `build-essential`.
4. **Volume shadowing** — empty `deps_cache`/`build_cache` named volumes shadowed the image's compiled artifacts; `entrypoint.sh` now runs `deps.get/compile/compile`, and only the example's source subdirs are bind-mounted.
5. **Code reloader** — added `listeners: [Phoenix.CodeReloader]` (required by Phoenix 1.8).
6. **File watcher** — forced the `:fs_poll` backend (the macOS-bind-mount-safe polling the phase intended but had not wired).

**Empirically verified after the fixes:**
- `docker compose up` → app served at `http://localhost:4700` (HTTP 200, real `<title>Crosswake Phoenix Host</title>` page) — **Truth 1 ✓ (runtime, not just static)**
- A bind-mounted source edit (`router.ex`) was picked up via compile-on-request with zero reloader errors — **Truth 2 ✓ (runtime)**
- SQLite `/data/crosswake_example.db` (named volume) survived a container restart and was auto-seeded on first boot — **Truth 3 ✓ (runtime)**

Full `mix test` after the fixes: 4 failures, all pre-existing docs-debt unrelated to this phase (HexPage ×2, Phase48, Phase69); the example-host proof tests pass.

---

_Verified: 2026-06-21T20:00:00Z (static); empirically re-verified 2026-06-21 after remediation `4112d13`_
_Verifier: Claude (gsd-verifier) + orchestrator empirical boot test_
